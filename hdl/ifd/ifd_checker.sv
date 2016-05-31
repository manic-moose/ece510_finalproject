/*
 * ifd_checker
 * Serves as a passive checker/scoreboard for monitoring
 * the IFD's communication with surrounding
 * hierachies to ensure all required transactions are
 * taking place and correct.
 *
 * Author: Chip Wood chawood@pdx.edu
 */


/* things to check for
 * 1. single instruction at a time - DONE
 * 2. memory turned into instruction correctly - DONE
 * 3. opcode cleared before new one is output
 * 4. base address output correctly after reset - DONE
 */
 

`define IFD_RULE_FILE         "ifd_rules.txt"
`define IFD_RULE_DISABLE_FILE "ifd_rules_disable.txt"

module ifd_checker(
    input clk,                              // Free running clock
    input reset_n,                          // Active low reset signal

    // memory interface
    // from instr_decode module
    input                   ifu_rd_req,
    input [`ADDR_WIDTH-1:0] ifu_rd_addr,
    // to instr_decode module
    input [`DATA_WIDTH-1:0] ifu_rd_data,
    
    // exec unit interface
    // From instr_decode module
    input [`ADDR_WIDTH-1:0] base_addr,      // Address for first instruction
    input pdp_mem_opcode_s pdp_mem_opcode,  // Decoded signals for memory instructions
    input pdp_op7_opcode_s pdp_op7_opcode,  // Decoded signals for op7 instructions
    // To instr_decode module
    input                   stall,          // Signal to stall instruction decoder
    input [`ADDR_WIDTH-1:0] PC_value        // Current value of Program Counter
);

localparam VERBOSE = 0;
localparam DEBUG = 1;

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

// initial setup of checker/tracker classes
initial begin
    tracker = new();
    defineCovLabels(tracker);
    chkr = new(`IFD_RULE_FILE, `IFD_RULE_DISABLE_FILE);
    chkr.setVerbose(VERBOSE);
    //$monitor("current instr: %p", current_instr);
end

// detecting stall transitions
logic prevStall, justStalled;
assign justStalled = (~prevStall & stall);
bit firstInstruction;

// detecting instruction transitions
logic prevInstruction, currentInstruction, newInstruction;
always @(posedge clk) begin
    prevInstruction <= currentInstruction;
    currentInstruction <= isMemType(current_instr) || isOp7Type(current_instr);
end
assign newInstruction = (~prevInstruction & currentInstruction);

// tracking new read requests to base opcode-zeroing off of
logic prevRdReq, newRdReq;
assign newRdReq = (~prevRdReq & ifu_rd_req);

