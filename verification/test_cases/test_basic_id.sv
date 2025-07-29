// Basic Device ID Test Case
// Tests the Read ID functionality of MX25L1605

`timescale 1ns/1ps

`include "../interfaces/spi_interface.sv"
`include "../utils/spi_transaction.sv"
`include "../agents/spi_driver.sv"
`include "../agents/spi_monitor.sv"

module test_basic_id;

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
    
    // Expected values
    parameter logic [7:0] EXPECTED_MFG_ID = 8'hC2;    // MXIC
    parameter logic [7:0] EXPECTED_MEM_TYPE = 8'h20;   // Memory Type
    parameter logic [7:0] EXPECTED_DENSITY = 8'h15;    // 16Mb (2MB)
    
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
        $display("=== MX25L1605 Basic ID Test ===");
        
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
        
        // Run tests
        test_read_id_command();
        test_read_manufacturer_id();
        test_read_electronic_id();
        
        // Report results
        #5000;
        report_results();
        $finish;
    end
    
    // Test 1: Basic Read ID (9Fh command)
    task test_read_id_command();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 1: Read ID Command (9Fh) ---");
        test_count++;
        
        // Create read ID transaction
        trans = new();
        trans.command = trans.RDID;
        
        // Send transaction
        driver_mailbox.put(trans);
        
        // Wait for response
        monitor_mailbox.get(received_trans);
        
        // Check results
        if (received_trans.command == trans.RDID) begin
            $display("✓ Command correctly identified");
            
            // Check device ID bytes
            if (received_trans.device_id[0] == EXPECTED_MFG_ID &&
                received_trans.device_id[1] == EXPECTED_MEM_TYPE &&
                received_trans.device_id[2] == EXPECTED_DENSITY) begin
                
                $display("✓ Device ID correct: MFG=0x%02X, Type=0x%02X, Density=0x%02X",
                        received_trans.device_id[0], 
                        received_trans.device_id[1], 
                        received_trans.device_id[2]);
                pass_count++;
            end else begin
                $display("✗ Device ID incorrect: Got MFG=0x%02X, Type=0x%02X, Density=0x%02X",
                        received_trans.device_id[0], 
                        received_trans.device_id[1], 
                        received_trans.device_id[2]);
                $display("  Expected: MFG=0x%02X, Type=0x%02X, Density=0x%02X",
                        EXPECTED_MFG_ID, EXPECTED_MEM_TYPE, EXPECTED_DENSITY);
            end
        end else begin
            $display("✗ Command not correctly identified");
        end
    endtask
    
    // Test 2: Read Electronic Manufacturer & Device ID (90h command)
    task test_read_manufacturer_id();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 2: Read Manufacturer ID Command (90h) ---");
        test_count++;
        
        // Create REMS transaction
        trans = new();
        trans.command = trans.REMS;
        trans.address = 24'h000000; // Address for REMS command
        
        // Send transaction
        driver_mailbox.put(trans);
        
        // Wait for response
        monitor_mailbox.get(received_trans);
        
        // Check results
        if (received_trans.command == trans.REMS) begin
            $display("✓ REMS command correctly identified");
            
            // Check manufacturer and device ID
            if (received_trans.response_data.size() >= 2) begin
                if (received_trans.response_data[0] == EXPECTED_MFG_ID &&
                    received_trans.response_data[1] == 8'h14) begin // MX25L1605 device ID
                    
                    $display("✓ Manufacturer ID correct: MFG=0x%02X, Device=0x%02X",
                            received_trans.response_data[0],
                            received_trans.response_data[1]);
                    pass_count++;
                end else begin
                    $display("✗ Manufacturer ID incorrect: Got MFG=0x%02X, Device=0x%02X",
                            received_trans.response_data[0],
                            received_trans.response_data[1]);
                end
            end else begin
                $display("✗ Insufficient response data received");
            end
        end else begin
            $display("✗ REMS command not correctly identified");
        end
    endtask
    
    // Test 3: Read Electronic ID (ABh command)
    task test_read_electronic_id();
        spi_transaction trans;
        spi_transaction received_trans;
        
        $display("\n--- Test 3: Read Electronic ID Command (ABh) ---");
        test_count++;
        
        // Create RES transaction
        trans = new();
        trans.command = trans.RES;
        
        // Send transaction
        driver_mailbox.put(trans);
        
        // Wait for response
        monitor_mailbox.get(received_trans);
        
        // Check results
        if (received_trans.command == trans.RES) begin
            $display("✓ RES command correctly identified");
            pass_count++;
        end else begin
            $display("✗ RES command not correctly identified");
        end
    endtask
    
    // Report final results
    task report_results();
        real pass_rate = (real'(pass_count) / real'(test_count)) * 100.0;
        
        $display("\n" + {"="*50});
        $display("BASIC ID TEST RESULTS");
        $display({"="*50});
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", test_count - pass_count);
        $display("Pass Rate:   %0.1f%%", pass_rate);
        $display({"="*50});
        
        if (pass_count == test_count) begin
            $display("*** ALL BASIC ID TESTS PASSED! ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", test_count - pass_count);
        end
    endtask
    
    // Waveform dumping
    initial begin
        $dumpfile("test_basic_id.vcd");
        $dumpvars(0, test_basic_id);
    end
    
endmodule