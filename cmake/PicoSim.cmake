# Shared Verilator CMake helpers for picorv32 (cmake-system/ and cmake-conan/).
# Kit find + Windows PE rules match weiwan-gmail/rtl-learning-plan cmake/.
#
# - Locate the Verilator kit; on Windows always drive verilator_bin.exe PE
#   (withlimon: https://github.com/withlimon/verilator-windows). Never the
#   extensionless Perl `verilator` (Explorer/CMD Open-with trap).
# - include(CheckCXXCompilerFlag) before verilate().
# - On MSVC, strip GCC-only -fcoroutines* flags Verilator may inject.
# - Wire the existing repo-root TB (testbench.v / picorv32.v / testbench.cc).
#   No RTL copies. Firmware hex is still built by the original Makefile when
#   PICO_REBUILD_FIRMWARE=ON (Linux default). The Verilator cmake path itself
#   uses --make cmake/json, not GNU make. Windows MSVC defaults to prebuilt hex.

include_guard(GLOBAL)

set(PICO_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}")
get_filename_component(PICO_REPO_ROOT "${PICO_CMAKE_DIR}/.." ABSOLUTE)

# Firmware hex is a runtime input ($readmemh), not part of verilate().
# Linux: rebuild via the original Makefile. Windows MSVC: do not require GNU
# make at configure — use committed firmware/*.hex, or opt in with
# -DPICO_REBUILD_FIRMWARE=ON once MSYS2 make + RISC-V GCC + bash exist.
if(WIN32)
  set(_PICO_REBUILD_FIRMWARE_DEFAULT OFF)
else()
  set(_PICO_REBUILD_FIRMWARE_DEFAULT ON)
endif()
option(PICO_REBUILD_FIRMWARE
  "Rebuild firmware/*.hex via the repo Makefile (GNU make + RISC-V GCC + bash)"
  ${_PICO_REBUILD_FIRMWARE_DEFAULT})

# MSYS2 names a Perl script share/verilator/bin/verilator_bin.exe. withlimon
# and mingw64/bin ship a real PE (MZ). Only the PE may be executed on Windows.
function(pico_windows_file_is_pe filepath outvar)
  set(_ok FALSE)
  if(EXISTS "${filepath}")
    file(READ "${filepath}" _magic HEX LIMIT 2)
    string(TOUPPER "${_magic}" _magic)
    if(_magic STREQUAL "4D5A")
      set(_ok TRUE)
    endif()
  endif()
  set(${outvar} ${_ok} PARENT_SCOPE)
endfunction()

function(pico_find_windows_pe outvar)
  unset(PICO_VERILATOR_BIN CACHE)
  set(_cands "")
  # Known PE bindirs first. $VERILATOR_ROOT/bin on MSYS2 is the Perl wrapper.
  list(APPEND _cands
    "D:/verilator/bin/verilator_bin.exe"
    "C:/msys64/mingw64/bin/verilator_bin.exe")
  if(DEFINED ENV{VERILATOR_ROOT} AND NOT "$ENV{VERILATOR_ROOT}" STREQUAL "")
    list(APPEND _cands
      "$ENV{VERILATOR_ROOT}/bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../bin/verilator_bin.exe"
      "$ENV{VERILATOR_ROOT}/../../bin/verilator_bin.exe")
  endif()
  foreach(_c IN LISTS _cands)
    get_filename_component(_abs "${_c}" ABSOLUTE)
    pico_windows_file_is_pe("${_abs}" _ispe)
    if(_ispe)
      set(${outvar} "${_abs}" PARENT_SCOPE)
      return()
    endif()
  endforeach()
  find_program(_pico_path_pe NAMES verilator_bin.exe)
  if(_pico_path_pe)
    pico_windows_file_is_pe("${_pico_path_pe}" _ispe)
    if(_ispe)
      set(${outvar} "${_pico_path_pe}" PARENT_SCOPE)
      return()
    endif()
  endif()
  set(${outvar} "" PARENT_SCOPE)
endfunction()

