{{
    config(
        materialized = 'incremental',
        unique_key = ['data_referencia', 'turno'],
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}

with datas_referencia as (
    select cast(current_timestamp as date) - 1 as data_referencia

    union

    select cast(current_timestamp as date) as data_referencia

    union

    select distinct
        cast(data_referencia as date) as data_referencia
    from {{ ref('int_evento_troca_ocupacao') }}
),

base_turnos as (
    select
        data_referencia,
        'MT' as turno
    from datas_referencia

    union all

    select
        data_referencia,
        'SN' as turno
    from datas_referencia
)

select
    data_referencia,
    turno,
    case
        when turno = 'MT' then cast(data_referencia as timestamp) + interval '7 hour'
        else cast(data_referencia as timestamp) + interval '19 hour'
    end as dt_inicio,
    case
        when turno = 'MT' then cast(data_referencia as timestamp) + interval '19 hour'
        else cast(data_referencia as timestamp) + interval '1 day' + interval '7 hour'
    end as dt_fim
from base_turnos
where case
                when turno = 'MT' then cast(data_referencia as timestamp) + interval '7 hour'
                else cast(data_referencia as timestamp) + interval '19 hour'
            end <= current_timestamp
