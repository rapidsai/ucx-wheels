#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

set -euo pipefail

package_name="ucx"
package_dir="python/libucx"
pyproject_file="${package_dir}/pyproject.toml"

source rapids-configure-sccache
source rapids-date-string

RAPIDS_PY_CUDA_SUFFIX="$(rapids-wheel-ctk-name-gen ${RAPIDS_CUDA_VERSION})"
PACKAGE_CUDA_SUFFIX="-${RAPIDS_PY_CUDA_SUFFIX}"
sed -i -E "s/^name = \"${package_name}(.*)?\"$/name = \"${package_name}${PACKAGE_CUDA_SUFFIX}\"/g" ${pyproject_file}

python -m pip wheel "${package_dir}"/ -w "${package_dir}"/dist -vvv --no-deps --disable-pip-version-check

# We must avoid bundling libcuda.so. What about libnvidia-ml.so? We had long
# discussions about this in the past, and at the time we settled on excluding
# it since we were going to be non-compliant without libcuda.so anyway.
python -m auditwheel repair -w ${package_dir}/final_dist --exclude "libcuda.so" ${package_dir}/dist/*
RAPIDS_PY_WHEEL_NAME="ucx_${RAPIDS_PY_CUDA_SUFFIX}" rapids-upload-wheels-to-s3 cpp ${package_dir}/final_dist
