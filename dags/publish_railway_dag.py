import os
from datetime import timedelta

import dlt
from airflow.decorators import dag
from airflow.providers.postgres.hooks.postgres import PostgresHook
from dlt.common import pendulum
from dlt.helpers.airflow_helper import PipelineTasksGroup


default_task_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email": "test@test.com",
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    "execution_timeout": timedelta(hours=4),
}

SOURCE_SCHEMA_PUBLICACAO = os.getenv("PUBLICACAO_SOURCE_SCHEMA", "mrt_gestao_a_vista")


@dag(
    dag_id="publish_railway_gestao_a_vista",
    schedule="@daily",
    start_date=pendulum.datetime(2025, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args=default_task_args,
)
def publish_railway_data():
    os.environ["DLT_PROJECT_DIR"] = "/usr/local/airflow"

    source_hook = PostgresHook(postgres_conn_id="postgres_prontocardio")
    source_conn = source_hook.get_connection(source_hook.postgres_conn_id)

    railway_hook = PostgresHook(postgres_conn_id="pg_railway_gestao_a_vista")
    railway_conn = railway_hook.get_connection(railway_hook.postgres_conn_id)
    destination_schema = os.getenv("PUBLICACAO_DESTINATION_SCHEMA", railway_conn.schema)

    source_credentials = (
        f"postgresql://{source_conn.login}:{source_conn.password}"
        f"@{source_conn.host}:{source_conn.port}/{source_conn.schema}"
    )

    railway_credentials = os.getenv("DATABASE_URL")
    if not railway_credentials:
        railway_credentials = (
            f"postgresql://{railway_conn.login}:{railway_conn.password}"
            f"@{railway_conn.host}:{railway_conn.port}/{railway_conn.schema}"
        )

    os.environ["SOURCE_POSTGRES_CREDENTIALS"] = (
        source_credentials
    )

    os.environ["DESTINATION__CREDENTIALS"] = (
        railway_credentials
    )

    tasks_dlt = PipelineTasksGroup(
        "publish_railway_pipeline_decomposed", use_data_folder=False, wipe_local_data=True
    )

    from script_ingestao.source_publicacao_railway import source_publicacao_railway

    pipeline = dlt.pipeline(
        pipeline_name="publish_railway_gestao_a_vista",
        dataset_name=destination_schema,
        destination="postgres",
        full_refresh=False,
        refresh="drop_sources",
    )

    source = source_publicacao_railway(source_schema=SOURCE_SCHEMA_PUBLICACAO)

    tasks_dlt.add_run(
        pipeline,
        source,
        decompose="serialize",
        trigger_rule="all_done",
        retries=0,
    )


dag = publish_railway_data()
