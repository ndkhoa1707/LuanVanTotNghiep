////////////////////////////////////////////////////////////////////////////////
// Task.ProgramApprovalTasks - Object Module
// BeforeWrite: nếu task vừa được BP tạo nhưng Performer + Description trống,
//   tự động fill dựa trên RoutePoint name.
//   Lý do: BeforeCreateTasks handler trong BP không hoạt động (TasksBeingFormed.Count=0).
////////////////////////////////////////////////////////////////////////////////

Procedure BeforeWrite(Cancel, WriteMode)
	// Chỉ fill khi RoutePoint đã được set
	If Not ValueIsFilled(RoutePoint) Then
		Return;
	EndIf;

	RPName = String(RoutePoint);

	// Fill Description nếu trống hoặc đang là default (= RoutePoint name)
	If IsBlankString(Description) Or Description = RPName Then
		Description = LookupDescription(RPName);
	EndIf;

	// Fill Performer nếu trống
	If Not ValueIsFilled(Performer) Then
		Performer = LookupPerformer(RPName);
	EndIf;
EndProcedure

Function LookupDescription(RPName)
	If RPName = "PrepareProposal" Then
		Return "T1 - Soạn đề xuất CTĐT";
	ElsIf RPName = "FacultyCouncilReview" Then
		Return "T2 - HĐKH Khoa phê duyệt CTĐT";
	ElsIf RPName = "InstitutionalReview" Then
		Return "T3 - HĐKHĐT Trường thẩm định CTĐT";
	ElsIf RPName = "IssueDecision" Then
		Return "T4 - Trình Giám đốc ký QĐ ban hành";
	EndIf;
	Return RPName;
EndFunction

Function LookupPerformer(RPName)
	// Lấy TargetProgram từ BP của task
	TargetProgram = Catalogs.TrainingPrograms.EmptyRef();
	If ValueIsFilled(BusinessProcess) Then
		TargetProgram = BusinessProcess.TargetProgram;
	EndIf;

	If RPName = "PrepareProposal" Then
		Return WorkflowAddressing.GetProposerOfProgram(TargetProgram);
	ElsIf RPName = "FacultyCouncilReview" Then
		Return WorkflowAddressing.FindHead(WorkflowAddressing.GetProposingFaculty(TargetProgram));
	ElsIf RPName = "InstitutionalReview" Then
		Return WorkflowAddressing.FindInstitutionalHead();
	ElsIf RPName = "IssueDecision" Then
		Return WorkflowAddressing.FindDean();
	EndIf;
	Return Catalogs.Lecturers.EmptyRef();
EndFunction
