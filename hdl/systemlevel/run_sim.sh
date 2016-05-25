#!/bin/bash

vlog -sv -mfcu -f pdp_top.f

vsim -c -do "run -all;exit" pdp_top
