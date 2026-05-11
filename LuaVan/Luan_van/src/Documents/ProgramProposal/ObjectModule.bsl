////////////////////////////////////////////////////////////////////////////////
// ProgramProposal - Object Module
// - FillCheckProcessing: validate fields trước khi post
// - Posting: ghi vào IR ProgramValidity + sync Catalog.TrainingPrograms.Status
////////////////////////////////////////////////////////////////////////////////

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If TargetProgram.IsEmpty() Then
		Msg = New UserMessage();
		Msg.Text = "CTĐT đề xuất bắt buộc.";
		Msg.Field = "TargetProgram";
		Msg.Message();
		Cancel = True;
	EndIf;
	If Proposer.IsEmpty() Then
		Msg = New UserMessage();
		Msg.Text = "Người đề xuất bắt buộc.";
		Msg.Field = "Proposer";
		Msg.Message();
		Cancel = True;
	EndIf;
EndProcedure

Procedure Posting(Cancel, PostingMode)
	ResolvedStatus = ?(Status.IsEmpty(), Enums.ProgramStatuses.UnderReview, Status);

	// 1. Ghi IR ProgramValidity
	RegisterRecords.ProgramValidity.Write = True;
	Record = RegisterRecords.ProgramValidity.Add();
	Record.Period = Date;
	Record.TrainingProgram = TargetProgram;
	Record.Status = ResolvedStatus;
	Record.Note = ProposalSummary;

	// 2. Sync Catalog.TrainingPrograms.Status (cached current state)
	UpdateProgramStatus(TargetProgram, ResolvedStatus);
EndProcedure

Procedure UpdateProgramStatus(ProgramRef, NewStatus)
	If ProgramRef.IsEmpty() Then
		Return;
	EndIf;
	ProgObj = ProgramRef.GetObject();
	If ProgObj <> Undefined Then
		ProgObj.Status = NewStatus;
		ProgObj.Write();
	EndIf;
EndProcedure
