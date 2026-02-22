{{
    config(
        materialized = 'incremental',
        unique_key = 'documento_id',
        on_schema_change = 'sync_all_columns',
        tags = ['gesta']
    )
}}


with janelas as (
    select
        data_referencia,
        turno,
        dt_inicio,
        dt_fim
    from {{ ref('dim_janela_turno') }}
),

leitos as (
    select
        cd_leito as leito_id,
        cd_unid_int as unidade_id
    from {{ ref('stg_leito') }}
),

ocupacao_atual as (
    select
        unidade_id,
        leito_id,
        paciente_id,
        atendimento_id,
        dh_atendimento
    from {{ ref('int_ocupacao_atual_leito') }}
),

eventos_troca as (
    select
        unidade_id,
        leito_id,
        paciente_id_atual as paciente_id,
        atendimento_id_atual as atendimento_id,
        dt_troca
    from {{ ref('int_evento_troca_ocupacao') }}
),

base_janela_leito as (
    -- CROSS JOIN (ON 1=1): cria a malha completa janela x todos os leito;
    -- objetivo: garantir todos os leitos em todas as janelas, com ou sem ocupação.
    -- Na sequência os leitos/unidades são preenchidos com dados da ocupação
    select
        j.data_referencia,
        j.turno,
        j.dt_inicio,
        j.dt_fim,
        l.unidade_id,
        l.leito_id,
        o.paciente_id,
        o.atendimento_id,
        o.dh_atendimento
    from janelas j
    join leitos l
        on 1 = 1
    left join ocupacao_atual o
        on o.unidade_id = l.unidade_id
       and o.leito_id = l.leito_id
),

linhas_base as (
    -- Efeito prático: gera a linha inicial do documento por janela/leito para pacientes ocupantes.
    -- Objetivo: criar o ponto de partida da timeline com dt_evento ajustado ao intervalo da janela.
    select
        data_referencia,
        turno,
        unidade_id,
        leito_id,
        paciente_id,
        atendimento_id,
        case
            when dh_atendimento is null then dt_inicio
            when dh_atendimento < dt_inicio then dt_inicio
            when dh_atendimento >= dt_fim then dt_inicio
            else dh_atendimento
        end as dt_evento,
        dt_inicio,
        dt_fim
    from base_janela_leito
    where paciente_id is not null
),

linhas_troca as (
    -- Efeito prático: cria uma linha para cada troca de paciente/atendimento dentro da janela.
    -- Objetivo: registrar eventos de mudança e gerar nova versão para envio à aplicação.
    select
        b.data_referencia,
        b.turno,
        b.unidade_id,
        b.leito_id,
        e.paciente_id,
        e.atendimento_id,
        e.dt_troca as dt_evento,
        b.dt_inicio,
        b.dt_fim
    from base_janela_leito b
    join eventos_troca e
        on e.unidade_id = b.unidade_id
       and e.leito_id = b.leito_id
       and e.dt_troca >= b.dt_inicio
       and e.dt_troca < b.dt_fim
),

timeline_documentos as (
    -- Efeito prático: une linha base + linhas de troca em uma única timeline de eventos do leito.
    -- Objetivo: consolidar todos os gatilhos de geração/versionamento do documento.
    select * from linhas_base
    union all
    select * from linhas_troca
),

timeline_ordenada as (
    -- Efeito prático: ordena os eventos por tempo e cria sequência por janela/unidade/leito.
    -- Objetivo: definir versão do documento (seq_documento) para rastreio e integração.
    select
        data_referencia,
        turno,
        unidade_id,
        leito_id,
        paciente_id,
        atendimento_id,
        dt_evento,
        dt_inicio,
        dt_fim,
        -- Efeito prático: numera cronologicamente cada documento dentro da mesma janela/unidade/leito.
        -- Objetivo: garantir versão sequencial e compor o identificador único (documento_id).
        row_number() over (
            partition by data_referencia, turno, unidade_id, leito_id
            order by dt_evento, paciente_id, atendimento_id
        ) as seq_documento
    from timeline_documentos
)

select
    cast(data_referencia as varchar)
        || '_' || turno
        || '_' || cast(unidade_id as varchar)
        || '_' || cast(leito_id as varchar)
        || '_' || cast(seq_documento as varchar) as documento_id,
    data_referencia,
    turno,
    unidade_id,
    leito_id,
    paciente_id,
    atendimento_id,
    'ABERTO' as status_documento,
    dt_inicio,
    dt_fim,
    dt_evento as dt_geracao_documento,
    seq_documento
from timeline_ordenada
