{{ config(materialized='table') }}

WITH complaints AS (
    SELECT 
        complaint_id,
        created_date,
        closed_date,
        COALESCE(
            NULLIF(UPPER(TRIM(complaint_type)), ''),
            'UNKNOWN'
        ) AS problem,
        NULLIF(UPPER(TRIM(descriptor)), '') AS problem_detail,
        COALESCE(
            NULLIF(UPPER(TRIM(status)), ''),
            'UNKNOWN'
        ) AS status,
        COALESCE(NULLIF(TRIM(zip_code), ''), 'UNKNOWN') AS zip_code,
        COALESCE(NULLIF(UPPER(TRIM(borough)), ''), 'UNKNOWN') AS borough,
        latitude,
        longitude,
        council_district
    FROM {{ ref('stg_nyc_311_complaints') }}
)

SELECT 
    FARM_FINGERPRINT(c.complaint_id) AS complaint_fact_key,
    c.complaint_id AS unique_key,
    COALESCE(created.date_key, 0) AS created_date_key,
    COALESCE(closed.date_key, 0) AS closed_date_key,
    l.location_key,
    t.complaint_type_key,
    s.status_key,
    1 AS complaint_count,
    CASE 
        WHEN c.closed_date >= c.created_date 
        THEN TIMESTAMP_DIFF(c.closed_date, c.created_date, SECOND) / 86400.0
        ELSE NULL
    END AS resolution_days
FROM complaints AS c
LEFT JOIN {{ ref('dim_date') }} AS created
    ON DATE(c.created_date) = created.calendar_date
LEFT JOIN {{ ref('dim_date') }} AS closed
    ON DATE(c.closed_date) = closed.calendar_date
LEFT JOIN {{ ref('dim_location') }} AS l
    ON c.zip_code = l.zip_code
    AND c.borough = l.borough
    AND c.latitude IS NOT DISTINCT FROM l.latitude
    AND c.longitude IS NOT DISTINCT FROM l.longitude
    AND c.council_district IS NOT DISTINCT FROM l.council_district
LEFT JOIN {{ ref('dim_hpd_complaint_type') }} AS t
    ON c.problem = t.problem
    AND c.problem_detail IS NOT DISTINCT FROM t.problem_detail
LEFT JOIN {{ ref('dim_complaint_status') }} AS s
    ON c.status = s.status