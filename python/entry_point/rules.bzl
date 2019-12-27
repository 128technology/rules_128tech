"""
Create a main file to enter a python environment
"""

def _py_entry_point_impl(ctx):
    substitutions = {
        "@@MODULE@@": ctx.attr.module,
    }

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.main,
        substitutions = substitutions,
    )

py_entry_point = rule(
    implementation = _py_entry_point_impl,
    attrs = {
        "module": attr.string(mandatory = True),
        "_template": attr.label(
            default = "//python/entry_point:template.py",
            allow_single_file = True,
        ),
    },
    outputs = {
        "main": "%{name}.py",
    },
)
