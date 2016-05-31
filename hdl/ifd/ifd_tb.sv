
module ifd_tb();

// global signals
wire clk, reset_n;

// memory interface
wire                    ifu_rd_req;
wire [`ADDR_WIDTH-1:0]  ifu_rd_addr;
wire [`ADDR_WIDTH-1:0]  ifu_rd_data;

// instruction decode and execute interface
wire                    stall;
wire [`ADDR_WIDTH-1:0]  PC_value;
wire [`ADDR_WIDTH-1:0]  base_addr;
wire pdp_mem_opcode_s   pdp_mem_opcode;
wire pdp_op7_opcode_s   pdp_op7_opcode;
    
// Clock Generator
clkgen_driver iclocker (clk, reset_n);

// Stimulus Generator
exec_bfm stimulator (clk, reset_n,
                stall, PC_value,
                base_addr, pdp_mem_opcode, pdp_op7_opcode);

// Responder (memory simulator)
memory_rndgen mem (clk,
                ifu_rd_req, ifu_rd_addr, ifu_rd_data);

// DUT - design under test
instr_decode dut (clk, reset_n,
                stall, PC_value,
                base_addr, pdp_mem_opcode, pdp_op7_opcode,
                ifu_rd_req, ifu_rd_addr, ifu_rd_data);

// Checker for IFD->Execution Unit interface
ifd_checker ifd_chkr (clk, reset_n,
                stall, PC_value,
                ifu_rd_req, ifu_rd_addr, ifu_rd_data,
                base_addr, pdp_mem_opcode, pdp_op7_opcode);


endmodule
