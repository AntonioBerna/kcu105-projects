VERILATOR ?= verilator
VERIBLE ?= verible-verilog-format
VERIBLE_SYNTAX ?= verible-verilog-syntax
VERIBLE_LINT ?= verible-verilog-lint
VERIBLE_LINT_FLAGS ?= --rules=-module-filename
VERILATOR_FLAGS ?= --sv --timing --trace -Wno-fatal
STOP_NS ?= 200
BUILD_SRC := rtl/led_bar.sv tb/tb.sv
ALL_SRC := $(wildcard rtl/*.sv) $(wildcard tb/*.sv) $(wildcard tb/*/*.sv)
TARGET := tb
BINARY := obj_dir/V$(TARGET)
VCD := dump.vcd

.PHONY: all run format clean

all: $(BINARY)

$(BINARY): $(BUILD_SRC)
	$(VERILATOR) --binary $(VERILATOR_FLAGS) -DSTOP_NS=$(STOP_NS) --top-module $(TARGET) $(BUILD_SRC)

run: $(BINARY)
	@rm -f $(VCD)
	./$(BINARY)
	@test -s $(VCD) || (echo "Error: $(VCD) is empty or missing"; exit 1)
	@echo "Generated $(VCD)"

format:
	@if ! command -v $(VERIBLE) >/dev/null 2>&1; then \
		echo "Error: $(VERIBLE) not found. Install verible."; \
		exit 1; \
	fi
	$(VERIBLE) --inplace $(ALL_SRC)
	$(VERIBLE_SYNTAX) $(ALL_SRC)
	$(VERIBLE_LINT) $(VERIBLE_LINT_FLAGS) $(ALL_SRC)

clean:
	rm -rf obj_dir *.out *.vcd
