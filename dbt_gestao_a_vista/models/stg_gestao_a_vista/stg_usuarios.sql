{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_usuario',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with source_data as (
    select
        CD_USUARIO,
        CD_MATRICULA,
        NM_USUARIO,
        SN_ATIVO
    from {{ source('raw_gestao_a_vista', 'USUARIOS') }}
    where SN_ATIVO = 'S'
)

select
    CD_USUARIO as cd_usuario,
    CD_MATRICULA as cd_matricula,
    NM_USUARIO as nm_usuario,
    SN_ATIVO as sn_ativo
from source_data
