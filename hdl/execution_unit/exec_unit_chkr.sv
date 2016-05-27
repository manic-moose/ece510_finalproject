/* exec_unit_chkr
 * Serves as a passive checker/scoreboard for monitoring
 * the execution unit's communication with surrounding
 * hierachies to ensure all required transactions are
 * taking place and correct.
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 */

`define EXE_RULE_FILE         "exec_unit_rules.txt"
`define EXE_RULE_DISABLE_FILE "exec_rule.disable"

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
    
localparam VERBOSE = 0;

CheckerClass chkr;
CovTracker tracker;
    
bit dummy;
bit ruleBit;
    
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
    
string ruleHash [integer];
bit ruleDisableHash[integer];

// Keep track of how many rules run/pass/fail
integer unsigned ruleRunCount  [integer];
integer unsigned rulePassCount [integer];
integer unsigned ruleFailCount [integer];

initial begin
    tracker = new();
    defineCovLabels(tracker);
    chkr = new(`EXE_RULE_FILE, `EXE_RULE_DISABLE_FILE);
    chkr.setVerbose(VERBOSE);
end

// Defines the functional coverage conditions desired
// to be tracked
task defineCovLabels (input CovTracker t);
    begin
        t.defineNewCov("CLA2");
        t.defineNewCov("SPA");
        t.defineNewCov("SMA");
        t.defineNewCov("SNA");
        t.defineNewCov("SZA");
        t.defineNewCov("SZL");
        t.defineNewCov("SNL");
        t.defineNewCov("SKP");
        t.defineNewCov("OSR");
        t.defineNewCov("HLT");
        t.defineNewCov("CLA_CLL");
        t.defineNewCov("CLA1");
        t.defineNewCov("CLL");
        t.defineNewCov("CIA");
        t.defineNewCov("CMA");
        t.defineNewCov("CML");
        t.defineNewCov("RTR");
        t.defineNewCov("RAR");
        t.defineNewCov("RTL");
        t.defineNewCov("RAL");
        t.defineNewCov("IAC");
        t.defineNewCov("NOP");
        t.defineNewCov("JMP");
        t.defineNewCov("JMS");
        t.defineNewCov("DCA");
        t.defineNewCov("ISZ");
        t.defineNewCov("TAD");
        t.defineNewCov("AND");
    end
endtask

final begin
    dummy = chkr.printLogSummary();
    dummy = tracker.printCoverageReport();
end
    
logic prevStall;
logic justStalled;
assign justStalled = (~prevStall & stall);
bit firstInstruction;

