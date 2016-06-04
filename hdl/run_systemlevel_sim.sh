#!/bin/sh

SOURCE="$0"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
UNIT_DIR=$SCRIPT_DIR/systemlevel

cd $UNIT_DIR

TOP_HIER=pdp_top
COV_DIR=$UNIT_DIR/coverage
COV_DB=$COV_DIR/coverage.ucdb

EXE_RULE_FILE=\"$SCRIPT_DIR/execution_unit/exec_unit_rules.txt\"
EXE_RULE_DISABLE=\"$SCRIPT_DIR/execution_unit/exec_rule.disable\"
IFD_RULE_FILE=\"$SCRIPT_DIR/ifd/ifd_rules.txt\"
IFD_RULE_DISABLE=\"$SCRIPT_DIR/ifd/ifd_rules_disable.txt\"

# Compile
vlog -sv -mfcu +define+EXE_RULE_FILE=$EXE_RULE_FILE+EXE_RULE_DISABLE_FILE=$EXE_RULE_DISABLE+IFD_RULE_FILE=$IFD_RULE_FILE+IFD_RULE_DISABLE_FILE=$IFD_RULE_DISABLE -f pdp_top.f

# Simulate with coverage collection
vsim -c -do "coverage save -onexit $COV_DB; run -all;exit" -coverage -voptargs="+cover=bcfst" $TOP_HIER

# Generate coverage report
vcover report -html -details -htmldir $COV_DIR/html -verbose -threshL 50 -threshH 90 $COV_DB
