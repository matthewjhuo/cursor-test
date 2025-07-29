// SPI Scoreboard for MX25L1605 verification
// Compares expected vs actual results and tracks verification progress

class spi_scoreboard;
    
    mailbox #(spi_transaction) expected_mailbox;
    mailbox #(spi_transaction) actual_mailbox;
    
    // Memory model for comparison
    logic [7:0] memory_model [logic [23:0]];
    logic [7:0] status_register;
    logic write_enable_latch;
    logic deep_power_down;
    logic enter_4k_mode;
    
    // Statistics
    int total_comparisons;
    int passed_tests;
    int failed_tests;
    
    // Device ID constants
    parameter logic [7:0] MANUFACTURER_ID = 8'hC2;
    parameter logic [7:0] MEMORY_TYPE = 8'h20;
    parameter logic [7:0] MEMORY_DENSITY = 8'h15;
    
    // Constructor
    function new(mailbox #(spi_transaction) expected_mailbox, 
                 mailbox #(spi_transaction) actual_mailbox);
        this.expected_mailbox = expected_mailbox;
        this.actual_mailbox = actual_mailbox;
        
        // Initialize memory model
        initialize_memory();
        
        // Initialize status
        status_register = 8'h00;
        write_enable_latch = 1'b0;
        deep_power_down = 1'b0;
        enter_4k_mode = 1'b0;
        
        total_comparisons = 0;
        passed_tests = 0;
        failed_tests = 0;
    endfunction
    
    // Initialize memory with 0xFF (erased state)
    function void initialize_memory();
        // Initialize all memory to 0xFF (typical flash erased state)
        for (int i = 0; i < (1 << 21); i++) begin // 2MB address space
            memory_model[i] = 8'hFF;
        end
    endfunction
    
    // Main scoreboard task
    task run();
        spi_transaction expected_trans, actual_trans;
        
        forever begin
            fork
                expected_mailbox.get(expected_trans);
                actual_mailbox.get(actual_trans);
            join
            
            compare_transactions(expected_trans, actual_trans);
        end
    endtask
    
    // Compare expected vs actual transactions
    task compare_transactions(spi_transaction expected, spi_transaction actual);
        bit match = 1'b1;
        string error_msg = "";
        
        total_comparisons++;
        
        // Check command
        if (expected.command != actual.command) begin
            match = 1'b0;
            error_msg = {error_msg, $sformatf("Command mismatch: Expected %s, Got %s; ", 
                       expected.command.name(), actual.command.name())};
        end
        
        // Check address for address-based commands
        if (needs_address(expected.command)) begin
            if (expected.address != actual.address) begin
                match = 1'b0;
                error_msg = {error_msg, $sformatf("Address mismatch: Expected 0x%06X, Got 0x%06X; ", 
                           expected.address, actual.address)};
            end
        end
        
        // Update internal model and check responses
        case (expected.command)
            expected.WREN: begin
                write_enable_latch = 1'b1;
                status_register[1] = 1'b1; // WEL bit
            end
            
            expected.WRDI: begin
                write_enable_latch = 1'b0;
                status_register[1] = 1'b0; // WEL bit
            end
            
            expected.RDID: begin
                // Check device ID response
                if (actual.device_id[0] != MANUFACTURER_ID ||
                    actual.device_id[1] != MEMORY_TYPE ||
                    actual.device_id[2] != MEMORY_DENSITY) begin
                    match = 1'b0;
                    error_msg = {error_msg, $sformatf("Device ID mismatch: Expected [0x%02X,0x%02X,0x%02X], Got [0x%02X,0x%02X,0x%02X]; ",
                               MANUFACTURER_ID, MEMORY_TYPE, MEMORY_DENSITY,
                               actual.device_id[0], actual.device_id[1], actual.device_id[2])};
                end
            end
            
            expected.RDSR: begin
                // Check status register response
                if (actual.status_response != status_register) begin
                    match = 1'b0;
                    error_msg = {error_msg, $sformatf("Status register mismatch: Expected 0x%02X, Got 0x%02X; ",
                               status_register, actual.status_response)};
                end
            end
            
            expected.WRSR: begin
                if (write_enable_latch) begin
                    status_register = (status_register & 8'h03) | (expected.status_reg & 8'hFC);
                    write_enable_latch = 1'b0;
                    status_register[1] = 1'b0; // Clear WEL
                end
            end
            
            expected.READ, expected.FASTREAD: begin
                // Check read data
                match = check_read_data(expected, actual, error_msg);
            end
            
            expected.PP: begin
                if (write_enable_latch) begin
                    // Program data to memory model
                    program_memory(expected.address, expected.data);
                    write_enable_latch = 1'b0;
                    status_register[1] = 1'b0; // Clear WEL
                    // Set WIP bit temporarily (in real device)
                    status_register[0] = 1'b1;
                    #1000; // Simulate program time
                    status_register[0] = 1'b0;
                end
            end
            
            expected.SE1: begin // 4KB sector erase
                if (write_enable_latch) begin
                    erase_4k_sector(expected.address);
                    write_enable_latch = 1'b0;
                    status_register[1] = 1'b0;
                end
            end
            
            expected.SE2: begin // 64KB sector erase
                if (write_enable_latch) begin
                    erase_64k_sector(expected.address);
                    write_enable_latch = 1'b0;
                    status_register[1] = 1'b0;
                end
            end
            
            expected.CE1, expected.CE2: begin // Chip erase
                if (write_enable_latch) begin
                    initialize_memory(); // Erase entire chip
                    write_enable_latch = 1'b0;
                    status_register[1] = 1'b0;
                end
            end
            
            expected.DP: begin
                deep_power_down = 1'b1;
            end
            
            expected.RDP: begin
                deep_power_down = 1'b0;
            end
            
            expected.EN4K: begin
                enter_4k_mode = 1'b1;
            end
            
            expected.EX4K: begin
                enter_4k_mode = 1'b0;
            end
        endcase
        
        // Report results
        if (match) begin
            passed_tests++;
            $display("[SCOREBOARD] %0t: PASS - Transaction #%0d: %s", 
                    $time, total_comparisons, expected.convert2string());
        end else begin
            failed_tests++;
            $error("[SCOREBOARD] %0t: FAIL - Transaction #%0d: %s\n  Error: %s", 
                  $time, total_comparisons, expected.convert2string(), error_msg);
        end
    endtask
    
    // Check if command needs address
    function bit needs_address(spi_transaction::cmd_type_e cmd);
        case (cmd)
            spi_transaction::READ, spi_transaction::FASTREAD, 
            spi_transaction::PP, spi_transaction::SE1, spi_transaction::SE2:
                return 1'b1;
            default:
                return 1'b0;
        endcase
    endfunction
    
    // Check read data against memory model
    function bit check_read_data(spi_transaction expected, spi_transaction actual, ref string error_msg);
        bit match = 1'b1;
        
        if (expected.data.size() != actual.response_data.size()) begin
            match = 1'b0;
            error_msg = {error_msg, $sformatf("Read data size mismatch: Expected %0d, Got %0d; ",
                       expected.data.size(), actual.response_data.size())};
            return match;
        end
        
        for (int i = 0; i < expected.data.size(); i++) begin
            logic [23:0] read_addr = expected.address + i;
            logic [7:0] expected_data = memory_model.exists(read_addr) ? memory_model[read_addr] : 8'hFF;
            
            if (actual.response_data[i] != expected_data) begin
                match = 1'b0;
                error_msg = {error_msg, $sformatf("Read data mismatch at addr 0x%06X: Expected 0x%02X, Got 0x%02X; ",
                           read_addr, expected_data, actual.response_data[i])};
            end
        end
        
        return match;
    endfunction
    
    // Program data to memory model
    function void program_memory(logic [23:0] start_addr, logic [7:0] data[]);
        for (int i = 0; i < data.size(); i++) begin
            logic [23:0] addr = start_addr + i;
            // Flash programming can only change 1s to 0s
            memory_model[addr] = memory_model[addr] & data[i];
        end
    endfunction
    
    // Erase 4KB sector
    function void erase_4k_sector(logic [23:0] addr);
        logic [23:0] sector_start = {addr[23:12], 12'h000};
        for (int i = 0; i < 4096; i++) begin
            memory_model[sector_start + i] = 8'hFF;
        end
    endfunction
    
    // Erase 64KB sector
    function void erase_64k_sector(logic [23:0] addr);
        logic [23:0] sector_start = {addr[23:16], 16'h0000};
        for (int i = 0; i < 65536; i++) begin
            memory_model[sector_start + i] = 8'hFF;
        end
    endfunction
    
    // Print final statistics
    function void print_final_stats();
        real pass_rate = (total_comparisons > 0) ? 
                        (real'(passed_tests) / real'(total_comparisons)) * 100.0 : 0.0;
        
        $display("\n" + {"="*60});
        $display("SCOREBOARD FINAL RESULTS");
        $display({"="*60});
        $display("Total Comparisons: %0d", total_comparisons);
        $display("Passed Tests:      %0d", passed_tests);
        $display("Failed Tests:      %0d", failed_tests);
        $display("Pass Rate:         %0.1f%%", pass_rate);
        $display({"="*60});
        
        if (failed_tests == 0) begin
            $display("*** ALL TESTS PASSED! ***");
        end else begin
            $display("*** %0d TESTS FAILED ***", failed_tests);
        end
    endfunction
    
endclass