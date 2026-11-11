{{ config(materialized='table') }}

WITH evictions AS (
    SELECT 
        court_index_number,
        docket_number,
        executed_date,
        eviction_address,
        eviction_apt_num,
        COALESCE(
            NULLIF(UPPER(TRIM(residential_commercial_ind)), ''),
            'UNKNOWN'
        ) AS property_type,
        COALESCE(
            NULLIF(TRIM(eviction_legal_possession), ''),
            'Unspecified'
        ) AS eviction_legal_possession,
        COALESCE(NULLIF(TRIM(zip_code), ''), 'UNKNOWN') AS zip_code,
        COALESCE(NULLIF(UPPER(TRIM(borough)), ''), 'UNKNOWN') AS borough,
        latitude,
        longitude,
        council_district
    FROM {{ ref('stg_nyc_evictions') }}
)

SELECT 
    FARM_FINGERPRINT(
        TO_JSON_STRING(
            STRUCT(
                e.court_index_number AS court_index_number,
                e.docket_number AS docket_number,
                e.executed_date AS executed_date,
                e.eviction_address AS eviction_address,
                e.eviction_apt_num AS eviction_apt_num
            )
        )
    ) AS eviction_fact_key,
    e.court_index_number,
    COALESCE(d.date_key, 0) AS executed_date_key,
    l.location_key,
    p.property_type_key,
    e.eviction_legal_possession,
    1 AS eviction_count
FROM evictions AS e
LEFT JOIN {{ ref('dim_date') }} AS d
    ON DATE(e.executed_date) = d.calendar_date
LEFT JOIN {{ ref('dim_location') }} AS l
    ON e.zip_code = l.zip_code
    AND e.borough = l.borough
    AND e.latitude IS NOT DISTINCT FROM l.latitude
    AND e.longitude IS NOT DISTINCT FROM l.longitude
    AND e.council_district IS NOT DISTINCT FROM l.council_district
LEFT JOIN {{ ref('dim_property_type') }} AS p
    ON e.property_type = p.property_type[cite: 36, 37, 38, 39, 40, 42, 43]