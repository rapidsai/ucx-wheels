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

# IMPORTANT: The load order here matters! libucm.so depends on symbols in libucs.so, but
# it does not express this via a DT_NEEDED entry, presumably because libucs.so also has
# a dependency on libucm.so and the libraries are attempting to avoid a circular
# dependency. Moreover, it seems like if libucs.so is not loaded before libuct.so and
# libucp.so something is set up incorrectly, perhaps with the atexit handlers, because
# on library close there is a double free issue. Therefore, libucs.so must be loaded
# first. The other libraries may then be loaded in any order. The libraries themselves
# all have $ORIGIN RPATHs to find each other.
UCX_LIBRARIES = [
    "libucs.so",
    "libucs_signal.so",
    "libucm.so",
    "libuct.so",
    "libucp.so",
]


# Loading with RTLD_LOCAL adds the library itself to the loader's
# loaded library cache without loading any symbols into the global
# namespace. This allows libraries that express a dependency on
# a library to be loaded later and successfully satisfy that dependency
# without polluting the global symbol table with symbols from
# that library that could conflict with symbols from other DSOs.
PREFERRED_LOAD_FLAG = ctypes.RTLD_LOCAL


def _load_system_installation(soname: str):
    """Try to dlopen() the library indicated by ``soname``
    Raises ``OSError`` if library cannot be loaded.
    """
    return ctypes.CDLL(soname, PREFERRED_LOAD_FLAG)


def _load_wheel_installation(soname: str):
    """Try to dlopen() the library indicated by ``soname``
    Returns ``None`` if the library cannot be loaded.
    """
    if os.path.isfile(lib := os.path.join(os.path.dirname(__file__), "lib", soname)):
        return ctypes.CDLL(lib, PREFERRED_LOAD_FLAG)
    return None


def load_library():
    """Dynamically load UCX libraries"""
    prefer_system_installation = (
        os.getenv("RAPIDS_LIBUCX_PREFER_SYSTEM_LIBRARY", "false").lower() != "false"
    )

    libraries = []
    for lib in UCX_LIBRARIES:
        if prefer_system_installation:
            # Prefer a system library if one is present to
            # avoid clobbering symbols that other packages might expect, but if no
            # other library is present use the one in the wheel.
            try:
                libucx_lib = _load_system_installation(lib)
            except OSError:
                libucx_lib = _load_wheel_installation(lib)
        else:
            # Prefer the libraries bundled in this package. If they aren't found
            # (which might be the case in builds where the library was prebuilt
            # before packaging the wheel), look for a system installation.
            libucx_lib = _load_wheel_installation(lib)

        libraries.append(libucx_lib)

    return libraries
