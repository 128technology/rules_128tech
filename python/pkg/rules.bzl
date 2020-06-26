"""Rules to package python applications."""

load("@rules_128tech//exec_wrapper:rules.bzl", "exec_wrapper")
load("@rules_128tech//python:env.bzl", "get_python_env")
load("@rules_128tech//python/par:rules.bzl", "par_binary")
load("@rules_pkg//:pkg.bzl", "pkg_tar")

def pkg_python_app(
        name,
        tar,
        entrypoint = None,
        bindir = None,
        libdir = None,
        env = None,
        exec_wrapper_kwargs = {},
        zip_safe = False,
        mode = "0755",
        tar_visibility = None,
        **kwargs):
    """
    Create and package a entire python application into a single tar.

    Args:
        name: (str) The name of the python binary application.

        tar: (str) The name of the tar containing all built artifacts.

        entrypoint: (str) The name of the entry point to execute the python application.
            Defaults to the `name` of the application

        bindir: (str) The directory where the binary entry point will be placed.

        libdir: (str) The directory where the par_binary will be placed. Note:  Two
            sub-folders will be used.
            - <libdir>/par/: The par_binary archive will be placed here.
            - <libdir>/unpar/: The par_binary archive will unpack here on first invocating.

        env (str_dict): Deprecated. Use exec_wrapper_kwargs instead

        exec_wrapper_kwargs: (str_dict) Specify custom args to override in the call
            to exec_wrapper. This will be merged with the default values.
            [default: {}]

        zip_safe: (bool) Whether the binary is zip safe. See par_binary for more info.

        mode: (str) The mode of the files in the tar.

        tar_visibility: (str_list) The visibility of the tar archive.

        **kwargs: pass anything to par_binary

    Creates:
        <name>: py_binary containing the python application.

        <name>.par: par_binary wrapping the py_binary into a stand-alone app.

        <name>_exec_wrapper: The entry point script.

        <tar>: pkg_tar containing the par_binary and entry point with the correct
            path structure.

    """
    entrypoint = entrypoint or name

    if env != None:
        fail("'env' arg is deprecated, use 'exec_wrapper_kwargs' with key 'env' instead")

    exec_wrapper_kwargs = dict(exec_wrapper_kwargs)
    exec_wrapper_kwargs.setdefault("name", "%s_exec_wrapper" % name)
    exec_wrapper_kwargs.setdefault("exe", "%s/par/%s.par" % (libdir, name))
    exec_wrapper_kwargs.setdefault("env", get_python_env())
    exec_wrapper(**exec_wrapper_kwargs)

    if zip_safe:
        extract_dir = None
    else:
        extract_dir = "%s/unpar/%s" % (libdir, name)

    par_binary(
        name = name,
        extract_dir = extract_dir,
        zip_safe = zip_safe,
        **kwargs
    )

    pkg_tar(
        name = tar,
        srcs = [
            ":%s_exec_wrapper" % name,
            ":%s.par" % name,
        ],
        mode = mode,
        strip_prefix = ".",
        remap_paths = {
            "/%s_exec_wrapper" % name: "%s/%s" % (bindir, entrypoint),
            "/%s.par" % name: "%s/par/%s.par" % (libdir, name),
        },
        visibility = tar_visibility,
    )
