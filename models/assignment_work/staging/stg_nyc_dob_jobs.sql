-- Clean and standardize DOB NOW job filings data
-- One row per job filing

WITH source AS (
    SELECT * FROM {{ source('raw', 'source_dob_now_jobs') }}
),

cleaned AS (
    SELECT
        -- Keep all other columns from the source intact for future fact tables
        * EXCEPT (
            job_filing_number,
            filing_date,
            current_status_date,
            first_permit_date,
            approved_date,
            signoff_date,
            borough,
            council_district,
            zip,          -- Added to prevent the duplicate column error
            zip_code,
            filing_representative_first_name,
            filing_representative_middle_initial,
            filing_representative_last_name,
            filing_representative_business_name,
            filing_representative_street_name,
            filing_representative_city,
            filing_representative_state,
            filing_representative_zip
        ),

        -- Identifiers
        CAST(job_filing_number AS STRING) AS job_filing_number,

        -- Dates (Required for dim_date)
        CAST(filing_date AS TIMESTAMP) AS filing_date,
        CAST(current_status_date AS TIMESTAMP) AS current_status_date,
        CAST(first_permit_date AS TIMESTAMP) AS first_permit_date,
        CAST(approved_date AS TIMESTAMP) AS approved_date,
        CAST(signoff_date AS TIMESTAMP) AS signoff_date,

        -- Location (Required for dim_location)
        -- Standardize borough to conform with 311 data
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,
        
        CAST(council_district AS STRING) AS council_district,
        
        -- Clean and rename zip_code to zip to conform with 311 data
        CASE
            WHEN UPPER(TRIM(CAST(zip_code AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(zip_code AS STRING)) = 5 THEN CAST(zip_code AS STRING)
            WHEN LENGTH(CAST(zip_code AS STRING)) = 9 THEN CAST(zip_code AS STRING)
            WHEN LENGTH(CAST(zip_code AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(zip_code AS STRING), r'^\d{5}-\d{4}') THEN CAST(zip_code AS STRING)
            ELSE NULL
        END AS zip,

        -- Filing Representative Details (Required for dim_filing_representative)
        CAST(filing_representative_first_name AS STRING) AS filing_representative_first_name,
        CAST(filing_representative_middle_initial AS STRING) AS filing_representative_middle_initial,
        CAST(filing_representative_last_name AS STRING) AS filing_representative_last_name,
        CAST(filing_representative_business_name AS STRING) AS filing_representative_business_name,
        CAST(filing_representative_street_name AS STRING) AS filing_representative_street_name,
        CAST(filing_representative_city AS STRING) AS filing_representative_city,
        CAST(filing_representative_state AS STRING) AS filing_representative_state,
        
        -- Clean filing rep zip code
        CASE
            WHEN UPPER(TRIM(CAST(filing_representative_zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN LENGTH(CAST(filing_representative_zip AS STRING)) = 5 THEN CAST(filing_representative_zip AS STRING)
            WHEN LENGTH(CAST(filing_representative_zip AS STRING)) = 9 THEN CAST(filing_representative_zip AS STRING)
            WHEN LENGTH(CAST(filing_representative_zip AS STRING)) = 10 AND REGEXP_CONTAINS(CAST(filing_representative_zip AS STRING), r'^\d{5}-\d{4}') THEN CAST(filing_representative_zip AS STRING)
            ELSE NULL
        END AS filing_representative_zip,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filter out rows where the primary key is null
    WHERE job_filing_number IS NOT NULL

    -- Deduplicate based on job_filing_number, keeping the most recently filed record
    QUALIFY ROW_NUMBER() OVER (PARTITION BY job_filing_number ORDER BY filing_date DESC) = 1
)

SELECT * FROM cleaned