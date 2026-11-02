# Windows CMake (follow-up — copy-paste)

Linux `cmake-system` / `cmake-conan` are proven in `PASS_EVIDENCE.md`. This file is only for Wei’s Windows worker. The original **Makefile is unchanged**.

## Machine notes

| Item | Value |
|------|--------|
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** |
| Engine | **`verilator_bin.exe`** (PE32+). Never the extensionless Perl `verilator` (Explorer/CMD “Open with…” trap). |
| Conan | **2.34** (`cmake-conan` tree only) |
| Firmware | hex still comes from `make firmware/hello.hex` (RISC-V GCC on PATH, or copy hex from Linux) |

## withlimon layout

Extract to a **short path without spaces** (example `D:\verilator`):

```
D:\verilator\
  bin\verilator_bin.exe     PE32+ engine  ← CMake/PowerShell drive this
  bin\verilator.exe         same PE, renamed copy
  bin\verilator             Perl driver, **no extension** — do not invoke
  include\
```

The withlimon tarball does **not** ship `verilator-config.cmake`. Shared helper `cmake/PicoSim.cmake` uses bundled `cmake/verilator-config.fallback.cmake` in that case.

Do **not** run `C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe` — Perl wrapper with a `.exe` suffix (not a PE). CMake, `build_sim.ps1`, and the Conan recipe MZ-check `verilator_bin.exe`.

## Environment (once)

```
VERILATOR_ROOT = D:\verilator
PATH          += D:\verilator\bin
```

## cmake-system (no Conan)

```bat
cd cmake-system
powershell -File .\build_sim.ps1
```

Or:

```bat
set VERILATOR_ROOT=D:\verilator
set PATH=%VERILATOR_ROOT%\bin;%PATH%
cmake -S cmake-system -B build-system -DCMAKE_BUILD_TYPE=Release
cmake --build build-system --config Release --target sim
ctest --test-dir build-system -C Release --output-on-failure
```

## cmake-conan (Conan 2.34 + local recipe)

```bat
cd cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

`conan install` uses `--no-remote` so extra remotes cannot prompt for a password. Profile: `cmake-conan/profiles/windows-msvc`.

## MSVC `-fcoroutines*`

`cmake/PicoSim.cmake` `include(CheckCXXCompilerFlag)` before `verilate()`, then strips GCC-only `-fcoroutines*` on MSVC.

## Do not

- Do not run extensionless `bin\verilator` from Explorer or CMD.
- Do not change the original Makefile or rewrite `picorv32.v` / `testbench.v`.
- Do not treat this file as PASS evidence — Windows re-proof is a follow-up.
