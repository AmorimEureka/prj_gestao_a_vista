{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_paciente',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with source_data as (
    select
        CD_PACIENTE,
        NM_PACIENTE,
        NM_MAE,
        DT_NASCIMENTO
    from {{ source('raw_gestao_a_vista', 'PACIENTE') }}
)

select
    CD_PACIENTE as cd_paciente,
    NM_PACIENTE as nm_paciente,
    NM_MAE as nm_mae,
    DT_NASCIMENTO as dt_nascimento
from source_data