function(pico_locate_verilator_kit)
  set(_root "")

  if(WIN32)
    pico_find_windows_pe(_pe)
    if(NOT _pe)
      message(FATAL_ERROR
        "Windows Verilator PE not found (verilator_bin.exe with MZ header).\n"
        "Install the withlimon build: https://github.com/withlimon/verilator-windows\n"
        "Extract to a short path (e.g. D:\\verilator), then:\n"
        "  VERILATOR_ROOT = D:\\verilator\n"
        "  PATH          += D:\\verilator\\bin\n"
        "Do NOT invoke the extensionless Perl `verilator` (Open-with trap).\n"
        "Do NOT invoke share/verilator/bin/verilator_bin.exe (Perl wrapper with a .exe suffix).")
    endif()
    set(PICO_VERILATOR_BIN "${_pe}")
  else()
    # Do not pre-set the result variable — find_program skips the search if it
    # is already defined (even as "").
    unset(PICO_VERILATOR_BIN CACHE)
    find_program(PICO_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin"
      /usr/bin
      /usr/local/bin)
    if(NOT PICO_VERILATOR_BIN)
      message(FATAL_ERROR
        "verilator_bin not found. Install Verilator 5.x (e.g. apt install verilator).")
    endif()
  endif()
  set(_pe "${PICO_VERILATOR_BIN}")

  get_filename_component(_bin "${_pe}" DIRECTORY)
  get_filename_component(_parent "${_bin}" DIRECTORY)
  foreach(_c
      "$ENV{VERILATOR_ROOT}"
      "${_parent}"
      "${_parent}/share/verilator"
      "/usr/share/verilator"
      "/usr/local/share/verilator"
      "D:/verilator"
      "C:/msys64/mingw64/share/verilator")
    if(_c AND EXISTS "${_c}/include/verilated.h")
      set(_root "${_c}")
      break()
    endif()
  endforeach()

  if(NOT _root)
    message(FATAL_ERROR
      "VERILATOR_ROOT kit not found (need include/verilated.h). PE was ${_pe}")
  endif()

  message(STATUS "PicoSim: VERILATOR_BIN=${_pe}")
  message(STATUS "PicoSim: VERILATOR_ROOT=${_root}")
  set(PICO_VERILATOR_BIN "${_pe}" PARENT_SCOPE)
  set(PICO_VERILATOR_ROOT "${_root}" PARENT_SCOPE)
endfunction()

