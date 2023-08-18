	.file	"p2021.c"
	.text
	.align	2
	.globl	quick_sort
	.type	quick_sort, @function
quick_sort:
.LFB0 = .
	bge	$r4,$r5,.L17
	addi.w	$r3,$r3,-16
.LCFI0 = .
	st.w	$r24,$r3,4
	st.w	$r25,$r3,0
	st.w	$r1,$r3,12
	st.w	$r23,$r3,8
.LCFI1 = .
	or	$r25,$r5,$r0
	la.local	$r24,b
.L2:
	ld.w	$r13,$r24,0
	or	$r23,$r25,$r0
	or	$r5,$r4,$r0
	add.w	$r12,$r13,$r4
	ld.b	$r14,$r12,0
.L10:
	add.w	$r12,$r13,$r23
	ld.b	$r12,$r12,0
	or	$r17,$r23,$r0
	bge	$r12,$r14,.L21
	addi.w	$r23,$r23,-1
	bgt	$r23,$r5,.L10
	add.w	$r12,$r13,$r23
	ld.b	$r12,$r12,0
	add.w	$r13,$r13,$r5
	or	$r17,$r23,$r0
	st.b	$r12,$r13,0
	ld.w	$r15,$r24,0
	or	$r16,$r5,$r0
	or	$r23,$r5,$r0
	add.w	$r12,$r15,$r5
	ld.b	$r13,$r12,0
	addi.w	$r5,$r5,-1
.L8:
	add.w	$r15,$r15,$r17
	st.b	$r13,$r15,0
	ld.w	$r12,$r24,0
	add.w	$r12,$r12,$r16
	st.b	$r14,$r12,0
	bl	quick_sort
	addi.w	$r4,$r23,1
	blt	$r4,$r25,.L2
	ld.w	$r1,$r3,12
.LCFI2 = .
	ld.w	$r23,$r3,8
.LCFI3 = .
	ld.w	$r24,$r3,4
.LCFI4 = .
	ld.w	$r25,$r3,0
.LCFI5 = .
	addi.w	$r3,$r3,16
.LCFI6 = .
	jr	$r1
.L21:
.LCFI7 = .
	add.w	$r13,$r13,$r5
	st.b	$r12,$r13,0
	or	$r16,$r5,$r0
	ld.w	$r15,$r24,0
	bge	$r5,$r23,.L6
	add.w	$r12,$r15,$r5
	ld.b	$r13,$r12,0
	ble	$r13,$r14,.L12
.L9:
	addi.w	$r12,$r5,1
	add.w	$r13,$r15,$r12
	ld.b	$r13,$r13,0
	or	$r16,$r12,$r0
	beq	$r12,$r23,.L8
	or	$r5,$r12,$r0
	blt	$r14,$r13,.L9
	add.w	$r15,$r15,$r23
	st.b	$r13,$r15,0
	ld.w	$r13,$r24,0
	or	$r5,$r12,$r0
	b	.L10
.L12:
	add.w	$r15,$r15,$r23
	or	$r12,$r5,$r0
	st.b	$r13,$r15,0
	ld.w	$r13,$r24,0
	or	$r5,$r12,$r0
	b	.L10
.L17:
.LCFI8 = .
	jr	$r1
.L6:
.LCFI9 = .
	add.w	$r12,$r15,$r5
	or	$r23,$r5,$r0
	ld.b	$r13,$r12,0
	addi.w	$r5,$r5,-1
	b	.L8
.LFE0:
	.size	quick_sort, .-quick_sort
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB1 = .
	addi.w	$r3,$r3,-32
.LCFI10 = .
	st.w	$r1,$r3,28
.LCFI11 = .
	or	$r20,$r0,$r0
	la.local	$r6,a
	la.local	$r5,b
	addi.w	$r19,$r0,100			# 0x64
	ori	$r4,$r0,3000			# 0xbb8
.L53:
	ld.w	$r13,$r6,0
	slli.w	$r12,$r20,2
	or	$r17,$r0,$r0
	add.w	$r12,$r13,$r12
	ld.w	$r16,$r12,0
	addi.w	$r18,$r16,40
.L52:
	ld.w	$r7,$r16,0
	ld.b	$r15,$r7,0
	ld.b	$r13,$r7,1
	add.w	$r12,$r15,$r13
	bgt	$r15,$r13,.L23
.L64:
	beq	$r15,$r13,.L54
	ble	$r13,$r19,.L55
	or	$r9,$r15,$r0
	addi.w	$r10,$r0,101			# 0x65
.L24:
	ld.b	$r14,$r7,2
	add.w	$r12,$r14,$r12
	or	$r8,$r14,$r0
	ble	$r13,$r14,.L26
	st.w	$r15,$r3,8
	ld.b	$r8,$r3,8
	st.b	$r15,$r3,8
	bge	$r8,$r14,.L27
	st.b	$r14,$r3,8
.L27:
	or	$r8,$r13,$r0
	ld.b	$r13,$r3,8
