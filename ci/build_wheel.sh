#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

set -euo pipefail

package_name="libucx"
package_dir="python/libucx"
pyproject_file="${package_dir}/pyproject.toml"

RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"
PACKAGE_CUDA_SUFFIX="-${RAPIDS_PY_CUDA_SUFFIX}"
sed -i -E "s/^name = \"${package_name}(.*)?\"$/name = \"${package_name}${PACKAGE_CUDA_SUFFIX}\"/g" ${pyproject_file}

python -m pip wheel "${package_dir}"/ -w "${package_dir}"/dist -vvv --no-deps --disable-pip-version-check

python -m auditwheel repair -w ${package_dir}/final_dist --exclude "libcuda.so.1" --exclude "libnvidia-ml.so.1" --exclude "libucm.so.0" --exclude "libuct.so.0" --exclude "libucs.so.0" --exclude "libucp.so.0" ${package_dir}/dist/*
RAPIDS_PY_WHEEL_NAME="${RAPIDS_PY_CUDA_SUFFIX}" rapids-upload-wheels-to-s3 cpp ${package_dir}/final_dist
