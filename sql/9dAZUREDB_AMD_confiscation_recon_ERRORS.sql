\copy (select * from RECONCILIATION_ERRORS where RRID = &1) To '/tmp/ams-reporting/9dAZUREDB_AMD_confication_recon_ERRORS.csv' With CSV DELIMITER ','
