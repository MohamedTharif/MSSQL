USE DBADB

GO

 

ALTER PROCEDURE dbo.usp_Send_RetailScan_DB_Schema_JSON

AS

BEGIN

    SET NOCOUNT ON;

 

    DECLARE @ServerName NVARCHAR(200) = @@SERVERNAME;

    DECLARE @DBName     NVARCHAR(200) = 'production_db_1';

    DECLARE @Subject    NVARCHAR(500);

    DECLARE @JSON       NVARCHAR(MAX);

 

    ------------------------------------------------------------

    -- 1. TABLES + COLUMNS

    ------------------------------------------------------------

    SET @Subject = 'RetailScan | ' + @ServerName + ' | Tables & Columns';

 

    SELECT @JSON = (

        SELECT 

            s.name AS schema_name,

            t.name AS table_name,

            c.name AS column_name,

            ty.name AS data_type,

            c.is_nullable

        FROM production_db_1.sys.tables t

        JOIN production_db_1.sys.schemas s  ON t.schema_id = s.schema_id

        JOIN production_db_1.sys.columns c  ON t.object_id = c.object_id

        JOIN production_db_1.sys.types ty   ON c.user_type_id = ty.user_type_id

        WHERE s.name NOT IN ('cdc','sys','INFORMATION_SCHEMA')

        ORDER BY s.name, t.name, c.column_id

        FOR JSON PATH, ROOT('TablesColumns')

    );

 

    EXEC msdb.dbo.sp_send_dbmail

        @profile_name = 'DBA',

        @recipients   = 'dccagent@geopits.com',

        @subject      = @Subject,

        @body         = @JSON,

        @body_format  = 'TEXT';

 

    ------------------------------------------------------------

    -- 2. PRIMARY KEYS

    ------------------------------------------------------------

    SET @Subject = 'RetailScan | ' + @ServerName + ' | Primary Keys';

 

    SELECT @JSON = (

        SELECT 

            s.name AS schema_name,

            t.name AS table_name,

            c.name AS column_name

        FROM production_db_1.sys.key_constraints kc

        JOIN production_db_1.sys.tables t   ON kc.parent_object_id = t.object_id

        JOIN production_db_1.sys.schemas s  ON t.schema_id = s.schema_id

        JOIN production_db_1.sys.index_columns ic 

            ON kc.parent_object_id = ic.object_id 

            AND kc.unique_index_id  = ic.index_id

        JOIN production_db_1.sys.columns c 

            ON ic.object_id  = c.object_id 

            AND ic.column_id = c.column_id

        WHERE kc.type = 'PK'

        FOR JSON PATH, ROOT('PrimaryKeys')

    );

 

    EXEC msdb.dbo.sp_send_dbmail

        @profile_name = 'DBA',

        @recipients   = 'dccagent@geopits.com',

        @subject      = @Subject,

        @body         = @JSON,

        @body_format  = 'TEXT';

 

    ------------------------------------------------------------

    -- 3. FOREIGN KEYS

    ------------------------------------------------------------

    SET @Subject = 'RetailScan | ' + @ServerName + ' | Foreign Keys';

 

    SELECT @JSON = (

        SELECT 

            fk.name  AS foreign_key_name,

            sp.name  AS schema_name,

            tp.name  AS parent_table,

            cp.name  AS parent_column,

            tr.name  AS referenced_table,

            cr.name  AS referenced_column

        FROM production_db_1.sys.foreign_keys fk

        JOIN production_db_1.sys.foreign_key_columns fkc 

            ON fk.object_id = fkc.constraint_object_id

        JOIN production_db_1.sys.tables tp   ON fkc.parent_object_id = tp.object_id

        JOIN production_db_1.sys.schemas sp  ON tp.schema_id = sp.schema_id

        JOIN production_db_1.sys.columns cp 

            ON fkc.parent_object_id  = cp.object_id 

            AND fkc.parent_column_id = cp.column_id

        JOIN production_db_1.sys.tables tr   ON fkc.referenced_object_id = tr.object_id

        JOIN production_db_1.sys.columns cr 

            ON fkc.referenced_object_id  = cr.object_id 

            AND fkc.referenced_column_id = cr.column_id

        FOR JSON PATH, ROOT('ForeignKeys')

    );

 

    EXEC msdb.dbo.sp_send_dbmail

        @profile_name = 'DBA',

        @recipients   = 'dccagent@geopits.com',

        @subject      = @Subject,

        @body         = @JSON,

        @body_format  = 'TEXT';

 

    ------------------------------------------------------------

    -- 4. INDEXES

    ------------------------------------------------------------

    SET @Subject = 'RetailScan | ' + @ServerName + ' | Indexes';

 

    SELECT @JSON = (

        SELECT 

            s.name AS schema_name,

            t.name AS table_name,

            i.name AS index_name,

            i.type_desc,

            c.name AS column_name

        FROM production_db_1.sys.indexes i

        JOIN production_db_1.sys.tables t   ON i.object_id = t.object_id

        JOIN production_db_1.sys.schemas s  ON t.schema_id = s.schema_id

        JOIN production_db_1.sys.index_columns ic 

            ON i.object_id  = ic.object_id 

            AND i.index_id  = ic.index_id

        JOIN production_db_1.sys.columns c 

            ON ic.object_id  = c.object_id 

            AND ic.column_id = c.column_id

        WHERE i.is_primary_key = 0

        FOR JSON PATH, ROOT('Indexes')

    );

 

    EXEC msdb.dbo.sp_send_dbmail

        @profile_name = 'DBA',

        @recipients   = 'dccagent@geopits.com',

        @subject      = @Subject,

        @body         = @JSON,

        @body_format  = 'TEXT';

 

END;

GO