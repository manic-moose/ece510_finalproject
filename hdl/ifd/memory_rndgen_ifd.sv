/*
 * memory_rndgen.sv - Module mimics some memory interface
 * for the instruction fetch unit. It will produce random
 * values for new reads, essentially generating itself as
 * the program runs.
 *
 * Author: Chip Wood chawood@pdx.edu
 *
 */
module memory_rndgen_ifd (
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

reg [3:0] isMemoryCmd;

always_ff @(posedge clk) begin
    if (ifu_rd_req) begin
        if (memArry.exists(ifu_rd_addr)) begin
            int_rd_data = memArry[ifu_rd_addr];
        end else begin
            // mem or op7 opcode?
            // lower chance for a memory command - there are way more op7 codes
            isMemoryCmd = $urandom_range(4'hF);
            
            if (isMemoryCmd == 1) begin // mem
                memArry[ifu_rd_addr] = $urandom_range({`DATA_WIDTH{1'b1}});
                memArry[ifu_rd_addr][`DATA_WIDTH-1:`DATA_WIDTH-3] = $urandom_range(5, 0);
                if (DEBUG) $display("mem mem code %p", memArry[ifu_rd_addr]);
            end
            else begin
                memArry[ifu_rd_addr] = $urandom_range({`DATA_WIDTH{1'b1}});
                memArry[ifu_rd_addr][`DATA_WIDTH-1:`DATA_WIDTH-3] = 'o7;
                if (DEBUG) $display("mem op7 code %p", memArry[ifu_rd_addr]);
            end
            int_rd_data =  memArry[ifu_rd_addr];
        end
        if (DEBUG) $display("mem returning int_rd_data = %o from addr = %o", int_rd_data, ifu_rd_addr);
    end
end
    
endmodule