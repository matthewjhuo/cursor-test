// SPI Transaction class for MX25L1605 verification
// Defines transaction items for SPI communication

class spi_transaction;
    
    // Command types
    typedef enum logic [7:0] {
        WREN = 8'h06,        // Write Enable
        WRDI = 8'h04,        // Write Disable
        RDID = 8'h9F,        // Read ID
        RDSR = 8'h05,        // Read Status
        WRSR = 8'h01,        // Write Status
        READ = 8'h03,        // Read Data
        FASTREAD = 8'h0B,    // Fast Read Data
        PARALLELMODE = 8'h55, // Parallel Mode
        SE1  = 8'h20,        // Sector Erase (4KB)
        SE2  = 8'hD8,        // Sector Erase (64KB)
        CE1  = 8'h60,        // Chip Erase
        CE2  = 8'hC7,        // Chip Erase
        PP   = 8'h02,        // Page Program
        DP   = 8'hB9,        // Deep Power Down
        EN4K = 8'hA5,        // Enter 4KB Sector
        EX4K = 8'hB5,        // Exit 4KB Sector
        RDP  = 8'hAB,        // Release from Deep Power Down
        RES  = 8'hAB,        // Read Electronic ID
        REMS = 8'h90         // Read Electronic Manufacturer & Device ID
    } cmd_type_e;
    
    // Transaction fields
    rand cmd_type_e command;
    rand logic [23:0] address;   // 24-bit address for 16MB
    rand logic [7:0] data[];     // Variable length data
    rand logic [7:0] status_reg; // Status register value
    rand int delay_cycles;       // Delay between operations
    
    // Control fields
    rand bit use_fast_read;
    rand bit use_parallel_mode;
    rand bit write_protection;
    rand bit hold_operation;
    
    // Response data
    logic [7:0] response_data[];
    logic [7:0] device_id[3];    // Manufacturer ID, Memory Type, Capacity
    logic [7:0] status_response;
    
    // Constraints
    constraint address_c {
        address < 24'h200000; // 2MB address space for MX25L1605
    }
    
    constraint data_size_c {
        data.size() inside {[1:256]}; // Page size is 256 bytes max
    }
    
    constraint delay_c {
        delay_cycles inside {[0:100]};
    }
    
    constraint command_weight_c {
        command dist {
            READ := 30,
            FASTREAD := 20,
            PP := 15,
            WREN := 10,
            WRDI := 5,
            SE1 := 5,
            SE2 := 3,
            RDSR := 7,
            RDID := 3,
            [DP:REMS] := 2
        };
    }
    
    // Constructor
    function new(string name = "spi_transaction");
        device_id[0] = 8'hC2; // Manufacturer ID (MXIC)
        device_id[1] = 8'h20; // Memory Type
        device_id[2] = 8'h15; // Memory Density (16Mb)
    endfunction
    
    // Convert to string for debug
    function string convert2string();
        string s;
        s = $sformatf("Command: %s, Address: 0x%06X", command.name(), address);
        if (data.size() > 0)
            s = {s, $sformatf(", Data Size: %0d", data.size())};
        return s;
    endfunction
    
    // Copy function
    function spi_transaction copy();
        spi_transaction t = new();
        t.command = this.command;
        t.address = this.address;
        t.data = this.data;
        t.status_reg = this.status_reg;
        t.delay_cycles = this.delay_cycles;
        t.use_fast_read = this.use_fast_read;
        t.use_parallel_mode = this.use_parallel_mode;
        t.write_protection = this.write_protection;
        t.hold_operation = this.hold_operation;
        return t;
    endfunction
    
endclass