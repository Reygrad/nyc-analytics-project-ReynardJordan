WITH raw_311 AS (
    SELECT *
    FROM {{ source('nyc_open_data_raw', '311_complaints_raw') }}
),

renamed_311 AS (
    SELECT
        unique_key AS complaint_id,
        created_date,
        closed_date,
        agency,
        agency_name,
        complaint_type,
        descriptor,
        incident_zip AS zip_code,
        borough,
        latitude,
        longitude
    FROM raw_311
)

SELECT * FROM renamed_311