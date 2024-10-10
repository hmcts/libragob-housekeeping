#!/usr/bin/env bash
####################################################### This is the AMD AzureDB Healthcheck Script, and the associated documentation is in Ensemble under the "Libra System Admin Documents" area:
####################################################### "GoB Phase 1 - Oracle_Postgres DB Checks_v11.5_MAP.docx" is the latest version as of 01/08/2024
echo "Script Version 6.0: Check #6"
mkdir /tmp/ams-reporting/
OPDIR="/tmp/ams-reporting/"
OUTFILE="${OPDIR}AZ_ThemisGOB_DB001_AMD"
OUTFILE_LOG="${OPDIR}AZ_ThemisGOB_DB001_AMD.log"
rm -f *.csv $OUTFILE $OUTFILE_LOG
echo $(date "+%d/%m/%Y %T") > $OUTFILE

###############################################################
### Set-up DB connection variables, extracted from KeyVault ###
###############################################################
# EventDB connection variables
event_username=$(cat /mnt/secrets/$KV_NAME/event-datasource-username)
event_password=$(cat /mnt/secrets/$KV_NAME/event-datasource-password)
event_url=$(cat /mnt/secrets/$KV_NAME/event-datasource-url)
event_host=`echo $event_url | awk -F"\/\/" {'print $2'} | awk -F":" {'print $1'}`
event_port=`echo $event_url | awk -F":" {'print $4'} | awk -F"\/" {'print $1'}`
event_db=`echo $event_url | awk -F":" {'print $4'} | awk -F"\/" {'print $2'}`

# PostgresDB connection variables
#postgres_username=`cat /mnt/secrets/$KV_NAME/themis-gateway-dbusername`
#postgres_password=`cat /mnt/secrets/$KV_NAME/themis-gateway-dbpassword`
#postgres_url=`cat /mnt/secrets/$KV_NAME/themis-gateway-datasourceurl`
#postgres_host=`echo $postgres_url | awk -F"\/\/" {'print $2'} | awk -F":" {'print $1'}`
#postgres_port=`echo $postgres_url | awk -F":" {'print $4'} | awk -F"\/" {'print $1'}`
#postgres_db=`echo $postgres_url | awk -F":" {'print $4'} | awk -F"\/" {'print $2'}

postgres_username=edb_amd
postgres_password=edb_read_0nly
postgres_host=libragob-test.postgres.database.azure.com
postgres_port=5432
postgres_db=postgres

# ConfiscationDB connection variables
#confiscation_username=$(cat /mnt/secrets/$KV_NAME/confiscation-datasource-username)
#confiscation_password=$(cat /mnt/secrets/$KV_NAME/confiscation-datasource-password)
#confiscation_url=$(cat /mnt/secrets/$KV_NAME/confiscation-datasource-url)
#confiscation_host=`echo $confiscation_url | awk -F"\/\/" {'print $2'} | awk -F":" {'print $1'}`
#confiscation_port=`echo $confiscation_url | awk -F":" {'print $4'} | awk -F"\/" {'print $1'}`
#confiscation_db=`echo $confiscation_url | awk -F":" {'print $4'} | awk -F"\/" {'print $2'}`

# FinesDB connection variables
#fines_username=$(cat /mnt/secrets/$KV_NAME/fines-datasource-username)
#fines_password=$(cat /mnt/secrets/$KV_NAME/fines-datasource-password)
#fines_url=$(cat /mnt/secrets/$KV_NAME/fines-datasource-url)
#fines_host=`echo $fines_url | awk -F"\/\/" {'print $2'} | awk -F":" {'print $1'}`
#fines_port=`echo $fines_url | awk -F":" {'print $4'} | awk -F"\/" {'print $1'}`
#fines_db=`echo $fines_url | awk -F":" {'print $4'} | awk -F"\/" {'print $2'}`

# MaintenanceDB connection variables
#maintenance_username=$(cat /mnt/secrets/$KV_NAME/maintenance-datasource-username)
#maintenance_password=$(cat /mnt/secrets/$KV_NAME/maintenance-datasource-password)
#maintenance_url=$(cat /mnt/secrets/$KV_NAME/maintenance-datasource-url)
#maintenance_host=`echo $maintenance_url | awk -F"\/\/" {'print $2'} | awk -F":" {'print $1'}`
#maintenance_port=`echo $maintenance_url | awk -F":" {'print $4'} | awk -F"\/" {'print $1'}`
#maintenance_db=`echo $maintenance_url | awk -F":" {'print $4'} | awk -F"\/" {'print $2'}`

confiscation_username=edb_amd
confiscation_password=edb_read_0nly
confiscation_host=libragob-test.postgres.database.azure.com
confiscation_port=5432
confiscation_db=nm_confiscation_db

fines_username=edb_amd
fines_password=edb_read_0nly
fines_host=libragob-test.postgres.database.azure.com
fines_port=5432
fines_db=nm_fines_db

maintenance_username=edb_amd
maintenance_password=edb_read_0nly
maintenance_host=libragob-test.postgres.database.azure.com
maintenance_port=5432
maintenance_db=nm_maintenance_db
############################################################################
### Push CSV file to BAIS so it can be ingested and displayed in the AMD ###
############################################################################
if [ -e /mnt/secrets/$KV_NAME/sftp-endpoint ] && [ -e /mnt/secrets/$KV_NAME/sftp-username ] && [ -e /mnt/secrets/$KV_NAME/sftp-password ];then
  stfp_endpoint=$(cat /mnt/secrets/$KV_NAME/sftp-endpoint)
  sftp_username=$(cat /mnt/secrets/$KV_NAME/sftp-username)
  sftp_password=$(cat /mnt/secrets/$KV_NAME/sftp-password)
