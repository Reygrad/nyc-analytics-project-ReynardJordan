{{ config(materialized='table') }}

WITH property_types AS (
    SELECT DISTINCT
        COALESCE(
            NULLIF(UPPER(TRIM(residential_commercial_ind)), ''),
            'UNKNOWN'
        ) AS property_type
    FROM {{ ref('stg_nyc_evictions') }}
)

SELECT 
    FARM_FINGERPRINT(property_type) AS property_type_key,
    property_type
FROM property_types