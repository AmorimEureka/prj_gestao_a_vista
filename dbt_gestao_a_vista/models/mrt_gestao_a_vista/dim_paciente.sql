{{
    config(
        materialized = 'view',
        tags = ['gesta']
    )
}}

select
    cd_paciente,
    nm_paciente,
    nm_mae,
    dt_nascimento,
    cast(date_part('year', age(current_date, dt_nascimento)) as integer) as idade
from {{ ref('stg_paciente') }}
