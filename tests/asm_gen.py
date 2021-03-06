########################################################################################################################
# Generate a random sequence of PDP-8 assembly commands
# Only using the commands supported by Professor Ahmad's PDP-8 SystemVerilog implementation
# Which is a rather small subset - all memory opcodes are supported but most 7xxx codes are not
# This is a good thing, as far as this script is concerned...
#
# Written by Chip Wood, Portland State University, June 2016
########################################################################################################################

# gotta write to files somehow
import os
# who doesn't like randomness
from random import randint

# beginning address for programs
startAddress = 200
# addressable  space in octal
addressSpace = [int('200', 8), int('7777', 8)]

# available memory opcodes
opMemCode = ['and', 'tad', 'isz', 'dca', 'jms', 'jmp']
# aaaaand available 7xxx opcodes
# again, only supporting those supported by Tareque Ahmad's SystemVerilog PDP-8 implementation
#op7Code = ['nop', 'cla', 'cll', 'cma', 'cml', 'iac', 'rar', 'rtr', 'ral', 'rtl', 'sma', 'sza', 'snl', 'spa', 'sna', 'szl', 'skp', 'osr', 'hlt', 'mql', 'mqa', 'swp', 'cam', 'cla cll', 'cia']
op7Code = ['nop', 'cla', 'cll', 'cma', 'cml', 'iac', 'rar', 'rtr', 'ral', 'rtl', 'sma', 'sza', 'snl', 'spa', 'sna', 'szl', 'skp', 'osr', 'hlt', 'cla cll', 'cia']
# remove duplicates because it's easier to do with code than manually purge the list
op7code = list(set(op7Code))
# and for convenience, stuff the opcodes into a single list
opcodes = opMemCode + op7Code

# some variables to use cuz i don't know what i'm doing
vars = ['a', 'b', 'c', 'd', 'e'] # 5 should be enough? whatever

# file name to write to
programName = 'randomTest.as'

def main():
    # 0 - open a file
    oup = open(programName, 'w+')

# 0.5 - set up start of program
    try:
        oup.write('*%04d\n' % (startAddress))

# 1 - generate a sequence of events using every opcode once
        # reserve HALT command for last, 
        usedCodes = ['hlt']
        i = 0
        print "generating random opcode sequence"
        # insert a cla_cll at the beginning to ensure
        # link and accumulator are zeroed out
        i+=1
        opcode = 'cla cll'
        usedCodes.append(opcode)
        oup.write(opcode+"\n")
        while i < len(opcodes)-1:
            i += 1
            command = ''
            # get a random opcode that hasn't been used yet
            opcode = opcodes[randint(0, len(opcodes)-1)]
            while opcode in usedCodes:
                opcode = opcodes[randint(0, len(opcodes)-1)]
            usedCodes.append(opcode)
            # determine if memory or op7 code
            if opcode in opMemCode:
                # pick a variable for the memory operation
                if opcode == 'jmp' or opcode == 'jms':
                    var = "%04s" % (oct(int(str(startAddress),8)+i+1))
                else:
                    var = vars[randint(0, len(vars)-1)]
                command = "%s %s" % (opcode, var)
            else:
                # op7 codes are cake
                command = opcode

            # write command to file and append a newline
            oup.write(command+"\n")
        oup.write('hlt\n\n')

# 2 - generate some variables and also pre-load the rest of the memory with junk
        print "generating some memory"
        # data section - leave space for program
        oup.write('*%04s\n' % (oct(int(str(startAddress),8)+len(opcodes)+1)))
        # creating variables
        for var in vars:
            # generate random numbers for the variables
            # don't get too crazy with the numbers, only use 6 bits
            oup.write('%s, %s\n' % (var, oct(randint(startAddress, startAddress+2**6))))

        oup.write('\n')
        
        # populate the rest of 

# 3 - force program to start at startAddress
        print "writing start address of program"
        oup.write('$%s\n'%(startAddress))

# 4 - Play catch
    except:
        print "something funky happened, code better next time"
        oup.close()
    print "fin!"
    oup.close()
    return

# the usual python shenanigans to force it to run main if no function/process/whatever was specified at run-time
if __name__ == '__main__':
    main()
