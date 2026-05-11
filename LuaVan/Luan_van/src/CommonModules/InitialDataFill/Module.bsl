////////////////////////////////////////////////////////////////////////////////
// InitialDataFill — Nạp dữ liệu mẫu Học viện Công nghệ Bưu chính Viễn thông
//
// SỬ DỤNG: Sau khi deploy lần đầu, từ Designer chạy:
//   InitialDataFill.RunAll();
//
// Module idempotent — chạy nhiều lần không tạo trùng.
////////////////////////////////////////////////////////////////////////////////

#Region PublicAPI

Procedure RunAll() Export
	FillConstants();
	FillAcademicYears();
	FillKnowledgeBlocks();
	FillFaculties();
	FillLecturers();
	FillMajors();
	FillCourses();
	FillDecisions();
	FillTrainingPrograms();
	FillDocuments();
EndProcedure

#EndRegion

#Region Constants

Procedure FillConstants() Export
	Constants.AcademicInstitutionName.Set("Học viện Công nghệ Bưu chính Viễn thông");
	Constants.UseDigitalSignatureFlag.Set(False);
EndProcedure

#EndRegion

#Region AcademicYears

Procedure FillAcademicYears() Export
	CreateAcademicYear("2023-2024", "Năm học 2023-2024", Date(2023, 9, 1), Date(2024, 8, 31), False);
	CreateAcademicYear("2024-2025", "Năm học 2024-2025", Date(2024, 9, 1), Date(2025, 8, 31), False);
	Y2526 = CreateAcademicYear("2025-2026", "Năm học 2025-2026", Date(2025, 9, 1), Date(2026, 8, 31), True);
	Constants.DefaultAcademicYear.Set(Y2526);
EndProcedure

Function CreateAcademicYear(Code, Description, StartDate, EndDate, IsCurrent)
	Existing = Catalogs.AcademicYears.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.AcademicYears.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.StartDate = StartDate;
	NewItem.EndDate = EndDate;
	NewItem.IsCurrent = IsCurrent;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region KnowledgeBlocks

// 4 khối kiến thức theo Thông tư 17/2021/TT-BGDĐT
Procedure FillKnowledgeBlocks() Export
	CreateKnowledgeBlock("DC",  "Khối Đại cương",        Undefined, 1);
	CreateKnowledgeBlock("CSN", "Khối Cơ sở ngành",      Undefined, 2);
	CreateKnowledgeBlock("CN",  "Khối Chuyên ngành",     Undefined, 3);
	CreateKnowledgeBlock("TN",  "Khối Tốt nghiệp",       Undefined, 4);

	// Phân nhánh khối Đại cương
	DC = Catalogs.KnowledgeBlocks.FindByCode("DC");
	CreateKnowledgeBlock("DC-LLCT",  "Lý luận chính trị + Pháp luật", DC, 11);
	CreateKnowledgeBlock("DC-TKHTN", "Toán - Khoa học tự nhiên",      DC, 12);
	CreateKnowledgeBlock("DC-NN",    "Ngoại ngữ",                     DC, 13);
	CreateKnowledgeBlock("DC-GDQP",  "Giáo dục quốc phòng - Thể chất", DC, 14);
EndProcedure

Function CreateKnowledgeBlock(Code, Description, Parent, SortOrder)
	Existing = Catalogs.KnowledgeBlocks.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.KnowledgeBlocks.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	If Parent <> Undefined Then
		NewItem.Parent = Parent;
	EndIf;
	NewItem.SortOrder = SortOrder;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Faculties

