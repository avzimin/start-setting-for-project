pyenv local 3.11
poetry init --python "^3.11" -n
poetry env use $(pyenv which python)

echo '''pydantic
pydantic-settings
tomli
pyyaml''' >> requirements.txt
cat requirements.txt | xargs poetry add

rm ./requirements.txt

echo '''
ruff
mypy
pytest
pre-commit''' >> requirements-dev.txt
cat requirements-dev.txt | xargs poetry add -G dev

rm ./requirements-dev.txt

echo '''version: "3"

tasks:
  default:
    - task: help

  help:
    desc: "List all tasks"
    silent: true
    cmds:
      - task --list-all

  generate-pre-commit-config:
    desc: "Generate .pre-commit-config.yaml file from .pre-commit-config.yaml.template"
    silent: true
    preconditions:
      - test -f .pre-commit-config.yaml.template
    generates:
      - .pre-commit-config.yaml
    env:
      PRE_COMMIT_ADDITIONAL_DEPENDENCIES:
        sh: echo "$(poetry export --with dev --without-hashes | while read line; do echo "          - $(echo ${line} | sed "s/^[[:space:]]*//")"; done)"
    cmds:
      - envsubst < .pre-commit-config.yaml.template > .pre-commit-config.yaml
      - echo "The .pre-commit-config.yaml file has been generated."

  install-pre-commit-config:
    desc: "Install pre-commit with generated .pre-commit-config.yaml"
    cmds:
      - pre-commit install
      - poetry update
      - task generate-pre-commit-config
      - pre-commit autoupdate
      - echo "The pre-commit installed and updated."

  update-pre-commit-config:
    desc: "Update versions .pre-commit-config.yaml and poetry update"
    cmds:
      - poetry update
      - task generate-pre-commit-config
      - pre-commit autoupdate
      - echo "The pre-commit updated."

  lint:
    desc: "Run pre-commit run --all-files"
    preconditions:
      - test -f .pre-commit-config.yaml
    cmds:
      - pre-commit run --all-files

  build-version:
    desc: "Generate version. Example for generate production version: task build-version -- -p"
    env:
      APP_VERSION:
        sh: python -m src.config.builder {{.CLI_ARGS}}
      APP_NAME:
        sh: python -m src.config.get_name
    cmds:
      - sed -i '.bak' -e "s/^APP_VERSION=.*/APP_VERSION=${APP_VERSION}/; s/^APP_NAME=.*/APP_NAME=${APP_NAME}/" build_version
      - echo "build version set up APP_VERSION=${APP_VERSION} APP_NAME=${APP_NAME}"

  build-docker-without-run:
    desc: "Build docker container Example: task build-docker-without-run -- '-p'"
    cmds:
      - task build-version -- {{.CLI_ARGS}}
      - docker compose -f docker-compose-dev.yaml --env-file ./build_version create --build

  # push-docker-container:
  #   desc: "Push docker container to docker hub"
  #   cmds:
  #     - docker image push --all-tags zimkaa/sales_bot

  run-docker:
    desc: Run docker container
    cmds:
      - docker compose -f docker-compose-dev.yaml --env-file ./build_version up -d

  stop-docker:
    desc: Stop docker container
    cmds:
      - docker compose -f docker-compose-dev.yaml --env-file ./build_version down

  # test:
  #   desc: Run tests
  #   cmds:
  #     - python -m coverage run
  #     - python -m coverage report -m
  #     - python -m coverage html

  test-deploy:
    desc: Action test locally
    cmds:
      # - act -j 'docker-build-push' --container-architecture linux/amd64 --var-file .vars --secret-file .secrets -e event.json
      - act --container-architecture linux/amd64 --var-file .vars --secret-file .secrets -e event.json''' >> Taskfile.yml

echo '''## folders
.venv/
.env/
__pycache__/
.pytest_cache/
.mypy_cache/

## files
*.pyc
*.log
*.log.zip
.python-version
.pre-commit-config.yaml
my_install.sh
.DS_Store

# dotenv
.env
.dev.env
.secrets
.vars''' | tee .gitignore .dockerignore

echo '''###########
# BUILDER #
###########
FROM python:3.11 as builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY ./pyproject.toml ./poetry.lock /app/

RUN pip install poetry && poetry install --no-dev

###########
## IMAGE ##
###########
FROM python:3.11-slim

WORKDIR /home/appuser/app

RUN groupadd -r appgroup && \
    useradd -r -g appgroup appuser && \
    chown -R appuser:appgroup /home/appuser/app

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

COPY . /home/appuser/app

RUN chmod +x /home/appuser/app/start_app.sh

USER appuser

CMD ["sh", "./start_app.sh"]'''  >> Dockerfile

