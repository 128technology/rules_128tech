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
        use_exec_wrapper = True,
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

        env: (str_dict) Specify custom environment variables that should be set.
            [default get_python_env()]

        use_exec_wrapper: (bool) Whether or not to create an exec_wrapper to run the app
            [default: True]

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

    if use_exec_wrapper:
        exec_wrapper(
            name = "%s_exec_wrapper" % name,
            env = env or get_python_env(),
            exe = "%s/par/%s.par" % (libdir, name),
        )

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

    srcs = [":%s.par" % name]
    remap_paths = {"/%s.par" % name: "%s/par/%s.par" % (libdir, name)}

    if use_exec_wrapper:
        srcs.append(":%s_exec_wrapper" % name)
        remap_paths["/%s_exec_wrapper" % name] = "%s/%s" % (bindir, entrypoint)

    pkg_tar(
        name = tar,
        srcs = srcs,
        mode = mode,
        strip_prefix = ".",
        remap_paths = remap_paths,
        visibility = tar_visibility,
    )
