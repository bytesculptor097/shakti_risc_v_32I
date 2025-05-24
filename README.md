# 🔧 Minimal RISC-V SoC using SHAKTI E-Class Core on Lattice FPGA

This project implements a **minimal System-on-Chip (SoC)** based on the **SHAKTI E-Class** RISC-V processor core. The goal is to build a lightweight, functional RISC-V SoC suitable for small, resource-constrained FPGAs like the Lattice iCE40UP5K.



---



## 🧠 Project Objective

The objective of this project is to:

- Implement a working 32‑bit RISC‑V RV32I processor using the SHAKTI E‑Class core.  
- Integrate basic memory and UART I/O within a simplified SoC fabric.  
- Demonstrate UART output from compiled firmware running on the SHAKTI core.  
- Fit the entire SoC within the limitations of a low‑cost Lattice FPGA.  
- Serve as a learning platform for students and beginners in RISC‑V, FPGA, and SoC development.

---

## 🧩 SoC Architecture

The SoC consists of the following primary components:

1. **SHAKTI E‑Class CPU Core**  
   - A 5‑stage in‑order pipelined processor implementing the RV32I instruction set.  
   - Sourced from the SHAKTI processor family (IIT‑Madras).  
   - Communicates with peripherals via an AXI4‑Lite interconnect.

2. **Instruction Memory (BRAM)**  
   - A block RAM preloaded with a compiled firmware binary (`firmware.bin`).  
   - Serves as read‑only instruction memory for the CPU.

3. **UART Peripheral**  
   - A memory‑mapped UART transmitter.  
   - Mapped to address `0x9000_0000` in the CPU’s address space.  
   - Outputs characters serially from executing firmware.

4. **AXI4‑Lite Interconnect**  
   - A lightweight bus linking CPU, BRAM, and UART.  
   - Provides memory‑mapped access for instruction fetch and data I/O.

---

## 🧩 System Components

The top‑level `mkSoc` module integrates:

1. **Clock/Reset Generation**  
   - Generates global clock (`clk_i`) and synchronized active‑low reset (`rst_n_i`) for all sub‑modules.

2. **Boot Loader & Interfaces**  
   - Initializes the program counter and memory map on power‑up.  
   - Provides UART and JTAG interfaces for firmware download and debugging.

3. **Shakti RISC‑V 32I Core**  
   - 5‑stage pipeline (IF, ID, EX, MEM, WB).  
   - Interfaces to instruction/data memory via AXI4‑Lite.

4. **Pipeline Stages**  
   - **IF**: Instruction Fetch from BRAM.  
   - **ID**: Decode & register fetch.  
   - **EX**: Execute via ALU/CSR.  
   - **MEM**: Data memory access.  
   - **WB**: Writeback to Register File.

5. **ALU & Control/CSR Unit**  
   - Arithmetic, logic, shift operations and CSR handling.

6. **Register File**  
   - 32 × 32‑bit registers with two read ports and one write port.

7. **BRAM Modules**  
   - Dual‑port block RAM for instructions and data.

8. **FIFO & Sync Modules**  
   - Handles clock‑domain crossing and buffering.

---

## 🎨 Design Style Explanation

- **Modular & Hierarchical**  
  - Each block (ALU, CSR, Pipeline, BRAM, FIFO) in its own RTL file under `rtl/`.  
  - Top‑level wrapper `mkSoc.v` wires sub‑modules.

- **Synchronous Reset**  
  - Active‑low `rst_n_i`, synchronized to `clk_i`.

- **Parameterization**  
  - Widths, depths, and addresses parameterized for reuse.

- **Signal Naming**  
  - Inputs: `<name>_i`  
  - Outputs: `<name>_o`  
  - Internals: lowercase with underscores.

- **Clock‑Domain Crossing**  
  - FIFOs use Gray‑coded pointers for safe pointer synchronization.

- **Comments & Documentation**  
  - Module headers list ports, parameters, and descriptions.  
  - Inline comments on non‑obvious logic.

---

## 🔌 I/O Signals of `mkSoc`

| Signal Name       | Dir | Width | Description                                      |
|-------------------|:---:|:-----:|--------------------------------------------------|
| `clk_i`           | in  | 1     | Global system clock                              |
| `rst_n_i`         | in  | 1     | Active‑low synchronous reset                     |
| `boot_addr_i`     | in  | 32    | Boot start address loaded at power‑up            |
| `instr_addr_o`    | out | 32    | Address bus for instruction BRAM                 |
| `instr_data_i`    | in  | 32    | Data bus from instruction BRAM                   |
| `data_addr_o`     | out | 32    | Address bus for data BRAM                        |
| `data_wdata_o`    | out | 32    | Write‑data bus to data BRAM                      |
| `data_rdata_i`    | in  | 32    | Read‑data bus from data BRAM                     |
| `data_we_o`       | out | 4     | Byte‑enable signals for data writes              |
| `uart_tx_o`       | out | 1     | UART transmit line                               |
| `uart_rx_i`       | in  | 1     | UART receive line                                |
| `gpio_leds_o`     | out | 8     | On‑board LEDs (user‑configurable patterns)       |
| `gpio_switches_i` | in  | 8     | On‑board switch inputs                           |

---

## 🚀 Project Overview

This project implements the Shakti 32I soft core on the VSD FPGA board, enabling real‑time interaction with a full RISC‑V CPU. The integer‑only variant is lightweight and ideal for teaching and embedded applications.

**Modules:**  
- CPU Core  
- Pipeline Stages (IF → ID → EX → MEM → WB)  
- ALU & CSR Unit  
- Register File  
- BRAM Modules  
- FIFO & Sync Units  
- Clock/Reset Generator  
- Boot Loader & Interfaces  

---

## 🔍 System Block Diagram

![WhatsApp Image 2025-05-24 at 18 17 38_825da6d7](https://github.com/user-attachments/assets/0027b169-4ba1-4df1-b2c5-42eab3f37c16)


---

## ⚙️ Working Principle

1. **Initialization**  
   - `Clock/Reset Generator` drives `clk_i`/`rst_n_i`.  
   - `Boot Loader` sets the PC to start of instruction BRAM.

2. **Fetch & Execute**  
   - CPU fetches from BRAM, decodes, executes via ALU/CSR.  
   - Data loads/stores via AXI4‑Lite.

3. **UART Output**  
   - Firmware writes to UART TX register at `0x9000_0000`.  
   - UART serializes and transmits to host PC.

4. **Synchronous Operation**  
   - Single clock domain for all modules.

---

## ⭐ Key Features

- ✅ Lightweight SHAKTI RV32I 5‑stage pipelined core  
- ✅ Memory‑mapped UART for serial I/O  
- ✅ On‑chip BRAM for firmware storage  
- ✅ AXI4‑Lite interconnect  
- ✅ Modular Verilog RTL  
- ✅ Fits low‑cost Lattice FPGA  

---

## 🎯 Target Platform

- **FPGA Board:** VSDSquadron FPGA mini (Lattice iCE40 / Tang Nano 9K)  
- **Toolchain:** Yosys + NextPNR (iCE40)   
- **Language:** Verilog 2001  

---

## 🙏 Acknowledgments

- Core sourced from the [SHAKTI Processor Program](https://shakti.org.in/) by IIT‑Madras.   
- Thanks to the VSDOpen community for FPGA tooling guidance.

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.



