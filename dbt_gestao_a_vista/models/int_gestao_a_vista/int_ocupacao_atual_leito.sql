{{
    config(
        materialized = 'incremental',
        unique_key = ['unidade_id', 'leito_id'],
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with leitos as (
    select
        cd_leito as leito_id,
        cd_unid_int as unidade_id
    from {{ ref('stg_leito') }}
),

atendimentos_ativos as (
    select
        cd_leito as leito_id,
        cd_paciente as paciente_id,
        dt_atendimento,
        hr_atendimento,
        cd_atendimento
    from {{ ref('stg_atendime') }}
    where cd_leito is not null and
          cd_paciente is not null and
          dt_alta is null
),

atendimentos_com_unidade as (
    -- DT_ALTA IS NULL indica atendimento ativo, mas pode haver mais
    -- de um ativo no mesmo leito; nem todos TP_ATENDIMENTO='U' possuem DT_ALTA.
    -- Aqui adicionamos a unidade para formar a chave correta (unidade + leito).
    select
        l.unidade_id,
        a.leito_id,
        a.paciente_id,
        cast(a.dt_atendimento as date) +
        coalesce(cast(a.hr_atendimento as time), cast('00:00:00' as time)) as dh_atendimento,
        a.cd_atendimento
    from atendimentos_ativos a
    join leitos l
        on l.leito_id = a.leito_id
),

ocupacao_rankeada as (
    -- rankeamento garante 1 ocupação atual por unidade/leito.
    -- Se houver duplicidade de ativos, fica o registro mais recente
    select
        unidade_id,
        leito_id,
        paciente_id,
        dh_atendimento,
        cd_atendimento,
        row_number() over (
            partition by unidade_id, leito_id
            order by dh_atendimento desc, cd_atendimento desc
        ) as rn
    from atendimentos_com_unidade
)

select
    unidade_id,
    leito_id,
    paciente_id,
    dh_atendimento,
    cd_atendimento as atendimento_id
from ocupacao_rankeada
where rn = 1