echo '''#!/bin/sh

python start.py'''  >> start_app.sh

chmod +x ./start_app.sh

echo '''version: '3.8'

services:
  YOUR_SERVICE:
    build: .
    container_name: "${APP_NAME}-${APP_VERSION}"
    image: ${APP_NAME}:${APP_VERSION}
    env_file: .dev.env'''  >> docker-compose-dev.yml

echo '''version: '3.8'

services:
  YOUR_SERVICE:
    build: .
    container_name: "${APP_NAME}-${APP_VERSION}"
    image: ${APP_NAME}:${APP_VERSION}
    env_file: .env'''  >> docker-compose.yml

echo '''[tool.pytest.ini_options]
addopts = "-vvv"
asyncio_mode="auto"
cache_dir = "/tmp/pytest_cache"
testpaths = [
    "tests",
]

[tool.ruff]
cache-dir = "/tmp/ruff_cache"
fix = true
line-length = 120
unsafe-fixes = true
exclude = [
    "alembic/",
    ".bzr",
    ".direnv",
    ".eggs",
    ".git",
    ".git-rewrite",
    ".hg",
    ".ipynb_checkpoints",
    ".mypy_cache",
    ".nox",
    ".pants.d",
    ".pyenv",
    ".pytest_cache",
    ".pytype",
    ".ruff_cache",
    ".svn",
    ".tox",
    ".venv",
    "venv",
    ".vscode",
    "__pypackages__",
    "_build",
    "buck-out",
    "build",
    "dist",
    "node_modules",
    "site-packages",
]

[tool.ruff.lint]
select = ["ALL"]
ignore = [
    "D1",  # docstring
    "D203",  # docstring
    "D205",  # docstring
    "D213",  # docstring
    "D401",  # docstring
    "TRY401",  # exception logging
    # "FA102",
    "ANN101",
    # "S101",
    "EXE002",  # executable
    # project specific
]
exclude = []

[tool.ruff.lint.isort]
no-lines-before = ["standard-library", "local-folder"]
known-third-party = []
known-local-folder = ["src"]
lines-after-imports = 2
force-single-line = true

[tool.ruff.lint.extend-per-file-ignores]
"tests/*.py" = ["ANN101", "S101", "S311"]

[tool.ruff.format]
quote-style = "double"

[tool.mypy]
cache_dir = "/tmp/mypy_cache"
disable_error_code = "import-untyped"
exclude = ["~/.pyenv/*", ".venv/", "alembic/"]
ignore_missing_imports = true
python_version = "3.11"
plugins = [
    "pydantic.mypy",
]
strict = false

[tool.pyright]
ignore = []
include = ["src"]
pythonVersion = "3.11"
reportInvalidTypeForm = "none"''' >> pyproject.toml

echo '''default_language_version:
  python: python3.11

repos:
  - repo: https://github.com/floatingpurr/sync_with_poetry
    rev: "1.1.0"
    hooks:
      - id: sync_with_poetry

  - repo: https://github.com/Lucas-C/pre-commit-hooks-safety
    rev: "v1.3.3"
    hooks:
      - id: python-safety-dependencies-check
        files: pyproject.toml

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.5
    hooks:
      - id: ruff
        args: [ --fix, --exit-non-zero-on-fix ]
      - id: ruff-format

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
        exclude: src/fight/example
        exclude_types:
          - markdown
      - id: check-added-large-files
        args:
          - "--maxkb=1024"
      - id: check-yaml
        exclude: \.gitlab-ci.yml
      - id: check-ast
      - id: check-case-conflict
      - id: check-merge-conflict
      - id: check-symlinks
      - id: check-toml
      - id: debug-statements
      - id: end-of-file-fixer

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: "v1.9.0"
    hooks:
      - id: mypy
        args:
          - "--config-file=pyproject.toml"
          - "--install-types"
          - "--non-interactive"
        exclude: "alembic/"
        additional_dependencies:
$PRE_COMMIT_ADDITIONAL_DEPENDENCIES''' >> .pre-commit-config.yaml.template

echo '''{
  "act": true
}''' >> event.json

echo '''def main() -> None:
    ...'''  >> src/main.py

echo '''from src.main import main


if __name__ == "__main__":
    main()'''  >> start.py

touch README.md LICENSE.txt example.env .env .dev.env .vars .secrets

mkdir src logger tests src/application src/config src/domain src/infrastrutrure src/infrastrutrure/repository \
    src/use_cases src/use_cases/irepository logger/logging_config