.L26:
	bge	$r9,$r14,.L28
	st.w	$r10,$r3,8
	st.w	$r14,$r3,12
	ld.b	$r11,$r3,8
	ld.b	$r15,$r3,12
	st.b	$r10,$r3,8
	ble	$r11,$r15,.L29
	st.b	$r14,$r3,8
.L29:
	or	$r14,$r9,$r0
	ld.b	$r9,$r3,8
.L28:
	ld.b	$r15,$r7,3
	add.w	$r12,$r15,$r12
	or	$r10,$r15,$r0
	ble	$r8,$r15,.L30
	st.w	$r13,$r3,8
	ld.b	$r10,$r3,8
	st.b	$r13,$r3,8
	bge	$r10,$r15,.L31
	st.b	$r15,$r3,8
.L31:
	or	$r10,$r8,$r0
	ld.b	$r8,$r3,8
.L30:
	bge	$r14,$r15,.L32
	st.w	$r9,$r3,8
	st.w	$r15,$r3,12
	ld.b	$r11,$r3,8
	ld.b	$r13,$r3,12
	st.b	$r9,$r3,8
	ble	$r11,$r13,.L33
	st.b	$r15,$r3,8
.L33:
	or	$r15,$r14,$r0
	ld.b	$r14,$r3,8
.L32:
	ld.b	$r13,$r7,4
	add.w	$r12,$r13,$r12
	or	$r9,$r13,$r0
	ble	$r10,$r13,.L34
	st.w	$r8,$r3,8
	ld.b	$r9,$r3,8
	st.b	$r8,$r3,8
	bge	$r9,$r13,.L35
	st.b	$r13,$r3,8
.L35:
	or	$r9,$r10,$r0
	ld.b	$r10,$r3,8
.L34:
	bge	$r15,$r13,.L36
	st.w	$r14,$r3,8
	st.w	$r13,$r3,12
	ld.b	$r8,$r3,8
	st.b	$r14,$r3,8
	ld.b	$r14,$r3,12
	ble	$r8,$r14,.L37
	st.b	$r13,$r3,8
.L37:
	or	$r13,$r15,$r0
	ld.b	$r15,$r3,8
.L36:
	ld.b	$r14,$r7,5
	add.w	$r12,$r14,$r12
	or	$r8,$r14,$r0
	ble	$r9,$r14,.L38
	st.w	$r10,$r3,8
	ld.b	$r8,$r3,8
	st.b	$r10,$r3,8
	bge	$r8,$r14,.L39
	st.b	$r14,$r3,8
.L39:
	or	$r8,$r9,$r0
	ld.b	$r9,$r3,8
.L38:
	bge	$r13,$r14,.L40
	st.w	$r15,$r3,8
	st.w	$r14,$r3,12
	ld.b	$r10,$r3,8
	st.b	$r15,$r3,8
	ld.b	$r15,$r3,12
	ble	$r10,$r15,.L41
	st.b	$r14,$r3,8
.L41:
	or	$r14,$r13,$r0
	ld.b	$r13,$r3,8
.L40:
	ld.b	$r15,$r7,6
	or	$r10,$r15,$r0
	add.w	$r12,$r12,$r15
	ble	$r8,$r15,.L60
	st.w	$r9,$r3,8
	ld.b	$r11,$r3,8
	st.b	$r9,$r3,8
	bge	$r11,$r15,.L43
	st.b	$r15,$r3,8
.L43:
	or	$r9,$r8,$r0
	or	$r11,$r8,$r0
	ld.b	$r8,$r3,8
.L42:
	bge	$r14,$r15,.L44
	st.w	$r13,$r3,8
	st.w	$r15,$r3,12
	ld.b	$r10,$r3,8
	st.b	$r13,$r3,8
	ld.b	$r13,$r3,12
	ble	$r10,$r13,.L45
	st.b	$r15,$r3,8
.L45:
	or	$r10,$r14,$r0
	or	$r15,$r14,$r0
	ld.b	$r14,$r3,8
.L44:
	ld.b	$r7,$r7,7
	ble	$r11,$r7,.L46
	st.w	$r8,$r3,8
	ld.b	$r13,$r3,8
	st.b	$r8,$r3,8
	bge	$r13,$r7,.L47
	st.b	$r7,$r3,8
.L47:
	add.w	$r13,$r12,$r7
	sub.w	$r12,$r13,$r9
	ld.b	$r9,$r3,8
.L46:
	bge	$r15,$r7,.L48
	st.w	$r14,$r3,8
	ld.b	$r13,$r3,8
	sub.w	$r12,$r12,$r9
	st.b	$r14,$r3,8
	sub.w	$r12,$r12,$r10
	ble	$r13,$r7,.L49
	st.b	$r7,$r3,8
.L49:
	ld.b	$r13,$r3,8
	addi.w	$r16,$r16,4
	sub.w	$r12,$r12,$r13
	srli.w	$r12,$r12,2
	add.w	$r17,$r17,$r12
	bne	$r16,$r18,.L52
