USE DBADB;
GO
SET NOCOUNT ON;
IF OBJECT_ID('tempdb..#job_success', 'U') IS NOT NULL
        DROP TABLE #job_success;
		IF OBJECT_ID('tempdb..#job_step_success', 'U') IS NOT NULL
		DROP TABLE #job_step_success;

DECLARE @server_name NVARCHAR(255) = @@SERVERNAME; -- Change Optional
DECLARE @minutes_to_monitor SMALLINT = 480; --last 8 hours success check
-- Temporary table to hold email data
DECLARE @EmailData TABLE (
    JobId NVARCHAR(255),
    JobName NVARCHAR(255),
    StepName NVARCHAR(255),
    Schedule NVARCHAR(255),
    LastSuccessTime NVARCHAR(MAX),
    SuccessMessages NVARCHAR(MAX),
    LastFailureTime DATETIME,
    JobStartTime DATETIME 
);
WITH CTE_NORMALIZE_DATETIME_DATA AS (
		SELECT
			sysjobhistory.job_id AS sql_server_agent_job_id_guid,
			CAST(sysjobhistory.run_date AS VARCHAR(MAX)) AS run_date_string, 
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_time AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_time AS VARCHAR(MAX)) AS run_time_string,
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_duration AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_duration AS VARCHAR(MAX)) AS run_duration_string,
			sysjobhistory.run_status,
			sysjobhistory.message,
			sysjobhistory.instance_id
		FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
		WHERE sysjobhistory.run_status = 1
		AND sysjobhistory.step_id = 0),
	CTE_GENERATE_DATETIME_DATA AS (
		SELECT
			CTE_NORMALIZE_DATETIME_DATA.sql_server_agent_job_id_guid,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 5, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 7, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 1, 4) AS DATETIME) +
			CAST(STUFF(STUFF(CTE_NORMALIZE_DATETIME_DATA.run_time_string, 5, 0, ':'), 3, 0, ':') AS DATETIME) AS job_start_datetime,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 1, 2) AS INT) * 3600 +
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 3, 2) AS INT) * 60 + 
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 5, 2) AS INT) AS job_duration_seconds,
			CASE CTE_NORMALIZE_DATETIME_DATA.run_status
				WHEN 0 THEN 'Failure'
				WHEN 1 THEN 'Success'
				WHEN 2 THEN 'Retry'
				WHEN 3 THEN 'Canceled'
				ELSE 'Unknown'
			END AS job_status,
			CTE_NORMALIZE_DATETIME_DATA.message,
			CTE_NORMALIZE_DATETIME_DATA.instance_id
		FROM CTE_NORMALIZE_DATETIME_DATA)
	SELECT
		CTE_GENERATE_DATETIME_DATA.sql_server_agent_job_id_guid,
		( CTE_GENERATE_DATETIME_DATA.job_start_datetime) AS job_start_time_utc,
		( DATEADD(SECOND, ISNULL(CTE_GENERATE_DATETIME_DATA.job_duration_seconds, 0), CTE_GENERATE_DATETIME_DATA.job_start_datetime)) AS job_Success_time_utc
		
		INTO #job_success
	FROM CTE_GENERATE_DATETIME_DATA
	WHERE ( DATEADD(SECOND, ISNULL(CTE_GENERATE_DATETIME_DATA.job_duration_seconds, 0), CTE_GENERATE_DATETIME_DATA.job_start_datetime)) > DATEADD(MINUTE, -1 * @minutes_to_monitor, getdate());
	WITH CTE_NORMALIZE_DATETIME_DATA AS (
		SELECT
			sysjobhistory.job_id AS sql_server_agent_job_id_guid,
			CAST(sysjobhistory.run_date AS VARCHAR(MAX)) AS run_date_string, 
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_time AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_time AS VARCHAR(MAX)) AS run_time_string,
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_duration AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_duration AS VARCHAR(MAX)) AS run_duration_string,
			sysjobhistory.run_status,
			sysjobhistory.step_id,
			sysjobhistory.step_name,
			sysjobhistory.message,
			sysjobhistory.retries_attempted,
			sysjobhistory.sql_severity,
			sysjobhistory.sql_message_id,
			sysjobhistory.instance_id
		FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
		WHERE sysjobhistory.run_status = 1
		AND sysjobhistory.step_id > 0 ),
	CTE_GENERATE_DATETIME_DATA AS (
		SELECT
			CTE_NORMALIZE_DATETIME_DATA.sql_server_agent_job_id_guid,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 5, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 7, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 1, 4) AS DATETIME) +
			CAST(STUFF(STUFF(CTE_NORMALIZE_DATETIME_DATA.run_time_string, 5, 0, ':'), 3, 0, ':') AS DATETIME) AS job_start_datetime,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 1, 2) AS INT) * 3600 +
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 3, 2) AS INT) * 60 + 
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 5, 2) AS INT) AS job_duration_seconds,
			CASE CTE_NORMALIZE_DATETIME_DATA.run_status
				WHEN 0 THEN 'Failure'
				WHEN 1 THEN 'Success'
				WHEN 2 THEN 'Retry'
				WHEN 3 THEN 'Canceled'
				ELSE 'Unknown'
			END AS job_status,
			CTE_NORMALIZE_DATETIME_DATA.step_id,
			CTE_NORMALIZE_DATETIME_DATA.step_name,
			CTE_NORMALIZE_DATETIME_DATA.message,
			CTE_NORMALIZE_DATETIME_DATA.retries_attempted,
			CTE_NORMALIZE_DATETIME_DATA.sql_severity,
			CTE_NORMALIZE_DATETIME_DATA.sql_message_id,
			CTE_NORMALIZE_DATETIME_DATA.instance_id
		FROM CTE_NORMALIZE_DATETIME_DATA)
	SELECT
		CTE_GENERATE_DATETIME_DATA.sql_server_agent_job_id_guid,
		 CTE_GENERATE_DATETIME_DATA.job_start_datetime AS job_start_time_utc,
		DATEADD(SECOND, ISNULL(CTE_GENERATE_DATETIME_DATA.job_duration_seconds, 0), CTE_GENERATE_DATETIME_DATA.job_start_datetime) AS job_success_time_utc,
		CTE_GENERATE_DATETIME_DATA.step_id AS job_failure_step_number,
		ISNULL(CTE_GENERATE_DATETIME_DATA.message, '') AS job_step_success_message,
		CTE_GENERATE_DATETIME_DATA.sql_severity AS job_step_severity,
		CTE_GENERATE_DATETIME_DATA.retries_attempted,
		CTE_GENERATE_DATETIME_DATA.step_name,
		CTE_GENERATE_DATETIME_DATA.sql_message_id,
		CTE_GENERATE_DATETIME_DATA.instance_id
	INTO #job_step_success
	FROM CTE_GENERATE_DATETIME_DATA
	WHERE  DATEADD(SECOND, ISNULL(CTE_GENERATE_DATETIME_DATA.job_duration_seconds, 0), CTE_GENERATE_DATETIME_DATA.job_start_datetime) > DATEADD(MINUTE, -1 * @minutes_to_monitor, getdate());
	
	WITH ScheduleCTE AS (
    SELECT 
        j.sql_server_agent_job_id,
        CASE 
            -- Handle Daily Frequency
            WHEN j.Frequency = 'Daily' THEN 
                CASE 
                    WHEN j.DailyFrequency LIKE '%Repeat%' 
                    THEN 'Every day from ' + CAST(j.StartTime AS NVARCHAR(8)) + 
                         ' to ' + CAST(j.EndTime AS NVARCHAR(8)) + 
                         ', repeats every ' + 
                         NULLIF(CAST(SUBSTRING(j.DailyFrequency, CHARINDEX('every ', j.DailyFrequency) + 6, LEN(j.DailyFrequency)) AS NVARCHAR), '') + '.'
                    ELSE 'Every day at ' + CAST(j.StartTime AS NVARCHAR(8)) + '.'
                END

            -- Handle Weekly Frequency
            WHEN j.Frequency = 'Weekly' THEN 
                'Every ' + 
                -- Concatenate the days correctly
                REPLACE(j.DayInterval, ' ', ', ') + 
                ' starts at ' + CAST(j.StartTime AS NVARCHAR(8)) + 
                CASE 
                    WHEN j.DailyFrequency LIKE '%Repeat%' THEN 
                        ', repeats every ' + 
                        NULLIF(CAST(SUBSTRING(j.DailyFrequency, CHARINDEX('every ', j.DailyFrequency) + 6, LEN(j.DailyFrequency)) AS NVARCHAR), '') + '.'
                    ELSE '.' 
                END

            -- Handle Monthly Frequency
            WHEN j.Frequency = 'Monthly' THEN 
                'On the ' + 
                CASE 
                    WHEN j.DayInterval LIKE '%1%' THEN '1st '
                    WHEN j.DayInterval LIKE '%2%' THEN '2nd '
                    WHEN j.DayInterval LIKE '%3%' THEN '3rd '
                    WHEN j.DayInterval LIKE '%4%' THEN '4th '
                    WHEN j.DayInterval LIKE '%5%' THEN '5th '
                    WHEN j.DayInterval LIKE '%last%' THEN 'Last '
                    ELSE 'Unknown '
                END + 
                'day of the month at ' + CAST(j.StartTime AS NVARCHAR(8)) +
                CASE 
                    WHEN j.DailyFrequency LIKE '%Repeat%' THEN 
                        ', repeats every ' + 
                        NULLIF(CAST(SUBSTRING(j.DailyFrequency, CHARINDEX('every ', j.DailyFrequency) + 6, LEN(j.DailyFrequency)) AS NVARCHAR), '') + '.'
                    ELSE '.' 
                END

            -- Default case for other frequencies
            ELSE 'Other frequency or Not scheduled' + j.Frequency
        END AS Schedule
    FROM 
        [DBADB].[dbo].[sql_server_agent_job] j
)
INSERT INTO @EmailData (JobId, JobName, StepName, Schedule ,JobStartTime, SuccessMessages, LastSuccessTime , LastFailureTime)
	select j.sql_server_agent_job_id,
    j.sql_server_agent_job_name,
	js.step_name , 
	sc.Schedule ,
	max(js.job_start_time_utc) as Last_succes_Start_timestamp,
	js.job_step_success_message,
	max(CONVERT(VARCHAR(23), CAST(js.job_success_time_utc AS DATETIME), 121)) as Last_job_success_timestamp , 
	max(jf.job_failure_time_utc) as Last_job_failure_timestamp 
	from #job_step_success js inner join [DBADB].[dbo].[sql_server_agent_job] j 
        ON js.sql_server_agent_job_id_guid = j.sql_server_agent_job_id_guid inner join [DBADB].[dbo].[sql_server_agent_job_failure] jf on j.sql_server_agent_job_id=jf.sql_server_agent_job_id JOIN 
    ScheduleCTE sc ON j.sql_server_agent_job_id = sc.sql_server_agent_job_id
		WHERE jf.ticket_status = 'Open' --and js.step_name=jf.job_failure_step_name and jf.job_step_message_id>-1
		
		group by j.sql_server_agent_job_id,
    j.sql_server_agent_job_name,
	js.step_name , 
	sc.Schedule ,js.job_step_success_message
	having max(CONVERT(VARCHAR(23), CAST(js.job_success_time_utc AS DATETIME), 121)) >max(jf.job_failure_time_utc);

