/*
 * exec_bfm.sv
 * Serves as a stimulus generator for the PDP8 
 * Instruction Fetch/Decode unit for unit level testing.
 *
 * Author: Chip Wood chawood@pdx.edu
 *
 */

module exec_bfm (
   // Global inputs
   input clk,
   input reset_n,
   // To IFD (stall, new PC)
   output stall,
   output [`ADDR_WIDTH-1:0] PC_value,
   // From IFD (decoded instructions)
   input [`ADDR_WIDTH-1:0] base_addr,
   input pdp_mem_opcode_s pdp_mem_opcode,
   input pdp_op7_opcode_s pdp_op7_opcode
);

// Max number of cycles stall asserted
`define MAX_DELAY_CYCLES 20
`define MIN_DELAY_CYCLES 1
`define MAX_TRANS_BEFORE_DONE 30000

localparam DEBUG = 0;

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
initial begin
    transactions = 'd0;
    forever begin
        waitForOpcode();
        randomizePCStall();
        transactions = transactions + 'd1;
    end
end






// wait for a new opcode to arrive
// not concerned with validity of opcode
task waitForOpcode();
begin
    wait(isMemType(current_instr) || isOp7Type(current_instr)) waitNClocks(1);
end
endtask

// generate a random program counter
// and stall for a random amount of time
task randomizePCStall();
reg [5:0] start_clocks, stop_clocks;
reg [`ADDR_WIDTH-1:0] tempPC;
begin
    intStall = 1'b1;
    // generate new random program counter.
    tempPC = $urandom_range({`ADDR_WIDTH{1'b1}});
    // prevent PC from being set to program counter
    // this prevents the simulation from stopping early
    if (transactions < `MAX_TRANS_BEFORE_DONE) begin
        while (tempPC == base_addr) begin
            tempPC = $urandom_range({`ADDR_WIDTH{1'b1}});
        end
    end
    else begin
        // set program counter to base address after maximun number of transactions
        tempPC = base_addr;
    end
    intPC = tempPC;
    start_clocks = clkCount;
    waitNClocks($urandom_range(`MAX_DELAY_CYCLES, `MIN_DELAY_CYCLES));
    stop_clocks = clkCount;
    if (DEBUG) $display("exec_bfm: Sending PC %o after %p stalled cycles. CLOCKS:  %d", intPC, stop_clocks-start_clocks, clkCount);
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

endmodule // exec_bfd