touch src/__init__.py tests/__init__.py tests/conftest.py src/application/__init__.py src/domain/__init__.py \
    src/domain/entity.py src/domain/value_object.py src/main.py logger/__init__.py src/use_cases/__init__.py \
    src/infrastrutrure/__init__.py src/infrastrutrure/repository/__init__.py src/use_cases/irepository/__init__.py

# LOGGER
echo '''from __future__ import annotations
import json
import logging
import time


LOG_RECORD_BUILTIN_ATTRS = {
    "args",
    "asctime",
    "created",
    "exc_info",
    "exc_text",
    "filename",
    "funcName",
    "levelname",
    "levelno",
    "lineno",
    "module",
    "msecs",
    "message",
    "msg",
    "name",
    "pathname",
    "process",
    "processName",
    "relativeCreated",
    "stack_info",
    "thread",
    "threadName",
    "taskName",
}

GREEN = "\\x1b[38;5;40m"
RED = "\\x1b[38;5;196m"
ORANGE = "\\x1b[38;5;202m"
YELLOW = "\\x1b[38;5;226m"
BLUE = "\\x1b[38;5;21m"
NC = "\\x1b[0m"

DATEFMT = "%Y-%m-%dT%H:%M:%S%z"


class StdoutCustomFormatter(logging.Formatter):
    def __init__(
        self,
        *,
        fmt_keys: dict[str, str] | None = None,
    ) -> None:
        super().__init__()
        self.fmt_keys = fmt_keys if fmt_keys is not None else {}

        self.format_date = self.fmt_keys.get("datefmt", None)
        if self.format_date is None:
            self.format_date = DATEFMT

        format_string = self.fmt_keys.get("format", None)
        if format_string is None:
            format_string = "%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)3d | %(message)s"
        fmt = format_string.split(" | ")
        asctime = fmt[0]
        levelname = fmt[1]
        third_part = "".join(fmt[2:-1])
        message = fmt[-1]
        self.FORMATS = {
            logging.DEBUG: f"{GREEN}{asctime}{NC} | {levelname} | {third_part} | {message}",
            logging.INFO: f"{GREEN}{asctime}{NC} | {BLUE}{levelname} | {third_part}{NC} | {message}",
            logging.WARNING: f"{GREEN}{asctime}{NC} | {YELLOW}{levelname} | {third_part}{NC} | {message}",
            logging.ERROR: f"{GREEN}{asctime}{NC} | {ORANGE}{levelname} | {third_part}{NC} | {message}",
            logging.CRITICAL: f"{GREEN}{asctime}{NC} | {RED}{levelname} | {third_part}{NC} | {message}",
        }

    def format(self, record: logging.LogRecord) -> str:
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt, datefmt=self.format_date)
        return formatter.format(record)


class JSONCustomFormatter(logging.Formatter):
    def __init__(
        self,
        *,
        fmt_keys: dict[str, str] | None = None,
    ) -> None:
        super().__init__()
        self.fmt_keys = fmt_keys if fmt_keys is not None else {}

    def format(self, record: logging.LogRecord) -> str:
        message = self._prepare_log_dict(record)
        return json.dumps(message, default=str)

    def _prepare_log_dict(self, record: logging.LogRecord) -> dict[str, str]:
        ct = self.converter(record.created)
        timestamp = time.strftime(DATEFMT, ct)
        always_fields = {
            "message": record.getMessage(),
            "timestamp": timestamp,
        }
        if record.exc_info is not None:
            always_fields["exc_info"] = self.formatException(record.exc_info)

        if record.stack_info is not None:
            always_fields["stack_info"] = self.formatStack(record.stack_info)

        message = {
            key: msg_val if (msg_val := always_fields.pop(val, None)) is not None else getattr(record, val)
            for key, val in self.fmt_keys.items()
        }

        message.update(always_fields)

        for key, val in record.__dict__.items():
            if key not in LOG_RECORD_BUILTIN_ATTRS:
                message[key] = val

        return message''' >> logger/custom.py

echo '''version: 1
disable_existing_loggers: false
formatters:
  simple:
    format: "%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)3d | %(message)s"
    datefmt: "%Y-%m-%dT%H:%M:%S%z"
handlers:
  stdout:
    class: logging.StreamHandler
    level: DEBUG
    formatter: simple
    stream: ext://sys.stdout
loggers:
  root:
    level: INFO
    handlers:
    - stdout''' >> logger/logging_config/config.yaml

