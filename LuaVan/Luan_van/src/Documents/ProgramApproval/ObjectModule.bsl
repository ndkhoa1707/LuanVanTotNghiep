////////////////////////////////////////////////////////////////////////////////
// ProgramApproval - Object Module
//   • Filling: auto-fill khi mở form từ Task (nút "Phê duyệt CTĐT")
//   • FillCheckProcessing: validate fields
//   • BeforeWrite: kiểm tra quyền theo Role ↔ ApprovalLevel
//   • Posting: ghi IR + cập nhật trạng thái Catalog
////////////////////////////////////////////////////////////////////////////////

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If TypeOf(FillingData) <> Type("Structure") Then
		Return;
	EndIf;

	If FillingData.Property("TargetProgram") And Not FillingData.TargetProgram.IsEmpty() Then
		TargetProgram = FillingData.TargetProgram;
	EndIf;
	If FillingData.Property("ApprovalLevel") And Not FillingData.ApprovalLevel.IsEmpty() Then
		ApprovalLevel = FillingData.ApprovalLevel;
	EndIf;

	Date = CurrentSessionDate();

	If Decision.IsEmpty() Then
		Decision = Enums.ApprovalDecision.Approved;
	EndIf;

	If IsBlankString(CouncilSession) Then
		LevelText = "";
		If ApprovalLevel = Enums.ApprovalLevel.FacultyCouncil Then
			LevelText = "HĐKH Khoa";
		ElsIf ApprovalLevel = Enums.ApprovalLevel.InstitutionalCouncil Then
			LevelText = "HĐKHĐT Trường";
		ElsIf ApprovalLevel = Enums.ApprovalLevel.Issued Then
			LevelText = "Quyết định ban hành";
		EndIf;
		CouncilSession = "Phiên " + LevelText + " " + Format(CurrentSessionDate(), "DF=dd/MM/yyyy");
	EndIf;

	If Status.IsEmpty() Then
		If ApprovalLevel = Enums.ApprovalLevel.Issued Then
			Status = Enums.ProgramStatuses.Issued;
		Else
			Status = Enums.ProgramStatuses.Approved;
		EndIf;
	EndIf;
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If TargetProgram.IsEmpty() Then
		ShowError("Vui lòng chọn CTĐT cần phê duyệt.", "TargetProgram", Cancel);
	EndIf;
	If Decision = Enums.ApprovalDecision.RequiresRevision And IsBlankString(RevisionNotes) Then
		ShowError("Vui lòng ghi rõ nội dung yêu cầu chỉnh sửa.", "RevisionNotes", Cancel);
	EndIf;
	If ApprovalLevel = Enums.ApprovalLevel.Issued And IssuanceDecision.IsEmpty() Then
		ShowError("Vui lòng chọn Quyết định ban hành căn cứ.", "IssuanceDecision", Cancel);
	EndIf;
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	If WriteMode <> DocumentWriteMode.Posting Then
		Return;
	EndIf;

	If IsSystemAdmin() Then
		Return;
	EndIf;

	CurrentLecturer = GetCurrentUserLecturer();
	If CurrentLecturer.IsEmpty() Then
		ShowError("Không xác định được giảng viên ứng với tài khoản đăng nhập."
			+ " Vui lòng kiểm tra mã giảng viên (Lecturer.Code) trùng với Login.", "", Cancel);
		Return;
	EndIf;

	UserRole = CurrentLecturer.Role;

	If ApprovalLevel = Enums.ApprovalLevel.FacultyCouncil Then
		If UserRole <> Enums.PerformerRoles.Head Then
			ShowError("Chỉ Trưởng Bộ môn / Trưởng Khoa mới có quyền phê duyệt ở cấp Khoa.", "ApprovalLevel", Cancel);
		EndIf;
	ElsIf ApprovalLevel = Enums.ApprovalLevel.InstitutionalCouncil Then
		If UserRole <> Enums.PerformerRoles.InstitutionalHead Then
			ShowError("Chỉ Phó Giám đốc / HĐKHĐT Trường mới có quyền thẩm định ở cấp Trường.", "ApprovalLevel", Cancel);
		EndIf;
	ElsIf ApprovalLevel = Enums.ApprovalLevel.Issued Then
		If UserRole <> Enums.PerformerRoles.Dean Then
			ShowError("Chỉ Giám đốc mới có quyền ký quyết định ban hành.", "ApprovalLevel", Cancel);
		EndIf;
	EndIf;
EndProcedure

Function IsSystemAdmin()
	CurrentUser = InfoBaseUsers.CurrentUser();
	If CurrentUser = Undefined Then
		Return False;
	EndIf;
	FullAccessRole = Metadata.Roles.Find("FullAccess");
	If FullAccessRole <> Undefined And CurrentUser.Roles.Contains(FullAccessRole) Then
		Return True;
	EndIf;
	SysAdminRole = Metadata.Roles.Find("SystemAdmin");
	If SysAdminRole <> Undefined And CurrentUser.Roles.Contains(SysAdminRole) Then
		Return True;
	EndIf;
	Return False;
EndFunction

Function GetCurrentUserLecturer()
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

Procedure ShowError(Text, Field, Cancel)
	Msg = New UserMessage();
	Msg.Text = Text;
	Msg.Field = Field;
	Msg.Message();
	Cancel = True;
EndProcedure

Procedure Posting(Cancel, PostingMode)
	ResolvedStatus = Status;
	If ResolvedStatus.IsEmpty() Then
		If ApprovalLevel = Enums.ApprovalLevel.Issued Then
			ResolvedStatus = Enums.ProgramStatuses.Issued;
		ElsIf Decision = Enums.ApprovalDecision.Approved Then
			ResolvedStatus = Enums.ProgramStatuses.Approved;
		Else
			ResolvedStatus = Enums.ProgramStatuses.UnderReview;
		EndIf;
	EndIf;

	RegisterRecords.ProgramValidity.Write = True;
	Record = RegisterRecords.ProgramValidity.Add();
	Record.Period = Date;
	Record.TrainingProgram = TargetProgram;
	Record.Status = ResolvedStatus;
	If Not IssuanceDecision.IsEmpty() Then
		Record.IssuanceDecision = IssuanceDecision;
	EndIf;
	Record.Note = CouncilSession;

	UpdateProgramStatus(TargetProgram, ResolvedStatus, IssuanceDecision);

	Msg = New UserMessage();
	Msg.Text = "Đã ghi nhận phê duyệt. Vui lòng mở 'Nhiệm vụ của tôi' và đánh dấu task tương ứng"
		+ " là Hoàn thành để chuyển sang bước tiếp theo.";
	Msg.Message();
EndProcedure

Procedure UpdateProgramStatus(ProgramRef, NewStatus, IssDec)
	If ProgramRef.IsEmpty() Then
		Return;
	EndIf;
	ProgObj = ProgramRef.GetObject();
	If ProgObj = Undefined Then
		Return;
	EndIf;
	ProgObj.Status = NewStatus;
	If Not IssDec.IsEmpty() Then
		ProgObj.DecisionNumber = IssDec.Code;
	EndIf;
	ProgObj.Write();
EndProcedure
