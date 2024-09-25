copy (SELECT schema_id as "LockedSchemas" from locked_schemas) To '${OPDIR}1AZUREDB_AMD_locked_schemas.csv' With CSV DELIMITER ','
