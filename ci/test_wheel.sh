#!/bin/bash
# Copyright (c) 2024-2025, NVIDIA CORPORATION.

set -euo pipefail

package_name="libucx"

WHEELHOUSE="${PWD}/dist/"
RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"
RAPIDS_PY_WHEEL_NAME="ucx_${RAPIDS_PY_CUDA_SUFFIX}" rapids-download-wheels-from-s3 cpp "${WHEELHOUSE}"
python -m pip install "${WHEELHOUSE}/${package_name}_${RAPIDS_PY_CUDA_SUFFIX}"*.whl

# Test basic library loading
python -c "import libucx; libucx.load_library(); print('Loaded libucx libraries successfully!')"

# Check CUDA symbols against reference list
echo "Checking CUDA symbols against reference list..."
if [ "${RAPIDS_CUDA_VERSION}" = "11" ]; then
    REFERENCE_FILE="ci/symbols_cuda11.txt"
elif [ "${RAPIDS_CUDA_VERSION}" = "12" ]; then
    REFERENCE_FILE="ci/symbols_cuda12.txt"
else
    echo "Error: Unsupported CUDA version ${RAPIDS_CUDA_VERSION}"
    exit 1
fi

bash ci/check_cuda_symbols.sh "$REFERENCE_FILE"
