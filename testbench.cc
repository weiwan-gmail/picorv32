// Verilator C++ driver for picorv32_wrapper (testbench.v).
// Clock/reset live here because the Verilog testbench module is
// wrapped in `ifndef VERILATOR`. Firmware is still loaded from
// firmware/*.hex via $readmemh in the wrapper.

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vpicorv32_wrapper.h"

static long parse_plus_long(const char *key, long default_value)
{
	const char *p = Verilated::commandArgsPlusMatch(key);
	if (!p || p[0] == '\0')
		return default_value;
	const char *eq = strchr(p, '=');
	if (!eq || eq[1] == '\0')
		return default_value;
	return strtol(eq + 1, NULL, 0);
}

int main(int argc, char **argv)
{
	Verilated::commandArgs(argc, argv);

	printf("Built with %s %s.\n", Verilated::productName(), Verilated::productVersion());
	printf("Recommended: Verilator 4.0 or later.\n");

	Vpicorv32_wrapper *top = new Vpicorv32_wrapper;

	VerilatedVcdC *tfp = NULL;
	const char *flag_vcd = Verilated::commandArgsPlusMatch("vcd");
	if (flag_vcd && 0 == strcmp(flag_vcd, "+vcd")) {
		Verilated::traceEverOn(true);
		tfp = new VerilatedVcdC;
		top->trace(tfp, 99);
		tfp->open("testbench.vcd");
	}

	FILE *trace_fd = NULL;
	const char *flag_trace = Verilated::commandArgsPlusMatch("trace");
	if (flag_trace && 0 == strcmp(flag_trace, "+trace"))
		trace_fd = fopen("testbench.trace", "w");

	const long max_cycles = parse_plus_long("max-cycles", 2000000);
	long cycles = 0;
	int t = 0;
	int exit_code = 0;

	top->clk = 0;
	top->resetn = 0;

	while (!Verilated::gotFinish()) {
		if (t > 200)
			top->resetn = 1;
		top->clk = !top->clk;
		top->eval();
		if (tfp)
			tfp->dump(t);
		if (trace_fd && top->clk && top->trace_valid)
			fprintf(trace_fd, "%9.9lx\n", (unsigned long)top->trace_data);
		if (top->clk) {
			cycles++;
			if (cycles > max_cycles) {
				printf("TIMEOUT after %ld clock cycles\n", cycles);
				exit_code = 2;
				break;
			}
		}
		t += 5;
	}

	if (exit_code == 0)
		exit_code = top->tests_passed ? 0 : 1;

	printf("verilator_exit=%d tests_passed=%d cycles=%ld\n",
	       exit_code, (int)top->tests_passed, cycles);

	if (tfp)
		tfp->close();
	if (trace_fd)
		fclose(trace_fd);
	delete top;
	return exit_code;
}
