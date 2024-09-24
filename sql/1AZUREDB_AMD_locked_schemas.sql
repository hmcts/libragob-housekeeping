\copy (SELECT schema_id as "LockedSchemas" from locked_schemas) To './scripts/1AZUREDB_AMD_locked_schemas.csv' With CSV DELIMITER ','
