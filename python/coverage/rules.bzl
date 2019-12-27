"""coverage.py utilities."""

load("@rules_python//python:defs.bzl", "py_binary")

_COLLECTOR = Label("//python/coverage:collector.py")

def coverage_collector(name, coveragerc = None):
    """
    Create a collector that merged multiple .coverage files found in the outputs of pytest_test.

    Args:
        name: (str): The name of the collector.
        coveragerc: (label) The configuration file for converage.py.

    """

    if coveragerc:
        args = ["--rcfile=$(execpath %s)" % coveragerc]
        data = [coveragerc]
    else:
        args = None
        data = None

    py_binary(
        name = name,
        srcs = [_COLLECTOR],
        args = args,
        data = data,
        main = _COLLECTOR,
        deps = [
            "@pip3//click",
            "@pip3//coverage",
        ],
    )
