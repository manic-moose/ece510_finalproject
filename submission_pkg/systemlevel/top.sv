/* pdp_top.sv - Top level testbench for PDP-8
 * Includes all checker and coverage verification
 * components.
 *
 */

`include "pdp8_pkg.sv"

import pdp8_pkg::*;

module top ();

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

SequenceMonitor seq_mon(
    .execTracker(exec_chkr.tracker),
    .ifdTracker(ifd_chkr.tracker_ifd)
);

clkgen_driver iclocker (
    .clk,
    .reset_n
);

instr_decode idecoder (
    .clk,
    .reset_n,
    .stall,
    .PC_value,
    .ifu_rd_req,
    .ifu_rd_addr,
    .ifu_rd_data,
    .base_addr,
    .pdp_mem_opcode,
    .pdp_op7_opcode
);

instr_exec iexecutor (
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
   .exec_rd_data
);

memory_pdp imemoryer (
    .clk,
    .ifu_rd_req,
    .ifu_rd_addr,
    .ifu_rd_data,
    .exec_rd_req,
    .exec_rd_addr,
    .exec_rd_data,
    .exec_wr_req,
    .exec_wr_addr,
    .exec_wr_data
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
    .wb_intAcc(iexecutor.intAcc),
    .wb_intLink(iexecutor.intLink)
);

// CHecker for IFD interface

ifd_checker ifd_chkr (
    .clk,
    .reset_n,
    .ifu_rd_req,
    .ifu_rd_data,
    .base_addr,
    .pdp_mem_opcode,
    .pdp_op7_opcode,
    .stall,
    .PC_value
);


endmodule
