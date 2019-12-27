"""
Wrappers around genrule
"""

def copy(src, out, **kwargs):
    """
    Copy a single source file to the given destination

    Args:
        src: the label of the source to copy

        out: the path to which it should be copied

        **kwargs: all arguments that can be used with genrule
    """
    native.genrule(
        name = "%s-copy" % out,
        srcs = [src],
        outs = [out],
        cmd = "cp $< $@",
        **kwargs
    )
