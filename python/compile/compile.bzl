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
    py_runtime = py_toolchain.py3_runtime
    pip_compile = ctx.executable._pip3_compile
    pip_compile_files = ctx.files._pip3_compile

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
        "@@HEADER@@": ctx.attr.header,
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
        "header": attr.string(default = "# This file is generated code. DO NOT EDIT."),
        "_pip3_compile": attr.label(
            default = Label("//python/compile:compile.zip"),
            allow_single_file = True,
            cfg = "host",
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
