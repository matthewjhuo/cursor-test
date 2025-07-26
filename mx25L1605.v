/*----------------------------------------------------------------------------
*
*    mx25L1605.v - 16M-BIT CMOS Serial eLiteFlash EEPROM
*
*            COPYRIGHT 2004 Macronix International Co., Ltd.
*
*-----------------------------------------------------------------------------
*  Environment  : VCS
*  Author       : C.M. Wu 
*  Creation Date: 2004/10/18
*  VERSION      : V 0.02
*  Update Author: Tiddy Tang
*  Update Time  : REV.1.0, DEC. 19, 2006
*  Note         : This model does not include test mode 
*  Description  : 
*                 module flash_16m -> behavior model for the 16M serial flash
*                 If you define Memory initial file init.dat, Memory value is 
*                 defined by init.dat .Otherwise, Memory value is defined 'FF'. 
*-----------------------------------------------------------------------------
*/

`timescale 1ns / 1ns
      // Define controller state
      `define    STANDBY_STATE          0
      `define    ACTION_STATE           1
      `define    CMD_STATE              2
      `define    BAD_CMD_STATE          3
      `define    ERASE_TIME             1_000_000_000  //     1 s
      //`define    CHIP_ERASE_TIME           64_000_000  //    64 s
      `define    PROG_TIME                  3_000_000  //     3 ms
      // Time delay to write instruction 
      `define    PUW_TIME                  10_000_000  //    10 ms  

`define    MX25L1605 //MX25L1605 MX25L3205 MX25L3205A MX25L6405

`ifdef MX25L1605 
       `define    FLASH_ADDR  21
       `define    SECTOR_ADDR 5
       `define    CHIP_ERASE_TIME             32_000_000  //     32 s unit is  us  instead of ns
       `define    BPBIT_NUM                          3    //     Block Protect bits number

`else  
       `ifdef MX25L3205  
             `define    FLASH_ADDR  22
             `define    SECTOR_ADDR 6
             `define    CHIP_ERASE_TIME             64_000_000  //     64 s unit is  us  instead of ns
             `define    BPBIT_NUM                          3    //     Block Protect bits number

       `else
        `ifdef  MX25L6405
             `define    FLASH_ADDR  23
             `define    SECTOR_ADDR 7
             `define    CHIP_ERASE_TIME             128_000_000  //     128 s unit is  us  instead of ns
             `define    BPBIT_NUM                          4     //     Block Protect bits number
       `endif
       `endif  