.L51:
	ld.w	$r12,$r5,0
	add.w	$r12,$r12,$r20
	st.b	$r17,$r12,0
	addi.w	$r20,$r20,1
	bne	$r20,$r4,.L53
	or	$r4,$r0,$r0
	ori	$r5,$r0,2999			# 0xbb7
	bl	quick_sort
	ld.w	$r1,$r3,28
.LCFI12 = .
	or	$r4,$r0,$r0
	addi.w	$r3,$r3,32
.LCFI13 = .
	jr	$r1
.L48:
.LCFI14 = .
	sub.w	$r12,$r12,$r9
	sub.w	$r12,$r12,$r7
	sub.w	$r12,$r12,$r10
	srli.w	$r12,$r12,2
	addi.w	$r16,$r16,4
	add.w	$r17,$r17,$r12
	beq	$r18,$r16,.L51
	ld.w	$r7,$r16,0
	ld.b	$r15,$r7,0
	ld.b	$r13,$r7,1
	add.w	$r12,$r15,$r13
	ble	$r15,$r13,.L64
.L23:
	st.w	$r13,$r3,12
	ld.b	$r14,$r3,12
	st.b	$r13,$r3,8
	bge	$r14,$r0,.L25
	addi.w	$r14,$r0,-1			# 0xffffffffffffffff
	st.b	$r14,$r3,8
.L25:
	or	$r10,$r15,$r0
	or	$r9,$r13,$r0
	or	$r13,$r15,$r0
	ld.b	$r15,$r3,8
	b	.L24
.L60:
	or	$r9,$r15,$r0
	or	$r11,$r15,$r0
	b	.L42
.L55:
	or	$r10,$r13,$r0
	or	$r9,$r15,$r0
	b	.L24
.L54:
	or	$r10,$r15,$r0
	or	$r9,$r15,$r0
	b	.L24
.LFE1:
	.size	main, .-main
	.globl	b
	.data
	.align	2
	.type	b, @object
	.size	b, 4
b:
	.word	-2143049344
	.globl	a
	.align	2
	.type	a, @object
	.size	a, 4
a:
	.word	-2143289344
	.section	.eh_frame,"aw",@progbits
.Lframe1:
	.4byte	.LECIE1-.LSCIE1
.LSCIE1:
	.4byte	0
	.byte	0x3
	.ascii	"\000"
	.byte	0x1
	.byte	0x7c
	.byte	0x1
	.byte	0xc
	.byte	0x3
	.byte	0
	.align	2
.LECIE1:
.LSFDE1:
	.4byte	.LEFDE1-.LASFDE1
.LASFDE1:
	.4byte	.LASFDE1-.Lframe1
	.4byte	.LFB0
	.4byte	.LFE0-.LFB0
	.byte	0x4
	.4byte	.LCFI0-.LFB0
	.byte	0xe
	.byte	0x10
	.byte	0x4
	.4byte	.LCFI1-.LCFI0
	.byte	0x98
	.byte	0x3
	.byte	0x99
	.byte	0x4
	.byte	0x81
	.byte	0x1
	.byte	0x97
	.byte	0x2
	.byte	0x4
	.4byte	.LCFI2-.LCFI1
	.byte	0xa
	.byte	0xc1
	.byte	0x4
	.4byte	.LCFI3-.LCFI2
	.byte	0xd7
	.byte	0x4
	.4byte	.LCFI4-.LCFI3
	.byte	0xd8
	.byte	0x4
	.4byte	.LCFI5-.LCFI4
	.byte	0xd9
	.byte	0x4
	.4byte	.LCFI6-.LCFI5
	.byte	0xe
	.byte	0
	.byte	0x4
	.4byte	.LCFI7-.LCFI6
	.byte	0xb
	.byte	0x4
	.4byte	.LCFI8-.LCFI7
	.byte	0xe
	.byte	0
	.byte	0xc1
	.byte	0xd7
	.byte	0xd8
	.byte	0xd9
	.byte	0x4
	.4byte	.LCFI9-.LCFI8
	.byte	0xe
	.byte	0x10
	.byte	0x81
	.byte	0x1
	.byte	0x97
	.byte	0x2
	.byte	0x98
	.byte	0x3
	.byte	0x99
	.byte	0x4
	.align	2
.LEFDE1:
.LSFDE3:
	.4byte	.LEFDE3-.LASFDE3
.LASFDE3:
	.4byte	.LASFDE3-.Lframe1
	.4byte	.LFB1
	.4byte	.LFE1-.LFB1
	.byte	0x4
	.4byte	.LCFI10-.LFB1
	.byte	0xe
	.byte	0x20
	.byte	0x4
	.4byte	.LCFI11-.LCFI10
	.byte	0x81
	.byte	0x1
	.byte	0x4
	.4byte	.LCFI12-.LCFI11
	.byte	0xa
	.byte	0xc1
	.byte	0x4
	.4byte	.LCFI13-.LCFI12
	.byte	0xe
	.byte	0
	.byte	0x4
	.4byte	.LCFI14-.LCFI13
	.byte	0xb
	.align	2
.LEFDE3:
	.ident	"GCC: (GNU) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
