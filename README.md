# 🔧 Minimal RISC-V SoC using SHAKTI E-Class Core on Lattice FPGA

This project implements a **minimal System-on-Chip (SoC)** based on the **SHAKTI E-Class** RISC-V processor core. The goal is to build a lightweight, functional RISC-V SoC suitable for small, resource-constrained FPGAs like the Lattice iCE40UP5K.

The SoC architecture is derived and adapted from the original [vsdip/shakti_vsdfpga](https://github.com/vsdip/shakti_vsdfpga) repository, with a specific focus on **minimization**, **functional clarity**, and **educational utility**.

---

## 🧠 Project Objective

The objective of this project is to:

- Implement a working 32-bit RISC-V RV32I processor using the SHAKTI E-Class core.
- Integrate basic memory and UART I/O within a simplified SoC fabric.
- Demonstrate UART output from compiled firmware running on the SHAKTI core.
- Fit the entire SoC within the limitations of a low-cost Lattice FPGA.
- Serve as a learning platform for students and beginners in RISC-V, FPGA, and SoC development.

---

## 🧩 SoC Architecture

The SoC consists of the following primary components:

### 1. **SHAKTI E-Class CPU Core**
- A 5-stage in-order pipelined processor implementing the **RV32I** instruction set.
- Sourced from the SHAKTI processor family, which is an open-source initiative by IIT-Madras.
- Communicates with peripherals via an **AXI4-Lite** interconnect interface.

### 2. **Instruction Memory (BRAM)**
- A block RAM preloaded with a compiled binary firmware (`firmware.bin`).
- Serves as read-only instruction memory for the CPU.
- No external memory interface is used for simplicity.

### 3. **UART Peripheral**
- A basic memory-mapped UART transmitter.
- Mapped to address `0x90000000` within the CPU’s address space.
- Used to print characters serially from the executing firmware.

### 4. **AXI4-Lite Interconnect**
- A simplified interconnect bus that links the CPU with memory and peripherals.
- Enables memory-mapped access to UART and instruction memory.

---

## 📦 Repository Contents