echo "endpoint=$stfp_endpoint"
echo "username=$stfp_username"
echo "password=$stfp_password"
  echo "$(date "+%d/%m/%Y %T") Uploading the report to SFTP server $sftp_endpoint" >> $OUTFILE_LOG
  #sftp $sftp_username@$sftp_endpoint:/ <<< $'put $OUTFILE'
  sshpass $stfp_password -e sftp $sftp_username@$sftp_endpoint:/ <<< $'put $OUTFILE'
else
  echo "Cannot access BAIS KeyVault connection variables" 
fi
####################################################### CHECK 1
echo "[Check #1: Locked Schemas]" >> $OUTFILE
echo "DateTime,CheckName,Description,Status,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #1" > $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/1AZUREDB_AMD_locked_schemas.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #1 has been run" >> $OUTFILE_LOG

while read -r line;do

schema_lock=''
schema_lock=`echo $line | awk '{print $1}'`

if [ ! -z $schema_lock ];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_schema_lock,Locked Schema Check,SchemaId $schema_lock is locked,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_schema_lock,Locked Schema Check,No Schemas Locks,ok" >> $OUTFILE
fi

done < ${OPDIR}1AZUREDB_AMD_locked_schemas.csv

echo "$(date "+%d/%m/%Y %T") Check #1 complete" >> $OUTFILE_LOG
####################################################### CHECK 2
echo "[Check #2: Locked Instance Keys]" >> $OUTFILE
echo "DateTime,CheckName,Description,Threshold,Status,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #2" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/2AZUREDB_AMD_locked_keys.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #2 has been run" >> $OUTFILE_LOG

while read -r line;do

key_lock=''
key_lock=`echo $line | awk '{print $1}'`

if [ ! -z $key_lock ];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_key_lock,Locked Instance Key Check,Instance Key $key_lock is locked,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_key_lock,Locked Instance Key Check,No Instance Key Locks,ok" >> $OUTFILE
fi

done < ${OPDIR}2AZUREDB_AMD_locked_keys.csv

echo "$(date "+%d/%m/%Y %T") Check #2 complete" >> $OUTFILE_LOG
####################################################### CHECK 4
echo "[Check #4: Thread Status Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,State,Threshold,Count,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #4" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/4AZUREDB_AMD_thread_status_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #4 has been run" >> $OUTFILE_LOG

idle_threshold=350
nonidle_threshold=10

while read -r line;do

if [[ `echo $line | grep "^,"` ]];then
state=null
else
state=`echo $line | awk -F"," '{print $1}'`
fi

count=`echo $line | awk -F"," '{print $2}'`

if [[ $state == idle ]];then

if [[ $count -gt $idle_threshold ]];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_db_threads,Thread Count Check,$state,$idle_threshold,$count,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_db_threads,Thread Count Check,$state,$idle_threshold,$count,ok" >> $OUTFILE
fi

else

if [[ $count -gt $nonidle_threshold ]];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_db_threads,Thread Count Check,$state,$nonidle_threshold,$count,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_db_threads,Thread Count Check,$state,$nonidle_threshold,$count,ok" >> $OUTFILE
fi

fi

done < ${OPDIR}4AZUREDB_AMD_thread_status_counts.csv

echo "$(date "+%d/%m/%Y %T") Check #4 complete" >> $OUTFILE_LOG
####################################################### CHECK 5
echo "[Check #5: MESSAGE_LOG Errors]" >> $OUTFILE
echo "DateTime,CheckName,Description,message_log_id,message_uuid,created_date,procedure_name,error_message,update_request_id,schema_id,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #5" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/5AZUREDB_AMD_message_log_errors.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #5 has been run" >> $OUTFILE_LOG

# Put protection in to only work on the last 100 lines of errors
tail -100 ${OPDIR}5AZUREDB_AMD_message_log_errors.csv > ${OPDIR}5AZUREDB_AMD_message_log_errors_100.tmp
mv ${OPDIR}5AZUREDB_AMD_message_log_errors_100.tmp ${OPDIR}5AZUREDB_AMD_message_log_errors_100.csv

while read -r line;do

message_log_id=`echo $line | awk -F"," '{print $1}'`
message_uuid=`echo $line | awk -F"," '{print $2}'`
created_date=`echo $line | awk -F"," '{print $3}'`
procedure_name=`echo $line | awk -F"," '{print $4}'`
error_message=`echo $line | awk -F"," '{print $5}'`
update_request_id=`echo $line | awk -F"," '{print $6}'`
schema_id=`echo $line | awk -F"," '{print $7}'`

if [ ! -z $message_log_id ];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_db_message_log_error,Message Log Error Check,$message_log_id,$message_uuid,$created_date,$procedure_name,$error_message,$update_request_id,$schema_id,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_db_message_log_error,Message Log Error Check,$message_log_id,$message_uuid,$created_date,$procedure_name,$error_message,$update_request_id,$schema_id,ok" >> $OUTFILE
fi

done < ${OPDIR}5AZUREDB_AMD_message_log_errors_100.csv

echo "$(date "+%d/%m/%Y %T") Check #5 complete" >> $OUTFILE_LOG
####################################################### CHECK 6
if [[ 0 == 1 ]];then

echo "[Check #6: Unprocessed, Complete & Processing Checks]" >> $OUTFILE
echo "DateTime,CheckName,Description,schema_id,Threshold,earliest_unprocessed,latest_complete,latest_processing,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #6" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/6AZUREDB_AMD_update_processing_backlog.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #6 has been run" >> $OUTFILE_LOG
rm -f ${OPDIR}earliest_unprocessed_timestamps.tmp ${OPDIR}earliest_processing_timestamps.tmp

while read -r line;do

echo "line=$line"

