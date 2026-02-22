{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_unid_int',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with source_data as (
    select
        CD_UNID_INT,
        DS_UNID_INT,
        SN_ATIVO
    from {{ source('raw_gestao_a_vista', 'UNID_INT') }}
    where SN_ATIVO = 'S'
)

select
    CD_UNID_INT as cd_unid_int,
    DS_UNID_INT as ds_unid_int,
    SN_ATIVO as sn_ativo
from source_data
