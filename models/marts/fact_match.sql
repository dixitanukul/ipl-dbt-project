{{ config(materialized='table', schema='MARTS') }}

WITH mapped_matches AS (
    SELECT
        m.*,
        COALESCE(vm.CANONICAL_VENUE_NAME, INITCAP(TRIM(m.VENUE))) AS STD_VENUE_NAME
    FROM {{ ref('stg_ipl_match_data') }} m
    LEFT JOIN {{ ref('venue_master') }} vm
        ON INITCAP(TRIM(m.VENUE)) = INITCAP(TRIM(vm.ALT_VENUE_NAME))
)
, dim_season AS (
    SELECT SEASON_NAME, SEASON_ID FROM {{ ref('dim_season') }}
)
, dim_team AS (
    SELECT TEAM_NAME, TEAM_ID FROM {{ ref('dim_team') }}
)
, dim_player AS (
    SELECT PLAYER_NAME, PLAYER_ID FROM {{ ref('dim_player') }}
)
, dim_venue AS (
    SELECT VENUE_NAME, VENUE_ID FROM {{ ref('dim_venue') }}
)
SELECT
    m.MATCH_ID,
    m.MATCH_DATE,
    s.SEASON_ID,
    t1.TEAM_ID AS TEAM_1_ID,
    t2.TEAM_ID AS TEAM_2_ID,
    v.VENUE_ID,
    m.MATCH_TYPE,
    m.MATCH_RESULT,
    w.TEAM_ID AS WINNER_ID,
    m.BY_WICKETS,
    m.BY_RUNS,
    p.PLAYER_ID AS PLAYER_OF_MATCH_ID,
    m.TOSS_DECISION,
    toss.TEAM_ID AS TOSS_WINNER_ID,
    m.UMPIRE_1,
    m.UMPIRE_2,
    -- All calculated/derived columns below:
    CASE
        WHEN m.BY_RUNS > 0 THEN 'Runs'
        WHEN m.BY_WICKETS > 0 THEN 'Wickets'
        ELSE 'Other'
    END AS WIN_TYPE,
    CASE
        WHEN (COALESCE(m.BY_RUNS, 0) >= 30 OR COALESCE(m.BY_WICKETS, 0) >= 8) THEN 'Dominant'
        WHEN (COALESCE(m.BY_RUNS, 0) <= 10 AND m.BY_RUNS IS NOT NULL)
           OR (COALESCE(m.BY_WICKETS, 0) <= 3 AND m.BY_WICKETS IS NOT NULL)
           THEN 'Close'
        ELSE 'Normal'
    END AS WIN_MARGIN_CATEGORY,
    CASE
        WHEN m.MATCH_RESULT ILIKE '%tie%' THEN 1
        ELSE 0
    END AS WAS_TIED,
    CASE
        WHEN m.METHOD IS NOT NULL AND LENGTH(m.METHOD) > 0 THEN 1
        ELSE 0
    END AS WAS_DUCKWORTH_LEWIS,
    CASE
        WHEN toss.TEAM_ID = w.TEAM_ID AND toss.TEAM_ID IS NOT NULL THEN 1
        ELSE 0
    END AS DID_TOSS_WINNER_WIN,
    CASE
        WHEN m.CITY IS NULL OR TRIM(m.CITY) = '' THEN 1 ELSE 0 END AS NEUTRAL_VENUE,
    CASE
        WHEN m.BY_RUNS > 0 THEN CONCAT('Won by ', m.BY_RUNS, ' runs')
        WHEN m.BY_WICKETS > 0 THEN CONCAT('Won by ', m.BY_WICKETS, ' wickets')
        ELSE m.MATCH_RESULT
    END AS WIN_MARGIN_DESC,
    CASE
        WHEN p.PLAYER_ID IS NOT NULL THEN 1
        ELSE 0
    END AS HAS_PLAYER_OF_MATCH

FROM mapped_matches m
LEFT JOIN dim_season s
    ON INITCAP(TRIM(m.SEASON)) = s.SEASON_NAME
LEFT JOIN dim_team t1
    ON INITCAP(TRIM(m.TEAM_1)) = t1.TEAM_NAME
LEFT JOIN dim_team t2
    ON INITCAP(TRIM(m.TEAM_2)) = t2.TEAM_NAME
LEFT JOIN dim_venue v
    ON m.STD_VENUE_NAME = v.VENUE_NAME
LEFT JOIN dim_team w
    ON INITCAP(TRIM(m.WINNER)) = w.TEAM_NAME
LEFT JOIN dim_team toss
    ON INITCAP(TRIM(m.TOSS_WINNER)) = toss.TEAM_NAME
LEFT JOIN dim_player p
    ON INITCAP(TRIM(m.PLAYER_OF_MATCH)) = p.PLAYER_NAME
