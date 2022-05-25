	.arch armv8-a
//	string symbol=1byte
	.data

mes1:
	.ascii "Enter string: "
	.equ 	mes1len, .-mes1

bufff:
	.skip 64
mes3:
	.string "File exists. Rewrite?(y/n)\n"
	.equ mes3len, .-mes3

answer:
	.skip 3
	
newstr:
	
	.skip 1024

buf:
	.skip 10
	.equ buflen, .-buf
fd:
	.skip 8

//x20 shift
//x21 file des
//x22 const '\n'
//x23 const '\0'
//x24 filename



 	.text
	.align	2
	.global _start
	.type _start, %function
_start:
mov x21, #0	//file descriptor
mov x22, '\n'
mov x23, '\0'
	//finding shift and filename
	bl getenv
	cmp x0, #-7 	//bad variables
	beq write_error
//x0 -shift x1 filename
// convert shift to integer
	mov x24, x1 //save filename
	bl shift
	cmp x0,#-22	//bad shift
	beq write_error
	mov x20,x0	//shift in int format range 0-25
	
//now create file or overwrite it
	mov x1,x24
	mov x0,#-100
	mov x2,#0xc1
	mov x3, #0600
	mov x8, #56
	svc #0
	cmp x0, #-17
	//if it is new file go to 3f
	bne 3f
	//else
	//write message about rewriting
	
	mov x0,#1
	adr x1,mes3
	mov x2,mes3len
	mov x8,#64
	svc #0
	mov x0,#0
	//write answer
	adr x1, answer
	mov x2,#3
	mov x8,#63
	svc #0
	cmp x0,#2
	beq ans
	mov x0,#-17
	b write_error
ans:
	adr x1,answer
	ldrb w0,[x1]
	cmp w0,['y']
	beq rewrite
	mov x0,#-17
	b write_error
rewrite:
	mov x0,#-100
	mov x1,x24	//filename
	mov x2, #0x201
	mov x3, #0600
	mov x8,#56
	svc #0
3:
	cmp x0,#0
	blt write_error
	mov x21,x0	//file descriptor
	//enter string
	mov x0,#1
	adr x1,mes1
	mov x2,mes1len
	mov x8,#64
	svc #0
	mov x0,#0
	adr x1, buf
	mov x2,#64
	mov x8,#63

	svc #0
	mov x26,x0
	adr x1, bufff
	ldr x1,[x1]
	
	bl work
	mov x0,x21
	mov x8,#57
	svc #0
	mov x0,#0
	mov x8,#93
	svc #0
	.size _start, .-_start
	
	
.type work, %function
.text
.align 2
work:
	sub sp, sp, #16
	mov x29,sp
	stp x29,x30,[sp]
	
	mov x1,#0	//word counter
	mov x2,#0	//string counter
	mov x10,x26	//entering string
	mov x0,#0 // word begining
	mov x11,x1	//tmpbuf
	mov x12,x2	//len of string
	mov x13,x20	//N
	mov x14,x21	//file des
	mov x15, #64	//size buf
	
1:
	ldrb w6,[x10,x2]
	cmp w6, ' '
	beq 2f
	cmp w6, '\t'
	beq 2f
	cmp w6,'\n'
	beq 4f
	cmp w6, #0
	beq 3f
	mov x0,x10	//word beggining(first symbol)
	add x0,x0,x2
	add x2,x2,#1
	b 5f
	
2:
	add x2,x2,#1
	cmp x15,#0	//check buffer 
	beq 1b
	mov x28,#1
	b 44f
5:
	ldrb w6,[x10,x2]
	cmp w6, ' '
	beq 11f
	cmp w6, '\t'
	beq 11f
	cmp w6, #0
	beq 22f
	cmp w6,'\n'
	beq 33f
	add x2,x2,#1	//skip
	b 5b

33:
	mov x28,#0
	b 6f
11:
	mov x28,#1
	b 6f
6:	//sum bykv of word
	mov x1,x10
	add x1,x1,x2
	sub x1,x1,x0
	cmp x15,#0	//check buffer
	bne 8f
	
