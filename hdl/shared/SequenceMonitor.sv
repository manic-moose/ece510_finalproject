module SequenceMonitor(
    input clk,
    input CovTracker ifdTracker,
    input CovTracker execTracker
);
    parameter MODE = 0;
    
    logic disabler = 0;
    
    CovSequencer sequencer;
    localparam SEQ_LABEL = "CLA_CLL->TAD->TAD->DCA->HLT->JMP";
    string bonus_sequence[$] = {"CLA_CLL","TAD","TAD","DCA","HLT","JMP"};
    
    CovTracker crossFuncTracker;
    
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
    
    always @(posedge clk) begin
        if (!disabler) begin
            if(sequencer.compareToSequence(bonus_sequence)) begin
                crossFuncTracker.observe(SEQ_LABEL);
                if (ifdTracker != null)  ifdTracker.clearSequence();
                if (execTracker != null) execTracker.clearSequence();
            end
        end
    end
    
    final begin
        crossFuncTracker.printCoverageReport();
    end
    
endmodule