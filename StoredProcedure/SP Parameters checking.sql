SP Parameters checking

    USE database_name;
GO

SELECT  
    OBJECT_NAME(object_id) AS ProcedureName,
    name AS ParameterName,
    TYPE_NAME(user_type_id) AS DataType,
    max_length,
    is_output
FROM sys.parameters
WHERE object_id IN (
    OBJECT_ID('dbo.SpGenerateTradingPandL'),
    OBJECT_ID('dbo.SpTax_GeneratePandL_TDS')
)
ORDER BY ProcedureName, parameter_id;