# 🔧 Minimal RISC-V SoC using SHAKTI E-Class Core on Lattice FPGA

This project implements a **minimal System-on-Chip (SoC)** based on the **SHAKTI E-Class** RISC-V processor core. The goal is to build a lightweight, functional RISC-V SoC suitable for small, resource-constrained FPGAs like the Lattice iCE40UP5K.



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
shakti_risc_v_32I/
├── rtl/ # RTL design files (Verilog)
├── tb/ # Testbenches
├── docs/ # Documentation and block diagram
├── constraints/ # FPGA constraints (pin assignments, etc.)
├── scripts/ # Simulation/build scripts
├── README.md # Project overview and instructions
└── LICENSE # License information


## Project Overview

This project aims to implement the Shakti 32I RISC-V soft core on the VSD FPGA board, which allows learners and developers to interact with a full RISC-V CPU in real-time. The 32I variant supports integer instructions only and is designed to be light-weight, making it suitable for academic and embedded applications.

The system involves multiple modules working together:

- **CPU Core:** The central Shakti RISC-V 32I core.
- **Pipeline Stages:** Implement instruction fetch, decode, execute, memory, and writeback stages.
- **ALU and CSR Unit:** Handle arithmetic and control flow.
- **Register File:** Stores temporary data and registers.
- **BRAM Modules:** Act as internal memory for program and data.
- **FIFO & Sync Modules:** Help in communication and synchronization across modules.
- **Clock/Reset Generator:** Drives and synchronizes the design.
- **Boot Loader & Interfaces:** Initialize the CPU at power-on.

---

## System Block Diagram

The following block diagram explains the architecture of the system implemented:

![WhatsApp Image 2025-05-24 at 18 17 38_4615df3a](https://github.com/user-attachments/assets/09ad6826-0f43-4f4e-b1a6-d7f48e1d34ef)

---

## Working Principle

The CPU core is initialized by the Boot Loader and Clock/Reset Generator. Once started, it begins fetching instructions from the BRAM, processing them through its pipeline. The ALU performs arithmetic operations while the Control Unit manages flow and CSR operations. Data transfer between memory and core is handled via BRAM modules and interfaces, synchronized properly using FIFO buffers.

All components are driven by a global clock and reset system, ensuring synchronous and deterministic behavior suitable for FPGA-based prototyping.

---

## Key Features

- ✅ Lightweight RISC-V 32I core
- ✅ Pipeline architecture
- ✅ Custom memory subsystem
- ✅ FIFO and synchronization logic
- ✅ Modular Verilog-based RTL structure
- ✅ Synthesizable on VSD FPGA board

---

## Target Platform

- FPGA Board: **VSD Squadon (Tang Nano 9K / iCE40 / Cyclone II)**
- Toolchain: **Yosys, NextPNR, Quartus (for Cyclone)**

---

## Acknowledgments

- This work is inspired and derived from [Shakti Processor Program](https://shakti.org.in/)
- Special thanks to VSDOpen for FPGA tools and community guidance.


---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.


