"""
Generates a BASH script to use as wrapper around another executable
"""

def _exec_wrapper_impl(ctx):
    args = " ".join(ctx.attr.static_args)

    env_vars = " ".join(["%s=%s" % pair for pair in ctx.attr.env.items()])

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.executable,
        substitutions = {
            "@ARGS@": args,
            "@ENV_VARS@": env_vars,
            "@EXECUTABLE@": ctx.attr.exe,
        },
        is_executable = True,
    )

exec_wrapper = rule(
    implementation = _exec_wrapper_impl,
    doc = """
Generates a BASH script to use as wrapper around another executable

This allows specific environment variables to be set or arguments to be passed
""",
    attrs = {
        "env": attr.string_dict(
            doc = "environment variables to set during execution",
        ),
        "exe": attr.string(
            mandatory = True,
            doc = "a path to an executable",
        ),
        "static_args": attr.string_list(
            doc = "arguments that should always be passed to the executable",
        ),
        "_template": attr.label(
            default = "//exec_wrapper:template.sh",
            allow_single_file = True,
        ),
    },
    executable = True,
)
