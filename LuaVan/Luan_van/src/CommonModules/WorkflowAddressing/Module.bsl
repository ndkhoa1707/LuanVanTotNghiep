////////////////////////////////////////////////////////////////////////////////
// WorkflowAddressing — Tìm người thực hiện Task dynamically theo Role
//
// Dùng trong event handlers BeforeTaskCreation của BusinessProcess.
// Tránh hard-code Lecturer code → linh hoạt khi đổi nhân sự.
////////////////////////////////////////////////////////////////////////////////

#Region PublicAPI

// Tìm Trưởng BM/Khoa của 1 Faculty cụ thể (Role=Head, Active=True)
// Nếu Faculty là Bộ môn → tìm Trưởng BM
// Nếu Faculty là Khoa → tìm bất kỳ Lecturer Role=Head thuộc Khoa hoặc BM con
Function FindHead(Val Faculty) Export
	If Faculty.IsEmpty() Then
		Return Catalogs.Lecturers.EmptyRef();
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Lecturers.Ref AS Ref
	|FROM
	|	Catalog.Lecturers AS Lecturers
	|WHERE
	|	Lecturers.Owner = &Faculty
	|	AND Lecturers.Role = VALUE(Enum.PerformerRoles.Head)
	|	AND Lecturers.Active = TRUE";
	Query.SetParameter("Faculty", Faculty);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;

	// Fallback: tìm trong Faculty cha nếu Faculty là Bộ môn
	If ValueIsFilled(Faculty.Parent) Then
		Return FindHead(Faculty.Parent);
	EndIf;

	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Tìm Trưởng Phòng Đào tạo/HĐKHĐT (Role=InstitutionalHead, Active=True)
Function FindInstitutionalHead() Export
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Lecturers.Ref AS Ref
	|FROM
	|	Catalog.Lecturers AS Lecturers
	|WHERE
	|	Lecturers.Role = VALUE(Enum.PerformerRoles.InstitutionalHead)
	|	AND Lecturers.Active = TRUE";

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
	"SELECT TOP 1
	|	Lecturers.Ref AS Ref
	|FROM
	|	Catalog.Lecturers AS Lecturers
	|WHERE
	|	Lecturers.Role = VALUE(Enum.PerformerRoles.Dean)
	|	AND Lecturers.Active = TRUE";

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Tìm 1 Lecturer bất kỳ trong Faculty (cho T1 - Soạn đề xuất)
Function FindAnyLecturerInFaculty(Val Faculty) Export
	If Faculty.IsEmpty() Then
		Return Catalogs.Lecturers.EmptyRef();
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	Lecturers.Ref AS Ref
	|FROM
	|	Catalog.Lecturers AS Lecturers
	|WHERE
	|	Lecturers.Owner = &Faculty
	|	AND Lecturers.Active = TRUE";
	Query.SetParameter("Faculty", Faculty);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction

// Lookup Faculty đề xuất từ Document ProgramProposal mới nhất gắn với CTĐT
Function GetProposingFaculty(Val TargetProgram) Export
	If TargetProgram.IsEmpty() Then
		Return Catalogs.Faculties.EmptyRef();
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ProgramProposal.ProposingFaculty AS Faculty
	|FROM
	|	Document.ProgramProposal AS ProgramProposal
	|WHERE
	|	ProgramProposal.TargetProgram = &TargetProgram
	|	AND ProgramProposal.Posted = TRUE
	|ORDER BY
	|	ProgramProposal.Date DESC";
	Query.SetParameter("TargetProgram", TargetProgram);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Faculty;
	EndIf;
	Return Catalogs.Faculties.EmptyRef();
EndFunction

#EndRegion
