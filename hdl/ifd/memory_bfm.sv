// =======================================================================
//   Department of Electrical and Computer Engineering
//   Portland State University
//
//   Course name:  ECE 510 - Pre-Silicon Validation
//   Term & Year:  Spring 2016
//   Instructor :  Tareque Ahmad
//
//   Project:      Hardware implementation of PDP8 
//                 Instruction Set Architecture (ISA) level simulator
//
//   Filename:     memory_bfm.sv
//   Description:  memory module for instruction decode interface of PDP-8
//   Created by:   Tareque Ahmad
//   Date:         May 08, 2016
//   Edited by:    Chip Wood
//   Date:         May 30, 2016
//
//   Copyright:    Tareque Ahmad 
// =======================================================================

module memory_pdp
  (
   // Global input
   input clk,

   input                    ifu_rd_req,
   input  [`ADDR_WIDTH-1:0] ifu_rd_addr,
   output [`DATA_WIDTH-1:0] ifu_rd_data

   );

   reg [`DATA_WIDTH-1:0] int_ifu_rd_data;
   reg [11:0] PDP_memory [0:4095];

   // Fill up the memory with known consecutive data
   integer k;
   initial begin
        for (k=0; k<4096; k=k+1)  begin
           //PDP_memory[k] = `DATA_WIDTH'bz;
           PDP_memory[k] = k;
        end
   end

   int file;
   // Fill the memory with values taken from a data file
   initial begin
      file = $fopen(`MEM_FILENAME, "r");
      if (file == 0)
         $display("\nError: Could not find file %s\n",`MEM_FILENAME);
      else
         $readmemh(`MEM_FILENAME,PDP_memory);
   end

   // Display the contents of memory
   integer l;
   initial begin
        $display("Contents of Mem after reading data file:");
        for (l=0; l<4096; l=l+1)  begin
           $display("%d:%h",l,PDP_memory[l]);
        end
   end

   //////////////////////////////////////////////////////////////////////////////////////////////
   // Process IFU read requests
   //////////////////////////////////////////////////////////////////////////////////////////////
   always_ff @(posedge clk) begin
      if (ifu_rd_req) begin
         int_ifu_rd_data    = PDP_memory[ifu_rd_addr];
      end
   end

   assign ifu_rd_data       = int_ifu_rd_data;

   int outfile;
   // dump memory to file
   final begin
      outfile = $fopen(`OUT_FILENAME, "w");
      if (outfile == 0)
         $display("\nError: Could not find file %s\n",`OUT_FILENAME);
      else
         $writememh(`OUT_FILENAME,PDP_memory);
   end



endmodule // memory_pdp
