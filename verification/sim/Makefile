# Makefile for MX25L1605 SPI Flash Verification
# Supports iverilog compilation and simulation

# Tools
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
DUT_DIR = ../..
TB_DIR = ../testbench
TEST_DIR = ../test_cases
INTERFACE_DIR = ../interfaces
UTILS_DIR = ../utils
AGENTS_DIR = ../agents
SCOREBOARD_DIR = ../scoreboard
SEQUENCES_DIR = ../sequences

# Files
DUT_FILE = $(DUT_DIR)/mx25L1605.v
MAIN_TB = $(TB_DIR)/spi_flash_tb.sv

# Test cases
TEST_BASIC_ID = $(TEST_DIR)/test_basic_id.sv
TEST_WRITE_READ = $(TEST_DIR)/test_write_read.sv
SIMPLE_BASIC_TEST = $(TEST_DIR)/simple_basic_test.sv

# Include paths for iverilog
INCLUDE_PATHS = -I$(INTERFACE_DIR) -I$(UTILS_DIR) -I$(AGENTS_DIR) -I$(SCOREBOARD_DIR) -I$(SEQUENCES_DIR)

# Compiler flags
IVERILOG_FLAGS = -g2012 -Wall $(INCLUDE_PATHS)
SIMPLE_IVERILOG_FLAGS = -g2012 -Wall
VVP_FLAGS = 

# Output files
MAIN_TB_OUT = spi_flash_tb.vvp
TEST_BASIC_ID_OUT = test_basic_id.vvp
TEST_WRITE_READ_OUT = test_write_read.vvp
SIMPLE_BASIC_OUT = simple_basic_test.vvp

# VCD files
MAIN_TB_VCD = spi_flash_sim.vcd
TEST_BASIC_ID_VCD = test_basic_id.vcd
TEST_WRITE_READ_VCD = test_write_read.vcd
SIMPLE_BASIC_VCD = simple_basic_test.vcd

# Default target
.PHONY: all
all: compile_simple

# Help target
.PHONY: help
help:
	@echo "MX25L1605 SPI Flash Verification Makefile"
	@echo "=========================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all          - Compile simple testbench (default)"
	@echo "  compile      - Compile all SystemVerilog testbenches"
	@echo "  compile_simple - Compile simple Verilog testbench"
	@echo "  run_main     - Run main testbench"
	@echo "  run_basic_id - Run basic ID test"
	@echo "  run_write_read - Run write-read test"
	@echo "  run_simple   - Run simple basic test"
	@echo "  run_all      - Run all tests sequentially"
	@echo "  wave_main    - Open main testbench waveform"
	@echo "  wave_basic_id - Open basic ID test waveform"
	@echo "  wave_write_read - Open write-read test waveform"
	@echo "  wave_simple  - Open simple test waveform"
	@echo "  clean        - Remove generated files"
	@echo "  lint         - Run basic syntax check"
	@echo "  lint_simple  - Run syntax check on simple test"
	@echo ""
	@echo "Examples:"
	@echo "  make run_simple      # Run simple test (recommended for iverilog)"
	@echo "  make run_basic_id    # Run basic ID test"
	@echo "  make run_all         # Run all tests"
	@echo "  make wave_simple     # View simple test waveforms"

# Compile all testbenches
.PHONY: compile
compile: compile_main compile_basic_id compile_write_read compile_simple

# Compile simple testbench (Verilog only)
.PHONY: compile_simple
compile_simple: $(SIMPLE_BASIC_OUT)

$(SIMPLE_BASIC_OUT): $(SIMPLE_BASIC_TEST) $(DUT_FILE)
	@echo "Compiling simple basic test..."
	$(IVERILOG) $(SIMPLE_IVERILOG_FLAGS) -o $(SIMPLE_BASIC_OUT) $(DUT_FILE) $(SIMPLE_BASIC_TEST)
	@echo "Simple basic test compiled successfully"

# Compile main testbench
.PHONY: compile_main
compile_main: $(MAIN_TB_OUT)

