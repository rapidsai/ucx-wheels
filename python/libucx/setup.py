from setuptools import setup
from setuptools.command.build_py import build_py as build_orig
import subprocess
from contextlib import contextmanager
import os
import tempfile
import glob


@contextmanager
def chdir(path):
    origin = os.getcwd()
    try:
        os.chdir(path)
        yield
    finally:
        os.chdir(origin)


class build_py(build_orig):
    def run(self):
        super().run()

        with open("VERSION") as f:
            version = f.read().strip()

        install_prefix = os.path.abspath(os.path.join(self.build_lib, "libucx"))

        with tempfile.TemporaryDirectory() as tmpdir:
            with chdir(tmpdir):
                subprocess.run(["git", "clone", "-b", f"v{version}", "https://github.com/openucx/ucx.git", "ucx"])
                with chdir("ucx"):
                    subprocess.run(["./autogen.sh"])
                    subprocess.run(["./contrib/configure-release",
                                    f"--prefix={install_prefix}",
                                    "--enable-mt",
                                    "--enable-cma",
                                    "--enable-numa",
                                    "--with-gnu-ld",
                                    "--with-sysroot",
                                    "--without-verbs",
                                    "--without-rdmacm",
                                    "--with-cuda=/usr/local/cuda"])
                    subprocess.run(["make", "-j"], env={**os.environ, "CPPFLAGS": "-I/usr/local/cuda/include"})
                    subprocess.run(["make", "install"])
                    # The config file built into UCX is not relocatable. We need to fix
                    # that so that we can package up UCX and distribute it in a wheel.
                    subprocess.run(
                        [
                            "sed",
                            "-i",
                            r"s/^set(prefix.*/set(prefix \"${CMAKE_CURRENT_LIST_DIR}\/..\/..\/..\")/",
                            f"{install_prefix}/lib/cmake/ucx/ucx-targets.cmake"
                        ]
                    )
                    # The UCX libraries must be able to find each other as dependencies.
                    for fn in glob.glob(f"{install_prefix}/lib/*.so*"):
                        subprocess.run(
                            [
                                "patchelf",
                                "--add-rpath",
                                "$ORIGIN",
                                "--force-rpath",
                                fn,
                            ]
                        )
                    # The transport layers must be able to find the main UCX. Note that
                    # this is not strictly necessary because the layers should only ever
                    # be dlopened by libuct.so (at which point all the dependencies of
                    # the layers are already loaded), but there's no real harm in making
                    # this linkage explicit here since the layout is fixed.
                    for fn in glob.glob(f"{install_prefix}/lib/ucx*.so*"):
                        subprocess.run(
                            [
                                "patchelf",
                                "--add-rpath",
                                "$ORIGIN/..",
                                "--force-rpath",
                                fn,
                            ]
                        )


setup(
    cmdclass={"build_py": build_py},
)
