#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

set -euo pipefail

package_name="libucx"

WHEELHOUSE="${PWD}/dist/"
RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"
RAPIDS_PY_WHEEL_NAME="${RAPIDS_PY_CUDA_SUFFIX}" rapids-download-wheels-from-s3 cpp "${WHEELHOUSE}"
python -m pip install "${package_name}-${RAPIDS_PY_CUDA_SUFFIX}" --find-links "${WHEELHOUSE}"
python -c "import libucx; libucx.load_library(); print('Loaded libucx libraries successfully!')"
