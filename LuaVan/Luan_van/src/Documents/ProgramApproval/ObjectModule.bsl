////////////////////////////////////////////////////////////////////////////////
// ProgramApproval - Module đối tượng
// Posting: Cập nhật trạng thái CTĐT dựa trên ApprovalLevel + Decision
////////////////////////////////////////////////////////////////////////////////

Procedure Posting(Cancel, PostingMode)
	// Status xác định từ field NewStatus của Document. Nếu chưa set,
	// fallback theo logic: Issued nếu Lvl=Issued, Approved nếu Decision=Approved
	ResolvedStatus = NewStatus;
	If ResolvedStatus.IsEmpty() Then
		If ApprovalLevel = Enums.ApprovalLevel.Issued Then
			ResolvedStatus = Enums.ProgramStatuses.Issued;
		ElsIf Decision = Enums.ApprovalDecision.Approved Then
			ResolvedStatus = Enums.ProgramStatuses.Approved;
		Else
			ResolvedStatus = Enums.ProgramStatuses.UnderReview;
		EndIf;
	EndIf;

	// Ghi ProgramValidity
	Movement = RegisterRecords.ProgramValidity.Add();
	Movement.Period = Date;
	Movement.TrainingProgram = TargetProgram;
	Movement.Status = ResolvedStatus;
	Movement.EffectiveDate = Date;
	If Not IssuanceDecision.IsEmpty() Then
		Movement.IssuanceDecision = IssuanceDecision;
	EndIf;

	// Ghi ApprovalLog
	Movement = RegisterRecords.ApprovalLog.Add();
	Movement.SourceDocument = Ref;
	DefaultPerformer = Catalogs.Lecturers.FindByCode("GV0001");
	Movement.Performer = ?(DefaultPerformer.IsEmpty(), Catalogs.Lecturers.EmptyRef(), DefaultPerformer);
	Movement.Action = ?(Decision = Enums.ApprovalDecision.Approved, "Approve",
		?(Decision = Enums.ApprovalDecision.RequiresRevision, "RequiresRevision", "Reject"));
	Movement.TargetProgram = TargetProgram;
	Movement.TimeStamp = CurrentDate();
EndProcedure

Procedure UndoPosting(Cancel)
EndProcedure
