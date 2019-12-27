import runpy
import sys


def main():
    runpy.run_path(sys.argv[1], run_name="__main__")


if __name__ == "__main__":
    main()
