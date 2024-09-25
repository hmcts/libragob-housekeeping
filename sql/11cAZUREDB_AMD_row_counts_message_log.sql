\copy (select count(*) from MESSAGE_LOG) To '/tmp/ams-reporting/11cAZUREDB_AMD_row_counts_message_log.csv' With CSV DELIMITER ','
