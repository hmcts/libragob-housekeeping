\copy (select max(RR_ID) from RECONCILIATION_RUNS) To '/tmp/ams-reporting/9eAZUREDB_AMD_fines_recon_RRID.csv' With CSV DELIMITER ','
