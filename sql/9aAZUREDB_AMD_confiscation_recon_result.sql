\copy (select * from RECONCILIATION_RUNS order by RR_ID desc limit 1) To '/tmp/ams-reporting/9aAZUREDB_AMD_confiscation_recon_result.csv' With CSV DELIMITER ','
