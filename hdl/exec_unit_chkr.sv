/* exec_unit_chkr
 * Serves as a passive checker/scoreboard for monitoring
 * the execution unit's communication with surrounding
 * hierachies to ensure all required transactions are
 * taking place and correct.
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 */
module exec_unit_chkr (
    // From clkgen_driver module
    input clk,                              // Free running clock
    input reset_n,                          // Active low reset signal

    // From instr_decode module
    input [`ADDR_WIDTH-1:0] base_addr,      // Address for first instruction
    input pdp_mem_opcode_s pdp_mem_opcode,  // Decoded signals for memory instructions
    input pdp_op7_opcode_s pdp_op7_opcode,  // Decoded signals for op7 instructions

    // To instr_decode module
    input                   stall,          // Signal to stall instruction decoder
    input [`ADDR_WIDTH-1:0] PC_value,       // Current value of Program Counter

    // To memory_pdp module
    input                    exec_wr_req,   // Write request to memory
    input  [`ADDR_WIDTH-1:0] exec_wr_addr,  // Write address 
    input  [`DATA_WIDTH-1:0] exec_wr_data,  // Write data to memory
    input                    exec_rd_req,   // Read request to memory
    input  [`ADDR_WIDTH-1:0] exec_rd_addr,  // Read address

    // From memory_pdp module
    input   [`DATA_WIDTH-1:0] exec_rd_data, // Read data returned by memory
    
    // WHITEBOX SIGNALS. Must pass in hierarchical path to the
    // these signals wherever this checker in instantiated
    input [`DATA_WIDTH:0] wb_intAcc,
    input                 wb_intLink

);

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

logic prevStall;
logic justStalled;
assign justStalled = (~prevStall & stall);
    
always @(posedge clk) begin
    if(~reset_n) begin
        prevStall <= 1'b0;
    end else begin
        prevStall <= stall;
        if (hasNewInstruction(current_instr) & justStalled) begin
            if (instrIsLegal(current_instr)) begin
            handleInstruction(current_instr);
            end else begin
                $display("Illegal Instruction Detected: %p", current_instr);
            end
        end
    end
end

// Helper Tasks//Functions

// runRule - Wrapper to check a rule 
// condition and handle logging/tracking
// of all checked rules.
function runRule (
    input integer ruleNumber,
    input string  ruleText,
    input bit     rulePass
);
begin
    if (rulePass) begin
        $display("PASS Rule %d - %s", ruleNumber, ruleText);
        return 1;
    end else begin
        $display("FAIL Rule %d - %s", ruleNumber, ruleText);
        return 0;
    end
end
endfunction

// handleInstruction - Encapsulates code necessary
// to follow an injected instruction and run
// necessary checks on it
task handleInstruction (input instruction_pack instr);
begin
    if (isMemType(instr)) begin
        handleMemoryInstr(instr.memCode);
    end else if (isOp7Type(instr)) begin
        $display("Found op7 type instr %p", instr);
    end
end
endtask

// Returns true if there is a new memory or op7
// opcode contained in the passed instruction
function hasNewInstruction (
    input instruction_pack instr
);
begin
    return (isMemType(instr) || isOp7Type(instr));
end
endfunction
    
// instrIsLegal - Ensure only one instruction is
// being inserted into the execution unit at a time.
// Returns true if 0 or 1 instructions are active,
// and returns false if more than 1 is active.
function instrIsLegal (
    input instruction_pack instr
);
    bit isLegal;
begin
    isLegal = 1;
    if (!isOp7Type(instr) & !isMemType(instr)) begin
        return 1;
    end else begin
        return (instr.op7Code.NOP       ^
                instr.op7Code.IAC       ^
                instr.op7Code.RAL       ^
                instr.op7Code.RTL       ^
                instr.op7Code.RAR       ^
                instr.op7Code.RTR       ^
                instr.op7Code.CML       ^
                instr.op7Code.CMA       ^
                instr.op7Code.CIA       ^
                instr.op7Code.CLL       ^
                instr.op7Code.CLA1      ^
                instr.op7Code.CLA_CLL   ^
                instr.op7Code.HLT       ^
                instr.op7Code.OSR       ^
                instr.op7Code.SKP       ^
                instr.op7Code.SNL       ^
                instr.op7Code.SZL       ^
                instr.op7Code.SZA       ^
                instr.op7Code.SNA       ^
                instr.op7Code.SMA       ^
                instr.op7Code.SPA       ^
                instr.op7Code.CLA2      ^
                instr.memCode.AND       ^
                instr.memCode.TAD       ^
                instr.memCode.ISZ       ^
                instr.memCode.DCA       ^
                instr.memCode.JMS       ^
                instr.memCode.JMP);
        end
    
        return isLegal;
end
endfunction
   
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
    
// Memory Instruction Tasks

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

// handleMemoryInstr - Encapsulates code necessary
// to track and run checkers for memory instructions
task handleMemoryInstr (
    input pdp_mem_opcode_s mCode
);
begin
    if      (mCode.AND) memANDInstr(mCode);
    else if (mCode.ISZ) memISZInstr(mCode);
    else if (mCode.TAD) memTADInstr(mCode);
    else if (mCode.DCA) memDCAInstr(mCode);
    else if (mCode.JMS) memJMSInstr(mCode);
    else if (mCode.JMP) memJMPInstr(mCode);
end
endtask

// 5 Instructions from Branch to Stall
// 
task memANDInstr (
    input pdp_mem_opcode_s instr
);
logic [`DATA_WIDTH:0] temp_intAcc;
integer clkCount;
begin
    // Save the current value of the accumulator
    temp_intAcc = wb_intAcc;
    // Wait for the read request to come through
    $display("TIME 0: %d", $time);
    wait(exec_rd_req) begin
        @(posedge clk);
        clkCount = clkCount + 1;
    end
    if (!runRule(1, "AND Command Read Address Correct", exec_rd_addr === instr.mem_inst_addr)) begin
        $display ("Expected Read Address: %d    Actual Read Address: %d", instr.mem_inst_addr, exec_rd_addr);
    end
end
endtask
    
task memISZInstr (
    input pdp_mem_opcode_s instr
);
endtask
    
task memTADInstr (
    input pdp_mem_opcode_s instr
);
endtask
    
task memDCAInstr (
    input pdp_mem_opcode_s instr
);
endtask
    
task memJMSInstr (
    input pdp_mem_opcode_s instr
);
endtask
    
task memJMPInstr (
    input pdp_mem_opcode_s instr
);
endtask

endmodule