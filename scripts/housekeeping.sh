#!/usr/bin/env bash
echo "Running housekeeping tasks against the LibraGoB database..."

event_username=$(cat /mnt/secrets/$KV_NAME/event-datasource-username)
event_password=$(cat /mnt/secrets/$KV_NAME/event-datasource-password)
event_url=$(cat /mnt/secrets/$KV_NAME/event-datasource-url)
event_host=$(echo "$event_url" | sed 's/jdbc:postgresql:\/\///' | sed 's/:5432//' | sed 's/\/.*//')
event_db=$(echo "$event_url" | sed 's/jdbc:postgresql:\/\///' | sed 's/:5432//' | sed 's/.*\///')

echo "Connecting to $event_db database at $event_host"

DB_HOST=$event_host
DB_USER=$event_username
PGPASSWORD=$event_password
DB_NAME=$event_db

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD}" --file=./sql/public_update_tables_housekeeping.sql

themis_gateway_username=$(cat /mnt/secrets/$KV_NAME/themis-gateway-dbusername)
themis_gateway_password=$(cat /mnt/secrets/$KV_NAME/themis-gateway-dbpassword)
themis_gateway_url=$(cat /mnt/secrets/$KV_NAME/themis-gateway-datasourceurl)
themis_gateway_host=$(echo "$themis_gateway_url" | sed 's/jdbc:postgresql:\/\///' | sed 's/:5432//' | sed 's/\/.*//')
themis_gateway_db=$(echo "$themis_gateway_url" | sed 's/jdbc:postgresql:\/\///' | sed 's/:5432//' | sed 's/.*\///')

echo "Connecting to $themis_gateway_db database at $themis_gateway_host"

DB_HOST=$themis_gateway_host
DB_USER=$themis_gateway_username
PGPASSWORD=$themis_gateway_password
DB_NAME=$themis_gateway_db

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD}" --file=./sql/audit_messages_housekeeping.sql
