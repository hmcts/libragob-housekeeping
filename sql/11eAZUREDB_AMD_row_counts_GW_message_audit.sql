\copy (select count(*) from themis_gateway.message_audit) To '/tmp/ams-reporting/11eAZUREDB_AMD_row_counts_GW_message_audit.csv' With CSV DELIMITER ','
