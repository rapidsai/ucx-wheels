#!/bin/bash

# SPDX-FileCopyrightText: Copyright (c) 2025, NVIDIA CORPORATION & AFFILIATES.
# SPDX-License-Identifier: BSD-3-Clause

# This script tests the check_cuda_symbols.sh script by:
# 1. Testing with a complete reference file (should pass)
# 2. Testing with a modified reference file missing some symbols (should fail)
# 3. Verifying the diff output shows the expected missing symbols

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Check if reference file path is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <reference_file>"
    echo "  reference_file: Path to the reference list of CUDA symbols (e.g., ci/symbols_cuda11.txt)"
    exit 1
fi

REFERENCE_FILE="$1"

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Test 1: Check with complete reference file
echo "Test 1: Checking with complete reference file (should pass)..."
if ! bash "${SCRIPT_DIR}/check_cuda_symbols.sh" "$REFERENCE_FILE"; then
    echo "Error: Test 1 FAILED - check should have passed with complete reference file"
    exit 1
fi
echo "Test 1 PASSED"

# Test 2: Create a modified reference file missing some symbols
echo -e "\nTest 2: Checking with modified reference file (should fail)..."
# Remove a few symbols from the reference file
grep -v -E 'cuEventCreate|cuStreamCreate' "$REFERENCE_FILE" > "$TEMP_DIR/modified_reference.txt"

# Run the check and capture the output
if bash "${SCRIPT_DIR}/check_cuda_symbols.sh" "$TEMP_DIR/modified_reference.txt" 2>&1 | tee "$TEMP_DIR/check_output.txt"; then
    echo "Error: Test 2 FAILED - check should have failed with modified reference file"
    exit 1
fi
echo "Test 2 PASSED"

# Test 3: Verify the diff output shows the expected missing symbols
echo -e "\nTest 3: Verifying diff output..."
if ! grep -q "cuEventCreate" "$TEMP_DIR/check_output.txt" || ! grep -q "cuStreamCreate" "$TEMP_DIR/check_output.txt"; then
    echo "Error: Test 3 FAILED - diff output should show missing symbols"
    exit 1
fi
echo "Test 3 PASSED"

echo -e "\nAll tests passed successfully!"
