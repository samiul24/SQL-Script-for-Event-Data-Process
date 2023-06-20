IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ElementRuns]') AND type in (N'U'))
	CREATE TABLE [dbo].[ElementRuns](
		[Id] int identity(1,1),
		[NumericId] [int] NULL,
		[ElementId] [varbinary](100) NULL,
		[UserId] [uniqueidentifier] NULL,
		[Element_Started] [datetimeoffset](7) NULL,
		[Element_Stopped] [datetimeoffset](7) NULL,
		[RunTime] [int] NULL,
		
	) ON [PRIMARY]
	GO

create or alter procedure SpElementRuns
As
declare @vId Int
declare @vNumericId Int
declare @vElementId varchar(250)
declare @vCorrelationId uniqueidentifier
declare @vUserId uniqueidentifier
declare @vTypeName varchar(25)
declare @vTypeControl varchar(25)
declare @vCreateDate datetimeoffset(7)
declare @vElementStart datetimeoffset(7)
declare @vElementStop datetimeoffset(7)
declare @ProcessingDate Date

select  @ProcessingDate=isnull(max(NextProcessingDate), (select cast(min(CreatedDate) as date) from dbo.Elements)) from dbo.Tbl_RPD where ControlFlag='ER'
--print	@ProcessingDate
if @ProcessingDate=cast(GETDATE() as Date)
	begin
		print('Data already processed till ' + cast(@ProcessingDate as varchar))
		GOTO LastPoint
	end

declare CurElement cursor
	for select distinct e.Id from elements e inner join AnalyticsEvents ae on ( e.id=ae.CorrelationId and ae.CorrelationId is not null) where cast(e.CreatedDate as Date) between @ProcessingDate and getdate()-1

	open CurElement;
	fetch next from CurElement into @vElementId;

	while @@FETCH_STATUS = 0
		begin
				set @vCorrelationId = null
				set @vUserId 		= null
				set @vTypeName		= null
				set @vTypeControl 	= null
				set @vCreateDate 	= null
				set @vElementStart 	= null
				set @vElementStop 	= null
				declare CurAnalyticsEvent cursor
					for select row_number() over( order by ae.NumericId, aet.Name) as Id, ae.NumericId, ae.CorrelationId, ae.UserId, aet.Name, ae.Date from elements e inner join AnalyticsEvents ae on (e.id=ae.CorrelationId) inner join AnalyticsEventTypes aet on (ae.TypeId=aet.Id) where ae.CorrelationId is not null and ae.CorrelationId=@vElementId and aet.Name in ('ElementStarted','ElementStopped') order by ae.NumericId, ae.Date;
					
					open CurAnalyticsEvent;
					fetch next from CurAnalyticsEvent into @vId, @vNumericId, @vCorrelationId, @vUserId, @vTypeName, @vCreateDate;
					while @@FETCH_STATUS = 0
						begin
							if @vId=1 and @vTypeName='ElementStarted' and @vTypeControl is null
							begin
								set @vElementStart=@vCreateDate
							end

							if @vTypeName='ElementStopped'
							begin
								set @vElementStop=@vCreateDate
								insert into ElementRuns(NumericId, ElementId, UserId, Element_Started, Element_Stopped, RunTime )
								values(@vNumericId, @vCorrelationId, @vUserId, @vElementStart, @vElementStop, datediff(second,isnull(@vElementStart, @vElementStop),isnull(@vElementStop,@vElementStart)))
								set @vTypeControl='ElementStarted'
							end

							if  @vId!=1 and @vTypeName='ElementStarted' and @vTypeControl='ElementStarted'
							begin
								set @vElementStart=@vCreateDate
								set @vTypeControl='ElementStopped'

							end

							fetch next from CurAnalyticsEvent into @vId, @vNumericId, @vCorrelationId, @vUserId, @vTypeName, @vCreateDate;
						end

				close CurAnalyticsEvent
				deallocate CurAnalyticsEvent
				set @vTypeControl=null
			fetch next from CurElement into @vElementId;
		end;
--delete from ElementRuns where Element_Started is null or Element_Stopped is null
close CurElement;
deallocate  CurElement;
print('Successfully completed')

--Next date running flag
insert into dbo.Tbl_RPD(NextProcessingDate, ControlFlag) values(GETDATE(),'ER')

LastPoint:


