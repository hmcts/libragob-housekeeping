\copy (select state,count(*) from pg_stat_activity group by state order by 2 desc) To '/tmp/ams-reporting/4AZUREDB_AMD_thread_status_counts.csv' With CSV DELIMITER ','