schema_id=`echo $line | awk -F"," '{print $1}'`
earliest_unprocessed=`echo $line | awk -F"," '{print $2}'`
dt_earliest_unprocessed=`echo $earliest_unprocessed | awk -F"." '{print $1}'`
latest_complete=`echo $line | awk -F"," '{print $3}'`
latest_processing=`echo $line | awk -F"," '{print $4}'`
dt_latest_processing=`echo $latest_processing | awk -F"." '{print $1}'`

echo "schema_id=$schema_id"
echo "earliest_unprocessed=$earliest_unprocessed"
echo "dt_earliest_unprocessed=$dt_earliest_unprocessed"
echo "latest_complete=$latest_complete"
echo "latest_processing=$latest_processing"
echo "dt_earliest_processing=$dt_earliest_processing"

last_check_unprocessed=`grep "$schema_id" ${OPDIR}earliest_unprocessed_timestamps_last_check.tmp | awk -F"," '{print $2}'`
echo "last_check_unprocessed=$last_check_unprocessed"
echo "$schema_id,$dt_earliest_unprocessed" >> ${OPDIR}earliest_unprocessed_timestamps.tmp

last_check_processing=`grep "$schema_id" ${OPDIR}earliest_processing_timestamps_last_check.tmp | awk -F"," '{print $2}'`
echo "last_check_processing=$last_check_processing"
echo "$schema_id,$dt_earliest_processing" >> ${OPDIR}earliest_processing_timestamps.tmp

echo "CAT of ${OPDIR}earliest_unprocessed_timestamps.tmp"
cat ${OPDIR}earliest_unprocessed_timestamps.tmp

echo "CAT of ${OPDIR}earliest_processing_timestamps.tmp"
cat ${OPDIR}earliest_processing_timestamps.tmp

t_delta_threshold_mins=90
t_delta_threshold_secs=$(($t_delta_threshold_mins*60*60)) # 90mins is 324000secs

dt_now=$(date "+%Y-%m-%d %T")

t_out_1900=$(date '+%s' -d "$dt_now")
t_in_1900_unprocessed=$(date '+%s' -d "$dt_earliest_unprocessed")
t_delta_secs_unprocessed=`expr $t_out_1900 - $t_in_1900_unprocessed`

echo "dt_now=$dt_now"
echo "t_out_1900=$t_out_1900"
echo "t_in_1900=$t_in_1900_unprocessed"
echo "t_delta_secs=$t_delta_secs"
echo "t_delta_threshold_secs=$t_delta_threshold_secs"

t_out_1900=$(date '+%s' -d "$dt_now")
t_in_1900_processing=$(date '+%s' -d "$dt_earliest_processing")
t_delta_secs_processing=`expr $t_out_1900 - $t_in_1900_processing`

echo "dt_now=$dt_now"
echo "t_out_1900=$t_out_1900"
echo "t_in_1900=$t_in_1900_processing"
echo "t_delta_secs=$t_delta_secs"
echo "t_delta_threshold_secs=$t_delta_threshold_secs"

if [[ $t_delta_secs_unprocessed -gt $t_delta_threshold_secs ]] || [[ $last_check_unprocessed -gt $t_delta_threshold_secs ]] || [[ $t_delta_secs_processing -gt $t_delta_threshold_secs ]] || [[ $last_check_processing -gt $t_delta_threshold_secs ]];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_update_processing_backlog,Check of Earliest Unprocessed vs. Latest Complete vs. Latest Processing,$schema_id,${t_delta_threshold_mins}minsStaleness,$earliest_unprocessed,$latest_complete,$latest_processing,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_update_processing_backlog,Check of Earliest Unprocessed vs. Latest Complete vs. Latest Processing,$schema_id,${t_delta_threshold_mins}minsStaleness,$earliest_unprocessed,$latest_complete,$latest_processing,ok" >> $OUTFILE
fi

done < ${OPDIR}6AZUREDB_AMD_update_processing_backlog.csv

mv ${OPDIR}earliest_unprocessed_timestamps.tmp ${OPDIR}earliest_unprocessed_timestamps_last_check.tmp
mv ${OPDIR}earliest_processing_timestamps.tmp ${OPDIR}earliest_processing_timestamps_last_check.tmp

echo "$(date "+%d/%m/%Y %T") Check #6 complete" >> $OUTFILE_LOG

fi
####################################################### CHECK 7
echo "[Check #7: Max Daily Update Counts by SchemaId]" >> $OUTFILE
echo "DateTime,CheckName,Description,schema_id,count_updates,sum_number_of_table_updates,max_number_of_table_updates,BundledPrintThreshold,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #7" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/7AZUREDB_AMD_max_daily_update_counts_by_schemaid.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #7 has been run" >> $OUTFILE_LOG
bundled_print_threshold=90000

while read -r line;do

schema_id=`echo $line | awk -F"," '{print $1}'`
count_updates=`echo $line | awk -F"," '{print $2}'`
sum_number_of_table_updates=`echo $line | awk -F"," '{print $3}'`
max_number_of_table_updates=`echo $line | awk -F"," '{print $4}'`

if [[ $max_number_of_table_updates -gt $bundled_print_threshold ]];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_max_updates,Max Updates by SchemaId,$schema_id,$count_updates,$sum_number_of_table_updates,$max_number_of_table_updates,$bundled_print_threshold,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_max_updates,Max Updates by SchemaId,$schema_id,$count_updates,$sum_number_of_table_updates,$max_number_of_table_updates,$bundled_print_threshold,ok" >> $OUTFILE
fi

done < ${OPDIR}7AZUREDB_AMD_max_daily_update_counts_by_schemaid.csv

