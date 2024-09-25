\copy (SELECT schema_id as "LockedSchemas" from locked_schemas) To '/tmp/ams-reporting/1AZUREDB_AMD_locked_schemas.csv' With CSV DELIMITER ','
