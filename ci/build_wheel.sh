#!/bin/bash
# Copyright (c) 2024-2025, NVIDIA CORPORATION.

set -euo pipefail

package_dir="python/libucx"

source rapids-configure-sccache
source rapids-date-string

python -m pip wheel "${package_dir}"/ -w "${package_dir}"/dist -vvv --no-deps --disable-pip-version-check

python -m auditwheel repair -w ${package_dir}/final_dist --exclude "libcuda.so.1" --exclude "libnvidia-ml.so.1" --exclude "libucm.so.0" --exclude "libuct.so.0" --exclude "libucs.so.0" --exclude "libucp.so.0" ${package_dir}/dist/*
