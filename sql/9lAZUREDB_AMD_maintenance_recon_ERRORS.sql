\copy (select * from RECONCILIATION_ERRORS where RRID = &1) To '/tmp/ams-reporting/9lAZUREDB_AMD_maintenance_recon_ERRORS.csv' With CSV DELIMITER ','
