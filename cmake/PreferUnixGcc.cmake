# Prefer g++/gcc on Unix when the user has not already selected a compiler.
# Include this file BEFORE the first project() call.
#
# Same role as PreferUnixGcc.cmake in weiwan-gmail/rtl-learning-plan.

if(UNIX)
  if(NOT CMAKE_CXX_COMPILER AND NOT DEFINED ENV{CXX})
    find_program(_PICO_GXX NAMES g++ g++-14 g++-13 g++-12)
    if(_PICO_GXX)
      set(CMAKE_CXX_COMPILER "${_PICO_GXX}")
      message(STATUS "PreferUnixGcc: CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}")
    endif()
  endif()
  if(NOT CMAKE_C_COMPILER AND NOT DEFINED ENV{CC})
    find_program(_PICO_GCC NAMES gcc gcc-14 gcc-13 gcc-12)
    if(_PICO_GCC)
      set(CMAKE_C_COMPILER "${_PICO_GCC}")
      message(STATUS "PreferUnixGcc: CMAKE_C_COMPILER=${CMAKE_C_COMPILER}")
    endif()
  endif()
endif()