--select JobId, JobName, StepName, Schedule ,JobStartTime, SuccessMessages, LastSuccessTime  , LastFailureTime from @EmailData;

    
DECLARE @subject NVARCHAR(255),
        @body NVARCHAR(MAX),
        @JobId NVARCHAR(255),
        @JobName NVARCHAR(255),
        @StepName NVARCHAR(255),
        @Schedule NVARCHAR(255),
        @SuccessMessages NVARCHAR(MAX),
        @LastFailureTime DATETIME,
        @LastSuccessTime DATETIME,
		@JobStartTime DATETIME;

DECLARE EmailCursor CURSOR FOR 
SELECT JobId, JobName, StepName, Schedule ,JobStartTime, SuccessMessages, LastSuccessTime , LastFailureTime
FROM @EmailData;

OPEN EmailCursor;
FETCH NEXT FROM EmailCursor INTO 
    @JobId, @JobName, @StepName, @Schedule ,@JobStartTime, @SuccessMessages, @LastSuccessTime , @LastFailureTime;

WHILE @@FETCH_STATUS = 0
BEGIN

	
	SET @subject = 'RetailScan '+ @server_name +' '+@JobName + ' Failed Alert -> Closed ' ; -- Change

	 SET @body ='<html>
    <head>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f6f9; /* Light gray background */
                color: #495057; /* Darker text color for better contrast */
            }
            h2 {
                color: #007bff; /* Soft blue color for headings */
                text-align: center;
                margin-bottom: 20px;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin: 20px 0;
                background-color: #ffffff; /* White background for table */
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); /* Subtle shadow for table */
            }
            th, td {
                padding: 15px;
                border: 1px solid #dee2e6; /* Lighter border color */
                text-align: left;
            }
            th {
                background-color: #007bff; /* Blue color for header */
                color: #ffffff; /* White text in header */
            }
            tr:nth-child(even) {
                background-color: #f8f9fa; /* Light gray for even rows */
            }
            tr:hover {
                background-color: #f1f1f1; /* Light hover effect for rows */
            }
            p {
                text-align: center;
                margin-top: 20px;
                font-weight: bold;
                color: #6c757d; /* Gray text color */
            }
        </style>
    </head>
    <body>
        <h2>Failed Job Success Alert</h2>
        <table>
            <tr><th>Job Name</th><td>' + @JobName + '</td></tr>
            <tr><th>Step Name</th><td>' + ISNULL(@StepName, 'N/A') + '</td></tr>
            <tr><th>Success Message</th><td>' + ISNULL(@SuccessMessages, 'N/A') + '</td></tr>
            <tr><th>Last Run Start Time</th><td>' + CONVERT(NVARCHAR, @JobStartTime, 120) + '</td></tr>
            <tr><th>Last Failure Time</th><td>' + CONVERT(NVARCHAR, @LastFailureTime, 120) + '</td></tr>
            <tr><th>Last Success Time</th><td>' + CONVERT(NVARCHAR, @LastSuccessTime, 120) + '</td></tr>
            <tr><th>Schedule</th><td>' + @Schedule + '</td></tr>
        </table>
    </body>
</html>';
    -- Send the email
	--select @body;
   EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'DBA', -- Change
        @recipients = 'mssqlalerts@geopits.com', -- --Changemssqlsupport@geopits.com
        @subject = @subject,
        @body = @body,
        @body_format = 'HTML';
		
   UPDATE [DBADB].[dbo].[sql_server_agent_job_failure]
   SET ticket_status = 'Closed'
   WHERE sql_server_agent_job_id = @JobId and has_email_been_sent_to_operator =1 and ticket_status = 'Open';

    FETCH NEXT FROM EmailCursor INTO 
        @JobId, @JobName, @StepName, @Schedule ,@JobStartTime, @SuccessMessages, @LastSuccessTime , @LastFailureTime;
END

CLOSE EmailCursor;
DEALLOCATE EmailCursor;	

DROP TABLE #job_success,#job_step_success;
SET NOCOUNT OFF;
GO