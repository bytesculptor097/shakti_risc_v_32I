.equ IO_BASE, 0x400000
.section .text
.globl start
start:
    li   gp, IO_BASE   /* Global pointer for I/O (not used in C code) */
    li   sp, 0x1800    /* Stack pointer at top of 6KB RAM */
    call main          /* Call main function */
    ebreak             /* Halt if main returns */
