////////////////////////////////////////////////////////////////////////////////
// InitialDataFill — Nạp dữ liệu mẫu cho phân hệ QLĐT v5
// Dữ liệu lấy từ Học viện Công nghệ Bưu chính Viễn thông (PTIT) - cơ sở Hà Nội
//
// CÁCH SỬ DỤNG:
//   Chạy 1 lần sau khi deploy lần đầu, từ Designer hoặc tạo Data Processor
//   gọi: InitialDataFill.RunAll();
//
// THỨ TỰ NẠP (do FK dependency):
//   Constants → AcademicYears → KnowledgeBlocks → Faculties (Khoa→BM)
//   → Lecturers → Majors → Courses → Decisions → TrainingPrograms
////////////////////////////////////////////////////////////////////////////////

#Region PublicAPI

// Entry point: nạp toàn bộ dữ liệu mẫu PTIT
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
EndProcedure

#EndRegion

#Region Constants

Procedure FillConstants() Export
	Constants.AcademicInstitutionName.Set("Học viện Công nghệ Bưu chính Viễn thông");
	Constants.UseDigitalSignatureFlag.Set(False);
	// DefaultAcademicYear sẽ set sau khi AcademicYears đã có
EndProcedure

#EndRegion

#Region AcademicYears

Procedure FillAcademicYears() Export
	CreateAcademicYear("2023-2024", "Năm học 2023-2024", Date(2023, 9, 1), Date(2024, 8, 31));
	CreateAcademicYear("2024-2025", "Năm học 2024-2025", Date(2024, 9, 1), Date(2025, 8, 31));
	Y2526 = CreateAcademicYear("2025-2026", "Năm học 2025-2026", Date(2025, 9, 1), Date(2026, 8, 31));
	Constants.DefaultAcademicYear.Set(Y2526);
EndProcedure

Function CreateAcademicYear(Code, Description, StartDate, EndDate)
	Existing = Catalogs.AcademicYears.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.AcademicYears.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.StartDate = StartDate;
	NewItem.EndDate = EndDate;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region KnowledgeBlocks

// 4 khối kiến thức theo Thông tư 17/2021/TT-BGDĐT
Procedure FillKnowledgeBlocks() Export
	CreateKnowledgeBlock("DC",  "Khối Đại cương",        Undefined, 30);
	CreateKnowledgeBlock("CSN", "Khối Cơ sở ngành",      Undefined, 30);
	CreateKnowledgeBlock("CN",  "Khối Chuyên ngành",     Undefined, 40);
	CreateKnowledgeBlock("TN",  "Khối Tốt nghiệp",       Undefined, 8);

	// Phân nhánh chi tiết khối Đại cương
	DC = Catalogs.KnowledgeBlocks.FindByCode("DC");
	CreateKnowledgeBlock("DC-LLCT", "Lý luận chính trị + Pháp luật", DC, 11);
	CreateKnowledgeBlock("DC-TKHTN", "Toán - Khoa học tự nhiên",      DC, 12);
	CreateKnowledgeBlock("DC-NN",    "Ngoại ngữ",                     DC, 9);
	CreateKnowledgeBlock("DC-GDQP",  "Giáo dục quốc phòng - Thể chất", DC, 8);
EndProcedure

Function CreateKnowledgeBlock(Code, Description, Parent, MinCredits)
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
	NewItem.MinCredits = MinCredits;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Faculties

// 8 Khoa cấp 1 + Bộ môn (con) - cơ cấu PTIT Hà Nội
Procedure FillFaculties() Export
	// Cấp Khoa (Parent = empty)
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
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Lecturers

