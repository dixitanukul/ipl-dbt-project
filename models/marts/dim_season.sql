{{ config(materialized='table', schema='MARTS') }}

WITH seasons AS (
    SELECT INITCAP(TRIM(SEASON)) AS SEASON_NAME
    FROM {{ ref('stg_ipl_match_data') }}
    WHERE SEASON IS NOT NULL AND TRIM(SEASON) <> ''
)
SELECT
    ROW_NUMBER() OVER (ORDER BY SEASON_NAME) AS SEASON_ID,
    SEASON_NAME
FROM seasons
GROUP BY SEASON_NAME
