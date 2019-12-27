"""
Wrap other python linters to provide a simple way to enable all possible linters
"""

load("//python/pylint:rules.bzl", "pylint_test")

_AUTO_ADD_RULE_TYPES = [
    "py_library",
    "py_binary",
    "py_test",
]

def add_python_lint_tests(pylint = True, rcfile = None):
    """
    Add all the available static analysis available for each python target in the current BUILD file.

    Pylint:
        Creates one or two targets in the current package named ":pylint_test", ":pylint"
        Targets with the tag "no-pylint" will not have pylint run on them.

    Args:
        pylint(bool): control whether pylint tests are created for each target
        rcfile(label): pylint configuration file

    """

    # split pylint into two groups as we have two different rc files.
    pylint_srcs = []
    pylint_deps = []

    for existing_rule in native.existing_rules().values():
        if not should_add_lint_test(existing_rule):
            continue

        srcs = existing_rule["srcs"]
        deps = existing_rule["deps"]

        if "no-pylint" not in existing_rule["tags"]:
            pylint_srcs.extend(srcs)
            pylint_deps.extend(deps)

            pylint_test(
                name = "%s_pylint" % existing_rule["name"],
                srcs = list(srcs),
                deps = deps,
                rcfile = rcfile,
                tags = ["manual"],
            )

    if pylint:
        if not pylint_srcs:
            fail("no files to run pylint on! Explicitly set `pylint = False`")

        pylint_test(
            name = "pylint",
            srcs = depset(pylint_srcs).to_list(),
            deps = depset(
                transitive = [depset(pylint_deps)],
            ),
            rcfile = rcfile,
        )

def should_add_lint_test(existing_rule):
    return existing_rule["kind"] in _AUTO_ADD_RULE_TYPES

def is_test(existing_rule):
    """
    Returns a boolean indicating whether the existing rule should use the test rcfile

    Args:
        existing_rule(unknown): A https://docs.bazel.build/versions/master/skylark/lib/native.html#existing_rule

    Returns:
        bool: is it a test or not
    """
    return (
        existing_rule["kind"] == "py_test" or
        existing_rule["name"].endswith("conftest") or
        (existing_rule["kind"] == "py_binary" and existing_rule["name"].lower().endswith("test"))
    )
