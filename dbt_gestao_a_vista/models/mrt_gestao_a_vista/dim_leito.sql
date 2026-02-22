{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_leito',
        incremental_strategy = 'merge',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

select
    cd_leito,
    cd_unid_int,
    ds_leito,
    tp_ocupacao
from {{ ref('stg_leito') }}
