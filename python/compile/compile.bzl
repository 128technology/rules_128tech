load("@bazel_skylib//lib:paths.bzl", "paths")

_PY_TOOLCHAIN_TYPE = "@bazel_tools//tools/python:toolchain_type"

def _get_path_relative_to_workspace(path, ctx):
    if paths.is_absolute(path):
        return paths.relativize(path, "/")
    else:
        return paths.join(ctx.label.package, path)

def _compile_pip_requirements_impl(ctx):
    out_file = ctx.actions.declare_file(ctx.label.name + ".sh")

    requirements_txt_path = _get_path_relative_to_workspace(
        ctx.attr.requirements_txt,
        ctx,
    )

    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN_TYPE]
    if ctx.attr.python_version == "PY3":
        py_runtime = py_toolchain.py3_runtime
        pip_compile = ctx.executable._pip3_compile
        pip_compile_files = ctx.files._pip3_compile
    else:
        py_runtime = py_toolchain.py2_runtime
        pip_compile = ctx.executable._pip2_compile
        pip_compile_files = ctx.files._pip2_compile

    if py_runtime.interpreter != None:
        # NOTE: we don't use an in-built interpreter so this might not be exactly correct.
        python_interpreter = py_runtime.interpreter.path
        py_runtime_files = py_runtime.files
    else:
        python_interpreter = py_runtime.interpreter_path
        py_runtime_files = []

    substitutions = {
        "@@REQUIREMENTS_IN_PATH@@": ctx.file.requirements_in.short_path,
        "@@REQUIREMENTS_TXT_PATH@@": requirements_txt_path,
        "@@PYTHON_INTERPRETER_PATH@@": python_interpreter,
        "@@PIP_COMPILE_BINARY@@": pip_compile.short_path,
        "@@CUSTOM_COMPILE_COMMAND@@": ctx.attr.custom_compile_command or "bazel run %s" % ctx.label,
        "@@QUIET_ARG@@": "--quiet" if not ctx.attr.verbose else "--verbose",
    }

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out_file,
        substitutions = substitutions,
        is_executable = True,
    )

    return [DefaultInfo(
        files = depset([out_file]),
        runfiles = ctx.runfiles(
            files = (
                ctx.files.requirements_in +
                ctx.files.data +
                pip_compile_files +
                py_runtime_files
            ),
        ),
        executable = out_file,
    )]

compile_pip_requirements = rule(
    implementation = _compile_pip_requirements_impl,
    attrs = {
        "requirements_in": attr.label(
            allow_single_file = [".in"],
            mandatory = True,
        ),
        "data": attr.label_list(allow_files = True),
        "requirements_txt": attr.string(default = "requirements.txt"),
        "python_version": attr.string(default = "PY3", values = ("PY2", "PY3")),
        "custom_compile_command": attr.string(),
        "verbose": attr.bool(default = False),
        "_pip2_compile": attr.label(
            default = Label("//python/compile:compile2.zip"),
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "_pip3_compile": attr.label(
            default = Label("//python/compile:compile.zip"),
            allow_single_file = True,
            cfg = "exec",
            executable = True,
        ),
        "_template": attr.label(
            default = Label("//python/compile:compile_pip_requirements_wrapper_template.sh"),
            allow_single_file = True,
        ),
    },
    toolchains = [_PY_TOOLCHAIN_TYPE],
    executable = True,
)
