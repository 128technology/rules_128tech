"""
pytest https://docs.pytest.org/en/latest/
"""

load("@rules_python//python:defs.bzl", "py_test")
load("//python/par:rules.bzl", "par_binary")
load("//private:cfg.bzl", "DISABLE_COLOR")

_MAIN = Label("//python/pytest:main.py")

def _get_color_args():
    return select({
        DISABLE_COLOR: ["--color=no"],
        "//conditions:default": ["--color=yes"],
    })

def pytest_test(
        name,
        srcs = [],
        deps = [],
        python_version = "PY3",
        data = [],
        tags = [],
        shuffle = True,
        **kwargs):
    """
    Create a pytest test target

    Args:
        name(str): name of the target
        srcs(label_list): Source files to test
        deps(label_list): dependencies of the test
        python_version(str): the major version of python under which to run the tests (as in py_test)
        data(label_list): data files to include
        tags(str_list): list of arbitrary text tag
        shuffle(bool): if true, use pytest-randomly to shuffle tests in an arbitrary order.
        **kwargs: anything else to pass to the underlying py_test rule
    """
    if kwargs.pop("src", None):
        fail("'src' is no longer used in the 'pytest_test' rule. Use 'srcs' as a list instead")

    args = []

    args.extend(["$(location %s)" % src_ for src_ in srcs])

    if python_version == "PY2AND3":
        version_names = [
            ("PY2", "py2_%s" % name),
            ("PY3", "py3_%s" % name),
        ]
    else:
        version_names = [(python_version, name)]

    extra_deps = [depset(deps)]

    for version, test_name in version_names:
        version_args = args
        pytest_deps = ["@pip2and3//pytest"]

        if version == "PY3":
            version_args.extend([
                "--isort",
                "--cov",
                "--no-cov-on-fail",
            ])

            # isort implicitly requires toml to use `pyproject.toml:[tool.isort]`
            pytest_deps.extend([
                "@pip3//pytest_isort",
                "@pip3//pytest_timeout",
                "@pip3//toml",
                "@pip3//pytest_cov",
                "@pip3//pdbpp",
            ])

            if shuffle:
                pytest_deps.append("@pip3//pytest_randomly")

        version_deps = depset(pytest_deps, transitive = extra_deps)

        py_test(
            name = test_name,
            srcs = list(srcs) + [_MAIN],
            main = _MAIN,
            deps = version_deps,
            data = data,
            python_version = version,
            args = _get_color_args() + version_args,
            tags = ["pytest"] + tags,
            **kwargs
        )

def pytest_par(name, srcs, deps = [], args = [], **kwargs):
    """
    Create a tar target with a pytest par_binary and its tests

    Args:
        name(str): name of the target
        srcs(label_list): source files to test
        args(string_list): any commandline arguments to pass to the binary
        deps(label_list): dependencies of the test
        **kwargs: anything else to pass to the underlying par_binary rule
    """

    if not name.lower().endswith("test"):
        fail("name must end with 'test' (any case) to be found by the test runner")

    # A custom "main" is necessary because par_binary does NOT have an `args`
    # argument. To specify test paths, we need to inject them into the main.
    #
    # The custom main also determines the paths to the tests based on the
    # temporary extraction directory the par creates. This extraction is
    # necessary for pytest to operate on tests and results from `zip_safe = False`.

    # lower case for this python file name avoids linting failures
    main = "%s_main.py" % name.lower()

    _pytest_par_binary_main(
        name = main,
        srcs = srcs,
        args = args,
    )

    par_binary(
        name = name,
        srcs = srcs + [main],
        main = main,
        deps = deps + ["@pip3//pytest"],
        zip_safe = False,
        **kwargs
    )

def _pytest_par_binary_main_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.executable,
        substitutions = {
            "@ARGS@": ", ".join(["'%s'" % arg for arg in ctx.attr.args]),
            "@SRCS@": _create_srcs_string(ctx),
        },
        is_executable = True,
    )

def _create_srcs_string(ctx):
    """
    Create the comma separated string of source locations including workspace name
    """

    paths = [
        "%s/%s" % (ctx.workspace_name, _get_src_location(ctx, src_))
        for src_ in ctx.attr.srcs
    ]

    return '"%s"' % "', '".join(paths)

def _get_src_location(ctx, src):
    return ctx.expand_location("$(locations %s)" % src.label.name, ctx.attr.srcs)

_pytest_par_binary_main = rule(
    implementation = _pytest_par_binary_main_impl,
    attrs = {
        "srcs": attr.label_list(mandatory = True, allow_files = [".py"]),
        "_template": attr.label(
            default = "//python/pytest:main.py.template",
            allow_single_file = True,
        ),
    },
    executable = True,
)
