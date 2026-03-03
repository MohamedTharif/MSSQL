
CREATE OR ALTER PROCEDURE dbo.usp_SendErrorLog
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LastUploaded DATETIME;
    DECLARE @CurrentTime DATETIME = GETDATE();
    DECLARE @MaxSizeBytes BIGINT = 10240 --10485760; -- 10MB
    DECLARE @StartRow INT = 1;
    DECLARE @EndRow INT;
    DECLARE @Serial INT = 1;
    DECLARE @TotalRows INT;
    DECLARE @PartSize BIGINT;
    DECLARE @Subject NVARCHAR(400);
    DECLARE @Filename NVARCHAR(400);
    DECLARE @Body NVARCHAR(400);
    DECLARE @Query NVARCHAR(MAX);
    DECLARE @AllSuccess BIT = 1;
    DECLARE @ExecutionID BIGINT;

    INSERT INTO dbo.ErrorLogExecutionTracker DEFAULT VALUES;

    SET @ExecutionID = SCOPE_IDENTITY();

    -- Get last uploaded time
    SELECT TOP 1 @LastUploaded = LastUploadedDateTime
    FROM dbo.ErrorLogUploadTracker
    ORDER BY ID DESC;

    -- Clear previous staging
    DELETE FROM dbo.ErrorLogStaging;

    -- Load logs
-- Temporary table to capture error log
CREATE TABLE #RawErrorLog
(
    LogDate DATETIME,
    ProcessInfo VARCHAR(50),
    Text NVARCHAR(MAX)
);

INSERT INTO #RawErrorLog
EXEC xp_readerrorlog 0, 1;

-- Insert filtered rows into staging table
INSERT INTO dbo.ErrorLogStaging
(
    ExecutionID,
    RowNum,
    LogDate,
    ProcessInfo,
    Text
)
SELECT
    @ExecutionID,
    ROW_NUMBER() OVER (ORDER BY LogDate),
    LogDate,
    ProcessInfo,
    Text
FROM #RawErrorLog
WHERE LogDate > @LastUploaded;

DROP TABLE #RawErrorLog;

    SELECT @TotalRows = COUNT(*)
    FROM dbo.ErrorLogStaging
    WHERE  ExecutionID = @ExecutionID;

    IF @TotalRows = 0
        RETURN;

    ------------------------------------------------
    -- SPLITTING LOOP
    ------------------------------------------------
    WHILE @StartRow <= @TotalRows
    BEGIN
        SET @EndRow = @StartRow;

        WHILE @EndRow <= @TotalRows
        BEGIN
            SELECT @PartSize = SUM(DATALENGTH(Text))
            FROM dbo.ErrorLogStaging
           WHERE  ExecutionID = @ExecutionID
            AND RowNum BETWEEN @StartRow AND @EndRow;

            IF @PartSize > @MaxSizeBytes
                BREAK;

            SET @EndRow = @EndRow + 1;
        END

        IF @PartSize > @MaxSizeBytes
            SET @EndRow = @EndRow - 1;

        SET @Subject =
            'SQL Error Log Execution: ' +
            CAST(@ExecutionID AS VARCHAR(20)) +
            ' | Part: ' +
            CAST(@Serial AS VARCHAR(10));

        SET @Filename='ErrorLog_' + CAST(@ExecutionID AS VARCHAR(50))
                    + '_Part_' + CAST(@Serial AS VARCHAR) + '.txt';

        SET @Body='Attached Error Log Part ' + CAST(@Serial AS VARCHAR)


        SET @Query =
            'SELECT LogDate, ProcessInfo, Text
             FROM DBADB.dbo.ErrorLogStaging
             WHERE ExecutionID = ' + CAST(@ExecutionID AS VARCHAR(20)) + '
             AND RowNum BETWEEN ' + CAST(@StartRow AS VARCHAR(20)) + '
             AND ' + CAST(@EndRow AS VARCHAR(20)) + '
             ORDER BY LogDate';

        BEGIN TRY

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'th1',
                @recipients = 'mohamed@geopits.com',
                @subject = @Subject,
                @body = @Body,
                @query = @Query,
                @attach_query_result_as_file = 1,
                @query_attachment_filename =@Filename,
                @query_result_no_padding = 1,
                @query_result_width = 32767;

        END TRY
        BEGIN CATCH
            SET @AllSuccess = 0;
        END CATCH

        SET @StartRow = @EndRow + 1;
        SET @Serial = @Serial + 1;
    END

    -- Update tracker only if all mails succeeded
    IF @AllSuccess = 1
    BEGIN
        UPDATE dbo.ErrorLogUploadTracker
        SET LastUploadedDateTime = @CurrentTime,
            ModifiedDate = GETDATE()
        WHERE ID = (SELECT MAX(ID) FROM dbo.ErrorLogUploadTracker);
    END
END
GO