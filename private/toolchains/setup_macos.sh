#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
    echo "usage: setup_macos.sh <PY2_MINOR_VERSION> <PY3_MINOR_VERSION>"
    exit 1
fi

PY2_MINOR_VERSION="$1"
PY3_MINOR_VERSION="$2"

if [ ! -x "$(command -v pyenv)" ]; then
    echo "pyenv command not found"
    exit 2
fi

PYENV_VERSIONS_ROOT="$(pyenv root)/versions"

function set_up_toolchain() {
    local MAJOR_VERSION=$1
    local MINOR_VERSION=$2
    local MAJOR_MINOR="$MAJOR_VERSION.$MINOR_VERSION"
    local LABEL="Python$MAJOR_MINOR"

    local SELECTED_ENV=""
    local INSTALLED_ENVS=$(pyenv versions --bare --skip-aliases | grep "^\s*$MAJOR_MINOR")

    if [ -z "$INSTALLED_ENVS" ]; then
        local AVAILABLE_ENVS=$(pyenv install --list | grep "^\s*$MAJOR_MINOR")

        if [ -z "$AVAILABLE_ENVS" ]; then
            echo "No available environments found for $LABEL."
            exit 2
        fi

        PS3="No installed environment found for $LABEL. Select one to install: "
        SELECTED_ENV=$(prompt_for_selection "$AVAILABLE_ENVS")
        pyenv install "$SELECTED_ENV"
    else
        PS3="Select environment for $LABEL: "
        SELECTED_ENV=$(prompt_for_selection "$INSTALLED_ENVS")
    fi

    create_toolchain_symlink "$MAJOR_MINOR" "$SELECTED_ENV"
    echo ""
}

function prompt_for_selection() {
    local OPTIONS=$1
    select SELECTION in $OPTIONS; do
        if [ -z $SELECTION ]; then
            >&2 echo "Invalid selection"
        else
            echo $SELECTION
            break
        fi
    done
}

function create_toolchain_symlink () {
    local MAJOR_MINOR=$1
    local ENV_NAME=$2
    local OPT_BIN_DIR="/opt/128technology/bazel/bin"
    local SYMLINK_PATH="$OPT_BIN_DIR/python$MAJOR_MINOR"
    local BIN_PATH="$PYENV_VERSIONS_ROOT/$ENV_NAME/bin/python"

    sudo mkdir -p $OPT_BIN_DIR
    sudo ln -sfv $BIN_PATH $SYMLINK_PATH
}

function yellow() {
    echo -e "\033[33m$1\033[0m"
}

function on_exit {
    if [ $? -ne 0 ]; then
        yellow "WARNING:"
        yellow "if your install failed with 'zlib not available' then you should run"
        echo "sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /"
        yellow "as explained in https://github.com/pyenv/pyenv/issues/1219"
    fi
}
trap "on_exit" EXIT

set_up_toolchain 2 $PY2_MINOR_VERSION
set_up_toolchain 3 $PY3_MINOR_VERSION
