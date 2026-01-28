Blocking
SELECT
    r.session_id AS blocked_session,
    r.blocking_session_id AS blocking_session,
    r.total_elapsed_time / 1000 AS elapsed_sec,
    r.wait_type,
    r.wait_resource,
    DB_NAME(r.database_id) AS database_name,
    t.text AS blocked_query
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id <> 0
ORDER BY r.total_elapsed_time DESC;
