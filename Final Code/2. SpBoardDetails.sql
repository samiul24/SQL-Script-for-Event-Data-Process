create or alter procedure dbo.SpBoardDetails
as
begin
	declare @LastMaxRecordId int
	declare @CurrentMaxRecordId int
	declare @ProcessingDate Date

	---Create table for record processing date
	IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Tbl_RPD' AND TABLE_SCHEMA = 'dbo')
		create table dbo.Tbl_RPD
		(
		Id Int Identity(1,1),
		NextProcessingDate Date Default GetDate(),
		ControlFlag varchar(5)
		)
	select  @ProcessingDate=isnull(max(NextProcessingDate), (select cast(min(CreatedDate) as date) from dbo.Boards)) from dbo.Tbl_RPD where ControlFlag='BD'
	--print @ProcessingDate

	if @ProcessingDate=cast(GETDATE() as Date)
		begin
			--print @ProcessingDate
			--print (cast(GETDATE() as Date))
			print('Data already processed till '  + cast(@ProcessingDate as varchar))
			GOTO LastPoint
		end

	---Count the board sharing number
    select * into #Tbl_BoardSharing 
	from 
	(
	select 
		 BoardId
		,count(1) as BoardIdCount
	from dbo.BoardSharing
	where BoardId is not null
	group by BoardId
	) as t

	---Finding the board last run
    select * into #Tbl_BoardLastRun
	from 
	(
	select
		 b.Id as Id
		,max(ae.Date) as LastRun
	from 
	dbo.Boards as b 
	left join dbo.AnalyticsEvents as ae
	on (b.Id=ae.CorrelationId)
	where ae.TypeId= (select Id from AnalyticsEventTypes where Name in ('BoardStarted'))
	and cast(CreatedDate as Date) between @ProcessingDate and getdate()-1
	and b.Id is not null and ae.CorrelationId is not null
	group by b.Id
	) as t
	--select * from #Tbl_BoardLastRun

	---Finding the board last updated/deleted date and userid
    select * into #Tbl_BoardLastUpdatedDeleted 
	from 
	(
	select
		 b.Id as Id
		,max(ae.Date) as LastEditedDate
		,max(ae.UserId) as LastEdited
	from 
	dbo.Boards as b 
	left join dbo.AnalyticsEvents as ae
	on (b.Id=ae.CorrelationId)
	where (ae.TypeId in (select Id from AnalyticsEventTypes where Name in ('BoardUpdated','BoardDeleted')))
	and cast(CreatedDate as Date) between @ProcessingDate and getdate()-1
	and b.Id is not null and ae.CorrelationId is not null
	group by b.Id
	) as t

	--select data for full and incremental load
	IF Not EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'BoardDetails' AND TABLE_SCHEMA = 'dbo')
		CREATE TABLE dbo.BoardDetails 
		(
		 Id   uniqueidentifier  NOT NULL,
		 Name   nvarchar (100) NOT NULL,
		 Created   datetimeoffset (7) NULL,
		 CreatedDate   datetimeoffset (7) NOT NULL,
		 OwnerUserId   uniqueidentifier  NOT NULL,
		 SharedCount   int  NOT NULL,
		 LastRun   datetimeoffset (7) NULL,
		 LastEdited   uniqueidentifier  NULL,
		 LastEditedDate   datetimeoffset (7) NULL,
		 NumberofElements int,
		 Archived datetimeoffset (7) NULL
		)

	IF Not EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProcessingHistory' AND TABLE_SCHEMA = 'dbo')
		CREATE TABLE dbo.ProcessingHistory 
		(
		 Id   int identity(1,1),
		 LastAnalyticsEventsNumericId int,
		 LastAnalyticsEventsProcessDate Date,
		 EntryTimeStamp Datetimeoffset(7) default cast(getdate() as Datetimeoffset),
		 LogsProcessed int,
		 ErroInCorrelationId int
		)

	IF Not EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UserSessions' AND TABLE_SCHEMA = 'dbo')
		CREATE TABLE dbo.UserSessions(
			Id int IDENTITY(1,1) NOT NULL,
			UserId uniqueidentifier ,
			SessionDate date ,
			SessionId uniqueidentifier ,
			SessionLength int
			)

	--print 'Insert'
	INSERT INTO dbo.BoardDetails
           ( Id, Name,Created,CreatedDate,OwnerUserId,SharedCount,LastRun,LastEdited,LastEditedDate,NumberofElements,Archived
		   ) 
		  select
		 b.Id as Id
		,b.Name as Name
		,cast(GETDATE() as datetimeoffset) as Created 
		,b.CreatedDate as CreatedDate
		,b.CreatedBy as OwnerUserId
		,isnull(bs.BoardIdCount,0) as SharedCount
		,blr.LastRun as LastRun
		,blud.LastEdited as LastEdited
		,blud.LastEditedDate as LastEditedDate
		,isnull(len(SUBSTRING(ae.Properties,CHARINDEX('elementIds', ae.Properties),CHARINDEX('', ae.Properties)))-len(replace(SUBSTRING(ae.Properties,CHARINDEX('elementIds', ae.Properties),CHARINDEX('', ae.Properties)),',','')),0) as NumberofElements
		,ArchivedDate
	from dbo.Boards							as b
	left join #Tbl_BoardSharing				as bs		on (b.Id=bs.BoardId)
	left join #Tbl_BoardLastRun				as blr		on (b.Id=blr.Id)
	left join #Tbl_BoardLastUpdatedDeleted  as blud	on (b.Id=blud.Id)
	left join dbo.AnalyticsEvents			as ae on (ae.CorrelationId=blr.Id and ae.Date=blr.LastRun)
	where cast(b.CreatedDate as Date) between @ProcessingDate and getdate()-1
	and b.Id is not null

