{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_unid_int',
        incremental_strategy = 'merge',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

select
    cd_unid_int,
    ds_unid_int
from {{ ref('stg_unid_int') }}
