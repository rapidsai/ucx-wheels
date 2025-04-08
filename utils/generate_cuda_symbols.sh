#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This script generates a list of CUDA symbols from all UCX CUDA libraries.
# It uses the nm command to extract the undefined symbols starting with 'cu'
# and saves them to a file. This file is then used to ensure no new CUDA symbols
# are inadvertently added to the libucx library that break backwards
# compatibility.

set -euo pipefail

# Source the shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cuda_symbols.sh"

# Check if output file path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <output_file>"
    echo "  output_file: Path where the list of CUDA symbols will be saved"
    exit 1
fi

OUTPUT_FILE="$1"

# Generate the combined list of CUDA symbols
get_cuda_symbols "$OUTPUT_FILE"

echo "Generated combined list of CUDA symbols in $OUTPUT_FILE"
