\copy (select min(started_date) from RECONCILIATION_RUNS where RR_ID = &1) To '/tmp/ams-reporting/9jAZUREDB_AMD_maintenance_recon_rundate.csv' With CSV DELIMITER ','
