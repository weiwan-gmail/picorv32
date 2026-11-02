from conan import ConanFile
from conan.tools.cmake import CMakeDeps, CMakeToolchain, cmake_layout


class PicoRv32SimConan(ConanFile):
    name = "picorv32-sim"
    version = "0.1"
    package_type = "application"
    settings = "os", "compiler", "build_type", "arch"

    def layout(self):
        cmake_layout(self)

    def build_requirements(self):
        # Local recipe: cmake-conan/recipes/verilator (withlimon on Windows).
        self.tool_requires("verilator/5.052")

    def generate(self):
        # CMakeConfigDeps is the newer generator; CMakeDeps is enough here.
        deps = CMakeDeps(self)
        # tool_requires are not in the host graph; publish them for find_package().
        deps.build_context_activated = ["verilator"]
        deps.build_context_build_modules = ["verilator"]
        deps.generate()
        tc = CMakeToolchain(self)
        tc.generate()
