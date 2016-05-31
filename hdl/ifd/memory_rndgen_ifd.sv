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
    
typedef logic [`ADDR_WIDTH-1:0] memAdx;
typedef logic [`DATA_WIDTH-1:0] memWrd;

memWrd memArry[memAdx];
    
memWrd int_rd_data;
assign ifu_rd_data = int_rd_data;

always_ff @(posedge clk) begin
    if (exec_rd_req) begin
        if (memArry.exists(exec_rd_addr)) begin
            int_rd_data = memArry[exec_rd_addr];
        end else begin
            memArry[exec_rd_addr] = $urandom();
            int_rd_data =  memArry[exec_rd_addr];
        end
    end
end
    
endmodule