// 8 Khoa cấp 1 + Bộ môn (con) - PTIT Hà Nội
Procedure FillFaculties() Export
	// Cấp Khoa (Parent rỗng)
	CreateFaculty("CNTT1",  "Khoa Công nghệ Thông tin 1", Undefined);
	CreateFaculty("VT1",    "Khoa Viễn thông 1", Undefined);
	CreateFaculty("ATTT",   "Khoa An toàn Thông tin", Undefined);
	CreateFaculty("DPT",    "Khoa Đa phương tiện", Undefined);
	CreateFaculty("KTDT1",  "Khoa Kỹ thuật Điện tử 1", Undefined);
	CreateFaculty("QTKD1",  "Khoa Quản trị Kinh doanh 1", Undefined);
	CreateFaculty("TCKT1",  "Khoa Tài chính Kế toán 1", Undefined);
	CreateFaculty("KHCB1",  "Khoa Cơ bản 1", Undefined);

	// Bộ môn thuộc Khoa CNTT1
	CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	CreateFaculty("KHMT",  "BM Khoa học máy tính",       CNTT1);
	CreateFaculty("CNPM",  "BM Công nghệ phần mềm",      CNTT1);
	CreateFaculty("HTTT",  "BM Hệ thống thông tin",      CNTT1);
	CreateFaculty("TTNT",  "BM Trí tuệ nhân tạo",        CNTT1);

	// Bộ môn thuộc Khoa VT1
	VT1 = Catalogs.Faculties.FindByCode("VT1");
	CreateFaculty("MVT",   "BM Mạng viễn thông",         VT1);
	CreateFaculty("VOT",   "BM Vô tuyến",                VT1);
	CreateFaculty("TTVT",  "BM Truyền thông",            VT1);

	// Bộ môn thuộc Khoa Cơ bản
	KHCB = Catalogs.Faculties.FindByCode("KHCB1");
	CreateFaculty("BM-TOAN", "BM Toán",                  KHCB);
	CreateFaculty("BM-LY",   "BM Vật lý",                KHCB);
	CreateFaculty("BM-NN",   "BM Ngoại ngữ",             KHCB);
EndProcedure

Function CreateFaculty(Code, Description, Parent)
	Existing = Catalogs.Faculties.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Faculties.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	If Parent <> Undefined Then
		NewItem.Parent = Parent;
	EndIf;
	NewItem.Active = True;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Lecturers

// Sample giảng viên (Owner = Faculty)
Procedure FillLecturers() Export
	CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	VT1   = Catalogs.Faculties.FindByCode("VT1");

	// Lãnh đạo PTIT (thông tin công khai)
	CreateLecturer("GV0001", "GS.TS. Từ Minh Phương",  CNTT1, "phuongtm@ptit.edu.vn", Date(1970, 1, 1));
	CreateLecturer("GV0002", "PGS.TS. Đặng Hoài Bắc",  VT1,   "bacdh@ptit.edu.vn",    Date(1975, 5, 10));

	// GV sample
	CreateLecturer("GV0010", "TS. Nguyễn Văn An",      CNTT1, "annv@ptit.edu.vn",     Date(1980, 3, 15));
	CreateLecturer("GV0011", "ThS. Trần Thị Bình",     CNTT1, "binhtt@ptit.edu.vn",   Date(1985, 7, 20));
	CreateLecturer("GV0012", "TS. Lê Hoàng Cường",     CNTT1, "cuonglh@ptit.edu.vn",  Date(1982, 11, 8));
	CreateLecturer("GV0013", "PGS.TS. Phạm Minh Dũng", CNTT1, "dungpm@ptit.edu.vn",   Date(1978, 4, 25));
	CreateLecturer("GV0020", "PGS.TS. Nguyễn Quốc Phong", VT1, "phongnq@ptit.edu.vn", Date(1976, 9, 12));
	CreateLecturer("GV0021", "TS. Lê Thị Hương",       VT1,   "huonglt@ptit.edu.vn",  Date(1983, 6, 30));
EndProcedure

Function CreateLecturer(Code, FullName, Faculty, Email, BirthDate)
	Existing = Catalogs.Lecturers.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Lecturers.CreateItem();
	NewItem.Owner = Faculty;
	NewItem.Code = Code;
	NewItem.Description = FullName;
	NewItem.Email = Email;
	NewItem.DateOfBirth = BirthDate;
	NewItem.JoinDate = Date(2015, 9, 1);
	NewItem.Active = True;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Majors

