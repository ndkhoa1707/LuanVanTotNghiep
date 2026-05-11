////////////////////////////////////////////////////////////////////////////////
// ProgramProposal - Module đối tượng
// Posting: Khi cán bộ khoa gửi đề xuất CTĐT, tạo bản ghi vào:
//   - ProgramValidity: trạng thái CTĐT chuyển sang UnderReview
//   - ApprovalLog: ghi audit log
////////////////////////////////////////////////////////////////////////////////

Procedure Posting(Cancel, PostingMode)
	// Ghi ProgramValidity: CTĐT chuyển sang UnderReview
	Movement = RegisterRecords.ProgramValidity.Add();
	Movement.Period = Date;
	Movement.TrainingProgram = TargetProgram;
	Movement.Status = Enums.ProgramStatuses.UnderReview;
	Movement.EffectiveDate = Date;

	// Ghi ApprovalLog: audit trail
	Movement = RegisterRecords.ApprovalLog.Add();
	Movement.SourceDocument = Ref;
	Movement.Performer = Proposer;
	Movement.Action = "Submit";
	Movement.TargetProgram = TargetProgram;
	Movement.TimeStamp = CurrentDate();
EndProcedure

Procedure UndoPosting(Cancel)
	// Khi unpost - các bản ghi RecorderSubordinate sẽ auto-delete
	// Có thể thêm logic rollback Status nếu cần
EndProcedure
