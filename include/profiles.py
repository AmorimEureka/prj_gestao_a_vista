

from cosmos import ProfileConfig
from cosmos.profiles import PostgresUserPasswordProfileMapping

airflow_postgres_db = ProfileConfig(
    profile_name="dbt_prontocardio",
    target_name="prod",
    profile_mapping=PostgresUserPasswordProfileMapping(
        conn_id="postgres_prontocardio",
        profile_args={"schema":"raw_mv"},
    ),
)

perfil_postgres_ens = ProfileConfig(
    profile_name="dbt_dw_entradas",
    target_name="prod",
    profile_mapping=PostgresUserPasswordProfileMapping(
        conn_id="postgres_prontocardio",
        profile_args={"schema": "raw_entradas_mv"},
    ),
)

perfil_postgres_gav = ProfileConfig(
    profile_name="dbt_gestao_a_vista",
    target_name="dev",
    profile_mapping=PostgresUserPasswordProfileMapping(
        conn_id="postgres_prontocardio",
        profile_args={"schema": "raw_gestao_a_vista"},
    ),
)
