// Verilator optionally defines sc_time_stamp as a weak ELF/Mach-O symbol.
// MSVC has no weak externs (VL_ATTR_WEAK is empty), so every CMake sim
// provides this stub. Same contract as Verilator's tracing examples.
double sc_time_stamp() { return 0; }
