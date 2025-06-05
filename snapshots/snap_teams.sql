{% snapshot snap_team %}
{{
    config(
      target_schema='SNAPSHOTS',
      unique_key='TEAM_NAME',
      strategy='check',
      check_cols=['TEAM_NAME']
    )
}}
SELECT * FROM {{ ref('dim_team') }}
{% endsnapshot %}
