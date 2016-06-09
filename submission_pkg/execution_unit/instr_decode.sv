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
//   Filename:     instr_decode.sv
//   Description:  TBD
//   Created by:   Tareque Ahmad
//   Date:         May 03, 2016
//
//   Copyright:    Tareque Ahmad 
// =======================================================================

`include "pdp8_pkg.sv"

import pdp8_pkg::*;

module instr_decode
  (
   // Global inputs
   input clk,
   input reset_n,

   // From Execution unit
   input stall,
   input [`ADDR_WIDTH-1:0] PC_value,

   // To memory unit
   output                    ifu_rd_req,
   output  [`ADDR_WIDTH-1:0] ifu_rd_addr,

   // From memory unit
   input [`DATA_WIDTH-1:0] ifu_rd_data,

   // To Execution unit (decode struct)
   output [`ADDR_WIDTH-1:0] base_addr,
   output pdp_mem_opcode_s pdp_mem_opcode,
   output pdp_op7_opcode_s pdp_op7_opcode
   );

   // Define enums for the state machine
   enum {IDLE,
         READY,
         SEND_REQ,
         DATA_RCVD,
         INST_DEC,
         STALL,
         DONE } current_state, next_state;

   reg [`ADDR_WIDTH-1:0] int_base_addr; // Latched value of base address

   reg                   int_rd_req;    // internal signal to drive read request to memory for instr fetch
   reg [`ADDR_WIDTH-1:0] int_rd_addr;   // internal register to latch PC from EU used as memory address for next instr fetch

   reg [`DATA_WIDTH-1:0] int_rd_data;   // Internal register to latch data from memory

   pdp_mem_opcode_s int_pdp_mem_opcode; // Internal struct to drive outut to Execution unit
   pdp_op7_opcode_s int_pdp_op7_opcode; // Internal struct to drive outut to Execution unit


   // always block to drive FSM
   always_ff @(posedge clk or negedge reset_n) 
      if (!reset_n) current_state <= IDLE;
      else          current_state <= next_state;


   // Always block to calculate outputs
   always_comb begin
      case (current_state)

         // The FSM will stay in IDLE until it gets out of reset
         // Once it's out of reset, it sets 0200 octal as starting address
         // and moves to READY state
         //
         IDLE: if (reset_n) begin
                   int_base_addr <= `START_ADDRESS;

                   // Clear all internal registers and flags
                   int_rd_req         <= 0;
                   int_rd_addr        <= 0;
                   int_rd_data        <= 0;
                   int_pdp_mem_opcode <= '{0,0,0,0,0,0,9'bz};
                   int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

                   next_state <= READY;
               end else begin
                   next_state <= IDLE;
               end

         // The sole purpose of having this READY state is to isolate read
         // address for the first and subsequent reads 
         // The state machine will get into this READY state only once.
         // Once it latches the first address, it moves to the SEND_REQ state,
         // The FSM does not stay in this state more than one cycle
         //
         READY: begin
                   int_rd_addr <= int_base_addr;

                   next_state <= SEND_REQ;
                end

         // Read request to memory is asserted in this state.
         // Previous outputs are also cleared. This allows the execution unit to
         // wait for a rising edge of the decode instruction signals if the same
         // instruction comes twice back to back from the memory
         // The FSM does not stay in this state more than one cycle
         //
         SEND_REQ: begin
                      int_pdp_mem_opcode <= '{0,0,0,0,0,0,9'bz};
                      int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                      int_rd_req <= 1;

                      next_state <= DATA_RCVD;
                   end

         // Read request to memory is cleared in this state.
         // Data from memory is latched 
         // Then the FSM moves to INST_DEC (instruction decode) state 
         // It does not stay in this state more than one cycle
         //
         DATA_RCVD: begin
                       int_rd_req <= 0;
                       int_rd_data <= ifu_rd_data;

                       next_state <= INST_DEC;
                    end

         // Decodes the read data from memory
         // and then moves to stall state
         // The FSM does not stay in this state more than one cycle
         // Any unsupported instruction is treated as NOP
         //
         INST_DEC: begin


                      if (int_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] < 6) begin
                         case (int_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3])

                            `AND: int_pdp_mem_opcode    <= '{1,0,0,0,0,0,int_rd_data[8:0]};
                            `TAD: int_pdp_mem_opcode    <= '{0,1,0,0,0,0,int_rd_data[8:0]};
                            `ISZ: int_pdp_mem_opcode    <= '{0,0,1,0,0,0,int_rd_data[8:0]};
                            `DCA: int_pdp_mem_opcode    <= '{0,0,0,1,0,0,int_rd_data[8:0]};
                            `JMS: int_pdp_mem_opcode    <= '{0,0,0,0,1,0,int_rd_data[8:0]};
                            `JMP: int_pdp_mem_opcode    <= '{0,0,0,0,0,1,int_rd_data[8:0]};
                            default: int_pdp_mem_opcode <= '{0,0,0,0,0,0,9'bz};
                         endcase
                      end else if (int_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == 7) begin
                         case (int_rd_data)
                            `NOP    : int_pdp_op7_opcode <= '{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `IAC    : int_pdp_op7_opcode <= '{0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `RAL    : int_pdp_op7_opcode <= '{0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `RTL    : int_pdp_op7_opcode <= '{0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `RAR    : int_pdp_op7_opcode <= '{0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `RTR    : int_pdp_op7_opcode <= '{0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `CML    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `CMA    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `CIA    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0};
                            `CLL    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0};
                            `CLA1   : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0};
                            `CLA_CLL: int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0};
                            `HLT    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0};
                            `OSR    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0};
                            `SKP    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0};
                            `SNL    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0};
                            `SZL    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0};
                            `SZA    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0};
                            `SNA    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0};
                            `SMA    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0};
                            `SPA    : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0};
                            `CLA2   : int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1};
                            default : int_pdp_op7_opcode <= '{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; //NOP
                         endcase
                      end else begin
                         int_pdp_mem_opcode <= '{0,0,0,0,0,0,9'bz};
                         int_pdp_op7_opcode <= '{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}; // NOP
                      end

                      next_state <= STALL;

                   end

         // This state is necessary to allow the execution unit to latch the
         // decoded signals and assert stall signal
         // The FSM will stay in this state as long the stall is asserted
         // Internal read address is updated for the next read based on the PC
         // value from execution unit
         //
         // If the updated PC value matches with the base address (Octal-200), FSM will go to DONE
         // state. Otherwise, it will go to SEND_REQ state for the next instruction fetch
         //
         STALL: begin

                   if (stall) begin
                      next_state <= STALL;
                   end else begin
                      int_rd_addr <= PC_value;
                      if (PC_value == int_base_addr) begin
                         next_state <= DONE;
                      end else
                         next_state <= SEND_REQ;
                   end
                end

         // This is the terminal state. The FSM jumps into this state when the
         // last JMP instruction is encountered and it stays in this stete unless
         // there is another reset
         DONE: begin
                   int_pdp_mem_opcode <= '{0,0,0,0,0,0,9'bz};
                   int_pdp_op7_opcode <= '{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
                   if (~reset_n) 
                      next_state <= IDLE;
                   else
                      next_state <= DONE;
               end
      endcase
   end


   // Continuous assignment for the outputs to memory unit
   assign ifu_rd_req      = int_rd_req;
   assign ifu_rd_addr     = int_rd_addr;

   // Continuous assignment for the outputs to exec unit
   assign base_addr       = int_base_addr;
   assign pdp_mem_opcode  = int_pdp_mem_opcode;
   assign pdp_op7_opcode  = int_pdp_op7_opcode;

endmodule //  instr_decode

