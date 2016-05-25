/* exec_tb.sv - Top level testbench for unit level testing
 * of PDP8 Execution Unit.
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 *
 */
module exec_tb ();
wire clk, reset_n;

wire [`ADDR_WIDTH-1:0] PC_value;

wire [`ADDR_WIDTH-1:0] base_addr;
pdp8_pkg::pdp_mem_opcode_s pdp_mem_opcode;
pdp8_pkg::pdp_op7_opcode_s pdp_op7_opcode;


wire exec_rd_req;
wire [`ADDR_WIDTH-1:0] exec_rd_addr;
wire [`DATA_WIDTH-1:0] exec_rd_data;
wire exec_wr_req;
wire [`ADDR_WIDTH-1:0] exec_wr_addr;
wire [`DATA_WIDTH-1:0] exec_wr_data;

// Clock Generator
clkgen_driver iclocker (
    .clk(clk),
    .reset_n(reset_n)
);

// Stimuls Generator
ifd_bfd stimulator (
    .clk(clk),
    .reset_n(reset_n),
    .stall(stall),
    .PC_value(PC_value),
    .base_addr(base_addr),
    .pdp_mem_opcode(pdp_mem_opcode),
    .pdp_op7_opcode(pdp_op7_opcode)
);

// Execution Unit - Module Under Test
instr_exec mut (
   .clk(clk),
   .reset_n(reset_n),
   .base_addr(base_addr),
   .pdp_mem_opcode(pdp_mem_opcode),
   .pdp_op7_opcode(pdp_op7_opcode),
   .stall(stall),
   .PC_value(PC_value),
   .exec_wr_req(exec_wr_req),
   .exec_wr_addr(exec_wr_addr),
   .exec_wr_data(exec_wr_data),
   .exec_rd_req(exec_rd_req),
   .exec_rd_addr(exec_rd_addr),
   .exec_rd_data(exec_rd_data)
);

// Responder - Re-use of memory BFM
memory_pdp imemoryer (
    .clk(clk),
    .ifu_rd_req(1'b0),
    .ifu_rd_addr(12'h000),
    .ifu_rd_data(),
    .exec_rd_req(exec_rd_req),
    .exec_rd_addr(exec_rd_addr),
    .exec_rd_data(exec_rd_data),
    .exec_wr_req(exec_wr_req),
    .exec_wr_addr(exec_wr_addr),
    .exec_wr_data(exec_wr_data)
);

// Checker for execution unit interface
exec_unit_chkr exec_chkr (
    .clk,
    .reset_n,
    .base_addr,
    .pdp_mem_opcode,
    .pdp_op7_opcode,
    .stall,
    .PC_value,
    .exec_wr_req,
    .exec_wr_addr,
    .exec_wr_data,
    .exec_rd_req,
    .exec_rd_addr,
    .exec_rd_data,
    // Whitebox signals
    .wb_intAcc(mut.intAcc),
    .wb_intLink(mut.intLink)
);

endmodule
