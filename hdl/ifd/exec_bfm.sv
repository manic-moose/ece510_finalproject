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
`define MAX_TRANS_BEFORE_DONE 100000

localparam DEBUG = 1;

// external interface back to IFD
reg [`ADDR_WIDTH-1:0] intPC;
assign PC_value = intPC;
reg intStall;
assign stall = intStall;

// count clocks just for display purposes
integer clkCount = 0;
always @(posedge clk) begin
    clkCount <= clkCount + 1;
end

integer transactions;

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









// respond to new opcode from IFD indefinitely
`ifdef CLKGEN
initial begin
    transactions = 'd0;
    forever begin
        waitForOpcode();
        randomizePCStall();
        transactions = transactions + 'd1;
    end
end
`else
// directed tests + random tests + base addr test
initial begin
    transactions = 'd0;
    repeat (NUM_RESETS) begin
        // reset the DUT
        reset_system();
        // delay random cycles
        waitNClocks($urandom_range(`MAX_DELAY_CYCLES, `MIN_DELAY_CYCLES));
    end
    repeat (`MAX_TRANS_BEFORE_DONE) begin
        if (DEBUG) $display("exec_bfm: next transaction: %d", transactions);
        waitForOpcode();
        randomizePCStall();
        transactions = transactions + 'd1;
    end
    // send the IFD the base addr to signal operation is complete
    if (DEBUG) $display("exec_bfm: waiting for final opcode before sending base addr");
    waitForOpcode();
    waitNClocks(5);
    sendBaseAddr();
    waitNClocks(5);
    reset_system();
    waitNClocks(5);
    $display("sim finishing");
    $finish;
end
`endif












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
task randomizePCStall();
begin
   randomizePC();
   randomizeStall();
end
endtask

// generate a random program counter
// that isn't the base addr
task randomizePC();
reg [`ADDR_WIDTH-1:0] tempPC;
begin
    tempPC = $urandom_range({`ADDR_WIDTH{1'b1}});
    while (tempPC == base_addr) begin
        tempPC = $urandom_range({`ADDR_WIDTH{1'b1}});
    end
    intPC = tempPC;
end
endtask

// stall for a random amount of time
task randomizeStall();
reg [5:0] start_clocks, stop_clocks;
begin
    intStall = 1'b1;
    start_clocks = clkCount;
    waitNClocks($urandom_range(`MAX_DELAY_CYCLES, `MIN_DELAY_CYCLES));
    stop_clocks = clkCount;
    intStall = 1'b0;
    if (DEBUG) $display("exec_bfm: Sending PC %o after %p stalled cycles. CLOCKS:  %d", intPC, stop_clocks-start_clocks, clkCount);
end
endtask

// send base addr as PC
// and toggle stall
task sendBaseAddr();
begin
    if (DEBUG) $display("exec_bfm: sending base addr");
    intPC = base_addr;
    intStall = 1'b1;
    waitNClocks(1);
    intStall = 1'b0;
end
endtask

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





// generate a clock
// don't generate reset, will muck with that
// throughout the test
`ifndef CLKGEN
reg int_clk;
reg int_reset_n;

assign clk     = int_clk;
assign reset_n = int_reset_n;

initial begin
    int_clk = 1'b1;
    forever #(CLOCK_PERIOD/2) int_clk = ~int_clk;
end

task reset_system();
begin
    int_reset_n = 1'b0;
    waitNClocks(RESET_DURATION);
    int_reset_n = 1'b1;
end
endtask
`endif


endmodule // exec_bfd
