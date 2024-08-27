\copy (select date_trunc('minute',processed_date),sum(number_of_table_updates) from update_requests where status = 'COMPLETE' group by date_trunc('minute',processed_date) order by 1 desc limit 100) To '/scripts/12qAZUREDB_AMD_minute_completed_update_request_counts.csv' With CSV DELIMITER ','