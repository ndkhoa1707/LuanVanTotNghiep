
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Ẩn command CreateDecisions nếu user không thuộc AcademicAffairsOffice (PĐT)
	If Not CurrentUserHasRole("AcademicAffairsOffice") Then
		If Items.Find("FormCreateDecisions") <> Undefined Then
			Items.FormCreateDecisions.Visible = False;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function CurrentUserHasRole(RoleName)
	User = InfoBaseUsers.CurrentUser();
	If User = Undefined Then
		Return False;
	EndIf;
	// FullAccess / SystemAdmin coi như có tất cả role
	FullAccess = Metadata.Roles.Find("FullAccess");
	If FullAccess <> Undefined And User.Roles.Contains(FullAccess) Then
		Return True;
	EndIf;
	SysAdmin = Metadata.Roles.Find("SystemAdmin");
	If SysAdmin <> Undefined And User.Roles.Contains(SysAdmin) Then
		Return True;
	EndIf;
	RoleMeta = Metadata.Roles.Find(RoleName);
	If RoleMeta = Undefined Then
		Return False;
	EndIf;
	Return User.Roles.Contains(RoleMeta);
EndFunction

&AtClient
Procedure CreateApprovalDoc(Command)
	OpenApprovalFromTask();
EndProcedure

&AtServer
Function GetContext()
	Return WorkflowAddressing.GetApprovalContextFromTask(Object.Ref);
EndFunction

&AtClient
Procedure OpenApprovalFromTask()
	Ctx = GetContext();
	If Ctx.TargetProgram.IsEmpty() Then
		ShowMessageBox(, "Nhiệm vụ này chưa gắn với CTĐT cụ thể, không thể tạo phê duyệt.");
		Return;
	EndIf;
	FillingValues = New Structure;
	FillingValues.Insert("TargetProgram", Ctx.TargetProgram);
	FillingValues.Insert("ApprovalLevel", Ctx.ApprovalLevel);
	OpenForm("Document.ProgramApproval.ObjectForm",
		New Structure("FillingValues", FillingValues),
		ThisObject);
EndProcedure

&AtClient
Procedure CreateDecisions(Command)
	OpenDecisionFromTask();
EndProcedure

&AtServer
Function GetDecisionFillingValues()
	Result = New Structure;
	Ctx = WorkflowAddressing.GetApprovalContextFromTask(Object.Ref);
	If Ctx.TargetProgram.IsEmpty() Then
		Return Result;
	EndIf;

	Program = Ctx.TargetProgram;

	// Description = "Quyết định ban hành CTĐT [Tên CTĐT]"
	Result.Insert("Description", "Quyết định ban hành CTĐT " + String(Program));

	// IssueDate = today, EffectiveDate = today + 30 ngày (mặc định)
	Today = CurrentSessionDate();
	Result.Insert("IssueDate", Today);
	Result.Insert("EffectiveDate", Today);

	// Signer = Giám đốc (Role=Dean)
	Result.Insert("Signer", WorkflowAddressing.FindDean());

	Return Result;
EndFunction

&AtClient
Procedure OpenDecisionFromTask()
	FillingValues = GetDecisionFillingValues();
	If FillingValues.Count() = 0 Then
		ShowMessageBox(, "Nhiệm vụ này chưa gắn với CTĐT cụ thể, không thể tạo Quyết định ban hành.");
		Return;
	EndIf;
	OpenForm("Catalog.Decisions.ObjectForm",
		New Structure("FillingValues", FillingValues),
		ThisObject);
EndProcedure
