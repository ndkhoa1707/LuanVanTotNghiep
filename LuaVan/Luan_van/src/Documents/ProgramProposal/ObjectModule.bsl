////////////////////////////////////////////////////////////////////////////////
// ProgramProposal - Module đối tượng
// Posting: Khi cán bộ khoa gửi đề xuất CTĐT, tạo bản ghi vào ProgramValidity
//   với Status = Document.Status (mặc định UnderReview nếu chưa set)
////////////////////////////////////////////////////////////////////////////////

Procedure Posting(Cancel, PostingMode)
	RegisterRecords.ProgramValidity.Write = True;
	Record = RegisterRecords.ProgramValidity.Add();
	Record.Period = Date;
	Record.TrainingProgram = TargetProgram;
	Record.Status = ?(Status.IsEmpty(), Enums.ProgramStatuses.UnderReview, Status);
	Record.Note = ProposalSummary;
EndProcedure

