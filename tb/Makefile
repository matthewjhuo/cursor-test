IVERILOG = iverilog
VVP = vvp
SRCS = ../mx25L1605.v
UTILS = ../sv_utils/spi_if.sv

all: tb_mx25L1605 testcase_page_program testcase_sector_erase testcase_chip_erase

build:
	mkdir -p ../build

tb_mx25L1605: build
	$(IVERILOG) -g2012 -o ../build/tb_mx25L1605 tb_mx25L1605.sv $(SRCS) $(UTILS)

testcase_page_program: build
	$(IVERILOG) -g2012 -o ../build/testcase_page_program testcase_page_program.sv $(SRCS) $(UTILS)

testcase_sector_erase: build
	$(IVERILOG) -g2012 -o ../build/testcase_sector_erase testcase_sector_erase.sv $(SRCS) $(UTILS)

testcase_chip_erase: build
	$(IVERILOG) -g2012 -o ../build/testcase_chip_erase testcase_chip_erase.sv $(SRCS) $(UTILS)

clean:
	rm -rf ../build/*