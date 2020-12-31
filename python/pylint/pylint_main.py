# pylint: skip_file

"""Entrypoint to running pylint_test."""

import os
import sys

import pylint

from rules_128tech import sharder


SOURCES = """
@SOURCES@
""".strip().splitlines()


def main():
    sys.argv += sharder.filter_items(SOURCES)

    pylint.run_pylint()


if __name__ == "__main__":
    main()
