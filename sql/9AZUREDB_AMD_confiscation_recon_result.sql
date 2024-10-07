\copy (select * from RECONCILIATION_RUNS order by RR_ID desc limit 8;) To '/tmp/ams-reporting/9AZUREDB_AMD_confiscation_recon_result.csv' With CSV DELIMITER ','
