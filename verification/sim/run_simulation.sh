#!/bin/bash

# MX25L1605 SPI Flash Verification Simulation Script
# Provides easy-to-use interface for running simulations

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
VERIFICATION_DIR="$PROJECT_ROOT/verification"

# Default settings
VERBOSE=0
CLEAN=0
WAVE=0
TEST=""
LOG_FILE=""

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo -e "${CYAN}"
    echo "================================================="
    echo "  MX25L1605 SPI Flash Verification Environment"
    echo "================================================="
    echo -e "${NC}"
}

# Function to print usage
print_usage() {
    print_header
    echo -e "${YELLOW}Usage:${NC} $0 [OPTIONS] [TEST]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help      Show this help message"
    echo "  -v, --verbose   Enable verbose output"
    echo "  -c, --clean     Clean before running"
    echo "  -w, --wave      Open waveform after simulation"
    echo "  -l, --log FILE  Save output to log file"
    echo "  --info          Show environment information"
    echo "  --debug         Show debug information"
    echo ""
    echo -e "${YELLOW}Available Tests:${NC}"
    echo "  basic_id        Run basic ID functionality test"
    echo "  write_read      Run write-read cycle test"
    echo "  main            Run comprehensive main testbench"
    echo "  all             Run all tests sequentially"
    echo "  smoke           Run quick smoke test"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 basic_id                    # Run basic ID test"
    echo "  $0 -w basic_id                 # Run test and open waveform"
    echo "  $0 -c -v all                   # Clean, run all tests verbosely"
    echo "  $0 -l test.log write_read      # Save output to log file"
    echo ""
}

# Function to check dependencies
check_dependencies() {
    local missing=0
    
    print_color $BLUE "Checking dependencies..."
    
    if ! command -v iverilog &> /dev/null; then
        print_color $RED "ERROR: iverilog not found. Please install Icarus Verilog."
        missing=1
    else
        local iverilog_version=$(iverilog -V 2>&1 | head -1)
        print_color $GREEN "✓ iverilog found: $iverilog_version"
    fi
    
    if ! command -v vvp &> /dev/null; then
        print_color $RED "ERROR: vvp not found. Please install Icarus Verilog."
        missing=1
    else
        print_color $GREEN "✓ vvp found"
    fi
    
    if ! command -v make &> /dev/null; then
        print_color $RED "ERROR: make not found. Please install make."
        missing=1
    else
        print_color $GREEN "✓ make found"
    fi
    
    if command -v gtkwave &> /dev/null; then
        print_color $GREEN "✓ GTKWave found (for waveform viewing)"
    else
        print_color $YELLOW "⚠ GTKWave not found (waveform viewing disabled)"
    fi
    
    if [ $missing -eq 1 ]; then
        print_color $RED "Missing dependencies. Please install required tools."
        exit 1
    fi
    
    echo ""
}

# Function to check file structure
check_structure() {
    print_color $BLUE "Checking file structure..."
    
    local required_files=(
        "$PROJECT_ROOT/mx25L1605.v"
        "$VERIFICATION_DIR/interfaces/spi_interface.sv"
        "$VERIFICATION_DIR/utils/spi_transaction.sv"
        "$VERIFICATION_DIR/agents/spi_driver.sv"
        "$VERIFICATION_DIR/agents/spi_monitor.sv"
        "$VERIFICATION_DIR/scoreboard/spi_scoreboard.sv"
        "$VERIFICATION_DIR/sequences/basic_sequence.sv"
        "$VERIFICATION_DIR/testbench/spi_flash_tb.sv"
        "$VERIFICATION_DIR/test_cases/test_basic_id.sv"
        "$VERIFICATION_DIR/test_cases/test_write_read.sv"
        "$VERIFICATION_DIR/sim/Makefile"
    )
    
    local missing_files=0
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            if [ $VERBOSE -eq 1 ]; then
                print_color $GREEN "✓ $file"
            fi
        else
            print_color $RED "✗ Missing: $file"
            missing_files=1
        fi
    done
    
    if [ $missing_files -eq 1 ]; then
        print_color $RED "Missing required files. Please check your verification environment."
        exit 1
    else
        print_color $GREEN "✓ All required files found"
    fi
    
    echo ""
}

