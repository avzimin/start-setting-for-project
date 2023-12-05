pyenv local 3.11.5
poetry init --python "^3.11" -n
poetry env use $(pyenv which python)
echo '''
ruff
mypy
pytest
pylint
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
      - poetry update
      - task generate-pre-commit-config
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
cache_dir = "/tmp/pytest_cache"
addopts = "-vvv"
testpaths = [
    "tests",
]

[tool.ruff]
line-length = 120
fix = true
unsafe-fixes = true
select = ["ALL"]
ignore = ["D1", "D203", "D213", "FA102", "ANN101", "S101"]
exclude = ["__init__.py", "alembic", ".venv/*"]
cache-dir = "/tmp/ruff_cache"

[tool.ruff.isort]
no-lines-before = ["standard-library", "local-folder"]
known-third-party = []
known-local-folder = ["whole_app"]
lines-after-imports = 2
force-single-line = true

[tool.ruff.extend-per-file-ignores]
"tests/*.py" = ["ANN101", "S101", "S311"]

[tool.ruff.format]
quote-style = "double"

[tool.mypy]
cache_dir = "/tmp/mypy_cache"
python_version = "3.11"
ignore_missing_imports = true
strict = true
install_types = true
exclude = [".venv/", "alembic/"]
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

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.0.286
    hooks:
      - id: ruff
        args: [ --fix, --exit-non-zero-on-fix ]
      - id: ruff-format

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
