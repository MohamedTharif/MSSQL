Procedure for adding New Data Files
--Procedure A: Adding a New Data File to the PRIMARY Filegroup
--Step 1: Add the data file
ALTER DATABASE ImageDB
ADD FILE
(
    NAME = ImageDB_Primary04,
    FILENAME = 'I:\Databases\IMAGEDB\ImageDB_Primary04.ndf',
    SIZE = 102400MB,        -- 100 GB initial size
    MAXSIZE = 8192000MB,    -- 6 TB limit
    FILEGROWTH = 65536MB    -- 64 GB growth
);
GO
--Step 2: Validate
SELECT name, size/128 AS size_MB, max_size/128 AS max_size_MB, growth/128 AS growth_MB FROM sys.database_files;

--Procedure B: Adding a New Data File to a Secondary Filegroup
--Step 1: Create the secondary filegroup (if not already present)
ALTER DATABASE ImageDB
ADD FILEGROUP ImageDB_DataFG;
GO
--Step 2: Add a new data file to the secondary filegroup
ALTER DATABASE ImageDB
ADD FILE
(
    NAME = ImageDB_Data04,
    FILENAME = 'I:\Databases\IMAGEDB\ImageDb4.ndf',
    SIZE = 102400MB,        -- 100 GB initial size
    MAXSIZE = 8192000MB,    -- 6 TB limit
    FILEGROWTH = 65536MB    -- 64 GB growth
)
TO FILEGROUP ImageDB_DataFG;
GO

--Step 3: Validate filegroup placement
SELECT
    fg.name AS filegroup_name,
    df.name AS logical_file_name,
    df.physical_name
FROM sys.database_files df
JOIN sys.filegroups fg
    ON df.data_space_id = fg.data_space_id
WHERE fg.name = 'ImageDB_DataFG';

