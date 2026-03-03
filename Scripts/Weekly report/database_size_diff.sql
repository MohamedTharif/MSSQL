SELECT
                a.Instance_Name AS [Instance Name],
                a.Database_Names AS [Database Name],
                b.size2 AS [15 Days before DB size (MB)],
                a.size1 AS [Current size (MB)],
                (CAST(CAST(((a.size1 - b.size2)/b.size2 * 100) AS DECIMAL(6,2)) AS VARCHAR(100)) + '%') AS [Difference]
            FROM (
                SELECT
                    Database_Names,
                    Instance_Name,
                    [Size MB] AS size1
                FROM DBADB.dbo.DB_Meta
                WHERE Dates = CAST(GETDATE()-1 AS DATE)) AS a INNER JOIN (
                    SELECT
                        Database_Names,
                        Instance_Name,
                        [Size MB] AS size2
                    FROM DBADB.dbo.DB_Meta
                    WHERE Dates = CAST(GETDATE()-5 AS DATE)) AS b
                ON a.Database_Names = b.Database_Names
                    AND a.Instance_Name = b.Instance_Name
            WHERE a.Database_Names NOT IN ('master','model','msdb','DBADB','ReportServer','ReportServerTempDB')
            ORDER BY a.Instance_Name