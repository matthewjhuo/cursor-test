`timescale 1ns/1ns

module tb_mx25L1605;
    // DUT 介面訊號
    reg SCLK, CS, SI, WP, HOLD;
    wire SO, PO0, PO1, PO2, PO3, PO4, PO5, PO6;

    // 實例化 DUT
    flash_16m dut (
        .SCLK(SCLK), .CS(CS), .SI(SI), .SO(SO),
        .PO0(PO0), .PO1(PO1), .PO2(PO2), .PO3(PO3), .PO4(PO4), .PO5(PO5), .PO6(PO6),
        .WP(WP), .HOLD(HOLD)
    );

    // 時脈產生
    initial SCLK = 0;
    always #5 SCLK = ~SCLK;

    // 重置信號與初始值
    initial begin
        CS = 1;
        SI = 0;
        WP = 1;
        HOLD = 1;
        #100;
        // 之後呼叫 testcase
        test_read_id();
        test_write_enable();
        test_read_status();
        $finish;
    end

    // SPI 指令發送 task
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

    // 測試案例1: 讀取ID
    task test_read_id;
        begin
            $display("[TEST] Read ID");
            CS = 0;
            spi_send(8'h9F); // RDID
            repeat(24) @(posedge SCLK); // 讀出ID
            CS = 1;
            #20;
        end
    endtask

    // 測試案例2: Write Enable
    task test_write_enable;
        begin
            $display("[TEST] Write Enable");
            CS = 0;
            spi_send(8'h06); // WREN
            CS = 1;
            #20;
        end
    endtask

    // 測試案例3: 讀取狀態暫存器
    task test_read_status;
        begin
            $display("[TEST] Read Status");
            CS = 0;
            spi_send(8'h05); // RDSR
            repeat(8) @(posedge SCLK); // 讀出status
            CS = 1;
            #20;
        end
    endtask

endmodule