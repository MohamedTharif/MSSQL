
DECLARE @from_lsn binary(10), @to_lsn binary(10);

-- Get LSN range
SET @from_lsn = sys.fn_cdc_get_min_lsn('CDC_1_AllCols');
SET @to_lsn   = sys.fn_cdc_get_max_lsn();


-- Query net changes
SELECT *
FROM cdc.fn_cdc_get_net_changes_CDC_1_AllCols(@from_lsn, @to_lsn, 'all');



DECLARE @from_lsn binary(10), @to_lsn binary(10);

-- Get LSN range
SET @from_lsn = sys.fn_cdc_get_min_lsn('CDC_1_AllCols');
SET @to_lsn   = sys.fn_cdc_get_max_lsn();

-- Detailed changes
SELECT *
FROM cdc.fn_cdc_get_all_changes_CDC_1_AllCols(@from_lsn, @to_lsn, 'all');
