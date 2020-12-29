"""
Thirdparty pip dependencies
"""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@rules_128tech//python:pip.bzl", "pip_aliases")
load("@com_github_ali5h_rules_pip//:defs.bzl", "pip_import")
load("//python:versions.bzl", "PYTHON2", "PYTHON3")
load("@rules_128tech//platforms:platforms.bzl", "PLATFORMS")

_INTERPRETERS = {
    "2": PYTHON2,
    "3": PYTHON3,
}
_SYS_PLATFORMS = {
    ("2", "osx"): "darwin",
    ("3", "osx"): "darwin",
    ("2", "linux"): "linux2",
    ("3", "linux"): "linux",
}

def pip_repositories():
    """
    Thirdparty pip dependencies
    """

    # Create a pip_import rule for each combination of platform and python version.
    for python_version in ("2", "3"):
        for platform in PLATFORMS:
            maybe(
                pip_import,
                name = "pip%s_%s" % (python_version, platform),
                python_interpreter = _INTERPRETERS[python_version],
                # com_github_ali5h_rules_pip adds the python version into the repo name
                # so we don't need to do it here.
                repo_prefix = "pypi_%s" % platform,
                requirements = "//thirdparty/pip/%s:requirements-%s.txt" % (python_version, platform),
                sys_platform = _SYS_PLATFORMS[(python_version, platform)],
            )

    # "@pip3" is a platform-independent way to reference python3 packages.
    maybe(
        pip_aliases,
        name = "pip3",
        requirements = [
            "//thirdparty/pip/3:requirements.in",
        ],
        select = {
            "@rules_128tech//platforms:osx": "pip3_osx",
            "@rules_128tech//platforms:linux": "pip3_linux",
        },
    )

    # "@pip2" is a platform-independent way to reference python2 packages.
    maybe(
        pip_aliases,
        name = "pip2",
        requirements = [
            "//thirdparty/pip/2:requirements.in",
        ],
        select = {
            "@rules_128tech//platforms:osx": "pip2_osx",
            "@rules_128tech//platforms:linux": "pip2_linux",
        },
    )

    # "@pip2and3" is a platform-independent, python version-independent way to reference
    # packages.
    maybe(
        pip_aliases,
        name = "pip2and3",
        requirements = [
            "//thirdparty/pip/2:requirements.in",
            "//thirdparty/pip/3:requirements.in",
        ],
        select = {
            "@rules_128tech//platforms:PY2_linux": "pip2_linux",
            "@rules_128tech//platforms:PY3_linux": "pip3_linux",
            "@rules_128tech//platforms:PY2_osx": "pip2_osx",
            "@rules_128tech//platforms:PY3_osx": "pip3_osx",
        },
    )
