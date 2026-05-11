
Procedure FacultyCouncilReviewBeforeCreateTasks(RoutePoint, TasksBeingFormed, StandardProcessing)
	TasksBeingFormed.Performer = Catalogs.Lecturers.FindByCode("GV0013");
    TasksBeingFormed.Description = "HĐKH Khoa phê duyệt";
EndProcedure

Procedure PrepareProposalBeforeCreateTasks(RoutePoint, TasksBeingFormed, StandardProcessing)
	TasksBeingFormed.Performer = Catalogs.Lecturers.FindByCode("GV0010");
    TasksBeingFormed.Description = "Soạn đề xuất CTĐT";
EndProcedure
