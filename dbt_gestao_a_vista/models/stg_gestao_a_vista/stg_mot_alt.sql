{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_mot_alt',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with source_data as (
    select
        CD_MOT_ALT,
        DS_MOT_ALT,
        TP_MOT_ALTA,
        SN_ATIVO
    from {{ source('raw_gestao_a_vista', 'MOT_ALT') }}
    where SN_ATIVO = 'S'
)

select
    CD_MOT_ALT as cd_mot_alt,
    DS_MOT_ALT as ds_mot_alt,
    TP_MOT_ALTA as tp_mot_alta,
    SN_ATIVO as sn_ativo
from source_data
