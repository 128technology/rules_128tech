"""Rules to package python applications."""

load("@rules_128tech//exec_wrapper:rules.bzl", "exec_wrapper")
load("@rules_128tech//python:env.bzl", "get_python_env")
load("@subpar//:subpar.bzl", "par_binary")
load("@rules_pkg//:pkg.bzl", "pkg_tar")
load("@rules_128tech//python/py_unzip:rules.bzl", "unzip")

def pkg_python_app(name, tar, bindir, libdir, use_py_unzip = False, **kwargs):
    """
    Create and package a entire python application into a single tar.

    Args:
        name: (str) The name of the python binary application.
        tar: (str) The name of the tar containing all built artifacts.
        bindir: (str) The directory where the entry point will be placed.
        libdir: (str) The directory where the binary will be placed.
        use_py_unzip: Switch between par_binary and py_unzip as the packaging strategy.
        **kwargs: pass anything to py_binary.

    Outputs:
        %{name}: py_binary containing the python application.

        %{name}.par: binary wrapping the py_binary into a stand-alone app. Iff
            use_py_unzip is False.

        %{name}_exec_wrapper: The entry point script. Iff use_exec_wrapper is True.

        %{tar}: pkg_tar containing the binary and entry point with the correct
            path structure.

    """
    if use_py_unzip:
        _pkg_py_unzip_app(
            name,
            tar = tar,
            bindir = bindir,
            libdir = libdir,
            **kwargs
        )
    else:
        _pkg_par_binary_app(
            name = name,
            tar = tar,
            bindir = bindir,
            libdir = libdir,
            **kwargs
        )

def _pkg_par_binary_app(
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
        entrypoint = entrypoint or name
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

def _pkg_py_unzip_app(
        name,
        tar,
        bindir,
        libdir,
        entrypoint = None,
        mode = "0755",
        env = None,
        visibility = None,
        **kwargs):
    if kwargs.pop("tar_visibility", None):
        fail("use 'visibility' not 'tar_visibility'")
    if kwargs.pop("zip_safe", None):
        fail("'zip_safe' must be false when using py_unzip")
    if kwargs.pop("use_exec_wrapper", None) == False:
        fail("use py_unzip directly instead of disabling 'use_exec_wrapper'")

    exec_wrapper_name = "%s_exec_wrapper" % name
    exec_wrapper(
        name = exec_wrapper_name,
        env = env or get_python_env(),
        exe = unzip.exec_path(libdir, name),
    )

    unzip.py_unzip(
        name = name,
        libdir = libdir,
        visibility = visibility,
        **kwargs
    )

    pkg_tar(
        name = tar,
        srcs = [exec_wrapper_name],
        deps = [name + ".tar"],
        mode = mode,
        strip_prefix = ".",
        remap_paths = {"/%s_exec_wrapper" % name: "%s/%s" % (bindir, entrypoint or name)},
        visibility = visibility,
    )
