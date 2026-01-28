--Declare @date1 Date='2026-02-20'
----DECLARE @Tomorrow DATE = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));
--DECLARE @Tomorrow DATE = DATEADD(DAY, 1, @date1);


DECLARE @Tomorrow DATE = DATEADD(DAY, 1, CAST(GETDATE() AS DATE));

-- Make weekday calculation predictable
SET DATEFIRST 1;

IF DATEPART(WEEKDAY, @Tomorrow) = 6
   AND MONTH(DATEADD(DAY, 7, @Tomorrow)) <> MONTH(@Tomorrow)
BEGIN
    EXEC msdb.dbo.sp_send_dbmail
        @profile_name = 'DBA',
        @recipients   = 'ankush.jain@retail-scan.com;nitish.bhardwaj@retail-scan.com;hartej.singh@retail-scan.com',
        @copy_recipients='mssqlsupport@geopits.com;customersuccess@geopits.com;servicedelivery@geopits.com',
        @subject      = 'Approval Required: Monthly Server Restart',
        @body_format  = 'HTML',
        @body = 
        'Hi Team,<br><br>

        As part of our <b>regular monthly maintenance</b>, <b>tomorrow</b> is the last 
        <b>Saturday</b> of this month. Hence, we are requesting your <b>approval</b> 
        to proceed with the SQL Server restart.<br><br>

        Please confirm your approval so that we can proceed with the planned restart activity.<br><br>

        Kindly let us know if you need any further information or clarification from our end.<br><br>

        Regards,<br>
        MSSQL Support';
END
