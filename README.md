# To start

If you don't have installed `Task`. Just [do it](https://taskfile.dev/ru-RU/installation/). (Used to create short aliases to long commands)

If you don't have installed `poetry` (python package manager). Also just [do it](https://python-poetry.org/docs/#installation). (It helps to keep packages actual and a human-readable view)

If you don't have installed `pyenv`. [Install it](https://github.com/pyenv/pyenv#installation) too. (For better using different Python versions)

## Try it your self

1. Clone this repo.

    ```sh
    git clone https://github.com/Ax-Technology/python-template-project.git
    ```

2. Maybe it is not necessary

    ```sh
    chmod +x ./my_install.sh 
    ```

3. Copy `my_install.sh` to your home folder to store this file. Example `cp ./my_install.sh <path_to_your_folder>`

    ```sh
    cp ./my_install.sh ~/
    ```

4. Go to your project folder.

    ```sh
    cd <path_to_your_project>
    ```

5. Copy from your folder where file is to your project folder.  Example `cp <path_to_your_folder> ./my_install.sh`

    ```sh
    cp ~/my_install.sh .
    ```

6. Run script.

    ```sh
    ./my_install.sh
    ```

7. Create actual `pre-commit.yaml` and under the hood it install pre-commit.

    ```sh
    task generate-pre-commit-config
    ```

8. Update `pre-commit` dependency.

    ```sh
    task update-pre-commit-config
    ```

9. Try to use manually `pre-commit` hooks.

    ```sh
    task lint
    ```

10. Try to commit changes.

    ```sh
    git commit -m "<text>"
    ```

for skip checks `git commit -m "<text>" --no-verify`

## Info

### About lints

1. `safety` python package for safety check your packages
2. `pyproject.toml` a single place of all configs here. For `ruff`, `mypy`, etc.

### About `Task`

I'm using `task` instead of `makefile`. It's really simple to use if you are lazy man as me

It's also only alias for command like this

```sh
task lint
```

this command will start this

```sh
pre-commit run --all-files
```

You can customize your command in file `Taskfile.yml`

For me, it is very useful

### About `poetry`

1. The most important thing is that helps to separate `dev` packages from `prod` environments.

    Example (part of `project.toml` file):

    ```toml
    [tool.poetry.dependencies]
    python = "^3.11"
    pydantic = "^2.5.0"


    [tool.poetry.group.dev.dependencies]
    ruff = "^0.1.5"
    mypy = "^1.7.0"
    pytest = "^7.4.3"
    pre-commit = "^3.5.0"
    safety = "^2.3.5"
    ```

2. You can update all dependencies to the latest version  compatibility with each other

    ```sh
    poetry update
    ```

3. You can view dependency tree

    ```sh
    poetry show -t
    ```

    looks like:

    ```no-highlight
    pydantic 2.5.0 Data validation using Python type hints
    ├── annotated-types >=0.4.0
    ├── pydantic-core 2.14.1
    │   └── typing-extensions >=4.6.0,<4.7.0 || >4.7.0
    └── typing-extensions >=4.6.1
    ```

4. If you already cloned the project just activate the virtual environment and install the dependencies

    Setup right path to correct Python version

    ```sh
    poetry env use $(pyenv which python)
    ```

    Install dependency

    ```sh
    poetry install
    ```

### About `pyenv`

1. To change python version for folder use

    ```sh
    pyenv local 3.10
    ```

2. To install new version

    ```sh
    pyenv install 3.11
    ```

3. To change python version for folder use

    ```sh
    pyenv 3.10
    ```

4. I don't recommend change system python version. It can broken something

### TODO

-[ ] write poetry settings

-[ ] ...

### draft

```poetry settings
cache-dir = "/Users/antonzimin/Library/Caches/pypoetry"
experimental.system-git-client = false
installer.max-workers = null
installer.modern-installation = true
installer.no-binary = null
installer.parallel = true
virtualenvs.create = true
virtualenvs.in-project = true
virtualenvs.options.always-copy = false
virtualenvs.options.no-pip = false
virtualenvs.options.no-setuptools = false
virtualenvs.options.system-site-packages = false
virtualenvs.path = "{cache-dir}/virtualenvs"  # /Users/antonzimin/Library/Caches/pypoetry/virtualenvs
virtualenvs.prefer-active-python = true
virtualenvs.prompt = "{project_name}-py{python_version}"
warnings.export = true
```
