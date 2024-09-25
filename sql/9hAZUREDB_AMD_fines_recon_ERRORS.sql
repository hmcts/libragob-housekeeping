\copy (select * from RECONCILIATION_ERRORS where RRID = &1) To '/tmp/ams-reporting/9hAZUREDB_AMD_fines_recon_ERRORS.csv' With CSV DELIMITER ','
