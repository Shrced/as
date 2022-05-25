	.arch armv8-a
//	res=((a+b)^2-(c-d)^2)/(a+e^3-c)
	.data
	.align	3
res:
	.skip 8
a:
	.long	11111111
b:
	.long	2222222
c:
	.long	3333333
d:
	.short	40
e:
	.short	30
	.text
	.align	2
	.global _start	
	.type	_start, %function
_start:
	adr	x0, a
	ldr	w1, [x0]
	adr	x0, b
	ldr	w2, [x0]
	adr	x0, c
	ldr	w3, [x0]
	adr	x0, d
	ldrsh	w4, [x0]
	adr	x0, e
	ldrsh	w5, [x0]
	add 	w6, w1, w2
	smull	x6, w6, w6
	sub 	w7, w3, w4
	smull 	x7, w7, w7
	sub 	x6, x6, x7
	mul 	w8, w5, w5
	smull 	x8, w8, w5 
	add 	x8, x8, w1, sxtw
	sub 	x8, x8, w3, sxtw
	sdiv	x8, x6, x8
	adr 	x0, res
	str	x8, [x0]
	mov 	x0, #0
	mov	x8, #93
	svc	#0
	.size	_start, .-_start
