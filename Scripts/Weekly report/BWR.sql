
--peak_cpu_usage CDCMS
            SELECT 
capturetime,UsedCPU,FreeCPU
            FROM [DBADB].[dbo].[CPUUtilisationdata]
            WHERE capturetime >= '02-02-2026' and CaptureTime<'08-02-2026'
            ORDER BY UsedCPU DESC
			
--peak_cpu_usage SAPINT and AADHAR
SELECT *  FROM [DBADB].[dbo].[CPUUtilisationdata] WHERE time > cast(getdate()-7 as date) and time<cast(getdate() as date) order by time desc

--User Connections
SELECT 
                [CaptureDate] AS [Time],
                [Value] AS [User Transactions]
            FROM [DBADB].[dbo].[PerfMonData]
            WHERE capturedate > cast(getdate()-7 as date) and Capturedate<cast(getdate() as date)
                AND Counter LIKE '%:General Statistics:User Connections:'
            ORDER BY Value DESC
--PLE
SELECT 
                [CaptureDate] AS [Time],
                [Value] AS [Transactions]
            FROM [DBADB].[dbo].[PerfMonData]
            WHERE capturedate > cast(getdate()-7 as date) and Capturedate<cast(getdate() as date)
                AND Counter LIKE '%Page Life Expectancy%'
            ORDER BY value DESC
			
--peak_table_usage			
Declare @startdate time=CAST(GETDATE()-7 AS DATE);
Declare @enddate time='';

            SELECT TOP 10
                @@SERVERNAME AS [Instance Name],
                a.DBNAME AS [Database Name],
                a.Tablename AS [Table Name],
                b.size2 AS [7 Days Before Table Size (MB)],
                a.size1 AS [Current Table Size (MB)],
                (CAST(CAST(((a.size1 - b.size2)/b.size2 * 100) AS DECIMAL(18,2)) AS VARCHAR(100)) + ' %') AS [Difference]
                FROM (SELECT TOP 15 DBName, Tablename, SUM(TotalSpaceMB) AS size1 FROM [DBADB].[dbo].[TableSizeData]
                WHERE Date = @enddate GROUP BY DBName, Tablename ORDER BY SUM(TotalSpaceMB) DESC) AS a 
				INNER JOIN
				(SELECT TOP 15 DBName, Tablename, SUM(TotalSpaceMB) AS size2 
				FROM [DBADB].[dbo].[TableSizeData] WHERE Date = @startdate GROUP BY DBName, Tablename ORDER BY SUM(TotalSpaceMB) DESC) AS b ON a.DBName = b.DBName AND a.Tablename = b.Tablename

--db_size
Declare @startdate time=CAST(GETDATE()-7 AS DATE);
Declare @enddate time='';
				SELECT
                a.Instance_Name AS [Instance Name],
                a.Database_Names AS [Database Name],
                b.size2 AS [7 Days before DB size (MB)],
                a.size1 AS [Current size (MB)],
                (CAST(CAST(((a.size1 - b.size2)/b.size2 * 100) AS DECIMAL(6,2)) AS VARCHAR(100)) + '%') AS [Difference]
            FROM (
                SELECT
                    Database_Names,
                    Instance_Name,
                    [Size MB] AS size1
                FROM DBADB.dbo.DB_Meta
                WHERE Dates = @enddate AS a INNER JOIN (
                    SELECT
                        Database_Names,
                        Instance_Name,
                        [Size MB] AS size2
                    FROM DBADB.dbo.DB_Meta
                    WHERE Dates  >= @startdate ) AS b
                ON a.Database_Names = b.Database_Names
                    AND a.Instance_Name = b.Instance_Name
            WHERE a.Database_Names NOT IN ('master','model','msdb','DBADB','ReportServer','ReportServerTempDB')
            ORDER BY a.Instance_Name
