{{ config(materialized='table') }}

WITH statuses AS (
    SELECT DISTINCT
        COALESCE(
            NULLIF(UPPER(TRIM(status)), ''),
            'UNKNOWN'
        ) AS status
    FROM {{ ref('stg_nyc_311_complaints') }}
)

SELECT 
    FARM_FINGERPRINT(status) AS status_key,
    status
FROM statuses