`timescale 1ns/1ns

module testcase_page_program;
    reg SCLK, CS, SI, WP, HOLD;
    wire SO, PO0, PO1, PO2, PO3, PO4, PO5, PO6;
    flash_16m dut (
        .SCLK(SCLK), .CS(CS), .SI(SI), .SO(SO),
        .PO0(PO0), .PO1(PO1), .PO2(PO2), .PO3(PO3), .PO4(PO4), .PO5(PO5), .PO6(PO6),
        .WP(WP), .HOLD(HOLD)
    );
    initial SCLK = 0;
    always #5 SCLK = ~SCLK;
    initial begin
        CS = 1; SI = 0; WP = 1; HOLD = 1;
        #100;
        // Write Enable
        CS = 0; spi_send(8'h06); CS = 1; #20;
        // Page Program: 0x02, address 0x000000, data 0xA5
        CS = 0; spi_send(8'h02); spi_send(8'h00); spi_send(8'h00); spi_send(8'h00); spi_send(8'hA5); CS = 1; #100000;
        // Read Data: 0x03, address 0x000000
        CS = 0; spi_send(8'h03); spi_send(8'h00); spi_send(8'h00); spi_send(8'h00);
        repeat(8) @(posedge SCLK);
        CS = 1; #20;
        $finish;
    end
    task spi_send;
        input [7:0] data;
        integer i;
        begin
            for (i=7; i>=0; i=i-1) begin
                SI = data[i];
                #5; SCLK = 0; #5; SCLK = 1;
            end
        end
    endtask
endmodule