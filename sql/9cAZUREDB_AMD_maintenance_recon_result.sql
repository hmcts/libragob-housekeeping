\copy (select * from RECONCILIATION_RUNS order by RR_ID desc limit 1) To '/tmp/ams-reporting/9cAZUREDB_AMD_maintenance_recon_result.csv' With CSV DELIMITER ','
