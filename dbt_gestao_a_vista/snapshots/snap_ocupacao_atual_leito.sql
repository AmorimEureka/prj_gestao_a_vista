{% snapshot snap_ocupacao_atual_leito %}

{{
    config(
        target_schema='snap_gestao_a_vista',
        unique_key=['unidade_id', 'leito_id'],
        strategy='check',
        check_cols=['paciente_id', 'atendimento_id'],
        invalidate_hard_deletes=true,
        tags=['gesta']
    )
}}

select *
from {{ ref('int_ocupacao_atual_leito') }}

{% endsnapshot %}
