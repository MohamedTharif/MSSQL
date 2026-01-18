3.Estimated size after compression

EXEC sp_estimate_data_compression_savings 
    @schema_name = 'dbo', 
    @object_name = 'NSDshold', 
    @index_id = NULL, 
    @partition_number = NULL, 
    @data_compression = 'ROW'
 
EXEC sp_estimate_data_compression_savings 
    @schema_name = 'dbo', 
    @object_name = 'NSDshold', 
    @index_id = NULL, 
    @partition_number = NULL, 
    @data_compression = 'PAGE'
 