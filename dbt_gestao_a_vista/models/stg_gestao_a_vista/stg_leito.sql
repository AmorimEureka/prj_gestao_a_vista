{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_leito',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with source_data as (
    select
        CD_LEITO,
        CD_UNID_INT,
        DS_LEITO,
        TP_OCUPACAO,
        TP_SITUACAO
    from {{ source('raw_gestao_a_vista', 'LEITO') }}
    WHERE TP_SITUACAO = 'A'
)

select
    CD_LEITO as cd_leito,
    CD_UNID_INT as cd_unid_int,
    DS_LEITO as ds_leito,
    TP_OCUPACAO as tp_ocupacao,
    TP_SITUACAO as tp_situacao
from source_data
