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
# libraries being loaded first, but does not express this via a DT_NEEDED entry.
UCX_LIBRARIES = [
    "libucp.so",
    "libuct.so",
    "libucs.so",
    "libucs_signal.so",
    "libucm.so",
]

def load_library():
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
