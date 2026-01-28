SELECT data_compression_desc, COUNT(*) 
FROM sys.partitions
GROUP BY data_compression_desc;

SELECT 
    database_name,
    backup_start_date,
    backup_size / 1024 / 1024 AS backup_MB,
    compressed_backup_size / 1024 / 1024 AS compressed_MB,
    CAST(backup_size * 1.0 / compressed_backup_size AS DECIMAL(10,2)) AS compression_ratio
FROM msdb.dbo.backupset
WHERE database_name IN ('Smartfarm', 'CropInMaster')
  AND type = 'D'   -- Only FULL backups
ORDER BY backup_start_date DESC;

EXEC msdb.dbo.sp_help_jobstep @job_name = 'your job name';

SELECT 
    DB_NAME() AS db,
    p.data_compression_desc,
    COUNT(*) AS partitions
FROM sys.partitions p
GROUP BY p.data_compression_desc;

EXEC msdb.dbo.sp_help_jobstep @job_name = 'Your Maintenance Job Name';



