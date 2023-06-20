create or alter procedure dbo.SpElementDetails
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
	select  @ProcessingDate=isnull(max(NextProcessingDate), (select cast(min(CreatedDate) as date) from dbo.Elements)) from dbo.Tbl_RPD where ControlFlag='ED'
	--print	@ProcessingDate

	if @ProcessingDate=cast(GETDATE() as Date)
		begin
			--print @ProcessingDate
			--print (cast(GETDATE() as Date))
			print('Data already processed till '  + cast(@ProcessingDate as varchar))
			GOTO LastPoint
		end

	---Count the element sharing number
    select * into #Tbl_ElementSharing 
	from 
	(
	select 
		 ElementId
		,count(1) as ElementIdCount
	from dbo.ElementSharing
	where ElementId is not null
	group by ElementId
	) as t

	---Finding the element last run
    select * into #Tbl_ElementLastRun
	from 
	(
	select
		 e.Id as Id
		,max(ae.Date) as LastRun
	from 
	dbo.Elements as e 
	left join dbo.AnalyticsEvents as ae
	on (e.Id=ae.CorrelationId)
	where ae.TypeId= (select Id from AnalyticsEventTypes where Name in ('ElementStarted'))
	and cast(CreatedDate as Date) between @ProcessingDate and getdate()-1
	and e.Id is not null and ae.CorrelationId is not null
	group by e.Id
	) as t

	--select * from #Tbl_ElementLastRun
	---Finding the element last updated/deleted date and userid
    select * into #Tbl_ElementLastUpdatedDeleted 
	from 
	(
	select
		 e.Id as Id
		,max(ae.Date) as LastEditedDate
		,max(ae.UserId) as LastEdited
	from 
	dbo.Elements as e 
	left join dbo.AnalyticsEvents as ae
	on (e.Id=ae.CorrelationId)
	where (ae.TypeId in (select Id from AnalyticsEventTypes where Name in ('ElementUpdated','ElementDeleted')))
	and cast(CreatedDate as Date) between @ProcessingDate and getdate()-1
	and e.Id is not null and ae.CorrelationId is not null
	group by e.Id
	) as t

	--select data for full and incremental load
	IF Not EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ElementDetails' AND TABLE_SCHEMA = 'dbo')
		CREATE TABLE dbo.ElementDetails 
		(
		 Id   uniqueidentifier  NOT NULL,
		 Name   nvarchar (1000) NOT NULL,
		 Created   datetimeoffset (7) NULL,
		 CreatedDate   datetimeoffset (7) NOT NULL,
		 OwnerUserId   uniqueidentifier  NOT NULL,
		 SharedCount   int  NOT NULL,
		 LastRun   datetimeoffset (7) NULL,
		 LastEdited   uniqueidentifier  NULL,
		 LastEditedDate   datetimeoffset (7) NULL,
		 Archived datetimeoffset (7) NULL
		)

	--print 'Insert'
	INSERT INTO dbo.ElementDetails
           ( Id,Name,Created,CreatedDate,OwnerUserId,SharedCount,LastRun,LastEdited,LastEditedDate,Archived
		   ) 
		  select
		 e.Id as Id
		,e.Name as Name
		,cast(GETDATE() as datetimeoffset) as Created 
		,e.CreatedDate as CreatedDate
		,e.CreatedBy as OwnerUserId
		,isnull(es.ElementIdCount,0) as SharedCount
		,elr.LastRun as LastRun
		,elud.LastEdited as LastEdited
		,elud.LastEditedDate as LastEditedDate
		,ArchivedDate
	from dbo.Elements							as e
	left join #Tbl_ElementSharing				as es		on (e.Id=es.ElementId)
	left join #Tbl_ElementLastRun				as elr		on (e.Id=elr.Id)
	left join #Tbl_ElementLastUpdatedDeleted	as elud	on (e.Id=elud.Id)
	left join dbo.AnalyticsEvents				as ae on (ae.CorrelationId=elr.Id and ae.Date=elr.LastRun)
	where cast(e.CreatedDate as Date) between @ProcessingDate and getdate()-1
	and e.Id is not null

	--Next date running flag
	insert into dbo.Tbl_RPD(NextProcessingDate, ControlFlag) values(GETDATE(),'ED')

	LastPoint:

end


