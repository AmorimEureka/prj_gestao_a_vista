{{
    config(
        materialized = 'table',
        tags = ['gesta']
    )
}}

select
    cd_usuario,
    cd_matricula,
    nm_usuario
from {{ ref('stg_usuarios') }}
where upper(left(cd_usuario, 2)) in ('EN', 'TE')
