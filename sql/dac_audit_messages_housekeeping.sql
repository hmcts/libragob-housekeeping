DELETE FROM themis_dac.message_audit
WHERE updated_date < CURRENT_TIMESTAMP - interval '2 days';