# Function to run make command
run_make() {
    local target=$1
    local make_args=""
    
    if [ $VERBOSE -eq 1 ]; then
        make_args="V=1"
    fi
    
    print_color $BLUE "Running: make $target $make_args"
    
    cd "$VERIFICATION_DIR/sim" || {
        print_color $RED "ERROR: Cannot change to simulation directory"
        exit 1
    }
    
    if [ -n "$LOG_FILE" ]; then
        make $target $make_args 2>&1 | tee "$LOG_FILE"
        local result=${PIPESTATUS[0]}
    else
        make $target $make_args
        local result=$?
    fi
    
    return $result
}

# Function to open waveform
open_waveform() {
    local test_name=$1
    local vcd_file=""
    
    case $test_name in
        "basic_id")
            vcd_file="test_basic_id.vcd"
            ;;
        "write_read")
            vcd_file="test_write_read.vcd"
            ;;
        "main")
            vcd_file="spi_flash_sim.vcd"
            ;;
        *)
            print_color $YELLOW "No specific VCD file for test: $test_name"
            return
            ;;
    esac
    
    cd "$VERIFICATION_DIR/sim" || return
    
    if [ -f "$vcd_file" ]; then
        if command -v gtkwave &> /dev/null; then
            print_color $GREEN "Opening waveform: $vcd_file"
            gtkwave "$vcd_file" &
        else
            print_color $YELLOW "GTKWave not available. VCD file created: $vcd_file"
        fi
    else
        print_color $YELLOW "VCD file not found: $vcd_file"
    fi
}

# Function to run specific test
run_test() {
    local test_name=$1
    local start_time=$(date +%s)
    
    print_color $PURPLE "Starting test: $test_name"
    echo ""
    
    # Clean if requested
    if [ $CLEAN -eq 1 ]; then
        print_color $BLUE "Cleaning previous build..."
        run_make clean
        echo ""
    fi
    
    # Run the test
    case $test_name in
        "basic_id")
            run_make run_basic_id
            ;;
        "write_read")
            run_make run_write_read
            ;;
        "main")
            run_make run_main
            ;;
        "all")
            run_make run_all
            ;;
        "smoke")
            run_make smoke
            ;;
        *)
            print_color $RED "ERROR: Unknown test: $test_name"
            return 1
            ;;
    esac
    
    local result=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    if [ $result -eq 0 ]; then
        print_color $GREEN "✓ Test '$test_name' completed successfully in ${duration}s"
        
        # Open waveform if requested
        if [ $WAVE -eq 1 ]; then
            open_waveform "$test_name"
        fi
    else
        print_color $RED "✗ Test '$test_name' failed after ${duration}s"
    fi
    
    return $result
}

# Function to show environment info
show_info() {
    cd "$VERIFICATION_DIR/sim" || exit 1
    run_make info
}

# Function to show debug info
show_debug() {
    cd "$VERIFICATION_DIR/sim" || exit 1
    run_make debug
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -c|--clean)
            CLEAN=1
            shift
            ;;
        -w|--wave)
            WAVE=1
            shift
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        --info)
            show_info
            exit 0
            ;;
        --debug)
            show_debug
            exit 0
            ;;
        -*)
            print_color $RED "ERROR: Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            if [ -z "$TEST" ]; then
                TEST="$1"
            else
                print_color $RED "ERROR: Multiple test names specified"
                print_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Main execution
main() {
    print_header
    
    # Check dependencies and structure
    check_dependencies
    check_structure
    
    # If no test specified, show usage
    if [ -z "$TEST" ]; then
        print_color $YELLOW "No test specified."
        echo ""
        print_usage
        exit 0
    fi
    
    # Show configuration if verbose
    if [ $VERBOSE -eq 1 ]; then
        print_color $CYAN "Configuration:"
        echo "  Test: $TEST"
        echo "  Clean: $CLEAN"
        echo "  Wave: $WAVE"
        echo "  Log file: ${LOG_FILE:-none}"
        echo "  Project root: $PROJECT_ROOT"
        echo ""
    fi
    
    # Run the test
    run_test "$TEST"
    local result=$?
    
    # Final status
    echo ""
    print_color $CYAN "================================================="
    if [ $result -eq 0 ]; then
        print_color $GREEN "SIMULATION COMPLETED SUCCESSFULLY"
    else
        print_color $RED "SIMULATION FAILED"
    fi
    print_color $CYAN "================================================="
    
    exit $result
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi