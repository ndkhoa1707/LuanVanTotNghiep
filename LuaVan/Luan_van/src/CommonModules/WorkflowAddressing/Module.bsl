////////////////////////////////////////////////////////////////////////////////
// WorkflowAddressing — Tìm người thực hiện Task động theo Role
//
// Dùng trong BeforeCreateTasks handlers của BusinessProcess và Task.BeforeWrite.
// Tránh hard-code Lecturer code, linh hoạt khi đổi nhân sự.
////////////////////////////////////////////////////////////////////////////////

#Region PublicAPI

// Tìm Trưởng BM / Trưởng Khoa cho Faculty cụ thể (Role=Head, Active=True).
// Thứ tự ưu tiên:
//   1. Trùng khớp Faculty
//   2. Faculty cha (lên Khoa nếu Faculty là BM)
//   3. BM cùng cấp (sibling BM trong cùng Khoa)
//   4. Bất kỳ Head nào trong toàn hệ thống (fallback cuối)
Function FindHead(Val Faculty) Export
	If Faculty.IsEmpty() Then
		Return FindAnyHead();
	EndIf;

	Found = FindHeadInFaculty(Faculty);
	If Not Found.IsEmpty() Then
		Return Found;
	EndIf;

	If ValueIsFilled(Faculty.Parent) Then
		Found = FindHeadInFaculty(Faculty.Parent);
		If Not Found.IsEmpty() Then
			Return Found;
		EndIf;

		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	Lecturers.Ref AS Ref
		|FROM
		|	Catalog.Lecturers AS Lecturers
		|		INNER JOIN Catalog.Faculties AS F
		|		ON Lecturers.Owner = F.Ref
		|WHERE
		|	F.Parent = &ParentFaculty
		|	AND Lecturers.Role = VALUE(Enum.PerformerRoles.Head)
		|	AND Lecturers.Active = TRUE";
		Query.SetParameter("ParentFaculty", Faculty.Parent);
		Sel = Query.Execute().Select();
		If Sel.Next() Then
			Return Sel.Ref;
		EndIf;
	EndIf;

	Return FindAnyHead();
EndFunction

Function FindHeadInFaculty(Val Faculty)
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 Lecturers.Ref AS Ref
	|FROM Catalog.Lecturers AS Lecturers
	|WHERE Lecturers.Owner = &Faculty
	|  AND Lecturers.Role = VALUE(Enum.PerformerRoles.Head)
	|  AND Lecturers.Active = TRUE";
	Query.SetParameter("Faculty", Faculty);
	Sel = Query.Execute().Select();
	If Sel.Next() Then
		Return Sel.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

Function FindAnyHead()
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 Lecturers.Ref AS Ref
	|FROM Catalog.Lecturers AS Lecturers
	|WHERE Lecturers.Role = VALUE(Enum.PerformerRoles.Head)
	|  AND Lecturers.Active = TRUE";
	Sel = Query.Execute().Select();
	If Sel.Next() Then
		Return Sel.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Tìm Trưởng PĐT / HĐKHĐT (Role=InstitutionalHead, Active=True)
Function FindInstitutionalHead() Export
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 Lecturers.Ref AS Ref
	|FROM Catalog.Lecturers AS Lecturers
	|WHERE Lecturers.Role = VALUE(Enum.PerformerRoles.InstitutionalHead)
	|  AND Lecturers.Active = TRUE";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Tìm Giám đốc (Role=Dean, Active=True)
Function FindDean() Export
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 Lecturers.Ref AS Ref
	|FROM Catalog.Lecturers AS Lecturers
	|WHERE Lecturers.Role = VALUE(Enum.PerformerRoles.Dean)
	|  AND Lecturers.Active = TRUE";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Tìm 1 Lecturer bất kỳ trong Faculty (fallback cho T1 - Soạn đề xuất)
Function FindAnyLecturerInFaculty(Val Faculty) Export
	If Faculty.IsEmpty() Then
		Return Catalogs.Lecturers.EmptyRef();
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 Lecturers.Ref AS Ref
	|FROM Catalog.Lecturers AS Lecturers
	|WHERE Lecturers.Owner = &Faculty
	|  AND Lecturers.Active = TRUE";
	Query.SetParameter("Faculty", Faculty);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Lấy Proposer (người tạo ProgramProposal mới nhất) cho 1 CTĐT.
// Không filter Posted=TRUE để bắt cả document đang trong transaction.
Function GetProposerOfProgram(Val TargetProgram) Export
	If TargetProgram.IsEmpty() Then
		Return Catalogs.Lecturers.EmptyRef();
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 ProgramProposal.Proposer AS Proposer
	|FROM Document.ProgramProposal AS ProgramProposal
	|WHERE ProgramProposal.TargetProgram = &TargetProgram
	|ORDER BY ProgramProposal.Date DESC";
	Query.SetParameter("TargetProgram", TargetProgram);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Proposer;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Map InfoBaseUser hiện tại → Catalog.Lecturers theo Lecturer.Code = User.Name
Function GetCurrentLecturer() Export
	CurrentUser = InfoBaseUsers.CurrentUser();
	If CurrentUser = Undefined Or IsBlankString(CurrentUser.Name) Then
		Return Catalogs.Lecturers.EmptyRef();
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 Lecturers.Ref AS Ref
	|FROM Catalog.Lecturers AS Lecturers
	|WHERE Lecturers.Code = &Login";
	Query.SetParameter("Login", CurrentUser.Name);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Lookup Faculty đề xuất từ ProgramProposal mới nhất gắn với CTĐT.
// Không filter Posted=TRUE để bắt cả document đang trong transaction.
Function GetProposingFaculty(Val TargetProgram) Export
	If TargetProgram.IsEmpty() Then
		Return Catalogs.Faculties.EmptyRef();
	EndIf;
	Query = New Query;
	Query.Text =
	"SELECT TOP 1 ProgramProposal.ProposingFaculty AS Faculty
	|FROM Document.ProgramProposal AS ProgramProposal
	|WHERE ProgramProposal.TargetProgram = &TargetProgram
	|ORDER BY ProgramProposal.Date DESC";
	Query.SetParameter("TargetProgram", TargetProgram);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Faculty;
	EndIf;
	Return Catalogs.Faculties.EmptyRef();
EndFunction

// Suy ra Context (TargetProgram + ApprovalLevel) từ Task,
// dùng cho nút "Phê duyệt CTĐT" trên Task form để auto-fill ProgramApproval.
Function GetApprovalContextFromTask(Val TaskRef) Export
	Result = New Structure;
	Result.Insert("TargetProgram", Catalogs.TrainingPrograms.EmptyRef());
	Result.Insert("ApprovalLevel", Enums.ApprovalLevel.EmptyRef());

	If TaskRef = Undefined Or TaskRef.IsEmpty() Then
		Return Result;
	EndIf;

	BP = TaskRef.BusinessProcess;
	If Not BP.IsEmpty() Then
		Result.TargetProgram = BP.TargetProgram;
	EndIf;

	Desc = Upper(TrimAll(String(TaskRef.Description)));
	If StrStartsWith(Desc, "T2") Then
		Result.ApprovalLevel = Enums.ApprovalLevel.FacultyCouncil;
	ElsIf StrStartsWith(Desc, "T3") Then
		Result.ApprovalLevel = Enums.ApprovalLevel.InstitutionalCouncil;
	ElsIf StrStartsWith(Desc, "T4") Then
		Result.ApprovalLevel = Enums.ApprovalLevel.Issued;
	EndIf;

	Return Result;
EndFunction

#EndRegion
