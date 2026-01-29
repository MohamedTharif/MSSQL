SELECT
    t.name AS TableName,
    i1.name AS Index1,
    i2.name AS Index2,
    i1cols.index_columns AS Index1Cols,
    i2cols.index_columns AS Index2Cols
FROM sys.indexes i1
JOIN sys.indexes i2
    ON i1.object_id = i2.object_id
   AND i1.index_id < i2.index_id
JOIN sys.tables t
    ON i1.object_id = t.object_id
CROSS APPLY (
    SELECT STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.key_ordinal)
    FROM sys.index_columns ic
    JOIN sys.columns c
        ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE ic.object_id = i1.object_id AND ic.index_id = i1.index_id AND ic.is_included_column = 0
) i1cols(index_columns)
CROSS APPLY (
    SELECT STRING_AGG(c.name, ',') WITHIN GROUP (ORDER BY ic.key_ordinal)
    FROM sys.index_columns ic
    JOIN sys.columns c
        ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE ic.object_id = i2.object_id AND ic.index_id = i2.index_id AND ic.is_included_column = 0
) i2cols(index_columns)
WHERE i1cols.index_columns LIKE i2cols.index_columns + '%'
  OR i2cols.index_columns LIKE i1cols.index_columns + '%'
ORDER BY t.name, i1.name, i2.name;


---
WITH idx AS (
    SELECT
        t.name AS TableName,
        i.name AS IndexName,
        i.index_id,
        i.object_id,
        i.type_desc,
        i.is_unique,
        i.has_filter,
        i.filter_definition,
        us.user_seeks + us.user_scans + us.user_lookups AS UsageCount,

        kc.KeyCols,
        ic.IncludeCols
    FROM sys.indexes i
    JOIN sys.tables t
        ON i.object_id = t.object_id

    -- Key columns
    CROSS APPLY (
        SELECT STRING_AGG(c.name, ',')
               WITHIN GROUP (ORDER BY ic.key_ordinal)
        FROM sys.index_columns ic
        JOIN sys.columns c
            ON ic.object_id = c.object_id
           AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id
          AND ic.index_id  = i.index_id
          AND ic.is_included_column = 0
    ) kc (KeyCols)

    -- Included columns
    CROSS APPLY (
        SELECT STRING_AGG(c.name, ',')
               WITHIN GROUP (ORDER BY c.name)
        FROM sys.index_columns ic
        JOIN sys.columns c
            ON ic.object_id = c.object_id
           AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id
          AND ic.index_id  = i.index_id
          AND ic.is_included_column = 1
    ) ic (IncludeCols)

    LEFT JOIN sys.dm_db_index_usage_stats us
        ON us.object_id = i.object_id
       AND us.index_id  = i.index_id
       AND us.database_id = DB_ID()

    WHERE i.type_desc = 'NONCLUSTERED'
)
SELECT
    a.TableName,
    a.IndexName AS Index1,
    b.IndexName AS Index2,
    a.KeyCols AS Index1Keys,
    b.KeyCols AS Index2Keys,
    a.IncludeCols AS Index1Includes,
    b.IncludeCols AS Index2Includes,
    a.UsageCount AS Index1Usage,
    b.UsageCount AS Index2Usage
FROM idx a
JOIN idx b
    ON a.object_id = b.object_id
   AND a.index_id < b.index_id
   AND a.type_desc = b.type_desc
   AND a.is_unique = b.is_unique
   AND a.has_filter = b.has_filter
   AND ISNULL(a.filter_definition,'') = ISNULL(b.filter_definition,'')
WHERE
      a.KeyCols = b.KeyCols
   OR a.KeyCols LIKE b.KeyCols + '%'
   OR b.KeyCols LIKE a.KeyCols + '%'
ORDER BY a.TableName;

