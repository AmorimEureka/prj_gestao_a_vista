import os

import dlt
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2 import sql


# Garante que o dlt leia .dlt/config.toml no ambiente do Airflow
os.environ.setdefault("DLT_PROJECT_DIR", "/usr/local/airflow")


def _normalize_optional_text(value):
    if value is None:
        return None
    if isinstance(value, str) and value.strip().lower() in {"", "none", "null"}:
        return None
    return value


def _build_resource(table_name: str, source_schema_override: str = None):
    configured_source_schema = _normalize_optional_text(
        dlt.config.get("sources.publicacao_railway.source_schema")
    )
    source_schema = _normalize_optional_text(
        dlt.config.get(f"sources.publicacao_railway.{table_name}.source_schema")
    ) or _normalize_optional_text(source_schema_override) or configured_source_schema
    write_disposition = _normalize_optional_text(
        dlt.config.get(f"sources.publicacao_railway.{table_name}.write_disposition")
    ) or "replace"
    primary_key = _normalize_optional_text(dlt.config.get(f"sources.publicacao_railway.{table_name}.primary_key"))
    target_table = _normalize_optional_text(
        dlt.config.get(f"sources.publicacao_railway.{table_name}.target_table")
    ) or f"app_{table_name}"

    source_credentials = os.getenv("SOURCE_POSTGRES_CREDENTIALS")
    if not source_credentials:
        raise ValueError("Variável de ambiente SOURCE_POSTGRES_CREDENTIALS não definida.")

    if not source_schema:
        raise ValueError(
            "Schema de origem não configurado para publicação. "
            "Defina 'sources.publicacao_railway.source_schema' "
            "ou 'sources.publicacao_railway.<tabela>.source_schema'."
        )

    @dlt.resource(name=target_table, write_disposition=write_disposition, primary_key=primary_key)
    def resource_publicacao():
        query = sql.SQL("SELECT * FROM {}.{}").format(
            sql.Identifier(source_schema),
            sql.Identifier(table_name),
        )

        with psycopg2.connect(source_credentials) as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(query)
                while True:
                    rows = cursor.fetchmany(1000)
                    if not rows:
                        break
                    for row in rows:
                        yield dict(row)

    return resource_publicacao


@dlt.source
def source_publicacao_railway(source_schema: str = None):
    table_names = dlt.config.get("sources.publicacao_railway.table_names") or []
    if isinstance(table_names, str):
        table_names = [table_names]

    if not table_names:
        table_names = [
            "mart_documento_por_janela_horario",
            "dim_leito",
            "dim_paciente",
            "dim_unid_int",
            "dim_usuarios",
        ]

    yield from [_build_resource(table_name, source_schema_override=source_schema) for table_name in table_names]
