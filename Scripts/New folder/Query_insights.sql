--Query Insights logical_reads
SELECT TOP 5
    DB_NAME(st.dbid) AS [Database Name],
    OBJECT_NAME(st.objectid, st.dbid) AS [Object Name],
    SUBSTRING(
        st.text,
        (qs.statement_start_offset / 2) + 1,
        (
            (CASE 
                WHEN qs.statement_end_offset = -1 
                THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 
                ELSE qs.statement_end_offset 
            END - qs.statement_start_offset) / 2
        ) + 1
    ) AS [Query SQL Text],
    CAST(qs.total_logical_reads / 128.0 AS BIGINT) AS [Total Logical Reads (KB)],
    qs.execution_count AS [Execution Count Recent]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE 
    st.objectid IS NOT NULL
    AND st.dbid IN (
        DB_ID('Hpcl_Hdesk'),
        DB_ID('HPGASDB'),
        DB_ID('CentralDCMSHelpDesk'),
        DB_ID('CentralAccProd')
    )
ORDER BY qs.total_logical_reads DESC;


--query_insights_by_cpu_time
SELECT TOP 5
 DB_NAME(st.dbid) AS [Database Name],
    OBJECT_NAME(st.objectid, st.dbid) AS [Object Name],
    SUBSTRING(st.text, (qs.statement_start_offset / 2) + 1, 
        ((CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 
            ELSE qs.statement_end_offset END 
            - qs.statement_start_offset) / 2) + 1) AS [Query SQL Text],
    qs.total_worker_time AS [Total CPU Time (ms)],
	qs.execution_count AS [Execution Count Recent]
     -- Get the object name from object ID
FROM 
    sys.dm_exec_query_stats qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) st
WHERE 
    st.objectid IS NOT NULL AND st.dbid IN (DB_ID(''DBLoanguard''), DB_ID(''DBLoanguardHistory''))
ORDER BY 
    qs.total_worker_time DESC