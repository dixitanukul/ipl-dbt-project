{{ config(materialized='table', schema='MARTS') }}

WITH teams AS (
    SELECT INITCAP(TRIM(TEAM_1)) AS TEAM_NAME
    FROM {{ ref('stg_ipl_match_data') }}
    WHERE TEAM_1 IS NOT NULL AND TRIM(TEAM_1) <> ''
    UNION
    SELECT INITCAP(TRIM(TEAM_2)) AS TEAM_NAME
    FROM {{ ref('stg_ipl_match_data') }}
    WHERE TEAM_2 IS NOT NULL AND TRIM(TEAM_2) <> ''
)
SELECT
    ROW_NUMBER() OVER (ORDER BY TEAM_NAME) AS TEAM_ID,
    TEAM_NAME
FROM teams
GROUP BY TEAM_NAME
