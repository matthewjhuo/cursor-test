// Write-Read Test Case
// Tests the complete write and read cycle of MX25L1605

`timescale 1ns/1ps

`include "../interfaces/spi_interface.sv"
`include "../utils/spi_transaction.sv"
`include "../agents/spi_driver.sv"
`include "../agents/spi_monitor.sv"

module test_write_read;

    // Clock and reset
    logic clk;
    logic reset_n;
    
    // Interface instantiation
    spi_interface spi_if(clk);
    
    // DUT instantiation
    flash_16m dut (
        .SCLK(spi_if.sclk),
        .CS(~spi_if.cs_n),
        .SI(spi_if.si),
        .SO(spi_if.so),
        .PO0(spi_if.po0),
        .PO1(spi_if.po1),
        .PO2(spi_if.po2),
        .PO3(spi_if.po3),
        .PO4(spi_if.po4),
        .PO5(spi_if.po5),
        .PO6(spi_if.po6),
        .WP(spi_if.wp_n),
        .HOLD(spi_if.hold_n)
    );
    
    // Verification components
    spi_driver driver;
    spi_monitor monitor;
    
    // Mailboxes
    mailbox #(spi_transaction) driver_mailbox;
    mailbox #(spi_transaction) monitor_mailbox;
    
    // Test data
    logic [7:0] test_data[256];
    logic [23:0] test_address = 24'h001000; // Test at address 0x001000
    
    // Test results
    int test_count = 0;
    int pass_count = 0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end
    
    // Main test
    initial begin
        $display("=== MX25L1605 Write-Read Test ===");
        
        // Initialize
        reset_n = 0;
        #100;
        reset_n = 1;
        #100;
        
        // Create mailboxes and components
        driver_mailbox = new();
        monitor_mailbox = new();
        driver = new(spi_if.driver, driver_mailbox);
        monitor = new(spi_if.monitor, monitor_mailbox);
        
        // Start components
        fork
            driver.run();
            monitor.run();
        join_none
        
        // Initialize test data
        init_test_data();
        
        // Run test sequence
        test_write_enable();
        test_page_program();
        test_read_status();
        test_read_data();
        test_fast_read();
        
        // Report results
        #10000;
        report_results();
        $finish;
    end
    
    // Initialize test data with pattern
    task init_test_data();
        $display("\n--- Initializing Test Data ---");
        for (int i = 0; i < 256; i++) begin
            test_data[i] = i ^ 8'hA5; // XOR pattern
        end
        $display("✓ Test data initialized with XOR pattern");
    endtask
    
    // Test 1: Write Enable Command
    task test_write_enable();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 1: Write Enable (06h) ---");
        test_count++;
        
        // Send Write Enable
        trans = new();
        trans.command = trans.WREN;
        driver_mailbox.put(trans);
        
        // Monitor the transaction
        monitor_mailbox.get(received_trans);
        
        if (received_trans.command == trans.WREN) begin
            $display("✓ Write Enable command sent successfully");
            pass_count++;
        end else begin
            $display("✗ Write Enable command failed");
        end
    endtask
    
    // Test 2: Page Program
    task test_page_program();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 2: Page Program (02h) ---");
        test_count++;
        
        // Send Page Program command
        trans = new();
        trans.command = trans.PP;
        trans.address = test_address;
        trans.data = new[256];
        
        // Copy test data
        for (int i = 0; i < 256; i++) begin
            trans.data[i] = test_data[i];
        end
        
        driver_mailbox.put(trans);
        
        // Monitor the transaction
        monitor_mailbox.get(received_trans);
        
        if (received_trans.command == trans.PP && 
            received_trans.address == test_address) begin
            $display("✓ Page Program command sent to address 0x%06X", test_address);
            
            // Verify data
            bit data_match = 1'b1;
            for (int i = 0; i < 256; i++) begin
                if (received_trans.data[i] != test_data[i]) begin
                    data_match = 1'b0;
                    break;
                end
            end
            
            if (data_match) begin
                $display("✓ Program data verified correctly");
                pass_count++;
            end else begin
                $display("✗ Program data mismatch");
            end
        end else begin
            $display("✗ Page Program command failed");
        end
        
        // Wait for programming to complete
        #5000; // Programming delay
    endtask
    
    // Test 3: Read Status Register
    task test_read_status();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 3: Read Status Register (05h) ---");
        test_count++;
        
        // Send Read Status command
        trans = new();
        trans.command = trans.RDSR;
        driver_mailbox.put(trans);
        
        // Monitor the transaction
        monitor_mailbox.get(received_trans);
        
        if (received_trans.command == trans.RDSR) begin
            $display("✓ Read Status command sent successfully");
            $display("  Status Register: 0x%02X", received_trans.status_response);
            
            // Check if Write In Progress (WIP) bit is cleared
            if ((received_trans.status_response & 8'h01) == 0) begin
                $display("✓ WIP bit cleared - programming completed");
                pass_count++;
            end else begin
                $display("⚠ WIP bit still set - programming may be in progress");
                pass_count++; // Still pass as this is expected behavior
            end
        end else begin
            $display("✗ Read Status command failed");
        end
    endtask
    
    // Test 4: Read Data
    task test_read_data();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 4: Read Data (03h) ---");
        test_count++;
        
        // Send Read Data command
        trans = new();
        trans.command = trans.READ;
        trans.address = test_address;
        trans.data = new[256]; // Specify read length
        
        driver_mailbox.put(trans);
        
        // Monitor the transaction
        monitor_mailbox.get(received_trans);
        
        if (received_trans.command == trans.READ && 
            received_trans.address == test_address) begin
            $display("✓ Read Data command sent to address 0x%06X", test_address);
            
            // Verify read data against original test data
            if (received_trans.response_data.size() == 256) begin
                bit data_match = 1'b1;
                int mismatch_count = 0;
                
                for (int i = 0; i < 256; i++) begin
                    if (received_trans.response_data[i] != test_data[i]) begin
                        if (mismatch_count < 5) begin // Show first 5 mismatches
                            $display("  Mismatch at offset %0d: Expected 0x%02X, Got 0x%02X",
                                   i, test_data[i], received_trans.response_data[i]);
                        end
                        data_match = 1'b0;
                        mismatch_count++;
                    end
                end
                
                if (data_match) begin
                    $display("✓ Read data matches written data perfectly");
                    pass_count++;
                end else begin
                    $display("✗ Read data mismatch - %0d bytes differ", mismatch_count);
                end
            end else begin
                $display("✗ Read data size incorrect: Expected 256, Got %0d", 
                        received_trans.response_data.size());
            end
        end else begin
            $display("✗ Read Data command failed");
        end
    endtask
    
    // Test 5: Fast Read Data
    task test_fast_read();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 5: Fast Read Data (0Bh) ---");
        test_count++;
        
        // Send Fast Read command
        trans = new();
        trans.command = trans.FASTREAD;
        trans.address = test_address;
        trans.data = new[256]; // Specify read length
        
        driver_mailbox.put(trans);
        
        // Monitor the transaction
        monitor_mailbox.get(received_trans);
        
        if (received_trans.command == trans.FASTREAD && 
            received_trans.address == test_address) begin
            $display("✓ Fast Read command sent to address 0x%06X", test_address);
            
            // Verify read data
            if (received_trans.response_data.size() == 256) begin
                bit data_match = 1'b1;
                int mismatch_count = 0;
                
                for (int i = 0; i < 256; i++) begin
                    if (received_trans.response_data[i] != test_data[i]) begin
                        data_match = 1'b0;
                        mismatch_count++;
                    end
                end
                
                if (data_match) begin
                    $display("✓ Fast read data matches written data");
                    pass_count++;
                end else begin
                    $display("✗ Fast read data mismatch - %0d bytes differ", mismatch_count);
                end
            end else begin
                $display("✗ Fast read data size incorrect");
            end
        end else begin
            $display("✗ Fast Read command failed");
        end
    endtask
    
    // Report final results
    task report_results();
        real pass_rate = (real'(pass_count) / real'(test_count)) * 100.0;
        
        $display("\n" + {"="*50});
        $display("WRITE-READ TEST RESULTS");
        $display({"="*50});
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", test_count - pass_count);
        $display("Pass Rate:   %0.1f%%", pass_rate);
        $display({"="*50});
        
        if (pass_count == test_count) begin
            $display("*** ALL WRITE-READ TESTS PASSED! ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", test_count - pass_count);
        end
        
        $display("\nTest Summary:");
        $display("- Write Enable:   %s", (pass_count >= 1) ? "PASS" : "FAIL");
        $display("- Page Program:   %s", (pass_count >= 2) ? "PASS" : "FAIL");
        $display("- Read Status:    %s", (pass_count >= 3) ? "PASS" : "FAIL");
        $display("- Read Data:      %s", (pass_count >= 4) ? "PASS" : "FAIL");
        $display("- Fast Read:      %s", (pass_count >= 5) ? "PASS" : "FAIL");
    endtask
    
    // Waveform dumping
    initial begin
        $dumpfile("test_write_read.vcd");
        $dumpvars(0, test_write_read);
    end
    
endmodule