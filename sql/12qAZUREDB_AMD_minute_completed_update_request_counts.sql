\copy (select date_trunc('minute',processed_date),sum(number_of_table_updates) from update_requests where status = 'COMPLETE' and created_date is not null and processed_date is not null and created_date > current_date group by date_trunc('minute',processed_date) order by 1 desc limit 120) To '/tmp/ams-reporting/12qAZUREDB_AMD_minute_completed_update_request_counts.csv' With CSV DELIMITER ','
