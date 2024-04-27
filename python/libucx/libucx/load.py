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


def load_library():
    # Dynamically load libucx.so. Prefer a system library if one is present to
    # avoid clobbering symbols that other packages might expect, but if no
    # other library is present use the one in the wheel.
    try:
        libucx_lib = ctypes.CDLL("libucx.so", ctypes.RTLD_GLOBAL)
    except OSError:
        libucx_lib = ctypes.CDLL(
            os.path.join(os.path.dirname(__file__), "lib", "libucx.so"),
            ctypes.RTLD_GLOBAL,
        )

    return libucx_lib
