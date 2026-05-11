////////////////////////////////////////////////////////////////////////////////
// ProgramAmendment - Module đối tượng
// Posting: Cập nhật trạng thái CTĐT dựa trên AmendmentType
////////////////////////////////////////////////////////////////////////////////

Procedure Posting(Cancel, PostingMode)
	// Xác định trạng thái mới
	NewStatus = Enums.ProgramStatuses.Issued;
	If AmendmentType = Enums.AmendmentType.Deactivation Then
		NewStatus = Enums.ProgramStatuses.Deactivated;
	ElsIf AmendmentType = Enums.AmendmentType.MajorAmendment Then
		NewStatus = Enums.ProgramStatuses.UnderReview;
	EndIf;

	// Ghi ProgramValidity
	Movement = RegisterRecords.ProgramValidity.Add();
	Movement.Period = Date;
	Movement.TrainingProgram = TargetProgram;
	Movement.Status = NewStatus;
	Movement.EffectiveDate = ?(EffectiveDate = '00010101', Date, EffectiveDate);

	// Ghi ApprovalLog
	Movement = RegisterRecords.ApprovalLog.Add();
	Movement.SourceDocument = Ref;
	DefaultPerformer = Catalogs.Lecturers.FindByCode("GV0001");
	Movement.Performer = ?(DefaultPerformer.IsEmpty(), Catalogs.Lecturers.EmptyRef(), DefaultPerformer);
	If AmendmentType = Enums.AmendmentType.Deactivation Then
		Movement.Action = "Deactivate";
	ElsIf AmendmentType = Enums.AmendmentType.MajorAmendment Then
		Movement.Action = "MajorAmend";
	ElsIf AmendmentType = Enums.AmendmentType.MinorAmendment Then
		Movement.Action = "MinorAmend";
	Else
		Movement.Action = "AnnualReview";
	EndIf;
	Movement.TargetProgram = TargetProgram;
	Movement.TimeStamp = CurrentDate();
EndProcedure

Procedure UndoPosting(Cancel)
EndProcedure
