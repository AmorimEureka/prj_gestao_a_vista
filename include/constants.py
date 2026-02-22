
from pathlib import Path
from cosmos import ExecutionConfig
from cosmos.config import RenderConfig


dbt_executable = Path("/usr/local/airflow/dbt_venv/bin/dbt")
dbt_project_path = Path("/usr/local/airflow/dbt_gestao_a_vista")

venv_execution_config = ExecutionConfig(
    dbt_executable_path=str(dbt_executable),
)

venv_prj_dbt = dbt_project_path

# Configuração de renderização para pular testes
render_skip_tests_config = RenderConfig(
    test_behavior="skip",
)
