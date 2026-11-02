# cmake-system: system Verilator, no Conan.
# Thin dual-tree wrapper; shared helpers live in ../cmake/.
# Pattern: https://github.com/weiwan-gmail/rtl-learning-plan
cmake_minimum_required(VERSION 3.24)
cmake_policy(SET CMP0074 NEW)
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()
include("${CMAKE_CURRENT_LIST_DIR}/../cmake/PreferUnixGcc.cmake")
project(picorv32_sim_system LANGUAGES CXX)
enable_testing()
include("${CMAKE_CURRENT_LIST_DIR}/../cmake/PicoSim.cmake")
pico_sim_setup()
