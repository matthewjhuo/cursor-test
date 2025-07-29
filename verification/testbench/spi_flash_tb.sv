// Main testbench for MX25L1605 SPI Flash verification
// Integrates all verification components and instantiates DUT

`timescale 1ns/1ps

// Include all verification files
`include "../interfaces/spi_interface.sv"
`include "../utils/spi_transaction.sv"
`include "../agents/spi_driver.sv"
`include "../agents/spi_monitor.sv"
`include "../scoreboard/spi_scoreboard.sv"
`include "../sequences/basic_sequence.sv"

module spi_flash_tb;

    // Clock and reset
    logic clk;
    logic reset_n;
    
    // Test control
    logic test_done;
    
    // Interface instantiation
    spi_interface spi_if(clk);
    
    // DUT instantiation - MX25L1605 Flash
    flash_16m dut (
        .SCLK(spi_if.sclk),
        .CS(~spi_if.cs_n),      // DUT expects active low CS
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
    
    // Verification environment components
    spi_driver driver;
    spi_monitor monitor;
    spi_scoreboard scoreboard;
    
    // Mailboxes for communication
    mailbox #(spi_transaction) driver_mailbox;
    mailbox #(spi_transaction) monitor_mailbox;
    mailbox #(spi_transaction) expected_mailbox;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz system clock
    end
    
    // Test environment setup
    initial begin
        // Initialize signals
        reset_n = 0;
        test_done = 0;
        
        // Create mailboxes
        driver_mailbox = new();
        monitor_mailbox = new();
        expected_mailbox = new();
        
        // Create verification components
        driver = new(spi_if.driver, driver_mailbox);
        monitor = new(spi_if.monitor, monitor_mailbox);
        scoreboard = new(expected_mailbox, monitor_mailbox);
        
        // Reset sequence
        #100;
        reset_n = 1;
        #100;
        
        // Start verification components
        fork
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none
        
        // Run test sequences
        run_test_sequences();
        
        // Wait for completion and report results
        wait_for_completion();
        report_final_results();
        
        test_done = 1;
        #1000;
        $finish;
    end
    
    // Task to run different test sequences
    task run_test_sequences();
        $display("\n" + {"="*80});
        $display("STARTING MX25L1605 SPI FLASH VERIFICATION");
        $display({"="*80});
        
        // Test 1: Basic ID and Status Check
        $display("\n--- Test 1: Basic ID and Status Check ---");
        run_id_status_test();
        
        // Test 2: Read Operations
        $display("\n--- Test 2: Read Operations Test ---");
        run_read_test();
        
        // Test 3: Write Operations  
        $display("\n--- Test 3: Write Operations Test ---");
        run_write_test();
        
        // Test 4: Erase Operations
        $display("\n--- Test 4: Erase Operations Test ---");
        run_erase_test();
        
        // Test 5: Power Management
        $display("\n--- Test 5: Power Management Test ---");
        run_power_test();
        
        // Test 6: Mixed Operations
        $display("\n--- Test 6: Mixed Operations Test ---");
        run_mixed_test();
        
        // Test 7: Stress Test
        $display("\n--- Test 7: Stress Test ---");
        run_stress_test();
        
        $display("\n--- All Test Sequences Completed ---");
    endtask
    
    // Individual test implementations
    task run_id_status_test();
        id_status_sequence id_seq = new("id_status_test", 15);
        id_seq.set_mailbox(driver_mailbox);
        
        fork
            id_seq.run();
            send_expected_transactions(id_seq);
        join
        
        #5000; // Wait for transactions to complete
    endtask
    
    task run_read_test();
        read_sequence read_seq = new("read_test", 25);
        read_seq.set_mailbox(driver_mailbox);
        
        fork
            read_seq.run();
            send_expected_transactions(read_seq);
        join
        
        #10000;
    endtask
    
    task run_write_test();
        write_sequence write_seq = new("write_test", 18);
        write_seq.set_mailbox(driver_mailbox);
        
        fork
            write_seq.run();
            send_expected_transactions(write_seq);
        join
        
        #15000;
    endtask
    
    task run_erase_test();
        erase_sequence erase_seq = new("erase_test", 15);
        erase_seq.set_mailbox(driver_mailbox);
        
        fork
            erase_seq.run();
            send_expected_transactions(erase_seq);
        join
        
        #20000;
    endtask
    
    task run_power_test();
        power_sequence power_seq = new("power_test", 12);
        power_seq.set_mailbox(driver_mailbox);
        
        fork
            power_seq.run();
            send_expected_transactions(power_seq);
        join
        
        #8000;
    endtask
    
    task run_mixed_test();
        mixed_sequence mixed_seq = new("mixed_test", 50);
        mixed_seq.set_mailbox(driver_mailbox);
        
        fork
            mixed_seq.run();
            send_expected_transactions(mixed_seq);
        join
        
        #25000;
    endtask
    
    task run_stress_test();
        basic_sequence stress_seq = new("stress_test", 100);
        stress_seq.set_mailbox(driver_mailbox);
        
        fork
            stress_seq.run();
            send_expected_transactions(stress_seq);
        join
        
        #50000;
    endtask
    
    // Task to send expected transactions to scoreboard
    task send_expected_transactions(basic_sequence seq);
        // This is a simplified version - in a real testbench,
        // you would duplicate the sequence generation logic
        // or use a more sophisticated prediction mechanism
        
        for (int i = 0; i < seq.num_transactions; i++) begin
            spi_transaction expected_trans = new();
            
            // Generate expected transaction (simplified)
            if (!expected_trans.randomize()) begin
                $error("Failed to generate expected transaction %0d", i);
                continue;
            end
            
            expected_mailbox.put(expected_trans);
            #100; // Small delay between transactions
        end
    endtask
    
    // Wait for all transactions to complete
    task wait_for_completion();
        int timeout_count = 0;
        int last_count = 0;
        
        // Wait for all transactions to be processed
        while (timeout_count < 1000) begin
            #1000;
            if (monitor.transaction_count == last_count) begin
                timeout_count++;
            end else begin
                timeout_count = 0;
                last_count = monitor.transaction_count;
            end
        end
        
        $display("\n[TESTBENCH] Verification completed with timeout or completion");
        $display("[TESTBENCH] Total transactions monitored: %0d", monitor.transaction_count);
    endtask
    
    // Report final verification results
    task report_final_results();
        $display("\n" + {"="*80});
        $display("FINAL VERIFICATION RESULTS");
        $display({"="*80});
        
        // Monitor statistics
        monitor.print_stats();
        
        // Scoreboard statistics  
        scoreboard.print_final_stats();
        
        $display({"="*80});
        $display("VERIFICATION SUMMARY:");
        if (scoreboard.failed_tests == 0) begin
            $display("*** VERIFICATION PASSED - ALL TESTS SUCCESSFUL ***");
        end else begin
            $display("*** VERIFICATION FAILED - %0d TESTS FAILED ***", scoreboard.failed_tests);
        end
        $display({"="*80});
    endtask
    
    // Timeout watchdog
    initial begin
        #1000000; // 1ms timeout
        if (!test_done) begin
            $error("TESTBENCH TIMEOUT - Test did not complete within 1ms");
            $finish;
        end
    end
    
    // Simulation control and waveform dumping
    initial begin
        // For iverilog VCD dump
        $dumpfile("spi_flash_sim.vcd");
        $dumpvars(0, spi_flash_tb);
        
        // Simulation messages
        $display("Starting MX25L1605 SPI Flash Verification");
        $display("Simulator: %s", `__FILE__);
        $display("Time: %0t", $time);
    end
    
    // Signal monitoring for debug
    always @(posedge spi_if.sclk) begin
        if (!spi_if.cs_n) begin
            $display("[DEBUG] %0t: SPI Active - CS_N=%b, SI=%b, SO=%b", 
                    $time, spi_if.cs_n, spi_if.si, spi_if.so);
        end
    end
    
endmodule