$(MAIN_TB_OUT): $(MAIN_TB) $(DUT_FILE)
	@echo "Compiling main testbench..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(MAIN_TB_OUT) $(DUT_FILE) $(MAIN_TB)
	@echo "Main testbench compiled successfully"

# Compile basic ID test
.PHONY: compile_basic_id
compile_basic_id: $(TEST_BASIC_ID_OUT)

$(TEST_BASIC_ID_OUT): $(TEST_BASIC_ID) $(DUT_FILE)
	@echo "Compiling basic ID test..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(TEST_BASIC_ID_OUT) $(DUT_FILE) $(TEST_BASIC_ID)
	@echo "Basic ID test compiled successfully"

# Compile write-read test
.PHONY: compile_write_read
compile_write_read: $(TEST_WRITE_READ_OUT)

$(TEST_WRITE_READ_OUT): $(TEST_WRITE_READ) $(DUT_FILE)
	@echo "Compiling write-read test..."
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(TEST_WRITE_READ_OUT) $(DUT_FILE) $(TEST_WRITE_READ)
	@echo "Write-read test compiled successfully"

# Run simple testbench
.PHONY: run_simple
run_simple: $(SIMPLE_BASIC_OUT)
	@echo "Running simple basic test..."
	$(VVP) $(VVP_FLAGS) $(SIMPLE_BASIC_OUT)
	@echo "Simple basic test completed"

# Run main testbench
.PHONY: run_main
run_main: $(MAIN_TB_OUT)
	@echo "Running main testbench..."
	$(VVP) $(VVP_FLAGS) $(MAIN_TB_OUT)
	@echo "Main testbench simulation completed"

# Run basic ID test
.PHONY: run_basic_id
run_basic_id: $(TEST_BASIC_ID_OUT)
	@echo "Running basic ID test..."
	$(VVP) $(VVP_FLAGS) $(TEST_BASIC_ID_OUT)
	@echo "Basic ID test completed"

# Run write-read test
.PHONY: run_write_read
run_write_read: $(TEST_WRITE_READ_OUT)
	@echo "Running write-read test..."
	$(VVP) $(VVP_FLAGS) $(TEST_WRITE_READ_OUT)
	@echo "Write-read test completed"

# Run all tests sequentially
.PHONY: run_all
run_all: run_simple run_basic_id run_write_read run_main
	@echo ""
	@echo "========================================"
	@echo "ALL TESTS COMPLETED"
	@echo "========================================"
	@echo "Check individual test results above"
	@echo "VCD files generated for waveform analysis"

# Open waveforms
.PHONY: wave_simple
wave_simple: $(SIMPLE_BASIC_VCD)
	@if command -v $(GTKWAVE) > /dev/null 2>&1; then \
		echo "Opening simple test waveform..."; \
		$(GTKWAVE) $(SIMPLE_BASIC_VCD) &; \
	else \
		echo "GTKWave not found. VCD file available: $(SIMPLE_BASIC_VCD)"; \
	fi

.PHONY: wave_main
wave_main: $(MAIN_TB_VCD)
	@if command -v $(GTKWAVE) > /dev/null 2>&1; then \
		echo "Opening main testbench waveform..."; \
		$(GTKWAVE) $(MAIN_TB_VCD) &; \
	else \
		echo "GTKWave not found. VCD file available: $(MAIN_TB_VCD)"; \
	fi

.PHONY: wave_basic_id
wave_basic_id: $(TEST_BASIC_ID_VCD)
	@if command -v $(GTKWAVE) > /dev/null 2>&1; then \
		echo "Opening basic ID test waveform..."; \
		$(GTKWAVE) $(TEST_BASIC_ID_VCD) &; \
	else \
		echo "GTKWave not found. VCD file available: $(TEST_BASIC_ID_VCD)"; \
	fi

.PHONY: wave_write_read
wave_write_read: $(TEST_WRITE_READ_VCD)
	@if command -v $(GTKWAVE) > /dev/null 2>&1; then \
		echo "Opening write-read test waveform..."; \
		$(GTKWAVE) $(TEST_WRITE_READ_VCD) &; \
	else \
		echo "GTKWave not found. VCD file available: $(TEST_WRITE_READ_VCD)"; \
	fi