--Processing History
insert into dbo.ProcessingHistory(LastAnalyticsEventsProcessDate, LogsProcessed, LastAnalyticsEventsNumericId, ErroInCorrelationId)
select  t1.ProcessDate as LastAnalyticsEventsProcessDate, 
		isnull(t1.LogsProcessed,0) as LogsProcessed, 
		t2.LastAnalyticsEventsNumericId, 
		isnull(t3.ErroInCorrelationId,0) as ErroInCorrelationId
from (
select cast( date as date) ProcessDate, count(1) as LogsProcessed
from dbo.AnalyticsEvents
where cast(Date as Date) between @ProcessingDate and getdate()-1
group by cast( date as date)
) as t1 left join 
(
select cast( date as date) ProcessDate, max(NumericID) as LastAnalyticsEventsNumericId 
from dbo.AnalyticsEvents
where cast(Date as Date) between @ProcessingDate and getdate()-1
group by cast( date as date)
) as t2 on (t1.ProcessDate=t2.ProcessDate) left join 

(
select cast( date as date) ProcessDate, count(CorrelationId) as ErroInCorrelationId 
from dbo.AnalyticsEvents
where CorrelationId is null
and  cast(Date as Date) between @ProcessingDate and getdate()-1
group by cast( date as date)
) as t3 on (t1.ProcessDate=t3.ProcessDate)
order by t1.ProcessDate

--Session
insert into dbo.UserSessions(UserId, SessionDate, SessionId, SessionLength)
select	UserId, 
		cast( min(date) as date) as SessionDate, 
		SessionId, 
		datediff(second, min(date), max(date)) as SessionLength
from dbo.AnalyticsEvents
where CorrelationId is not null 
and SessionId is not null
and UserId is not null 
and  cast(Date as Date) between @ProcessingDate and getdate()-1
group by UserId, cast( date as date), SessionId
order by cast( date as date)

--Next date running flag
insert into dbo.Tbl_RPD(NextProcessingDate,ControlFlag) values(GETDATE(), 'BD')

	LastPoint:

end


