"""
Wrap other python linters to provide a simple way to enable all possible linters
"""

load("//python/pylint:rules.bzl", "pylint_test")

_AUTO_ADD_RULE_TYPES = [
    "py_library",
    "py_binary",
    "py_test",
]

def add_python_lint_tests(pylint = True, rcfile = None, deps = [], **kwargs):
    """
    Add all the available static analysis available for each python target in the current BUILD file.

    Pylint:
        Create a single target named ":pylint" which will lint all *py_binary*'s in the
        current directory.

        Targets with the tag "no-pylint" will not have pylint run on them.

        For each *py_binary* a "manual" target with the name
        "<original_py_binary_name>_pylint" will be created so that linting can be run
        on just that file.

    Args:
        pylint(bool): control whether pylint tests are created.
        rcfile(label): pylint configuration file
        deps(label_list): extra dependencies of the pylint test
        **kwargs: Pass other keyword arguments directly to pylint_test.

    """

    pylint_srcs = []
    pylint_deps = []

    for existing_rule in native.existing_rules().values():
        if not should_add_lint_test(existing_rule):
            continue

        if "no-pylint" not in existing_rule["tags"]:
            pylint_srcs.extend(existing_rule["srcs"])
            pylint_deps.append(existing_rule["name"])

    if pylint:
        if not pylint_srcs:
            fail("no files to run pylint on! Explicitly set `pylint = False`")

        pylint_test(
            name = "pylint",
            srcs = depset(pylint_srcs).to_list(),
            deps = depset(direct = deps, transitive = [depset(pylint_deps)]),
            rcfile = rcfile,
            **kwargs
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
