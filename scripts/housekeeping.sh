#!/usr/bin/env bash
echo "Running housekeeping tasks agains the LibraGoB database..."

$event_username=$(cat /mnt/secrets/$KV_NAME/event-datasource-username)
$event_password=$(cat /mnt/secrets/$KV_NAME/event-datasource-password)
$event_url=$(cat /mnt/secrets/$KV_NAME/event-datasource-url)
$event_host=$(echo $event_url | sed 's/jdbc:postgresql:\/\///' | sed 's/:5432//'| sed 's/\/.*//')
$event_db=$(echo $event_url | sed 's/jdbc:postgresql:\/\///' | sed 's/:5432//' | sed 's/.*\///')

DB_HOST=$event_host
DB_USER=$event_username
PGPASSWORD=$event_password
DB_NAME=$event_db

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD} file=./sql/public_update_tables_housekeeping.sql"
