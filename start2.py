from typing import NoReturn
from pydantic import BaseModel
from logging import Logger
import time
logger = Logger(__name__)
my_dict = {
    1: 'apple',
    2: 'ball',
}

my_list = [1, 2, 3, 4, 5, 6, 7, 8, 9]


class MyModel(BaseModel):
    pass

class MyError(Exception):
    ...


def do_example(a: str | None = None, b: int | None = None, c: int | None = None, d: int | None = None, e: int | None = None) -> NoReturn:
    """Compute function"""
    # logger.info(a, b, c, d, e)
    msg = "no way"
    raise MyError(msg)


def do_example2(a: str | None = None, b: int | None = None, c: int | None = None, d: int | None = None, e: int | None = None, f: int | None = None) -> NoReturn:
    """Example function2"""
    logger.info(a, b, c, d, e, f)

def do_example3(a: str | None = None, b: int | None = None, c: int | None = None, d: int | None = None, e: int | None = None,) -> NoReturn:
    """Example function"""
    logger.info(a, b, c, d, e)
    raise Exception('no way')
