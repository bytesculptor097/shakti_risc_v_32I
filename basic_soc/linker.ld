ENTRY(_start)

MEMORY {
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 6K
}

SECTIONS {
  . = 0x00000000;

  .text : { *(.text*) } > RAM
  .rodata : { *(.rodata*) } > RAM
  .data : { *(.data*) } > RAM
  .bss : { *(.bss*) *(COMMON) } > RAM

  . = ALIGN(4);
  . = . + 0x1000;
  _stack_top = .;
}
