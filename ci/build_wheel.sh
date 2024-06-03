#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

set -euo pipefail

package_dir="python/libucx"

source rapids-configure-sccache
source rapids-date-string

RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"

python -m pip wheel "${package_dir}"/ -w "${package_dir}"/dist -vvv --no-deps --disable-pip-version-check

python -m auditwheel repair -w ${package_dir}/final_dist --exclude "libcuda.so.1" --exclude "libnvidia-ml.so.1" --exclude "libucm.so.0" --exclude "libuct.so.0" --exclude "libucs.so.0" --exclude "libucp.so.0" ${package_dir}/dist/*
RAPIDS_PY_WHEEL_NAME="ucx_${RAPIDS_PY_CUDA_SUFFIX}" rapids-upload-wheels-to-s3 cpp ${package_dir}/final_dist
