from typing import NoReturn
from pydantic import BaseModel

my_dict = {
    1: "apple",
    2: "ball",
}

my_list = [1, 2, 3, 4, 5, 6, 7, 8, 9]


class MyModel(BaseModel):
    pass

def do_example(a: str | None = None, b: int | None = None, c: int | None = None, d: int | None = None, e: int | None = None) -> NoReturn:
    """Example function"""



def do_example2(a: str | None = None, b: int | None = None, c: int | None = None, d: int | None = None, e: int | None = None, f: int | None = None) -> NoReturn:
    """Example function2"""
