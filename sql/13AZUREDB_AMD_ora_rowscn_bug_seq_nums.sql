\copy (SELECT update_request_id,schema_id,sequence_number,previous_sequence_number from public.update_requests where status != 'COMPLETE' and sequence_number=previous_sequence_number order by 1 asc) To '/scripts/13AZUREDB_AMD_ora_rowscn_bug_seq_nums.csv' With CSV DELIMITER ','