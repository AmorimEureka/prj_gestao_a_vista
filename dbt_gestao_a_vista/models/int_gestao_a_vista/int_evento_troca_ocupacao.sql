{{
    config(
        materialized = 'incremental',
        unique_key = 'evento_troca_id',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with historico_ocupacao as (
    select
        unidade_id,
        leito_id,
        paciente_id,
        atendimento_id,
        dbt_valid_from,
        dbt_valid_to,
        lag(paciente_id) over (
            partition by unidade_id, leito_id
            order by dbt_valid_from
        ) as paciente_id_anterior,
        lag(atendimento_id) over (
            partition by unidade_id, leito_id
            order by dbt_valid_from
        ) as atendimento_id_anterior
    from {{ ref('snap_ocupacao_atual_leito') }}
),

eventos_troca as (
    select
        unidade_id,
        leito_id,
        paciente_id_anterior,
        paciente_id as paciente_id_atual,
        atendimento_id_anterior,
        atendimento_id as atendimento_id_atual,
        dbt_valid_from as dt_troca,
        dbt_valid_to as dt_fim_vigencia,
        case
                        when (paciente_id_anterior is not null or atendimento_id_anterior is not null)
                         and (
                                        (paciente_id_anterior is distinct from paciente_id)
                                 or (atendimento_id_anterior is distinct from atendimento_id)
                                 )
            then 1
            else 0
        end as fl_troca
    from historico_ocupacao
),

base_eventos as (
    select
        row_number() over (
            order by unidade_id, leito_id, dt_troca
        ) as evento_troca_id,
        unidade_id,
        leito_id,
        paciente_id_anterior,
        paciente_id_atual,
        atendimento_id_anterior,
        atendimento_id_atual,
        dt_troca,
        dt_fim_vigencia,
        cast(dt_troca as date) as data_referencia
    from eventos_troca
    where fl_troca = 1
)

select
    evento_troca_id,
    unidade_id,
    leito_id,
    paciente_id_anterior,
    paciente_id_atual,
    atendimento_id_anterior,
    atendimento_id_atual,
    dt_troca,
    dt_fim_vigencia,
    data_referencia
from base_eventos
