# Copyright (c) 2024, NVIDIA CORPORATION.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

import ctypes
import os


# IMPORTANT: The load order here matters! libucm.so depends on symbols in the other
# libraries being loaded first, but does not express this via a DT_NEEDED entry. The
# others can all be loaded in any order since they do state their dependencies and they
# all have $ORIGIN RPATHs to find each other.
UCX_LIBRARIES = [
    "libucp.so",
    "libuct.so",
    "libucs.so",
    "libucs_signal.so",
    "libucm.so",
]

def load_library():
    # First validate if libcuda.so and libnvidia-ml.so are present. These cannot be
    # bundled, so we want to provide the user with a reasonable error if they are not
    # available rather than a loader error on import.
    try:
        ctypes.CDLL("libcuda.so.1", ctypes.RTLD_GLOBAL)
    except OSError:
        raise RuntimeError("The CUDA driver library libcuda.so.1 was not found "
                      "on your system. This library cannot be provided by the libucx "
                      "wheel and must be installed separately.")

    try:
        ctypes.CDLL("libnvidia-ml.so.1", ctypes.RTLD_GLOBAL)
    except OSError:
        raise RuntimeError("The library libnvidia-ml.so.1 was not found on your "
                      "system. This library cannot be provided by the libucx wheel and "
                      "must be installed separately.")

    # Dynamically load libucx.so. Prefer a system library if one is present to
    # avoid clobbering symbols that other packages might expect, but if no
    # other library is present use the one in the wheel.
    libraries = []
    for lib in UCX_LIBRARIES:
        try:
            libucx_lib = ctypes.CDLL(lib, ctypes.RTLD_GLOBAL)
        except OSError:
            libucx_lib = ctypes.CDLL(
                os.path.join(os.path.dirname(__file__), "lib", lib),
                ctypes.RTLD_GLOBAL,
            )
        libraries.append(libucx_lib)

    return libraries
