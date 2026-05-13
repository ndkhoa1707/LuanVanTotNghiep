////////////////////////////////////////////////////////////////////////////////
// Catalog.Decisions - Object Module
// Filling: nhận FillingValues khi mở form từ Task CreateDecisions command
//   - Description, IssueDate, EffectiveDate, Signer được auto-fill
////////////////////////////////////////////////////////////////////////////////

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If IsBlankString(Description) Then
		Msg = New UserMessage();
		Msg.Text = "Vui lòng nhập Trích yếu Quyết định.";
		Msg.Field = "Description";
		Msg.Message();
		Cancel = True;
	EndIf;
	If Not ValueIsFilled(IssueDate) Then
		Msg = New UserMessage();
		Msg.Text = "Vui lòng nhập Ngày ban hành.";
		Msg.Field = "IssueDate";
		Msg.Message();
		Cancel = True;
	EndIf;
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	If TypeOf(FillingData) <> Type("Structure") Then
		Return;
	EndIf;

	If FillingData.Property("Description") And Not IsBlankString(FillingData.Description) Then
		Description = FillingData.Description;
	EndIf;

	If FillingData.Property("IssueDate") And ValueIsFilled(FillingData.IssueDate) Then
		IssueDate = FillingData.IssueDate;
	EndIf;

	If FillingData.Property("EffectiveDate") And ValueIsFilled(FillingData.EffectiveDate) Then
		EffectiveDate = FillingData.EffectiveDate;
	EndIf;

	If FillingData.Property("Signer") And ValueIsFilled(FillingData.Signer) Then
		Signer = FillingData.Signer;
	EndIf;
EndProcedure
