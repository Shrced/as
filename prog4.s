	.arch armv8-a
	.data
	.align 3
//-1<x<1
//n>0
input_mes:
	.asciz "Enter x, n: "
input_prot:
	.asciz "%f %f"
lb_res:
	.asciz "Lib: %.7f\n"
my_res:
	.asciz "My: %.7f\n"
error_mes:
	.asciz "Incorrect input\n"
member_prot:
	.asciz "%d %.7f\n"
mode:
	.asciz "w"
fd:
	.skip 4
space:
	.asciz ".7f\n"

filename:
	.asciz "output.txt"

	.text
	.align 2
	.global main
	.type main, %function
	.equ x,16		//sdvig
	.equ n,24
	.equ size,32
main:
	sub sp,sp,size
	stp x29, x30,[sp]
	mov x29,sp		//saving x29
	ldr x0, = input_mes
	bl printf	//input x,n
	ldr x0,=input_prot
	add x1, x29,x
	add x2, x29,n
	bl scanf
	cmp x0,#2
	bne error	//error with scanf
	
			//liblary res arcsinx then print it
	ldr s0,[x29,x]
	fcvt d0,s0
	bl asin
	ldr x0,=lb_res
	bl printf	//print lib res
//////////////////////////////////
	ldr s0,[x29,x]
	ldr s1,[x29,n]
	bl counter
	//printing result
	fcvt d0,s0
	ldr x0,=my_res
	bl printf
	mov w0,#1
	b exit
exit:
	ldp x29,x30,[sp]
	add sp,sp,size
	ret
	.size main, .-main
error:
	adr x0,stderr
	ldr x0,[x0]
	ldr x1,= error_mes
	bl fprintf
	mov w0,#1
	b exit


	.global write_member
	.type write_member, %function
	.text
	.align 2
write_member:
	//s0- value x0- number
	sub sp,sp,#16
	stp x29,x30,[sp]
	mov x29,sp
	fcvt d0,s0
	mov x2,x0
	ldr x0,=fd
	ldr x0,[x0]
	ldr x1,=member_prot
	bl fprintf
	ldp x29,x30,[sp]
	add sp,sp,#16
	ret
	.size write_member, .-write_member

.global factorial
	.type factorial, %function
	.text
	.align 2
factorial:
	//x0- value
	sub sp,sp, #16
	stp x29,x30,[sp]
	mov x29,sp
	cmp x0,#0
	beq 11f
	mov x1,#1 //counter
	mov x2,#1 //value of factorial
33:
	cmp x1,x0
	bgt 44f
	mul x2,x2,x1
	add x1,x1,#1
	b 33b	
44:
	mov x0,x2
	b 22f
11:
	mov x0,#1
	b 22f
22:
	ldp x29,x30,[sp]
	add sp,sp,#16
	ret
	.size factorial, .-factorial

	.global my_pow
	.type my_pow, %function
	.text
	.align 2
my_pow:
	sub sp,sp,#16
	stp x29,x30,[sp]
	mov x29,sp
	mov x2,#1   //counter
	fmov s10,#1.0	//value
1:
	cmp x2,x0
	bgt 2f
	fmul s10,s10,s0
	add x2,x2,#1
	b 1b
2:
	fmov s0,s10
	ldp x29,x30,[sp]
	add sp,sp,#16
	ret
	.size my_pow, .-my_pow




	.global counter
	.type counter, %function
	.text
	.align 2
	//s0=x,s1=n
counter:
	.equ x,16
	.equ n,20
	.equ counter_number,24
	.equ size,32
	mov x20,#0
	sub sp,sp,size
	stp x29,x30,[sp]	//saving x29 x30
	add sp,sp,#16
	stp s0,s1,[sp]	//saving x n
	add sp,sp,#8
	str x20,[sp]	//counter 0
	mov x20,#24	//counter
	sub sp,sp, x20
	mov x29,sp
	bl file_op
	fmov s2,wzr	// (2n)!
	fmov s3,wzr	//4^n
	fmov s4,wzr	//n!)^2
	fmov s5,wzr	//2n+1
	fmov s6,wzr	//x^(2n+1)
	fmov s7, wzr	//sum
	fmov s8,wzr	//previous member of series
1:
	//(2n)!
	ldr x0,[x29,counter_number]
	mov x15,#2
	mul x0,x0,x15
	bl factorial
	scvtf s2,x0
	
	//4^n
	fmov s0,#4.0
	ldr x0,[x29,counter_number]
	bl my_pow
	fmov s3,s0
	
	//n!^2
	ldr x0,[x29,counter_number]
	bl factorial
	mul x0,x0,x0
	scvtf s4,x0
	
	//2n+1
	ldr x0,[x29,counter_number]
	mov x15, #2
	mul x0,x0,x15
	add x0, x0, #1
	scvtf s5,x0
	
	//x^(2n+1)
	ldr s0,[x29,x]
	ldr x0,[x29,counter_number]
	mov x15,#2
	mul x0,x0,x15
	add x0,x0,#1
	bl my_pow
	fmov s6,s0
	
	//member calculating
	fmul s2,s2,s6
	fmul s3,s3,s4
	fmul s3,s3,s5
	fdiv s2,s2,s3
	fmov s0,s2
	
	//saving membrr
	stp s0,s2,[sp,#-8]!
	stp s7,s8,[sp,#-8]!
	ldr x0,[x29,counter_number]
	bl write_member
	ldp s7,s8,[sp],#8
	ldp s0,s2,[sp],#8
	ldr x15,[x29,counter_number]
	add x15,x15,#1
	str x15,[x29,counter_number]
	cmp x15,#1
	beq 2f
	ldr s1,[x29,n]
	fsub s9,s8,s0
	fcmp s1,s9
	bgt 3f
	b 2f
	
2:
	fmov s8,s0
	fadd s7,s7,s0
	b 1b
3:
	fmov s0,s7
	bl file_cl
	ldp x29,x30,[sp]
	add sp,sp,size
	ret
	.size counter, .-counter
	
	
	
		
	

	
	
.global file_op
.type file_op, %function
	.text
	.align 2
file_op:
	//x1 mode x0 name
	sub sp,sp, #16
	stp x29,x30,[sp]
	ldr x0,=filename
	ldr x1,=mode
	bl fopen
	ldr x1,=fd
	str x0,[x1]
	ldp x29,x30,[sp]
	add sp,sp,#16
	ret
	.size file_op, .-file_op

.global file_cl
.type 	file_cl, %function
	.text
	.align 2
file_cl:
	sub sp,sp,#16
	stp x29,x30,[sp]
	ldr x0,=fd
	ldr x0,[x0]
	bl fclose
	ldp x29,x30,[sp]
	add sp,sp,#16
	ret
	.size file_cl, .-file_cl	
	
		
	
	
