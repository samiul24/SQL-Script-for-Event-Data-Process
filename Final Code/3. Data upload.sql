insert into AnalyticsEventTypes(NumericId, Id, Name)
SELECT	NumericId, 
		cast(Id as uniqueidentifier) as Id, 
		Name
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=C:\AnalyticsTestData.xlsx', [AnalyticsEventTypes$])


--insert into AnalyticsEventTypes(NumericId, Id, Name)
--SELECT	NumericId, 
--		cast(Id as uniqueidentifier) as Id, 
--		Name
--FROM AnalyticsTestData



insert into AnalyticsEvents(NumericId, Id, TypeId,SessionId, CorrelationId, UserId, Date, Properties, ClientInfo
)
SELECT	NumericId, 
		cast(Id as uniqueidentifier) as Id, 
		cast(case when TypeId='NULL' then '00000000-0000-0000-0000-000000000000' else TypeId  end  as uniqueidentifier) as TypeId,
		cast(case when SessionId='NULL' then '00000000-0000-0000-0000-000000000000' else SessionId  end as uniqueidentifier) as SessionId,
		cast(case when CorrelationId='NULL' then '00000000-0000-0000-0000-000000000000' else CorrelationId  end  as uniqueidentifier) as CorrelationId,
		cast(case when UserId='NULL' then '00000000-0000-0000-0000-000000000000' else UserId  end  as uniqueidentifier) as UserId,
		Date,
		Properties,
		ClientInfo
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=C:\AnalyticsTestData.xlsx', [AnalyticsEvents$])



insert into Boards(NumericId, Id, Name, Description, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, ArchivedBy, ArchivedDate, Archived)
SELECT	NumericId, 
		cast(Id as uniqueidentifier) as Id,
		Name,
		isnull(Description,'Test Description'),
		cast(case when CreatedBy='NULL' then '00000000-0000-0000-0000-000000000000' else CreatedBy  end  as uniqueidentifier) as CreatedBy,
		case when CreatedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else CreatedDate  end as CreatedDate, 
		cast(case when ModifiedBy='NULL' then '00000000-0000-0000-0000-000000000000' else ModifiedBy  end as uniqueidentifier) as ModifiedBy,
		case when ModifiedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else ModifiedDate  end as ModifiedDate,
		cast(case when ArchivedBy='NULL' then '00000000-0000-0000-0000-000000000000' else ArchivedBy  end  as uniqueidentifier) as ArchivedBy,
		case when ArchivedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else ArchivedDate  end as ArchivedDate,
		Archived
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=C:\AnalyticsTestData.xlsx', [Boards$])



insert into BoardSharing(NumericId, Id, SharedBy, SharedTo, SharedDate, Level, Seen, Assigned, BoardId)
SELECT	NumericId, 
		cast(Id as uniqueidentifier) as Id,
		cast(case when SharedBy='NULL' then '00000000-0000-0000-0000-000000000000' else SharedBy  end  as uniqueidentifier) as SharedBy, 
		cast(case when SharedTo='NULL' then '00000000-0000-0000-0000-000000000000' else SharedTo  end as uniqueidentifier) as SharedTo,
		case when SharedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else SharedDate  end as SharedDate,
		Level,
		Seen,
		Assigned,
		cast(case when BoardId='NULL' then '00000000-0000-0000-0000-000000000000' else BoardId  end  as uniqueidentifier) as BoardId
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=C:\AnalyticsTestData.xlsx', [BoardSharing$])



insert into Elements(NumericId, Id, Name, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, ArchivedBy, ArchivedDate, Archived, TemplateVariantId)
SELECT	NumericId, 
		cast(Id as uniqueidentifier) as Id,
		Name,
		cast(case when CreatedBy='NULL' then '00000000-0000-0000-0000-000000000000' else CreatedBy  end  as uniqueidentifier) as CreatedBy,
		case when CreatedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else CreatedDate  end as CreatedDate, 
		cast(case when ModifiedBy='NULL' then '00000000-0000-0000-0000-000000000000' else ModifiedBy  end as uniqueidentifier) as ModifiedBy,
		case when ModifiedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else ModifiedDate  end as ModifiedDate,
		cast(case when ArchivedBy='NULL' then '00000000-0000-0000-0000-000000000000' else ArchivedBy  end  as uniqueidentifier) as ArchivedBy,
		case when ArchivedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else ArchivedDate  end as ArchivedDate,
		Archived,
		cast(case when TemplateVariantId='NULL' then '00000000-0000-0000-0000-000000000000' else TemplateVariantId  end  as uniqueidentifier) as TemplateVariantId
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=C:\AnalyticsTestData.xlsx', [Elements$])



insert into ElementSharing(NumericId, Id, SharedBy, SharedTo, SharedDate, Level, Seen, ElementId)
SELECT	NumericId, 
		cast(Id as uniqueidentifier) as Id,
		cast(case when SharedBy='NULL' then '00000000-0000-0000-0000-000000000000' else SharedBy  end  as uniqueidentifier) as SharedBy, 
		cast(case when SharedTo='NULL' then '00000000-0000-0000-0000-000000000000' else SharedTo  end as uniqueidentifier) as SharedTo,
		case when SharedDate='NULL' then '2023-05-13 14:19:46.1008053 +00:00' else SharedDate  end as SharedDate,
		Level,
		Seen,
		cast(case when ElementId='NULL' then '00000000-0000-0000-0000-000000000000' else ElementId  end  as uniqueidentifier) as ElementId
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0; Database=C:\AnalyticsTestData.xlsx', [ElementSharing$])




