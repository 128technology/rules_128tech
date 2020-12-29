workspace(name = "rules_128tech")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# First party dependencies
load("//:deps.bzl", "rules_128tech_deps")

rules_128tech_deps()

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

http_archive(
    name = "com_github_ali5h_rules_pip",
    patch_args = ["-p1"],
    patches = [
        "//thirdparty/pip:export-all.patch",
        "//thirdparty/pip:sys-platform.patch",
    ],
    sha256 = "983eecdfac362d8e7eeb8761ef96e17a3f860aac002bb2bb529adfa39620ddc8",
    strip_prefix = "rules_pip-0559f4dfb1bfce200dc8db5d8f1c011d1eb1aaff",
    urls = ["https://github.com/ali5h/rules_pip/archive/0559f4dfb1bfce200dc8db5d8f1c011d1eb1aaff.tar.gz"],
)

load("//thirdparty/pip:repositories.bzl", "pip_repositories")

pip_repositories()

load("//thirdparty/pip:install.bzl", "pip_install")

pip_install()

register_toolchains(
    "//private/toolchains:linux_x86_64_python_toolchain",
    "//private/toolchains:osx_x86_64_python_toolchain",
)

http_archive(
    name = "io_bazel_skydoc",
    sha256 = "6d07d18c15abb0f6d393adbd6075cd661a2219faab56a9517741f0fc755f6f3c",
    strip_prefix = "stardoc-0.4.0",
    url = "https://github.com/bazelbuild/stardoc/archive/0.4.0.tar.gz",
)

load("@io_bazel_skydoc//:setup.bzl", "stardoc_repositories")

stardoc_repositories()
