"""
pylint https://www.pylint.org/
"""

load("@rules_python//python:defs.bzl", "py_test")
load("//python/entry_point:rules.bzl", "py_entry_point")
load("//private:cfg.bzl", "DISABLE_COLOR")

def _get_color_args():
    return select({
        DISABLE_COLOR: ["--output-format=text"],
        "//conditions:default": [],
    })

def pylint_test(
        name,
        srcs,
        deps = [],
        data = [],
        args = [],
        tags = [],
        rcfile = None,
        **kwargs):
    """
    Create a py_test that runs pylint

    This currently only supports Python 3 because getting Pylint to work
    inside Bazel for Python 2 has been problematic

    Args:
        name(str): name of the test
        srcs(label_list): list of source files
        deps(depset): The list of other libraries to be linked in to the binary target
        data(label_list): The list of files needed by this rule at runtime
        args(str_list): Command line argument to pass to pylint
        tags(str_list): List of arbitrary text tags
        rcfile(label): pylint configuration file
        **kwargs(dict): arguments to pass to the native py_test rule
    """
    entry_point_name = "%s_entry_point" % name
    entry_point_output = ":%s.py" % entry_point_name

    py_entry_point(
        name = entry_point_name,
        module = "pylint",
    )

    args = list(args) + ["--score", "no"]

    if rcfile != None:
        args.extend(["--rcfile", "$(location %s)" % rcfile])

    for src in srcs:
        args.append("$(rootpaths %s)" % src)

    py_test(
        name = name,
        srcs = [entry_point_output] + srcs,
        data = [rcfile] + data,
        main = entry_point_output,
        deps = depset(
            direct = ["@pip3//pylint"],
            transitive = [depset(deps)],
        ),
        python_version = "PY3",
        args = _get_color_args() + args,
        tags = ["pylint", "lint"] + tags,
        **kwargs
    )
