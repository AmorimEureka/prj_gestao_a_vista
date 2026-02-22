{{
    config(
        materialized = 'incremental',
        unique_key = 'cd_atendimento',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with source_data as (
    select
        CD_ATENDIMENTO,
        CD_PACIENTE,
        CD_CONVENIO,
        CD_LEITO,
        DT_ATENDIMENTO,
        DT_ALTA,
        HR_ALTA,
        HR_ATENDIMENTO,
        TP_ATENDIMENTO,
        SN_OBITO
    from {{ source('raw_gestao_a_vista', 'ATENDIME') }}
    where TP_ATENDIMENTO in('I','U')
)

select
    CD_ATENDIMENTO as cd_atendimento,
    CD_PACIENTE as cd_paciente,
    CD_CONVENIO as cd_convenio,
    CD_LEITO as cd_leito,
    DT_ATENDIMENTO as dt_atendimento,
    DT_ALTA as dt_alta,
    HR_ALTA as hr_alta,
    HR_ATENDIMENTO as hr_atendimento,
    TP_ATENDIMENTO as tp_atendimento,
    SN_OBITO as sn_obito
from source_data
