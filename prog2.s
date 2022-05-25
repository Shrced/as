	.arch armv8-a
//	matrix
	.data
	.align 3
n:
	.short 4
m:
	.short 3
matrix:
	.short 6, 2, 2, 7
	.short 2, 5, 8, 9
	.short 9, 1, 5, 0

	.text
	.align	2

	.type sum_counter, %function
	.global sum_counter
sum_counter:
	stp x29,x30,[sp,-16]!
L0:
         mov     x9, #0
         mov     x0, #0
         mov     x11, #0
         mul x16, x8, x1
         lsl x11, x16, #1
L1:
         cmp     x9, w1,sxtw
         bge	ExitFromSum
         ldrsh   x10, [x2,x11]
         add     x11, x11, #2
         add     x0, x0, x10
         add     x9, x9, #1
         b  L1
ExitFromSum:
	ldp x29,x30,[sp],16
	ret
	.size sum_counter, .-sum_counter

	.type compare, %function
	.global compare
compare: //x12 x13 compr x0-flag
if1:
	.ifdef REVERSE
	cmp x12,x13
	.else
	cmp x13, x12
	.endif
	cset x0,ge
	ret
	.size compare, .-compare
	

	.global _start	
	.type	_start, %function
_start:
	adr	x2, n
	ldrh	w1, [x2]
	adr 	x2, m
	ldrh	w3, [x2]
	adr 	x2, matrix
	//mov 	x4, #0 	//counter
	//lsl 	x6, x4, #1
	sub 	x4 ,x3, #1
	mov 	x5,  #0
	//mov 	x15, #1
L5:	
	cmp x5, x4
	bge Ending
	mov x6, x5
	mov x7, x5
	mov x8, x5 // for function to detect string 1 string
	
	bl sum_counter
	mov x12, x0
	
L6:	
	
	add x6, x6, #1
	cmp x6, w3,sxtw
	bge L8
	mov x8,x6 //for function to detect 2 string
	bl sum_counter
	mov x13, x0
L7:	

	//cmp x13, x12
	bl compare
	cmp x0,#1
	beq L6
	//bge L6
	mov x7, x6 //pixaem 2 stroke v nashem slycae 
	//mov x12, x13
	b L6
L8:	 
	//mov x18, #0
	mul x9, x5, x1
	mul x12, x7,x1
	lsl x6, x9, #1
	lsl x7, x12, #1
	//add x6, x2,x9, lsl #1
	//add x7, x2, x12, lsl #1
	mov x10, #0
L9:	
	cmp x10, w1,sxtw
	bge Nextit
	ldrsh x8, [x2,x6]
	ldrsh x9, [x2,x7]
	strh w8, [x2,x7]
	strh w9, [x2,x6]
	add x6, x6, #2
	add x7, x7, #2
	add x10, x10,#1
	b L9

Nextit:
	add x5,x5,#1
	b L5


Ending:
	mov x0,#0
	mov x8, #93
	svc #0                             
	.size	_start, .-_start