`endif       


module flash_16m( SCLK, CS, SI, SO, PO0, PO1, PO2, PO3, PO4, PO5, PO6, WP, HOLD);

    //---------------------------------------------------------------------
    // Declaration of ports (input,output, inout)
    //---------------------------------------------------------------------
    input  SCLK,    // Signal of Clock Input
           CS,      // Chip select (Low active)
           SI,      // Serial Data Input
           WP,      // Write Protection:connect to GND
           HOLD;    // HOLD to pause the serial communication
    inout  SO,      // Serial Data Output // PO7/
           PO6,     // Parallel data output     
           PO5,     // Parallel data output
           PO4,     // Parallel data output
           PO3,     // Parallel data output
           PO2,     // Parallel data output
           PO1,     // Parallel data output
           PO0;     // Parallel data output
    //---------------------------------------------------------------------
    // Declaration of parameter (parameter)
    //---------------------------------------------------------------------
    parameter  FLASH_SIZE  = 1 << `FLASH_ADDR,  // 16M bytes
               SECTOR_SIZE = 1 << 16,           // 64K bytes
               FLASH_4kb_SIZE = 1 << 9,         // 4k bits
               tAA     = 12,                    // Access Time [ns],tAA = tSKH + tCLQ
               tC      = 20,                    // Clock Cycle Time,tC  = tSKH + tSKL 
               //tSKH   =  9,                   // Clock High Time
               //tSKL   =  9,                   // Clock Low Time
               tSHQZ   =  8,                    // CS High to SO Float Time [ns]
               tCLQV   =  8,                    // Clock Low to Output Valid
               tHHQX   =  8,                    //  HOLD to Output Low-z
               tHLQZ   =  8,                    //  HOLD to Output High-z
               tDP     =   3_000_000,           //   3 ms
               tRES1   =  30_000_000,           //  30 ms
               tRES2   =  30_000_000,           //  30 ms
               tW_min  =  90_000_000,           //  90 ms
               tW_max  = 500_000_000;           //  500 ms

    parameter init_file = "init.dat";
    parameter  [7:0]  ID_MXIC   = 8'hc2;                 
    parameter  [7:0]  MEMORY_Type    = 8'h20;    

    `ifdef MX25L1605
           parameter  [7:0]  ID_Device   = 8'h14;    // MX25L1605
           parameter  [7:0]  MEMORY_Density = 8'h15;
    `else 
           `ifdef MX25L3205
		  parameter  [7:0]  ID_Device   = 8'h15;    // MX25L3205
                  parameter  [7:0]  MEMORY_Density = 8'h16; // MX25L3205
           `else
                 `ifdef MX25L6405
                        parameter  [7:0]  ID_Device   = 8'h16;    // MX25L6405 
                        parameter  [7:0]  MEMORY_Density = 8'h17;  // MX25L6405 
                 `endif      
           `endif
    `endif
    
    
    parameter  [7:0]  WREN = 8'h06, //WriteEnable   = 8'h06,
                      WRDI = 8'h04, //WriteDisable  = 8'h04,
                      RDID = 8'h9F, //ReadID        = 8'h9f,
                      RDSR = 8'h05, //ReadStatus    = 8'h05,
                      WRSR = 8'h01, //WriteStatus   = 8'h01,
                      READ = 8'h03, //ReadData      = 8'h03,
                      FASTREAD = 8'h0b, //FastReadData  = 8'h0b,
                      PARALLELMODE = 8'h55, //PallelMode    = 8'h55,
                      SE1 = 8'h20, //SectorErase   = 8'h20,//8'hd8
                      SE2 = 8'hd8, //SectorErase   = 8'h20,//8'hd8
                      CE1 = 8'h60, //ChipErase     = 8'h60,//8'hc7
                      CE2 = 8'hc7, //ChipErase     = 8'h60,//8'hc7
                      PP = 8'h02, //PageProgram   = 8'h02,
                      DP = 8'hb9, //DeepPowerDown = 8'hb9,
                      EN4K = 8'ha5, //Enter4kbSector= 8'ha5,
                      EX4K = 8'hb5, //Exit4kbSector = 8'hb5,
                      RDP  = 8'hab, //ReleaseFromDeepPowerDwon = 8'hab,
                      RES  = 8'hab, //ReadElectricID = 8'hab,
                      REMS = 8'h90; //ReadElectricManufacturerDeviceID = 90;


    //---------------------------------------------------------------------
    // Declaration of internal-register (reg)
    //---------------------------------------------------------------------

    // memory array
    reg  [7:0]  	     	ROM_ARRAY    [ 0:FLASH_SIZE-1 ];
    reg  [7:0]       		ROM_4Kb_ARRAY[ 0:FLASH_4kb_SIZE-1];
    reg  [`FLASH_ADDR - 1 :0] 	Address;
    reg  [`FLASH_ADDR - 1 :0] 	rom_addr;
    reg  [256*8-1:0]    	si_reg;           // temp reg to store serial in
    reg  [256*8-1:0]		psi_reg;          // temp reg to store parallel in
    reg  [256*8-1:0]		dummy_A;          // page size
    reg  [`FLASH_ADDR - 9 :0]   	segment_addr;     // A[MSB:8] segment address
    reg  [7:0]               	offset_addr;      // A[7:0] means 256 bytes
    reg  [`SECTOR_ADDR - 1:0] 	sector;           // means sectors number

    reg  [7:0]       status_reg;       // Status Register
    reg  [2:0]       state;

    reg  ENB_S0,ENB_P0,ENB_S1,ENB_P1;
    //ENB_S0 fSCLK Serial AC Characteristics;
    //ENB_P0 fSCLK parallel AC Characteristics;
    //ENB_S1 fRSCLK Serial AC Characteristics;
    //ENB_P1 fRSCLK parallel AC Characteristics;
    
    reg  SO_reg;
    reg  PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0;
    reg  latch_SO,latch_PO6,latch_PO5,latch_PO4,latch_PO3,latch_PO2,latch_PO1,latch_PO0;
    reg  pmode;        // parallel mode
    reg  dpmode;       // deep power down mode
    reg  enter4kbmode; // enter 4kb mode
    reg  chip_erase_oe;
    integer i,chip_erase_count;

    /*-------------------------------------------------------*/
    /* interface control                                     */
    /*-------------------------------------------------------*/  
    reg  SCLK_EN;
    wire wp_reg;
    wire ISCLK; 
    wire HOLD_int;
    assign wp_reg   = WP;
    assign ISCLK    = (SCLK_EN==1'b1) ? SCLK:1'b0;
    assign HOLD_int = (CS==1'b0)      ? HOLD:1'b1;
   
    //assign SO = pp_p ? 8'bz : SO_reg;
    reg  SO_outEN;
    reg  DisSO_outENB;
    assign {PO6,PO5,PO4,PO3,PO2,PO1,PO0} = SO_outEN && pmode ? {PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} : 7'bz ;
    assign SO = SO_outEN && DisSO_outENB? SO_reg : 1'bz ;

    always @(SO or PO6 or PO5 or PO4 or PO3 or PO2 or PO1 or PO0) begin
          {latch_SO,latch_PO6,latch_PO5,latch_PO4,latch_PO3,latch_PO2,latch_PO1,latch_PO0} = {SO,PO6,PO5,PO4,PO3,PO2,PO1,PO0};
    end

    /*-------------------------------------------------------*/
    /*  initial variable value                               */
    /*-------------------------------------------------------*/    
    initial
    begin
         enter4kbmode  = 1'b0;
         dpmode        = 1'b0;
         pmode         = 1'b0;
         chip_erase_oe = 1'b0;
         chip_erase_count = 0;
         status_reg    = 8'b0000_0000;
         {ENB_S0,ENB_P0,ENB_S1,ENB_P1} = {1'b1,1'b0,1'b0,1'b0};
         i = 0;
         SCLK_EN=1'b1;
         SO_outEN=1'b0;
         DisSO_outENB=1'b1;
    end

    /*-------------------------------------------------------*/
    /*  initial flash data                                   */
    /*-------------------------------------------------------*/
    initial begin : memory_initialize
         for (i=0;i<FLASH_SIZE;i=i+1)
         ROM_ARRAY[i] = 8'hff; 
         if (init_file == "init.dat")
   	 $readmemh(init_file,ROM_ARRAY) ;
         for (i=0;i<FLASH_4kb_SIZE;i=i+1)
          ROM_4Kb_ARRAY[i] = 8'hff;
    end


    /*-------------------------------------------------------*/
    /*  latch signal SI into si_reg                          */
    /*-------------------------------------------------------*/
    always @( posedge SCLK ) begin
        if ( $time > `PUW_TIME ) begin
            if ( CS == 1'b0 ) begin
                { si_reg[ 256*8-1:0 ] } = { si_reg[ 256*8-2:0 ], SI };
            end
        end 
    end
    /*-------------------------------------------------------*/
    /*  chip erase process                                   */
    /*-------------------------------------------------------*/
    always @( posedge chip_erase_oe ) begin
        for ( chip_erase_count = 0;chip_erase_count<`CHIP_ERASE_TIME;chip_erase_count=chip_erase_count+1)
        begin
        #1000;
        end
        //WIP : write in process bit
        for( chip_erase_count = 0; chip_erase_count < FLASH_SIZE; chip_erase_count = chip_erase_count+1 )
        begin
            ROM_ARRAY[ chip_erase_count ] <= 8'hff;
        end
        chip_erase_count = 0;
        //WIP : write in process bit
        status_reg[0] <= 1'b0;//WIP
        //WEL : write enable latch
        status_reg[1] <= 1'b0;//WEL
        chip_erase_oe = 1'b0;
    end    


    /*-------------------------------------------------------*/
    /* When Hold Condtion Operation;                   */
    /*-------------------------------------------------------*/

     always @(HOLD_int) begin 
       if(pmode==1'b0) begin
         if(HOLD_int==1'b0) begin
            wait(SCLK==1'b0);
            SCLK_EN =1'b0;
            DisSO_outENB <= #tHLQZ 1'b0;
        end
        else begin
            wait(SCLK==1'b0);
            SCLK_EN =1'b1;
            DisSO_outENB <= #tHHQX 1'b1;
        end 
      end
    end

    /*-------------------------------------------------------*/
    /*  Finite state machine to control Flash operation      */
    /*-------------------------------------------------------*/
    wire WIP, WEL;
    wire discpers, diswrsr;    
    reg  [7:0]  CMD_REG;
  
    assign WIP   = status_reg[0] ;
    assign WEL   = status_reg[1] ;
    assign discpers  = status_reg[`BPBIT_NUM + 1:2]; 
    assign diswrsr   = wp_reg ==1'b0 && status_reg[7]==1'b1;

    always @( posedge ISCLK or posedge CS ) 
    begin
        if ( CS == 1'b1 ) begin    // Chip Disable
            state  <= #(tC-1) `STANDBY_STATE;
            SO_outEN <= #tSHQZ 1'b0;
        end
    end


    always @( posedge ISCLK ) 
    begin
        if ( CS == 1'b0 ) begin:CMD_DEC    // Chip Enable
            /*-------------------------------------------------------*/
            /*SI Decode                                              */
            /*-------------------------------------------------------*/
            case ( state )
                `STANDBY_STATE: begin
                    dummy_cycle( 6 );
                    state <= #(tC-1) `CMD_STATE;
                end

                `CMD_STATE: begin
                    #1
                    CMD_REG=si_reg[ 7:0 ];
                    if ( si_reg[ 7:0 ] == WREN && !dpmode && !WIP) begin
                        @(posedge ISCLK or posedge CS);
                        if(CS==1'b1) begin  
                           //$display( $stime, " Enter Write Enable Function ...");
                           write_enable;
                           //$display( $stime, " Leave Write Enable Function ...");
                           state <= `STANDBY_STATE;
                        end
                        else 
                           state <= `BAD_CMD_STATE;
                    end 

                    else if ( si_reg[ 7:0 ] == WRDI && !dpmode && !WIP) begin
                        @(posedge ISCLK or posedge CS);
                        if(CS==1'b1) begin  
                            //$display( $stime, " Enter Write Disable Function ...");
                            write_disable;
                            //$display( $stime, " Leave Write Disable Function ...");
                           state <= `STANDBY_STATE; 
                        end
                        else 
                           state <= `BAD_CMD_STATE;
                    end
                    
                    else if ( si_reg[ 7:0 ] == RDID && !dpmode && !WIP) begin
                        //$display( $stime, " Enter Read ID Function ...");
                        read_id;
                        //$display( $stime, " Leave Read ID Function ...");
                        state <= `STANDBY_STATE;                        
                    end

                    else if ( si_reg[ 7:0 ] == RDSR && !dpmode ) begin
                        //$display( $stime, " Enter Read Status Function ...");
                        read_status ;
                        //$display( $stime, " Leave Read Status Function ...");
                        state <= `STANDBY_STATE;                        
                    end

                    else if ( si_reg[ 7:0 ] == WRSR && !dpmode && !WIP && WEL && !enter4kbmode) begin
                        dummy_cycle( 8 );
                        if(diswrsr==0) begin
                           @(posedge ISCLK or posedge CS);
                          if(CS==1'b1) begin                         
                             //$display( $stime, " Enter Write Status Function ...");
                             write_status;
                             //$display( $stime, " Leave Write Status Function ...");
                             state <= `STANDBY_STATE;
                          end
                          else 
                             state <= `BAD_CMD_STATE;
                        end 
                        else   
                             state <= `BAD_CMD_STATE;
                                                 
                    end

                    else if ( si_reg[ 7:0 ] == READ && !dpmode && !WIP) begin
                        //$display( $stime, " Enter Read Data Function ...");
                        dummy_cycle( 23 );      // to get 24 bits address
                        @(negedge ISCLK);
                        SO_outEN=1'b1;
                        dummy_cycle(1);
                        #1 Address=si_reg[`FLASH_ADDR-1:0];
                        read_data;
                        //$display( $stime, " Leave Read Data Function ...");
                        state <= `STANDBY_STATE;                        
                    end

                    else if ( si_reg[ 7:0 ] == FASTREAD && !dpmode && !WIP && !pmode) begin
                        //$display( $stime, " Enter Fast Read Data Function ...");
                        dummy_cycle( 24 );      // to get 24 bits address
                        #1 Address=si_reg[`FLASH_ADDR-1:0];
                        fast_read_data;
                        //$display( $stime, " Leave Fast Read Data Function ...");
                        state <= `STANDBY_STATE;                        
                    end

                    else if ( si_reg[ 7:0 ] == PARALLELMODE && !dpmode && !WIP) begin
                        @(posedge ISCLK or posedge CS)
                        if(CS==1'b1) begin
                        //$display( $stime, " Enter Parallel Mode Function ...");
                        parallel_mode;
                        //$display( $stime, " Leave Parallel Mode Function ...");
                        state <= `STANDBY_STATE; 
                        end 
                        else 
                             state <= `BAD_CMD_STATE;
                    end

                    else if ( (si_reg[ 7:0 ] == SE1 || si_reg[ 7:0 ] == SE2 )  && !dpmode && !WIP && WEL ) begin
                        dummy_cycle( 24 );      // to get 24 bits address
                        #1 Address=si_reg[`FLASH_ADDR - 1:0];
                        if(protected_area(Address[`FLASH_ADDR - 1:16])==1'b0) begin
                           @(posedge ISCLK or posedge CS);
                           if(CS==1'b1) begin  
                           //$display( $stime, " Enter Sector Erase Function ...");
                           sector_erase;
                           //$display( $stime, " Leave Sector Erase Function ...");
                           state <= `STANDBY_STATE;   
                           end 
                          else 
                             state <= `BAD_CMD_STATE;
                        end
                        else  
                             state <= `BAD_CMD_STATE;
                    end

                    else if ( (si_reg[ 7:0 ] == CE1 || si_reg[ 7:0 ] == CE2) && !dpmode && !WIP && WEL &&!enter4kbmode) begin
                        if(discpers==0) begin
                           @(posedge ISCLK or posedge CS);
                           if(CS==1'b1) begin  
                           //$display( $stime, " Enter Chip Erase Function ...");
                           chip_erase;
                           //$display( $stime, " Leave Chip Erase Function ...");
                           state <= `STANDBY_STATE;
                           end 
                          else 
                             state <= `BAD_CMD_STATE;
                        end
                        else  
                             state <= `BAD_CMD_STATE;
                    end

                    else if ( si_reg[ 7:0 ] == PP && !dpmode && !WIP && WEL) begin
                        dummy_cycle( 24 );      // to get 24 bits address
                        #1 Address=si_reg[`FLASH_ADDR - 1:0];
                        if(protected_area(Address[`FLASH_ADDR - 1:16])==1'b0) begin
                        //$display( $stime, " Enter Page Program Function ...");
                        setup_addr( Address, segment_addr, offset_addr );
                        page_program( segment_addr, offset_addr );
                        update_array( segment_addr, offset_addr );
                        //$display( $stime, " Leave Page Program Function ...");
                        state <= `STANDBY_STATE;   
                        end
                        else begin
                           state <= `BAD_CMD_STATE;
                           @ (posedge CS)
                           state <= `STANDBY_STATE;
                        end  
                    end

                    else if ( si_reg[ 7:0 ] == DP && !WIP) begin
                         @(posedge ISCLK or posedge CS)
                         if(CS==1'b1) begin
                          //$display( $stime, " Enter Deep Power Dwon Function ...");
                          deep_power_down;
                          //$display( $stime, " Leave Deep Power Down Function ...");
                          state <= `STANDBY_STATE;
                         end
                         else 
                             state <= `BAD_CMD_STATE;
                    end

                    else if ( si_reg[ 7:0 ] == EN4K && !dpmode && !WIP ) begin
                         @(posedge ISCLK or posedge CS)
                         if(CS==1'b1) begin

                        //$display( $stime, " Enter Enter 4Kb Sector Function ...");
                        enter_4kb_sector;
                        //$display( $stime, " Leave Entor 4Kb Sector Function ...");
                        state <= `STANDBY_STATE;
                         end
                         else 
                             state <= `BAD_CMD_STATE;
                    end

                    else if ( si_reg[ 7:0 ] == EX4K && !dpmode && !WIP ) begin
                         @(posedge ISCLK or posedge CS)
                         if(CS==1'b1) begin
                        //$display( $stime, " Enter Exit 4Kb Sector Function ...");
                        exit_4kb_sector;
                        //$display( $stime, " Leave Exit 4Kb Sector Function ...");
                        state <= `STANDBY_STATE;
                         end
                         else 
                             state <= `BAD_CMD_STATE;
                    end

                    else if ( (si_reg[ 7:0 ] == RDP || si_reg[ 7:0 ] == RES) && !WIP) begin
                        //$display( $stime, " Enter Release from Deep Power Dwon Function ...");
                        release_from_deep_power_dwon;
                        //$display( $stime, " Leave Release from Deep Power Dwon Function ...");
                        state <= `STANDBY_STATE;
                    end

                    else if ( si_reg[ 7:0 ] == REMS && !dpmode && !WIP) begin
                        dummy_cycle ( 16 ); // 2 dummy cycle
                        dummy_cycle ( 7 );  // 1 AD
                        @(negedge ISCLK);  
                        SO_outEN=1'b1;
                        dummy_cycle ( 1 );  // 1 AD
                        //$display( $stime, " Enter Read Electronic Manufacturer & ID Function ...");
                        read_electronic_manufacturer_device_id;
                        //$display( $stime, " Leave Read Electronic Manufacturer & ID Function ...");
                        state <= `STANDBY_STATE;
                    end
                    
                    else begin
                        state <= #1 `BAD_CMD_STATE;
                    end
                end

                `BAD_CMD_STATE: begin
                    state <= #(tC-1) `BAD_CMD_STATE;
                end

                default: begin
                    state <= #(tC-1) `STANDBY_STATE;
                end
            endcase
        end  // else begin
    end  //  always @( posedge ISCLK or posedge CS ) begin

 
  
    //////////////////////////////////////////////////////////////////////
    //  Module Task Declaration
    //////////////////////////////////////////////////////////////////////
    /*---------------------------------------------------------------*/
    /*  Description: define a wait dummy cycle task                  */
    /*  INPUT                                                        */
    /*      cnum: cycle number                                       */
    /*---------------------------------------------------------------*/
     task dummy_cycle;
        input [31:0] cnum;

        begin
            repeat( cnum ) begin
                @( posedge ISCLK or CS);
                if(CS==1'b1)
                disable CMD_DEC;
            end
        end
    endtask
 
    /*---------------------------------------------------------------*/
    /*  Description: setup segment address and offset address from   */
    /*               4-byte serial input.                            */
    /*  INPUT                                                        */
    /*      si: 4-byte serial input                                  */
    /*  OUTPUT                                                       */
    /*      segment: segment address                                 */
    /*      offset : offset address                                  */
    /*---------------------------------------------------------------*/
    task setup_addr;
        input  [23:0] si;
        output [15:0] segment;
        output [7:0]  offset;

        begin
            #1;
            { offset[ 7:0 ] }   = { si_reg[ 7:0 ] };
            { segment[ 15:0 ] } = { si_reg[`FLASH_ADDR - 1:8 ] };
        end
    endtask

    /*---------------------------------------------------------------*/
    /*  Description: define a write enable task                      */
    /*---------------------------------------------------------------*/
    task write_enable;
        begin
           //$display( $stime, " Old Status Register = %b", status_reg );
           status_reg[1] = 1'b1; 
           //$display( $stime, " New Status Register = %b", status_reg );
        end
    endtask

    
    /*---------------------------------------------------------------*/
    /*  Description: define a write disable task (WRDI)              */
    /*---------------------------------------------------------------*/
    task write_disable;
        begin
           //$display( $stime, " Old Status Register = %b", status_reg );
           status_reg[1] = 1'b0; 
           //$display( $stime, " New Status Register = %b", status_reg );
        end
    endtask
    
   

    /*---------------------------------------------------------------*/
    /*  Description: define a read id task (RDID)                    */
    /*---------------------------------------------------------------*/
    task read_id;
        reg  [ 23:0 ] dummy_ID;
        integer dummy_count;
        begin
            dummy_ID = {ID_MXIC,MEMORY_Type,MEMORY_Density};
            dummy_count = 0;
            SO_outEN = 1'b1;
            forever begin
                @( negedge ISCLK or posedge CS );
                if ( CS == 1'b1 ) begin
                    SO_outEN <=#tSHQZ 1'b0;
                    disable read_id;
                end
                else begin
                     //SO_outEN = 1'b1;
                     if ( pmode == 1'b0) begin // check parallel mode (2)
                           { SO_reg, dummy_ID } <= #tCLQV { dummy_ID, dummy_ID[ 23 ] };
                     end
                     else begin
                         if ( dummy_count == 0 ) begin
                             {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} <= #tCLQV ID_MXIC;
                             dummy_count = 1;
                         end    
                         else if ( dummy_count == 1 ) begin    
                             {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} <= #tCLQV MEMORY_Type;
                             dummy_count = 2;
                         end
                         else if ( dummy_count == 2 ) begin                         
                             {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} <= #tCLQV MEMORY_Density;
                             dummy_count = 0;
                         end    
                     end
                end
            end  // end forever
        end
    endtask

    
    /*---------------------------------------------------------------*/
    /*  Description: define a read status task (WRSR)                */
    /*---------------------------------------------------------------*/
    task read_status;
        integer dummy_count;
        begin
            dummy_count = 8;
            SO_outEN = 1'b1; 
            forever begin
                @( negedge ISCLK or posedge CS );
                if ( CS == 1'b1 ) begin
                    SO_outEN <=#tSHQZ 1'b0;
                    disable read_status;
                end
                else begin
                        //SO_outEN = 1'b1;
                        if ( pmode == 1'b0 ) begin
                            if (dummy_count) begin
                                 dummy_count = dummy_count - 1;
                                 SO_reg <= #tCLQV status_reg[dummy_count];
                            end
                            else begin
                                      dummy_count = 7;
                                      SO_reg<= #tCLQV status_reg[dummy_count];
                            end          
                        end
                        else begin 
                                  {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} <= #tCLQV status_reg;
                        end
                end
            end  // end forever
        end
    endtask


    /*---------------------------------------------------------------*/
    /*  Description: define a write status task                      */
    /*---------------------------------------------------------------*/
     task write_status;
        begin
            //$display( $stime, " Old Status Register = %b", status_reg );
            if( (status_reg[7] == si_reg[7] ) && (status_reg[`BPBIT_NUM+1:2] == si_reg[`BPBIT_NUM+1:2] )) begin
               //WIP:Write Enable Latch
               status_reg[0]   <= 1'b1;
               status_reg[0]   <= #tW_min 1'b0;
               //WEL:Write Enable Latch
               status_reg[1]   <= #tW_min 1'b0;
            end   
            else begin
               //SRWD:Status Register Write Protect
               status_reg[7]   <= #tW_max si_reg[7];
               status_reg[`BPBIT_NUM+1:2] <= #tW_max si_reg[`BPBIT_NUM+1:2];
               //WIP:Write Enable Latch
               status_reg[0]   <= 1'b1;
               status_reg[0]   <= #tW_max 1'b0;
               //WEL:Write Enable Latch
               status_reg[1]   <= #tW_max 1'b0;
            end
            //$display( $stime, " New Status Register = %b", status_reg );
        end
    endtask
   

 
    /*---------------------------------------------------------------*/
    /*  Description: define a read data task                         */
    /*---------------------------------------------------------------*/
    task read_data;
       // reg  [`FLASH_ADDR - 1:0]      rom_addr;    // rom_addr = {segment, offset}
        integer dummy_count, tmp_int;
        reg  [7:0]       out_buf;
        begin
            dummy_count = 8;
            rom_addr = (enter4kbmode==1)?si_reg[8:0]:si_reg[`FLASH_ADDR - 1:0];
            out_buf =  (enter4kbmode==1)?ROM_4Kb_ARRAY[rom_addr]:ROM_ARRAY[rom_addr];
            
            forever begin
                @( negedge ISCLK or posedge CS);
                if ( CS == 1'b1 ) begin
                    if (pmode == 0) begin
                        {ENB_S0,ENB_P0,ENB_S1,ENB_P1} = {1'b1,1'b0,1'b0,1'b0};
                    end    
                    else begin
                        {ENB_S0,ENB_P0,ENB_S1,ENB_P1} = {1'b0,1'b1,1'b0,1'b0};
                    end
                    SO_outEN <= #tSHQZ 1'b0;
                    disable read_data;
                end 
                else  begin 
              //     SO_outEN  = 1'b1;
                   if ( pmode == 1'b0) begin
                        {ENB_S0,ENB_P0,ENB_S1,ENB_P1} = {1'b0,1'b0,1'b1,1'b0};
                        if ( dummy_count ) begin
                                 { SO_reg, out_buf } <=#tCLQV { out_buf, out_buf[6] };
                                 dummy_count = dummy_count - 1;
                        end
                        else begin
                                  rom_addr = rom_addr + 1;
                                  rom_addr = (enter4kbmode==1)?rom_addr[8:0]:rom_addr;
                                  out_buf  = (enter4kbmode==1)?ROM_4Kb_ARRAY[rom_addr]:ROM_ARRAY[rom_addr];
                                  { SO_reg, out_buf } <=#tCLQV  { out_buf, out_buf[6] };
                                  dummy_count = 7 ;
                        end
                   end
                   else begin
                              {ENB_S0,ENB_P0,ENB_S1,ENB_P1} = {1'b0,1'b0,1'b0,1'b1};
                              out_buf  = (enter4kbmode==1)?ROM_4Kb_ARRAY[rom_addr]:ROM_ARRAY[rom_addr];
                              {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} 
                              <= #tCLQV {out_buf};
                              rom_addr = rom_addr + 1;
                              rom_addr = (enter4kbmode==1)?rom_addr[8:0]:rom_addr;
                    end
                end 
            end  // end forever

        end   
    endtask


 
    /*---------------------------------------------------------------*/
    /*  Description: define a fast read data task                    */
    /*               0B AD1 AD2 AD3 X                                */
    /*---------------------------------------------------------------*/
    task fast_read_data;

       // reg  [`FLASH_ADDR - 1:0]      rom_addr;    // rom_addr = {segment, offset}
        integer dummy_count, tmp_int;
        reg  [7:0]       out_buf;
       // reg  SO_reg_tmp;       
        begin
            dummy_count = 8;
            rom_addr = (enter4kbmode==1)?si_reg[8:0]:si_reg[`FLASH_ADDR - 1:0];
            out_buf =  (enter4kbmode==1)?ROM_4Kb_ARRAY[rom_addr]:ROM_ARRAY[rom_addr];

            dummy_cycle( 7 );
            @( negedge ISCLK);
            SO_outEN = 1'b1;
            dummy_cycle( 1 );

           forever begin
                @( negedge ISCLK or posedge CS);
                if ( CS == 1'b1 ) begin
		    SO_outEN <= #tSHQZ 1'b0;
                    disable fast_read_data;
                end 
                else begin //do work on non deep power down mode
                   //SO_outEN = 1'b1;
                      if ( dummy_count ) begin
                               { SO_reg, out_buf } <=#tCLQV  { out_buf, out_buf[6] };
                               dummy_count = dummy_count - 1;
                      end
                      else begin
                                rom_addr = rom_addr + 1;
                                rom_addr = (enter4kbmode==1)?rom_addr[8:0]:rom_addr;
                                out_buf  = (enter4kbmode==1)?ROM_4Kb_ARRAY[rom_addr]:ROM_ARRAY[rom_addr];
                                { SO_reg, out_buf } <=#tCLQV { out_buf, out_buf[6] };
                                dummy_count = 7 ;
                      end
                end    
            end  // end forever
        end   
    endtask


    
    /*---------------------------------------------------------------*/
    /*  Description: define a parallel mode task                     */
    /*---------------------------------------------------------------*/
    task parallel_mode;
        begin
           //$display( $stime, " Old Pmode Register = %b", pmode );
           pmode = 1;
           {ENB_S0,ENB_P0,ENB_S1,ENB_P1} = {1'b0,1'b1,1'b0,1'b0};
           //$display( $stime, " New Pmode Register = %b", pmode );
        end
    endtask

    /*---------------------------------------------------------------*/
    /*  Description: define a sector erase task                      */
    /*               20(D8) AD1 AD2 AD3                              */
    /*---------------------------------------------------------------*/
        task sector_erase;
        reg [`SECTOR_ADDR - 1:0] sector; 
        reg [11:0] offset; // 64K Byte

        integer i, start_addr,end_addr,start_4kb_addr,end_4kb_addr;
        begin
           sector     =Address[`FLASH_ADDR - 1:16]; 
           start_addr = (Address[`FLASH_ADDR - 1:16]<<16) + 16'h0000;
           end_addr   = (Address[`FLASH_ADDR - 1:16]<<16) + 16'hffff;  
           start_4kb_addr = 9'h000;
           end_4kb_addr   = 9'h1ff;              
           //WIP : write in process bit
           status_reg[0] =  1'b1;
           if ( enter4kbmode == 1'b0 ) begin // enter4kbmode = 1'b0
              for( i = start_addr; i <=end_addr; i = i + 1 )
              begin
                  ROM_ARRAY[ i ] <= #`ERASE_TIME 8'hff;
              end
           end 
           else begin // on enter4kbmode
              if ( si_reg[21:9]==0 ) begin // A21~A9=0 , A8~A0 customer defined
                  for( i = start_4kb_addr; i <= end_4kb_addr; i = i + 1 )
                  begin
                      ROM_4Kb_ARRAY[ i ] <= #`ERASE_TIME 8'hff;
                  end
              end    
           end
   
           //WIP : write in process bit
           status_reg[0] <=  #`ERASE_TIME 1'b0;//WIP
           //WEL : write enable latch
           status_reg[1] <=  #`ERASE_TIME 1'b0;//WEL
         end
    endtask


    /*---------------------------------------------------------------*/
    /*  Description: define a chip erase task                        */
    /*               60(C7)                                          */
    /*---------------------------------------------------------------*/
      task chip_erase;
           integer i;
     
           begin
               // WIP : write in process bit
                chip_erase_oe = 1'b1;
                status_reg[0] <= 1'b1;
                //for( i = 0; i < FLASH_SIZE; i = i+1 )
                //begin
                //    ROM_ARRAY[ i ] <= #`CHIP_ERASE_TIME 8'hff;
                //end
                ////WIP : write in process bit
                //status_reg[0] <=  #`CHIP_ERASE_TIME 1'b0;//WIP
                ////WEL : write enable latch
                //status_reg[1] <=  #`CHIP_ERASE_TIME 1'b0;//WEL
           end
      endtask

    /*---------------------------------------------------------------*/
    /*  Description: define a page program task                      */
    /*               02 AD1 AD2 AD3                                  */
    /*---------------------------------------------------------------*/
      task page_program;
        input  [`FLASH_ADDR - 9:0]      segment;
        input  [7:0]       offset;
        integer dummy_count, tmp_int, i;

        begin
            dummy_count = 256;    // page size
            //offset[7:0] = 8'h00;  // the start address of the page
            rom_addr[`FLASH_ADDR - 1:0] =(enter4kbmode==1)?{segment[0],offset[7:0]}:{ segment[`FLASH_ADDR - 9:0 ],offset[7:0] };
            
            /*------------------------------------------------*/
            /*  Store 256 bytes into a temp buffer - dummy_A  */
            /*------------------------------------------------*/
            while ( dummy_count ) begin
                rom_addr[`FLASH_ADDR - 1:0 ] =(enter4kbmode==1)?{segment[0],offset[7:0]}:{ segment[`FLASH_ADDR - 9:0 ],offset[7:0] };
                dummy_count = dummy_count - 1;
                tmp_int = dummy_count << 3;    /* transfer byte to bit */
                { dummy_A[ tmp_int+7 ], dummy_A[ tmp_int+6 ],
                  dummy_A[ tmp_int+5 ], dummy_A[ tmp_int+4 ],
                  dummy_A[ tmp_int+3 ], dummy_A[ tmp_int+2 ],
                  dummy_A[ tmp_int+1 ], dummy_A[ tmp_int ] } 
                  =(enter4kbmode==1)?ROM_4Kb_ARRAY[rom_addr ]:ROM_ARRAY[ rom_addr ];
                offset = offset + 1;
            end
            tmp_int = 0;
            forever begin
                @( posedge ISCLK or posedge CS );
                if ( CS == 1'b1 ) begin
                   if ( pmode == 1'b0 && tmp_int % 8 !==0) begin 
                       disable CMD_DEC;
                   end
                   else  begin
                       tmp_int=(tmp_int>256*8)?256*8:tmp_int;
                       if ( pmode == 1'b0 ) begin
                                   for( i = 1; i <= tmp_int; i=i+1 ) begin
                                       //$display( $stime, " dummy_A %d = %d ",  256*8-i,dummy_A[ 256*8-i ] );
                                       if( dummy_A[ 256*8-i ] == 1'b1 ) begin // 1 -> 1 ,1 -> 0
                                          dummy_A[ 256*8-i ] = si_reg[ tmp_int-i ];
                                       end
                                   end
                       end    
                       else begin
                                   for( i = 1; i <= tmp_int; i=i+1 ) begin
                                     if( dummy_A[ 256*8-i ] == 1'b1 ) begin // 1 -> 1 ,1 -> 0
                                         dummy_A[ 256*8-i ] = psi_reg[ tmp_int-i ];
                                     end
                                   end
                      
                               //  for( i = 1; i <= tmp_int; i=i+8 ) begin
                               //      if( dummy_A[ 256*8-i-0 ] == 1'b1 ) begin
                               //         dummy_A[ 256*8-i-0 ] = psi_reg[ tmp_int-i-0 ];
                               //      end
                               //      if( dummy_A[ 256*8-i-1 ] == 1'b1 ) begin
                               //         dummy_A[ 256*8-i-1 ] = psi_reg[ tmp_int-i-1 ];
                               //      end   
                               //      if( dummy_A[ 256*8-i-2 ] == 1'b1 ) begin
                               //         dummy_A[ 256*8-i-2 ] = psi_reg[ tmp_int-i-2 ];
                               //      end   
                               //      if( dummy_A[ 256*8-i-3 ] == 1'b1 ) begin
                               //         dummy_A[ 256*8-i-3 ] = psi_reg[ tmp_int-i-3 ];
                               //      end   
                               //      if( dummy_A[ 256*8-i-4 ] == 1'b1 ) begin
                               //         dummy_A[ 256*8-i-4 ] = psi_reg[ tmp_int-i-4 ];
                               //      end
                               //      if( dummy_A[ 256*8-i-5 ] == 1'b1 ) begin 
                               //         dummy_A[ 256*8-i-5 ] = psi_reg[ tmp_int-i-5 ];
                               //      end   
                               //      if( dummy_A[ 256*8-i-6 ] == 1'b1 ) begin 
                               //         dummy_A[ 256*8-i-6 ] = psi_reg[ tmp_int-i-6 ];
                               //      end
                               //      if( dummy_A[ 256*8-i-7 ] == 1'b1 ) begin 
                               //         dummy_A[ 256*8-i-7 ] = psi_reg[ tmp_int-i-7 ];
                               //      end
                               //  end
                       end
                       disable page_program;
                   end
                end
                else begin  // count how many bits been shifted
                        if ( pmode == 1'b0 ) begin
                              tmp_int = tmp_int + 1;
                        end    
                        else begin
                            { psi_reg[ 256*8-1:0 ] } = { psi_reg[ 256*8-9:0 ],{latch_SO,latch_PO6,latch_PO5,latch_PO4,latch_PO3,latch_PO2,latch_PO1,latch_PO0}};
                            tmp_int = tmp_int + 8;
                        end
                end
            end  // end forever
        end
    endtask




    
    /*---------------------------------------------------------------*/
    /*  Description: define a deep power down (DP)                   */
    /*---------------------------------------------------------------*/
    task deep_power_down;
        begin
            //$display( $stime, " Old DP Mode Register = %b", dpmode );
            if (dpmode == 1'b0)
             dpmode <= #tDP 1'b1;
            //$display( $stime, " New DP Mode Register = %b", dpmode );
        end
    endtask

    /*---------------------------------------------------------------*/
    /*  Description: define a enter 4kb sector task                  */
    /*---------------------------------------------------------------*/
    task enter_4kb_sector;
        begin
            //$display( $stime, " Old Enter 4kb Sector Register = %b", enter4kbmode );
            enter4kbmode = 1;
            //$display( $stime, " New Enter 4kb Sector Register = %b", enter4kbmode );
        end
    endtask
    
    /*---------------------------------------------------------------*/
    /*  Description: define a exit 4kb sector task                   */
    /*---------------------------------------------------------------*/
    task exit_4kb_sector;
        begin
            //$display( $stime, " Old Enter 4kb Sector Register = %b", enter4kbmode );
            enter4kbmode = 0;
        end
    endtask

    /*---------------------------------------------------------------*/
    /*  Description: define a release from deep power dwon task (RDP)*/
    /*---------------------------------------------------------------*/
     task release_from_deep_power_dwon;
        begin
            //$display( $stime, " Old DP Mode Register = %b", dpmode );
             @( posedge ISCLK or posedge CS );
               if( CS == 1'b1) begin
                  if (dpmode==1'b1) dpmode <= #tRES1 1'b0;
                  //$display( $stime, " New DP Mode Register = %b", dpmode );
               end 
               else begin
                         //$display( $stime, " Enter Read Electronic ID Function ...");
                         dummy_cycle( 22 );
                         @( negedge ISCLK); 
                         SO_outEN = 1'b1;
                         dummy_cycle( 1 );
                         read_electronic_id;
                         //$display( $stime, " Leave Read Electronic ID Function ...");
               end
        end
    endtask
   
    /*---------------------------------------------------------------*/
    /*  Description: define a read electronic ID (RES)               */
    /*               AB X X X                                        */
    /*---------------------------------------------------------------*/
    task read_electronic_id;
        reg  [ 7:0 ] dummy_ID;
        begin
            //$display( $stime, " Old DP Mode Register = %b", dpmode );
            dummy_ID = ID_Device;
            forever begin
             @( negedge ISCLK or posedge CS );
               if( CS == 1'b1 ) begin
                  SO_outEN <= #tSHQZ 1'b0;   
                  if (dpmode==1'b1) dpmode <= #tRES2 1'b0;
                  //$display( $stime, " New DP Mode Register = %b", dpmode );    
                  disable read_electronic_id;
               end 
               else begin
                    //SO_outEN = 1'b1; 
                    if ( pmode == 1'b0 ) begin
                        { SO_reg, dummy_ID } <=  #tCLQV { dummy_ID, dummy_ID[ 7 ] };
                    end 
                    else begin
                        {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} <= #tCLQV ID_Device; 
                    end
               end
            end // end forever   
        end
    endtask



    /*---------------------------------------------------------------*/
    /*  Description: define a read electronic manufacturer & device ID */
    /*---------------------------------------------------------------*/
    task read_electronic_manufacturer_device_id;
        reg  [ 15:0 ] dummy_ID;
        integer dummy_count;
        begin
            //$width(negedge SCLK,1);
            //$period( posedge SCLK, tCY );    // SCLK _/~ -> _/~
            #1;  
            if ( si_reg[0]==1'b0 ) begin
                dummy_ID = {ID_MXIC,ID_Device};
            end
            else begin
                dummy_ID = {ID_Device,ID_MXIC};
            end
            dummy_count = 0;
            forever begin
                @( negedge ISCLK or posedge CS );
                if ( CS == 1'b1 ) begin
                       SO_outEN <= #tSHQZ 1'b0; 
                    disable read_electronic_manufacturer_device_id;
                end
                else begin
                     //SO_outEN = 1'b1;
                     if ( pmode == 1'b0) begin // check parallel mode (2)
                         { SO_reg, dummy_ID } <=  #tCLQV { dummy_ID, dummy_ID[ 15 ] };
                     end    
                     else begin
                         if ( dummy_count == 0 ) begin
                             {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} =  #tCLQV dummy_ID[15:8];
                             dummy_count = 1;
                         end
                         else begin
                             {SO_reg,PO_reg6,PO_reg5,PO_reg4,PO_reg3,PO_reg2,PO_reg1,PO_reg0} =  #tCLQV dummy_ID[7:0];
                             dummy_count = 0;
                         end
                     end
                end
            end  // end forever
        end
    endtask

    
    /*---------------------------------------------------------------*/
    /*  Description: define a program chip task                      */
    /*  INPUT                                                        */
    /*      segment: segment address                                 */
    /*      offset : offset address                                  */
    /*---------------------------------------------------------------*/
    task update_array;
        input [`FLASH_ADDR -9:0] segment;
        input [7:0]  offset;
        integer dummy_count, tmp_int;
        reg   [`SECTOR_ADDR - 1:0]  sector;
        begin
            dummy_count = 256;
            rom_addr = {segment, offset};
            /*------------------------------------------------*/
            /*  Store 256 bytes back to ROM Page              */
            /*------------------------------------------------*/
            // initial start rom addrress
            // offset = 8'h00;
            rom_addr[`FLASH_ADDR - 1:0] = enter4kbmode?{segment[0],offset[7:0]}:{ segment[`FLASH_ADDR -9:0 ],offset[7:0] };
            // in write operation
            status_reg[0]= 1'b1;
            // not in write operation after PROG_TIME
            status_reg[0]<= #`PROG_TIME 1'b0;
            // WEL : write enable latch
            status_reg[1]<= #`PROG_TIME 1'b0;
            while ( dummy_count ) begin
                   rom_addr[`FLASH_ADDR - 1:0] = enter4kbmode?{segment[0],offset[7:0]}:{ segment[`FLASH_ADDR -9:0 ],offset[7:0] };
                   dummy_count = dummy_count - 1;
                   tmp_int = dummy_count << 3; /* byte to bit */ 
                   if (enter4kbmode == 1'b0) 
                   ROM_ARRAY[ rom_addr ] <=#`PROG_TIME 
                   { dummy_A[ tmp_int+7 ], dummy_A[ tmp_int+6 ],
                     dummy_A[ tmp_int+5 ], dummy_A[ tmp_int+4 ],
                     dummy_A[ tmp_int+3 ], dummy_A[ tmp_int+2 ],
                     dummy_A[ tmp_int+1 ], dummy_A[ tmp_int ] };
                   else
                   ROM_4Kb_ARRAY[ rom_addr ] <= #`PROG_TIME
                   { dummy_A[ tmp_int+7 ], dummy_A[ tmp_int+6 ],
                     dummy_A[ tmp_int+5 ], dummy_A[ tmp_int+4 ],
                     dummy_A[ tmp_int+3 ], dummy_A[ tmp_int+2 ],
                     dummy_A[ tmp_int+1 ], dummy_A[ tmp_int ] };
                   offset = offset + 1;
            end
        end
    endtask


    /*---------------------------------------------------------------*/
    /*  Description: define a protected_area area function           */
    /*  INPUT                                                        */
    /*      sector : sector address                                  */
    /*---------------------------------------------------------------*/    
    function protected_area;
        input [7:0]  sector;
    begin
        `ifdef MX25L1605
            if (status_reg[5:2]==4'b0000) begin
                protected_area = 1'b0;
            end
            else if (status_reg[5:2]==4'b0001) begin
                     if (sector[`SECTOR_ADDR - 1:0] == 31) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0010) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 30 && sector[`SECTOR_ADDR - 1:0] <= 31) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0011) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 28 && sector[`SECTOR_ADDR - 1:0] <= 31) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0100) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 24 && sector[`SECTOR_ADDR - 1:0] <= 31) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end            
            else if (status_reg[5:2]==4'b0101) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 16 && sector[`SECTOR_ADDR - 1:0] <= 31) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else begin
                        protected_area = 1'b1;                     
            end
       `else
            `ifdef MX25L3205  
            if (status_reg[5:2]==4'b0000) begin
                protected_area = 1'b0;
            end
            else if (status_reg[5:2]==4'b0001) begin
                     if (sector[`SECTOR_ADDR - 1:0] == 63) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0010) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 62 && sector[`SECTOR_ADDR - 1:0] <= 63) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0011) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 60 && sector[`SECTOR_ADDR - 1:0] <= 63) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0100) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 56 && sector[`SECTOR_ADDR - 1:0] <= 63) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0101) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 48 && sector[`SECTOR_ADDR - 1:0] <= 63) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else if (status_reg[5:2]==4'b0110) begin
                     if (sector[`SECTOR_ADDR - 1:0] >= 32 && sector[`SECTOR_ADDR - 1:0] <= 63) begin
                        protected_area = 1'b1;
                     end   
                     else begin
                        protected_area = 1'b0;
                     end
            end
            else begin
                        protected_area = 1'b1;                     
            end      
            `else
                 `ifdef MX25L6405
                       if (status_reg[5:2]==4'b0000) begin
                           protected_area = 1'b0;
                       end
                       else if (status_reg[5:2]==4'b0001) begin
                                if (sector[`SECTOR_ADDR - 1:0] == 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end
                       else if (status_reg[5:2]==4'b0010) begin
                                if (sector[`SECTOR_ADDR - 1:0] >= 126 && sector[`SECTOR_ADDR - 1:0] <= 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end
                       else if (status_reg[5:2]==4'b0011) begin
                                if (sector[`SECTOR_ADDR - 1:0] >= 124 && sector[`SECTOR_ADDR - 1:0] <= 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end
                       else if (status_reg[5:2]==4'b0100) begin
                                if (sector[`SECTOR_ADDR - 1:0] >= 120 && sector[`SECTOR_ADDR - 1:0] <= 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end
                       else if (status_reg[5:2]==4'b0101) begin
                                if (sector[`SECTOR_ADDR - 1:0] >= 112 && sector[`SECTOR_ADDR - 1:0] <= 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end
                       else if (status_reg[5:2]==4'b0110) begin
                                if (sector[`SECTOR_ADDR - 1:0] >=  96 && sector[`SECTOR_ADDR - 1:0] <= 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end
                       else if (status_reg[5:2]==4'b0111) begin
                                if (sector[`SECTOR_ADDR - 1:0] >= 64 && sector[`SECTOR_ADDR - 1:0] <= 127) begin
                                   protected_area = 1'b1;
                                end   
                                else begin
                                   protected_area = 1'b0;
                                end
                       end         
                       else begin
                                protected_area = 1'b1;
                       end
                  `endif     
            `endif
        `endif
    end
    endfunction
    //////////////////////////////////////////////////////////////////////
    // AC Timing Check Section
    //////////////////////////////////////////////////////////////////////
    specify

        //======================================================
        // AC Timing Parameter
        //======================================================
        specparam  tSLCH   = 5,     // CS Lead Clock Time (min) [ns]
                   tCHSL   = 5,     // CS Lag Clock Time (min) [ns]
                   tSHSL   = 100,   // CS High Time (min) [ns]
                   tDVCH   = 2,     // SI Setup Time (min) [ns]
                   tCHDX   = 5,     // SI Hold Time (min) [ns]
                   tCHSH   = 5,     // CS# Active Hold Time (relative to SCLK) (min) [ns]
                   tSHCH   = 5,     // CS# Not Active Setup Time (relative to SCLK) (min) [ns]
                   tHLCH   = 5,     // HOLD#  Setup Time (relative to SCLK) (min) [ns]               
                   tCHHH   = 5,     // HOLD#  Hold  Time (relative to SCLK) (min) [ns]              
                   tHHCH   = 5,     // HOLD  Setup Time (relative to SCLK) (min) [ns]                    
                   tCHHL   = 5,     // HOLD  Hold  Time (relative to SCLK) (min) [ns]                    
                   tWHSL   = 20,    //Write Protection Setup Time                
                   tSHWL   = 100;   //Write Protection Hold  Time  

        //======================================================
        // Timing Check
        //======================================================
           $width ( posedge  CS   , tSHSL );      // CS _/~\_
          
           $setup ( SI, posedge SCLK &&& ~CS,  tDVCH );
           $hold  ( posedge SCLK &&& ~CS, SI,  tCHDX );

           $setup    ( negedge CS, posedge SCLK &&& ~CS, tSLCH );
           $hold     ( posedge SCLK &&& ~CS, posedge CS, tCHSH );
     

           $setup    ( posedge CS, posedge SCLK &&& CS, tSHCH );
           $hold     ( posedge  SCLK &&& CS, negedge CS, tCHSL );


           $setup ( negedge HOLD &&& ~CS, posedge SCLK &&& ~CS,  tHLCH );
           $hold  ( posedge SCLK &&& ~CS, posedge HOLD &&& ~CS,  tCHHH );

           $setup ( posedge HOLD &&& ~CS, posedge SCLK &&& ~CS,  tHHCH );
           $hold  ( posedge SCLK &&& ~CS, negedge HOLD &&& ~CS,  tCHHL );

           $setup ( negedge WP, negedge CS,  tWHSL );
           $hold  ( posedge CS, posedge WP,  tSHWL );

    endspecify
    
   
    timing_S0 u1 (.SCLK(SCLK && ENB_S0),.ENB(ENB_S0));
    timing_P0 u2 (.SCLK(SCLK && ENB_P0),.ENB(ENB_P0));
    timing_S1 u3 (.SCLK(SCLK && ENB_S1),.ENB(ENB_S1));
    timing_P1 u4 (.SCLK(SCLK && ENB_P1),.ENB(ENB_P1));
endmodule  // serial16m

module timing_S0( SCLK, ENB);

    //---------------------------------------------------------------------
    // Declaration of ports (input,output, inout)
    //---------------------------------------------------------------------
    input  SCLK;    // Signal of Clock Input
    input  ENB; 
    //////////////////////////////////////////////////////////////////////
    // AC Timing Check Section
    //////////////////////////////////////////////////////////////////////
    specify
        //======================================================
        // AC Timing Parameter
        //======================================================
        specparam  tCYC    = 20,    // Clock Cycle Time [ns]
                   tCH     = 10,    // Clock High Time (min) [ns]
                   tCL     = 10;    // Clock Low Time (min) [ns]
        //======================================================
        // Timing Check
        //======================================================
           $period( posedge  SCLK , tCYC  );    // SCLK _/~ -> _/~
           $period( negedge  SCLK , tCYC  );    // SCLK ~\_ -> ~\_
           $width ( posedge  SCLK , tCH   );    // SCLK _/~~\_
           $width ( negedge  SCLK , tCL   );    // SCLK ~\__/~
    endspecify
endmodule

module timing_P0( SCLK, ENB);

    //---------------------------------------------------------------------
    // Declaration of ports (input,output, inout)
    //---------------------------------------------------------------------
    input  SCLK;    // Signal of Clock Input
    input  ENB;       
    //////////////////////////////////////////////////////////////////////
    // AC Timing Check Section
    //////////////////////////////////////////////////////////////////////
    specify
        //======================================================
        // AC Timing Parameter
        //======================================================
        specparam  tCYC    = 666,   // Clock Cycle Time [ns]
                   tCH     = 180,   // Clock High Time (min) [ns]
                   tCL     = 180;   // Clock Low Time (min) [ns]
        //======================================================
        // Timing Check
        //======================================================
           $period( posedge  SCLK , tCYC  );    // SCLK _/~ -> _/~
           $period( negedge  SCLK , tCYC  );    // SCLK ~\_ -> ~\_
           $width ( posedge  SCLK , tCH   );    // SCLK _/~~\_
           $width ( negedge  SCLK , tCL   );    // SCLK ~\__/~
    endspecify
endmodule

module timing_S1( SCLK, ENB);

    //---------------------------------------------------------------------
    // Declaration of ports (input,output, inout)
    //---------------------------------------------------------------------
    input  SCLK;    // Signal of Clock Input
    input  ENB;       
    //////////////////////////////////////////////////////////////////////
    // AC Timing Check Section
    //////////////////////////////////////////////////////////////////////
    specify
        //======================================================
        // AC Timing Parameter
        //======================================================
        specparam  tCYC    = 50,    // Clock Cycle Time [ns]
                   tCH     = 10,    // Clock High Time (min) [ns]
                   tCL     = 10;    // Clock Low Time (min) [ns]
        //======================================================
        // Timing Check
        //======================================================
           $period( posedge  SCLK , tCYC  );    // SCLK _/~ -> _/~
           $period( negedge  SCLK , tCYC  );    // SCLK ~\_ -> ~\_
           $width ( posedge  SCLK , tCH   );    // SCLK _/~~\_
           $width ( negedge  SCLK , tCL   );    // SCLK ~\__/~
    endspecify           
endmodule

module timing_P1( SCLK, ENB);

    //---------------------------------------------------------------------
    // Declaration of ports (input,output, inout)
    //---------------------------------------------------------------------
    input  SCLK;    // Signal of Clock Input
    input  ENB;       
    //////////////////////////////////////////////////////////////////////
    // AC Timing Check Section
    //////////////////////////////////////////////////////////////////////
    specify
        //======================================================
        // AC Timing Parameter
        //======================================================
        specparam  tCYC    = 833,    // Clock Cycle Time [ns]
                   tCH     = 180,    // Clock High Time (min) [ns]
                   tCL     = 180;    // Clock Low Time (min) [ns]
        //======================================================
        // Timing Check
        //======================================================
           $period( posedge  SCLK , tCYC  );    // SCLK _/~ -> _/~
           $period( negedge  SCLK , tCYC  );    // SCLK ~\_ -> ~\_
           $width ( posedge  SCLK , tCH   );    // SCLK _/~~\_
           $width ( negedge  SCLK , tCL   );    // SCLK ~\__/~
    endspecify
endmodule



