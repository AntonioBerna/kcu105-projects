VERILATOR ?= verilator
VERIBLE ?= verible-verilog-format
VERIBLE_SYNTAX ?= verible-verilog-syntax
VERIBLE_LINT ?= verible-verilog-lint

CONFIG_DIR ?= ../../config
VERILATOR_FLAGS_FILE ?= $(CONFIG_DIR)/verilator.flags
VERIBLE_FORMAT_FLAGS_FILE ?= $(CONFIG_DIR)/verible-format.flags
VERIBLE_SYNTAX_FLAGS_FILE ?= $(CONFIG_DIR)/verible-syntax.flags
VERIBLE_LINT_FLAGS_FILE ?= $(CONFIG_DIR)/verible-lint.flags

VERILATOR_FLAGS ?= --sv -Wno-fatal
STOP_NS ?= 200
BUILD_SRC := rtl/led_bar.sv tb/tb.sv
ALL_SRC := $(wildcard rtl/*.sv) $(wildcard tb/*.sv) $(wildcard tb/*/*.sv)
TARGET := tb
BINARY := obj_dir/V$(TARGET)
VCD := dump.vcd
CONFIG_FILES := $(VERILATOR_FLAGS_FILE) $(VERIBLE_FORMAT_FLAGS_FILE) $(VERIBLE_SYNTAX_FLAGS_FILE) $(VERIBLE_LINT_FLAGS_FILE)

.PHONY: all run format clean check-config

all: $(BINARY)

check-config:
	@for f in $(CONFIG_FILES); do \
		if [ ! -f "$$f" ]; then \
			echo "Error: missing config file $$f"; \
			exit 1; \
		fi; \
	done

$(BINARY): $(BUILD_SRC) check-config
	$(VERILATOR) --binary $(VERILATOR_FLAGS) $$(cat $(VERILATOR_FLAGS_FILE)) -DSTOP_NS=$(STOP_NS) --top-module $(TARGET) $(BUILD_SRC)

run: $(BINARY)
	@rm -f $(VCD)
	./$(BINARY)
	@test -s $(VCD) || (echo "Error: $(VCD) is empty or missing"; exit 1)
	@echo "Generated $(VCD)"

format: check-config
	@if ! command -v $(VERIBLE) >/dev/null 2>&1; then \
		echo "Error: $(VERIBLE) not found. Install verible."; \
		exit 1; \
	fi
	$(VERIBLE) --inplace $$(cat $(VERIBLE_FORMAT_FLAGS_FILE)) $(ALL_SRC)
	$(VERIBLE_SYNTAX) $$(cat $(VERIBLE_SYNTAX_FLAGS_FILE)) $(ALL_SRC)
	$(VERIBLE_LINT) $$(cat $(VERIBLE_LINT_FLAGS_FILE)) $(ALL_SRC)

clean:
	rm -rf obj_dir *.out *.vcd
