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
    
    function new ();
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
        begin
            $display("EVENT\t\t\t\tOBSERVATIONS");
            foreach (this.CovDefs[i]) begin
                $display("%p\t\t\t\t%p",i,this.CovDefs[i]);
            end
            return 0;
        end
    endfunction
    
endclass