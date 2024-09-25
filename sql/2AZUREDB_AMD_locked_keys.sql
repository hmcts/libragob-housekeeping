\copy (SELECT instance_key as "LockedKeys" FROM themis_dac.instance_keys WHERE key_status = 'LOCKED') To '/tmp/ams-reporting/2AZUREDB_AMD_locked_keys.csv' With CSV DELIMITER ','
