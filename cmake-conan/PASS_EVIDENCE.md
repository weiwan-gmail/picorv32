# cmake-conan PASS evidence (Linux Cursor VM)

Recorded **2026-11-02** on this Cloud Agent Linux VM (`cursor`, Ubuntu, x86_64). Same helpers as cmake-system (`cmake/PicoSim.cmake`). Original **Makefile was not edited**.

| Tool | Version |
|------|---------|
| CMake | 3.28.3 |
| g++ | 13.3.0 (`PreferUnixGcc`; `conan profile detect` guessed clang 18, provider used **auto-cmake → gcc 13**) |
| Verilator | local recipe `verilator/5.052` **packaged the system 5.020 kit** (did not rebuild from source) |
| Conan | **2.34.0** (`pip install --user conan`) |
| RISC-V GCC | `riscv64-unknown-elf-gcc` 13.2.0 |

Windows (Conan 2.34 + withlimon `verilator_bin.exe` + MSVC) is **code-ready** — [`../cmake-system/WINDOWS.md`](../cmake-system/WINDOWS.md). Same no-make / copy-hex rules as cmake-system. PC2023 `.\build_sim.ps1` re-proof is a worker follow-up.

## Configure

```bash
export PATH="$HOME/.local/bin:$PATH"
conan profile detect --force
cmake -S cmake-conan -B build-conan -DCMAKE_BUILD_TYPE=Release
```

```
======== Installing packages ========
-------- Installing package verilator/5.052 ...
Calling package()
package(): Packaged 1 '.cmake' file: verilator-config.cmake
...
Install finished successfully
-- PicoSim: Conan package folder /home/ubuntu/.conan2/p/b/veril.../p
-- PicoSim: VERILATOR_BIN=.../p/bin/verilator_bin
-- PicoSim: VERILATOR_ROOT=.../p
-- PicoSim: GNU make=/usr/bin/gmake (firmware rebuild ON)
-- Executing Verilator...
-- Configuring done (2.5s)
```

`conan install` used `--no-remote` and in-tree `recipes/verilator` (`tool_requires("verilator/5.052")`).

## sim / ctest

```bash
cmake --build build-conan --target sim
ctest --test-dir build-conan --output-on-failure
```

`--target sim`:

```
hello world
DONE
TRAP after 35823 clock cycles
ALL TESTS PASSED.
verilator_exit=0 tests_passed=1 cycles=35845
[100%] Built target sim
```

`ctest`:

```
    Start 1: sim_hello
1/2 Test #1: sim_hello ........................   Passed    0.01 sec
    Start 2: sim_firmware
2/2 Test #2: sim_firmware .....................   Passed    0.11 sec

100% tests passed, 0 tests failed out of 2
```
