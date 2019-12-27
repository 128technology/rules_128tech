# Python Toolchains

These rules define the Python interpreters that should be used to execute Python binaries within the context of Bazel. A toolchain is defined for each supported platform. See the [design document](https://github.com/bazelbuild/rules_python/blob/master/proposals/2019-02-12-design-for-a-python-toolchain.md) for more information.

## Linux

Install the python interpreter using your package manager of choice

## macOS

Run the following Bazel command to set up the environment:

```sh
bazel run //private/toolchains:setup_macos
```

It will prompt you to choose a `pyenv` environment to use for each major Python version and create symlinks from the expected toolchain paths under `/opt/128technology/bazel/bin/` to the selected interpreters.
