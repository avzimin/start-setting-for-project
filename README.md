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
