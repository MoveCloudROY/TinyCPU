    .section .text.entry
    .globl _start
_start:
    pcaddu12i       $r3,8
    b main

    .section .bss.stack
    .globl boot_stack
boot_stack:
    .space 4096 * 16
    .globl boot_stack_top
boot_stack_top:

