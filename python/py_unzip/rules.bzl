"""Create an archive that can be expanded into a standalone, runnable python application."""

load("@rules_python//python:defs.bzl", "PyInfo", "py_binary")

def py_unzip(
        name,
        libdir,
        main = None,
        srcs = [],
        tags = [],
        visibility = None,
        testonly = False,
        **kwargs):
    """
    Create an archive that can be expanded into a standalone, runnable python application.

    Args:
        name: (str) The name of the py_binary.
        libdir: The directory in which to expand the specified files.
        main: (str) The main entry point for the py_binary.
        srcs: (str_list) A list of python source files.
        tags: (str_list) A list of tags to apply to the target.
        visibility: (str_list) The visibility of the target.
        testonly: (bool) If True, only testonly targets (such as tests) can depend on this target.
        **kwargs: Pass additional keyword arguments to the underlying py_binary.

    Outputs:
        "%{name}": A py_binary that can be `bazel run` if needed.
        "%{name}.tar: A tarfile that can be extracted into a runnable python application.

    """
    py_binary(
        # TODO: add 'main = _determine_main(main, srcs)' otherwise the main argument is
        # mandatory due to the underscore in the name.
        name = "_" + name,
        tags = tags,
        main = main,
        srcs = srcs,
        visibility = visibility,
        testonly = testonly,
        **kwargs
    )

    native.alias(
        name = name,
        actual = "_" + name,
        testonly = testonly,
        tags = tags,
        visibility = visibility,
    )

    _py_unzip(
        name = name + ".tar",
        src = "_" + name,
        main = main,
        srcs = srcs,
        tags = tags + ["py_unzip"],
        visibility = visibility,
        testonly = testonly,
        package_dir = _package_dir(libdir, name),
    )

def _py_unzip_impl(ctx):
    main_file = _generate_main(ctx)
    zip_file = _get_zip_file(ctx)

    ctx.actions.run(
        outputs = [ctx.outputs.executable],
        mnemonic = "ReZipper",
        inputs = [zip_file, main_file],
        executable = ctx.executable._rezipper,
        arguments = [
            "--src",
            zip_file.path,
            "--dst",
            ctx.outputs.executable.path,
            "--package-dir",
            _get_package_dir(ctx),
            "--main",
            main_file.path,
        ],
        progress_message = "Repacking %s into %s" % (zip_file.short_path, ctx.outputs.executable.short_path),
    )

    return [
        # TODO: This isn't actually execuable. This is needed so that the outputs can
        # be '%{name}' and '%{name}.tar'.
        DefaultInfo(executable = ctx.outputs.executable),
    ]

def _generate_main(ctx):
    py_runtime = ctx.toolchains["@bazel_tools//tools/python:toolchain_type"].py3_runtime

    main_file = ctx.actions.declare_file(ctx.label.name + ".__main__.py")

    ctx.actions.expand_template(
        template = ctx.file._main_template,
        output = main_file,
        substitutions = {
            "%imports%": ":".join(ctx.attr.src[PyInfo].imports.to_list()),
            "%main%": ctx.workspace_name + "/" + _determine_main(ctx).path,
            "%python_binary%": py_runtime.interpreter_path,
            "%shebang%": py_runtime.stub_shebang,
        },
        is_executable = True,
    )

    return main_file

def removesuffix(string, suffix):
    """https://www.python.org/dev/peps/pep-0616/"""

    # suffix='' should not call string[:-0].
    if suffix and string.endswith(suffix):
        return string[:-len(suffix)]
    return string[:]

def _determine_main(ctx):
    """https://github.com/bazelbuild/bazel/blob/1eda22fa4d8488e434a7bbe1c548b5ca7fb7b6e5/src/main/starlark/builtins_bzl/common/python/py_executable.bzl#L608"""

    # This doesn't need robust error-handling because the py_binary is instantiated
    # first and will fail first.
    if ctx.attr.main:
        proposed_main = ctx.attr.main.label.name
    else:
        proposed_main = removesuffix(ctx.label.name, ".tar") + ".py"

    main_files = [src for src in ctx.files.srcs if _path_endswith(src.short_path, proposed_main)]
    if len(main_files) != 1:
        fail("failed to determine main", attr = main_files)
    return main_files[0]

def _path_endswith(path, endswith):
    # Use slash to anchor each path to prevent e.g.
    # "ab/c.py".endswith("b/c.py") from incorrectly matching.
    return ("/" + path).endswith("/" + endswith)

def _get_zip_file(ctx):
    zip_file = ctx.attr.src[OutputGroupInfo].python_zip_file
    inputs = zip_file.to_list()
    if len(inputs) != 1:
        fail("expected only one .zip file", attr = inputs)
    return inputs[0]

def _get_package_dir(ctx):
    package_dir = ctx.attr.package_dir or ""
    if package_dir.startswith("/"):
        package_dir = package_dir[1:]
    return package_dir

_py_unzip = rule(
    implementation = _py_unzip_impl,
    attrs = {
        "main": attr.label(allow_files = True),
        "package_dir": attr.string(),
        "src": attr.label(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
        "_main_template": attr.label(
            default = "//python/py_unzip:__main__.py.tmpl",
            allow_single_file = True,
        ),
        "_rezipper": attr.label(
            default = "//python/py_unzip:rezipper",
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@bazel_tools//tools/python:toolchain_type"],
    executable = True,
)

def _package_dir(libdir, app_name):
    return "%s/unzip/%s" % (libdir.rstrip("/"), app_name.strip("/"))

def _exec_path(libdir, app_name):
    return "%s/__main__.py" % _package_dir(libdir, app_name)

unzip = struct(
    package_dir = _package_dir,
    exec_path = _exec_path,
    py_unzip = py_unzip,
)
