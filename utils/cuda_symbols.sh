#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This file contains shared functions for handling CUDA symbols in UCX libraries.

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Get the UCX library directory
get_ucx_lib_dir() {
    UCX_PATH=$(python -c "import libucx; import os; print(os.path.dirname(libucx.__file__))")
    echo "${UCX_PATH}/lib/ucx"
}

# Get CUDA symbols from all UCX libraries
# Usage: get_cuda_symbols <output_file>
get_cuda_symbols() {
    local output_file="$1"
    local lib_dir
    local temp_file

    lib_dir=$(get_ucx_lib_dir)
    temp_file="${TEMP_DIR}/all_symbols.txt"

    # Initialize the output file
    touch "$temp_file"

    # Generate list of undefined symbols starting with 'cu' for each library
    for lib in libuct_cuda.so libucm_cuda.so libucx_perftest_cuda.so; do
        if [ -f "$lib_dir/$lib" ]; then
            nm -D "$lib_dir/$lib" | grep -E '^\s+U\s+cu' | awk '{print $NF}' >> "$temp_file"
        else
            echo "Warning: $lib not found in $lib_dir"
        fi
    done

    # Sort and deduplicate the combined symbols
    sort -u "$temp_file" > "$output_file"
}
