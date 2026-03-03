WITH MonthlyData AS (
    SELECT
        DBNAME,
        SchemaName,
        TableName,
        DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1) AS MonthDate,
        MAX(UsedSpaceMB) AS UsedSpaceMB,
        MAX([rows]) AS [RowCount]
    FROM [DBADB].[dbo].[TableSizeData]
    GROUP BY
        DBNAME,
        SchemaName,
        TableName,
        DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1)
),
MonthlyGrowth AS (
    SELECT
        *,
        LAG(UsedSpaceMB) OVER (
            PARTITION BY DBNAME, SchemaName, TableName
            ORDER BY MonthDate
        ) AS PrevUsedSpaceMB,
        LAG([RowCount]) OVER (
            PARTITION BY DBNAME, SchemaName, TableName
            ORDER BY MonthDate
        ) AS PrevRowCount
    FROM MonthlyData
)
SELECT
    DBNAME,
    SchemaName,
    TableName,
    MonthDate,
    [RowCount],
    PrevRowCount,
    [RowCount] - PrevRowCount AS RowGrowth,
    CAST(
        CASE
            WHEN PrevRowCount = 0 OR PrevRowCount IS NULL
                THEN 0
            ELSE
                (([RowCount] - PrevRowCount) * 100.0) / PrevRowCount
        END AS DECIMAL(10,2)
    ) AS RowGrowthPercent,
    UsedSpaceMB,
    PrevUsedSpaceMB,
    UsedSpaceMB - PrevUsedSpaceMB AS SpaceGrowthMB,
    CAST(
        CASE
            WHEN PrevUsedSpaceMB = 0 OR PrevUsedSpaceMB IS NULL
                THEN 0
            ELSE
                ((UsedSpaceMB - PrevUsedSpaceMB) * 100.0) / PrevUsedSpaceMB
        END AS DECIMAL(10,2)
    ) AS SpaceGrowthPercent
FROM MonthlyGrowth
WHERE PrevRowCount IS NOT NULL and DBNAME='Vasdev_sel'
ORDER BY [RowCount] DESC;