// Clock driven logic.
// When not reset, monitors the instruction
// busses for new instructions and follows
// the execution path for each one, running
// all defined rules in the process.
always @(posedge clk) begin
    if(~reset_n) begin
        prevStall <= 1'b0;
        firstInstruction = 1'b1;
    end else begin
        prevStall <= stall;
        if (hasNewInstruction(current_instr) & justStalled) begin
            if (firstInstruction) begin
                dummy = chkr.runRule(25, base_addr === `START_ADDRESS);
                dummy = chkr.runRule(26, PC_value === base_addr);
                firstInstruction = 1'b0;
            end
            dummy = chkr.runRule(3, stall);
            if (chkr.runRule(12,instrIsLegal(current_instr))) begin
                handleInstruction(current_instr);
            end else begin
                $display("Illegal Instruction Detected: %p", current_instr);
            end
        end
    end
end

// Helper Tasks//Functions
    
// handleInstruction - Encapsulates code necessary
// to follow an injected instruction and run
// necessary checks on it
task handleInstruction (input instruction_pack instr);
begin
    ruleBit = 1;
    if (isMemType(instr)) begin
        handleMemoryInstr(instr.memCode);
    end else if (isOp7Type(instr)) begin
        handleOp7Instr(instr.op7Code);
    end
    if (ruleBit) begin
        // Rule bit will only be true if all the
        // rules for a given instrucion are passed.
        // We only want to observe the instruction
        // for coverage purposes if it passed all rules.
        observeInstruction(tracker, instr);
    end
end
endtask
    
// This will call observe for the instruction
// contained in "instr"
task observeInstruction (
input CovTracker t,
input instruction_pack instr
);
begin
    if (instr.op7Code.NOP)          t.observe("NOP");
    else if (instr.op7Code.IAC)     t.observe("IAC");
    else if (instr.op7Code.RAL)     t.observe("RAL");
    else if (instr.op7Code.RTL)     t.observe("RTL");
    else if (instr.op7Code.RAR)     t.observe("RAR");
    else if (instr.op7Code.RTR)     t.observe("RTR");
    else if (instr.op7Code.CML)     t.observe("CML");
    else if (instr.op7Code.CMA)     t.observe("CMA");
    else if (instr.op7Code.CIA)     t.observe("CIA");
    else if (instr.op7Code.CLL)     t.observe("CLL");
    else if (instr.op7Code.CLA1)    t.observe("CLA1");
    else if (instr.op7Code.CLA_CLL) t.observe("CLA_CLL");
    else if (instr.op7Code.HLT)     t.observe("HLT");
    else if (instr.op7Code.OSR)     t.observe("OSR");
    else if (instr.op7Code.SKP)     t.observe("SKP");
    else if (instr.op7Code.SNL)     t.observe("SNL");
    else if (instr.op7Code.SZL)     t.observe("SZL");
    else if (instr.op7Code.SZA)     t.observe("SZA");
    else if (instr.op7Code.SNA)     t.observe("SNA");
    else if (instr.op7Code.SMA)     t.observe("SMA");
    else if (instr.op7Code.SPA)     t.observe("SPA");
    else if (instr.op7Code.CLA2)    t.observe("CLA2");
    else if (instr.memCode.AND)     t.observe("AND");
    else if (instr.memCode.TAD)     t.observe("TAD");
    else if (instr.memCode.ISZ)     t.observe("ISZ");
    else if (instr.memCode.DCA)     t.observe("DCA");
    else if (instr.memCode.JMS)     t.observe("JMS");
    else if (instr.memCode.JMP)     t.observe("JMP");
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
    
/***************** OP7 Instruction Tasks ********************
 Tasks related to handling the rule checking of OP7 opcode
 instructions being passed into the execution unit.
 *
 ***********************************************************/
  
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

// handleOp7Instr Encapsulates code necessary
// to track and run checkers for op7 opcodes
task handleOp7Instr (
    pdp_op7_opcode_s opCode
);
begin
    if      (opCode.NOP)     handleNOP(opCode);
    else if (opCode.CLA_CLL) handleCLA_CLL(opCode);
    else                     handleNOP(opCode);
end
endtask

task handleNOP (
    pdp_op7_opcode_s opCode
);
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
begin
    ruleBit &= chkr.runRule(3, stall, "Rule 3 NOP Failure");
    waitNClocks(1);
    ruleBit &= chkr.runRule(3, stall, "Rule 3 NOP Failure");
    waitNClocks(1);
    ruleBit &= chkr.runRule(3, stall, "Rule 3 NOP Failure");
    waitNClocks(1);
    ruleBit &= chkr.runRule(4,~stall, "Rule 4 NOP Failure");
    expected_PC = local_PC_value + 1;
    if (!chkr.runRule(7, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("PC_value not properly updated during NOP. Expected: %p Actual: %p", expected_PC,PC_value);
    end
end
endtask
    
task handleCLA_CLL (
    pdp_op7_opcode_s opCode
);
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
begin
    ruleBit &= chkr.runRule(3, stall, "Rule 3 CLA_CLL Failure");
    waitNClocks(1);
    ruleBit &= chkr.runRule(3, stall, "Rule 3 CLA_CLL Failure");
    waitNClocks(1);
    ruleBit &= chkr.runRule(3, stall, "Rule 3 CLA_CLL Failure");
    ruleBit &= chkr.runRule(23, wb_intAcc === 0);
    ruleBit &= chkr.runRule(24, ~wb_intLink);
    waitNClocks(1);
    ruleBit &= chkr.runRule(4,~stall, "Rule 4 CLA_CLL Failure");
    expected_PC = local_PC_value + 1;
    if (!chkr.runRule(7, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("PC_value not properly updated during CLA_CLL. Expected: %p Actual: %p", expected_PC,PC_value);
    end
end
endtask

/***************** Memory Instruction Tasks ********************
 Tasks related to handling the rule checking of memory opcode
 instructions being passed into the execution unit.
 *
 **************************************************************/

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


task memANDInstr (
    input pdp_mem_opcode_s instr
);
automatic logic [`DATA_WIDTH:0] temp_intAcc = wb_intAcc;
logic [`DATA_WIDTH-1:0] temp_rdData;
automatic integer clkCount = 0;
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
begin
    ruleBit &= chkr.runRule(3, stall);
    // Wait for the read request to come through
    wait(exec_rd_req) begin
        waitNClocks(1);
        clkCount = clkCount + 1;
        ruleBit &= chkr.runRule(3, stall);
    end
    if (!chkr.runRule(1, exec_rd_addr === instr.mem_inst_addr)) begin
        ruleBit = 0;
        $display ("Expected Read Address: %d    Actual Read Address: %d", instr.mem_inst_addr, exec_rd_addr);
    end
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    temp_rdData = exec_rd_data;
    temp_intAcc = temp_intAcc & temp_rdData;
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    ruleBit &= chkr.runRule(2, temp_intAcc === wb_intAcc);
    waitNClocks(1);
    clkCount = clkCount + 1;
    if (!chkr.runRule(5, clkCount === 4)) begin
        ruleBit = 0;
        $display("Expected 4 clock cycles from branch to stall de-asserting for AND");
    end
    if (!chkr.runRule(4, ~stall)) begin
        ruleBit = 0;
        $display("Stall not de-asserted after 4 clock cycles for AND");
    end
    expected_PC = local_PC_value + 1;
    if (!chkr.runRule(7, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("PC_value not properly updated during AND. Expected: %p Actual: %p", expected_PC,PC_value);
    end
end
endtask
    
task memISZInstr (
    input pdp_mem_opcode_s instr
);
automatic logic [`DATA_WIDTH:0] temp_intAcc = wb_intAcc;
logic [`DATA_WIDTH-1:0] temp_rdData;
automatic integer clkCount = 0;
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
logic [`DATA_WIDTH-1:0] wrData_expected;
begin
    ruleBit &= chkr.runRule(3, stall);
    // Wait for the read request to come through
    wait(exec_rd_req) begin
        waitNClocks(1);
        clkCount = clkCount + 1;
        ruleBit &= chkr.runRule(3, stall);
    end
    if (!chkr.runRule(20, exec_rd_addr === instr.mem_inst_addr)) begin
        ruleBit = 0;
        $display ("Expected Read Address: %d    Actual Read Address: %d", instr.mem_inst_addr, exec_rd_addr);
    end
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    temp_rdData = exec_rd_data;
    wait(exec_wr_req) begin
        waitNClocks(1);
        clkCount = clkCount + 1;
        ruleBit &= chkr.runRule(3, stall);
    end
    wrData_expected = temp_rdData + 1;
    if(!chkr.runRule(21, exec_wr_data === wrData_expected)) begin
        ruleBit = 0;
        $display("ISZ Command did not provide correct write data. Expected: %p  Actual: %p", wrData_expected,exec_wr_data);
    end
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(1);
    clkCount = clkCount + 1;
    if (temp_rdData === 0) begin
        expected_PC = local_PC_value + 2;
    end else begin
        expected_PC = local_PC_value + 1;
    end
    if(!chkr.runRule(7, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("ISZ PC_value error. Expected: %p  Actual: %p", expected_PC,PC_value);
    end
    if (!chkr.runRule(4, ~stall)) begin
        ruleBit = 0;
        $display("Stall not de-asserted after 4 clock cycles for AND");
    end
    if (!chkr.runRule(22, clkCount === 5)) begin
        ruleBit = 0;
        $display("ISZ Clock Count Expected: %p  Actual: %p", 5, clkCount);
    end
end
endtask
    
task memTADInstr (
    input pdp_mem_opcode_s instr
);
automatic logic [`DATA_WIDTH:0] temp_intAcc = wb_intAcc;
logic [`DATA_WIDTH-1:0] temp_rdData;
automatic integer clkCount = 0;
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
begin
    ruleBit &= chkr.runRule(3, stall);
    // Wait for the read request to come through
    wait(exec_rd_req) begin
        waitNClocks(1);
        clkCount = clkCount + 1;
        ruleBit &= chkr.runRule(3, stall);
    end
    if (!chkr.runRule(13, exec_rd_addr === instr.mem_inst_addr)) begin
        ruleBit = 0;
        $display ("Expected Read Address: %d    Actual Read Address: %d", instr.mem_inst_addr, exec_rd_addr);
    end
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    temp_rdData = exec_rd_data;
    temp_intAcc = temp_intAcc + temp_rdData;
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    ruleBit &= chkr.runRule(14, temp_intAcc === wb_intAcc);
    waitNClocks(1);
    clkCount = clkCount + 1;
    if (!chkr.runRule(15, clkCount === 4)) begin
        ruleBit = 0;
        $display("Expected 4 clock cycles from branch to stall de-asserting for ADD");
    end
    if (!chkr.runRule(4, ~stall)) begin
        ruleBit = 0;
        $display("Stall not de-asserted after 4 clock cycles for ADD");
    end
    expected_PC = local_PC_value + 1;
    if (!chkr.runRule(7, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("PC_value not properly updated during ADD. Expected: %p Actual: %p", expected_PC,PC_value);
    end
end
endtask
    
task memDCAInstr (
    input pdp_mem_opcode_s instr
);
automatic logic [`DATA_WIDTH:0] temp_intAcc = wb_intAcc;
automatic integer clkCount = 0;
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
begin
    ruleBit &= chkr.runRule(3, stall);
    wait(exec_wr_req) begin
        waitNClocks(1);
        clkCount = clkCount + 1;
        ruleBit &= chkr.runRule(3, stall);
    end
    if(!chkr.runRule(16, exec_wr_addr === instr.mem_inst_addr)) begin
        ruleBit = 0;
        $display("Incorrect DCA address. Expected: %p  Actual: %p", instr.mem_inst_addr, exec_wr_addr);
    end
    if(!chkr.runRule(17, exec_wr_data === temp_intAcc[`DATA_WIDTH-1:0])) begin
        ruleBit = 0;
        $display("Incorrect DCA data. Expected: %p  Actual: %p", temp_intAcc[`DATA_WIDTH-1:0],exec_wr_data);
    end
    waitNClocks(1);
    clkCount = clkCount + 1;
    ruleBit &= chkr.runRule(3, stall);
    if(!chkr.runRule(18, wb_intAcc === 0));
    waitNClocks(1);
    clkCount = clkCount + 1;
    expected_PC = local_PC_value + 1;
    if(!chkr.runRule(11, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("PC_value not properly updated during DCA. Expected: %p Actual: %p", expected_PC,PC_value);
    end
    if(!chkr.runRule(4, ~stall)) begin
        ruleBit = 0;
        $display("Stall not de-asserted when expected for DCA command");
    end
    if(!chkr.runRule(19, clkCount === 3)) begin
        ruleBit = 0;
        $display("DCA command number of clocks incorrect  Expected: %p  Actual: %p", 3, clkCount);
    end
end
endtask
    
task memJMSInstr (
    input pdp_mem_opcode_s instr
);
automatic integer clkCount = 0;
automatic logic [`ADDR_WIDTH-1:0] local_PC_value = PC_value;
logic [`ADDR_WIDTH-1:0] expected_PC;
logic [`ADDR_WIDTH-1:0] wrData_expected;
begin
    ruleBit &= chkr.runRule(3, stall);
    wait(exec_wr_req) begin
        waitNClocks(1);
        clkCount = clkCount + 1;
        ruleBit &= chkr.runRule(3, stall);
    end
    if(!chkr.runRule(8, exec_wr_addr === instr.mem_inst_addr)) begin
        ruleBit = 0;
        $display("Incorrect JMS address. Expected: %p  Actual: %p", instr.mem_inst_addr, exec_wr_addr);
    end
    wrData_expected = local_PC_value + 1;
    if(!chkr.runRule(9, exec_wr_data === wrData_expected)) begin
        ruleBit = 0;
        $display("Incorrect JMS data. Expected: %p  Actual: %p", wrData_expected,exec_wr_data);
    end
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(1);
    clkCount = clkCount + 1;
    waitNClocks(1);
    expected_PC = instr.mem_inst_addr + 1;
    if(!chkr.runRule(11, PC_value === expected_PC)) begin
        ruleBit = 0;
        $display("PC_value not properly updated during JMS. Expected: %p Actual: %p", expected_PC,PC_value);
    end
    clkCount = clkCount + 1;
    if(!chkr.runRule(10, clkCount === 3)) begin
        ruleBit = 0;
        $display("JMS Instruction did not take expected (3) number of clock cycles. Actual: %p", clkCount);
    end
    if(!chkr.runRule(4, ~stall)) begin
        ruleBit = 0;
        $display("JMS Instruction did not de-assert stall when expected");
    end
end    
endtask
    
task memJMPInstr (
    input pdp_mem_opcode_s instr
);
begin
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(2);
    ruleBit &= chkr.runRule(3, stall);
    waitNClocks(1);
    if (!chkr.runRule(6, PC_value === instr.mem_inst_addr)) begin
        ruleBit = 0;
        $display("PC Value Expected: %d  Actual: %d", instr.mem_inst_addr, PC_value);
    end
    if (!chkr.runRule(4, ~stall)) begin
        ruleBit = 0;
        $display("Stall not de-asserted after 2 clock cycles for JMP");
    end
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
