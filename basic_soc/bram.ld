MEMORY {
    BRAM (RWX) : ORIGIN = 0x0000, LENGTH = 0x1800  /* 6kB RAM */
}
SECTIONS {
    everything : {
        . = ALIGN(4);
        start.o (.text)  /* Ensure startup code is first */
        *(.text .text.*) /* Program code */
        *(.rodata .rodata.*) /* Read-only data */
        *(.data .data.*) /* Initialized data */
        *(.bss .bss.*)   /* Uninitialized data */
        *(.*)            /* Catch-all */
    } >BRAM
}
