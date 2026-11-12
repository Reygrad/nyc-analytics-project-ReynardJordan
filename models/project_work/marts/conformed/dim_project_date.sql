{{ config(materialized='table') }}

WITH source_dates AS (
    SELECT DATE(created_date) AS calendar_date
    FROM {{ ref('stg_nyc_311_complaints') }}
    
    UNION DISTINCT
    
    SELECT DATE(closed_date)
    FROM {{ ref('stg_nyc_311_complaints') }}
    
    UNION DISTINCT
    
    SELECT DATE(executed_date)
    FROM {{ ref('stg_nyc_evictions') }}
),

date_bounds AS (
    SELECT 
        MIN(calendar_date) AS min_date,
        MAX(calendar_date) AS max_date
    FROM source_dates
    WHERE calendar_date IS NOT NULL
),

calendar AS (
    SELECT calendar_date
    FROM date_bounds,
    UNNEST(GENERATE_DATE_ARRAY(min_date, max_date)) AS calendar_date
)

SELECT 
    CAST(FORMAT_DATE('%Y%m%d', calendar_date) AS INT64) AS date_key,
    calendar_date,
    EXTRACT(YEAR FROM calendar_date) AS year,
    EXTRACT(MONTH FROM calendar_date) AS month,
    FORMAT_DATE('%Y-%m', calendar_date) AS year_month
FROM calendar

UNION ALL

SELECT
    0 AS date_key,
    CAST(NULL AS DATE) AS calendar_date,
    CAST(NULL AS INT64) AS year,
    CAST(NULL AS INT64) AS month,
    CAST(NULL AS STRING) AS year_month