# Syntax check / lint
.PHONY: lint
lint:
	@echo "Running syntax check on DUT..."
	$(IVERILOG) $(IVERILOG_FLAGS) -t null $(DUT_FILE)
	@echo "Running syntax check on testbenches..."
	$(IVERILOG) $(IVERILOG_FLAGS) -t null $(DUT_FILE) $(MAIN_TB)
	$(IVERILOG) $(IVERILOG_FLAGS) -t null $(DUT_FILE) $(TEST_BASIC_ID)
	$(IVERILOG) $(IVERILOG_FLAGS) -t null $(DUT_FILE) $(TEST_WRITE_READ)
	@echo "Syntax check completed"

# Syntax check for simple test only
.PHONY: lint_simple
lint_simple:
	@echo "Running syntax check on DUT..."
	$(IVERILOG) $(SIMPLE_IVERILOG_FLAGS) -t null $(DUT_FILE)
	@echo "Running syntax check on simple test..."
	$(IVERILOG) $(SIMPLE_IVERILOG_FLAGS) -t null $(DUT_FILE) $(SIMPLE_BASIC_TEST)
	@echo "Simple syntax check completed"

# Quick smoke test
.PHONY: smoke
smoke: compile_simple run_simple
	@echo "Smoke test completed - basic functionality verified"

# Clean generated files
.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	rm -f *.vvp *.vcd *.fst *.lxt *.out
	rm -f dump.vcd
	@echo "Clean completed"

# Create directory structure if needed
.PHONY: setup
setup:
	@echo "Setting up verification directory structure..."
	mkdir -p $(TB_DIR) $(TEST_DIR) $(INTERFACE_DIR) $(UTILS_DIR) 
	mkdir -p $(AGENTS_DIR) $(SCOREBOARD_DIR) $(SEQUENCES_DIR)
	@echo "Directory structure created"

# Development targets
.PHONY: dev
dev: clean compile_simple run_simple wave_simple

# Continuous integration target
.PHONY: ci
ci: clean lint_simple compile_simple run_simple
	@echo "CI pipeline completed"

# Debug information
.PHONY: debug
debug:
	@echo "Debug Information:"
	@echo "=================="
	@echo "DUT File: $(DUT_FILE)"
	@echo "Simple Test: $(SIMPLE_BASIC_TEST)"
	@echo "Main TB: $(MAIN_TB)"
	@echo "Include Paths: $(INCLUDE_PATHS)"
	@echo "Iverilog Version:"
	@$(IVERILOG) -V | head -1
	@echo ""
	@echo "Available VCD files:"
	@ls -la *.vcd 2>/dev/null || echo "No VCD files found"

# Show file structure
.PHONY: structure
structure:
	@echo "Verification Environment Structure:"
	@echo "=================================="
	@tree .. 2>/dev/null || find .. -type f -name "*.sv" -o -name "*.v" | sort

.PHONY: info
info:
	@echo "MX25L1605 SPI Flash Verification Environment"
	@echo "============================================"
	@echo ""
	@echo "This verification environment provides comprehensive testing"
	@echo "for the MX25L1605 16Mbit SPI Flash memory model."
	@echo ""
	@echo "Key Features:"
	@echo "- SystemVerilog-based testbench (advanced features)"
	@echo "- Simple Verilog testbench (iverilog compatible)"
	@echo "- Transaction-level modeling"
	@echo "- Multiple test scenarios"
	@echo "- Waveform generation for debug"
	@echo "- Automated pass/fail reporting"
	@echo ""
	@echo "Supported Commands:"
	@echo "- Read ID (9Fh)"
	@echo "- Read Status (05h)"
	@echo "- Write Enable/Disable (06h/04h)"
	@echo "- Page Program (02h)"
	@echo "- Sector Erase (20h/D8h)"
	@echo "- Read Data (03h/0Bh)"
	@echo "- Power Management (B9h/ABh)"
	@echo ""
	@echo "For iverilog users: Use 'make run_simple' for best compatibility"
	@echo "Use 'make help' for available targets"