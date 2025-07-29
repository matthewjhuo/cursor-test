// Basic sequence for SPI Flash verification
// Generates various SPI command patterns for testing

class basic_sequence;
    
    mailbox #(spi_transaction) sequence_mailbox;
    int num_transactions;
    string sequence_name;
    
    // Constructor
    function new(string name = "basic_sequence", int num_trans = 50);
        sequence_name = name;
        num_transactions = num_trans;
    endfunction
    
    // Set mailbox
    function void set_mailbox(mailbox #(spi_transaction) mailbox_h);
        sequence_mailbox = mailbox_h;
    endfunction
    
    // Main sequence task
    virtual task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        // Generate and send transactions
        for (int i = 0; i < num_transactions; i++) begin
            spi_transaction trans = new();
            
            // Randomize transaction
            if (!trans.randomize()) begin
                $error("[SEQUENCE] Failed to randomize transaction %0d", i);
                continue;
            end
            
            // Send transaction
            sequence_mailbox.put(trans);
            $display("[SEQUENCE] Generated transaction %0d: %s", i+1, trans.convert2string());
        end
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass

// Read-focused sequence
class read_sequence extends basic_sequence;
    
    function new(string name = "read_sequence", int num_trans = 20);
        super.new(name, num_trans);
    endfunction
    
    task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        for (int i = 0; i < num_transactions; i++) begin
            spi_transaction trans = new();
            
            // Force read commands
            trans.command.rand_mode(0);
            if (i % 2 == 0)
                trans.command = trans.READ;
            else
                trans.command = trans.FASTREAD;
            
            // Randomize other fields
            if (!trans.randomize()) begin
                $error("[SEQUENCE] Failed to randomize read transaction %0d", i);
                continue;
            end
            
            sequence_mailbox.put(trans);
            $display("[SEQUENCE] Generated read transaction %0d: %s", i+1, trans.convert2string());
        end
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass

// Write-focused sequence  
class write_sequence extends basic_sequence;
    
    function new(string name = "write_sequence", int num_trans = 15);
        super.new(name, num_trans);
    endfunction
    
    task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        for (int i = 0; i < num_transactions; i++) begin
            spi_transaction trans = new();
            
            // Typical write sequence: WREN -> PP -> RDSR (check completion)
            case (i % 3)
                0: begin // Write Enable
                    trans.command.rand_mode(0);
                    trans.command = trans.WREN;
                end
                1: begin // Page Program
                    trans.command.rand_mode(0);
                    trans.command = trans.PP;
                    // Ensure reasonable data size for page program
                    trans.data_size_c.constraint_mode(0);
                    trans.data = new[256]; // Full page
                    for (int j = 0; j < 256; j++) begin
                        trans.data[j] = $urandom_range(0, 255);
                    end
                end
                2: begin // Read Status
                    trans.command.rand_mode(0);
                    trans.command = trans.RDSR;
                end
            endcase
            
            // Randomize other fields
            if (!trans.randomize()) begin
                $error("[SEQUENCE] Failed to randomize write transaction %0d", i);
                continue;
            end
            
            sequence_mailbox.put(trans);
            $display("[SEQUENCE] Generated write transaction %0d: %s", i+1, trans.convert2string());
        end
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass

// Erase-focused sequence
class erase_sequence extends basic_sequence;
    
    function new(string name = "erase_sequence", int num_trans = 12);
        super.new(name, num_trans);
    endfunction
    
    task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        for (int i = 0; i < num_transactions; i++) begin
            spi_transaction trans = new();
            
            // Typical erase sequence: WREN -> Erase -> RDSR
            case (i % 3)
                0: begin // Write Enable
                    trans.command.rand_mode(0);
                    trans.command = trans.WREN;
                end
                1: begin // Sector Erase
                    trans.command.rand_mode(0);
                    if (i % 6 < 3)
                        trans.command = trans.SE1; // 4KB erase
                    else
                        trans.command = trans.SE2; // 64KB erase
                end
                2: begin // Read Status
                    trans.command.rand_mode(0);
                    trans.command = trans.RDSR;
                end
            endcase
            
            // Randomize other fields
            if (!trans.randomize()) begin
                $error("[SEQUENCE] Failed to randomize erase transaction %0d", i);
                continue;
            end
            
            sequence_mailbox.put(trans);
            $display("[SEQUENCE] Generated erase transaction %0d: %s", i+1, trans.convert2string());
        end
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass

// ID and status sequence
class id_status_sequence extends basic_sequence;
    
    function new(string name = "id_status_sequence", int num_trans = 10);
        super.new(name, num_trans);
    endfunction
    
    task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        for (int i = 0; i < num_transactions; i++) begin
            spi_transaction trans = new();
            
            // Focus on ID and status commands
            trans.command.rand_mode(0);
            case (i % 4)
                0: trans.command = trans.RDID;
                1: trans.command = trans.RDSR;
                2: trans.command = trans.REMS;
                3: trans.command = trans.RES;
            endcase
            
            // Randomize other fields
            if (!trans.randomize()) begin
                $error("[SEQUENCE] Failed to randomize ID/status transaction %0d", i);
                continue;
            end
            
            sequence_mailbox.put(trans);
            $display("[SEQUENCE] Generated ID/status transaction %0d: %s", i+1, trans.convert2string());
        end
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass

// Power management sequence
class power_sequence extends basic_sequence;
    
    function new(string name = "power_sequence", int num_trans = 8);
        super.new(name, num_trans);
    endfunction
    
    task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        for (int i = 0; i < num_transactions; i++) begin
            spi_transaction trans = new();
            
            // Power management commands
            trans.command.rand_mode(0);
            case (i % 4)
                0: trans.command = trans.DP;    // Deep Power Down
                1: trans.command = trans.RDP;   // Release Power Down
                2: trans.command = trans.EN4K;  // Enter 4K mode
                3: trans.command = trans.EX4K;  // Exit 4K mode
            endcase
            
            // Randomize other fields
            if (!trans.randomize()) begin
                $error("[SEQUENCE] Failed to randomize power transaction %0d", i);
                continue;
            end
            
            sequence_mailbox.put(trans);
            $display("[SEQUENCE] Generated power transaction %0d: %s", i+1, trans.convert2string());
        end
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass

// Complex mixed sequence
class mixed_sequence extends basic_sequence;
    
    function new(string name = "mixed_sequence", int num_trans = 100);
        super.new(name, num_trans);
    endfunction
    
    task run();
        $display("[SEQUENCE] Starting %s with %0d transactions", sequence_name, num_transactions);
        
        // Create sub-sequences
        read_sequence    read_seq    = new("read_sub", 25);
        write_sequence   write_seq   = new("write_sub", 30);
        erase_sequence   erase_seq   = new("erase_sub", 21);
        id_status_sequence id_seq    = new("id_sub", 15);
        power_sequence   power_seq   = new("power_sub", 9);
        
        // Set mailboxes
        read_seq.set_mailbox(sequence_mailbox);
        write_seq.set_mailbox(sequence_mailbox);
        erase_seq.set_mailbox(sequence_mailbox);
        id_seq.set_mailbox(sequence_mailbox);
        power_seq.set_mailbox(sequence_mailbox);
        
        // Run sequences in parallel or sequentially
        fork
            begin
                id_seq.run();       // Start with ID check
                #1000;
                read_seq.run();     // Then reads
                #1000;
                write_seq.run();    // Then writes
                #1000;
                erase_seq.run();    // Then erases
                #1000;
                power_seq.run();    // Finally power management
            end
        join
        
        $display("[SEQUENCE] Completed %s", sequence_name);
    endtask
    
endclass