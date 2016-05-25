/* memory_rndgen.sv - Module mimics some memory interface
 * for the execution unit. It will save any memory written to it
 * and produce random values for new reads (and saving the new read).
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 *
 */
module memory_rndgen (
    // Global input
   input clk,

   input                    exec_rd_req,
   input  [`ADDR_WIDTH-1:0] exec_rd_addr,
   output [`DATA_WIDTH-1:0] exec_rd_data,

   input                    exec_wr_req,
   input  [`ADDR_WIDTH-1:0] exec_wr_addr,
   input  [`DATA_WIDTH-1:0] exec_wr_data
);
    
typedef logic [`ADDR_WIDTH-1:0] memAdx;
typedef logic [`DATA_WIDTH-1:0] memWrd;

memWrd memArry[memAdx];
    
memWrd int_rd_data;
assign exec_rd_data = int_rd_data;

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

always_ff @(posedge clk) begin
    if (exec_wr_req) begin
        memArry[exec_wr_addr] = exec_wr_data;
    end
end
    
endmodule