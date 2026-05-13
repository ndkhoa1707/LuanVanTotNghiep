////////////////////////////////////////////////////////////////////////////////
// ProgramProposal - Object Module
//   • FillCheckProcessing: validate fields trước khi post
//   • Posting:
//       - Ghi IR ProgramValidity (lịch sử trạng thái)
//       - Update Status của Catalog.TrainingPrograms
//       - Tự động tạo + Start BusinessProcess.ProgramApprovalProcess
//         (nếu chưa có BP đang chạy cho CTĐT này)
////////////////////////////////////////////////////////////////////////////////

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If TargetProgram.IsEmpty() Then
		ShowError("Vui lòng chọn CTĐT đề xuất.", "TargetProgram", Cancel);
	EndIf;
	If Proposer.IsEmpty() Then
		ShowError("Vui lòng chọn người đề xuất.", "Proposer", Cancel);
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
	ResolvedStatus = ?(Status.IsEmpty(), Enums.ProgramStatuses.UnderReview, Status);

	// Ghi IR ProgramValidity
	RegisterRecords.ProgramValidity.Write = True;
	Record = RegisterRecords.ProgramValidity.Add();
	Record.Period = Date;
	Record.TrainingProgram = TargetProgram;
	Record.Status = ResolvedStatus;
	Record.Note = ProposalSummary;

	// Cập nhật trạng thái Catalog
	SetPrivilegedMode(True);
	UpdateProgramStatus(TargetProgram, ResolvedStatus);

	// Đảm bảo có BP đang chạy cho CTĐT
	EnsureWorkflowStarted();
	SetPrivilegedMode(False);

	NotifyUserOfTask();
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

// Tạo BP mới nếu chưa có BP đang chạy cho TargetProgram
Procedure EnsureWorkflowStarted()
	If TargetProgram.IsEmpty() Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	BP.Ref AS Ref,
	|	BP.Started AS Started
	|FROM
	|	BusinessProcess.ProgramApprovalProcess AS BP
	|WHERE
	|	BP.TargetProgram = &Program
	|	AND BP.Completed = FALSE
	|ORDER BY BP.Date DESC";
	Query.SetParameter("Program", TargetProgram);

	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Started Then
		// BP đã tồn tại, không tạo mới
		Return;
	EndIf;

	BPObj = BusinessProcesses.ProgramApprovalProcess.CreateBusinessProcess();
	BPObj.Date = CurrentSessionDate();
	BPObj.TargetProgram = TargetProgram;
	BPObj.Write();
	BPObj.Start();
EndProcedure

// Thông báo cho người dùng task T1 đã được tạo
Procedure NotifyUserOfTask()
	Msg = New UserMessage();
	Msg.Text = "Đã ghi nhận đề xuất CTĐT. Vui lòng mở 'Nhiệm vụ của tôi' và hoàn thành"
		+ " task 'T1 - Soạn đề xuất CTĐT' để chuyển sang bước phê duyệt cấp Khoa.";
	Msg.Message();
EndProcedure
