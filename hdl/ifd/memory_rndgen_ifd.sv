/*
 * memory_rndgen.sv - Module mimics some memory interface
 * for the instruction fetch unit. It will produce random
 * values for new reads, essentially generating itself as
 * the program runs.
 *
 * Author: Chip Wood chawood@pdx.edu
 *
 */
module memory_rndgen (
    // Global input
   input clk,

   input                    ifu_rd_req,
   input  [`ADDR_WIDTH-1:0] ifu_rd_addr,
   output [`DATA_WIDTH-1:0] ifu_rd_data
);

localparam DEBUG = 0;
    
typedef logic [`ADDR_WIDTH-1:0] memAdx;
typedef logic [`DATA_WIDTH-1:0] memWrd;

memWrd memArry[memAdx];
    
memWrd int_rd_data;
assign ifu_rd_data = int_rd_data;

integer isMemoryCmd;

always_ff @(posedge clk) begin
    if (ifu_rd_req) begin
        if (memArry.exists(ifu_rd_addr)) begin
            int_rd_data = memArry[ifu_rd_addr];
        end else begin
            // mem or op7 opcode?
            // 10% chance for a memory command - way more op7 codes, focus on those
            isMemoryCmd = $urandom_range(10);
            
            if (isMemoryCmd == 1) begin // mem
                if (DEBUG) $display("mem mem code");
                memArry[ifu_rd_addr] = $urandom();
                memArry[ifu_rd_addr][`DATA_WIDTH-1:`DATA_WIDTH-3] = $urandom_range(5);
            end
            else begin
                if (DEBUG) $display("mem op7 code");
                memArry[ifu_rd_addr] = $urandom();
                memArry[ifu_rd_addr][`DATA_WIDTH-1:`DATA_WIDTH-3] = 'o7;
            end
            int_rd_data =  memArry[ifu_rd_addr];
        end
        if (DEBUG) $display("mem returning int_rd_data = %o from addr = %o", int_rd_data, ifu_rd_addr);
    end
end
    
endmodule