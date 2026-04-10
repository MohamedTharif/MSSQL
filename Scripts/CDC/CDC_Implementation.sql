USE Minion;

--CDC Implementation 

--Database level CDC
EXEC sys.sp_cdc_enable_db;

--Table Level CDC
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'Table_1',
    @role_name     = NULL;

--Check CDC Status
USE Minion;
--Database Level
SELECT name, is_cdc_enabled
FROM sys.databases where is_cdc_enabled=1;
--Table Level
SELECT name,create_date,modify_date,is_tracked_by_cdc FROM sys.tables WHERE is_tracked_by_cdc = 1;


SELECT 
    t.name AS table_name,
    cdc.is_tracked_by_cdc
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
LEFT JOIN sys.tables cdc ON t.object_id = cdc.object_id
WHERE t.is_tracked_by_cdc = 1;

--Change Table details
SELECT * FROM cdc.change_tables;



--Multiple CDC Instance for One table
-- First capture instance
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'Table_2',
    @role_name     = NULL,
    @capture_instance = N'CDC_1_AllCols',
    @supports_net_changes = 1; --Net changes function will be created

-- Second capture instance with fewer columns
EXEC sys.sp_cdc_enable_table
    @source_schema = N'dbo',
    @source_name   = N'Table_2',
    @role_name     = NULL,
    @capture_instance = N'CDC_2_KeyCols',
    @captured_column_list = N'col1,col2',
    @supports_net_changes = 0;

--Disable CDC    

--Check for CDC Details
 EXEC sys.sp_cdc_help_change_data_capture
--Disable Table level CDC
 EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name   = N'Table_1',
    @capture_instance=N'dbo_Table_1';
--Disable Database Level CDC
 EXEC sys.sp_cdc_disable_db;
