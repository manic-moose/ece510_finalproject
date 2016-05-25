
// Import the package
module pdp_top ();

wire clk, reset_n;

wire stall;
wire [`ADDR_WIDTH-1:0] PC_value;

wire [`ADDR_WIDTH-1:0] base_addr;
pdp8_pkg::pdp_mem_opcode_s pdp_mem_opcode;
pdp8_pkg::pdp_op7_opcode_s pdp_op7_opcode;

wire ifu_rd_req;
wire [`ADDR_WIDTH-1:0] ifu_rd_addr;
wire [`DATA_WIDTH-1:0] ifu_rd_data;
wire exec_rd_req;
wire [`ADDR_WIDTH-1:0] exec_rd_addr;
wire [`DATA_WIDTH-1:0] exec_rd_data;
wire exec_wr_req;
wire [`ADDR_WIDTH-1:0] exec_wr_addr;
wire [`DATA_WIDTH-1:0] exec_wr_data;

clkgen_driver iclocker (
    .clk(clk),
    .reset_n(reset_n)
);

instr_decode idecoder (
    .clk(clk),
    .reset_n(reset_n),
    .stall(stall),
    .PC_value(PC_value),
    .ifu_rd_req(ifu_rd_req),
    .ifu_rd_addr(ifu_rd_addr),
    .ifu_rd_data(ifu_rd_data),
    .base_addr(base_addr),
    .pdp_mem_opcode(pdp_mem_opcode),
    .pdp_op7_opcode(pdp_op7_opcode)
);

instr_exec iexecutor (
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

memory_pdp imemoryer (
    .clk(clk),
    .ifu_rd_req(ifu_rd_req),
    .ifu_rd_addr(ifu_rd_addr),
    .ifu_rd_data(ifu_rd_data),
    .exec_rd_req(exec_rd_req),
    .exec_rd_addr(exec_rd_addr),
    .exec_rd_data(exec_rd_data),
    .exec_wr_req(exec_wr_req),
    .exec_wr_addr(exec_wr_addr),
    .exec_wr_data(exec_wr_data)
);


endmodule
