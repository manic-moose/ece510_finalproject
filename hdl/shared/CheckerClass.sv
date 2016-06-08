/* CheckerClass.sv - Class implements a few utilities
 * to be able to store away rule definitions in a text
 * file, run the rules in a checker module, and
 * keep track of the failing and passing rules.
 *
 * Also implemented is a mechanism to provide
 * a list of disabled rules via a different
 * text file.
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 */
class CheckerClass;
    local string ruleHash [integer];
    local bit ruleDisableHash[integer];

    // Keep track of how many rules run/pass/fail
    local integer unsigned ruleRunCount  [integer];
    local integer unsigned rulePassCount [integer];
    local integer unsigned ruleFailCount [integer];
    
    local bit VERBOSE;
    local bit dummy;

    local string checkerName;
    
    function new (
        string ruleFile,
        string ruleFileDisable = "",
        string checkerName = ""
    );
        begin
            dummy = readRuleFile(ruleFile,ruleFileDisable);
            this.checkerName = checkerName;
        end
    endfunction
    
    task setVerbose (
        bit verbose
    );
    begin
        this.VERBOSE = verbose;
    end
    endtask

    // runRule - Wrapper to check a rule 
    // condition and handle logging/tracking
    // of all checked rules.
    function bit runRule (
        input integer ruleNumber,
        input bit     rulePass,
        input string failMsg = ""
    );
    begin
        if (this.ruleHash.exists(ruleNumber)) begin
            if (!this.ruleDisableHash[ruleNumber]) begin
                this.ruleRunCount[ruleNumber] = this.ruleRunCount[ruleNumber] + 1;
                assert (rulePass) begin
                    this.rulePassCount[ruleNumber] = this.rulePassCount[ruleNumber] + 1;
                    if (this.VERBOSE) $display("PASS Rule %p - %p   Simulation Time: %p", ruleNumber, this.ruleHash[ruleNumber], $time);
                    return 1;
                end else begin
                    this.ruleFailCount[ruleNumber] = this.ruleFailCount[ruleNumber] + 1;
                    $display("FAIL Rule %p - %p   Simulation Time: %p", ruleNumber, this.ruleHash[ruleNumber], $time);
                    if (failMsg != "") $display("\t%p",failMsg);
                    return 0;
                end
            end
        end else begin
            $display("Rule number %d not found in rule file", ruleNumber); 
        end
    end
    endfunction

    // readRuleFile - Reads in fileName text
    // and populates the rule array with 
    // correct data
    function readRuleFile(
        string fileName,
        string disableFileName = ""
    );
    integer fileHandle;
    string ruleText;
    integer ruleNumber;
    string  ruleNumStr;
    string line;
    integer numLength;
    integer lineLength;
    begin
        fileHandle = $fopen(fileName, "r");
        if (!fileHandle) begin
            $display("An error has occurred when attempting to read %s.", fileName);
            $finish;
        end
        while(!$feof(fileHandle)) begin
            this.dummy = $fgets(line,fileHandle);
            lineLength = line.len();
            if (lineLength > 0) begin
                line = stringTrim(line);
                ruleNumStr = "";
                this.dummy = $sscanf(line,"%s ", ruleNumStr);
                numLength = ruleNumStr.len();
                if (numLength > 0 && line.substr(0,0) != "#") begin
                    ruleNumber = ruleNumStr.atoi();
                    line = line.substr(numLength,line.len()-1);
                    line = stringTrim(line);
                    // Update rule hash
                    this.ruleHash[ruleNumber] = line;
                    this.ruleRunCount[ruleNumber]  = 0;
                    this.rulePassCount[ruleNumber] = 0;
                    this.ruleFailCount[ruleNumber] = 0;
                    this.ruleDisableHash[ruleNumber] = 0;
                end else if (line.len() == 0 || line.substr(0,0) == "#") begin
                        // Ignore
                end else begin
                    $display("Illegal line in rules file: %s", line);
                end
            end
        end
        $fclose(fileHandle);
        if (disableFileName != "") dummy = readDisableFile(disableFileName);
        return 0;
    end
    endfunction

    // readDisableFile
    // Reads the disable file list
    function readDisableFile (
        string fileName
    );
    integer fileHandle;
    integer ruleNumber;
    string ruleNumStr;
    integer lineLength;
    string line;
    integer numLength;
    begin
        fileHandle = $fopen(fileName, "r");
        if (!fileHandle) begin
            $display("An error has occurred when attempting to read %s.", fileName);
            $finish;
        end
        while(!$feof(fileHandle)) begin
            dummy = $fgets(line,fileHandle);
            lineLength = line.len();
            if (lineLength > 0) begin
                line = stringTrim(line);
                ruleNumStr = "";
                dummy = $sscanf(line,"%s", ruleNumStr);
                numLength = ruleNumStr.len();
                if (numLength > 0 && line.substr(0,0) != "#") begin
                    ruleNumber = ruleNumStr.atoi();
                    this.ruleDisableHash[ruleNumber] = 1;
                end else if (line.len() == 0 || line.substr(0,0) == "#") begin
                        // Ignore
                end else begin
                    $display("Illegal line in rules file: %s", line);
                end
            end
        end
        return 0;
    end
    endfunction
    
    // Prints a summary of the rules that have been run and if they passed or failed
    function printLogSummary ();
    begin
        $display("\nRule Checker Summary: %s", this.checkerName);
        $display("RULE      TOTAL          PASS           FAIL           DESCRIPTION");
        foreach (ruleHash[i]) begin
            $display("%-10d%-15d%-15d%-15d%-80s",
                     i, this.ruleRunCount[i], this.rulePassCount[i], this.ruleFailCount[i], this.ruleHash[i]);
        end
        $display("\n");
        return 0;
    end
    endfunction
    
    // stringTrim - trim off extra whitespace characters around string
    static function string stringTrim (
        input string mystring
    );
    begin
        while (mystring.substr(0,0) == " " || mystring.substr(0,0) == "\t") begin
            mystring = mystring.substr(1, mystring.len()-1);
        end
        while (mystring.substr(mystring.len()-1,mystring.len()-1) == " "  || 
               mystring.substr(mystring.len()-1,mystring.len()-1) == "\t" ||
               mystring.substr(mystring.len()-1,mystring.len()-1) == "\n" ) begin
            mystring = mystring.substr(0,mystring.len()-2);
        end
        return mystring;
    end
endfunction
    
endclass
