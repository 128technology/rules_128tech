#!/bin/bash

# Generate documentation for this repo.

set -e

echo "building documentation..."
bazel build --config=docs //docs

echo "expanding docs into repo..."
tar -xvf bazel-bin/docs/docs.tar

echo "success"
