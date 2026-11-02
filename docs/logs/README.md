# Proven simulation logs

Captured on Ubuntu 24.04 with Icarus Verilog 12.0, Verilator 5.020, and
`riscv64-unknown-elf-gcc` 13.2.0 (`make toolchain-info`).

| File | What it is |
|------|------------|
| [01-inspect.txt](01-inspect.txt) | Tool versions and auto-detected `TOOLCHAIN_PREFIX` |
| [02-build-hello.txt](02-build-hello.txt) | Cross-compile of the hello-only C firmware → `firmware/hello.hex` |
| [03-verilator-build.txt](03-verilator-build.txt) | `verilator --cc --exe --build` of `picorv32_wrapper` |
| [04-iverilog-hello.txt](04-iverilog-hello.txt) | `make test_hello` → `ALL TESTS PASSED.`, `exit_code=0` |
| [05-verilator-hello.txt](05-verilator-hello.txt) | `make test_verilator_hello` → `ALL TESTS PASSED.`, `verilator_exit=0` |
| [06-verilator-firmware.txt](06-verilator-firmware.txt) | Full upstream firmware on Verilator → `ALL TESTS PASSED.` |

The EBREAK register dump at the end is expected: firmware writes the magic
pass value to `0x20000000`, then `ebreak`s so the TB can trap and check
`tests_passed`.
