# cmake-conan: Conan 2 + local Verilator recipe (withlimon on Windows,
# system kit on Linux). Thin dual-tree wrapper; shared helpers in ../cmake/.
# Pattern: https://github.com/weiwan-gmail/rtl-learning-plan
cmake_minimum_required(VERSION 3.24)
cmake_policy(SET CMP0074 NEW)
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()
include("${CMAKE_CURRENT_LIST_DIR}/../cmake/PreferUnixGcc.cmake")

# Export the in-tree recipe so find_package(verilator) can resolve it.
find_program(CONAN_CMD conan)
if(CONAN_CMD)
  execute_process(
    COMMAND "${CONAN_CMD}" export "${CMAKE_CURRENT_LIST_DIR}/recipes/verilator"
    RESULT_VARIABLE _pico_conan_export_rc
  )
  if(_pico_conan_export_rc)
    message(WARNING
      "conan export of cmake-conan/recipes/verilator failed (rc=${_pico_conan_export_rc})")
  endif()
else()
  message(WARNING "conan not on PATH; cmake-conan expects Conan 2 (PC2023: 2.34)")
endif()

# Inject cmake-conan provider at first project() so find_package(verilator)
# runs `conan install` (same flow as passing CMAKE_PROJECT_TOP_LEVEL_INCLUDES).
# Prefer the CMake-detected compiler (PreferUnixGcc → g++) over `conan profile detect`.
set(CONAN_HOST_PROFILE "auto-cmake" CACHE STRING "Conan host profile")
set(CONAN_BUILD_PROFILE "auto-cmake" CACHE STRING "Conan build profile")
# Local verilator recipe only. Skip remotes (conancenter has no Conan 2
# verilator; extra remotes may prompt for a password).
set(CONAN_INSTALL_ARGS "--build=missing;--no-remote" CACHE STRING
  "Extra arguments for cmake-conan provider conan install")
list(PREPEND CMAKE_PROJECT_TOP_LEVEL_INCLUDES
  "${CMAKE_CURRENT_LIST_DIR}/conan_provider.cmake")

project(picorv32_sim_conan LANGUAGES CXX)
enable_testing()
include("${CMAKE_CURRENT_LIST_DIR}/../cmake/PicoSim.cmake")
pico_sim_setup()
