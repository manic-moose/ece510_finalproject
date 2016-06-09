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
//   Filename:     instr_exec.sv
//   Description:  TBD
//   Created by:   Tareque Ahmad
//   Date:         May 03, 2016
//
//   Copyright:    Tareque Ahmad 
// =======================================================================

`include "pdp8_pkg.sv"
import pdp8_pkg::*;

module instr_exec
  (
   // From clkgen_driver module
   input clk,                              // Free running clock
   input reset_n,                          // Active low reset signal

   // From instr_decode module
   input [`ADDR_WIDTH-1:0] base_addr,      // Address for first instruction
   input pdp_mem_opcode_s pdp_mem_opcode,  // Decoded signals for memory instructions
   input pdp_op7_opcode_s pdp_op7_opcode,  // Decoded signals for op7 instructions

   // To instr_decode module
   output                   stall,         // Signal to stall instruction decoder
   output [`ADDR_WIDTH-1:0] PC_value,      // Current value of Program Counter

   // To memory_pdp module
   output                    exec_wr_req,  // Write request to memory
   output  [`ADDR_WIDTH-1:0] exec_wr_addr, // Write address 
   output  [`DATA_WIDTH-1:0] exec_wr_data, // Write data to memory
   output                    exec_rd_req,  // Read request to memory
   output  [`ADDR_WIDTH-1:0] exec_rd_addr, // Read address

   // From memory_pdp module
   input   [`DATA_WIDTH-1:0] exec_rd_data  // Read data returned by memory

   );

   // Define enums for the state machine
   enum {IDLE,
         STALL,
         BRANCH,
         CLA,
         CLA_CLL,
         MEM_RD_REQ,
         DATA_RCVD,
         ADD_ACC_MEM,
         AND_ACC_MEM,
         ISZ_WR_REQ,
         ISZ_UPDT_PC,
         DCA,
         JMS_WR_REQ,
         JMS_UPDT_PC,
         JMP,
         NOP,
         UNSTALL } current_state, next_state;

   reg                   int_stall; // Internal signal to control stall
   reg [`DATA_WIDTH:0]   intAcc;    // 1bit extra for CARRY
   reg [`DATA_WIDTH:0]   tempAcc;   // 1bit extra for CARRY

   reg [`ADDR_WIDTH-1:0] intPC;     // Internal register to calculate PC value
   reg [`ADDR_WIDTH-1:0] tempPC;    // Internal register to calculate PC value

   reg                   intLink;   // Internal register to Link
   reg                   tempLink;  // Internal register to Link

   // Internal signal to support read operations
   reg                   int_exec_rd_req;
   reg [`ADDR_WIDTH-1:0] int_exec_rd_addr;
   reg [`DATA_WIDTH-1:0] int_exec_rd_data;

   // Internal signal to support write operations
   reg                   int_exec_wr_req;
   reg [`ADDR_WIDTH-1:0] int_exec_wr_addr;
   reg [`DATA_WIDTH-1:0] int_exec_wr_data;

   reg                   new_mem_opcode; // Signal to detect a new memory instruction
   reg                   new_op7_opcode; // Signal to detect a new op7 instruction


   assign new_mem_opcode = (pdp_mem_opcode.AND ||
                            pdp_mem_opcode.TAD ||
                            pdp_mem_opcode.ISZ ||
                            pdp_mem_opcode.DCA ||
                            pdp_mem_opcode.JMS ||
                            pdp_mem_opcode.JMP);

   assign new_op7_opcode = (pdp_op7_opcode.NOP ||
                            pdp_op7_opcode.IAC ||
                            pdp_op7_opcode.RAL ||
                            pdp_op7_opcode.RTL ||
                            pdp_op7_opcode.RAR ||
                            pdp_op7_opcode.RTR ||
                            pdp_op7_opcode.CML ||
                            pdp_op7_opcode.CMA ||
                            pdp_op7_opcode.CIA ||
                            pdp_op7_opcode.CLL ||
                            pdp_op7_opcode.CLA1 ||
                            pdp_op7_opcode.CLA_CLL ||
                            pdp_op7_opcode.HLT ||
                            pdp_op7_opcode.OSR ||
                            pdp_op7_opcode.SKP ||
                            pdp_op7_opcode.SNL ||
                            pdp_op7_opcode.SZL ||
                            pdp_op7_opcode.SZA ||
                            pdp_op7_opcode.SNA ||
                            pdp_op7_opcode.SMA ||
                            pdp_op7_opcode.SPA ||
                            pdp_op7_opcode.CLA2);

   // always block to drive FSM
   always_ff @(posedge clk or negedge reset_n) 
      if (!reset_n) current_state <= IDLE;
      else          current_state <= next_state;

   // Always block to calculate outputs
   always_comb begin
      case (current_state)

         // The FSM will stay in IDLE until it gets out of reset
         // Once it's out of reset, it sets base address as PC
         // and moves to STALL state
         //
         IDLE:
            begin
               intPC            <= base_addr;
               tempPC           <= base_addr;
               next_state       <= STALL;
            end


         // The FSM stays in this state until it receives a new instruction
         // Once a new instruction arrive, the FSM asserts stall and moves 
         // to BRANCH state
         //
         STALL:
               if (new_mem_opcode || new_op7_opcode) begin


                  int_stall        <= 1;
                  next_state       <= BRANCH;
               end else begin
                  int_stall        <= 0;
                  int_exec_rd_req  <= 0;
                  int_exec_rd_addr <= 0;
                  next_state       <= STALL;
               end

         // PC is incremented in this state
         // The FSM branches off to different paths from here based on the
         // actual insruction
         // The FSM does not stay in this state more than one cycle
         //
         BRANCH:
            begin

               intPC <= tempPC + 1;

               if (pdp_op7_opcode.CLA_CLL)
                  next_state <= CLA_CLL;
               else if (pdp_mem_opcode.TAD || pdp_mem_opcode.AND || pdp_mem_opcode.ISZ)
                  next_state <= MEM_RD_REQ;
               else if (pdp_mem_opcode.DCA)
                  next_state <= DCA;
               else if (pdp_mem_opcode.JMS)
                  next_state <= JMS_WR_REQ;
               else if (pdp_mem_opcode.JMP)
                  next_state <= JMP;
               else
                  next_state <= NOP;
            end

         // AC is cleared in this state and the FSM jumps to UNSTALL state
         // The FSM does not stay in this state more than one cycle
         //
         CLA:
            begin
               intAcc     <= 0;
               next_state <= UNSTALL;
            end

         // Both AC and Link are cleared in this state and the FSM jumps to UNSTALL state
         // The FSM does not stay in this state more than one cycle
         //
         CLA_CLL:
            begin
               intAcc     <= 0;
               intLink    <= 0;
               next_state <= UNSTALL;
            end

         // Read request is sent to memory
         // Address is used from instrction
         // FSM moves to DATA_RCVD state
         // The FSM does not stay in this state more than one cycle
         //
         MEM_RD_REQ:
            begin
               int_exec_rd_req  <= 1;
               int_exec_rd_addr <= pdp_mem_opcode.mem_inst_addr;
               next_state       <= DATA_RCVD;
            end

         // Data is received from memory and latched
         // Current value of AC and Link to stored in temp location
         // The FSM jumps to different states based on opcode
         //
         DATA_RCVD:
            begin
               int_exec_rd_req  <= 0;
               int_exec_rd_data <= exec_rd_data;
               tempAcc          <= intAcc;
               tempLink         <= intLink;

               if (pdp_mem_opcode.TAD)
                  next_state <= ADD_ACC_MEM;
               else if (pdp_mem_opcode.AND)
                  next_state <= AND_ACC_MEM;
               else if (pdp_mem_opcode.ISZ)
                  next_state <= ISZ_WR_REQ;
            end

         // Data from memory is added to AC value
         // Link is complemented if there is carry
         // TAD is done here. FSM moves to UNSTALL
         //
         ADD_ACC_MEM:
            begin
               intAcc <= tempAcc + int_exec_rd_data;
               if (intAcc[`DATA_WIDTH]) intLink <= ~tempLink;
               next_state <= UNSTALL;
            end

         // Data from memory is AND'ed wth AC value
         // AND is done here. FSM moves to UNSTALL
         //
         //
         AND_ACC_MEM:
            begin
               intAcc <= tempAcc & int_exec_rd_data;
               next_state <= UNSTALL;
            end

         // Data from memory is incremented by 1
         // Write addr/data is calculated 
         // Write request is asserted
         // PC is NOT changed YET
         // Jumps to ISZ_UPDT_PC state
         //
         ISZ_WR_REQ:
            begin
               int_exec_wr_req  <= 1;
               int_exec_wr_addr <= pdp_mem_opcode.mem_inst_addr;
               int_exec_wr_data <= int_exec_rd_data+1;
               tempPC           <= intPC;
               next_state       <= ISZ_UPDT_PC;
            end

         // This state is needed to increment PC conditiionally
         // ISZ is done here. FSM moves to UNSTALL
         //
         ISZ_UPDT_PC:
            begin
               if (int_exec_rd_data == 0) intPC <= tempPC + 1;
               next_state <= UNSTALL;
            end

         // Write request is asserted
         // Write address is derived from opcode
         // Write data is AC value
         // The FSM jumps to CLA state to clear AC there
         //
         DCA:
            begin
               int_exec_wr_req  <= 1;
               int_exec_wr_addr <= pdp_mem_opcode.mem_inst_addr;
               int_exec_wr_data <= intAcc;
               next_state       <= CLA;
            end

         // Write request is asserted
         // Write address is derived from opcode
         // Write data is PC value
         // The FSM jumps to JMS_UPDT_PC state to update PC there
         //
         JMS_WR_REQ:
            begin
               int_exec_wr_req  <= 1;
               int_exec_wr_addr <= pdp_mem_opcode.mem_inst_addr;
               int_exec_wr_data <= intPC;
               next_state       <= JMS_UPDT_PC;
            end

         // PC is updated with value from opcode
         // JMS is done here. FSM moves to UNSTALL
         //
         JMS_UPDT_PC:
            begin
               intPC      <= pdp_mem_opcode.mem_inst_addr+1;
               next_state <= UNSTALL;
            end

         // PC is updated with value from opcode
         // JMP is done here. FSM moves to UNSTALL
         //
         JMP:
            begin
               intPC      <= pdp_mem_opcode.mem_inst_addr;
               next_state <= UNSTALL;
            end

         // NOP is done here. FSM moves to UNSTALL
         //
         NOP:
            begin
               next_state <= UNSTALL;
            end

         // Stall is cleared
         // Write request is cleared
         // PC value is updated internally
         // Jumps to STALL state for the 
         //
         UNSTALL:
            begin
               int_stall        <= 0;
               int_exec_wr_req  <= 0;
               tempPC           <= intPC;
               next_state       <= STALL;
            end

      endcase
   end

   // Continuous assignment for the outputs to instruction decode unit
   assign stall        = int_stall;
   assign PC_value     = tempPC;

   // Continuous assignment for the outputs to memory unit
   assign exec_rd_req  = int_exec_rd_req;
   assign exec_rd_addr = int_exec_rd_addr;
   assign exec_wr_req  = int_exec_wr_req;
   assign exec_wr_addr = int_exec_wr_addr;
   assign exec_wr_data = int_exec_wr_data;


endmodule //  instr_exec

