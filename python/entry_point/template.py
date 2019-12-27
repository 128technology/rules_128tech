import runpy


def main():
    # if the module name is too long black will complain
    # fmt: off
    runpy.run_module("@@MODULE@@", run_name="__main__", alter_sys=True)
    # fmt: on


if __name__ == "__main__":
    main()
