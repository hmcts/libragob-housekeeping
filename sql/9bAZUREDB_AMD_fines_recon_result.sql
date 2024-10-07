\copy (select * from RECONCILIATION_RUNS order by RR_ID desc limit 46;) To '/tmp/ams-reporting/9bAZUREDB_AMD_fines_recon_result.csv' With CSV DELIMITER ','
