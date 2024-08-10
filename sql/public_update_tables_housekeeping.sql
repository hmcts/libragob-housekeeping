INSERT INTO public.table_updates_backup
SELECT *
FROM public.table_updates
WHERE created_date < CURRENT_TIMESTAMP - interval '5 days';
DELETE FROM public.table_updates
WHERE created_date < CURRENT_TIMESTAMP - interval '5 days';
INSERT INTO public.update_requests_backup
SELECT *
FROM public.update_requests
WHERE created_date < CURRENT_TIMESTAMP - interval '5 days';
DELETE FROM public.update_requests
WHERE created_date < CURRENT_TIMESTAMP - interval '5 days';