// 10 ngành của PTIT (Owner = Faculty, MOECode theo BGDĐT)
Procedure FillMajors() Export
	CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	VT1   = Catalogs.Faculties.FindByCode("VT1");
	ATTT  = Catalogs.Faculties.FindByCode("ATTT");
	DPT   = Catalogs.Faculties.FindByCode("DPT");
	KTDT1 = Catalogs.Faculties.FindByCode("KTDT1");
	QTKD1 = Catalogs.Faculties.FindByCode("QTKD1");
	TCKT1 = Catalogs.Faculties.FindByCode("TCKT1");

	CreateMajor("CT-IT",   "Công nghệ thông tin",        CNTT1, "7480201", "CN");
	CreateMajor("CT-KHMT", "Khoa học máy tính",          CNTT1, "7480101", "CN");
	CreateMajor("CT-KTPM", "Kỹ thuật phần mềm",          CNTT1, "7480103", "CN");
	CreateMajor("CT-HTTT", "Hệ thống thông tin",         CNTT1, "7480104", "CN");
	CreateMajor("CT-AI",   "Trí tuệ nhân tạo",           CNTT1, "7480107", "CN");
	CreateMajor("CT-ATTT", "An toàn thông tin",          ATTT,  "7480202", "CN");
	CreateMajor("CT-KTVT", "Kỹ thuật viễn thông",        VT1,   "7520207", "KS");
	CreateMajor("CT-DTVT", "Kỹ thuật điện tử-viễn thông", KTDT1, "7520201", "KS");
	CreateMajor("CT-TTDPT", "Truyền thông đa phương tiện", DPT,  "7320104", "CN");
	CreateMajor("CT-QTKD", "Quản trị kinh doanh",        QTKD1, "7340101", "CN");
	CreateMajor("CT-KT",   "Kế toán",                    TCKT1, "7340301", "CN");
EndProcedure

Function CreateMajor(Code, Description, Faculty, MOECode, DegreeLevel)
	Existing = Catalogs.Majors.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Majors.CreateItem();
	NewItem.Owner = Faculty;
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.MOECode = MOECode;
	NewItem.DegreeLevel = DegreeLevel;
	NewItem.Active = True;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Courses

Procedure FillCourses() Export
	DC_LLCT  = Catalogs.KnowledgeBlocks.FindByCode("DC-LLCT");
	DC_TKHTN = Catalogs.KnowledgeBlocks.FindByCode("DC-TKHTN");
	DC_NN    = Catalogs.KnowledgeBlocks.FindByCode("DC-NN");
	CSN      = Catalogs.KnowledgeBlocks.FindByCode("CSN");
	CN       = Catalogs.KnowledgeBlocks.FindByCode("CN");
	TN       = Catalogs.KnowledgeBlocks.FindByCode("TN");

	// Khối Đại cương
	CreateCourse("BAS1101", "Triết học Mác-Lênin",            3, DC_LLCT);
	CreateCourse("BAS1102", "Kinh tế chính trị Mác-Lênin",    2, DC_LLCT);
	CreateCourse("BAS1103", "Tư tưởng Hồ Chí Minh",           2, DC_LLCT);
	CreateCourse("BAS1201", "Toán cao cấp 1 (Giải tích)",     4, DC_TKHTN);
	CreateCourse("BAS1202", "Toán cao cấp 2 (Đại số)",        3, DC_TKHTN);
	CreateCourse("BAS1203", "Xác suất thống kê",              3, DC_TKHTN);
	CreateCourse("BAS1301", "Tiếng Anh 1",                    3, DC_NN);
	CreateCourse("BAS1302", "Tiếng Anh 2",                    3, DC_NN);

	// Khối Cơ sở ngành (CNTT)
	CreateCourse("INT1154", "Nhập môn lập trình",             3, CSN);
	CreateCourse("INT1234", "Lập trình hướng đối tượng",      3, CSN);
	CreateCourse("INT1340", "Cấu trúc dữ liệu và giải thuật", 3, CSN);
	CreateCourse("INT1432", "Cơ sở dữ liệu",                  3, CSN);
	CreateCourse("INT1339", "Mạng máy tính",                  3, CSN);
	CreateCourse("INT1306", "Hệ điều hành",                   3, CSN);
	CreateCourse("INT1313", "Kiến trúc máy tính",             3, CSN);

	// Khối Chuyên ngành
	CreateCourse("INT2208", "Phát triển ứng dụng web",        3, CN);
	CreateCourse("INT1419", "Trí tuệ nhân tạo",               3, CN);
	CreateCourse("INT1397", "Học máy",                        3, CN);
	CreateCourse("INT1448", "Phân tích thiết kế hệ thống",    3, CN);
	CreateCourse("INT2210", "Lập trình di động",              3, CN);
	CreateCourse("INT1331", "An toàn thông tin",              3, CN);

	// Khối Tốt nghiệp
	CreateCourse("INT2030", "Thực tập tốt nghiệp",            4, TN);
	CreateCourse("INT2031", "Đồ án tốt nghiệp",               8, TN);
