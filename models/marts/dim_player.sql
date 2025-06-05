{{ config(materialized='table', schema='MARTS') }}

WITH players AS (
    SELECT INITCAP(TRIM(PLAYER_OF_MATCH)) AS PLAYER_NAME
    FROM {{ ref('stg_ipl_match_data') }}
    WHERE PLAYER_OF_MATCH IS NOT NULL AND TRIM(PLAYER_OF_MATCH) <> ''
)
SELECT
    ROW_NUMBER() OVER (ORDER BY PLAYER_NAME) AS PLAYER_ID,
    PLAYER_NAME
FROM players
GROUP BY PLAYER_NAME
