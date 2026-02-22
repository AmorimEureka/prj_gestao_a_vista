flowchart TB

%% =====================================================
%% 1) FONTE ORACLE (DBAMV)
%% =====================================================
A["1) Oracle / DBAMV (fonte)
Tabelas principais:
- ATENDIME
- PACIENTE
- USUARIOS
- UNID_INT
- LEITO
- MOT_ALT"]

%% =====================================================
%% 2) INGESTAO DLT (AIRFLOW)
%% =====================================================
B["2) Airflow + DLT
Pipeline: gestao_a_vista
Carga incremental para Postgres
Dataset: raw_gestao_a_vista"]

subgraph RAW["raw_gestao_a_vista"]
	RAW_H["Tabelas RAW"]
	B1["raw_gestao_a_vista.atendime"]
	B2["raw_gestao_a_vista.paciente"]
	B3["raw_gestao_a_vista.usuarios"]
	B4["raw_gestao_a_vista.unid_int"]
	B5["raw_gestao_a_vista.leito"]
	B6["raw_gestao_a_vista.mot_alt"]
	RAW_H --> B1
	RAW_H --> B2
	RAW_H --> B3
	RAW_H --> B4
	RAW_H --> B5
	RAW_H --> B6
end

%% =====================================================
%% 3) DBT STAGING
%% =====================================================
subgraph STG["Modelos Staging"]
	STG_H["3) dbt staging (stg_gestao_a_vista)"]
	C1["stg_atendime"]
	C2["stg_paciente"]
	C3["stg_usuarios"]
	C4["stg_unid_int"]
	C5["stg_leito"]
	C6["stg_mot_alt"]
	STG_H --> C1
	STG_H --> C2
	STG_H --> C3
	STG_H --> C4
	STG_H --> C5
	STG_H --> C6
end

%% =====================================================
%% 4) DBT INTERMEDIARIO + SNAPSHOT
%% =====================================================
subgraph INT["Modelos Intermediate / Snapshot / Dimensão"]
	D["4) int_ocupacao_atual_leito
1 linha por unidade+leito
Campos-chave:
- paciente_id
- atendimento_id
- dh_atendimento"]

	E["5) snap_ocupacao_atual_leito (SCD2)
Chave: unidade_id + leito_id
Versiona mudança em:
- paciente_id
- atendimento_id"]

	F["6) int_evento_troca_ocupacao
Detecta troca por mudança de:
- paciente_id
- atendimento_id
Saída:
- dt_troca
- paciente/anterior-atual
- atendimento/anterior-atual"]

	G["7) dim_janela_turno
Janelas de turno:
- MT (07-19)
- SN (19-07)
Campos: data_referencia, dt_inicio, dt_fim"]
end

%% =====================================================
%% 5) MART
%% =====================================================
subgraph MART["Modelos Mart"]
	H["8) mart_documento_por_janela_horario
Rastreável por:
data, turno, unidade, leito, paciente, atendimento
Gera versões (seq_documento)
status_documento = ABERTO"]
end

%% =====================================================
%% 6) ENTREGA APLICACAO (OBJETIVO OPERACIONAL)
%% =====================================================
subgraph APP["Aplicação / Railway / Get Mocha"]
	I["9) Upsert para Railway (fonte da aplicação)
Dados publicados para app:
- documentos por janela
- usuários/equipe (origem: stg_usuarios)"]

	J["10) Get Mocha - Módulo Escala
Gerencia escala de técnicos/enfermeiros
Baseado em stg_usuarios"]

	K["11) Vínculo Equipe x Documento
Chave operacional:
data_referencia + turno + unidade
Define responsáveis pelo preenchimento"]

	L["12) Get Mocha - Módulo Protocolos
Exibe documentos gerados pelo pipeline
Equipe da escala preenche os documentos
Status operacional da app:
ABERTO -> INVALIDADO/FECHADO"]
end

%% =====================================================
%% CONEXOES
%% =====================================================
A --> B
B --> RAW
RAW --> STG
STG --> INT
INT --> MART

D --> E
E --> F

I --> J
I --> L
J --> K
L --> K

MART --> APP
