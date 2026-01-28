SELECT
    r.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    r.status,
    r.command,
    r.blocking_session_id,
    r.wait_type,
    r.wait_resource,
    r.total_elapsed_time / 1000 AS elapsed_sec,
    r.cpu_time,
    r.reads,
    r.writes,
    DB_NAME(r.database_id) AS database_name,
    t.text
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s
    ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id > 50
ORDER BY r.total_elapsed_time DESC;
