#!/bin/sh

SOURCE="$0"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"

cd $SCRIPT_DIR

TOP_HIER=pdp_top
COV_DIR=$SCRIPT_DIR/coverage
COV_DB=$COV_DIR/coverage.ucdb

# Compile
vlog -sv -mfcu -f pdp_top.f

# Simulate with coverage collection
vsim -c -do "coverage save -onexit $COV_DB; run -all;exit" -coverage -voptargs="+cover=bcfst" $TOP_HIER

# Generate coverage report
vcover report -html -details -htmldir $COV_DIR/html -verbose -threshL 50 -threshH 90 $COV_DB
