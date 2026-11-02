# Build-time check used when PICO_REBUILD_FIRMWARE=OFF (Windows MSVC default).
# Invoked as: cmake -DHEX_PATH=<abs> -P cmake/RequireFirmwareHex.cmake
#
# The Verilator cmake path does not need GNU make. Firmware hex is only a
# $readmemh runtime input.

if(NOT HEX_PATH)
  message(FATAL_ERROR "RequireFirmwareHex: HEX_PATH is not set")
endif()

if(NOT EXISTS "${HEX_PATH}")
  message(FATAL_ERROR
    "Firmware hex not found: ${HEX_PATH}\n"
    "cmake-system / cmake-conan do not need GNU make to run Verilator "
    "(--make cmake/json).\n"
    "Committed prebuilts live at firmware/hello.hex and firmware/firmware.hex.\n"
    "Restore them (`git checkout -- firmware/hello.hex firmware/firmware.hex`) "
    "or rebuild on Linux with `make firmware/hello.hex firmware/firmware.hex`.\n"
    "To rebuild hex here, install RISC-V GCC (and on Windows: MSYS2 make + bash) "
    "then reconfigure with -DPICO_REBUILD_FIRMWARE=ON.")
endif()

message(STATUS "PicoSim: using prebuilt ${HEX_PATH}")
