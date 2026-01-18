1.data compression tables


SELECT 
    t.name AS table_name,
    i.name AS index_name,
    p.data_compression_desc,
    COUNT(*) AS partition_count
FROM sys.tables t
JOIN sys.indexes i 
    ON t.object_id = i.object_id
JOIN sys.partitions p 
    ON i.object_id = p.object_id
GROUP BY 
    t.name, i.name, p.data_compression_desc
ORDER BY t.name;
