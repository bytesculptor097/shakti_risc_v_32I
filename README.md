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

## 🧩 System Components

| Component Name                   | Type                             | Function                                                                                 |
|----------------------------------|----------------------------------|------------------------------------------------------------------------------------------|
| **eclass**                       | CPU Core                         | Executes RV32I instructions; interfaces with memory/peripherals via AXI4‑Lite.           |
| **clint (CLINT)**                | Timer/Interrupt Controller       | Manages machine‑mode timers (`mtime`, `mtimecmp`) and software interrupts (`MSIP`).     |
| **uart_user_ifc**                | UART (Serial Port)               | Handles serial TX/RX, with FIFOs for buffering.                                         |
| **fabric (Interconnect)**        | AXI4‑Lite Crossbar               | Routes read/write requests between CPU, memory, and peripherals.                         |
| **main_mem_master**              | Memory Interface                 | AXI4‑Lite master for main data RAM.                                                     |
| **boot_mem_master**              | Memory Interface                 | AXI4‑Lite master for boot ROM/flash.                                                     |
| **err_slave**                    | Error Handler                    | Catches invalid memory accesses (for debugging).                                        |
| **signature**                    | Simulation Monitor               | Ends simulation when tests complete (`mv_end_simulation`).                              |
| **clint_s_xactor**               | AXI4‑Lite Transaction Handler    | Manages AXI reads/writes for the CLINT.                                                 |
| **uart_s_xactor**                | AXI4‑Lite Transaction Handler    | Manages AXI reads/writes for the UART.                                                  |
| **fabric_xactors_from_masters**  | AXI4‑Lite Master Interfaces      | Buffers requests from CPU masters (instr, data, debug).                                 |
| **fabric_xactors_to_slaves**     | AXI4‑Lite Slave Interfaces       | Buffers requests to slaves (main mem, boot mem, CLINT, UART, err_slave, signature).     |
| **fabric_v_f_rd_mis / …_wr**     | Routing FIFOs                    | Track in‑flight AXI read/write transactions.                                             |
| **uart_baudGen**                 | Baud Rate Generator              | Generates baud clock for UART.                                                          |
| **uart_fifoRecv / fifoXmit**     | FIFO Buffers                     | Buffers incoming/outgoing UART data.                                                    |

---

## 🎨 Design Style Explanation

- **Modular & Hierarchical**  
  - Each block under `rtl/` (e.g., ALU, CSR, Pipeline, BRAM, FIFO).  
  - Top‑level `mkSoc.v` instantiates sub‑modules.

- **Synchronous Reset**  
  - Single active‑low reset (`rst_n_i`), synchronized to `clk_i`.

- **Parameterization**  
  - Data widths, address widths, FIFO depths are parameters.

- **Signal Naming**  
  - Inputs: `<name>_i`  
  - Outputs: `<name>_o`  
  - Internals: snake_case.

- **Clock‑Domain Crossing**  
  - Gray‑coded pointers in FIFOs for safe sync.

- **Documentation**  
  - Module headers list ports, parameters, brief description.  
  - Inline comments for complex logic.

---

## 🔌 I/O Signals of `mkSoc`

| Signal Name            | Direction | Width | Meaning                                          | Usage                                                        |
|------------------------|-----------|:-----:|--------------------------------------------------|--------------------------------------------------------------|
| **Clock/Reset Signals**                                                      |
| `CLK_tck_clk`          | in        | 1     | JTAG test clock (unused normally)                | Tie to 0 if unused.                                          |
| `RST_N_trst`           | in        | 1     | JTAG test reset (unused normally)                | Tie to 0 if unused.                                          |
| `CLK`                  | in        | 1     | Main system clock                                | Connect to clock source.                                     |
| `RST_N`                | in        | 1     | Active‑low system reset                          | Assert (low) to reset.                                       |
| **Dump Interface**                                                           |
| `EN_io_dump_get`       | in        | 1     | Enable signal to read system state               | Assert to trigger state dump (debug).                        |
| `io_dump_get`          | out       | 167   | System state data (registers, FIFOs, etc.)       | Capture when `EN_io_dump_get` is asserted.                   |
| `RDY_io_dump_get`      | out       | 1     | Indicates `io_dump_get` is ready                 | Check before asserting `EN_io_dump_get`.                      |
| **Main Memory AXI Master**                                                   |
| `main_mem_master_awvalid` | out    | 1     | AXI write address valid                          | Indicates valid write address.                               |
| `main_mem_master_awaddr`  | out    | 32    | AXI write address                                | Connect to RAM controller.                                   |
| `main_mem_master_awprot`  | out    | 3     | AXI write protection                             | Set security/privilege level.                                |
| `main_mem_master_awsize`  | out    | 3     | AXI write burst size                             | e.g. `2'b011` for 8‑byte bursts.                             |
| `main_mem_master_wvalid`  | out    | 1     | AXI write data valid                             | Indicates valid write data.                                  |
| `main_mem_master_wdata`   | out    | 64    | AXI write data                                   | Data to write.                                               |
| `main_mem_master_wstrb`   | out    | 8     | AXI write strobe                                 | Byte‑enable for `wdata`.                                     |
| `main_mem_master_bready`  | out    | 1     | AXI write response ready                         | Accept write responses.                                      |
| `main_mem_master_arvalid` | out    | 1     | AXI read address valid                           | Indicates valid read address.                                |
| `main_mem_master_araddr`  | out    | 32    | AXI read address                                 | Connect to RAM controller.                                   |
| `main_mem_master_arprot`  | out    | 3     | AXI read protection                              | Set security/privilege level.                                |
| `main_mem_master_arsize`  | out    | 3     | AXI read burst size                              | e.g. `2'b011` for 8‑byte bursts.                             |
| `main_mem_master_rready`  | out    | 1     | AXI read data ready                              | Accept read data.                                            |
| **Boot Memory AXI Master**                                                   |
| `boot_mem_master_*`     | out       | —     | AXI signals for boot memory (same as main_mem)   | Connect to ROM/flash controller.                             |
| **UART**                                                                     |
| `uart_io_SIN`          | in        | 1     | UART serial input                                | Connect to external RX.                                      |
| `uart_io_SOUT`         | out       | 1     | UART serial output                               | Connect to external TX.                                      |
| **Simulation Control**                                                       |
| `mv_end_simulation`    | out       | 1     | End‑of‑simulation signal                         | Assert when tests complete.                                  |
| `RDY_mv_end_simulation`| out       | 1     | Indicates `mv_end_simulation` is valid           | Check before reading.                                        |

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



