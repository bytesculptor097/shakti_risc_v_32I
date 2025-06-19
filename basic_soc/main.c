#include <stdint.h>

#define UART_BASE ((volatile uint8_t*)0x00000100)

void uart_putchar(char c) {
    *UART_BASE = c;
}

void _start() {
    asm volatile("la sp, _stack_top");

    while (1) {
        uart_putchar('S');
        uart_putchar('H');
        uart_putchar('A');
        uart_putchar('K');
        uart_putchar('T');
        uart_putchar('I');
        uart_putchar('\n');
        uart_putchar('\r');

        for (volatile int i = 0; i < 100000; i++);
    }
}
