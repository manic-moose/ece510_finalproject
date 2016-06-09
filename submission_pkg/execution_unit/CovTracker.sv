/* CovTracker - Simple utility to use for adding very
 * basic coverage metrics. Provides commands 
 * adding definitions of events to observe. The definition
 * is just a label of the event. Provides a method to call
 * when the event is observed to add to the observed methods
 * count. Provides a method to print out a report of the coverage
 * metrics when complete (just a table of each defined event and the
 * number of times each has been observed.
 */

package CovTracker_pkg;

class CovTracker;
    
    local int CovDefs[string];
    local string unitName;

    bit observationFlag;
    
    string sequence_queue[$];
    local integer maxSequenceCount;
    
    function new (string unitName = "",
                 integer maxSequenceCount = 0
                 );
        this.observationFlag = 0;
        this.unitName = unitName;
        this.maxSequenceCount = maxSequenceCount;
    endfunction
    
    task defineNewCov (string name);
        begin
            this.CovDefs[name] = 0;
        end
    endtask
    
    task observe (string name);
        if (this.CovDefs.exists(name)) begin
            this.CovDefs[name] = this.CovDefs[name] + 1;
        end else begin
            this.CovDefs[name] = 1;
        end
        if (maxSequenceCount > 0) begin
            sequence_queue.push_back(name);
            if (sequence_queue.size() > this.maxSequenceCount) begin
                sequence_queue.pop_front();
            end
        end
        setObsFlag();
    endtask

    task clearObsFlag ();
    begin
        this.observationFlag = 0;
    end
    endtask

    task setObsFlag();
    begin
        this.observationFlag = 1;
    end
    endtask
    
    function printCoverageReport ();
        automatic real covPointCount = this.CovDefs.num();
        automatic real ObsCount      = 0.0;
        automatic real percent       = 0.0;
        begin
            foreach (this.CovDefs[i]) begin
                if (this.CovDefs[i] > 0)
                    ObsCount = ObsCount + 1.0;
            end
            percent = ObsCount/covPointCount * 100;
            $display("\nFunctional Coverage Summary: %s    Total Coverage: %f%%", this.unitName, percent);
            $display("EVENT                              OBSERVATIONS");
            foreach (this.CovDefs[i]) begin
                $display("%-35s%p",i,this.CovDefs[i]);
            end
            $display("\n");
            return 0;
        end
    endfunction
    
    function sequencesMatch(CovTracker t);
        return compareSequences(t.sequence_queue, this.sequence_queue);
    endfunction
    
    task clearSequence();
        this.sequence_queue.delete();
    endtask
    
    static function compareSequences(string seqa[$], string seqb[$]);
        if (seqa.size() != seqb.size()) begin
            return 0;
        end else begin
            foreach (seqa[k]) begin
                if (!(seqa[k] ==(seqb[k])))
                    return 0;
            end
        end
        return 1; 
    endfunction
    
endclass

endpackage
