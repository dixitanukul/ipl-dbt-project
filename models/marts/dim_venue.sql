{{ config(materialized='table', schema='MARTS') }}

WITH raw_venues AS (
    SELECT
        INITCAP(TRIM(VENUE)) AS ALT_VENUE_NAME,
        INITCAP(TRIM(CITY)) AS ALT_CITY_NAME
    FROM {{ ref('stg_ipl_match_data') }}
    WHERE VENUE IS NOT NULL AND TRIM(VENUE) <> ''
)
, mapped_venues AS (
    SELECT
        vm.CANONICAL_VENUE_NAME,
        vm.CITY
    FROM raw_venues rv
    LEFT JOIN {{ ref('venue_master') }} vm
      ON rv.ALT_VENUE_NAME = INITCAP(TRIM(vm.ALT_VENUE_NAME))
    WHERE vm.CANONICAL_VENUE_NAME IS NOT NULL
)
SELECT
    ROW_NUMBER() OVER (ORDER BY CANONICAL_VENUE_NAME) AS VENUE_ID,
    CANONICAL_VENUE_NAME AS VENUE_NAME,
    CITY AS CITY_NAME
FROM mapped_venues
GROUP BY CANONICAL_VENUE_NAME, CITY
