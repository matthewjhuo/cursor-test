// SPI Monitor for MX25L1605 verification
// Monitors and captures SPI bus activity

class spi_monitor;
    
    virtual spi_interface.monitor vif;
    mailbox #(spi_transaction) monitor_mailbox;
    
    // Statistics
    int transaction_count;
    int error_count;
    
    // Constructor
    function new(virtual spi_interface.monitor vif, mailbox #(spi_transaction) monitor_mailbox);
        this.vif = vif;
        this.monitor_mailbox = monitor_mailbox;
        transaction_count = 0;
        error_count = 0;
    endfunction
    
    // Main monitor task
    task run();
        spi_transaction trans;
        
        forever begin
            @(negedge vif.cs_n); // Wait for chip select assertion
            
            trans = new();
            capture_transaction(trans);
            
            if (trans != null) begin
                transaction_count++;
                monitor_mailbox.put(trans);
                $display("[MONITOR] %0t: Captured transaction #%0d: %s", 
                        $time, transaction_count, trans.convert2string());
            end
        end
    endtask
    
    // Capture a complete SPI transaction
    task capture_transaction(ref spi_transaction trans);
        logic [7:0] command_byte;
        logic [23:0] address;
        logic [7:0] data_byte;
        int data_count;
        
        // Capture command byte
        capture_byte(command_byte);
        
        // Decode command and capture appropriate data
        case (command_byte)
            8'h06: begin // WREN
                trans.command = trans.WREN;
            end
            
            8'h04: begin // WRDI
                trans.command = trans.WRDI;
            end
            
            8'h9F: begin // RDID
                trans.command = trans.RDID;
                // Capture 3 bytes of device ID
                trans.response_data = new[3];
                for (int i = 0; i < 3; i++) begin
                    capture_byte(data_byte);
                    trans.response_data[i] = data_byte;
                end
            end
            
            8'h05: begin // RDSR
                trans.command = trans.RDSR;
                capture_byte(data_byte);
                trans.status_response = data_byte;
            end
            
            8'h01: begin // WRSR
                trans.command = trans.WRSR;
                capture_byte(data_byte);
                trans.status_reg = data_byte;
            end
            
            8'h03: begin // READ
                trans.command = trans.READ;
                capture_address(address);
                trans.address = address;
                capture_data_until_cs_high(trans);
            end
            
            8'h0B: begin // FAST READ
                trans.command = trans.FASTREAD;
                capture_address(address);
                trans.address = address;
                capture_byte(data_byte); // Dummy byte
                capture_data_until_cs_high(trans);
            end
            
            8'h02: begin // PAGE PROGRAM
                trans.command = trans.PP;
                capture_address(address);
                trans.address = address;
                capture_data_until_cs_high(trans);
            end
            
            8'h20: begin // SECTOR ERASE 4KB
                trans.command = trans.SE1;
                capture_address(address);
                trans.address = address;
            end
            
            8'hD8: begin // SECTOR ERASE 64KB
                trans.command = trans.SE2;
                capture_address(address);
                trans.address = address;
            end
            
            8'h60, 8'hC7: begin // CHIP ERASE
                trans.command = (command_byte == 8'h60) ? trans.CE1 : trans.CE2;
            end
            
            8'hB9: begin // DEEP POWER DOWN
                trans.command = trans.DP;
            end
            
            8'hAB: begin // RELEASE POWER DOWN / READ ID
                trans.command = trans.RDP;
            end
            
            8'hA5: begin // ENTER 4K MODE
                trans.command = trans.EN4K;
            end
            
            8'hB5: begin // EXIT 4K MODE
                trans.command = trans.EX4K;
            end
            
            8'h90: begin // READ MANUFACTURER ID
                trans.command = trans.REMS;
                // Skip 3 address bytes
                capture_byte(data_byte); // Addr[23:16]
                capture_byte(data_byte); // Addr[15:8]  
                capture_byte(data_byte); // Addr[7:0]
                // Capture manufacturer and device ID
                trans.response_data = new[2];
                capture_byte(data_byte);
                trans.response_data[0] = data_byte; // Manufacturer ID
                capture_byte(data_byte);
                trans.response_data[1] = data_byte; // Device ID
            end
            
            default: begin
                $warning("[MONITOR] Unknown command: 0x%02X", command_byte);
                error_count++;
                trans = null; // Invalid transaction
            end
        endcase
        
        // Wait for CS deassertion
        @(posedge vif.cs_n);
    endtask
    
    // Capture a single byte from SPI bus
    task capture_byte(output logic [7:0] data);
        for (int i = 7; i >= 0; i--) begin
            @(posedge vif.sclk);
            data[i] = vif.si;
        end
    endtask
    
    // Capture 24-bit address
    task capture_address(output logic [23:0] addr);
        logic [7:0] addr_byte;
        capture_byte(addr_byte);
        addr[23:16] = addr_byte;
        capture_byte(addr_byte);
        addr[15:8] = addr_byte;
        capture_byte(addr_byte);
        addr[7:0] = addr_byte;
    endtask
    
    // Capture data until CS goes high
    task capture_data_until_cs_high(ref spi_transaction trans);
        logic [7:0] data_queue[$];
        logic [7:0] data_byte;
        
        while (vif.cs_n == 1'b0) begin
            // Check if there's enough time for another byte
            fork
                begin
                    capture_byte(data_byte);
                    data_queue.push_back(data_byte);
                end
                begin
                    @(posedge vif.cs_n);
                end
            join_any
            disable fork;
        end
        
        // Convert queue to array
        trans.data = new[data_queue.size()];
        for (int i = 0; i < data_queue.size(); i++) begin
            trans.data[i] = data_queue[i];
        end
    endtask
    
    // Get statistics
    function void print_stats();
        $display("[MONITOR] Transaction Statistics:");
        $display("  Total Transactions: %0d", transaction_count);
        $display("  Errors: %0d", error_count);
        $display("  Success Rate: %0.1f%%", 
                (transaction_count > 0) ? 
                100.0 * (transaction_count - error_count) / transaction_count : 0.0);
    endfunction
    
endclass