with duplicados as (
    select
        data_referencia,
        turno,
        unidade_id,
        leito_id,
        seq_documento,
        count(*) as qtd_registros
    from {{ ref('mart_documento_por_janela_horario') }}
    group by
        data_referencia,
        turno,
        unidade_id,
        leito_id,
        seq_documento
    having count(*) > 1
)

select *
from duplicados
