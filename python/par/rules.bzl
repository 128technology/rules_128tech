"""
wrappers around subpar
"""

load("@subpar//:subpar.bzl", original_par_binary = "par_binary")
load("//python:versions.bzl", "PYTHON3")

def par_binary(
        name,
        python_version = "PY3",
        zip_safe = False,
        extract_dir = None,
        compiler_args = None,
        **kwargs):
    """
    A wrapper for the subpar par_binary rule that allows pars to be built with the correct interpreter

    Args:
        name(str): name of the target

        python_version (str): the major Python version with which this par
            should be executed [default: "PY3"]

        zip_safe: (bool) Whether to import Python code and read datafiles directly from
            the zip archive.  Otherwise, if False, all files are extracted to a
            temporary directory (or extract_dir) on disk each time the par file
            executes.

        extract_dir: (str) Set an explicit extraction output directory.  This is only
            used if zip_safe is True.

        compiler_args: (str_list) Explicitly set the compiler arguments.

        **kwargs(dict): passed to subpar par_binary
    """

    # TODO move this to subpar
    if extract_dir and zip_safe:
        fail("'extract_dir' only has an affect when 'zip_safe' is False")

    original_par_binary(
        name = name,
        compiler = "@subpar//compiler",
        compiler_args = compiler_args or ["--interpreter", "/usr/bin/env %s" % PYTHON3],
        python_version = python_version,
        zip_safe = zip_safe,
        extract_dir = extract_dir,
        **kwargs
    )

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
