////////////////////////////////////////////////////////////////////////////////
// ProgramAmendment - Object Module
// - FillCheckProcessing: validate
//   + Deactivation/MajorAmendment → SupportingDecision bắt buộc
//   + AnnualReview → ReviewYear bắt buộc
// - Posting: ghi IR ProgramValidity + sync Catalog.Status
////////////////////////////////////////////////////////////////////////////////

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If TargetProgram.IsEmpty() Then
		ShowError("CTĐT bắt buộc.", "TargetProgram", Cancel);
	EndIf;
	If (AmendmentType = Enums.AmendmentType.Deactivation
		Or AmendmentType = Enums.AmendmentType.MajorAmendment)
		And SupportingDecision.IsEmpty() Then
		ShowError("Sửa đổi lớn / Ngừng hiệu lực phải có QĐ căn cứ.", "SupportingDecision", Cancel);
	EndIf;
	If AmendmentType = Enums.AmendmentType.AnnualReview And ReviewYear.IsEmpty() Then
		ShowError("Rà soát hằng năm phải có ReviewYear.", "ReviewYear", Cancel);
	EndIf;
EndProcedure

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
		If AmendmentType = Enums.AmendmentType.Deactivation Then
			ResolvedStatus = Enums.ProgramStatuses.Deactivated;
		ElsIf AmendmentType = Enums.AmendmentType.MajorAmendment Then
			ResolvedStatus = Enums.ProgramStatuses.UnderReview;
		Else
			ResolvedStatus = Enums.ProgramStatuses.Issued;
		EndIf;
	EndIf;

	RegisterRecords.ProgramValidity.Write = True;
	Record = RegisterRecords.ProgramValidity.Add();
	Record.Period = ?(EffectiveDate = '00010101', Date, EffectiveDate);
	Record.TrainingProgram = TargetProgram;
	Record.Status = ResolvedStatus;
	If Not SupportingDecision.IsEmpty() Then
		Record.IssuanceDecision = SupportingDecision;
	EndIf;
	Record.Note = AmendmentSummary;

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
