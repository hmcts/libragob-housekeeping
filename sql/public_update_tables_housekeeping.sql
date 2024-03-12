SELECT * FROM public.table_updates
WHERE created_date < CURRENT_TIMESTAMP - interval '5 days';
SELECT *  FROM public.update_requests
WHERE created_date < CURRENT_TIMESTAMP - interval '5 days';