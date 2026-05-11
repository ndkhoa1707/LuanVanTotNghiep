////////////////////////////////////////////////////////////////////////////////
// ProgramApproval - Module đối tượng
// Posting: Cập nhật trạng thái CTĐT trong IR ProgramValidity
//   Status = Document.Status (nếu set), nếu không fallback theo logic:
//   - ApprovalLevel=Issued → Issued
//   - Decision=Approved → Approved
//   - khác → UnderReview
////////////////////////////////////////////////////////////////////////////////

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
EndProcedure


