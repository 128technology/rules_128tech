"""
Thirdparty pip dependencies
"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@com_apt_itude_rules_pip//rules:repository.bzl", "pip_repository")
load("//python:versions.bzl", "PYTHON2", "PYTHON3")
load("//python:pip.bzl", "pip_aliases")

def pip_repositories():
    """
    Thirdparty pip dependencies
    """

    maybe(
        pip_repository,
        name = "pip2",
        python_interpreter = PYTHON2,
        requirements_per_platform = {
            "//thirdparty/pip/2:requirements-linux.txt": "linux",
            "//thirdparty/pip/2:requirements-osx.txt": "osx",
        },
    )

    maybe(
        pip_repository,
        name = "pip3",
        python_interpreter = PYTHON3,
        requirements_per_platform = {
            "//thirdparty/pip/3:requirements-linux.txt": "linux",
            "//thirdparty/pip/3:requirements-osx.txt": "osx",
        },
    )

    maybe(
        pip_aliases,
        name = "pip2and3",
        requirements = [
            "//thirdparty/pip/2:requirements.in",
            "//thirdparty/pip/3:requirements.in",
        ],
        select = {
            "@rules_python//python:PY2": "pip2",
            "@rules_python//python:PY3": "pip3",
        },
    )
