`include "CovTracker.sv"
import CovTracker_pkg::*;

class CovSequencer;
    
    CovTracker trackers[$];    
    
    function new();
    endfunction
    
    task addTracker(CovTracker t);
        trackers.push_front(t);
    endtask
    
    function allSequencesEqual();
        foreach (trackers[k]) begin
            foreach (trackers[j]) begin
                if (!trackers[k].sequencesMatch(trackers[j])) begin
                    return 0;
                end
            end
        end
        return 1;
    endfunction

    
    function compareToSequence(string seq_q[$]);
        if (!allSequencesEqual()) begin
            return 0;
        end else if (trackers.size() == 0)
            return 0;
        else begin
            return CovTracker::compareSequences(seq_q, trackers[0].sequence_queue);
        end
    endfunction
    
endclass