7:
	sub sp,sp,#16
	stp x0,x1,[sp]
	sub sp,sp,#16
	stp x2,x28,[sp]
	bl change
	ldp x2,x28,[sp]
	add sp,sp,#16
	ldp x0,x1,[sp]
	add sp,sp,#16
	mov x16,x0

	mov x17,x1
mov x18,x2
	mov x0,x14	//file des
	mov x1,x16
	mov x2,x17
	//write
	mov x0,x14
//	mov x1, x11	//file buf
	mov x8,#64
	svc #0
	cmp x0,#0
	beq write_error	
	mov x0,x16
	mov x1,x17
	mov x2,x18
	b 1b
	
8:	//buf not empty
	mov x5,#0
	mov x7,x15
9:
	ldrb w6,[x0,x5]
	strb w6,[x11,x7]
	add x5,x5,#1
	add x7,x7,#1
	cmp x5,x1
	bne 9b
	add x15,x15,x1


44:
	mov x0,x11
	mov x1,x15
	mov x15,#0
	b 7b

	
22: // copy start of word in buffer
	mov x1,x10
	add x1,x1,x2
	sub x1,x1,x0
	mov x5,#0
23:	
	ldrb w6,[x0,x5]
	strb w6,[x11,x5]
	add x5,x5,#1
	cmp x5,x1
	bne 23b
	mov x15,x1
	b 3f
	// n 23 0 22



4:	//write \n in file
	cmp x15,#0
	bne 44b
mov x0,x14
	
	mov x1,x10
	add x1,x1,x2
	mov x2,#1
	mov x28,#0
	mov x8,#64
	svc #0
	cmp x0,#0
	beq write_error
	b 3f
3:
	ldp x29,x30,[sp]
	add sp,sp,#16
	mov x27,#64
	str x15,[x27]
	ret
	.size work, .-work
	

	.type change, %function
	.text
	.align 2
change:
	sub sp,sp,#16
	stp x29,x30,[sp]
	mov x29,sp
	
	mov x28,#0
	udiv x3,x2,x1
	mul x3,x3,x1
	sub x3,x2,x3
	//mwithout shift
	cmp x3,x1
	beq 3f
	mov x4,#0	//shift count counter
0:
	cmp x4,x3
	beq 3f
	ldrb w5,[x0]
	mov x6,#1
	mov x8,#1
1:
	cmp x8,x1
	beq 2f
	ldrb w7,[x0,x6]
	sub x6,x6,#1
	strb w7,[x0,x6]
	add x6,x6,#2
	add x8,x8,#1
	b 1b
2:
	sub x6,x1,#1
	strb w5,[x0,x6]
	add x4,x4,#1
	b 0b
3:
	ldp x29,x30,[sp]
	add sp,sp,#16
	ret
	.size change, .-change


	
	.type write_error, %function
	.data
usage:
	.string "Programm does not require parameters\n"
	.equ usagelen, .-usage
nofile:
	.string "No such file or directory\n"
	.equ nofilelen, .-nofile
permission:
	.string "Permission denied\n"
	.equ permissionlen, .-permission
exist:
	.string "File exists\n"
	.equ existlen, .-exist
isdir:
	.string "Is a directory\n"
	.equ isdirlen, .-isdir
toolong:
	.string "File name too long\n"
	.equ toolonglen, .-toolong
readerror:
	.string "Error reading filename\n"
	.equ readerrorlen, .-readerror
unknown:
	.string "Unknown error\n"
	.equ unknownlen, .-unknown
	.text
	.align 2
write_error:
	cbnz x0,0f
	adr x1,usage
	mov x2,usagelen
	b 7f
0:
	cmp x0,#-2
	bne 1f
	adr x1,nofile
	mov x2,nofilelen
	b 7f
1:
	cmp x0,#-13
	bne 2f
	adr x1,permission
	mov x2,permissionlen
	b 7f
2:
	cmp x0,#-17
	bne 3f
	adr x1,exist
	mov x2,existlen
	b 7f
3:
	cmp x0,#-21
	bne 4f
	adr x1,isdir
	mov x2,isdirlen
	b 7f
4:
	cmp x0,#-36
	bne 5f
	adr x1,toolong
	mov x2,toolonglen
	b 7f
