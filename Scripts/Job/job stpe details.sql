SELECT TOP (200)
    j.name AS JobName,

    -- Step details
    h.step_id AS StepID,
    CASE 
        WHEN h.step_id = 0 THEN 'Job Outcome'
        ELSE js.step_name
    END AS StepName,

    -- Run datetime
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS RunDateTime,

    -- Duration in HH:MM:SS
    RIGHT('0' + CAST(h.run_duration / 10000 AS VARCHAR(2)), 2) + ':' +
    RIGHT('0' + CAST((h.run_duration % 10000) / 100 AS VARCHAR(2)), 2) + ':' +
    RIGHT('0' + CAST(h.run_duration % 100 AS VARCHAR(2)), 2) AS RunDuration,

    -- Status
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
        ELSE 'Unknown'
    END AS StepStatus,

    h.message
FROM msdb.dbo.sysjobhistory h
JOIN msdb.dbo.sysjobs j
    ON j.job_id = h.job_id
LEFT JOIN msdb.dbo.sysjobsteps js
    ON js.job_id = h.job_id
   AND js.step_id = h.step_id
WHERE h.job_id = 'FD37EF32-01B4-48A6-B75B-B6500B416820'
ORDER BY
    msdb.dbo.agent_datetime(h.run_date, h.run_time) DESC,
    h.step_id;
