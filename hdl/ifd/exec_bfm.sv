/*
 * exec_bfm.sv
 * Serves as a stimulus generator for the PDP8 
 * Instruction Fetch/Decode unit for unit level testing.
 *
 * Author: Chip Wood chawood@pdx.edu
 *
 */

module exec_bfm (
`ifdef CLKGEN
   // Global inputs
   input clk,
   input reset_n,
`else
   output clk,
   output reset_n,
`endif
   // To IFD (stall, new PC)
   output stall,
   output [`ADDR_WIDTH-1:0] PC_value,
   // From IFD (decoded instructions)
   input [`ADDR_WIDTH-1:0] base_addr,
   input pdp_mem_opcode_s pdp_mem_opcode,
   input pdp_op7_opcode_s pdp_op7_opcode
);
`ifndef CLKGEN
parameter CLOCK_PERIOD = 10;
parameter RESET_DURATION = 50;
parameter RUN_TIME = 5000000;
parameter NUM_RESETS = 100;
`endif

// Max number of cycles stall asserted
`define MAX_DELAY_CYCLES 20
`define MIN_DELAY_CYCLES 1
`define MAX_TRANS_BEFORE_DONE 50000

localparam DEBUG = 0;

// external interface back to IFD
reg [`ADDR_WIDTH-1:0] intPC;
assign PC_value = intPC;
reg intStall;
assign stall = intStall;

typedef struct packed {
    pdp_mem_opcode_s memCode;
    pdp_op7_opcode_s op7Code;
} instruction_pack;

// Always pack this for convenience
instruction_pack current_instr;
always @(*) begin
    current_instr.memCode <= pdp_mem_opcode;
    current_instr.op7Code <= pdp_op7_opcode;
end








////////////////////////////////////////////////////////////
// respond to opcode from IFD
// with random PC and stall forever
// (clkgen module dictates how long simulation is)
`ifdef CLKGEN
initial begin
    forever begin
        waitForOpcode();
        respondToOpcode();
    end
end
`else
////////////////////////////////////////////////////////////
// Semi-random testing
// clk and reset_n generated in this module
// allows forcing resets randomly
reg int_clk, int_reset_n;
assign clk     = int_clk;
assign reset_n = int_reset_n;
// generate the clock
initial begin
    int_clk = 1'b1;
    forever #(CLOCK_PERIOD/2) int_clk = ~int_clk;
end
// simplify resetting 
task resetSystem();
begin
    int_reset_n = 1'b0;
    waitNClocks(RESET_DURATION);
    int_reset_n = 1'b1;
end
endtask

initial begin
    if (DEBUG) $display("exec_bfm: Beginning stimulus - randomized resets");
    repeat (NUM_RESETS) begin
        // reset the DUT
        resetSystem();
        // delay random cycles
        waitNClocks($urandom_range(`MAX_DELAY_CYCLES, `MIN_DELAY_CYCLES));
    end
    if (DEBUG) $display("exec_bfm: Second stimulus - random program counters and stalls");
    repeat (`MAX_TRANS_BEFORE_DONE) begin
        waitForOpcode();
        respondToOpcode();
    end
    // let last random PC complete
    waitForOpcode();
    waitNClocks(1);
    // send the IFD the base addr to signal operation is complete
    if (DEBUG) $display("exec_bfm: Third stimulus - PC=base_addr to force IFD to halt");
    PCBaseAddr();
    waitNClocks(5);
    // reset the FSM one last time
    if (DEBUG) $display("exec_bfm: Resetting system");
    resetSystem();
    waitNClocks(5);
    if (DEBUG) $display("exec_bfm: Simulation complete");
    $finish;
end
`endif











////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
// helper functions

// wait for a new opcode to arrive
// not concerned with validity of opcode
task waitForOpcode();
begin
    wait(isMemType(current_instr) || isOp7Type(current_instr)) waitNClocks(1);
end
endtask

// respond to an opcode with a random PC
// and drive the 'stall' signal high
// for a random amount of time
task respondToOpcode();
begin
   PCRandomize();
   stallRandomize();
end
endtask

// Set PC to random address
// that isn't the base addr
task PCRandomize();
reg [`ADDR_WIDTH-1:0] tempPC;
begin
    tempPC = $urandom_range({`ADDR_WIDTH{1'b1}});
    while (tempPC == base_addr) begin
        tempPC = $urandom_range({`ADDR_WIDTH{1'b1}});
    end
    intPC = tempPC;
end
endtask

// Set PC to base_addr
// and toggle stall
task PCBaseAddr();
begin
    if (DEBUG) $display("exec_bfm: sending base addr");
    intPC = base_addr;
    stallRandomize();
    //intStall = 1'b1;
    //waitNClocks(1);
    //intStall = 1'b0;
end
endtask

// stall for a random amount of time
task stallRandomize();
integer delay;
begin
    intStall = 1'b1;
    delay = $urandom_range(`MAX_DELAY_CYCLES, `MIN_DELAY_CYCLES);
    waitNClocks(delay);
    intStall = 1'b0;
    if (DEBUG) $display("exec_bfm: Sending PC %o after %p stalled cycles", intPC, delay);
end
endtask





/*********************************************************
 * Tasks for checking if opcodes are available
 *********************************************************/

// isOp7Type - Returns true if the instruction
// contains at least one op7 operation active
function isOp7Type (
    input instruction_pack instr
);
begin
    return (instr.op7Code.NOP       ||
            instr.op7Code.IAC       ||
            instr.op7Code.RAL       ||
            instr.op7Code.RTL       ||
            instr.op7Code.RAR       ||
            instr.op7Code.RTR       ||
            instr.op7Code.CML       ||
            instr.op7Code.CMA       ||
            instr.op7Code.CIA       ||
            instr.op7Code.CLL       ||
            instr.op7Code.CLA1      ||
            instr.op7Code.CLA_CLL   ||
            instr.op7Code.HLT       ||
            instr.op7Code.OSR       ||
            instr.op7Code.SKP       ||
            instr.op7Code.SNL       ||
            instr.op7Code.SZL       ||
            instr.op7Code.SZA       ||
            instr.op7Code.SNA       ||
            instr.op7Code.SMA       ||
            instr.op7Code.SPA       ||
            instr.op7Code.CLA2);
end
endfunction

// isMemType - Returns true if at least
// one memory opcode is active
function isMemType (
    input instruction_pack instr
);
begin
    return (instr.memCode.AND ||
            instr.memCode.TAD ||
            instr.memCode.ISZ ||
            instr.memCode.DCA ||
            instr.memCode.JMS ||
            instr.memCode.JMP);
end
endfunction

// Blocks until n clocks are observed
task waitNClocks (
    input integer n
);
begin
    repeat (n) @(posedge clk);
end
endtask







endmodule // exec_bfd