5:
	cmp x0,#1
	bne 6f
	adr x1,readerror
	mov x2,readerrorlen
	b 7f
6:
	adr x1, unknown
	mov x2, unknownlen
7:
	mov x0,#2
	mov x8,#64
	svc #0
	ret
	.size write_error, .-write_error

	.type shift, %function
	.text
	.align 2
	
shift:
	mov x1,#0	//x1 current symbol
	mov x3,#0	//number
	ldrb w1,[x0]	//where x0 adress of input shift
	cmp w1,#45	//if minus x2=1,else=0
	cset x2,eq
	//go to the end of number and count symbols
	mov x4,#0	//couner
	
1:
	add x4,x4,#1
	ldrb w1,[x0,x4]
	cmp w1,#0
	bne  1b
	sub x8,x4,x2
	cmp x8,#18	//if number too big
	bgt 3f
	//get value
	mov x5,x4
	mov x6,#1
	mov x7,#10	//for mul
	mov x8,#26
2:
	cmp x5,x2
	beq 4f
	sub x5,x5,#1
	ldrb w1,[x0,x5]
	//check if it a number(from 48 -57 ascii)
	cmp w1,#48
	blt 3f
	cmp w1,#57
	bgt 3f
	
	sub x1,x1,#48
	madd x3,x6,x1,x3 //number +=t*s[i]
	mul x6,x6,x7	//t=t*10
	b 2b
3:
	mov x0,#-22	//invalid
	b 5f
4:
	udiv x4,x3,x8
	msub x0,x4,x8,x3 //mod of shift i range 0-25
	cmp x2,#1
	bne 5f
	sub x0,x8,x0	//if shift negative x0=26-x0
	cmp x0,#26	//if x0 was sero,x0=26->x0=0
	csel x0,xzr,x0,eq
5:
	ret
	.size shift, .-shift

	.type getenv, %function
	.data
variable1:
	.asciz "SHIFT="
variable2:
	.asciz "OUTPUT="

	//x0-adress shift
	//x1 adress output
	//x7 temp for var1
	//x8 temp for var2
	//x6-current symbol of env value
	//x4 symbol of var1
	//x5 symbol of var2
	.text
	.align 2
getenv:
	mov x0,sp	//adress for env vars
	mov x7,#0
	mov x8,#0
0:	//go to env vars
	ldr x1,[x0],#8
	cmp x1,#0
	bne 0b
1:
	ldr x1,[x0],#8
	adr x2,variable1
	adr x3,variable2
	cmp x1,#0	//check if it is 0
	beq err
	ldrb w6,[x1],#1
	ldrb w4,[x2],#1
	ldrb w5,[x3],#1
	cmp w6,w4
	bne 3f
	//check if it is var1
2:
	ldrb w6,[x1],#1
	ldrb w4,[x2],#1
	cmp w6,w4
	bne 1b
	cmp w6,'='	//it is var1
	bne 2b
	mov x7,x1	
	b 5f	//find var2

3:
	cmp w6,w5
	bne 1b

	//check if it is var2
4:	ldrb w6,[x1],#1
	ldrb w5,[x3],#1
	cmp w6,w5
	bne 1b
	cmp w6,'='	//it is var2
	bne 4b
	mov x8,x1
	b 7f
5:	//var 1 founded,find var2
	ldr x1,[x0],#8
	adr x3,variable2
	cmp x1,#0	//check if it is 0
	beq err
6:
	ldrb w6,[x1],#1
	ldrb w5,[x3],#1
	cmp w6,w5
	bne 5b
	cmp w6,'='
	bne 6b
	mov x0,x7
	b 9f	//out:x6->x0 var1 adr,x1- var2 adr


7:	//var2 found,find var1
	ldr x1,[x0],#8
	adr x2,variable1
	cmp x1,#0
	beq err
8:
	ldrb w6,[x1],#1
	ldrb w4,[x2],#1
	cmp w6,w4
	bne 7b
	cmp w6,'='
	bne 8b
	mov x0,x8
	b 9f
	
err:
	mov x0,#-7
9:
	ret
	.size getenv, .-getenv




	

