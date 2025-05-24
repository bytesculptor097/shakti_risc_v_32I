

#  SHAKTI E-Class RISC-V Minimal SoC (Lattice FPGA)

This repo shows our journey of optimizing the SHAKTI E-Class RISC-V core and building a minimal SoC for small Lattice FPGAs.

* * *

##  Project Summary

Started with the full SHAKTI core, stripped it down, and built a clean SoC that runs on low-resource FPGAs.

* * *

##  Work Done So Far

### 1\. Core Optimization

*   Removed: CLINT, PMP, Debug logic
    
*   LUT usage reduced from >5k to ~3k
    
*   Tried BRAM-based FIFOs (in earlier tests) but skipped them in final SoC
    

### 2\. Minimal SoC Build

*   Used only the CPU core
    
*   Added BRAM for instruction memory
    
*   Memory-mapped UART at `0x90000000` using AXI4-Lite
    
*   Verified UART output from RISC-V firmware
    

### 3\. Toolchain

*   Compiled `main.c` using `riscv32-unknown-elf-gcc`
    
*   Converted to `firmware.hex` for BRAM
    
*   Synthesized on Lattice FPGA (within 30 BRAMs)
    

* * *

## 🧠 SoC Block Diagram (Text)

SHAKTI CPU (AXI4 Master)  
├── BRAM (Instruction Memory)  
└── AXI4-Lite to UART → UART TX (8N1)



## 📁 Files

*   `mkeclass_axi4.v` – Top wrapper
    
*   `mkeclass.v` – CPU core
    
*   `axi4_uart_bridge.v` – UART mapped bridge
    
*   `uart_tx.v` – UART TX logic
    
*   `bram_1rw.v` – Instruction memory
    
*   `main.c` – RISC-V C code
    
*   `firmware.hex` – Output for BRAM
    
*   `Makefile` – Builds hex from C
    

* * *

## 🙌 Thanks To

*   SHAKTI team
    
*   VSD & Lattice Semiconductor for guidance