echo "$(date "+%d/%m/%Y %T") Check #7 complete" >> $OUTFILE_LOG
####################################################### CHECK 8
echo "[Check #8: Today's Hourly Update Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,schema_id,count_updates,sum_number_of_table_updates,max_number_of_table_updates,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #8" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/8AZUREDB_AMD_todays_hourly_update_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #8 has been run" >> $OUTFILE_LOG

while read -r line;do

schema_id=`echo $line | awk -F"," '{print $1}'`
count_updates=`echo $line | awk -F"," '{print $2}'`
sum_number_of_table_updates=`echo $line | awk -F"," '{print $3}'`
max_number_of_table_updates=`echo $line | awk -F"," '{print $4}'`

echo "dt,AZDB001_hourly_updates,Today's Hourly Updates,$schema_id,$count_updates,$sum_number_of_table_updates,$max_number_of_table_updates,ok" >> $OUTFILE

done < ${OPDIR}8AZUREDB_AMD_todays_hourly_update_counts.csv

echo "$(date "+%d/%m/%Y %T") Check #8 complete" >> $OUTFILE_LOG
####################################################### CHECK 9
echo "[Check #9: Azure Recon (ORA Recon check is on AMD Database INFO tab)]" >> $OUTFILE
echo "DateTime,CheckName,Description,Status,Result" >> $OUTFILE
dt_today=$(date "+%Y-%m-%d")
echo "$(date "+%d/%m/%Y %T") Starting Check #9a" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $confiscation_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${confiscation_host} dbname=${confiscation_db} port=${confiscation_port} user=${confiscation_username} password=${confiscation_password}" --file=/sql/9aAZUREDB_AMD_confiscation_recon_result.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #9a has been run" >> $OUTFILE_LOG
error_count=`grep "1$" ${OPDIR}9aAZUREDB_AMD_confiscation_recon_result.csv | wc -l | xargs`

if [[ `grep "$dt_today" ${OPDIR}9aAZUREDB_AMD_confiscation_recon_result.csv` ]];then

