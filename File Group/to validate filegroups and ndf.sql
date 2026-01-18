SELECT 
    name AS LogicalName,
    physical_name,
    size/128 AS Size_MB,
    FILEPROPERTY(name, 'SpaceUsed')/128 AS Used_MB
FROM sys.database_files
WHERE type_desc = 'ROWS';


SELECT df.name, fg.name AS FilegroupName
FROM sys.database_files df
JOIN sys.filegroups fg
ON df.data_space_id = fg.data_space_id;

SELECT 
    fg.name AS Filegroup,
    COUNT(o.object_id) AS ObjectCount
FROM sys.filegroups fg
LEFT JOIN sys.indexes i ON fg.data_space_id = i.data_space_id
LEFT JOIN sys.objects o ON i.object_id = o.object_id
GROUP BY fg.name
ORDER BY fg.name;

