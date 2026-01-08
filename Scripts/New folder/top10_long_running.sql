 --top 10 long running quereies
WITH LastWeekData AS (
    SELECT
        StartTime,
        ElapsedTime,
        DatabaseName,
        REPLACE(REPLACE(StatementText, CHAR(13), ' '), CHAR(10), ' ') AS StatementText,
        StoredProcedure,
        COALESCE(WaitType, 'None') AS WaitType,
        UserName,
        logdate
    FROM [DBADB].[dbo].[longqrydetails]
    WHERE logdate >= DATEADD(DAY, -7, GETDATE())
      AND is_closed = 0                          -- optional
      AND ProgramName NOT LIKE '%SQLAgent%'     -- exclude SQL Agent jobs
),
Deduplicated AS (
    SELECT
        StartTime,
        ElapsedTime,
        DatabaseName,
        StatementText,
        StoredProcedure,
        WaitType,
        UserName,
        ROW_NUMBER() OVER (
            PARTITION BY DatabaseName, StatementText, StoredProcedure, UserName
            ORDER BY ElapsedTime DESC
        ) AS rn
    FROM LastWeekData
)
SELECT TOP 10
    StartTime        AS [Start Time],
    ElapsedTime      AS [Elapsed Time],
    DatabaseName     AS [Database Name],
    StatementText,
    StoredProcedure,
    WaitType,
    UserName
FROM Deduplicated
WHERE rn = 1
ORDER BY ElapsedTime DESC;
