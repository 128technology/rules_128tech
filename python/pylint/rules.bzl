"""
pylint https://www.pylint.org/
"""

load("@rules_python//python:defs.bzl", "py_test")
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

    args = list(args) + ["--score", "no"]
    pylint_data = list()

    if rcfile != None:
        pylint_data.append(rcfile)
        args.extend(["--rcfile", "$(location %s)" % rcfile])

    _pylint_main(name = "%s_pylint_main" % name, srcs = srcs)

    main = "%s_pylint_main.py" % name

    py_test(
        name = name,
        srcs = [main] + list(srcs),
        data = pylint_data + data,
        main = main,
        deps = depset(
            direct = [
                "@rules_128tech//rules_128tech:sharder",
                "@pip3//pylint",
                # we need an explicit dep on toml because rules_pip doesn't support
                # adding a dep on `isort[pyproject]`.
                "@pip3//toml",
            ],
            transitive = [depset(deps)],
        ),
        python_version = "PY3",
        args = _get_color_args() + args,
        tags = ["pylint", "lint"] + tags,
        **kwargs
    )

def _impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.main,
        substitutions = {
            "@SOURCES@": "\n".join([src.path for src in ctx.files.srcs]),
        },
    )

_pylint_main = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".py"],
            mandatory = True,
        ),
        "_template": attr.label(
            default = "//python/pylint:pylint_main.py",
            allow_single_file = True,
        ),
    },
    outputs = {
        "main": "%{name}.py",
    },
)
