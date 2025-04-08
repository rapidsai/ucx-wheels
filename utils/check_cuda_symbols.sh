#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This script checks if both libuct_cuda.so and libucm_cuda.so libraries have any new CUDA symbols
# that are not present in the reference file. If new symbols are detected,
# it will exit with a non-zero exit code. This is used to ensure no new CUDA
# symbols are inadvertently added to the libucx library that break backwards
# compatibility.

set -euo pipefail

# Check if reference file path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <reference_file>"
    echo "  reference_file: Path to the reference list of CUDA symbols"
    exit 1
fi

REFERENCE_FILE="$1"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Find the location of the UCX libraries
LIB_DIR=$(python -c "import libucx; import os; print(os.path.dirname(libucx.__file__))")/lib/ucx

# Generate current list of undefined symbols starting with 'cu' for each library
for lib in libuct_cuda.so libucm_cuda.so libucx_perftest_cuda.so; do
    if [ -f "$LIB_DIR/$lib" ]; then
        nm -D "$LIB_DIR/$lib" | grep -E '^\s+U\s+cu' | awk '{print $NF}' >> "$TEMP_DIR/current_symbols.txt"
    else
        echo "Warning: $lib not found in $LIB_DIR"
    fi
done

# Sort and deduplicate the combined symbols
sort -u "$TEMP_DIR/current_symbols.txt" > "$TEMP_DIR/current_symbols_sorted.txt"

# Compare with reference list
if ! diff -u "$REFERENCE_FILE" "$TEMP_DIR/current_symbols_sorted.txt" > "$TEMP_DIR/symbol_diff.txt"; then
    echo "Error: New CUDA symbols detected!"
    echo "Diff of changes:"
    cat "$TEMP_DIR/symbol_diff.txt"
    exit 1
fi

echo "No new CUDA symbols detected"
