# CMake dual-tree (Verilator co-sim)

中文：`cmake-system/` 用本机 Verilator；`cmake-conan/` 用 Conan 2 包同一套 kit。共用 `cmake/` 查找逻辑。不改现有 `Makefile`，也不复制 RTL。Windows 用 [withlimon](https://github.com/withlimon/verilator-windows) 的 `verilator_bin.exe`（PE），后续再证明。

Pattern: [weiwan-gmail/rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan) `cmake-system/` + `cmake-conan/`. This repo keeps the original **Makefile** (`make test_verilator_hello`). CMake only wraps the same sources:

| Path | Role |
|------|------|
| `testbench.v` + `picorv32.v` | DUT / wrapper (relative paths, no copies) |
| `testbench.cc` | existing C++ clock/reset driver |
| `firmware/*.hex` | still built by the Makefile (RISC-V GCC) |
| `cmake/` | shared Verilator find (Linux `verilator_bin`, Windows withlimon PE), MSVC `-fcoroutines*` strip, `sc_time_stamp` stub |
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

## Windows (follow-up)

Not proven on this PR. Use [withlimon/verilator-windows](https://github.com/withlimon/verilator-windows) **`verilator_bin.exe`** (PE32+). Never the extensionless Perl `verilator`. Copy-paste: [`cmake-system/WINDOWS.md`](cmake-system/WINDOWS.md). Firmware hex still needs a RISC-V GCC (or a hex built on Linux).
