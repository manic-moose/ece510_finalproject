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
//   Filename:     pdp8_pkg.sv
//   Description:  Package file for PDP8 implementation
//   Created by:   Tareque Ahmad
//   Date:         May 04, 2016
//
//   Copyright:    Tareque Ahmad 
// =======================================================================

// Declare time paramemters
timeunit 1ns;
timeprecision 1ns;


// Pacakge definition
package pdp8_pkg;

`define MEM_FILENAME "test.mem"
`define OUT_FILENAME "out.mem"

`define START_ADDRESS 12'o0200

`define ADDR_WIDTH 12
`define DATA_WIDTH 12

// Defines for MRI instructions
`define AND 0
`define TAD 1
`define ISZ 2
`define DCA 3
`define JMS 4
`define JMP 5

typedef struct packed {
   logic AND;
   logic TAD;
   logic ISZ;
   logic DCA;
   logic JMS;
   logic JMP;
   logic [`DATA_WIDTH-1:0] mem_inst_addr;

} pdp_mem_opcode_s;

// Defines for op7 instructions
`define NOP 12'o7000
`define IAC 12'o7001
`define RAL 12'o7004
`define RTL 12'o7006
`define RAR 12'o7010
`define RTR 12'o7012
`define CML 12'o7020
`define CMA 12'o7040
`define CIA 12'o7041
`define CLL 12'o7104
`define CLA1    12'o7200
`define CLA_CLL 12'o7300
`define HLT 12'o7402
`define OSR 12'o7404
`define SKP 12'o7410
`define SNL 12'o7420
`define SZL 12'o7430
`define SZA 12'o7440
`define SNA 12'o7450
`define SMA 12'o7500
`define SPA 12'o7510
`define CLA2 12'o7600

typedef struct packed {
   logic NOP;
   logic IAC;
   logic RAL;
   logic RTL;
   logic RAR;
   logic RTR;
   logic CML;
   logic CMA;
   logic CIA;
   logic CLL;
   logic CLA1;
   logic CLA_CLL;
   logic HLT;
   logic OSR;
   logic SKP;
   logic SNL;
   logic SZL;
   logic SZA;
   logic SNA;
   logic SMA;
   logic SPA;
   logic CLA2;

} pdp_op7_opcode_s;

endpackage: pdp8_pkg

