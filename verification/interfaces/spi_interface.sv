// SPI Interface for MX25L1605 Flash Memory
// This interface defines all signals needed for SPI communication

interface spi_interface(input logic clk);
    
    // SPI signals
    logic sclk;          // SPI Clock
    logic cs_n;          // Chip Select (active low)
    logic si;            // Serial Data Input (MOSI)
    logic so;            // Serial Data Output (MISO)
    logic wp_n;          // Write Protection (active low)
    logic hold_n;        // Hold signal (active low)
    
    // Parallel output signals
    logic po0, po1, po2, po3, po4, po5, po6;
    
    // Control signals for testbench
    logic reset_n;
    
    // Modport for driver
    modport driver (
        output sclk, cs_n, si, wp_n, hold_n, reset_n,
        input so, po0, po1, po2, po3, po4, po5, po6
    );
    
    // Modport for monitor
    modport monitor (
        input sclk, cs_n, si, so, wp_n, hold_n, reset_n,
        input po0, po1, po2, po3, po4, po5, po6
    );
    
    // Modport for DUT
    modport dut (
        input sclk, cs_n, si, wp_n, hold_n,
        inout so, po0, po1, po2, po3, po4, po5, po6
    );
    
    // Clock generation for SPI
    initial begin
        sclk = 0;
        forever #10 sclk = ~sclk; // 25MHz SPI clock
    end
    
endinterface