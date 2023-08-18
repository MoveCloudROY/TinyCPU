	.file	"p2020.c"
	.text
	.section	.text.startup,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB0 = .
	lu12i.w	$r17,200704>>12			# 0x31000
	addi.w	$r15,$r0,1			# 0x1
	or	$r16,$r0,$r0
	ori	$r17,$r17,274
.L3:
	or	$r12,$r15,$r0
	or	$r13,$r0,$r0
.L2:
	addi.w	$r14,$r12,-1
	and	$r12,$r12,$r14
	addi.w	$r13,$r13,1
	bne	$r12,$r0,.L2
	addi.w	$r15,$r15,1
	add.w	$r16,$r16,$r13
	bne	$r15,$r17,.L3
	lu12i.w	$r12,-2143289344>>12			# 0xffffffff80400000
	st.w	$r16,$r12,0
	or	$r4,$r0,$r0
	jr	$r1
.LFE0:
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
	.ident	"GCC: (GNU) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
