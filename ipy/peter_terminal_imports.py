import time

start = time.time()

import contextlib


@contextlib.contextmanager
def timing():
    start_ns = time.time_ns()
    yield
    end_ns = time.time_ns()
    elapsed = (end_ns - start_ns) / 1e9
    print(f"{elapsed} sec")


import numpy as np
from rich import pretty

pretty.install()

from rich.console import Console
from rich.table import Table
from rich import box
from typing import List, Dict, Tuple, Callable, Union, Any
import copy
import os, sys
from pathlib import Path
# import sympy as s

console = Console()


def wa(debug=False) -> str:
    """
    Calls WolframAlpha on a string query.
    :param query:
    :return:
    """
    if not debug:
        # if query is None:
        #     raise ValueError("You don't want to add a query?")
        # elif not isinstance(query, str):
        #     raise TypeError(f"Query must be a string, you provided a {type(query)}.")
        query = input("Query: ")

    import wolframalpha
    import json

    with open("credentials.json") as f:
        credentials = json.load(f)

    client = wolframalpha.Client(
        app_id=credentials["wolfram_appid"]
    )

    if debug:
        details = {
            'Result'                  : '69710 mi^2 (square miles)',
            'Input interpretation'    : 'Missouri | total area',
            'Comparisons as area'     : '≈ 0.51 × total area of Germany ( 357022 km^2 )',
            'Corresponding quantities': 'Radius r of a circle from A = πr^2:\n'
                                        ' | 149 miles\n'
                                        ' | 240 km (kilometers)',
            'Geographic properties'   : 'total area | 69710 mi^2\n'
                                        'land area | 68740 mi^2\n'
                                        'water area | 965.5 mi^2\n'
                                        'farmland area | 29 million acres\n'
                                        'mean elevation | 787.4 ft\n'
                                        'highest point | Taum Sauk Mountain, 1772 ft\n'
                                        'lowest point | Saint Francis River, 229.7 ft\n'
                                        '(2002)',
            'Unit conversions'        : '1.943×10^12 ft^2 (square feet)'
        }
    else:
        output = client.query(input=query)
        details = output.details

    table = Table(show_header=False)
    table.no_wrap = True
    table.box = box.MINIMAL

    result = None

    if "Result" in details.keys():  # If results are there, put them on top
        details = {
            "Result": details.pop("Result"),
            **details
        }

    for i, (k, v) in enumerate(details.items()):
        if k == "input interpretation":
            style = "white"
        else:
            style = "dim white"

        if "Result" in details.keys():
            if k == "Result":
                style = "bold green"
        else:
            if i == 0:
                style = "bold green"

        table.add_row(
            k,
            v,
            style=style
        )
        if i == 0:
            table.add_row()

    console.print(table)

    return result


print(f"Peter's Python Terminal"
      f" (started in {1000 * (time.time() - start):.0f} ms)"
      )
del start

