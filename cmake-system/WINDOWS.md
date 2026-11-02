# Windows CMake (PC2023 — copy-paste)

Linux `cmake-system` / `cmake-conan` are proven in `PASS_EVIDENCE.md`. This file is the Windows worker path. The original **Makefile is unchanged**.

## Machine notes

| Item | Value |
|------|--------|
| Verilator | **[withlimon/verilator-windows](https://github.com/withlimon/verilator-windows)** (MSYS2 unpack is fine) |
| Engine | **`verilator_bin.exe`** (PE32+). Never the extensionless Perl `verilator` (Explorer/CMD “Open with…” trap). |
| Host C++ | **MSVC** via the Visual Studio generator (PC2023: VS 2022). `#if defined(_MSC_VER)` in `testbench.cc`. |
| Conan | **2.34** (`cmake-conan` tree only) |
| GNU make | **Not required** for configure / Verilator / `sim` / `ctest`. CMake uses `--make cmake` or `--make json`. |
| Firmware | `$readmemh` input. **Committed** `firmware/hello.hex` and `firmware/firmware.hex` (Linux prebuilts). Optional Makefile rebuild below. |

PC2023 develop tip previously failed at configure with `GNU make not found` from `PicoSim.cmake`. That hard dependency is gone. Verilator PE on this worker: `C:\msys64\mingw64\bin\verilator_bin.exe`.

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

MSYS2 unpack of the same (or MSYS2 `mingw-w64-x86_64-verilator`) kit:

- Use **`C:\msys64\mingw64\bin\verilator_bin.exe`** (PE).
- Do **not** run `C:\msys64\mingw64\share\verilator\bin\verilator_bin.exe` — Perl wrapper with a `.exe` suffix (not a PE).

CMake, `build_sim.ps1`, and the Conan recipe MZ-check `verilator_bin.exe` and prefer `D:\verilator\bin` then `C:\msys64\mingw64\bin`.

## Environment (once)

```
VERILATOR_ROOT = D:\verilator
PATH          += D:\verilator\bin
```

If the PE lives under MSYS2, `build_sim.ps1` finds `C:\msys64\mingw64\bin\verilator_bin.exe` and sets `VERILATOR_ROOT` to `C:\msys64\mingw64\share\verilator` when that kit has `include\verilated.h`.

## Firmware hex (no RISC-V GCC on the Windows box)

`firmware/hello.hex` and `firmware/firmware.hex` are **in the git tree** (built on Linux with `riscv64-unknown-elf-gcc`). `PICO_REBUILD_FIRMWARE` defaults to **OFF** on Windows; `--target sim` / `ctest` use those files. Do not copy by hand.

Optional rebuild on Windows (needs MSYS2 `make` **and** RISC-V GCC **and** `bash`, because the original Makefile sets `SHELL = bash`):

```bat
cmake -S cmake-system -B build-system -G "Visual Studio 17 2022" -DPICO_REBUILD_FIRMWARE=ON
```

CMake searches `C:\msys64\usr\bin\make.exe` and `mingw32-make` under MSYS2 prefixes even when they are not on PATH. Pass `-DPICO_GNU_MAKE=...` to override. This is **not** the PC2023 default; committed hex is.

## cmake-system (no Conan)

```bat
cd cmake-system
powershell -File .\build_sim.ps1
```

Or:

```bat
set VERILATOR_ROOT=C:\msys64\mingw64\share\verilator
set PATH=C:\msys64\mingw64\bin;%PATH%
cmake -S cmake-system -B build-system
cmake --build build-system --config Release --target sim
ctest --test-dir build-system -C Release --output-on-failure
```

On PC2023, CMake selects **Visual Studio 17 2022** / MSVC when `-G` is omitted. `build_sim.ps1` always drives `verilator_bin.exe` (PE), never extensionless Perl `verilator`.

## cmake-conan (Conan 2.34 + local recipe)

```bat
cd cmake-conan
conan profile detect --force
powershell -File .\build_sim.ps1
```

`conan install` uses `--no-remote` so extra remotes cannot prompt for a password. Profile: `cmake-conan/profiles/windows-msvc`. Same PE + no-make + hex rules as cmake-system.

## MSVC host C++

- `cmake/PicoSim.cmake` `include(CheckCXXCompilerFlag)` before `verilate()`, then strips GCC-only `-fcoroutines*` on MSVC.
- `cmake/sc_time_stamp.cpp` supplies `sc_time_stamp` (`VL_ATTR_WEAK` is empty on MSVC).
- `testbench.cc` uses `#if defined(_MSC_VER)` for CRT/`NOMINMAX` and 64-bit trace printf (`unsigned long` is 32-bit on LLP64).
- Target also gets `_CRT_SECURE_NO_WARNINGS` and `NOMINMAX`.

## Do not

- Do not run extensionless `bin\verilator` from Explorer or CMD.
- Do not change the original Makefile or rewrite `picorv32.v` / `testbench.v`.
- Do not install GNU make only to satisfy configure — it is not required for Verilator cmake.

PC2023: configure + Verilator already OK on this branch; `--target sim` needs the committed hex in this push. Re-run `powershell -File .\build_sim.ps1`. Linux evidence: [`PASS_EVIDENCE.md`](PASS_EVIDENCE.md).
