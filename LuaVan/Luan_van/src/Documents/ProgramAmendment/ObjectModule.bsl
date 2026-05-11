////////////////////////////////////////////////////////////////////////////////
// ProgramAmendment - Module đối tượng
// Posting: Cập nhật trạng thái CTĐT trong IR ProgramValidity
//   Status = Document.Status (nếu set), nếu không fallback theo AmendmentType:
//   - Deactivation → Deactivated
//   - MajorAmendment → UnderReview
//   - Minor/AnnualReview → Issued
////////////////////////////////////////////////////////////////////////////////

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
EndProcedure

Procedure UndoPosting(Cancel)
EndProcedure
