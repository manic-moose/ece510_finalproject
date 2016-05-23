/* ifd_bfm.sv
 * Serves as a stimulus generator for the PDP8 instruction
 * Execution unit for unit level testing.
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 *
 */
module ifd_bfd (
   // Global inputs
   input clk,
   input reset_n,
   // From Execution unit
   input stall,
   input [`ADDR_WIDTH-1:0] PC_value,
   // To Execution unit (decode struct)
   output [`ADDR_WIDTH-1:0] base_addr,
   output pdp_mem_opcode_s pdp_mem_opcode,
   output pdp_op7_opcode_s pdp_op7_opcode
);

localparam DEBUG = 0;

logic [`ADDR_WIDTH-1:0] int_base_addr;
assign int_base_addr = `START_ADDRESS;
    
integer clkCount = 0;
always @(posedge clk) begin
    clkCount <= clkCount + 1;
end

pdp_op7_opcode_s int_pdp_op7_opcode;
pdp_mem_opcode_s int_pdp_mem_opcode;

// Label Decoded op7 opcodes
localparam logic [21:0]
    CLA2    = 1 << 0,
    SPA     = 1 << 1,
    SMA     = 1 << 2,
    SNA     = 1 << 3,
    SZA     = 1 << 4,
    SZL     = 1 << 5,
    SNL     = 1 << 6,
    SKP     = 1 << 7,
    OSR     = 1 << 8,
    HLT     = 1 << 9,
    CLA_CLL = 1 << 10,
    CLA1    = 1 << 11,
    CLL     = 1 << 12,
    CIA     = 1 << 13,
    CMA     = 1 << 14,
    CML     = 1 << 15,
    RTR     = 1 << 16,
    RAR     = 1 << 17,
    RTL     = 1 << 18,
    RAL     = 1 << 19,
    IAC     = 1 << 20,
    NOP     = 1 << 21;


// label Decoded memory opcodes
localparam logic [5:0]
    JMP = 1 << 0,
    JMS = 1 << 1,
    DCA = 1 << 2,
    ISZ = 1 << 3,
    TAD = 1 << 4,
    AND = 1 << 5;

assign pdp_mem_opcode = int_pdp_mem_opcode;
assign pdp_op7_opcode = int_pdp_op7_opcode;
assign base_addr      = int_base_addr;


// Roll Through Test Sequence
initial begin
    initialize();
    runDirectedVectors(); 
    runRandomVectors();
    waitNClocks(100);
    $stop;
end


// Helper Tasks

// Clears opcodes and waits for end of reset
task initialize ();
begin
    clearOpCodes();
    wait(reset_n);
    waitNClocks(10);
end
endtask

// Run through initial set of directed
// test vectors
task runDirectedVectors();
begin
    sendMemoryCmd(AND,  1);
    sendMemoryCmd(AND,  2);
    sendMemoryCmd(TAD,  3);
    sendMemoryCmd(TAD,  4);
    sendMemoryCmd(ISZ,  5);
    sendMemoryCmd(ISZ,  6);
    sendMemoryCmd(DCA,  7);
    sendMemoryCmd(DCA,  8);
    sendMemoryCmd(JMS,  9);
    sendMemoryCmd(JMS, 10);
    sendMemoryCmd(JMP, 11);
    sendMemoryCmd(JMP, 12);
    sendOp7Cmd(NOP);
    sendOp7Cmd(CLA_CLL);
end
endtask

// Run through a set of randomized vectors
task runRandomVectors();
logic isMemoryCmd;
begin
    while (1) begin
        isMemoryCmd = $urandom_range(1);
        if (isMemoryCmd) begin
            runRandomMemoryCmd();
        end else begin
            runRandomOp7Cmd();
        end
    end
end
endtask
    
// Injects a randomly selected
// memory command and address
task runRandomMemoryCmd ();
    logic [2:0] shiftAmnt;
    logic [5:0] cmd;
begin
    shiftAmnt = $urandom_range(5);
    cmd = 1 << shiftAmnt;
    sendMemoryCmd(cmd, getRandomAdx());
end
endtask
    
task runRandomOp7Cmd ();
logic [4:0] shiftAmnt;
logic [21:0] cmd;
begin
    shiftAmnt = $urandom_range(21);
    cmd = 1 << shiftAmnt;
    sendOp7Cmd(cmd);
end
endtask

// Returns a pseudo-random ADDR_WIDTH bit value
function logic[`ADDR_WIDTH-1:0] getRandomAdx ();
logic [31:0] bits;
begin
    bits = $urandom();
    return bits;
end
endfunction

// Wait for stall to be de-asserted,
// send the op code and adx, and wait
// for stall to be asserted
task sendMemoryCmd (
    input [5:0] code,
    input [`DATA_WIDTH-1:0] address
);
begin
    wait(stall === 1'b0) waitNClocks(1);
    if (DEBUG) $display("Sending %p memory command with adx %p    CLOCKS:  %d", code, address, clkCount);
    setMemory_Op(code,address);
    waitNClocks(1);
    wait(stall === 1'b0) waitNClocks(1);
    clearOpCodes();
end
endtask

// Set a memory command output
task setMemory_Op (
    input [5:0] code,
    input [`DATA_WIDTH-1:0] address
);
begin
    int_pdp_mem_opcode <= {code, address};
end
endtask

// Wait for stall to be de-asserted,
// send the op code, and wait
// for stall to be asserted
task sendOp7Cmd (
    input pdp_op7_opcode_s code
);
begin
    wait(!stall) waitNClocks(1);
    if (DEBUG) $display("Sending %p op7 command", code);
    setOp7_Op(code);
    waitNClocks(1);
    wait(!stall) waitNClocks(1);
    clearOpCodes();
end
endtask

// Set an op7 command output
task setOp7_Op (
    input pdp_op7_opcode_s code
);
begin
    int_pdp_op7_opcode <= code;
end
endtask

// Clear OP Codes
task clearOpCodes ();
begin
    setMemory_Op(6'b0, {`DATA_WIDTH{1'b0}});
    setOp7_Op({22{1'b0}});
end
endtask

// Blocks until n clocks are observed
task waitNClocks (
    input integer n
);
begin
    repeat (n) @(posedge clk);
end
endtask

endmodule
