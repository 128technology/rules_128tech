#!/bin/bash
# Copyright 2018 128 Technology, Inc.

exec env @ENV_VARS@ @EXECUTABLE@ @ARGS@ "${@}"
