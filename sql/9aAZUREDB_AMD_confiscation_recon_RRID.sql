\copy (select max(RR_ID) from RECONCILIATION_RUNS) To '/tmp/ams-reporting/9aAZUREDB_AMD_confiscation_recon_RRID.csv' With CSV DELIMITER ','
