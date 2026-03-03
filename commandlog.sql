

WITH Before19 AS
(
    SELECT *
    FROM
    (
        SELECT 
            DatabaseName,
            SchemaName,
            ObjectName,
            IndexName,
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
          --  AVG(DATEDIFF(SECOND, StartTime, EndTime)) AS AvgDurationSeconds,
            ROW_NUMBER() OVER 
            (
                PARTITION BY DatabaseName, SchemaName, ObjectName, IndexName
                ORDER BY StartTime DESC
            ) AS RN
        FROM [DBADB].[dbo].[CommandLog]
        WHERE CommandType LIKE '%ALTER_INDEX%'
          AND StartTime >= '2026-02-11'
          AND StartTime <  '2026-02-19'
          AND EndTime IS NOT NULL
    ) A
    WHERE RN = 1
)select * from before19 order by DurationSeconds desc;
go



with After19 AS
(
    SELECT *
    FROM
    (
        SELECT 
            DatabaseName,
            SchemaName,
            ObjectName,
            IndexName,
            StartTime,
            EndTime,
            DATEDIFF(SECOND, StartTime, EndTime) AS DurationSeconds,
            ROW_NUMBER() OVER 
            (
                PARTITION BY DatabaseName, SchemaName, ObjectName, IndexName
                ORDER BY StartTime DESC
            ) AS RN
        FROM [DBADB].[dbo].[CommandLog]
        WHERE CommandType LIKE '%ALTER_INDEX%'
          AND StartTime >= '2026-02-19'
          AND EndTime IS NOT NULL
          and objectname not like '%backup%'
    ) B
    WHERE RN = 1
)select * from after19 order by DurationSeconds desc





select avg(TotalDuration_Seconds) as avg_duration from
(
  SELECT 
    IndexName,
    objectname,
    SUM(DATEDIFF(SECOND, StartTime, EndTime)) AS [TotalDuration_Seconds(last15_days)]
FROM [DBADB].[dbo].[CommandLog]
WHERE CommandType LIKE '%ALTER_INDEX'
  AND StartTime >= '2026-02-06' and StartTime <= '2026-02-10'
  AND EndTime IS NOT NULL
  and objectname not like '%backup%'
GROUP BY IndexName,OBJECTNAME
ORDER BY [TotalDuration_Seconds(last15_days)] DESC
)A;

select avg(TotalDuration_Seconds) as avg_duration from
(
  SELECT 
    IndexName,
    objectname,
    SUM(DATEDIFF(SECOND, StartTime, EndTime)) AS TotalDuration_Seconds
FROM [DBADB].[dbo].[CommandLog]
WHERE CommandType LIKE '%ALTER_INDEX'
  AND StartTime >= '2026-02-20' --and StartTime <= '2026-02-10'
  AND EndTime IS NOT NULL
 and objectname not like '%backup%' --and indexname like '%PK%'
-- and ObjectName='tbl_user_lifecycle'
GROUP BY IndexName,OBJECTNAME
ORDER BY TotalDuration_Seconds DESC
)A;
