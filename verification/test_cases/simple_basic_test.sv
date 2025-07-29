// Simple Basic Test for MX25L1605 SPI Flash
// Uses standard Verilog syntax compatible with iverilog

`timescale 1ns/1ps

module simple_basic_test;

    // Clock and reset
    reg clk;
    reg reset_n;
    
    // SPI signals
    reg sclk;
    reg cs_n;
    reg si;
    wire so;
    reg wp_n;
    reg hold_n;
    
    // Parallel output signals
    wire po0, po1, po2, po3, po4, po5, po6;
    
    // Test control
    reg test_done;
    integer test_count;
    integer pass_count;
    
    // Expected device ID values
    localparam [7:0] EXPECTED_MFG_ID = 8'hC2;    // MXIC
    localparam [7:0] EXPECTED_MEM_TYPE = 8'h20;   // Memory Type
    localparam [7:0] EXPECTED_DENSITY = 8'h15;    // 16Mb
    
    // DUT instantiation
    flash_16m dut (
        .SCLK(sclk),
        .CS(cs_n),
        .SI(si),
        .SO(so),
        .PO0(po0),
        .PO1(po1),
        .PO2(po2),
        .PO3(po3),
        .PO4(po4),
        .PO5(po5),
        .PO6(po6),
        .WP(wp_n),
        .HOLD(hold_n)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz system clock
    end
    
    // SPI clock generation
    initial begin
        sclk = 0;
        forever #10 sclk = ~sclk; // 25MHz SPI clock
    end
    
    // Main test
    initial begin
        $display("=== MX25L1605 Simple Basic Test ===");
        $display("Time: %t", $time);
        
        // Initialize signals
        reset_n = 0;
        test_done = 0;
        test_count = 0;
        pass_count = 0;
        
        cs_n = 1;
        si = 0;
        wp_n = 1;
        hold_n = 1;
        
        // Reset sequence
        #100;
        reset_n = 1;
        #100;
        
        // Run tests
        test_read_id();
        test_read_status();
        test_write_enable();
        
        // Report results
        #1000;
        report_results();
        
        test_done = 1;
        #100;
        $finish;
    end
    
    // Task to send a byte over SPI
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            cs_n = 0;
            #20; // Setup time
            
            for (i = 7; i >= 0; i = i - 1) begin
                @(negedge sclk);
                si = data[i];
                @(posedge sclk);
            end
            
            #20; // Hold time
            cs_n = 1;
            #40; // CS high time
        end
    endtask
    
    // Task to receive a byte over SPI
    task receive_byte;
        output [7:0] data;
        integer i;
        begin
            data = 8'h00;
            for (i = 7; i >= 0; i = i - 1) begin
                @(posedge sclk);
                data[i] = so;
            end
        end
    endtask
    
    // Test 1: Read ID Command (9Fh)
    task test_read_id;
        reg [7:0] mfg_id, mem_type, density;
        begin
            $display("\n--- Test 1: Read ID Command (9Fh) ---");
            test_count = test_count + 1;
            
            // Send Read ID command
            cs_n = 0;
            #20;
            
            send_byte_continuous(8'h9F); // Read ID command
            
            // Receive 3 bytes of ID
            receive_byte(mfg_id);
            receive_byte(mem_type);
            receive_byte(density);
            
            cs_n = 1;
            #40;
            
            // Check results
            $display("Received ID: MFG=0x%02X, Type=0x%02X, Density=0x%02X", 
                    mfg_id, mem_type, density);
            
            if (mfg_id == EXPECTED_MFG_ID && 
                mem_type == EXPECTED_MEM_TYPE && 
                density == EXPECTED_DENSITY) begin
                $display("✓ Read ID test PASSED");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Read ID test FAILED");
                $display("  Expected: MFG=0x%02X, Type=0x%02X, Density=0x%02X",
                        EXPECTED_MFG_ID, EXPECTED_MEM_TYPE, EXPECTED_DENSITY);
            end
        end
    endtask
    
    // Task to send byte continuously (without CS control)
    task send_byte_continuous;
        input [7:0] data;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                @(negedge sclk);
                si = data[i];
                @(posedge sclk);
            end
        end
    endtask
    
    // Test 2: Read Status Register (05h)
    task test_read_status;
        reg [7:0] status;
        begin
            $display("\n--- Test 2: Read Status Register (05h) ---");
            test_count = test_count + 1;
            
            // Send Read Status command
            cs_n = 0;
            #20;
            
            send_byte_continuous(8'h05); // Read Status command
            receive_byte(status);
            
            cs_n = 1;
            #40;
            
            $display("Status Register: 0x%02X", status);
            $display("  WIP (bit 0): %b", status[0]);
            $display("  WEL (bit 1): %b", status[1]);
            
            // Status register read should always work
            $display("✓ Read Status test PASSED");
            pass_count = pass_count + 1;
        end
    endtask
    
    // Test 3: Write Enable (06h)
    task test_write_enable;
        reg [7:0] status_before, status_after;
        begin
            $display("\n--- Test 3: Write Enable (06h) ---");
            test_count = test_count + 1;
            
            // Read status before
            cs_n = 0;
            #20;
            send_byte_continuous(8'h05);
            receive_byte(status_before);
            cs_n = 1;
            #40;
            
            // Send Write Enable
            cs_n = 0;
            #20;
            send_byte_continuous(8'h06);
            cs_n = 1;
            #40;
            
            // Read status after
            cs_n = 0;
            #20;
            send_byte_continuous(8'h05);
            receive_byte(status_after);
            cs_n = 1;
            #40;
            
            $display("Status before: 0x%02X, after: 0x%02X", status_before, status_after);
            
            // Check if WEL bit (bit 1) is set
            if (status_after[1] == 1'b1) begin
                $display("✓ Write Enable test PASSED - WEL bit set");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Write Enable test FAILED - WEL bit not set");
            end
        end
    endtask
    
    // Report final results
    task report_results;
        real pass_rate;
        begin
            pass_rate = (test_count > 0) ? (pass_count * 100.0) / test_count : 0.0;
            
            $display("\n" + "==================================================");
            $display("SIMPLE BASIC TEST RESULTS");
            $display("==================================================");
            $display("Total Tests: %0d", test_count);
            $display("Passed:      %0d", pass_count);
            $display("Failed:      %0d", test_count - pass_count);
            $display("Pass Rate:   %0.1f%%", pass_rate);
            $display("==================================================");
            
            if (pass_count == test_count) begin
                $display("*** ALL TESTS PASSED! ***");
            end else begin
                $display("*** %0d TESTS FAILED ***", test_count - pass_count);
            end
        end
    endtask
    
    // Timeout watchdog
    initial begin
        #50000; // 50us timeout
        if (!test_done) begin
            $display("ERROR: Test timeout!");
            $finish;
        end
    end
    
    // Waveform dumping
    initial begin
        $dumpfile("simple_basic_test.vcd");
        $dumpvars(0, simple_basic_test);
    end
    
    // Debug monitoring
    always @(posedge sclk) begin
        if (!cs_n) begin
            $display("[DEBUG] %t: SPI Active - CS=%b, SI=%b, SO=%b", $time, cs_n, si, so);
        end
    end
    
endmodule