if [[ $error_count -gt 0 ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_confiscation_recon,Confiscation Recon,Recon has errors so pls investigate,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_confiscation_recon_status,Confiscation Recon,Recon ran with no errors,ok" >> $OUTFILE

fi

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_confiscation_recon_status,Confiscation Recon,Recon didn't run today so check ORA recon ran ok,warn" >> $OUTFILE

fi

echo "$(date "+%d/%m/%Y %T") Connecting to $fines_db database" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Starting Check #9b" >> $OUTFILE_LOG
psql "sslmode=require host=${fines_host} dbname=${fines_db} port=${fines_port} user=${fines_username} password=${fines_password}" --file=/sql/9bAZUREDB_AMD_fines_recon_result.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #9b has been run" >> $OUTFILE_LOG
error_count=`grep "1$" ${OPDIR}9bAZUREDB_AMD_fines_recon_result.csv | wc -l | xargs`

if [[ `grep "$dt_today" ${OPDIR}9bAZUREDB_AMD_fines_recon_result.csv` ]];then

if [[ $error_count -gt 0 ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_fines_recon,Fines Recon,Recon has errors so pls investigate,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_fines_recon_status,Fines Recon,Recon ran with no errors,ok" >> $OUTFILE

fi

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_fines_recon_status,Fines Recon,Recon didn't run today so check ORA recon ran ok,warn" >> $OUTFILE

fi

echo "$(date "+%d/%m/%Y %T") Connecting to $maintenance_db database" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Starting Check #9c" >> $OUTFILE_LOG
psql "sslmode=require host=${maintenance_host} dbname=${maintenance_db} port=${maintenance_port} user=${maintenance_username} password=${maintenance_password}" --file=/sql/9cAZUREDB_AMD_maintenance_recon_result.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #9c has been run" >> $OUTFILE_LOG
error_count=`grep "1$" ${OPDIR}9cAZUREDB_AMD_maintenance_recon_result.csv | wc -l | xargs`

if [[ `grep "$dt_today" ${OPDIR}9cAZUREDB_AMD_maintenance_recon_result.csv` ]];then

if [[ $error_count -gt 0 ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_maintenance_recon,Maintenance Recon,Recon has errors so pls investigate,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_maintenance_recon_status,Maintenance Recon,Recon ran with no errors,ok" >> $OUTFILE

fi

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_maint_maintenance_recon_status,Maintenance Recon,Recon didn't run today so check ORA recon ran ok,warn" >> $OUTFILE

fi

echo "$(date "+%d/%m/%Y %T") Check #9 complete" >> $OUTFILE_LOG
####################################################### CHECK 10
echo "[Check #10: Themis WebLogic]" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #10" >> $OUTFILE_LOG
echo "ReminderMessage" >> $OUTFILE
echo "Remember to check Themis Process States & WL Backlogs on AMD LIBRA Web App ADMIN-1 server" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Check #10 has been run" >> $OUTFILE_LOG
####################################################### CHECK 11
echo "[Check #11: Table Row Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,RowCount,Threshold,Result" >> $OUTFILE

threshold_count_update_requests=14000
threshold_count_table_updates=120000
threshold_count_message_log=80000
threshold_count_dac_audit=123000000
threshold_count_gateway_audit=50000

echo "$(date "+%d/%m/%Y %T") Starting Check #11a" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/11aAZUREDB_AMD_row_counts_update_requests.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #11a has been run" >> $OUTFILE_LOG

rowcount_update_requests=`cat ${OPDIR}11aAZUREDB_AMD_row_counts_update_requests.csv`

if [[ $rowcount_update_requests -gt $threshold_count_update_requests ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_update_requests_row_count,UPDATE_REQUEST RowCount,$rowcount_update_requests,$threshold_count_update_requests,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_update_requests_row_count,UPDATE_REQUEST RowCount,$rowcount_update_requests,$threshold_count_update_requests,ok" >> $OUTFILE

fi

echo "$(date "+%d/%m/%Y %T") Starting Check #11b" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/11bAZUREDB_AMD_row_counts_table_updates.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #11b has been run" >> $OUTFILE_LOG

rowcount_table_updates=`cat ${OPDIR}11bAZUREDB_AMD_row_counts_table_updates.csv`

if [[ $rowcount_table_updates -gt $threshold_count_table_updates ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_table_updates_row_count,TABLE_UPDATES RowCount,$rowcount_table_updates,$threshold_count_table_updates,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_table_updates_row_count,TABLE_UPDATES RowCount,$rowcount_table_updates,$threshold_count_table_updates,ok" >> $OUTFILE

fi

echo "$(date "+%d/%m/%Y %T") Starting Check #11c" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/11cAZUREDB_AMD_row_counts_message_log.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #11c has been run" >> $OUTFILE_LOG

rowcount_message_log=`cat ${OPDIR}11cAZUREDB_AMD_row_counts_message_log.csv`

if [[ $rowcount_message_log -gt $threshold_count_message_log ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_message_log_row_count,MESSAGE_LOG RowCount,$rowcount_message_log,$threshold_count_message_log,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_message_log_row_count,MESSAGE_LOG RowCount,$rowcount_message_log,$threshold_count_message_log,ok" >> $OUTFILE

fi

if [[ 0 == 1 ]];then

echo "$(date "+%d/%m/%Y %T") Starting Check #11d" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/11dAZUREDB_AMD_row_counts_DAC_message_audit.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #11d has been run" >> $OUTFILE_LOG

rowcount_dac_audit=`cat ${OPDIR}11dAZUREDB_AMD_row_counts_DAC_message_audit.csv`

if [[ $rowcount_dac_audit -gt $threshold_count_dac_audit ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_dac_audit_row_count,DAC_AUDIT RowCount,$rowcount_dac_audit,$threshold_count_dac_audit,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_dac_audit_row_count,DAC_AUDIT RowCount,$rowcount_dac_audit,$threshold_count_dac_audit,ok" >> $OUTFILE

fi

fi

echo "$(date "+%d/%m/%Y %T") Starting Check #11e" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/11eAZUREDB_AMD_row_counts_GW_message_audit.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #11e has been run" >> $OUTFILE_LOG

rowcount_gateway_audit=`cat ${OPDIR}11eAZUREDB_AMD_row_counts_GW_message_audit.csv`

if [[ $rowcount_gateway_audit -gt $threshold_count_gateway_audit ]];then

echo "$(date "+%d/%m/%Y %T"),AZDB001_gateway_audit_row_count,GATEWAY_AUDIT RowCount,$rowcount_gateway_audit,$threshold_count_gateway_audit,warn" >> $OUTFILE

else

echo "$(date "+%d/%m/%Y %T"),AZDB001_gateway_audit_row_count,GATEWAY_AUDIT RowCount,$rowcount_gateway_audit,$threshold_count_gateway_audit,ok" >> $OUTFILE

fi

cat ${OPDIR}11aAZUREDB_AMD_row_counts_update_requests.csv >> $OUTFILE
cat ${OPDIR}11bAZUREDB_AMD_row_counts_table_updates.csv >> $OUTFILE
cat ${OPDIR}11cAZUREDB_AMD_row_counts_message_log.csv >> $OUTFILE
cat ${OPDIR}11dAZUREDB_AMD_row_counts_DAC_message_audit.csv >> $OUTFILE
cat ${OPDIR}11eAZUREDB_AMD_row_counts_GW_message_audit.csv >> $OUTFILE

echo "$(date "+%d/%m/%Y %T") Check #11 complete" >> $OUTFILE_LOG
####################################################### CHECK 12
if [[ 0 == 1 ]];then

echo "[Check #12a: Today's Latest 100 DACAudit DB Roundtrip Deltas Step 13-12]" >> $OUTFILE
echo "DateTime,CheckName,Description,updated_date,uuid,Roundtrip in Millisecs,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12a" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12aAZUREDB_AMD_dacaudit_DBstep13-12_latest100_processing_rates.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12a has been run" >> $OUTFILE_LOG

while read -r line;do

updated_date=`echo $line | awk '{print $1}'`
uuid=`echo $line | awk '{print $2}'`
roundtrip=`echo $line | awk '{print $3}'`

echo "dt,AZDB001_dacaudit_db_100_proc_rates,Today's Latest 100 DACAudit DB Roundtrip Deltas Step 13-12,$updated_date,$uuid,$rountrip,ok" >> $OUTFILE

done < ${OPDIR}12aAZUREDB_AMD_dacaudit_DBstep13-12_latest100_processing_rates.csv
######################################################################################################################################################################################################
echo "[Check #12b: Today's Latest 100 DACAudit Full Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,updated_date,uuid,Roundtrip in Millisecs,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12b" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12bAZUREDB_AMD_dacaudit_step10-1_latest100_processing_rates.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12b has been run" >> $OUTFILE_LOG

while read -r line;do

updated_date=`echo $line | awk '{print $1}'`
uuid=`echo $line | awk '{print $2}'`
roundtrip=`echo $line | awk '{print $3}'`

echo "dt,AZDB001_dacaudit_100_proc_rates,Today's Latest 100 DACAudit Full Roundtrip Deltas Step 10-1,$updated_date,$uuid,$rountrip,ok" >> $OUTFILE

done < ${OPDIR}12bAZUREDB_AMD_dacaudit_DBstep10-1_latest100_processing_rates.csv
######################################################################################################################################################################################################
echo "[Check #12c: Today's Latest 100 GatewayAudit Full Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,updated_date,uuid,Roundtrip in Millisecs,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12c" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12cAZUREDB_AMD_gwaudit_step10-1_latest100_processing_rates.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12c has been run" >> $OUTFILE_LOG

while read -r line;do

updated_date=`echo $line | awk '{print $1}'`
uuid=`echo $line | awk '{print $2}'`
roundtrip=`echo $line | awk '{print $3}'`

echo "dt,AZDB001_gwaudit_100_proc_rates,Today's Latest 100 GatewayAudit Full Roundtrip Deltas Step 10-1,$updated_date,$uuid,$rountrip,ok" >> $OUTFILE

done < ${OPDIR}12cAZUREDB_AMD_gwaudit_step10-1_latest100_processing_rates.csv
######################################################################################################################################################################################################
echo "[Check #12d: Daily AVG DACAudit DB Roundtrip Deltas Step 13-12]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgDailyRT in Millisecs,TotalWorkload in Hours,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12d" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12dAZUREDB_AMD_dacaudit_DBstep13-12_avgDailyRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12d has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgDailyRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_dacaudit_db_avgDailyRT,Daily AVG DACAudit DB Roundtrip Deltas Step 13-12,$dateddmmyyyy,$avgDailyRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12dAZUREDB_AMD_dacaudit_DBstep13-12_avgDailyRT.csv
######################################################################################################################################################################################################
echo "[Check #12e: Daily AVG DACAudit Full Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgDailyRT in Millisecs,TotalWorkload in Hours,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12e" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12eAZUREDB_AMD_dacaudit_step10-1_avgDailyRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12e has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgDailyRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_dacaudit_avgDailyRT,Daily AVG DACAudit Full Roundtrip Deltas Step 10-1,$dateddmmyyyy,$avgDailyRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12eAZUREDB_AMD_dacaudit_step10-1_avgDailyRT.csv
######################################################################################################################################################################################################
echo "[Check #12f: Daily AVG GatewayAudit Full Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgDailyRT in Millisecs,TotalWorkload in Hours,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12f" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12fAZUREDB_AMD_gwaudit_step10-1_avgDailyRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12f has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgDailyRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_gwaudit_avgDailyRT,Daily AVG GatewayAudit Full Roundtrip Deltas Step 10-1,$dateddmmyyyy,$avgDailyRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12fAZUREDB_AMD_gwaudit_step10-1_avgDailyRT.csv
######################################################################################################################################################################################################
echo "[Check #12g: 48 Hourly AVG DACAudit DB Roundtrip Deltas Step 13-12]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgHourlyRT in Millisecs,TotalWorkload in Mins,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12g" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12gAZUREDB_AMD_dacaudit_DBstep13-12_avgHourlyRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12g has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgHourlyRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_dacaudit_db_avgHourlyRT,48 Hourly AVG DACAudit DB Roundtrip Deltas Step 13-12,$dateddmmyyyy,$avgHourlyRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12gAZUREDB_AMD_dacaudit_DBstep13-12_avgHourlyRT.csv
######################################################################################################################################################################################################
echo "[Check #12h: 60 Minute AVG DACAudit DB Roundtrip Deltas Step 13-12]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgMinuteRT in Millisecs,TotalWorkload in Secs,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12h" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12hAZUREDB_AMD_dacaudit_DBstep13-12_avgMinuteRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12h has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgMinuteRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_dacaudit_db_avgMinuteRT,60 Minute AVG DACAudit DB Roundtrip Deltas Step 13-12,$dateddmmyyyy,$avgMinuteRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12hAZUREDB_AMD_dacaudit_DBstep13-12_avgMinuteRT.csv
######################################################################################################################################################################################################
echo "[Check #12i: 48 Hourly AVG DACAudit DB Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgHourlyRT in Millisecs,TotalWorkload in Mins,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12i" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12iAZUREDB_AMD_dacaudit_DBstep10-1_avgHourlyRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12i has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgHourlyRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_dacaudit_db_avgHourlyRT,48 Hourly AVG DACAudit DB Roundtrip Deltas Step 10-1,$dateddmmyyyy,$avgHourlyRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12iAZUREDB_AMD_dacaudit_DBstep10-1_avgHourlyRT.csv
######################################################################################################################################################################################################
echo "[Check #12j: 60 Minute AVG DACAudit DB Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgMinuteRT in Millisecs,TotalWorkload in Secs,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12j" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12jAZUREDB_AMD_dacaudit_DBstep10-1_avgMinuteRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12j has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgMinuteRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_dacaudit_db_avgMinuteRT,60 Minute AVG DACAudit DB Roundtrip Deltas Step 10-1,$dateddmmyyyy,$avgMinuteRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12jAZUREDB_AMD_dacaudit_DBstep10-1_avgMinuteRT.csv
######################################################################################################################################################################################################
echo "[Check #12k: 48 Hourly AVG GatewayAudit Full Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgHourlyRT in Millisecs,TotalWorkload in Mins,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12k" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12kAZUREDB_AMD_gwaudit_step10-1_avgHourlyRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12k has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgHourlyRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_gwaudit_avgHourlyRT,48 Hourly AVG GatewayAudit Full Roundtrip Deltas Step 10-1,$dateddmmyyyy,$avgHourlyRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12kAZUREDB_AMD_gwaudit_step10-1_avgHourlyRT.csv
######################################################################################################################################################################################################
echo "[Check #12l: 60 Minute AVG GatewayAudit Full Roundtrip Deltas Step 10-1]" >> $OUTFILE
echo "DateTime,CheckName,Description,avgMinuteRT in Millisecs,TotalWorkload in Mins,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12l" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $postgres_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${postgres_host} dbname=${postgres_db} port=${postgres_port} user=${postgres_username} password=${postgres_password}" --file=/sql/12lAZUREDB_AMD_gwaudit_step10-1_avgMinuteRT.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12l has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
avgMinuteRT=`echo $line | awk '{print $2}'`
total_workload=`echo $line | awk '{print $3}'`
records=`echo $line | awk '{print $4}'`

echo "dt,AZDB001_gwaudit_avgMinuteRT,60 Minute AVG GatewayAudit Full Roundtrip Deltas Step 10-1,$dateddmmyyyy,$avgMinuteRT,$total_workload,$records,ok" >> $OUTFILE

done < ${OPDIR}12lAZUREDB_AMD_gwaudit_step10-1_avgMinuteRT.csv
######################################################################################################################################################################################################
echo "[Check #12m: Daily Completed UPDATE_REQUESTS Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,DTBucket,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12m" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/12mAZUREDB_AMD_daily_completed_update_request_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12m has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
records=`echo $line | awk '{print $2}'`

echo "dt,AZDB001_daily_completed_update_requests,Daily Completed UPDATE_REQUESTS Counts,$dateddmmyyyy,$records,ok" >> $OUTFILE

done < ${OPDIR}12mAZUREDB_AMD_daily_completed_update_request_counts.csv
######################################################################################################################################################################################################
echo "[Check #12n: Daily Completed TABLE_UPDATES Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,DTBucket,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12n" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/12nAZUREDB_AMD_daily_completed_table_updates_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12n has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
records=`echo $line | awk '{print $2}'`

echo "dt,AZDB001_daily_completed_table_updates,Daily Completed TABLE_UPDATES Counts,$dateddmmyyyy,$records,ok" >> $OUTFILE

done < ${OPDIR}12nAZUREDB_AMD_daily_completed_table_updates_counts.csv
######################################################################################################################################################################################################
echo "[Check #12o: Hourly Completed UPDATE_REQUESTS Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,DTBucket,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12o" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/12oAZUREDB_AMD_Hourly_completed_update_request_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12o has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
records=`echo $line | awk '{print $2}'`

echo "dt,AZDB001_hourly_completed_update_requests,Hourly Completed UPDATE_REQUESTS Counts,$dateddmmyyyy,$records,ok" >> $OUTFILE

done < ${OPDIR}12oAZUREDB_AMD_hourly_completed_update_request_counts.csv
######################################################################################################################################################################################################
echo "[Check #12p: Hourly Completed TABLE_UPDATES Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,DTBucket,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12p" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/12pAZUREDB_AMD_Hourly_completed_table_updates_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12p has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
records=`echo $line | awk '{print $2}'`

echo "dt,AZDB001_hourly_completed_table_updates,Hourly Completed TABLE_UPDATES Counts,$dateddmmyyyy,$records,ok" >> $OUTFILE

done < ${OPDIR}12pAZUREDB_AMD_hourly_completed_table_updates_counts.csv
######################################################################################################################################################################################################
echo "[Check #12q: Minute Completed UPDATE_REQUESTS Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,DTBucket,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12q" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/12qAZUREDB_AMD_Minute_completed_update_request_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12q has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
records=`echo $line | awk '{print $2}'`

echo "dt,AZDB001_minute_completed_update_requests,Minute Completed UPDATE_REQUESTS Counts,$dateddmmyyyy,$records,ok" >> $OUTFILE

done < ${OPDIR}12qAZUREDB_AMD_minute_completed_update_request_counts.csv
######################################################################################################################################################################################################
echo "[Check #12r: Minute Completed TABLE_UPDATES Counts]" >> $OUTFILE
echo "DateTime,CheckName,Description,DTBucket,RecordCount,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #12r" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/12rAZUREDB_AMD_Minute_completed_table_updates_counts.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #12r has been run" >> $OUTFILE_LOG

while read -r line;do

dateddmmyyyy=`echo $line | awk '{print $1}'`
records=`echo $line | awk '{print $2}'`

echo "dt,AZDB001_minute_completed_table_updates,Minute Completed TABLE_UPDATES Counts,$dateddmmyyyy,$records,ok" >> $OUTFILE

done < ${OPDIR}12rAZUREDB_AMD_minute_completed_table_updates_counts.csv

echo "$(date "+%d/%m/%Y %T") Check #12 complete" >> $OUTFILE_LOG

fi
####################################################### CHECK 3
echo "[Check #3: Update Backlogs]" >> $OUTFILE
echo "DateTime,CheckName,Description,SchemaId,Status,COUNTupdates,max_number_of_table_updates,sum_number_of_table_updates,AdaptiveBacklogThreshold,DBdacRate_inMS,TOTALdacRate_inMS,TOTALgwRate_inMS,Total Roundtrip in Millisecs,RoundtripThreshold,DeliveryETA,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #3" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/3AZUREDB_AMD_message_backlogs.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #3 has been run" >> $OUTFILE_LOG

backlog_threshold=850000 # 30K allowable back at 17:xx
roundtrip_threshold=3000
dt_hr=$(date "+%H")
dt_hr1=`echo $dt_hr | cut -b 1`
dt_hr2=`echo $dt_hr | cut -b 2`

echo "====================================="
cat ${OPDIR}3AZUREDB_AMD_message_backlogs.csv
echo "====================================="
echo $dt_hr
echo $dt_hr1
echo $dt_hr2
echo "====================================="

if [[ $dt_hr == 00 ]];then
backlog_adaptive_threshold=$backlog_threshold
elif [[ $dt_hr1 == 0 ]];then
backlog_adaptive_threshold=$(($backlog_threshold/$dt_hr2))
else
backlog_adaptive_threshold=$(($backlog_threshold/$dt_hr))
fi

echo "====================================="
echo $backlog_adaptive_threshold
echo "====================================="

while read -r line;do

schema_id=`echo $line | awk -F"," '{print $1}'`
status=`echo $line | awk -F"," '{print $2}'`
count_updates=`echo $line | awk -F"," '{print $3}'`
sum_number_of_table_updates=`echo $line | awk -F"," '{print $4}'`
max_number_of_table_updates=`echo $line | awk -F"," '{print $5}'`

echo "====================================="
echo $schema_id
echo $status
echo $count_updates
echo $sum_number_of_table_updates
echo $max_number_of_table_updates
echo "====================================="

#db_dac_rate=`head -1 ${OPDIR}12AZUREDB_AMD_dacaudit_DBstep13-12_latest100_processing_rates.csv | awk -F"," '{print $3}'`
#total_dac_rate=`head -1 ${OPDIR}12AZUREDB_AMD_dacaudit_DBstep10-1_latest100_processing_rates.csv  | awk -F"," '{print $3}'`
#total_gw_rate=`head -1 ${OPDIR}12AZUREDB_AMD_gwaudit_step10-1_latest100_processing_rates.csv  | awk -F"," '{print $3}'`
db_dacRT=589
total_dacRT=1101
total_gwRT=799
total_roundtrip=`echo "$db_dacRT+$total_dacRT+$total_gwRT" | bc`
total_roundtrip_secs=`echo "scale=3;$total_roundtrip/1000" | bc`
delivery_rate_secs=`echo "scale=1;$sum_number_of_table_updates/$total_roundtrip_secs" | bc`

if [[ $delivery_rate_secs -lt 60 ]];then
adj_delivery_rate=$delivery_rate_secs
eta_units=secs
elif [[ $delivery_rate_secs -lt $((60*60)) ]];then
adj_delivery_rate=`echo "scale=2;$delivery_rate_secs/(60*60)" | bc`
eta_units=mins
elif [[ $delivery_rate_secs -lt $((60*60*24)) ]];then
adj_delivery_rate=`echo "scale=2;$delivery_rate_secs/(60*60*24)" | bc`
eta_units=hrs
else
eta_units=days
fi

echo "--------------------------------------------------------------"
echo $db_dacRT
echo $total_dacRT
echo $total_gwRT
echo $total_roundtrip
echo $total_roundtrip_secs
echo $delivery_rate_secs
echo $adj_delivery_rate
echo $eta_units
echo "--------------------------------------------------------------"

if [[ $status != ERROR ]];then

if [[ $sum_number_of_table_updates -gt $backlog_adaptive_threshold ]] || [[ $total_roundtrip -gt $roundtrip_threshold ]];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_msg_backlog,MessageBacklogCheck,$schema_id,$status,$count_updates,$max_number_of_table_updates,$sum_number_of_table_updates,$backlog_adaptive_threshold,$db_dacRT,$total_dacRT,$total_gwRT,$total_roundtrip,$roundtrip_threshold,${adj_delivery_rate}${eta_units},warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_msg_backlog,MessageBacklogCheck,$schema_id,$status,$count_updates,$max_number_of_table_updates,$sum_number_of_table_updates,$backlog_adaptive_threshold,$db_dacRT,$total_dacRT,$total_gwRT,$total_roundtrip,$roundtrip_threshold,${adj_delivery_rate}${eta_units},ok" >> $OUTFILE
fi

fi

done < ${OPDIR}3AZUREDB_AMD_message_backlogs.csv

echo "$(date "+%d/%m/%Y %T") Check #3 complete" >> $OUTFILE_LOG

echo "cat of OUTFILE:"
cat $OUTFILE
echo "cat of OUTFILE_LOG:"
cat $OUTFILE_LOG
exit 0
####################################################### CHECK 13
if [[ 0 == 1 ]];then # disabled permanently as it's since been realised its not always a hard break when sequence_number = previous_sequence_number

echo "[Check #13: ora_rowscn SequenceNumber Bug]" >> $OUTFILE
echo "DateTime,CheckName,Description,update_request_id,schema_id,sequence_number,previous_sequence_number,Result" >> $OUTFILE
echo "$(date "+%d/%m/%Y %T") Starting Check #13" >> $OUTFILE_LOG
echo "$(date "+%d/%m/%Y %T") Connecting to $event_db database" >> $OUTFILE_LOG
psql "sslmode=require host=${event_host} dbname=${event_db} port=${event_port} user=${event_username} password=${event_password}" --file=/sql/13AZUREDB_AMD_ora_rowscn_bug_seq_nums.sql
echo "$(date "+%d/%m/%Y %T") SQL for Check #13 has been run" >> $OUTFILE_LOG

while read -r line;do

update_request_id=`echo $line | awk -F"," '{print $1}'`
schema_id=`echo $line | awk -F"," '{print $2}'`
sequence_number=`echo $line | awk -F"," '{print $3}'`
previous_sequence_number=`echo $line | awk -F"," '{print $4}'`
insert_type=`echo $line | awk -F"," '{print $5}'`

if [[ $sequence_number -eq $previous_sequence_number ]] && [[ $insert_type = I ]];then
echo "$(date "+%d/%m/%Y %T"),AZDB001_ora_rowscn_bug,SequenceNumber Bug Check,$update_request_id,$schema_id,$sequence_number,$previous_sequence_number,warn" >> $OUTFILE
else
echo "$(date "+%d/%m/%Y %T"),AZDB001_ora_rowscn_bug,SequenceNumber Bug Check,$update_request_id,$schema_id,$sequence_number,$previous_sequence_number,ok" >> $OUTFILE
fi

done < ${OPDIR}13AZUREDB_AMD_ora_rowscn_bug_seq_nums.csv

fi

mv $OUTFILE $OUTFILE.csv

echo "$(date "+%d/%m/%Y %T") Check #13 complete" >> $OUTFILE_LOG
