# PicoRV32 learning index / 学习入口

Primary tutorial (Chinese, for Wei): **[TUTORIAL_zh.md](TUTORIAL_zh.md)**
Shorter English summary: **[TUTORIAL.md](TUTORIAL.md)**
Proven command logs: **[logs/](logs/)**

This fork (`weiwan-gmail/picorv32`, work on **develop**, parent
[YosysHQ/picorv32](https://github.com/YosysHQ/picorv32)) keeps the original
Icarus + firmware-hex flow and makes the **already-present Verilator C++
driver** work on a modern Linux box. The CPU in `picorv32.v` is not rewritten.

**Why hex + Verilator, not a new C ISS:** PicoRV32 already compiles C
(`firmware/*.c`) to `firmware.hex`, `$readmemh`s it into TB RAM, and
`testbench.cc` only toggles `clk`/`resetn`. That *is* C firmware co-sim for
this core. A separate instruction-set simulator would be a second CPU.

## Exact commands (reproduced in `docs/logs/`)

Install tools (Ubuntu/Debian):

```bash
sudo apt-get install -y iverilog verilator gcc-riscv64-unknown-elf python3 build-essential
make toolchain-info
```

### 1) Small C hello (documented demo)

```bash
make test_verilator_hello
# expect: hello world / DONE / ALL TESTS PASSED. / verilator_exit=0
```

Icarus (same hex, same TB protocol):

```bash
make test_hello
# expect: ALL TESTS PASSED.
```

### 2) Full upstream firmware (ISA + sieve + mul + stats)

```bash
make test_verilator
# expect: hello world, many "OK" lines, ALL TESTS PASSED., verilator_exit=0
```

No RISC-V GCC at all (hardcoded 6 instructions, Icarus only):

```bash
make test_ez
```

## How to read PASS / FAIL

| Check | Meaning |
|-------|---------|
| UART-style MMIO `0x10000000` | each `sw` of a byte is a printed character (`print.c`) |
| MMIO `0x20000000` ← `123456789` | firmware claims success (`tests_passed`) |
| CPU `trap` after `ebreak` | TB decides PASS vs ERROR |
| stdout `ALL TESTS PASSED.` | `tests_passed==1` at trap |
| `verilator_exit=0` | C++ driver agrees (1 = fail, 2 = timeout) |

## Next cores on the ladder

After this tree is green:

1. **FemtoRV** (`learn-fpga`) — teaching SoCs (QUARK → ELEPHANT), another UART + linker-script view.
2. **darkriscv** — a from-scratch RV32 core; compare coding style with PicoRV32’s single-file `picorv32.v`.
3. **SERV** — bit-serial RISC-V; same ISA, radically different microarchitecture.

See the last section of [TUTORIAL_zh.md](TUTORIAL_zh.md).
