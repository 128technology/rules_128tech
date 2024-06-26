"""
External dependencies of rules_128tech
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_128tech_deps():
    """
    External dependencies of rules_128tech
    """

    # Skylib
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "7ac0fa88c0c4ad6f5b9ffb5e09ef81e235492c873659e6bb99efb89d11246bcb",
        strip_prefix = "bazel-skylib-1.0.3",
        type = "tar.gz",
        url = "https://github.com/bazelbuild/bazel-skylib/archive/1.0.3.tar.gz",
    )

    # Subpar

    maybe(
        http_archive,
        name = "subpar",
        sha256 = "b80297a1b8d38027a86836dbadc22f55dc3ecad56728175381aa6330705ac10f",
        strip_prefix = "subpar-2.0.0",
        type = "tar.gz",
        url = "https://github.com/google/subpar/archive/2.0.0.tar.gz",
    )

    # Packaging
    maybe(
        http_archive,
        name = "rules_pkg",
        sha256 = "d250924a2ecc5176808fc4c25d5cf5e9e79e6346d79d5ab1c493e289e722d1d0",
        urls = ["https://github.com/bazelbuild/rules_pkg/releases/download/0.10.1/rules_pkg-0.10.1.tar.gz"],
    )

    # These are transitive dependencies of rules_pkg that we shouldn't need to declare
    maybe(
        http_archive,
        name = "abseil_py",
        sha256 = "3d0f39e0920379ff1393de04b573bca3484d82a5f8b939e9e83b20b6106c9bbe",
        strip_prefix = "abseil-py-pypi-v0.7.1",
        urls = ["https://github.com/abseil/abseil-py/archive/pypi-v0.7.1.tar.gz"],
    )

    maybe(
        http_archive,
        name = "six_archive",
        build_file = "@abseil_py//third_party:six.BUILD",
        sha256 = "105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a",
        strip_prefix = "six-1.10.0",
        urls = ["https://mirror.bazel.build/pypi.python.org/packages/source/s/six/six-1.10.0.tar.gz"],
    )

    # Python/pip
    maybe(
        http_archive,
        name = "rules_python",
        sha256 = "43c007823228f88d6afe1580d00f349564c97e103309a234fa20a5a10a9ff85b",
        strip_prefix = "rules_python-54d1cb35cd54318d59bf38e52df3e628c07d4bbc",
        type = "tar.gz",
        url = "https://github.com/bazelbuild/rules_python/archive/54d1cb35cd54318d59bf38e52df3e628c07d4bbc.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_python",
        url = "https://github.com/bazelbuild/rules_python/releases/download/0.0.1/rules_python-0.0.1.tar.gz",
        sha256 = "aa96a691d3a8177f3215b14b0edc9641787abaaa30363a080165d06ab65e1161",
    )
