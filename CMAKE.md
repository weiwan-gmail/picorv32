# CMake dual-tree (Verilator co-sim)

中文：`cmake-system/` 用本机 Verilator；`cmake-conan/` 用 Conan 2 包同一套 kit。共用 `cmake/` 查找逻辑。不改现有 `Makefile`，也不复制 RTL。Windows 用 [withlimon](https://github.com/withlimon/verilator-windows) 的 `verilator_bin.exe`（PE）+ MSVC；GNU make 不是 Verilator cmake 路径的硬依赖。

Pattern: [weiwan-gmail/rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) `cmake-system/` + `cmake-conan/`. This repo keeps the original **Makefile** (`make test_verilator_hello`). CMake only wraps the same sources:

| Path | Role |
|------|------|
| `testbench.v` + `picorv32.v` | DUT / wrapper (relative paths, no copies) |
| `testbench.cc` | existing C++ clock/reset driver |
| `firmware/*.hex` | Linux: Makefile rebuild (default). Windows MSVC: copy from Linux, or `-DPICO_REBUILD_FIRMWARE=ON` |
| `cmake/` | shared Verilator find (Linux `verilator_bin`, Windows withlimon PE), MSVC `-fcoroutines*` strip, `sc_time_stamp`, optional GNU make |
| `cmake-system/` | system Verilator, no Conan |
| `cmake-conan/` | Conan 2 + local `recipes/verilator` (packages the system kit on Linux; withlimon on Windows) |

## Linux

```bash
# cmake-system (no Conan)
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim          # C hello → ALL TESTS PASSED.
ctest --test-dir build-system --output-on-failure  # sim_hello + sim_firmware

# cmake-conan (Conan 2; recipe wraps the same kit, does not rebuild Verilator)
export PATH="$HOME/.local/bin:$PATH"   # if pip --user
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

`sim` is the documented hello demo (`+firmware=firmware/hello.hex`). `sim-firmware` / ctest `sim_firmware` is the full upstream hex. Evidence: [`cmake-system/PASS_EVIDENCE.md`](cmake-system/PASS_EVIDENCE.md), [`cmake-conan/PASS_EVIDENCE.md`](cmake-conan/PASS_EVIDENCE.md).

Make is unchanged:

```bash
make test_verilator_hello
```

## Windows (MSVC / Visual Studio generator)

CMake configure does **not** require GNU make. Verilator is driven as `verilator_bin.exe` (withlimon PE; on PC2023 `C:\msys64\mingw64\bin\verilator_bin.exe`). Host C++ is MSVC (`#if defined(_MSC_VER)` in `testbench.cc`). Copy `firmware/*.hex` from Linux (or opt in to Makefile rebuild). Copy-paste: [`cmake-system/WINDOWS.md`](cmake-system/WINDOWS.md).

PC2023 re-proof of `.\build_sim.ps1` is a worker follow-up; Linux gcc sim/ctest is in the PASS_EVIDENCE files.
