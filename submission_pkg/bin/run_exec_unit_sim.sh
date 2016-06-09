#!/bin/sh

SOURCE="$0"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
UNIT_DIR=$SCRIPT_DIR/../execution_unit

cd $UNIT_DIR

TOP_HIER=top
COV_DIR=$UNIT_DIR/coverage
COV_DB=$COV_DIR/coverage.ucdb

# Compile
vlog -f vfiles.f >& compile.log

# Simulate with coverage collection
vsim -c -do "coverage save -onexit $COV_DB; run -all;exit" -coverage -voptargs="+cover=bcfst" $TOP_HIER >& simulation.log

# Generate coverage report
vcover report -html -details -htmldir $COV_DIR/html -verbose -threshL 50 -threshH 90 $COV_DB