// Sample giảng viên (sử dụng tên public của lãnh đạo PTIT + một số tên minh hoạ)
Procedure FillLecturers() Export
	CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	VT1   = Catalogs.Faculties.FindByCode("VT1");
	KHMT  = Catalogs.Faculties.FindByCode("KHMT");
	CNPM  = Catalogs.Faculties.FindByCode("CNPM");
	TTNT  = Catalogs.Faculties.FindByCode("TTNT");

	// Lãnh đạo Học viện (thông tin công khai)
	CreateLecturer("GV0001", "Từ Minh Phương",       CNTT1, "GS",    "TS",  "phuongtm@ptit.edu.vn");
	CreateLecturer("GV0002", "Đặng Hoài Bắc",        VT1,   "PGS",   "TS",  "bacdh@ptit.edu.vn");

	// GV Khoa CNTT1 (sample)
	CreateLecturer("GV0010", "Nguyễn Văn An",        KHMT,  "TS",    "TS",  "annv@ptit.edu.vn");
	CreateLecturer("GV0011", "Trần Thị Bình",        CNPM,  "ThS",   "ThS", "binhtt@ptit.edu.vn");
	CreateLecturer("GV0012", "Lê Hoàng Cường",       CNPM,  "TS",    "TS",  "cuonglh@ptit.edu.vn");
	CreateLecturer("GV0013", "Phạm Minh Dũng",       TTNT,  "PGS",   "TS",  "dungpm@ptit.edu.vn");
	CreateLecturer("GV0014", "Hoàng Thị Em",         KHMT,  "ThS",   "ThS", "emht@ptit.edu.vn");

	// GV Khoa VT1 (sample)
	CreateLecturer("GV0020", "Nguyễn Quốc Phong",    VT1,   "PGS",   "TS",  "phongnq@ptit.edu.vn");
	CreateLecturer("GV0021", "Lê Thị Hương",         VT1,   "TS",    "TS",  "huonglt@ptit.edu.vn");

	// Cập nhật Trưởng đơn vị (sample)
	UpdateFacultyHead("CNTT1", "GV0001");
	UpdateFacultyHead("VT1",   "GV0002");
	UpdateFacultyHead("KHMT",  "GV0010");
	UpdateFacultyHead("CNPM",  "GV0012");
	UpdateFacultyHead("TTNT",  "GV0013");
EndProcedure

Function CreateLecturer(Code, FullName, Faculty, AcademicTitle, Degree, Email)
	Existing = Catalogs.Lecturers.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Lecturers.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = FullName;
	NewItem.Faculty = Faculty;
	NewItem.AcademicTitle = AcademicTitle;
	NewItem.Degree = Degree;
	NewItem.Email = Email;
	NewItem.IsActive = True;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

Procedure UpdateFacultyHead(FacultyCode, LecturerCode)
	Faculty = Catalogs.Faculties.FindByCode(FacultyCode);
	Lecturer = Catalogs.Lecturers.FindByCode(LecturerCode);
	If Faculty.IsEmpty() Or Lecturer.IsEmpty() Then
		Return;
	EndIf;
	FacultyObj = Faculty.GetObject();
	FacultyObj.Head = Lecturer;
	FacultyObj.Write();
EndProcedure

#EndRegion

#Region Majors

// 10 ngành chính của PTIT (mã theo BGDĐT 2022)
Procedure FillMajors() Export
	CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	VT1   = Catalogs.Faculties.FindByCode("VT1");
	ATTT  = Catalogs.Faculties.FindByCode("ATTT");
	DPT   = Catalogs.Faculties.FindByCode("DPT");
	KTDT1 = Catalogs.Faculties.FindByCode("KTDT1");
	QTKD1 = Catalogs.Faculties.FindByCode("QTKD1");
	TCKT1 = Catalogs.Faculties.FindByCode("TCKT1");

	CreateMajor("7480201", "Công nghệ thông tin",        CNTT1, "Cử nhân");
	CreateMajor("7480101", "Khoa học máy tính",          CNTT1, "Cử nhân");
	CreateMajor("7480103", "Kỹ thuật phần mềm",          CNTT1, "Cử nhân");
	CreateMajor("7480104", "Hệ thống thông tin",         CNTT1, "Cử nhân");
	CreateMajor("7480107", "Trí tuệ nhân tạo",           CNTT1, "Cử nhân");
	CreateMajor("7480202", "An toàn thông tin",          ATTT,  "Cử nhân");
	CreateMajor("7520207", "Kỹ thuật viễn thông",        VT1,   "Kỹ sư");
	CreateMajor("7520201", "Kỹ thuật điện tử-viễn thông", KTDT1, "Kỹ sư");
	CreateMajor("7320104", "Truyền thông đa phương tiện", DPT,   "Cử nhân");
	CreateMajor("7340101", "Quản trị kinh doanh",        QTKD1, "Cử nhân");
	CreateMajor("7340301", "Kế toán",                    TCKT1, "Cử nhân");
