DELETE FROM public.table_updates
WHERE created_date < CURRENT_TIMESTAMP - interval '7 days';
DELETE FROM public.update_requests
WHERE created_date < CURRENT_TIMESTAMP - interval '7 days';