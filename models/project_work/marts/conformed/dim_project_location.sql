{{ config(materialized='table') }}

WITH combined_locations AS (
    SELECT 
        zip_code, 
        borough, 
        latitude, 
        longitude, 
        council_district
    FROM {{ ref('stg_nyc_311_complaints') }}
    
    UNION ALL
    
    SELECT 
        zip_code, 
        borough, 
        latitude, 
        longitude, 
        council_district
    FROM {{ ref('stg_nyc_evictions') }}
),

locations AS (
    SELECT DISTINCT
        COALESCE(NULLIF(TRIM(zip_code), ''), 'UNKNOWN') AS zip_code,
        COALESCE(NULLIF(UPPER(TRIM(borough)), ''), 'UNKNOWN') AS borough,
        latitude,
        longitude,
        council_district
    FROM combined_locations
)

SELECT 
    FARM_FINGERPRINT(
        TO_JSON_STRING(
            STRUCT(
                zip_code AS zip_code,
                borough AS borough,
                latitude AS latitude,
                longitude AS longitude,
                council_district AS council_district
            )
        )
    ) AS location_key,
    zip_code,
    borough,
    latitude,
    longitude,
    council_district
FROM locations