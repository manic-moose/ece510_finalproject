#!/bin/bash

TOP_HIER=ifd_tb
COV_DIR=$PWD/coverage
COV_DB=$COV_DIR/coverage.ucdb

# Compile
vlog -sv -mfcu -f ifd.f

# Simulate with coverage collection
vsim -c -do "coverage save -onexit $COV_DB; run -all;exit" -coverage -voptargs="+cover=bcfst" $TOP_HIER

# Generate coverage report
vcover report -html -details -htmldir $COV_DIR/html -verbose -threshL 50 -threshH 90 $COV_DB
