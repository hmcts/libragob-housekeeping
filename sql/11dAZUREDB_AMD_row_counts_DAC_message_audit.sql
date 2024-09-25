\copy (select count(*) from themis_dac.message_audit) To '/tmp/ams-reporting/11dAZUREDB_AMD_row_counts_DAC_message_audit.csv' With CSV DELIMITER ','