EndProcedure

Function CreateCourse(Code, Description, Credits, KnowledgeBlock)
	Existing = Catalogs.Courses.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Courses.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.Credits = Credits;
	NewItem.DefaultBlock = KnowledgeBlock;
	NewItem.Hours_Theory = Credits * 15;
	NewItem.Hours_Practice = Credits * 5;
	NewItem.Hours_SelfStudy = Credits * 30;
	NewItem.Discontinued = False;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Decisions

Procedure FillDecisions() Export
	GD = Catalogs.Lecturers.FindByCode("GV0001");
	CreateDecision(
		"QD-1234",
		"Quyết định ban hành CTĐT Cử nhân Công nghệ thông tin K2024",
		Date(2024, 6, 15),
		GD,
		Date(2024, 9, 1)
	);
EndProcedure

Function CreateDecision(Code, Description, IssueDate, Signer, EffectiveDate)
	Existing = Catalogs.Decisions.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Decisions.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.IssueDate = IssueDate;
	NewItem.Signer = Signer;
	NewItem.EffectiveDate = EffectiveDate;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region TrainingPrograms

// Sample CTĐT: Cử nhân CNTT K2024 (Owner = Major CT-IT)
Procedure FillTrainingPrograms() Export
	Major_IT = Catalogs.Majors.FindByCode("CT-IT");

	Existing = Catalogs.TrainingPrograms.FindByCode("CT-IT-2024");
	If Not Existing.IsEmpty() Then
		Return;
	EndIf;

	NewItem = Catalogs.TrainingPrograms.CreateItem();
	NewItem.Owner = Major_IT;
	NewItem.Code = "CT-IT-2024";
	NewItem.Description = "Cử nhân Công nghệ Thông tin K2024";
	NewItem.IssueYear = 2024;
	NewItem.Version = 1;
	NewItem.Status = Enums.ProgramStatuses.Issued;
	NewItem.TotalCredits = 130;
	NewItem.TitleAwarded = "Cử nhân";
	NewItem.Framework = "TT17-2021";
	NewItem.IssuanceDate = Date(2024, 6, 15);
	NewItem.DecisionNumber = "QD-1234";
	NewItem.ValidFrom = Date(2024, 9, 1);
	NewItem.ValidTo = Date(2028, 8, 31);
	NewItem.Description_Long = "Chương trình đào tạo cử nhân Công nghệ Thông tin theo Thông tư 17/2021/TT-BGDĐT.";
	NewItem.GraduationRequirements = "Hoàn thành 130 TC, GPA >= 2.0, chuẩn ngoại ngữ B1, chuẩn tin học IC3.";

	// CourseList tabular: Course (String), KnowledgeBlock (CatalogRef), CourseType (String),
	// SuggestedSemester (Number), Credits (Number), GroupCode (String)
	BlockDC  = Catalogs.KnowledgeBlocks.FindByCode("DC");
	BlockCSN = Catalogs.KnowledgeBlocks.FindByCode("CSN");
	BlockCN  = Catalogs.KnowledgeBlocks.FindByCode("CN");
	BlockTN  = Catalogs.KnowledgeBlocks.FindByCode("TN");

	// HK1
	AddCourseListRow(NewItem, "BAS1101", BlockDC,  "Bắt buộc", 1, 3);
	AddCourseListRow(NewItem, "BAS1201", BlockDC,  "Bắt buộc", 1, 4);
	AddCourseListRow(NewItem, "BAS1301", BlockDC,  "Bắt buộc", 1, 3);
	AddCourseListRow(NewItem, "INT1154", BlockCSN, "Bắt buộc", 1, 3);
	// HK2
	AddCourseListRow(NewItem, "BAS1102", BlockDC,  "Bắt buộc", 2, 2);
	AddCourseListRow(NewItem, "BAS1202", BlockDC,  "Bắt buộc", 2, 3);
	AddCourseListRow(NewItem, "BAS1302", BlockDC,  "Bắt buộc", 2, 3);
	AddCourseListRow(NewItem, "INT1234", BlockCSN, "Bắt buộc", 2, 3);
	// HK3
	AddCourseListRow(NewItem, "BAS1103", BlockDC,  "Bắt buộc", 3, 2);
	AddCourseListRow(NewItem, "BAS1203", BlockDC,  "Bắt buộc", 3, 3);
	AddCourseListRow(NewItem, "INT1340", BlockCSN, "Bắt buộc", 3, 3);
	AddCourseListRow(NewItem, "INT1313", BlockCSN, "Bắt buộc", 3, 3);
	// HK4
	AddCourseListRow(NewItem, "INT1306", BlockCSN, "Bắt buộc", 4, 3);
	AddCourseListRow(NewItem, "INT1432", BlockCSN, "Bắt buộc", 4, 3);
	AddCourseListRow(NewItem, "INT1339", BlockCSN, "Bắt buộc", 4, 3);
	// HK5
	AddCourseListRow(NewItem, "INT1448", BlockCN,  "Bắt buộc", 5, 3);
	AddCourseListRow(NewItem, "INT2208", BlockCN,  "Bắt buộc", 5, 3);
	AddCourseListRow(NewItem, "INT1331", BlockCN,  "Bắt buộc", 5, 3);
	// HK6
	AddCourseListRow(NewItem, "INT1419", BlockCN,  "Bắt buộc", 6, 3);
	AddCourseListRow(NewItem, "INT2210", BlockCN,  "Tự chọn",  6, 3);
	// HK7
	AddCourseListRow(NewItem, "INT1397", BlockCN,  "Tự chọn",  7, 3);
	// HK8 - Tốt nghiệp
	AddCourseListRow(NewItem, "INT2030", BlockTN,  "Bắt buộc", 8, 4);
	AddCourseListRow(NewItem, "INT2031", BlockTN,  "Bắt buộc", 8, 8);

	NewItem.Write();
