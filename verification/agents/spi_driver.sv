// SPI Driver for MX25L1605 verification
// Converts transactions to actual SPI signal sequences

class spi_driver;
    
    virtual spi_interface.driver vif;
    mailbox #(spi_transaction) driver_mailbox;
    
    // Constructor
    function new(virtual spi_interface.driver vif, mailbox #(spi_transaction) driver_mailbox);
        this.vif = vif;
        this.driver_mailbox = driver_mailbox;
    endfunction
    
    // Main driver task
    task run();
        spi_transaction trans;
        
        // Initialize signals
        init_signals();
        
        forever begin
            driver_mailbox.get(trans);
            $display("[DRIVER] %0t: Executing transaction: %s", $time, trans.convert2string());
            
            // Execute the transaction
            case (trans.command)
                trans.WREN: send_write_enable();
                trans.WRDI: send_write_disable();
                trans.RDID: send_read_id(trans);
                trans.RDSR: send_read_status(trans);
                trans.WRSR: send_write_status(trans);
                trans.READ: send_read_data(trans);
                trans.FASTREAD: send_fast_read(trans);
                trans.PP: send_page_program(trans);
                trans.SE1: send_sector_erase_4k(trans);
                trans.SE2: send_sector_erase_64k(trans);
                trans.CE1, trans.CE2: send_chip_erase();
                trans.DP: send_deep_power_down();
                trans.RDP: send_release_power_down();
                trans.EN4K: send_enter_4k_mode();
                trans.EX4K: send_exit_4k_mode();
                trans.REMS: send_read_manufacturer_id(trans);
                default: $error("[DRIVER] Unknown command: %s", trans.command.name());
            endcase
            
            // Add delay if specified
            if (trans.delay_cycles > 0) begin
                repeat(trans.delay_cycles) @(posedge vif.sclk);
            end
        end
    endtask
    
    // Initialize signals
    task init_signals();
        vif.cs_n = 1'b1;
        vif.si = 1'b0;
        vif.wp_n = 1'b1;
        vif.hold_n = 1'b1;
        vif.reset_n = 1'b1;
        repeat(10) @(posedge vif.sclk);
    endtask
    
    // Send a byte over SPI
    task send_byte(input logic [7:0] data);
        vif.cs_n = 1'b0;
        for (int i = 7; i >= 0; i--) begin
            @(negedge vif.sclk);
            vif.si = data[i];
            @(posedge vif.sclk);
        end
    endtask
    
    // Receive a byte over SPI
    task receive_byte(output logic [7:0] data);
        for (int i = 7; i >= 0; i--) begin
            @(posedge vif.sclk);
            data[i] = vif.so;
        end
    endtask
    
    // Send address (24-bit)
    task send_address(input logic [23:0] addr);
        send_byte(addr[23:16]); // High byte
        send_byte(addr[15:8]);  // Middle byte
        send_byte(addr[7:0]);   // Low byte
    endtask
    
    // Command implementations
    task send_write_enable();
        send_byte(8'h06);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_write_disable();
        send_byte(8'h04);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_read_id(spi_transaction trans);
        logic [7:0] id_data;
        send_byte(8'h9F);
        // Read 3 bytes of ID
        for (int i = 0; i < 3; i++) begin
            receive_byte(id_data);
            trans.device_id[i] = id_data;
        end
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_read_status(spi_transaction trans);
        logic [7:0] status;
        send_byte(8'h05);
        receive_byte(status);
        trans.status_response = status;
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_write_status(spi_transaction trans);
        send_byte(8'h01);
        send_byte(trans.status_reg);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_read_data(spi_transaction trans);
        logic [7:0] read_data;
        send_byte(8'h03);
        send_address(trans.address);
        
        // Read specified amount of data
        trans.response_data = new[trans.data.size()];
        for (int i = 0; i < trans.data.size(); i++) begin
            receive_byte(read_data);
            trans.response_data[i] = read_data;
        end
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_fast_read(spi_transaction trans);
        logic [7:0] read_data;
        send_byte(8'h0B);
        send_address(trans.address);
        send_byte(8'h00); // Dummy byte for fast read
        
        // Read specified amount of data
        trans.response_data = new[trans.data.size()];
        for (int i = 0; i < trans.data.size(); i++) begin
            receive_byte(read_data);
            trans.response_data[i] = read_data;
        end
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_page_program(spi_transaction trans);
        send_byte(8'h02);
        send_address(trans.address);
        
        // Send data to program
        for (int i = 0; i < trans.data.size(); i++) begin
            send_byte(trans.data[i]);
        end
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_sector_erase_4k(spi_transaction trans);
        send_byte(8'h20);
        send_address(trans.address);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_sector_erase_64k(spi_transaction trans);
        send_byte(8'hD8);
        send_address(trans.address);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_chip_erase();
        send_byte(8'h60);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_deep_power_down();
        send_byte(8'hB9);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_release_power_down();
        send_byte(8'hAB);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_enter_4k_mode();
        send_byte(8'hA5);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_exit_4k_mode();
        send_byte(8'hB5);
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
    task send_read_manufacturer_id(spi_transaction trans);
        logic [7:0] id_data;
        send_byte(8'h90);
        send_byte(8'h00); // Address byte 1
        send_byte(8'h00); // Address byte 2
        send_byte(8'h00); // Address byte 3
        
        // Read manufacturer and device ID
        receive_byte(id_data);
        trans.device_id[0] = id_data;
        receive_byte(id_data);
        trans.device_id[1] = id_data;
        
        vif.cs_n = 1'b1;
        @(posedge vif.sclk);
    endtask
    
endclass