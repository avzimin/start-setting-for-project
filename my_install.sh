pyenv local 3.11.5
poetry init --python "^3.11" -n
poetry env use $(pyenv which python)
echo '''
black
ruff
mypy
pytest
pylint
bandit
pre-commit

''' >> requirements-dev.txt
cat requirements-dev.txt | xargs poetry add -G dev

rm ./requirements-dev.txt


echo '''
version: "3"

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
        sh: echo "$(poetry export --with dev --without-hashes | while read line; do echo "          - $(echo ${line} | sed "s/^[ \t]*//")"; done)"
    cmds:
      - envsubst < .pre-commit-config.yaml.template > .pre-commit-config.yaml
      - echo "The .pre-commit-config.yaml file has been generated."

  update-pre-commit-config:
    desc: "Update versions .pre-commit-config.yaml"
    cmds:
      - pre-commit autoupdate

  lint:
    desc: "Run pre-commit run --all-files"
    preconditions:
      - test -f .pre-commit-config.yaml
    cmds:
      - pre-commit run --all-files

''' >> Taskfile.yml

echo '''
## folders
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

# dotenv
.env

''' | tee .gitignore .dockerignore

echo '''
[tool.pytest.ini_options]
addopts = "-vvv"
testpaths = [
    "tests",
]

[tool.ruff]
line-length = 120
exclude = ["__init__.py", "alembic", "src/upivka.py", "src/fight/example/*"]

[tool.bandit]
exclude_dirs = ["venv", "tests"]

[tool.mypy]
python_version = "3.11"
ignore_missing_imports = true
exclude = ["venv/", "alembic/"]

[tool.black]
line-length = 120

[tool.isort]
line_length = 119
profile = "black"
multi_line_output = 6
lines_after_imports = 2
force_single_line = true

[tool.autoflake]
check = true
imports = ["django", "requests", "urllib3"]

''' >> pyproject.toml

echo '''
default_language_version:
  python: python3.11

repos:
  - repo: https://github.com/floatingpurr/sync_with_poetry
    rev: "1.1.0"
    hooks:
      - id: sync_with_poetry

  - repo: https://github.com/Lucas-C/pre-commit-hooks-safety
    rev: "v1.3.1"
    hooks:
      - id: python-safety-dependencies-check
        files: pyproject.toml

  - repo: https://github.com/PyCQA/bandit
    rev: "1.7.5"
    hooks:
      - id: bandit
        args:
          - "--recursive"
          - "--aggregate=vuln"
          - "--configfile=pyproject.toml"
        additional_dependencies: ["bandit[toml]"]

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.0.286
    hooks:
      - id: ruff
        args: [ --fix, --exit-non-zero-on-fix ]

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        name: isort (python)

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
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

  - repo: https://github.com/psf/black
    rev: 23.7.0
    hooks:
      - id: black

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: "v1.7.0"
    hooks:
      - id: mypy
        args:
          - "--config-file=pyproject.toml"
          - "--install-types"
          - "--non-interactive"
        exclude: "alembic/"
        additional_dependencies:
$PRE_COMMIT_ADDITIONAL_DEPENDENCIES
''' >> .pre-commit-config.yaml.template

git init
git add .
git commit -m "initial"
touch start.py
touch README.md
