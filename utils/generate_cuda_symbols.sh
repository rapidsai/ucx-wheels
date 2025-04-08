#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This script generates a list of CUDA symbols from both libuct_cuda.so and libucm_cuda.so libraries.
# It uses the nm command to extract the undefined symbols starting with 'cu'
# and saves them to a file. This file is then used to ensure no new CUDA symbols
# are inadvertently added to the libucx library that break backwards
# compatibility.

set -euo pipefail

# Check if output file path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <output_file>"
    echo "  output_file: Path where the list of CUDA symbols will be saved"
    exit 1
fi

OUTPUT_FILE="$1"

# Find the location of the UCX libraries
LIB_DIR=$(python -c "import libucx; import os; print(os.path.dirname(libucx.__file__))")/lib/ucx

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Generate list of undefined symbols starting with 'cu' for each library
for lib in libuct_cuda.so libucm_cuda.so libucx_perftest_cuda.so; do
    if [ -f "$LIB_DIR/$lib" ]; then
        nm -D "$LIB_DIR/$lib" | grep -E '^\s+U\s+cu' | awk '{print $NF}' >> "$TEMP_DIR/all_symbols.txt"
    else
        echo "Warning: $lib not found in $LIB_DIR"
    fi
done

# Sort and deduplicate the combined symbols
sort -u "$TEMP_DIR/all_symbols.txt" > "$OUTPUT_FILE"

echo "Generated combined list of CUDA symbols in $OUTPUT_FILE"
