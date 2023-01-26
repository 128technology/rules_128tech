# Managing pip Dependencies

## Overview

All external pip dependencies for the entire workspace are defined here.
There is only a single dependency set because the entire workspace uses the same
version of python.

## requirements.in

This file is intended to be manually edited by the developer whenever external
dependencies are added or removed. It follows the format of a [pip requirements
file](https://pip.pypa.io/en/stable/user_guide/#requirements-files).

For the most part, this file should only contain direct dependencies of Python
code in the workspace, rather than transitive dependencies, and it should simply
contain the name of the required package, rather than a version restriction.

## requirements-\<platform\>.txt

These files are automatically generated from the `requirements.in` file and
should never be manually edited. They also follow the pip requirements file
format, but contain all transitive dependencies as well as exact versions and
hash values for each dependency. There is one per supported platform because
the transitive dependency set may differ across platforms.

These files are used by Bazel to determine exactly which external dependencies
to fetch.

## Adding a new dependency

1. Add the distribution name of the pip dependency (i.e. the name you would pass
   to a `pip install` command) to the `requirements.in` file for the desired
   major Python version. **NOTE**: this file should be alpha-ordered.
1. Run `bazel run //thirdparty/pip/3:compile` on your Mac
1. Run `bazel run //thirdparty/pip/3:compile` on your Linux
   VM
1. Make sure both generated files are copied to the machine you use for source
   control (i.e. that's where you perform `git commit` and `git push` operations)
   1. If you use Mac for source control, copy the generated
      `requirements-linux.txt` from the Linux VM to your Mac.
   1. If you use Linux for source control, copy the generated
      `requirements-osx.txt` from the Mac to your Linux VM.
   1. If you use Windows, I'm not sure who let you in.
1. Commit all three files (`requirements.in`, `requirements-linux.txt`, and
   `requirements-osx.txt`) to source control

## Updating a single dependency

1. Run `bazel run //thirdparty/pip/3:compile -- -P <name>` on
   your Mac
1. Run `bazel run //thirdparty/pip/3:compile -- -P <name>` on
   your Linux VM
1. Follow steps 4-5 from "Adding a new dependency"

## Updating all dependencies

1. Run `bazel run //thirdparty/pip/3:compile -- -U` on your
   Mac
1. Run `bazel run //thirdparty/pip/3:compile -- -U` on your
   Linux VM
1. Follow steps 4-5 from "Adding a new dependency"

## Declaring dependencies in BUILD.bazel files

Python Bazel rules can declare dependencies on any package defined in a
`requirements.in` file using the label format `@pip3//<package-name>`.

`version` will be the major Python version for which the dependency was defined

`package-name` will be the distribution name in the requirements file, with all
letters lowercased and all hyphens replaced with underscores

### Example

`pip/3/requirements.in`:

```txt
python-dateutil
PyYAML
```

`BUILD.bazel`:

```py
py_library(
    name = "mylib",
    srcs = "mylib.py",
    deps = [
        "@pip3//python_dateutil",
        "@pip3//pyyaml",
    ]
)
```

## Debugging

### `no such package '@pip3>//<y>': BUILD file not found on package path`

Bazel provides little to no information while resolving/retrieving external
dependencies, so it can be difficult to triage issues that arise with missing or
broken pip dependencies.

For example, Bazel commonly prints error messages like the following:

```txt
ERROR: Analysis of target '//packaging/apps/blaster/saltlib/saltlib:arrow' failed; build aborted: no such package '@pip3//pyyaml': BUILD file not found on package path
INFO: Elapsed time: 18.842s
INFO: 0 processes.
FAILED: Build did NOT complete successfully (74 packages loaded, 717 targets configured)
    currently loading: @pip3//pytest_mock ... (4 packages)
```

This error does not occur until _after_ external dependencies have been fetched
and Bazel has proceeded to analyze the dependency tree. The only thing it
indicates is that the `@pip3//pyyaml` package was not properly fetched, but it
does not provide any useful context.

Try the following steps in order to resolve the issue:

#### Clean Bazel's external dependency cache

Running this command before any build or test commands will remove all of the
fetched external dependencies and force Bazel to start from scratch:

```sh
bazel clean --expunge
```

#### Check for downloaded pip dependencies

Bazel stores the fetched pip dependencies in the following directory:

```sh
$(bazel info output_base)/external/pip3/
```

Where:

If the directory does not contain any wheel files, this can be an indication
that the `create_pip_repository` tool never ran due to the Python interpreter
not being available. See
`Make sure the required Python interpreters are available` below.

If the directory contains wheel files, there was most likely an error running
the `create_pip_repository` tool. See
`Try manually creating the pip repository to check for errors` below.

For more information about the output directories created by Bazel, see
[the official documentation](https://docs.bazel.build/versions/master/output_directories.html).

#### Make sure the required Python interpreters are available

The correct Python interpreters must be available within the Bazel execution
environment. To verify this, execute the following:

```sh
cd $(bazel info output_base)
python3.<minor> --version
```

Where:

`<minor>` is the minor Python version that the repo currently uses for the
given major version (see `python/versions.bzl`)

If either of the version queries does not succeed, you must install that version
of Python and ensure that the interpreter is available on the user's `PATH`.

#### Try manually creating the pip repository to check for errors

Bazel unfortunately swallows output from the tools that it executes when
fetching external dependencies and does not provide any verbosity control.

In order to debug the tool that is used for fetching the pip dependencies,
execute the following commands:

```sh
python3.<minor> $(bazel info output_base)/external/com_128technology_rules_pip/tools/create_pip_repository.par /tmp/bazel-pip-repo thirdparty/pip/3/requirements-<platform>.txt
```

Where:

`<minor>` is the minor Python version that the repo currently uses for the given
major version (see `python/versions.bzl`)

`<platform>` is the name of the platform on which you are executing the command
(either `osx` or `linux`)

This will print any errors that are preventing Bazel from fetching the pip
dependencies.
