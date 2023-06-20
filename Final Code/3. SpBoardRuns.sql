IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BoardRuns]') AND type in (N'U'))
	CREATE TABLE [dbo].[BoardRuns](
		[ID] int identity(1,1),
		[NUMERICID] [int] NULL,
		[BoardId] [varbinary](100) NULL,
		[UserId] [uniqueidentifier] NULL,
		[BOARD_STARTED] [datetimeoffset](7) NULL,
		[BOARD_STOPPED] [datetimeoffset](7) NULL,
		[RUNTIME] [int] NULL,
	
	) ON [PRIMARY]
	GO

CREATE OR ALTER   PROCEDURE [dbo].[SpBoardRuns]
AS

BEGIN
DECLARE @vId		int
DECLARE @vEventTypeName varchar(50)
DECLARE @vCORRELATIONID uniqueidentifier
DECLARE @vUserId uniqueidentifier
DECLARE @ProcessingDate Date

DECLARE @vBoardEventsDate datetimeoffset(7)
DECLARE @vBoardStarted	  datetimeoffset(7)
DECLARE @vBoardStopped    datetimeoffset(7)

DECLARE @vHour	  float
DECLARE @vMinute  float
DECLARE @vSecond  float
DECLARE @vRuntime float

	select  @ProcessingDate=isnull(max(NextProcessingDate), (select cast(min(CreatedDate) as date) from dbo.Boards)) from dbo.Tbl_RPD where ControlFlag='BR'
	--print   @ProcessingDate

	if @ProcessingDate=cast(GETDATE() as Date)
		begin
			--print @ProcessingDate
			--print (cast(GETDATE() as Date))
			print('Data already processed till '  + cast(@ProcessingDate as varchar))
			GOTO LastPoint
		end
	
	DECLARE vcrAnalyticsEvents 
	CURSOR FOR
	SELECT DISTINCT ae.NUMERICID,--ae.ID,ae.TYPEID,
		t.Name,
		ae.CORRELATIONID,--ae.USERID,
		ae.DATE,--ae.PROPERTIES,ae.CLIENTINFO
		ae.UserId
	FROM  DBO.AnalyticsEventTypes t, DBO.ANALYTICSEVENTS ae, Boards b
	WHERE t.Id = ae.TypeId
	ANd	  t.Name IN ('BoardStarted','BoardStopped')
	AND	  ae.CorrelationId = b.Id
	and cast(B.CreatedDate as Date) between @ProcessingDate and getdate()-1
	and b.Id is not null and ae.CorrelationId is not null
	ORDER BY ae.CORRELATIONID, ae.NUMERICID

	OPEN vcrAnalyticsEvents
	FETCH NEXT FROM vcrAnalyticsEvents INTO @vId,@vEventTypeName,@vCORRELATIONID,@vBoardEventsDate,@vUserId

	IF @vEventTypeName='BoardStarted'
	BEGIN
		SELECT @vBoardStarted = @vBoardEventsDate
	END

	IF @vEventTypeName='BoardStopped'
	BEGIN
		SELECT @vBoardStopped = @vBoardEventsDate
	END

	WHILE @@FETCH_STATUS=0
		
		BEGIN
			IF ( @vBoardStarted<>@vBoardStopped) AND (@vBoardStarted IS NOT NULL AND @vBoardStopped IS NOT NULL)			
			BEGIN
			print(@vBoardStarted)
			print(@vBoardStopped)
			SELECT @vRunTime=0
			SELECT @vRunTime = datediff(ss,@vBoardStarted,@vBoardStopped)

			DELETE FROM BoardRuns WHERE  NUMERICID=@vId
				INSERT INTO BoardRuns(NUMERICID,BoardId,UserId, BOARD_STARTED,BOARD_STOPPED,RUNTIME)
				VALUES(@vId,@vCORRELATIONID,@vUserId,@vBoardStarted,@vBoardStopped,@vRunTime)
			
			SELECT @vBoardStopped = NULL
			END

			FETCH NEXT FROM vcrAnalyticsEvents INTO @vId,@vEventTypeName,@vCORRELATIONID,@vBoardEventsDate,@vUserId


			IF @vEventTypeName='BoardStarted'
			BEGIN
				SELECT @vBoardStarted = @vBoardEventsDate
			END

			IF @vEventTypeName='BoardStopped'
			BEGIN
				SELECT @vBoardStopped = @vBoardEventsDate
			END
		
		END
		
	CLOSE vcrAnalyticsEvents
	DEALLOCATE vcrAnalyticsEvents

	--Next date running flag
	insert into dbo.Tbl_RPD(NextProcessingDate,ControlFlag) values(GETDATE(), 'BR')

	LastPoint:

END

