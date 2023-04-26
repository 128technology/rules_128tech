"""
wrappers around subpar
"""

load("@subpar//:subpar.bzl", "par_binary")

def parkour(name, srcs = [], python_version = "PY3", **kwargs):
    """
    Creates a par binary that acts as the Python interpreter. PARKOUR!

    By depending on py_library targets, a parkour can act as a Python interpreter with
    bundled libraries, so a script that uses the parkour as its shebang can import those
    libraries. PARKOUR!

    Args:
        name(str): name of the target
        srcs(label_list): list of source files
        python_version (str): the major Python version with which this par
            should be executed [default: "PY3"]

        **kwargs(dict): passed to subpar par_binary
    """
    parkour_main = Label("//python/par:kour.py")

    par_binary(
        name = name,
        python_version = python_version,
        srcs = srcs + [parkour_main],
        main = parkour_main,
        **kwargs
    )
