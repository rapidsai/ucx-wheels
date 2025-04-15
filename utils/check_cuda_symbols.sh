#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This script checks if any UCX CUDA libraries have new CUDA symbols
# that are not present in the reference file. If new symbols are detected,
# it will exit with a non-zero exit code. This is used to ensure no new CUDA
# symbols are inadvertently added to the libucx library that break backwards
# compatibility.

set -euo pipefail

# Source the shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cuda_symbols.sh"

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

# Generate current list of symbols
get_cuda_symbols "$TEMP_DIR/current_symbols.txt"

# Compare with reference list
new_symbols=()
while IFS= read -r symbol; do
    if ! grep -q "^$symbol$" "$REFERENCE_FILE"; then
        new_symbols+=("$symbol")
    fi
done < "$TEMP_DIR/current_symbols.txt"

if [ ${#new_symbols[@]} -ne 0 ]; then
    echo "Error: New CUDA symbols detected!"
    echo "The following symbols are not present in the reference file:"
    printf '* %s\n' "${new_symbols[@]}"
    exit 1
fi

echo "No new CUDA symbols detected"