EndProcedure

Function CreateMajor(Code, Description, Faculty, EducationLevel)
	Existing = Catalogs.Majors.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Majors.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.Faculty = Faculty;
	NewItem.EducationLevel = EducationLevel;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

#EndRegion

#Region Courses

// Sample học phần cho ngành CNTT (mã theo PTIT format)
Procedure FillCourses() Export
	DC_LLCT  = Catalogs.KnowledgeBlocks.FindByCode("DC-LLCT");
	DC_TKHTN = Catalogs.KnowledgeBlocks.FindByCode("DC-TKHTN");
	DC_NN    = Catalogs.KnowledgeBlocks.FindByCode("DC-NN");
	CSN      = Catalogs.KnowledgeBlocks.FindByCode("CSN");
	CN       = Catalogs.KnowledgeBlocks.FindByCode("CN");
	TN       = Catalogs.KnowledgeBlocks.FindByCode("TN");

	KHCB1    = Catalogs.Faculties.FindByCode("KHCB1");
	CNTT1    = Catalogs.Faculties.FindByCode("CNTT1");
	KHMT     = Catalogs.Faculties.FindByCode("KHMT");
	CNPM     = Catalogs.Faculties.FindByCode("CNPM");
	TTNT     = Catalogs.Faculties.FindByCode("TTNT");

	// Khối Đại cương
	CreateCourse("BAS1101", "Triết học Mác-Lênin",                 3, DC_LLCT,  KHCB1, "Lý thuyết");
	CreateCourse("BAS1102", "Kinh tế chính trị Mác-Lênin",         2, DC_LLCT,  KHCB1, "Lý thuyết");
	CreateCourse("BAS1103", "Tư tưởng Hồ Chí Minh",                2, DC_LLCT,  KHCB1, "Lý thuyết");
	CreateCourse("BAS1201", "Toán cao cấp 1 (Giải tích)",          4, DC_TKHTN, KHCB1, "Lý thuyết");
	CreateCourse("BAS1202", "Toán cao cấp 2 (Đại số)",             3, DC_TKHTN, KHCB1, "Lý thuyết");
	CreateCourse("BAS1203", "Xác suất thống kê",                   3, DC_TKHTN, KHCB1, "Lý thuyết");
	CreateCourse("BAS1301", "Tiếng Anh 1",                         3, DC_NN,    KHCB1, "Lý thuyết");
	CreateCourse("BAS1302", "Tiếng Anh 2",                         3, DC_NN,    KHCB1, "Lý thuyết");

	// Khối Cơ sở ngành (CNTT)
	CreateCourse("INT1154", "Nhập môn lập trình",                  3, CSN,      KHMT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1234", "Lập trình hướng đối tượng",           3, CSN,      KHMT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1340", "Cấu trúc dữ liệu và giải thuật",     3, CSN,      KHMT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1432", "Cơ sở dữ liệu",                       3, CSN,      KHMT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1339", "Mạng máy tính",                       3, CSN,      KHMT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1306", "Hệ điều hành",                        3, CSN,      KHMT,  "Lý thuyết");
	CreateCourse("INT1313", "Kiến trúc máy tính",                  3, CSN,      KHMT,  "Lý thuyết");

	// Khối Chuyên ngành
	CreateCourse("INT2208", "Phát triển ứng dụng web",             3, CN,       CNPM,  "Lý thuyết + Thực hành");
	CreateCourse("INT1419", "Trí tuệ nhân tạo",                    3, CN,       TTNT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1397", "Học máy",                             3, CN,       TTNT,  "Lý thuyết + Thực hành");
	CreateCourse("INT1448", "Phân tích thiết kế hệ thống",         3, CN,       CNPM,  "Lý thuyết + Đồ án");
	CreateCourse("INT2210", "Lập trình di động",                   3, CN,       CNPM,  "Lý thuyết + Thực hành");
	CreateCourse("INT1331", "An toàn thông tin",                   3, CN,       CNTT1, "Lý thuyết");

	// Khối Tốt nghiệp
	CreateCourse("INT2030", "Thực tập tốt nghiệp",                 4, TN,       CNTT1, "Thực tập");
	CreateCourse("INT2031", "Đồ án tốt nghiệp",                    8, TN,       CNTT1, "Đồ án");

	// Set Prerequisites mẫu (Cấu trúc DL cần Nhập môn LT)
	AddPrerequisite("INT1340", "INT1154", "Tiên quyết");
	AddPrerequisite("INT1234", "INT1154", "Tiên quyết");
	AddPrerequisite("INT2208", "INT1432", "Học trước");
	AddPrerequisite("INT1397", "INT1419", "Học trước");
EndProcedure

Function CreateCourse(Code, Description, Credits, KnowledgeBlock, ManagingFaculty, CourseType)
	Existing = Catalogs.Courses.FindByCode(Code);
	If Not Existing.IsEmpty() Then
		Return Existing;
	EndIf;
	NewItem = Catalogs.Courses.CreateItem();
	NewItem.Code = Code;
	NewItem.Description = Description;
	NewItem.Credits = Credits;
	NewItem.KnowledgeBlock = KnowledgeBlock;
	NewItem.ManagingFaculty = ManagingFaculty;
	NewItem.CourseType = CourseType;
	NewItem.IsActive = True;
	NewItem.Write();
	Return NewItem.Ref;
EndFunction

Procedure AddPrerequisite(CourseCode, PrereqCode, PrereqType)
	Course = Catalogs.Courses.FindByCode(CourseCode);
	Prereq = Catalogs.Courses.FindByCode(PrereqCode);
	If Course.IsEmpty() Or Prereq.IsEmpty() Then
		Return;
	EndIf;
	CourseObj = Course.GetObject();
	NewRow = CourseObj.Prerequisites.Add();
	NewRow.PrerequisiteCourse = Prereq;
	NewRow.PrerequisiteType = PrereqType;
	CourseObj.Write();
EndProcedure

#EndRegion

#Region Decisions

Procedure FillDecisions() Export
	GD = Catalogs.Lecturers.FindByCode("GV0001");
	CreateDecision(
		"QĐ-1234/QĐ-HV",
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

// Sample CTĐT: Cử nhân CNTT K2024 (130 TC, 4 năm)
Procedure FillTrainingPrograms() Export
	Major_CNTT = Catalogs.Majors.FindByCode("7480201");
	Faculty_CNTT1 = Catalogs.Faculties.FindByCode("CNTT1");
	Year_2425 = Catalogs.AcademicYears.FindByCode("2024-2025");
	Decision = Catalogs.Decisions.FindByCode("QĐ-1234/QĐ-HV");

	BlockDC  = Catalogs.KnowledgeBlocks.FindByCode("DC");
	BlockCSN = Catalogs.KnowledgeBlocks.FindByCode("CSN");
	BlockCN  = Catalogs.KnowledgeBlocks.FindByCode("CN");
	BlockTN  = Catalogs.KnowledgeBlocks.FindByCode("TN");

	Existing = Catalogs.TrainingPrograms.FindByCode("CT-IT-2024");
	If Not Existing.IsEmpty() Then
		Return;
	EndIf;

	NewItem = Catalogs.TrainingPrograms.CreateItem();
	NewItem.Code = "CT-IT-2024";
	NewItem.Description = "Cử nhân Công nghệ Thông tin K2024";
	NewItem.Major = Major_CNTT;
	NewItem.Faculty = Faculty_CNTT1;
	NewItem.Framework = "Khung CTĐT Cử nhân theo TT17/2021";
	NewItem.EducationLevel = "Cử nhân";
	NewItem.TotalCredits = 130;
	NewItem.DurationYears = 4;
	NewItem.IssueYear = Year_2425;
	NewItem.Status = Enums.ProgramStatuses.Issued;
	NewItem.IssuanceDecision = Decision;
	NewItem.Notes = "CTĐT mẫu PTIT - dữ liệu sample InitialDataFill";

	// Tabular: KnowledgeBlocksAndCredits (phân bổ TC theo khối)
	AddBlockCredits(NewItem, BlockDC,  40, True);
	AddBlockCredits(NewItem, BlockCSN, 30, True);
	AddBlockCredits(NewItem, BlockCN,  52, True);
	AddBlockCredits(NewItem, BlockTN,   8, True);

	// Tabular: ProgramCourses (HP theo kỳ)
	// Học kỳ 1
	AddProgramCourse(NewItem, "BAS1101", 1, True, BlockDC);
	AddProgramCourse(NewItem, "BAS1201", 1, True, BlockDC);
	AddProgramCourse(NewItem, "BAS1301", 1, True, BlockDC);
	AddProgramCourse(NewItem, "INT1154", 1, True, BlockCSN);
	// Học kỳ 2
	AddProgramCourse(NewItem, "BAS1102", 2, True, BlockDC);
	AddProgramCourse(NewItem, "BAS1202", 2, True, BlockDC);
	AddProgramCourse(NewItem, "BAS1302", 2, True, BlockDC);
	AddProgramCourse(NewItem, "INT1234", 2, True, BlockCSN);
	// Học kỳ 3
	AddProgramCourse(NewItem, "BAS1103", 3, True, BlockDC);
	AddProgramCourse(NewItem, "BAS1203", 3, True, BlockDC);
	AddProgramCourse(NewItem, "INT1340", 3, True, BlockCSN);
	AddProgramCourse(NewItem, "INT1313", 3, True, BlockCSN);
	// Học kỳ 4
	AddProgramCourse(NewItem, "INT1306", 4, True, BlockCSN);
	AddProgramCourse(NewItem, "INT1432", 4, True, BlockCSN);
	AddProgramCourse(NewItem, "INT1339", 4, True, BlockCSN);
	// Học kỳ 5
	AddProgramCourse(NewItem, "INT1448", 5, True, BlockCN);
	AddProgramCourse(NewItem, "INT2208", 5, True, BlockCN);
	AddProgramCourse(NewItem, "INT1331", 5, True, BlockCN);
	// Học kỳ 6
	AddProgramCourse(NewItem, "INT1419", 6, True, BlockCN);
	AddProgramCourse(NewItem, "INT2210", 6, False, BlockCN);
	// Học kỳ 7
	AddProgramCourse(NewItem, "INT1397", 7, False, BlockCN);
	// Học kỳ 8 (Tốt nghiệp)
	AddProgramCourse(NewItem, "INT2030", 8, True, BlockTN);
	AddProgramCourse(NewItem, "INT2031", 8, True, BlockTN);

	NewItem.Write();
EndProcedure

Procedure AddBlockCredits(Item, Block, Credits, IsRequired)
	NewRow = Item.KnowledgeBlocksAndCredits.Add();
	NewRow.KnowledgeBlock = Block;
	NewRow.Credits = Credits;
	NewRow.IsRequired = IsRequired;
EndProcedure

Procedure AddProgramCourse(Item, CourseCode, Semester, IsRequired, KBlock)
	Course = Catalogs.Courses.FindByCode(CourseCode);
	If Course.IsEmpty() Then
		Return;
	EndIf;
	NewRow = Item.ProgramCourses.Add();
	NewRow.Course = Course;
	NewRow.Semester = Semester;
	NewRow.IsRequired = IsRequired;
	NewRow.KnowledgeBlock = KBlock;
EndProcedure

#EndRegion
