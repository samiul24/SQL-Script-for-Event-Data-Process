--->Source table list<---

IF OBJECT_ID('dbo.AnalyticsEventTypes', 'u') IS NOT NULL 
   DROP TABLE dbo.AnalyticsEventTypes;  
GO
CREATE  TABLE AnalyticsEventTypes (
 NumericId int NOT NULL,
 Id uniqueidentifier NOT NULL,
 Name nvarchar(100) NOT NULL
)
GO

IF OBJECT_ID('dbo.AnalyticsEvents', 'u') IS NOT NULL 
   DROP TABLE dbo.AnalyticsEvents; 
GO
CREATE  TABLE AnalyticsEvents (
 NumericId int NOT NULL,
 Id uniqueidentifier NOT NULL,
 TypeId uniqueidentifier NOT NULL,
 SessionId uniqueidentifier NOT NULL,
 CorrelationId uniqueidentifier NULL,
 UserId uniqueidentifier NULL,
 Date datetimeoffset NOT NULL,
 Properties nvarchar(MAX) NOT NULL,
 ClientInfo nvarchar(MAX) NOT NULL
) 
GO


IF OBJECT_ID('dbo.Boards', 'u') IS NOT NULL 
   DROP TABLE dbo.Boards; 
GO
CREATE  TABLE Boards (
 NumericId int NOT NULL,
 Id uniqueidentifier NOT NULL,
 Name nvarchar(100) NOT NULL,
 Description nvarchar(500) NOT NULL,
 CreatedBy uniqueidentifier NOT NULL,
 CreatedDate datetimeoffset NOT NULL,
 ModifiedBy uniqueidentifier NULL,
 ModifiedDate datetimeoffset NULL,
 ArchivedBy uniqueidentifier NULL,
 ArchivedDate datetimeoffset NULL,
 Archived bit NOT NULL
)
GO


IF OBJECT_ID('dbo.BoardSharing', 'u') IS NOT NULL 
   DROP TABLE dbo.BoardSharing; 
GO
CREATE  TABLE BoardSharing (
 NumericId int NOT NULL,
 Id uniqueidentifier NOT NULL,
 SharedBy uniqueidentifier NOT NULL,
 SharedTo uniqueidentifier NOT NULL,
 SharedDate datetimeoffset NOT NULL,
 Level nvarchar(50) NOT NULL,
 Seen bit NOT NULL,
 Assigned bit NOT NULL,
 BoardId uniqueidentifier NOT NULL
)
GO


IF OBJECT_ID('dbo.Elements', 'u') IS NOT NULL 
   DROP TABLE dbo.Elements; 
GO
CREATE  TABLE Elements (
 NumericId int NOT NULL,
 Id uniqueidentifier NOT NULL,
 Name nvarchar(500) NOT NULL,
 CreatedBy uniqueidentifier NOT NULL,
 CreatedDate datetimeoffset NOT NULL,
 ModifiedBy uniqueidentifier NULL,
 ModifiedDate datetimeoffset NULL,
 ArchivedBy uniqueidentifier NULL,
 ArchivedDate datetimeoffset NULL,
 Archived bit NOT NULL,
 TemplateVariantId uniqueidentifier NOT NULL,
)
GO


IF OBJECT_ID('dbo.ElementSharing', 'u') IS NOT NULL 
   DROP TABLE dbo.ElementSharing; 
GO
CREATE  TABLE ElementSharing (
 NumericId int NOT NULL,
 Id uniqueidentifier NOT NULL,
 SharedBy uniqueidentifier NOT NULL,
 SharedDate datetimeoffset NOT NULL,
 SharedTo uniqueidentifier NOT NULL,
 Level nvarchar(50) NOT NULL,
 Seen bit NOT NULL,
 ElementId uniqueidentifier NOT NULL
)
GO

--->Target table list<---
IF OBJECT_ID('dbo.ProcessingHistory', 'u') IS NOT NULL 
   DROP TABLE dbo.ProcessingHistory; 
GO
CREATE TABLE ProcessingHistory (
NumericId int IDENTITY(1,1) PRIMARY KEY,
LastAnalyticsEventsNumericId int NOT NULL,
LastAnalyticsEventsProcessDate date NOT NULL,
EntryTimeStamp datetimeoffset NOT NULL,
LogsProcessed int
);
GO


IF OBJECT_ID('dbo.UserSessions', 'u') IS NOT NULL 
   DROP TABLE dbo.UserSessions; 
GO
CREATE TABLE UserSessions (
NumericId int IDENTITY(1,1) PRIMARY KEY,
UserId uniqueidentifier NOT NULL,
DataDate date NOT NULL,
SessionId uniqueidentifier NOT NULL,
SessionLength int
);
GO

IF OBJECT_ID('dbo.BoardDetails', 'u') IS NOT NULL 
   DROP TABLE dbo.BoardDetails; 
GO
CREATE TABLE BoardDetails (
Id uniqueidentifier PRIMARY KEY,
Name nvarchar(100) NOT NULL,
Created datetimeoffset NOT NULL,
CreatedDate date NOT NULL,
OwnerUserId uniqueidentifier NOT NULL,
SharedCount int,
LastRan datetimeoffset,
LastEdited datetimeoffset,
LastEditedDate date NOT NULL,
NumberofElements int,
Archived bit NOT NULL
);
GO

IF OBJECT_ID('dbo.BoardRuns', 'u') IS NOT NULL 
   DROP TABLE dbo.BoardRuns; 
GO
CREATE TABLE BoardRuns (
Id int PRIMARY KEY,
CONSTRAINT FK_BoardDetails_Id FOREIGN KEY (BoardId) REFERENCES BoardDetails(Id),
BoardId uniqueidentifier NOT NULL,
UserId uniqueidentifier NOT NULL,
DataDate date NOT NULL,
RunTime int
);


IF OBJECT_ID('dbo.ElementDetails', 'u') IS NOT NULL 
   DROP TABLE dbo.ElementDetails; 
GO
CREATE TABLE ElementDetails (
Id uniqueidentifier PRIMARY KEY,
Name nvarchar(100) NOT NULL,
Created datetimeoffset NOT NULL,
CreatedDate date NOT NULL,
OwnerUserId uniqueidentifier NOT NULL,
SharedCount int,
LastRan datetimeoffset,
LastEdited datetimeoffset,
LastEditedDate date NOT NULL,
Archived bit NOT NULL
);
GO


IF OBJECT_ID('dbo.ElementRuns', 'u') IS NOT NULL 
   DROP TABLE dbo.ElementRuns; 
GO
CREATE TABLE ElementRuns (
Id int PRIMARY KEY,
ElementId uniqueidentifier NOT NULL,
CONSTRAINT FK_ElementDetails_Id FOREIGN KEY (ElementId) REFERENCES ElementDetails(Id),
UserId uniqueidentifier NOT NULL,
DataDate date NOT NULL,
RunTime int
)
