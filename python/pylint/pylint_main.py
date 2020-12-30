# pylint: skip_file

"""Entrypoint to running pylint_test."""

import os
import sys

import pylint

from rules_128tech import sharder


def main():
    sep = sys.argv.index("--")
    if sep == -1:
        os.exit("expected to find '--' on the command line")

    flags, files_to_lint = sys.argv[:sep], sys.argv[sep:]

    sys.argv[:] = flags + sharder.filter_items(files_to_lint)

    pylint.run_pylint()


if __name__ == "__main__":
    main()
