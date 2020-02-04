# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Wraps a binary to be run in the workspace root via bazel run.

For example, one might do something like

workspace_binary(
    name = "dep",
    cmd = "//vendor/github.com/golang/dep/cmd/dep",
)

which would allow running dep with bazel run.
"""

def _workspace_binary_script_impl(ctx):
    content = """#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ -n "${{BUILD_WORKSPACE_DIRECTORY:-}}" ]]; then
  # Running from inside bazel
  cd "${{BUILD_WORKSPACE_DIRECTORY}}"
else
  # Running from bazel-bin
  cd "$(git rev-parse --show-toplevel)"
fi
"bazel-${{PWD##*/}}/{cmd}" "$@"
""".format(
        cmd = ctx.file.cmd.path,
    )
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = content,
        is_executable = True,
    )
    runfiles = ctx.runfiles(
        files = [
            ctx.file.cmd,
        ],
    )
    return [DefaultInfo(runfiles = runfiles)]

_workspace_binary_script = rule(
    attrs = {
        "cmd": attr.label(
            mandatory = True,
            allow_single_file = True,
        ),
    },
    executable = True,
    implementation = _workspace_binary_script_impl,
)

def workspace_binary(name, cmd, args = None, visibility = None):
    script_name = name + "_script"
    _workspace_binary_script(
        name = script_name,
        cmd = cmd,
        tags = ["manual"],
    )
    native.sh_binary(
        name = name,
        srcs = [":" + script_name],
        args = args,
        visibility = visibility,
        tags = ["manual"],
    )
