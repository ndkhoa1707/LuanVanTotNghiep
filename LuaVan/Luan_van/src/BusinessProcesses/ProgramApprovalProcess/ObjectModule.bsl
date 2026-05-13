////////////////////////////////////////////////////////////////////////////////
// BusinessProcess.ProgramApprovalProcess - Object Module
//   • 4 BeforeCreateTasks handlers (T1-T4):
//     - Set Performer động theo Role qua WorkflowAddressing
//     - Lưu ý: trong trường hợp TasksBeingFormed.Count() = 0 ở thời điểm call,
//       việc fill Performer/Description sẽ được Task.BeforeWrite handler đảm nhiệm
//   • 4 Condition handlers: rẽ nhánh BP theo Decision của ProgramApproval mới nhất
////////////////////////////////////////////////////////////////////////////////

#Region TaskCreationHandlers

// T1 - Soạn đề xuất CTĐT
Procedure PrepareProposalBeforeCreateTasks(RoutePoint, TasksBeingFormed, StandardProcessing)
	Performer = WorkflowAddressing.GetProposerOfProgram(TargetProgram);
	If Performer.IsEmpty() Then
		Faculty = GetProposingFacultyOrDefault();
		Performer = WorkflowAddressing.FindAnyLecturerInFaculty(Faculty);
	EndIf;
	For Each Task In TasksBeingFormed Do
		Task.Performer = Performer;
		Task.Description = "T1 - Soạn đề xuất CTĐT";
	EndDo;
EndProcedure

// T2 - HĐKH Khoa phê duyệt
Procedure FacultyCouncilReviewBeforeCreateTasks(RoutePoint, TasksBeingFormed, StandardProcessing)
	Faculty = GetProposingFacultyOrDefault();
	Performer = WorkflowAddressing.FindHead(Faculty);
	For Each Task In TasksBeingFormed Do
		Task.Performer = Performer;
		Task.Description = "T2 - HĐKH Khoa phê duyệt CTĐT";
	EndDo;
EndProcedure

// T3 - HĐKHĐT Trường thẩm định
Procedure InstitutionalReviewBeforeCreateTasks(RoutePoint, TasksBeingFormed, StandardProcessing)
	Performer = WorkflowAddressing.FindInstitutionalHead();
	For Each Task In TasksBeingFormed Do
		Task.Performer = Performer;
		Task.Description = "T3 - HĐKHĐT Trường thẩm định CTĐT";
	EndDo;
EndProcedure

// T4 - Trình Giám đốc ký QĐ ban hành
Procedure IssueDecisionBeforeCreateTasks(RoutePoint, TasksBeingFormed, StandardProcessing)
	Performer = WorkflowAddressing.FindDean();
	For Each Task In TasksBeingFormed Do
		Task.Performer = Performer;
		Task.Description = "T4 - Trình Giám đốc ký QĐ ban hành";
	EndDo;
EndProcedure

#EndRegion

#Region ConditionHandlers

// Sau T2 (HĐKH Khoa): Approved?
//   Yes → T3 (đi tiếp lên Trường)
//   No  → Cond2 (check tiếp)
Procedure IsApprovedConditionCheck(RoutePoint, Result)
	LatestDecision = GetLatestDecision(Enums.ApprovalLevel.FacultyCouncil);
	Result = (LatestDecision = Enums.ApprovalDecision.Approved);
EndProcedure

// Sau Cond1 (No): RequiresRevision?
//   Yes → T1 (quay lại sửa)
//   No  → End (Rejected)
Procedure NeedsRevisionConditionCheck(RoutePoint, Result)
	LatestDecision = GetLatestDecision(Enums.ApprovalLevel.FacultyCouncil);
	Result = (LatestDecision = Enums.ApprovalDecision.RequiresRevision);
EndProcedure

// Sau T3 (HĐKHĐT Trường): Approved?
//   Yes → T4 (ban hành)
//   No  → Cond4
Procedure IsApprovedInstConditionCheck(RoutePoint, Result)
	LatestDecision = GetLatestDecision(Enums.ApprovalLevel.InstitutionalCouncil);
	Result = (LatestDecision = Enums.ApprovalDecision.Approved);
EndProcedure

// Sau Cond3 (No): RequiresRevision?
//   Yes → T1 (quay lại sửa từ đầu)
//   No  → End (Rejected)
Procedure NeedsRevisionInstConditionCheck(RoutePoint, Result)
	LatestDecision = GetLatestDecision(Enums.ApprovalLevel.InstitutionalCouncil);
	Result = (LatestDecision = Enums.ApprovalDecision.RequiresRevision);
EndProcedure

#EndRegion

#Region Helpers

// Lấy Decision mới nhất của ProgramApproval cho CTĐT này tại cấp Level
Function GetLatestDecision(Level)
	If TargetProgram.IsEmpty() Then
		Return Enums.ApprovalDecision.EmptyRef();
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ProgramApproval.Decision AS Decision
	|FROM
	|	Document.ProgramApproval AS ProgramApproval
	|WHERE
	|	ProgramApproval.TargetProgram = &TargetProgram
	|	AND ProgramApproval.ApprovalLevel = &Level
	|	AND ProgramApproval.Posted = TRUE
	|ORDER BY
	|	ProgramApproval.Date DESC";
	Query.SetParameter("TargetProgram", TargetProgram);
	Query.SetParameter("Level", Level);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Decision;
	EndIf;
	Return Enums.ApprovalDecision.EmptyRef();
EndFunction

// Lookup Faculty đề xuất từ ProgramProposal mới nhất, fallback CNTT1 nếu chưa có
Function GetProposingFacultyOrDefault()
	If Not TargetProgram.IsEmpty() Then
		Faculty = WorkflowAddressing.GetProposingFaculty(TargetProgram);
		If Not Faculty.IsEmpty() Then
			Return Faculty;
		EndIf;
	EndIf;
	Return Catalogs.Faculties.FindByCode("CNTT1");
EndFunction

#EndRegion
