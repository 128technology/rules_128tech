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
    main = main if main else name + ".py"
    py_name = "_" + name

    py_binary(
        name = py_name,
        tags = tags,
        main = main,
        srcs = srcs,
        visibility = visibility,
        testonly = testonly,
        **kwargs
    )

    _py_unzip(
        name = name,
        src = py_name,
        main = main,
        srcs = srcs,
        tags = tags + ["py_unzip"],
        visibility = visibility,
        testonly = testonly,
        package_dir = _package_dir(libdir, name),
    )

def _py_binary_shim(ctx):
    actual = ctx.files.src[1]
    executable = ctx.actions.declare_file(ctx.attr.name + ".py_binary_shim.sh")

    ctx.actions.expand_template(
        template = ctx.file._py_binary_shim_template,
        output = executable,
        substitutions = {
            "%workspace%": ctx.workspace_name,
            "%executable%": actual.short_path,
        },
        is_executable = True,
    )

    return DefaultInfo(
        executable = executable,
        files = depset([actual]),
        runfiles = ctx.runfiles(
            files = [actual],
        ).merge(
            ctx.attr.src[DefaultInfo].default_runfiles,
        ),
    )

def _py_unzip_impl(ctx):
    main_file = _generate_main(ctx)
    zip_file = _get_zip_file(ctx)

    tar = ctx.outputs.tar
    ctx.actions.run(
        outputs = [tar],
        mnemonic = "ReZipper",
        inputs = [zip_file, main_file],
        executable = ctx.executable._rezipper,
        arguments = [
            "--src",
            zip_file.path,
            "--dst",
            tar.path,
            "--package-dir",
            _get_package_dir(ctx),
            "--main",
            main_file.path,
        ],
        progress_message = "Repacking %s into %s" % (
            zip_file.short_path,
            tar.short_path,
        ),
    )

    default_info = _py_binary_shim(ctx)

    return [
        default_info,
    ]

def _py_runtime(ctx):
    return ctx.toolchains["@bazel_tools//tools/python:toolchain_type"].py3_runtime

def _generate_main(ctx):
    py_runtime = _py_runtime(ctx)
    main_file = ctx.actions.declare_file(ctx.label.name + ".__main__.py")

    ctx.actions.expand_template(
        template = ctx.file._main_template,
        output = main_file,
        substitutions = {
            "%imports%": ":".join(ctx.attr.src[PyInfo].imports.to_list()),
            "%main%": ctx.workspace_name + "/" + ctx.file.main.path,
            "%python_binary%": py_runtime.interpreter_path,
            "%shebang%": py_runtime.stub_shebang,
        },
    )

    return main_file

def removesuffix(string, suffix):
    """https://www.python.org/dev/peps/pep-0616/"""

    # suffix='' should not call string[:-0].
    if suffix and string.endswith(suffix):
        return string[:-len(suffix)]
    return string[:]

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
        "main": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "package_dir": attr.string(),
        "src": attr.label(
            mandatory = True,
            providers = [PyInfo],
        ),
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "_main_template": attr.label(
            default = "//python/py_unzip:__main__.py.tmpl",
            allow_single_file = True,
        ),
        "_py_binary_shim_template": attr.label(
            default = "//python/py_unzip:py_binary_shim.sh.tmpl",
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
    outputs = {
        "tar": "%{name}.tar",
    },
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
