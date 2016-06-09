timeunit 1ns;
timeprecision 1ns;

`include "CheckerClass.sv"
`include "CovSequencer.sv"

module SequenceMonitor(
    input CovTracker ifdTracker,
    input CovTracker execTracker
);

    parameter MODE = 0;
    
    logic disabler = 0;
    
    CovSequencer sequencer;
    localparam SEQ_LABEL = "CLA_CLL->TAD->TAD->DCA->HLT->JMP";
    string bonus_sequence[$] = {"CLA_CLL","TAD","TAD","DCA","HLT","JMP"};
    
    CovTracker crossFuncTracker;

    bit obsFlag;
    
    always begin
        #1ns;
        if (MODE == 0) begin
            if (execTracker != null) obsFlag = execTracker.observationFlag;
            if (ifdTracker  != null) obsFlag = obsFlag & ifdTracker.observationFlag;
        end else if (MODE == 1) begin
            if (ifdTracker != null)  obsFlag = ifdTracker.observationFlag;
        end else if (MODE == 2) begin
            if (execTracker != null) obsFlag = execTracker.observationFlag;
        end
    end
    
    initial begin
        crossFuncTracker = new("SequenceMonitor");
        crossFuncTracker.defineNewCov(SEQ_LABEL);
        sequencer = new();
        if (MODE == 0) begin
            wait(execTracker != null && ifdTracker != null);
            sequencer.addTracker(execTracker);
            sequencer.addTracker(ifdTracker);
        end else if (MODE == 1) begin
            wait(ifdTracker != null);
            sequencer.addTracker(ifdTracker);
        end else if (MODE == 2) begin
            wait(execTracker != null);
            sequencer.addTracker(execTracker);
        end else
            disabler = 1;
    end
    
    always @(obsFlag) begin
        if (!disabler & obsFlag) begin
            if(sequencer.compareToSequence(bonus_sequence)) begin
                crossFuncTracker.observe(SEQ_LABEL);
            end
            clearObsFlags();
        end
    end
    
    final begin
        crossFuncTracker.printCoverageReport();
    end

    task clearObsFlags ();
    begin
        if (ifdTracker != null)  ifdTracker.clearObsFlag();
        if (execTracker != null) execTracker.clearObsFlag();
    end
    endtask
    
endmodule
