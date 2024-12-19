WITH xml_data AS (
    SELECT 
        update_request_id,
        primary_key_id,
        table_name,
        update_type,
        change_items::xml AS xml_content,
        processed_date  -- Directly include this column from the table
    FROM 
        table_updates
    WHERE 
        change_items IS NOT NULL
),
filtered_values AS (
    SELECT
        update_request_id,
        primary_key_id,
        table_name,
        update_type,
        -- Extract the <NewValue> associated with <ColumnName>MODIFIED_DATE</ColumnName>
        xpath('//ColumnName[text()="MODIFIED_DATE"]/following-sibling::NewValue/text()', xml_content) AS new_values,
        processed_date,  -- Directly pass through the processed_date
        -- Convert new_value to timestamp if valid
        CASE 
            WHEN cardinality(xpath('//ColumnName[text()="MODIFIED_DATE"]/following-sibling::NewValue/text()', xml_content)) > 0 
                 AND (xpath('//ColumnName[text()="MODIFIED_DATE"]/following-sibling::NewValue/text()', xml_content))[1]::text ~ '^\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}$'
            THEN to_timestamp((xpath('//ColumnName[text()="MODIFIED_DATE"]/following-sibling::NewValue/text()', xml_content))[1]::text, 'DD/MM/YYYY HH24:MI:SS')
            ELSE NULL
        END AS new_value_date
    FROM
        xml_data
    WHERE
        cardinality(xpath('//ColumnName[text()="MODIFIED_DATE"]', xml_content)) > 0
        AND cardinality(xpath('//ColumnName[text()="MODIFIED_DATE"]/following-sibling::NewValue/text()', xml_content)) > 0
),
comparison_results AS (
    SELECT
        fv1.update_request_id AS update_request_id_1,
        fv1.primary_key_id,
        fv1.table_name,
        fv1.update_type,
        fv1.new_value_date AS new_value_date_1,
        fv1.processed_date AS processed_date_1,
        fv2.update_request_id AS update_request_id_2,
        fv2.new_value_date AS new_value_date_2,
        fv2.processed_date AS processed_date_2
    FROM
        filtered_values fv1
    JOIN
        filtered_values fv2
    ON
        fv1.table_name = fv2.table_name
        AND fv1.primary_key_id = fv2.primary_key_id
        AND fv1.update_type = fv2.update_type
        AND fv1.update_request_id <> fv2.update_request_id
    WHERE
        fv1.new_value_date > fv2.new_value_date
        AND fv1.processed_date < fv2.processed_date
),
distinct_records AS (
    SELECT DISTINCT
        update_request_id_1 AS update_request_id,
        primary_key_id,
        table_name,
        update_type,
        new_value_date_1 AS new_value_date,
        processed_date_1 AS processed_date,
        update_request_id_2,
        new_value_date_2,
        processed_date_2
    FROM
        comparison_results
)
INSERT INTO data_differences_table (
    update_request_id, 
    primary_key_id, 
    table_name, 
    update_type, 
    new_value_date, 
    processed_date, 
    update_request_id_2, 
    new_value_date_2, 
    processed_date_2
)
SELECT 
    dr.update_request_id,
    dr.primary_key_id,
    dr.table_name,
    dr.update_type,
    dr.new_value_date,
    dr.processed_date,
    dr.update_request_id_2,
    dr.new_value_date_2,
    dr.processed_date_2
FROM
    distinct_records dr
WHERE
    NOT EXISTS (
        SELECT 1
        FROM data_differences_table tt
        WHERE tt.update_request_id = dr.update_request_id
        AND tt.primary_key_id = dr.primary_key_id
        AND tt.table_name = dr.table_name
        AND tt.update_type = dr.update_type
        AND tt.new_value_date = dr.new_value_date
        AND tt.processed_date = dr.processed_date
        AND tt.update_request_id_2 = dr.update_request_id_2
        AND tt.new_value_date_2 = dr.new_value_date_2
        AND tt.processed_date_2 = dr.processed_date_2
    );
INSERT INTO public.table_updates_backup
SELECT *
FROM public.table_updates
WHERE update_request_id IN 
(SELECT update_request_id FROM public.update_requests
WHERE created_date < CURRENT_DATE - INTERVAL '5 days');
INSERT INTO public.update_requests_backup
SELECT *
FROM public.update_requests
WHERE created_date < CURRENT_DATE - INTERVAL '5 days';

DELETE FROM public.table_updates
WHERE update_request_id IN
(SELECT update_request_id FROM public.update_requests
WHERE created_date < CURRENT_DATE - INTERVAL '5 days');
DELETE FROM public.update_requests
WHERE created_date < CURRENT_DATE - INTERVAL '5 days';
DELETE FROM public.table_updates_backup
WHERE created_date < CURRENT_DATE - INTERVAL '45 days';
DELETE FROM public.update_requests_backup
WHERE created_date < CURRENT_DATE - INTERVAL '45 days';
