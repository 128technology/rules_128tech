"""
Simple wrapper around generating a template from a macro or BUILD file
"""

def _impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = ctx.outputs.out,
        substitutions = ctx.attr.substitutions,
    )

template = rule(
    implementation = _impl,
    doc = "Simple wrapper around generating a template from a macro or BUILD file",
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "out": attr.output(mandatory = True),
        "substitutions": attr.string_dict(),
    },
)
