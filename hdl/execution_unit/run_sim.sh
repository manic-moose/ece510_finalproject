#!/bin/bash

vlog -sv -mfcu -f exec_unit.f

vsim -c -do "run -all;exit" exec_tb
