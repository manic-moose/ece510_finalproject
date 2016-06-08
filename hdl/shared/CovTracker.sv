/* CovTracker - Simple utility to use for adding very
 * basic coverage metrics. Provides commands 
 * adding definitions of events to observe. The definition
 * is just a label of the event. Provides a method to call
 * when the event is observed to add to the observed methods
 * count. Provides a method to print out a report of the coverage
 * metrics when complete (just a table of each defined event and the
 * number of times each has been observed.
 */
class CovTracker;
    
    local int CovDefs[string];
    local string unitName;
    
    function new (string unitName = "");
        this.unitName = unitName;
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
            $display("EVENT               OBSERVATIONS");
            foreach (this.CovDefs[i]) begin
                $display("%-20s%p",i,this.CovDefs[i]);
            end
            $display("\n");
            return 0;
        end
    endfunction
    
endclass
