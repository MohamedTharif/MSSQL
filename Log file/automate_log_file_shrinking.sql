DECLARE @CurrentFileSizeMB BIGINT;
DECLARE @FileName SYSNAME = 'vasdev_sel_log';   -- Logical log file name
DECLARE @DBName SYSNAME = 'vasdev_sel';         -- Database name
DECLARE @LogReuseWaitDesc SYSNAME;

------------------------------------------------------------
-- Get log file size
------------------------------------------------------------
SELECT @CurrentFileSizeMB = size * 8 / 1024
FROM sys.master_files
WHERE database_id = DB_ID(@DBName)
  AND name = @FileName;

------------------------------------------------------------
-- Get log_reuse_wait_desc
------------------------------------------------------------
SELECT @LogReuseWaitDesc = log_reuse_wait_desc
FROM sys.databases
WHERE name = @DBName;

------------------------------------------------------------
-- condition
------------------------------------------------------------
IF @CurrentFileSizeMB > 10240        -- 10 GB
   AND @LogReuseWaitDesc = 'NOTHING'
BEGIN
    EXEC (
        'USE [' + @DBName + '];
         DBCC SHRINKFILE (N''' + @FileName + ''', 1024);'
    );
END
ELSE
BEGIN
    PRINT 'Shrink skipped';
    PRINT 'Log Size (MB): ' + CAST(@CurrentFileSizeMB AS VARCHAR(20));
    PRINT 'log_reuse_wait_desc: ' + ISNULL(@LogReuseWaitDesc, 'UNKNOWN');
END;