EndProcedure

Procedure AddCourseListRow(Program, CourseCode, KnowledgeBlock, CourseType, Semester, Credits)
	NewRow = Program.CourseList.Add();
	NewRow.Course = CourseCode;
	NewRow.KnowledgeBlock = KnowledgeBlock;
	NewRow.CourseType = CourseType;
	NewRow.SuggestedSemester = Semester;
	NewRow.Credits = Credits;
	NewRow.GroupCode = "";
EndProcedure

#EndRegion

#Region Documents

// Tạo + Post 5 Documents mẫu mô phỏng vòng đời CTĐT CT-IT-2024:
//   1. ProgramProposal — Khoa CNTT1 đề xuất
//   2. ProgramApproval (FacultyCouncil) — HĐKH Khoa duyệt
//   3. ProgramApproval (InstitutionalCouncil) — HĐKHĐT Trường duyệt
//   4. ProgramApproval (Issued) — Ban hành QĐ
//   5. ProgramAmendment (AnnualReview) — Rà soát năm 2025-2026
Procedure FillDocuments() Export
	CTDT = Catalogs.TrainingPrograms.FindByCode("CT-IT-2024");
	If CTDT.IsEmpty() Then
		Return;
	EndIf;

	CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	GD = Catalogs.Lecturers.FindByCode("GV0001");
	Proposer = Catalogs.Lecturers.FindByCode("GV0010");
	Decision = Catalogs.Decisions.FindByCode("QD-1234");
	Year2526 = Catalogs.AcademicYears.FindByCode("2025-2026");

	// 1. ProgramProposal → Status UnderReview
	Proposal = CreateProgramProposal(Date(2024, 1, 15), CNTT1, Proposer, CTDT,
		"Đề xuất ban hành CTĐT Cử nhân Công nghệ Thông tin K2024 theo TT17/2021",
		Enums.ProgramStatuses.UnderReview);

	// 2. ProgramApproval cấp Khoa → Status Approved
	CreateProgramApproval(Date(2024, 3, 10), CTDT, Enums.ApprovalLevel.FacultyCouncil,
		Proposal, "Phiên họp số 03/HĐKH-CNTT1 ngày 10/03/2024",
		Enums.ApprovalDecision.Approved, "GS.TS. Từ Minh Phương, PGS.TS. Đặng Hoài Bắc",
		Undefined, Enums.ProgramStatuses.Approved);

	// 3. ProgramApproval cấp Trường → Status vẫn Approved (chỉ kế tiếp Lvl)
	CreateProgramApproval(Date(2024, 5, 20), CTDT, Enums.ApprovalLevel.InstitutionalCouncil,
		Undefined, "Phiên họp số 02/HĐKHĐT-PTIT ngày 20/05/2024",
		Enums.ApprovalDecision.Approved, "GS.TS. Từ Minh Phương (Chủ tịch HĐKHĐT)",
		Undefined, Enums.ProgramStatuses.Approved);

	// 4. ProgramApproval Ban hành → Status Issued
	CreateProgramApproval(Date(2024, 6, 15), CTDT, Enums.ApprovalLevel.Issued,
		Undefined, "QĐ-1234/QĐ-HV ngày 15/06/2024",
		Enums.ApprovalDecision.Approved, "GS.TS. Từ Minh Phương (Giám đốc)",
		Decision, Enums.ProgramStatuses.Issued);

	// 5. ProgramAmendment - Rà soát hằng năm → Status giữ Issued
	CreateProgramAmendment(Date(2025, 12, 15), CTDT, Enums.AmendmentType.AnnualReview,
		"Rà soát hằng năm CTĐT CNTT 2024 cho năm học 2025-2026 - không thay đổi nội dung",
		Date(2026, 1, 1), Undefined, Year2526,
		"Kết quả rà soát: Đạt yêu cầu. Tỷ lệ sinh viên đăng ký 95%. GPA trung bình 2.8.",
		Enums.ProgramStatuses.Issued);
