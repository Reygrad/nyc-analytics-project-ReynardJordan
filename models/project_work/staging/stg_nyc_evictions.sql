WITH raw_evictions AS (
    SELECT *
    FROM {{ source('nyc_open_data_raw', 'evictions_raw') }}
),

renamed_evictions AS (
    SELECT
        court_index_number,
        docket_number,
        eviction_address,
        eviction_apt_num,
        executed_date,
        marshal_first_name,
        marshal_last_name,
        residential_commercial_ind,
        borough,
        eviction_zip AS zip_code,
        eviction_possession AS eviction_legal_possession,
        SAFE_CAST(latitude AS FLOAT64) AS latitude,
        SAFE_CAST(longitude AS FLOAT64) AS longitude,
        SAFE_CAST(council_district AS INT64) AS council_district
    FROM raw_evictions
)

SELECT DISTINCT * FROM renamed_evictions