function(pico_find_verilator)
  # Pre-seed VERILATOR_BIN so a Debian/Ubuntu verilator-config.cmake does not
  # FATAL (it searches only VERILATOR_ROOT/bin with NO_CMAKE_SYSTEM_PATH), and
  # so an MSYS2 kit config does not pick share/verilator/bin's Perl wrapper.
  if(WIN32)
    pico_find_windows_pe(_pe_seed)
    if(_pe_seed)
      set(PICO_VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "PICO_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_seed}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  else()
    find_program(PICO_VERILATOR_BIN NAMES verilator_bin HINTS
      "$ENV{VERILATOR_ROOT}/bin" /usr/bin /usr/local/bin)
    if(PICO_VERILATOR_BIN)
      set(VERILATOR_BIN "${PICO_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    endif()
  endif()

  # First find_package() triggers cmake-conan if the provider is registered.
  find_package(verilator QUIET)

  foreach(_pkg_var
      verilator_PACKAGE_FOLDER_RELEASE
      verilator_PACKAGE_FOLDER_RELWITHDEBINFO
      verilator_PACKAGE_FOLDER_DEBUG
      verilator_PACKAGE_FOLDER)
    if(DEFINED ${_pkg_var} AND EXISTS "${${_pkg_var}}/include/verilated.h")
      set(ENV{VERILATOR_ROOT} "${${_pkg_var}}")
      # Prefer the packaged PE (withlimon on Windows) over a stale PATH hit.
      unset(PICO_VERILATOR_BIN CACHE)
      message(STATUS "PicoSim: Conan package folder ${${_pkg_var}}")
      break()
    endif()
  endforeach()

  pico_locate_verilator_kit()
  set(VERILATOR_ROOT "${PICO_VERILATOR_ROOT}" CACHE PATH "VERILATOR_ROOT" FORCE)
  set(verilator_ROOT "${PICO_VERILATOR_ROOT}" CACHE PATH "verilator_ROOT" FORCE)
  set(VERILATOR_BIN "${PICO_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
  set(ENV{VERILATOR_ROOT} "${PICO_VERILATOR_ROOT}")

  if(NOT COMMAND verilate)
    if(EXISTS "${PICO_VERILATOR_ROOT}/verilator-config.cmake")
      include("${PICO_VERILATOR_ROOT}/verilator-config.cmake")
    else()
      message(STATUS
        "PicoSim: kit has no verilator-config.cmake (typical of withlimon); "
        "using bundled cmake/verilator-config.fallback.cmake")
      include("${PICO_CMAKE_DIR}/verilator-config.fallback.cmake")
    endif()
  endif()

  # Kit configs may find_program() VERILATOR_ROOT/bin (Perl wrapper on MSYS2).
  # Re-assert the PE after that include so verilate() drives verilator_bin.exe.
  if(WIN32)
    set(VERILATOR_BIN "${PICO_VERILATOR_BIN}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
    pico_windows_file_is_pe("${VERILATOR_BIN}" _bin_is_pe)
    if(NOT _bin_is_pe)
      pico_find_windows_pe(_pe_fix)
      if(NOT _pe_fix)
        message(FATAL_ERROR
          "VERILATOR_BIN is not a PE engine: ${VERILATOR_BIN}\n"
          "Do not use share/verilator/bin/verilator_bin.exe (Perl wrapper).")
      endif()
      set(PICO_VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "PICO_VERILATOR_BIN" FORCE)
      set(VERILATOR_BIN "${_pe_fix}" CACHE FILEPATH "VERILATOR_BIN" FORCE)
      message(STATUS "PicoSim: replaced non-PE VERILATOR_BIN with ${_pe_fix}")
    endif()
  endif()

  if(NOT COMMAND verilate)
    message(FATAL_ERROR "verilate() missing after Verilator package load")
  endif()
endfunction()

function(pico_strip_msvc_gcc_flags target)
  if(NOT MSVC)
    return()
  endif()
  foreach(_prop COMPILE_OPTIONS INTERFACE_COMPILE_OPTIONS)
    get_target_property(_opts ${target} ${_prop})
    if(_opts)
      list(FILTER _opts EXCLUDE REGEX "fcoroutines")
      set_property(TARGET ${target} PROPERTY ${_prop} "${_opts}")
    endif()
  endforeach()
endfunction()

function(pico_msvc_host_defs target)
  if(NOT MSVC)
    return()
  endif()
  # fopen in testbench.cc; NOMINMAX so Verilator min/max templates compile.
  target_compile_definitions(${target} PRIVATE _CRT_SECURE_NO_WARNINGS NOMINMAX)
endfunction()

# GNU make is optional for the Verilator cmake path. Search PATH, then well-known
# MSYS2 prefixes (PC2023 has make at C:\msys64\usr\bin\make.exe, not on PATH).
function(pico_find_gnu_make)
  if(PICO_GNU_MAKE AND EXISTS "${PICO_GNU_MAKE}")
    return()
  endif()
  if(PICO_GNU_MAKE AND NOT EXISTS "${PICO_GNU_MAKE}")
    unset(PICO_GNU_MAKE CACHE)
  endif()
  set(_hints "")
  if(WIN32)
    set(_roots "C:/msys64" "D:/msys64" "C:/tools/msys64")
    if(DEFINED ENV{MSYS2_ROOT} AND NOT "$ENV{MSYS2_ROOT}" STREQUAL "")
      list(INSERT _roots 0 "$ENV{MSYS2_ROOT}")
    endif()
    foreach(_r IN LISTS _roots)
      list(APPEND _hints
        "${_r}/usr/bin"
        "${_r}/mingw64/bin"
        "${_r}/ucrt64/bin"
        "${_r}/clang64/bin")
    endforeach()
  endif()
  find_program(PICO_GNU_MAKE NAMES gmake make mingw32-make HINTS ${_hints}
    DOC "GNU make for optional firmware/*.hex rebuild")
endfunction()

function(pico_add_firmware_hex name makefile_target hex_path)
  if(PICO_REBUILD_FIRMWARE)
    add_custom_target(${name}
      COMMAND "${PICO_GNU_MAKE}" ${makefile_target}
      WORKING_DIRECTORY "${PICO_REPO_ROOT}"
      BYPRODUCTS "${hex_path}"
      COMMENT "Build ${makefile_target} via existing Makefile"
      VERBATIM)
  else()
    add_custom_target(${name}
      COMMAND "${CMAKE_COMMAND}"
              "-DHEX_PATH=${hex_path}"
              -P "${PICO_CMAKE_DIR}/RequireFirmwareHex.cmake"
      WORKING_DIRECTORY "${PICO_REPO_ROOT}"
      COMMENT "Require prebuilt ${makefile_target} (no Makefile rebuild)"
      VERBATIM)
  endif()
endfunction()

function(pico_sim_setup)
  if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  endif()
  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  pico_find_verilator()
  include(CheckCXXCompilerFlag)

  pico_find_gnu_make()
  if(PICO_REBUILD_FIRMWARE)
    if(NOT PICO_GNU_MAKE)
      message(FATAL_ERROR
        "PICO_REBUILD_FIRMWARE=ON but GNU make was not found.\n"
        "The Verilator cmake path does not need make (--make cmake/json).\n"
        "Install make, pass -DPICO_GNU_MAKE=..., or reconfigure with "
        "-DPICO_REBUILD_FIRMWARE=OFF and use committed firmware/*.hex.\n"
        "Windows: CMake also searches C:\\msys64\\usr\\bin\\make.exe and "
        "mingw32-make under MSYS2 prefixes.")
    endif()
    message(STATUS "PicoSim: GNU make=${PICO_GNU_MAKE} (firmware rebuild ON)")
  else()
    if(PICO_GNU_MAKE)
      message(STATUS
        "PicoSim: GNU make=${PICO_GNU_MAKE} (firmware rebuild OFF; "
        "prebuilt firmware/*.hex)")
    else()
      message(STATUS
        "PicoSim: GNU make not found; Verilator cmake path does not need it. "
        "Using committed firmware/*.hex (rebuild with the Makefile if stale).")
    endif()
  endif()

  set(_tb "${PICO_REPO_ROOT}/testbench.cc")
  set(_v_tb "${PICO_REPO_ROOT}/testbench.v")
  set(_v_core "${PICO_REPO_ROOT}/picorv32.v")
  foreach(_f IN ITEMS _tb _v_tb _v_core)
    if(NOT EXISTS "${${_f}}")
      message(FATAL_ERROR "PicoSim: missing ${${_f}}")
    endif()
  endforeach()

  # Same Verilator contract as Makefile testbench_verilator:
  # --cc --top-module picorv32_wrapper --no-timing -Wno-lint -Wno-fatal --trace
  # -DCOMPRESSED_ISA (Makefile COMPRESSED_ISA=C). C++ driver is testbench.cc.
  add_executable(sim_picorv32
    "${_tb}"
    "${PICO_CMAKE_DIR}/sc_time_stamp.cpp")
  target_compile_features(sim_picorv32 PRIVATE cxx_std_17)
  pico_msvc_host_defs(sim_picorv32)

  include(CheckCXXCompilerFlag)
  verilate(sim_picorv32
    PREFIX Vpicorv32_wrapper
    TOP_MODULE picorv32_wrapper
    TRACE
    SOURCES "${_v_tb}" "${_v_core}"
    VERILATOR_ARGS
      --no-timing -Wno-lint -Wno-fatal -DCOMPRESSED_ISA
  )
  pico_strip_msvc_gcc_flags(sim_picorv32)

  set(_hello_hex "${PICO_REPO_ROOT}/firmware/hello.hex")
  set(_fw_hex "${PICO_REPO_ROOT}/firmware/firmware.hex")
  # Relative plusarg: picorv32_wrapper stores the path in reg [1023:0]
  # (128 bytes). Absolute Windows paths can overflow that.
  set(_hello_plus "firmware/hello.hex")
  set(_fw_plus "firmware/firmware.hex")
  pico_add_firmware_hex(firmware_hello firmware/hello.hex "${_hello_hex}")
  pico_add_firmware_hex(firmware_full firmware/firmware.hex "${_fw_hex}")

  # Default `sim` is the documented C hello demo (make test_verilator_hello).
  add_custom_target(sim
    DEPENDS sim_picorv32 firmware_hello
    COMMAND "$<TARGET_FILE:sim_picorv32>"
            "+firmware=${_hello_plus}"
    WORKING_DIRECTORY "${PICO_REPO_ROOT}"
    COMMENT "Verilator co-sim: C hello firmware (ALL TESTS PASSED.)"
    VERBATIM)

  add_custom_target(sim-firmware
    DEPENDS sim_picorv32 firmware_full
    COMMAND "$<TARGET_FILE:sim_picorv32>"
            "+firmware=${_fw_plus}"
    WORKING_DIRECTORY "${PICO_REPO_ROOT}"
    COMMENT "Verilator co-sim: full firmware.hex (ISA + C)"
    VERBATIM)

  add_test(NAME sim_hello
    COMMAND "$<TARGET_FILE:sim_picorv32>" "+firmware=${_hello_plus}"
    WORKING_DIRECTORY "${PICO_REPO_ROOT}")
  set_tests_properties(sim_hello PROPERTIES
    TIMEOUT 60
    PASS_REGULAR_EXPRESSION "ALL TESTS PASSED")

  add_test(NAME sim_firmware
    COMMAND "$<TARGET_FILE:sim_picorv32>" "+firmware=${_fw_plus}"
    WORKING_DIRECTORY "${PICO_REPO_ROOT}")
  set_tests_properties(sim_firmware PROPERTIES
    TIMEOUT 300
    PASS_REGULAR_EXPRESSION "ALL TESTS PASSED")

  # Hex is a run-time (not link-time) input. Build it with the default ALL
  # target so `cmake --build && ctest` does not race an empty firmware/.
  add_dependencies(sim_picorv32 firmware_hello firmware_full)

  message(STATUS "PicoSim: sim_picorv32  (testbench.cc + testbench.v + picorv32.v)")
  message(STATUS "PicoSim: sim           → firmware/hello.hex")
  message(STATUS "PicoSim: sim-firmware  → firmware/firmware.hex")
endfunction()
