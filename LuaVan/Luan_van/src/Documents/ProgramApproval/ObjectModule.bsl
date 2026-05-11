////////////////////////////////////////////////////////////////////////////////
// ProgramApproval - Object Module
// - FillCheckProcessing: validate fields
//   + Decision=RequiresRevision → RevisionNotes bắt buộc
//   + ApprovalLevel=Issued → IssuanceDecision bắt buộc
// - Posting: ghi IR ProgramValidity + sync Catalog.Status
////////////////////////////////////////////////////////////////////////////////

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If TargetProgram.IsEmpty() Then
		ShowError("CTĐT bắt buộc.", "TargetProgram", Cancel);
	EndIf;
	If Decision = Enums.ApprovalDecision.RequiresRevision And IsBlankString(RevisionNotes) Then
		ShowError("Decision=RequiresRevision → RevisionNotes bắt buộc.", "RevisionNotes", Cancel);
	EndIf;
	If ApprovalLevel = Enums.ApprovalLevel.Issued And IssuanceDecision.IsEmpty() Then
		ShowError("ApprovalLevel=Issued → IssuanceDecision bắt buộc.", "IssuanceDecision", Cancel);
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

	// Sync Catalog.TrainingPrograms.Status + IssuanceDecision (nếu Issued)
	UpdateProgramStatus(TargetProgram, ResolvedStatus, IssuanceDecision);
EndProcedure

Procedure UpdateProgramStatus(ProgramRef, NewStatus, IssDec)
	If ProgramRef.IsEmpty() Then
		Return;
	EndIf;
	ProgObj = ProgramRef.GetObject();
	If ProgObj = Undefined Then
		Return;
	EndIf;
	ProgObj.Status = NewStatus;
	If Not IssDec.IsEmpty() Then
		// Catalog có DecisionNumber String field, dùng Decision Code
		ProgObj.DecisionNumber = IssDec.Code;
	EndIf;
	ProgObj.Write();
EndProcedure
