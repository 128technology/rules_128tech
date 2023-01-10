"""
Thirdparty pip dependencies
"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_128tech//python:pip.bzl", "pip_aliases")
load("@com_github_ali5h_rules_pip//:defs.bzl", "pip_import")
load("//python:versions.bzl", "PYTHON3")

def pip_repositories():
    """
    Thirdparty pip dependencies
    """

    maybe(
        pip_import,
        name = "pip3_current",
        requirements_per_platform = {
            "//thirdparty/pip/3:requirements-linux.txt": "linux",
            "//thirdparty/pip/3:requirements-osx.txt": "osx",
        },
        python_interpreter_per_platform = {
            "/usr/bin/%s" % PYTHON3: "linux",
            "/opt/128technology/bazel/bin/%s" % PYTHON3: "osx",
        },
    )

    # This allows us to add deps using "@pip3//pytest" instead of using the requirement
    # macro.
    maybe(
        pip_aliases,
        name = "pip3",
        requirements = [
            "//thirdparty/pip/3:requirements.in",
        ],
        select = {
            "//conditions:default": "pip3_current",
        },
    )
