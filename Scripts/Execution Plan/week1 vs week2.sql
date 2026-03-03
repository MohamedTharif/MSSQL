WITH Week2 AS
(
    SELECT 
        q.query_id,
        qt.query_sql_text,
        SUM(rs.count_executions) AS Executions,
        SUM(rs.avg_duration * rs.count_executions) 
            / NULLIF(SUM(rs.count_executions),0) / 1000.0 AS AvgDuration_ms
    FROM sys.query_store_query q
    JOIN sys.query_store_query_text qt 
        ON q.query_text_id = qt.query_text_id
    JOIN sys.query_store_plan p 
        ON q.query_id = p.query_id
    JOIN sys.query_store_runtime_stats rs 
        ON p.plan_id = rs.plan_id
    JOIN sys.query_store_runtime_stats_interval rsi 
        ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    WHERE rsi.start_time >= '2026-02-19'
      AND (
            qt.query_sql_text LIKE '%tbl_user_lifecycle%'
         OR qt.query_sql_text LIKE '%tbl_user_hits%'
         OR qt.query_sql_text LIKE '%tbl_user_subscriptions%'
         OR qt.query_sql_text LIKE '%tbl_ads2shistory%'
          )
      AND qt.query_sql_text NOT LIKE '%_backup%'
       AND qt.query_sql_text NOT LIKE '%ALter%'
       AND qt.query_sql_text NOT LIKE '%Create Nonclustered%'
       AND qt.query_sql_text NOT LIKE '%update statistics%'
    GROUP BY q.query_id, qt.query_sql_text
)

SELECT *
FROM Week2
ORDER BY AvgDuration_ms DESC;


WITH QData AS
(
    SELECT 
        q.query_id,
        qt.query_sql_text,
        CASE 
            WHEN rsi.start_time BETWEEN '2026-02-10' AND '2026-02-16 23:59:59'
                THEN 'Week1'
            WHEN rsi.start_time >= '2026-02-19'
                THEN 'Week2'
        END AS Period,
        rs.count_executions,
        rs.avg_duration
    FROM sys.query_store_query q
    JOIN sys.query_store_query_text qt 
        ON q.query_text_id = qt.query_text_id
    JOIN sys.query_store_plan p 
        ON q.query_id = p.query_id
    JOIN sys.query_store_runtime_stats rs 
        ON p.plan_id = rs.plan_id
    JOIN sys.query_store_runtime_stats_interval rsi 
        ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    WHERE (
            qt.query_sql_text LIKE '%tbl_user_lifecycle%'
         OR qt.query_sql_text LIKE '%tbl_user_hits%'
         OR qt.query_sql_text LIKE '%tbl_user_subscriptions%'
         OR qt.query_sql_text LIKE '%tbl_ads2shistory%'
          )
          AND qt.query_sql_text NOT LIKE '%_backup%'
       AND qt.query_sql_text NOT LIKE '%ALter%'
       AND qt.query_sql_text NOT LIKE '%Create Nonclustered%'
       AND qt.query_sql_text NOT LIKE '%update statistics%'
      AND (
            rsi.start_time BETWEEN '2026-02-10' AND '2026-02-16 23:59:59'
         OR rsi.start_time >= '2026-02-19'
          )
)

SELECT TOP 5
    query_id,
    MAX(CASE WHEN Period='Week1' 
        THEN avg_duration/1000.0 END) AS BeforeArchival_Avg_ms,
    MAX(CASE WHEN Period='Week2' 
        THEN avg_duration/1000.0 END) AS AfterArchival_Avg_ms
FROM QData
GROUP BY query_id
HAVING 
    MAX(CASE WHEN Period='Week1' THEN avg_duration END) IS NOT NULL
AND MAX(CASE WHEN Period='Week2' THEN avg_duration END) IS NOT NULL
ORDER BY BeforeArchival_Avg_ms DESC;