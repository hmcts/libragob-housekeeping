#!/usr/bin/env bash
echo "This is the AMS Reporting script"

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

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD}" --file=./sql/update_requests_reporting.sql

cat /tmp/output.csv

if [ -f /mnt/secrets/$KV_NAME/sftp-endpoint ] && [ -f /mnt/secrets/$KV_NAME/sftp-username ] && [ -f /mnt/secrets/$KV_NAME/sftp-password ]; then
  stfp_endpoint=$(cat /mnt/secrets/$KV_NAME/sftp-endpoint)
  sftp_username=$(cat /mnt/secrets/$KV_NAME/sftp-username)
  sftp_password=$(cat /mnt/secrets/$KV_NAME/sftp-password)

  echo "Uploading the report to SFTP server $sftp_endpoint"

  sftp $sftp_username@$sftp_endpoint:/ <<< $'put /tmp/output.csv'
fi