// Clock driven logic.
// When not resetting, monitors the instruction
// busses for new instructions and memory reads
always @(posedge clk) begin
    if(~reset_n) begin
        prevStall <= 1'b0;
        prevRdReq <= 1'b0;
        firstInstruction = 1'b1;
    end else begin
        prevStall <= stall;
        prevRdReq <= ifu_rd_req;
        // check opcode was cleared properly
        if (newRdReq) begin
            dummy <= chkr.runRule(3, opcodesZeroed(current_instr));
        end
        
        // check current instruction output
        if (hasNewInstruction(current_instr) & justStalled) begin
        //if (newInstruction) begin
            if (firstInstruction) begin
                dummy <= chkr.runRule(25, base_addr === `START_ADDRESS);
                firstInstruction <= 1'b0;
            end
            if (chkr.runRule(1, instrIsLegal(current_instr))) begin
                // check if instruction was decoded properly
                if (chkr.runRule(2, instrIsCorrect(current_instr))) begin
                    observeInstruction(tracker, current_instr);
                end else begin
                    $display("Incorrect conversion from memory %p to instruction %p", ifu_rd_data, current_instr);
                end
            end else begin
                $display("Illegal Instruction Detected: %p", current_instr);
            end
        end
    end
end


////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
// helper functions

/*********************************************************
 * Tasks related to handling the rule checking of opcode
 * instructions being driven from the IFD
 *********************************************************/

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

// instrIsCorrect - returns true if instruction decoding
// matches expected value based on memory data
function instrIsCorrect (
    input instruction_pack instr
);
begin
    if (isMemType(instr) && isOp7Type(instr)) begin
        $display("uh oh shaggy, not good");
    end
    else if (isOp7Type(instr)) begin
             if (instr.op7Code.IAC)        return ifu_rd_data == `IAC;
        else if (instr.op7Code.RAL)        return ifu_rd_data == `RAL;
        else if (instr.op7Code.RTL)        return ifu_rd_data == `RTL;
        else if (instr.op7Code.RAR)        return ifu_rd_data == `RAR;
        else if (instr.op7Code.RTR)        return ifu_rd_data == `RTR;
        else if (instr.op7Code.CML)        return ifu_rd_data == `CML;
        else if (instr.op7Code.CMA)        return ifu_rd_data == `CMA;
        else if (instr.op7Code.CIA)        return ifu_rd_data == `CIA;
        else if (instr.op7Code.CLL)        return ifu_rd_data == `CLL;
        else if (instr.op7Code.CLA1)       return ifu_rd_data == `CLA1;
        else if (instr.op7Code.CLA_CLL)    return ifu_rd_data == `CLA_CLL;
        else if (instr.op7Code.HLT)        return ifu_rd_data == `HLT;
        else if (instr.op7Code.OSR)        return ifu_rd_data == `OSR;
        else if (instr.op7Code.SKP)        return ifu_rd_data == `SKP;
        else if (instr.op7Code.SNL)        return ifu_rd_data == `SNL;
        else if (instr.op7Code.SZL)        return ifu_rd_data == `SZL;
        else if (instr.op7Code.SZA)        return ifu_rd_data == `SZA;
        else if (instr.op7Code.SNA)        return ifu_rd_data == `SNA;
        else if (instr.op7Code.SMA)        return ifu_rd_data == `SMA;
        else if (instr.op7Code.SPA)        return ifu_rd_data == `SPA;
        else if (instr.op7Code.CLA2)       return ifu_rd_data == `CLA2;
        // all others are NOPs, aka not decoded. Return happy go lucky fun times.
        else if (instr.op7Code.NOP)        return 1;
    end
    else if (isMemType(instr)) begin
        if      (instr.memCode.AND) return ifu_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == `AND;
        else if (instr.memCode.TAD) return ifu_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == `TAD;
        else if (instr.memCode.ISZ) return ifu_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == `ISZ;
        else if (instr.memCode.DCA) return ifu_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == `DCA;
        else if (instr.memCode.JMS) return ifu_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == `JMS;
        else if (instr.memCode.JMP) return ifu_rd_data[`DATA_WIDTH-1:`DATA_WIDTH-3] == `JMP;
        return instr.memCode.mem_inst_addr === ifu_rd_data[`DATA_WIDTH-4:0];
    end
    $display("also not good, shaggy");
    return 0;
end
endfunction

function opcodesZeroed(
    input instruction_pack instr
);
logic op7Zeroed, memZeroed, memAddrZeroed, memOpZeroed;
begin
    //
    op7Zeroed = instr.op7Code == 'd0;
    //memAddrZeroed = instr.memCode.mem_inst_addr === 'bZ; // uhhh this doesn't work for some reason. Neat.
    memAddrZeroed = 1'b1;
    memOpZeroed = (!instr.memCode.AND &
                   !instr.memCode.TAD &
                   !instr.memCode.ISZ &
                   !instr.memCode.DCA &
                   !instr.memCode.JMS &
                   !instr.memCode.JMP);
    memZeroed = memAddrZeroed & memOpZeroed;
    //$display("op7Zeroed=%p, memZeroed=%p, mem_instr_addr=%p, memAddrZeroed=%p, memOpZeroed=%p", op7Zeroed, memZeroed, instr.memCode.mem_inst_addr, memAddrZeroed, memOpZeroed);
    return op7Zeroed & memZeroed;
end
endfunction


/*********************************************************
 * Coverage related tasks
 *********************************************************/

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
        t.defineNewCov("NOP");
    end
endtask

final begin
    dummy = chkr.printLogSummary();
    dummy = tracker.printCoverageReport();
end

// This will call observe for the instruction
// contained in "instr"
task observeInstruction (
input CovTracker t,
input instruction_pack instr
);
begin
    if      (instr.op7Code.NOP)     t.observe("NOP");
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
    else if (instr.op7Code.NOP)     t.observe("NOP");
    else if (instr.memCode.AND)     t.observe("AND");
    else if (instr.memCode.TAD)     t.observe("TAD");
    else if (instr.memCode.ISZ)     t.observe("ISZ");
    else if (instr.memCode.DCA)     t.observe("DCA");
    else if (instr.memCode.JMS)     t.observe("JMS");
    else if (instr.memCode.JMP)     t.observe("JMP");
end
endtask

    



endmodule

