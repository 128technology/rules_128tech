workspace(name = "rules_128tech")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# TODO buildifier is required because of an exposed dependency in rules_pip.
# https://github.com/apt-itude/rules_pip/issues/44

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "9fb16af4d4836c8222142e54c9efa0bb5fc562ffc893ce2abeac3e25daead144",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/0.19.0/rules_go-0.19.0.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.19.0/rules_go-0.19.0.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

go_register_toolchains()

http_archive(
    name = "com_google_protobuf",
    sha256 = "64104b8d7b623e804f981b52378267148cca42af4b77fe70ddfc27857dc5bae0",
    strip_prefix = "protobuf-master",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/master.zip"],
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

http_archive(
    name = "com_github_bazelbuild_buildtools",
    sha256 = "deadb35ae3877aa118ba20531afb2e2e4e8aaac5d3df5d5b51cbb3f0f2e0581e",
    strip_prefix = "buildtools-master",
    url = "https://github.com/bazelbuild/buildtools/archive/master.zip",
)

load("@com_github_bazelbuild_buildtools//buildifier:deps.bzl", "buildifier_dependencies")

buildifier_dependencies()

# First party dependencies
load("//:deps.bzl", "rules_128tech_deps")

rules_128tech_deps()

load("@rules_python//python:repositories.bzl", "py_repositories")

py_repositories()

load("//thirdparty/pip:repositories.bzl", "pip_repositories")

pip_repositories()

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
