{% snapshot snap_venue %}
{{
    config(
      target_schema='SNAPSHOTS',
      unique_key='VENUE',
      strategy='check',
      check_cols=['VENUE']
    )
}}
SELECT * FROM {{ ref('dim_venue') }}
{% endsnapshot %}
