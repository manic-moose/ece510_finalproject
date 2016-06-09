/ Program : Add01.pal
/ Date : March 3, 2002
/
/ Desc : This program computes c = a + b
/
/-------------------------------------------
/
/ Code Section
/
*0200			/ start at address 0200
Main, 	cla cll 	/ clear AC and Link
	tad A 		/ add A to Accumulator
	tad B 		/ add B
	dca C 		/ store sum at C
 nop     / do nothing
 iac     / increment accumulator
 rar     / rotate accumulator and link right
 cma     / complement accumulator
 sza     / skip on zero acc
 cia     / ???
 isz D   / increment and skip on 0
 skp     / skip
 skp     / skip
 cll     / clear link
 7104    / clear link (gets the opcode that matches pdp8_pkg.sv)
 cla     / clear accumulator
 iac     / increment accumulator
 rtr     / rotate accumulator and link twice
 ral     / rotate accumulator and link
 tad A   / add a to accumulator
 and B   / and B with accumulator
 dca D   / store acc at D
 iac     / increment acc
 dca E   / store acc at E
 cll cll / clear link/acc
 iac     / increment acc
 snl     / skip on nonzero link
 tad A   / add a to accumulator
 and B   / and B with accumulator
 dca D   / store acc at D
 iac     / increment acc
 dca E   / store acc at E
 sna     / skip on nonzero acc
 tad A   / add a to accumulator
 and B   / and B with accumulator
 dca D   / store acc at D
 iac     / increment acc
 dca E   / store acc at E
 skp     / skip
 tad A   / add a to accumulator
 and B   / and B with accumulator
 dca D   / store acc at D
 iac     / increment acc
 dca E   / store acc at E
 spa     / skip on positive acc
 tad A   / add a to acc
 cml     / complement link
 osr     / or switch reg with acc
 szl     / skip on zero link
 tad A   / add a to accumulator
 and B   / and B with accumulator
 dca D   / store acc at D
 iac     / increment acc
 dca E   / store acc at E
 sma     / skip on minus acc
 tad A   / add a to accumulator
 and B   / and B with accumulator
 dca D   / store acc at D
 iac     / increment acc
 dca E   / store acc at E
 //sma
 rtl
 7510
 7600
 //jms Main 
 cla cll
 tad A
 tad B
 dca C
	hlt 		/ Halt program
	jmp End / end program
 jms End
 
*0313
End, hlt

/

/ Data Section
/
*0306 			/ place data at address 0350
A, 	2 		/ A equals 2
B, 	3 		/ B equals 3
C, 	0
D,  0
E,  0


$Main 			/ End of Program; Main is entry point
