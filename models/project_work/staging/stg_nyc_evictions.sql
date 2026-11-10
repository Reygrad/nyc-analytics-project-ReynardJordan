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
        latitude,
        longitude
    FROM raw_evictions
)

SELECT * FROM renamed_evictions