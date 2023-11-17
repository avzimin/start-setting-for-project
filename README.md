# To start

If you don't have installed `Task`. Just [do it](https://taskfile.dev/ru-RU/installation/).

If you don't have installed `poetry` (python package manager). Also just [do it](https://python-poetry.org/docs/#installation).

For better using different Python versions use `pyenv`. [Install it](https://github.com/pyenv/pyenv#installation) too.

1. Copy to folder

    ```sh
    cp <path>/my_install.sh .
    ```

2. Run script

    ```sh
    ./my_install.sh
    ```

3. Initialization pre-commit

    ```sh
    pre-commit install --allow-missing-config
    ```

4. Create actual `pre-commit.yaml`

    ```sh
    task generate-pre-commit-config
    ```

5. Try to use manually pre-commit hooks

    ```sh
    task lint
    ```

6. Stage files

    ```sh
    git add start2.py
    ```

7. Try to commit changes

    ```sh
    git commit -m "<text>"
    ```

for skip checks `git commit -m "<text>" --no-verify`

## Info

### About lints

1. `black` formatter default use double quotes it means that most `'` will be replaced to `"`
2. `isort` automatically places imports
3. `safety` python package for safety check your packages
4. `pyproject.toml` a single place of configs. all configs here. for `ruff`, `mypy`, `black`, `isort`, `autoflake`

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

For me, it is very useful

### About `pyenv`


