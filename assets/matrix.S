	.file	"matrix.c"
	.text
	.align	2
	.globl	matrix
	.type	matrix, @function
matrix:
.LFB0 = .
	beq	$r7,$r0,.L1
	slli.w	$r12,$r7,9
	or	$r20,$r5,$r0
	add.w	$r8,$r20,$r12
	or	$r5,$r4,$r0
	add.w	$r4,$r6,$r12
.L3:
	or	$r18,$r6,$r0
	or	$r19,$r5,$r0
.L5:
	ld.w	$r17,$r19,0
	or	$r16,$r20,$r0
	or	$r12,$r18,$r0
	or	$r15,$r0,$r0
.L4:
	ld.w	$r14,$r16,0
	ld.w	$r13,$r12,0
	addi.w	$r12,$r12,4
	mul.w	$r14,$r17,$r14
	addi.w	$r15,$r15,1
	addi.w	$r16,$r16,4
	add.w	$r13,$r13,$r14
	st.w	$r13,$r12,-4
	bne	$r7,$r15,.L4
	addi.w	$r18,$r18,512
	addi.w	$r19,$r19,512
	bne	$r4,$r18,.L5
	addi.w	$r20,$r20,512
	addi.w	$r5,$r5,4
	bne	$r20,$r8,.L3
.L1:
	jr	$r1
.LFE0:
	.size	matrix, .-matrix
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB1 = .
	addi.w	$r3,$r3,-16
.LCFI0 = .
	lu12i.w	$r4,-2143289344>>12			# 0xffffffff80400000
	addi.w	$r7,$r0,96			# 0x60
	lu12i.w	$r6,-2143158272>>12			# 0xffffffff80420000
	lu12i.w	$r5,-2143223808>>12			# 0xffffffff80410000
	st.w	$r1,$r3,12
.LCFI1 = .
	bl	matrix
	ld.w	$r1,$r3,12
.LCFI2 = .
	or	$r4,$r0,$r0
	addi.w	$r3,$r3,16
.LCFI3 = .
	jr	$r1
.LFE1:
	.size	main, .-main
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
	.align	2
.LEFDE1:
.LSFDE3:
	.4byte	.LEFDE3-.LASFDE3
.LASFDE3:
	.4byte	.LASFDE3-.Lframe1
	.4byte	.LFB1
	.4byte	.LFE1-.LFB1
	.byte	0x4
	.4byte	.LCFI0-.LFB1
	.byte	0xe
	.byte	0x10
	.byte	0x4
	.4byte	.LCFI1-.LCFI0
	.byte	0x81
	.byte	0x1
	.byte	0x4
	.4byte	.LCFI2-.LCFI1
	.byte	0xc1
	.byte	0x4
	.4byte	.LCFI3-.LCFI2
	.byte	0xe
	.byte	0
	.align	2
.LEFDE3:
	.ident	"GCC: (GNU) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
