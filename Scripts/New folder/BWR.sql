--peak_table_usage
            SELECT TOP 10
                @@SERVERNAME AS [Instance Name],
                a.DBNAME AS [Database Name],
                a.Tablename AS [Table Name],
                b.size2 AS [7 Days Before Table Size (MB)],
                a.size1 AS [Current Table Size (MB)],
                (CAST(CAST(((a.size1 - b.size2)/b.size2 * 100) AS DECIMAL(18,2)) AS VARCHAR(100)) + ' %') AS [Difference]
                FROM (SELECT TOP 15 DBName, Tablename, SUM(TotalSpaceMB) AS size1 FROM [DBADB].[dbo].[TableSizeData]
                WHERE Date = CAST(GETDATE()-1 AS DATE) GROUP BY DBName, Tablename ORDER BY SUM(TotalSpaceMB) DESC) AS a 
				INNER JOIN
				(SELECT TOP 15 DBName, Tablename, SUM(TotalSpaceMB) AS size2 
				FROM [DBADB].[dbo].[TableSizeData] WHERE Date = CAST(GETDATE()-7 AS DATE) GROUP BY DBName, Tablename ORDER BY SUM(TotalSpaceMB) DESC) AS b ON a.DBName = b.DBName AND a.Tablename = b.Tablename

--db_size
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

--'peak_cpu_usage'
            SELECT TOP 10
capturetime,UsedCPU,FreeCPU
            FROM [DBADB].[dbo].[CPUUtilisationdata]
            WHERE capturetime >= DATEADD(DAY, -7, GETDATE())
            ORDER BY UsedCPU DESC
----'user_connection_insights'
--            SELECT
--                [CaptureDate] AS [Time],
--                [Value] AS [Transactions]
--            FROM [DBADB].[dbo].[PerfMonData]
--            WHERE CaptureDate >= DATEADD(DAY, -7, GETDATE())
--                AND Counter LIKE '%:General Statistics:User Connections:'
--'peak_user_connection_insights'
SELECT TOP 10
                [CaptureDate] AS [Time],
                [Value] AS [Transactions]
            FROM [DBADB].[dbo].[PerfMonData]
            WHERE CaptureDate >= DATEADD(DAY, -7, GETDATE())
                AND Counter LIKE '%:General Statistics:User Connections:'
            ORDER BY Value DESC
