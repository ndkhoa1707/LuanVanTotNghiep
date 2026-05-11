# Hướng dẫn hoàn thiện phân hệ QLĐT v5 trong 1C:EDT

Tài liệu này hướng dẫn từng bước những việc còn lại cần làm **trực tiếp trong 1C:EDT GUI** để hoàn thiện hệ thống. Các phần đã làm xong qua XML/BSL (Phase 1-11) không nằm trong tài liệu này.

**Trạng thái hệ thống hiện tại** (commit `676b22f`):
- 8 Catalogs, 4 Enums, 3 Constants, 2 Subsystems, 4 Roles
- 1 FunctionalOption, 3 Documents (có Posting + validation), 1 IR, 2 Reports stub
- 2 DataProcessors stub, 1 BusinessProcess stub, 1 Task có addressing
- 1 CommonModule InitialDataFill (sample data PTIT)

---

## Mục lục

1. [BusinessProcess Route Map](#1-businessprocess-route-map) 🔴 BẮT BUỘC
2. [DCS Schema cho 2 Reports](#2-dcs-schema-cho-2-reports) 🔴 BẮT BUỘC
3. [Rights chi tiết cho 4 Roles](#3-rights-chi-tiết-cho-4-roles) 🔴 BẮT BUỘC
4. [Custom Forms cho 3 Documents](#4-custom-forms-cho-3-documents) 🟡 NÊN CÓ
5. [DataProcessor ImportFromExcel](#5-dataprocessor-importfromexcel) 🟡 NÊN CÓ
6. [Print form QĐ Ban hành](#6-print-form-qđ-ban-hành) 🟢 TUỲ CHỌN
7. [Checklist final trước bảo vệ](#checklist-final)

---

## 1. BusinessProcess Route Map

**Mục đích**: Vẽ workflow tự động: khi Document phê duyệt được post, hệ thống tự sinh Task cho người thực hiện bước tiếp theo. Thay vì gán Task thủ công như sample data hiện tại.

**Thời gian**: ~30-45 phút

### Bước 1: Mở Route Map

1. Trong **Project Explorer** (EDT) → expand:
   `Luan_van → BusinessProcesses → ProgramApprovalProcess`
2. Right-click `ProgramApprovalProcess` → **Open**
3. Chọn tab **Route map** (hoặc **Карта маршрута**)

### Bước 2: Thiết kế Workflow

Vẽ sơ đồ theo cấu trúc sau:

```
┌────────┐    ┌──────────────────┐    ┌──────────────────────┐
│ Start  │───>│ T1: PrepareProp  │───>│ T2: FacultyCouncil   │
└────────┘    └──────────────────┘    └──────────────────────┘
                       ▲                          │
                       │                          ▼
                       │              ┌──────────────────────┐
                       │              │ Cond: Decision?      │
                       │              └──────────────────────┘
                       │                  │      │      │
                       │   Approved───────┘      │      └──Rejected
                       │                         │              │
                       │                  RequiresRevision      │
                       │                         │              ▼
                       │<────────────────────────┘         ┌────────┐
                       │                                    │  End   │
                       │              ┌──────────────────┐  └────────┘
                       │              │ T3: Institutional│
                       │              │    Review        │
                       │              └──────────────────┘
                       │                       │
                       │                       ▼
                       │              ┌──────────────────┐
                       │              │ Cond: Decision?  │
                       │              └──────────────────┘
                       │                  │      │      │
                       │   Approved───────┘      │      └──Rejected
                       │                         │              │
                       │                  RequiresRevision      │
                       │<────────────────────────┘              ▼
                                                          ┌────────┐
                                         ┌──────────────┐ │  End   │
                                         │ T4: Issue    │ └────────┘
                                         │   Decision   │
                                         └──────────────┘
                                                 │
                                                 ▼
                                          ┌────────┐
                                          │  End   │
                                          └────────┘
```

### Bước 3: Thao tác cụ thể

1. **Từ Palette** (thường ở góc phải), kéo các shape vào canvas:
   - **Start point** (vòng tròn xanh) — 1 cái
   - **Action point** (hình chữ nhật) — 4 cái, đặt tên T1, T2, T3, T4
   - **Condition** (hình thoi) — 2 cái (đặt sau T2 và T3)
   - **End point** (vòng tròn đỏ) — 1 hoặc nhiều

2. **Đặt tên action points** (double-click vào hình):
   - T1 → Name: `PrepareProposal`, Synonym: "Soạn đề xuất CTĐT"
   - T2 → Name: `FacultyCouncilReview`, Synonym: "HĐKH Khoa phê duyệt"
   - T3 → Name: `InstitutionalReview`, Synonym: "HĐKHĐT Trường phê duyệt"
   - T4 → Name: `IssueDecision`, Synonym: "Ký QĐ ban hành"

3. **Gán Task addressing cho mỗi action point**:
   - T1 → Properties → Addressing → Performer = (để trống, sẽ điền ở instance)
   - Hoặc gán role: T1 → Role = `FacultyStaff`
   - T2 → Role = `HeadOfDepartment`
   - T3 → Role = `AcademicAffairsOffice`
   - T4 → Role = `AcademicAffairsOffice`

4. **Vẽ transitions** (mũi tên):
   - Click Start → drag tới T1
   - T1 → T2
   - T2 → Condition1
   - Condition1 → T3 (label: `Approved`)
   - Condition1 → T1 (label: `RequiresRevision`)
   - Condition1 → End (label: `Rejected`)
   - T3 → Condition2
   - Condition2 → T4 (label: `Approved`)
   - Condition2 → T1 (label: `RequiresRevision`)
   - Condition2 → End (label: `Rejected`)
   - T4 → End

5. **Set Condition expressions** (double-click Condition):
   - Condition1: `Document.ProgramApproval.Decision = Enums.ApprovalDecision.Approved` (cho nhánh "Approved")
   - Tương tự với các nhánh khác

### Bước 4: BSL Handler

Mỗi action point có thể có handler. Mở ObjectModule của BusinessProcess:

```bsl
// Handler khi T1 hoàn thành (TaskExecution)
Procedure T1OnTaskExecution(Task) Export
    Task.Completed = True;
    Task.Write();
EndProcedure

// Handler khi T2 hoàn thành — kiểm tra Decision của ProgramApproval gần nhất
Procedure T2OnTaskExecution(Task) Export
    // Tìm Document ProgramApproval mới nhất cho CTĐT này
    // Set Task.Completed = True
    Task.Completed = True;
    Task.Write();
EndProcedure
```

### Bước 5: Kiểm tra

1. Save → F5 refresh project
2. Run 1C:Enterprise
3. Vào **Quy trình phê duyệt CTĐT** → tạo BP instance mới → Post
4. → tự động sinh Task T1 cho người được gán
5. Khi T1 hoàn thành → BP advance → sinh T2 → ...

---

## 2. DCS Schema cho 2 Reports

**Mục đích**: Tạo data composition schema để báo cáo hiển thị dữ liệu thực tế (hiện chỉ là stub trống).

**Thời gian**: ~20 phút/báo cáo

### 2A. ProgramListReport — Danh sách CTĐT

**Mục đích**: Hiển thị danh sách CTĐT theo Khoa/Ngành/Trạng thái tại 1 mốc thời gian.

#### Bước 1: Tạo DCS schema

1. Project Explorer → `Reports → ProgramListReport`
2. Right-click → **New → Data Composition Schema**
3. Đặt tên: `ProgramListSchema` (hoặc giữ default `MainDataCompositionSchema`)

#### Bước 2: Define Data Source

Trong DCS editor, tab **Data sources**:
- Add → **Local** → Name: `LocalDB`, Type: `Database` ✓

#### Bước 3: Tạo Query trong tab Data sets

1. Add → **Query** → đặt tên: `ProgramList`
2. Click **Query designer**
3. Drag từ Database tree:
   - Catalog.TrainingPrograms (vào FROM)
   - InformationRegister.ProgramValidity.SliceLast(&AsOfDate) (vào LEFT JOIN)
4. Mapping JOIN: `TrainingPrograms.Ref = ProgramValidity.TrainingProgram`
5. **Select fields**:
   - TrainingPrograms.Code
   - TrainingPrograms.Description
   - TrainingPrograms.Owner (Ngành) 
   - TrainingPrograms.IssueYear
   - TrainingPrograms.TotalCredits
   - ProgramValidity.Status
   - ProgramValidity.IssuanceDecision
6. **WHERE**: optionally filter theo parameter
7. Save query

#### Bước 4: Parameters

Tab **Parameters**:
- `AsOfDate` (Date) — default = `CurrentDate()`
- `Faculty` (CatalogRef.Faculties) — optional
- `Status` (EnumRef.ProgramStatuses) — optional

#### Bước 5: Settings

Tab **Settings** (mặc định):
- **Grouping**: Owner → Description
- **Selected fields**: Code, Description, IssueYear, TotalCredits, Status, IssuanceDecision
- **Order**: Owner ascending, Description ascending
- **Conditional appearance**: 
  - Status = Issued → green background
  - Status = Deactivated → gray background

#### Bước 6: Liên kết với Report

1. Mở `ProgramListReport.mdo` 
2. Property `MainDataCompositionSchema` → trỏ tới schema vừa tạo
3. Property `DefaultSettingsForm` (optional) → tạo form chọn parameter

### 2B. ApprovalAuditReport — Báo cáo audit

Vì đã bỏ ApprovalLog IR, có thể:
- **Bỏ Report này** (đơn giản nhất), hoặc
- Tạo DCS đọc từ UNION 3 Documents:

```sql
SELECT
    Date AS Timestamp,
    "Submit" AS Action,
    Proposer AS Performer,
    TargetProgram,
    Ref AS Document
FROM Document.ProgramProposal
WHERE Posted = TRUE

UNION ALL

SELECT
    Date,
    CASE
        WHEN ApprovalLevel = VALUE(Enum.ApprovalLevel.Issued) THEN "Issue"
        WHEN Decision = VALUE(Enum.ApprovalDecision.Approved) THEN "Approve"
        WHEN Decision = VALUE(Enum.ApprovalDecision.RequiresRevision) THEN "Revision"
        ELSE "Reject"
    END,
    NULL,
    TargetProgram,
    Ref
FROM Document.ProgramApproval
WHERE Posted = TRUE

UNION ALL

SELECT
    Date,
    CAST(AmendmentType AS STRING(30)),
    NULL,
    TargetProgram,
    Ref
FROM Document.ProgramAmendment
WHERE Posted = TRUE

ORDER BY Timestamp DESC
```

---

## 3. Rights chi tiết cho 4 Roles

**Mục đích**: Phân quyền chi tiết — hiện tại Rights.rights chỉ là skeleton "full open", cần tinh chỉnh theo ma trận quyền v5.

**Thời gian**: ~30-45 phút

### Ma trận quyền tham khảo (v5 spec)

| Object | FacultyStaff | HeadOfDepartment | AcademicAffairsOffice | SystemAdmin |
|--------|-------------|------------------|----------------------|-------------|
| Catalog.TrainingPrograms | V I* E* (RLS Faculty) | V I E (toàn Khoa) | V I E | V I E D |
| Catalog.Courses | V I* E* | V I E | V I E | V I E D |
| Catalog.Lecturers,Faculties,Majors | V | V | V I E | V I E D |
| Catalog.AcademicYears,KnowledgeBlocks | V | V | V I E | V I E D |
| Catalog.Decisions | — | — | V I E | V I E D |
| Doc.ProgramProposal | V I P (own) | V I P (Khoa) | V | V I E D P |
| Doc.ProgramApproval | — | I P (Lvl=Faculty) | I P (Lvl=Inst/Issued) | V I E D P |
| Doc.ProgramAmendment | — | — | I P | V I E D P |
| IR.ProgramValidity | V | V | V | V |
| Reports | V (Khoa) | V (Khoa) | V (toàn HV) | V |
| DataProcessors | Use | Use | Use | Use |
| BusinessProcess | V (own) | V (Khoa) | V | V |
| Task | V (own) | V (Khoa) | V (own) | V |

Ký hiệu: V=View, I=Insert, E=Edit, D=Delete, P=Post, U=Use, *=có RLS

### Cách thao tác trong EDT GUI

1. Project Explorer → `Roles → FacultyStaff` → Open
2. EDT mở Role editor có 2 tab:
   - **Rights**: bảng các metadata object × quyền (Read/Add/Edit/Delete/Post...)
   - **Templates**: RLS templates
3. Tick/bỏ tick theo ma trận trên
4. Save → Repeat cho 4 Roles

### RLS Templates (cho FacultyStaff)

Tab **Templates** → New Template → Name: `OwnFaculty`

```
TrainingPrograms WHERE TrainingPrograms.Faculty = &CurrentFaculty
```

Sau đó apply template cho Read/Update của Catalog.TrainingPrograms.

`&CurrentFaculty` cần được populate trong session — qua module `SessionParameters` hoặc `OnStart`.

### Test

Tạo user mới → gán Role FacultyStaff → đăng nhập → check chỉ thấy data thuộc Khoa của mình.

---

## 4. Custom Forms cho 3 Documents

**Mục đích**: Dynamic visibility — ẩn/hiện field theo ngữ cảnh, giảm rối form.

**Thời gian**: ~15 phút/Document

### 4A. ProgramApproval Form

**Yêu cầu**:
- `IssuanceDecision` chỉ hiện khi `ApprovalLevel = Issued`
- `BasedOnProposal` chỉ hiện khi `ApprovalLevel = FacultyCouncil`
- `RevisionNotes` chỉ hiện khi `Decision = RequiresRevision`
- `VotingResults` tabular chỉ hiện khi `ApprovalLevel != Issued`

#### Bước 1: Tạo form

1. `Documents → ProgramApproval → Forms` → right-click → **New → Form**
2. Wizard:
   - Form type: **Document form**
   - Name: `DocumentForm`
   - Generate code: ✓

#### Bước 2: Form module

Right-click form → **Module** → paste:

```bsl
&AtClient
Procedure OnOpen(Cancel)
    UpdateFieldVisibility();
EndProcedure

&AtClient
Procedure ApprovalLevelOnChange(Item)
    UpdateFieldVisibility();
EndProcedure

&AtClient
Procedure DecisionOnChange(Item)
    UpdateFieldVisibility();
EndProcedure

&AtClient
Procedure UpdateFieldVisibility()
    IsIssued = (Object.ApprovalLevel = PredefinedValue("Enum.ApprovalLevel.Issued"));
    IsFacultyLvl = (Object.ApprovalLevel = PredefinedValue("Enum.ApprovalLevel.FacultyCouncil"));
    NeedRevision = (Object.Decision = PredefinedValue("Enum.ApprovalDecision.RequiresRevision"));

    Items.IssuanceDecision.Visible = IsIssued;
    Items.BasedOnProposal.Visible = IsFacultyLvl;
    Items.RevisionNotes.Visible = NeedRevision;
    Items.VotingResults.Visible = Not IsIssued;
EndProcedure
```

#### Bước 3: Test

Run Enterprise → mở Document mới → đổi ApprovalLevel → fields thay đổi.

### 4B. ProgramAmendment Form

Tương tự — ẩn hiện theo `AmendmentType`:
- `EffectiveDate`, `SupportingDecision` chỉ hiện khi `Minor/Major/Deactivation`
- `ReviewYear`, `ReviewSummary` chỉ hiện khi `AnnualReview`

```bsl
&AtClient
Procedure AmendmentTypeOnChange(Item)
    IsAnnualReview = (Object.AmendmentType = PredefinedValue("Enum.AmendmentType.AnnualReview"));

    Items.EffectiveDate.Visible = Not IsAnnualReview;
    Items.SupportingDecision.Visible = Not IsAnnualReview;
    Items.AmendmentSummary.Visible = Not IsAnnualReview;
    Items.ReviewYear.Visible = IsAnnualReview;
    Items.ReviewSummary.Visible = IsAnnualReview;
EndProcedure
```

### 4C. ProgramProposal Form (optional)

Auto-fill `ProposingFaculty` từ user hiện tại:

```bsl
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
    If Not ValueIsFilled(Object.Ref) Then  // tạo mới
        // Lấy Faculty từ user
        CurrentUser = Catalogs.Users.FindByDescription(UserName());
        If Not CurrentUser.IsEmpty() Then
            Object.Proposer = CurrentUser;
            // Object.ProposingFaculty = ... (lookup từ user metadata)
        EndIf;
    EndIf;
EndProcedure
```

---

## 5. DataProcessor ImportFromExcel

**Mục đích**: Cho phép user nhập hàng loạt Course/Lecturer/Major từ file Excel.

**Thời gian**: ~1-2 giờ

### Bước 1: Tạo Form

1. `DataProcessors → ImportFromExcel → Forms` → New → Form
2. Layout:
   - **Combobox** "Loại dữ liệu" — items: "Học phần", "Giảng viên", "Ngành"
   - **Button** "Tải template" — download Excel mẫu
   - **FileSelectField** "Chọn file Excel"
   - **Button** "Đọc & Preview"
   - **SpreadsheetField** preview data (highlight errors)
   - **Button** "Import"

### Bước 2: BSL Form Module

```bsl
&AtClient
Var FilePath; // path đến file Excel đã chọn

&AtClient
Procedure DownloadTemplate(Command)
    // Sinh Excel template
    Template = GenerateExcelTemplateAtServer(TargetType);
    // Save to local file
    Dialog = New FileDialog(FileDialogMode.Save);
    Dialog.Filter = "Excel files (*.xlsx)|*.xlsx";
    If Dialog.Choose() Then
        // ... save template
    EndIf;
EndProcedure

&AtClient
Procedure SelectFile(Command)
    Dialog = New FileDialog(FileDialogMode.Open);
    Dialog.Filter = "Excel files (*.xlsx)|*.xlsx";
    If Dialog.Choose() Then
        FilePath = Dialog.FullFileName;
        Items.FilePathLabel.Title = FilePath;
    EndIf;
EndProcedure

&AtClient
Procedure ParsePreview(Command)
    PreviewData = ReadExcelAtServer(FilePath, TargetType);
    // Display in SpreadsheetField with error highlighting
EndProcedure

&AtServerNoContext
Function ReadExcelAtServer(Path, Type)
    Spreadsheet = New SpreadsheetDocument();
    Spreadsheet.Read(Path);

    Data = New Array();
    Errors = New Array();

    For RowIdx = 2 To Spreadsheet.TableHeight Do  // skip header row
        Row = New Structure();
        Row.Insert("Code", Spreadsheet.Area("R" + RowIdx + "C1").Text);
        Row.Insert("Description", Spreadsheet.Area("R" + RowIdx + "C2").Text);
        // ... more columns

        // Validate
        If IsBlankString(Row.Code) Then
            Errors.Add("Row " + RowIdx + ": Code rỗng");
            Continue;
        EndIf;
        If Type = "Courses" And Not Catalogs.Courses.FindByCode(Row.Code).IsEmpty() Then
            Errors.Add("Row " + RowIdx + ": Code " + Row.Code + " đã tồn tại");
        EndIf;

        Data.Add(Row);
    EndDo;

    Return New Structure("Data, Errors", Data, Errors);
EndFunction

&AtServer
Procedure ImportData(PreviewedData)
    For Each Row In PreviewedData Do
        If Type = "Courses" Then
            NewItem = Catalogs.Courses.CreateItem();
            NewItem.Code = Row.Code;
            NewItem.Description = Row.Description;
            // ... fill other fields
            NewItem.Write();
        EndIf;
        // similar for Lecturers, Majors
    EndDo;
EndProcedure
```

### Bước 3: Test

Tạo file Excel mẫu → upload → preview → fix errors → Import → check Catalog.

---

## 6. Print form QĐ Ban hành

**Mục đích**: In Quyết định ban hành CTĐT ra giấy/PDF theo template Học viện.

**Thời gian**: ~30-45 phút

### Bước 1: Tạo Template

1. `Catalogs → Decisions → Templates` → right-click → **New → Template**
2. Type: **Spreadsheet document**
3. Name: `DecisionPrintForm`

### Bước 2: Design layout

Trong template editor, vẽ:

```
┌────────────────────────────────────────────────────────────┐
│ [LOGO]    HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG          │
│                                                            │
│                  CỘNG HOÀ XÃ HỘI CHỦ NGHĨA VIỆT NAM        │
│                  Độc lập - Tự do - Hạnh phúc               │
│                                                            │
│              Hà Nội, ngày [Date] tháng [Month] năm [Year]  │
│                                                            │
│                    QUYẾT ĐỊNH                              │
│              Số: [DecisionNumber]                          │
│      [Description]                                         │
│                                                            │
│           GIÁM ĐỐC HỌC VIỆN CNBC VT                        │
│                                                            │
│ Căn cứ ...                                                 │
│                                                            │
│                    QUYẾT ĐỊNH:                             │
│                                                            │
│ Điều 1. Ban hành kèm theo Quyết định này [Content]         │
│ Điều 2. Quyết định có hiệu lực từ ngày [EffectiveDate]     │
│ Điều 3. Trưởng Khoa, Phòng Đào tạo, các đơn vị có          │
│         liên quan chịu trách nhiệm thi hành Quyết định này.│
│                                                            │
│                                  GIÁM ĐỐC                  │
│                                                            │
│                                  [Signer]                  │
└────────────────────────────────────────────────────────────┘
```

Đặt **named cells** cho placeholder:
- `[Date]`, `[Month]`, `[Year]` → cell name `DateD`, `DateM`, `DateY`
- `[DecisionNumber]` → cell name `Code`
- `[Description]` → cell name `Description`
- `[EffectiveDate]` → cell name `EffectiveDate`
- `[Signer]` → cell name `Signer`

### Bước 3: Add command "Print QĐ"

1. `Catalogs → Decisions` → Forms → ItemForm → Commands → Add:
   - Name: `PrintDecision`
   - Caption: "In QĐ"
2. Form Module:

```bsl
&AtClient
Procedure PrintDecision(Command)
    SpreadsheetDoc = GeneratePrintFormAtServer(Object.Ref);
    SpreadsheetDoc.Show("In QĐ " + Object.Code);
EndProcedure

&AtServerNoContext
Function GeneratePrintFormAtServer(DecisionRef)
    Template = Catalogs.Decisions.GetTemplate("DecisionPrintForm");
    Output = New SpreadsheetDocument();

    Decision = DecisionRef.GetObject();

    // Fill placeholders
    Area = Template.GetArea();
    Area.Parameters.Code = Decision.Code;
    Area.Parameters.Description = Decision.Description;
    Area.Parameters.DateD = Format(Decision.IssueDate, "DF=dd");
    Area.Parameters.DateM = Format(Decision.IssueDate, "DF=MM");
    Area.Parameters.DateY = Format(Decision.IssueDate, "DF=yyyy");
    Area.Parameters.EffectiveDate = Format(Decision.EffectiveDate, "DF='dd/MM/yyyy'");
    Area.Parameters.Signer = ?(Decision.Signer.IsEmpty(), "", Decision.Signer.Description);

    Output.Put(Area);
    Return Output;
EndFunction
```

### Bước 4: Test

Run Enterprise → mở Decision QD-1234 → click "In QĐ" → SpreadsheetDocument hiển thị → Print/Export PDF.

---

## Checklist final

Trước khi bảo vệ luận văn, kiểm tra:

### Bắt buộc

- [ ] BusinessProcess Route Map đã vẽ và test với 1 instance
- [ ] DCS Schema ProgramListReport hiển thị data thực
- [ ] Rights chi tiết cho ít nhất 2 Roles (FacultyStaff + AcademicAffairsOffice)
- [ ] Đã chạy `InitialDataFill.RunAll()` và data đầy đủ

### Nên có

- [ ] Custom forms cho ProgramApproval + ProgramAmendment với dynamic visibility
- [ ] Print form QĐ Ban hành hoạt động

### Optional

- [ ] DCS Schema ApprovalAuditReport
- [ ] ImportFromExcel có thể import 1 Catalog mẫu

### Demo flow cho buổi bảo vệ

**Kịch bản 1 - Tạo CTĐT mới**:
1. Đăng nhập với role `FacultyStaff`
2. Vào **Quản lý CTĐT & HP → CTĐT** → New → tạo `CT-AI-2026`
3. Vào **Đề xuất CTĐT** → New → fill data → Post
4. (BP auto-sinh Task T1) → đăng nhập role `HeadOfDepartment` → check Task → complete
5. Đăng nhập `AcademicAffairsOffice` → Tasks T2/T3/T4 → complete → ban hành
6. Vào **Báo cáo → Danh sách CTĐT** → AsOfDate = today → thấy CT-AI-2026 với Status=Issued
7. Mở Decision liên kết → **In QĐ** → PDF

**Kịch bản 2 - Sample data sẵn**:
1. `InitialDataFill.RunAll()` (nếu chưa chạy)
2. Show menu các đối tượng đã có data
3. Mở Document ProgramApproval (Lvl=Issued) → demo VotingResults
4. Mở IR ProgramValidity → SliceLast → trạng thái hiện tại CT-IT-2024 = `Issued`
5. Mở BusinessProcess instance → 4 Tasks đã completed

---

## Liên hệ & Hỗ trợ

Nếu gặp vướng mắc:
- **Lỗi SDBL khi build**: backup project, revert commit cuối, bisect
- **EDT auto-generate file lạ**: commit về git, có thể revert nếu cần
- **Sample data conflict**: chạy `InitialDataFill.RunAll()` trên infobase mới (xoá DB cũ trước)

Toàn bộ source: branch `claude/v5_3` trên GitHub
