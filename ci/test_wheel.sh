#!/bin/bash
# Copyright (c) 2024-2025, NVIDIA CORPORATION.

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

package_name="libucx"

RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"
WHEELHOUSE=$(RAPIDS_PY_WHEEL_NAME="ucx_${RAPIDS_PY_CUDA_SUFFIX}" rapids-download-wheels-from-github cpp)
python -m pip install "${WHEELHOUSE}/${package_name}_${RAPIDS_PY_CUDA_SUFFIX}"*.whl

# Test basic library loading
python -c "import libucx; libucx.load_library(); print('Loaded libucx libraries successfully!')"

if [[ "${RAPIDS_CUDA_VERSION}" =~ ^11\..* ]]; then
    REFERENCE_FILE="${SCRIPT_DIR}/symbols_cuda11.txt"
elif [[ "${RAPIDS_CUDA_VERSION}" =~ ^12\..* ]]; then
    REFERENCE_FILE="${SCRIPT_DIR}/symbols_cuda12.txt"
else
    echo "Error: Unsupported CUDA version ${RAPIDS_CUDA_VERSION}"
    exit 1
fi

rapids-logger "Test CUDA symbol checker"
bash "${SCRIPT_DIR}/../utils/test_check_cuda_symbols.sh" "$REFERENCE_FILE"

rapids-logger "Checking CUDA symbols against reference list"
bash "${SCRIPT_DIR}/../utils/check_cuda_symbols.sh" "$REFERENCE_FILE"
