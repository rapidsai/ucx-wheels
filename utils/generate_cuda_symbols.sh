#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This script generates a list of CUDA symbols from the libuct_cuda.so library.
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

# Find the location of libuct_cuda.so
LIB_PATH=$(python -c "import libucx; import os; print(os.path.dirname(libucx.__file__))")/lib/ucx/libuct_cuda.so

# Generate list of undefined symbols starting with 'cu'
nm -D "$LIB_PATH" | grep -E '^\s+U\s+cu' | awk '{print $NF}' | sort > "$OUTPUT_FILE"

echo "Generated list of CUDA symbols in $OUTPUT_FILE"
