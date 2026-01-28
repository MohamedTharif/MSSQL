File size greater than 1.5TB and having data file count >1 
WITH FileStats AS (
    SELECT 
        d.name AS DatabaseName,
        mf.name AS LogicalName,
        mf.physical_name,
        mf.size * 8.0 / 1024 / 1024 AS SizeTB,

        -- Autogrowth formatted
        CASE 
            WHEN mf.is_percent_growth = 1 
                THEN CAST(mf.growth AS VARCHAR(10)) + '%'
            ELSE 
                CAST(mf.growth * 8 / 1024 AS VARCHAR(10)) + ' MB'
        END AS AutoGrowth,

        -- Max size formatted
        CASE 
            WHEN mf.max_size = -1 THEN 'UNLIMITED'
            ELSE CAST(mf.max_size * 8.0 / 1024 / 1024 AS VARCHAR(20)) + ' TB'
        END AS MaxSize,

        -- Growth policy
        CASE 
            WHEN mf.max_size = -1 THEN 'Unlimited Growth'
            ELSE 'Restricted (Max Size Set)'
        END AS GrowthPolicy

    FROM sys.master_files mf
    JOIN sys.databases d
        ON mf.database_id = d.database_id
    WHERE mf.type = 0
),
FileCounts AS (
    SELECT 
        DatabaseName,
        COUNT(*) AS DataFileCount
    FROM FileStats
    GROUP BY DatabaseName
)
SELECT  
    f.DatabaseName,
    f.LogicalName,
    f.physical_name,
    CAST(f.SizeTB AS DECIMAL(10,2)) AS FileSizeTB,
    f.AutoGrowth,
    f.MaxSize,
    f.GrowthPolicy,
    c.DataFileCount
FROM FileStats f
JOIN FileCounts c
    ON f.DatabaseName = c.DatabaseName
WHERE 
    f.SizeTB > 1.5
    AND c.DataFileCount = 1
ORDER BY f.SizeTB DESC;
