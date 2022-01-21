# pylint: skip-file

from __future__ import absolute_import

import os
import shutil
import sys

import pytest


def main():
    old = sys.argv

    sys.argv[:] = sys.argv[:1] + _junit_args(old) + _fail_fast_flag(old) + sys.argv[1:]
    exit_code = pytest.main()

    save_coverage_report()

    # TODO when upgrading to pytest >= 5.0.0 use `pytest.ExitCode`
    # http://doc.pytest.org/en/latest/reference.html#pytest-exitcode

    # Suppress exit code 5, which means no tests were collected, in case all
    # tests need to be skipped due to the platform or other support limitations
    # https://docs.pytest.org/en/latest/usage.html#possible-exit-codes
    if exit_code != 5:
        sys.exit(exit_code)


def _junit_args(argv):
    if _has_arg(argv, "--junit-xml"):
        return []

    try:
        path = os.environ["XML_OUTPUT_FILE"]
    except KeyError:
        return []
    return ["--junit-xml", path]


def _has_arg(argv, name):
    return any(arg.startswith(name + "=") or arg == name for arg in argv)


def _fail_fast_flag(argv):
    if _has_flags(argv, "-x", "--exitfirst"):
        return []

    try:
        # If `--test_runner_fail_fast` is passed to bazel then this envionment variable
        # will be set. As noted here, https://github.com/bazelbuild/bazel/issues/11667,
        # this is not currently documented anywhere.
        fail_fast = os.environ["TESTBRIDGE_TEST_RUNNER_FAIL_FAST"]
    except KeyError:
        return []

    if not fail_fast or fail_fast == "0":
        return []

    return ["--exitfirst"]


def _has_flags(argv, *names):
    return any(arg in names for arg in argv)


# TODO: instead of hacking our own coverage tools we should use `bazel coverage` and
# save this to the corresponding location.
def save_coverage_report():
    """
    Save the coverage report generated by coverage.py run as part of pytest-cov.
    """
    src = ".coverage"
    if not os.path.exists(src):
        return

    try:
        # See the following two links for more about interacting with `TEST_UNDECLARED_OUTPUTS_DIR`.
        # https://stackoverflow.com/questions/47871993/bazel-writable-archivable-path-for-test-runtime
        # https://docs.bazel.build/versions/master/test-encyclopedia.html#test-interaction-with-the-filesystem
        dest = os.environ["TEST_UNDECLARED_OUTPUTS_DIR"]
    except KeyError:
        return
    else:
        dest = os.path.join(dest, ".coverage")
        shutil.move(src, dest)


if __name__ == "__main__":
    main()