echo '''version: 1
disable_existing_loggers: false
formatters:
  simple:
    format: "%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)3d | %(message)s"
    datefmt: "%Y-%m-%dT%H:%M:%S%z"
  custom:
    (): logger.custom.StdoutCustomFormatter
    fmt_keys:
      format: "%(asctime)s | %(levelname)8s | %(filename)s:%(lineno)3d | %(message)s"
      datefmt: "%Y-%m-%dT%H:%M:%S%z"
handlers:
  stdout:
    class: logging.StreamHandler
    formatter: custom
    stream: ext://sys.stdout
    level: DEBUG
  file:
    class: logging.handlers.RotatingFileHandler
    formatter: simple
    filename: "tests.log"
    level: DEBUG
    maxBytes: 10000000
    backupCount: 5
loggers:
  root:
    level: INFO
    handlers:
    - stdout
    - file''' >> logger/logging_config/custom_config.yaml

echo '''import logging.config
from pathlib import Path
from typing import Final

import yaml

from .settings import settings


LOGGER_FOLDER_NAME: Final[str] = "logger"
LOGGER_CONFIG_FOLDER_NAME: Final[str] = "logging_config"

ROOT_PATH_LOGGER_FOLDER = Path(LOGGER_FOLDER_NAME)
PATH_LOGGER_FOLDER = ROOT_PATH_LOGGER_FOLDER / LOGGER_CONFIG_FOLDER_NAME

logger = logging.getLogger(settings.APP_NAME)


def setup_logging(config_file: str) -> None:
    config_file = PATH_LOGGER_FOLDER / config_file  # type: ignore[assignment]
    with Path(config_file).open() as f_in:
        config = yaml.safe_load(f_in)

    logging.config.dictConfig(config)


debug_level = "DEBUG" if settings.DEBUG else "INFO"
logger_level = settings.LOGGER_LEVEL if settings.LOGGER_LEVEL else debug_level
logger.setLevel(logger_level)
setup_logging(settings.LOGGER_CONFIG_FILE)''' >> src/config/logger.py

# SRC
echo '''from typing import Final


README_PATH: Final[str] = "./README.md"''' >> src/config/constants.py

echo '''import sys

from .project_info import get_name


def main() -> None:
    sys.stdout.write(f"{get_name()}\\n")


if __name__ == "__main__":
    main()''' >> src/config/get_name.py

echo '''import sys

from .project_info import get_version


def main() -> None:
    sys.stdout.write(f"{get_version()}\\n")


if __name__ == "__main__":
    main()''' >> src/config/get_version.py

echo '''from pathlib import Path

import tomli


def get_name() -> str:
    with Path("pyproject.toml").open("rb") as f:
        data = tomli.load(f)
    return data["tool"]["poetry"]["name"]


def get_version() -> str:
    with Path("pyproject.toml").open("rb") as f:
        data = tomli.load(f)
    return data["tool"]["poetry"]["version"]''' >> src/config/project_info.py

echo '''import sys
from datetime import datetime
from datetime import timezone
from pathlib import Path

from src.config import settings
from src.config.constants import README_PATH


class Build:
    def __init__(self, *, production: bool) -> None:
        self.production = production
        self.version = settings.APP_VERSION

    def _get_created_date(self) -> datetime:
        timestamp = Path(README_PATH).stat().st_ctime
        return datetime.fromtimestamp(timestamp, tz=timezone.utc)

    def _generate_version_code(self) -> int:
        start_dev = self._get_created_date()
        current_date = datetime.now(tz=timezone.utc)
        difference = current_date - start_dev
        return difference.seconds

    def change_version(self) -> None:
        if not self.production:
            version_code = self._generate_version_code()
            build_number = f"-{version_code}"
            self.version = f"{self.version}{build_number}"

    def get_version(self) -> str:
        self.change_version()
        return self.version


def main(*, production: bool = False) -> None:
    build = Build(production=production)
    sys.stdout.write(f"{build.get_version()}\\n")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("-production", action="store_true", help="Creates a build version for production")
    args = parser.parse_args()
    main(production=args.production)''' >> src/config/builder.py

echo '''from pydantic import Field
from pydantic_settings import BaseSettings
from pydantic_settings import SettingsConfigDict

from .project_info import get_name
from .project_info import get_version


app_version = get_version()
app_name = get_name()


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="allow", env_file=".env", env_file_encoding="utf-8")

    DEBUG: bool = Field(default=False)
    LOGGER_LEVEL: str = Field(default="")
    LOGGER_CONFIG_FILE: str = Field(default="config.yaml")

    APP_VERSION: str = Field(default=app_version)
    APP_NAME: str = Field(default=app_name)


settings = Settings()''' >> src/config/settings.py

echo '''from .logger import logger
from .settings import settings


__all__ = [
    "logger",
    "settings",
]''' >> src/config/__init__.py

echo '''APP_VERSION=
APP_NAME=''' >> build_version

git add .
git commit -m "initial"
git branch -M main
