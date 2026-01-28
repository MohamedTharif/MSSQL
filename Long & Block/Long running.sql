Long running
SELECT
    r.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    r.status,
	    r.wait_time / 1000/60 AS wait_time_min,
    r.command,
    r.blocking_session_id,
    r.wait_type,

    r.cpu_time,
    r.total_elapsed_time / 1000 AS elapsed_sec,
    DB_NAME(r.database_id) AS database_name,
    SUBSTRING(
        t.text,
        r.statement_start_offset / 2 + 1,
        CASE 
            WHEN r.statement_end_offset = -1 
            THEN LEN(t.text)
            ELSE (r.statement_end_offset - r.statement_start_offset) / 2 + 1
        END
    ) AS running_statement
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id > 50
  AND r.total_elapsed_time > 300000   -- 5 minutes
ORDER BY r.total_elapsed_time DESC;



