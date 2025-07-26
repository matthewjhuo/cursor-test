interface spi_if(input bit clk);
    logic SCLK, CS, SI, SO, WP, HOLD;
    logic [6:0] PO;
    modport dut (input SCLK, CS, SI, WP, HOLD, output SO, PO);
    modport tb  (output SCLK, CS, SI, WP, HOLD, input SO, PO);
endinterface