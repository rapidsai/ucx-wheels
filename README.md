# UCX wheel building

This repository hosts code for building wheels of [UCX](https://github.com/openucx/ucx/).

## Purpose 
RAPIDS publishes multiple libraries that rely on UCX, including [ucxx](https://github.com/rapidsai/ucxx/) and [ucx-py](https://github.com/rapidsai/ucx-py).
One of the ways that RAPIDS vendors these libraries is in the form of [pip wheels](https://packaging.python.org/en/latest/specifications/binary-distribution-format/).
For portability, wheels should be as self-contained as possible as per the [manylinux standard](https://peps.python.org/pep-0513/).
However, the cost of this is (sometimes extreme) bloat as wheels must bundle all their dependencies.
Moreover, to avoid bundled dynamic libraries conflicting with local copies of shared libraries, wheels must mangle library names using tools like [auditwheel](https://github.com/pypa/auditwheel).
This practice is particularly problematic for libraries like UCX that rely heavily on `dlopen` to load libraries at runtime instead of link time, making static analysis of a binary to determine its dependency tree far more difficult.
To avoid this problem, in this repo we build the UCX libraries directly and vendor them in a wheel without mangling, but in a way that supports dynamic loading of the library at runtime to avoid clashing with system versions of the library.
While this approach can still be problematic if other libraries loaded on the system do use a system copy of UCX, it is a relatively more robust solution than most of the alternatives.

# How UCX Wheels Are Built

UCX wheels in this repository are built by using a custom build command for setuptools to trigger the build of the UCX library.
The library is then bundled and installed directly into the output directories.
