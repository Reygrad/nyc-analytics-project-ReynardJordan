{{ config(materialized='table') }}

WITH complaint_types AS (
    SELECT DISTINCT
        COALESCE(
            NULLIF(UPPER(TRIM(complaint_type)), ''),
            'UNKNOWN'
        ) AS problem,
        NULLIF(UPPER(TRIM(descriptor)), '') AS problem_detail
    FROM {{ ref('stg_nyc_311_complaints') }}
)

SELECT 
    FARM_FINGERPRINT(
        TO_JSON_STRING(
            STRUCT(problem AS problem, problem_detail AS problem_detail)
        )
    ) AS complaint_type_key,
    problem,
    problem_detail
FROM complaint_types