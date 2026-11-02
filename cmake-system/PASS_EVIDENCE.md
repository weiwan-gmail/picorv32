# cmake-system PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64). Dual-tree pattern from [rtl-learning-plan](https://github.com/weiwan-gmail/rtl-learning-plan). Original **Makefile was not edited**.

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`) |
| Verilator | 5.020 (Debian 5.020-1), `verilator_bin` at `/bin/verilator_bin`, kit `/usr/share/verilator` |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |
| Conan | not used in this tree |

Windows MSVC (withlimon `verilator_bin.exe`, Visual Studio generator): configure + Verilator already OK on PC2023. `firmware/hello.hex` and `firmware/firmware.hex` are **committed prebuilts** so `--target sim` works with `PICO_REBUILD_FIRMWARE=OFF` (no copy step). [`WINDOWS.md`](WINDOWS.md).

## Make still green

```bash
make test_verilator_hello
# hello world / DONE / ALL TESTS PASSED. / verilator_exit=0 / cycles=35845
```

## cmake-system (default: rebuild hex via Makefile)

```bash
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --target sim
ctest --test-dir build-system --output-on-failure
```

Configure:

```
-- PreferUnixGcc: CMAKE_CXX_COMPILER=/usr/bin/g++
-- PicoSim: VERILATOR_BIN=/bin/verilator_bin
-- PicoSim: VERILATOR_ROOT=/usr/share/verilator
-- PicoSim: GNU make=/usr/bin/gmake (firmware rebuild ON)
-- Executing Verilator...
-- PicoSim: sim_picorv32  (testbench.cc + testbench.v + picorv32.v)
-- Configuring done (1.6s)
```

`--target sim` (existing `testbench.cc` + `firmware/hello.hex` via Makefile):

```
hello world
DONE
TRAP after 35823 clock cycles
ALL TESTS PASSED.
verilator_exit=0 tests_passed=1 cycles=35845
[100%] Built target sim
```

`ctest` (hello + full firmware hex, same binary):

```
    Start 1: sim_hello
1/2 Test #1: sim_hello ........................   Passed    0.01 sec
    Start 2: sim_firmware
2/2 Test #2: sim_firmware .....................   Passed    0.10 sec

100% tests passed, 0 tests failed out of 2
```

`sim_firmware` stdout includes ISA `..OK` lines, sieve primes, mul/div OK, CPI, then `ALL TESTS PASSED.` / `verilator_exit=0` / `cycles=477300`.

## Prebuilt-hex path (Windows MSVC default)

Committed `firmware/*.hex`; configure without Makefile rebuild (same as WIN32 default):

```bash
cmake -S cmake-system -B build-system-nomake -DCMAKE_BUILD_TYPE=Release -DPICO_REBUILD_FIRMWARE=OFF
cmake --build build-system-nomake --target sim
ctest --test-dir build-system-nomake --output-on-failure
```

```
-- PicoSim: GNU make=/usr/bin/gmake (firmware rebuild OFF; prebuilt firmware/*.hex)
```

`--target sim` and `ctest` both PASS (`sim_hello` + `sim_firmware`, same `ALL TESTS PASSED.` / cycles as above).