EndProcedure

Function CreateProgramProposal(DocDate, Faculty, Proposer, CTDT, Summary, NewSt)
	NewDoc = Documents.ProgramProposal.CreateDocument();
	NewDoc.Date = DocDate;
	NewDoc.ProposingFaculty = Faculty;
	NewDoc.Proposer = Proposer;
	NewDoc.TargetProgram = CTDT;
	NewDoc.ProposalSummary = Summary;
	NewDoc.NewStatus = NewSt;
	NewDoc.Write(DocumentWriteMode.Posting);
	Return NewDoc.Ref;
EndFunction

Function CreateProgramApproval(DocDate, CTDT, Level, BasedOn, Session, Result, Signers, IssuedDecision, NewSt)
	NewDoc = Documents.ProgramApproval.CreateDocument();
	NewDoc.Date = DocDate;
	NewDoc.TargetProgram = CTDT;
	NewDoc.ApprovalLevel = Level;
	If BasedOn <> Undefined Then
		NewDoc.BasedOnProposal = BasedOn;
	EndIf;
	NewDoc.CouncilSession = Session;
	NewDoc.Decision = Result;
	NewDoc.SignerSummary = Signers;
	If IssuedDecision <> Undefined Then
		NewDoc.IssuanceDecision = IssuedDecision;
	EndIf;
	NewDoc.NewStatus = NewSt;
	NewDoc.Write(DocumentWriteMode.Posting);
	Return NewDoc.Ref;
EndFunction

Function CreateProgramAmendment(DocDate, CTDT, AmendType, Summary, EffDate, SupDec, RevYear, RevSummary, NewSt)
	NewDoc = Documents.ProgramAmendment.CreateDocument();
	NewDoc.Date = DocDate;
	NewDoc.TargetProgram = CTDT;
	NewDoc.AmendmentType = AmendType;
	NewDoc.AmendmentSummary = Summary;
	NewDoc.EffectiveDate = EffDate;
	If SupDec <> Undefined Then
		NewDoc.SupportingDecision = SupDec;
	EndIf;
	If RevYear <> Undefined Then
		NewDoc.ReviewYear = RevYear;
	EndIf;
	NewDoc.ReviewSummary = RevSummary;
	NewDoc.NewStatus = NewSt;
	NewDoc.Write(DocumentWriteMode.Posting);
	Return NewDoc.Ref;
EndFunction

#EndRegion
