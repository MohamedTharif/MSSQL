CREATE or alter TRIGGER trg_Server_RSIPCheck
ON ALL SERVER
FOR LOGON
AS
BEGIN
    IF TRIGGER_NESTLEVEL() > 1
        RETURN;

    DECLARE
        @LoginName     NVARCHAR(128),
        @IPAddress     NVARCHAR(50),
        @AlertMessage  NVARCHAR(4000),
        @HTMLBody      NVARCHAR(MAX);

    SET @LoginName = ORIGINAL_LOGIN();

    -- Get client IP
    SELECT @IPAddress = client_net_address
    FROM sys.dm_exec_connections
    WHERE session_id = @@SPID;


	-- Ignore local server connections and system/service logins
	IF @IPAddress IS NULL
	   OR @IPAddress IN ('127.0.0.1', '::1')
	   OR @IPAddress = @@SERVERNAME
	   OR @LoginName LIKE 'NT Service%'
	    OR @IPAddress LIKE '<LOCAL%'
	BEGIN
		RETURN;
	END

    -- If IP is NOT allow-listed → alert
    IF NOT EXISTS (
        SELECT 1
        FROM dbadb.dbo.ValidIPAddress
        WHERE IPAddress = @IPAddress
    )
    BEGIN
        SET @AlertMessage = CONCAT(
            'ALERT: Login from unauthorized IP (',
            ISNULL(@IPAddress, 'Unknown'),
            ') by login ',
            @LoginName,
            ' at ',
            CONVERT(VARCHAR(30), GETDATE(), 120)
        );

        -- Avoid duplicate alerts within 10 seconds
        IF EXISTS (
            SELECT 1
            FROM dbadb.dbo.RSLoginAudit
            WHERE LoginName = @LoginName
              AND IPAddress = @IPAddress
              AND DATEDIFF(SECOND, LoginTime, GETDATE()) < 10
        )
            RETURN;

        INSERT INTO dbadb.dbo.RSLoginAudit
            (LoginName, IPAddress, AlertMessage)
        VALUES
            (@LoginName, @IPAddress, @AlertMessage);

        SET @HTMLBody = CONCAT(
            '<html><body>',
            '<p><b style="color:red;">', @AlertMessage, '</b></p>',
            '<p><b>Login Name:</b> ', @LoginName, '<br>',
            '<b>IP Address:</b> ', ISNULL(@IPAddress, 'Unknown'), '<br>',
            '<b>Time:</b> ', CONVERT(VARCHAR(30), GETDATE(), 120), '</p>',
            '</body></html>'
        );

        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'tharif',
            @recipients   = 'mohamed@geopits.com',
            @subject      = 'ALERT: Unauthorized login IP detected',
            @body         = @HTMLBody,
            @body_format  = 'HTML';
    END
END;
GO
