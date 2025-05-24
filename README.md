# 🔧 Minimal RISC-V SoC using SHAKTI E-Class Core on Lattice FPGA

This project implements a **minimal System-on-Chip (SoC)** based on the **SHAKTI E-Class** RISC-V processor core. The goal is to build a lightweight, functional RISC-V SoC suitable for small, resource-constrained FPGAs like the Lattice iCE40UP5K.The Shakti RISC‑V 32I Core on VSD FPGA project brings together two vibrant open‑source ecosystems—India’s SHAKTI processor family and the VSDOpen FPGA community—to create a low‑cost, hands‑on RISC‑V SoC platform. At its heart lies the SHAKTI E‑Class RV32I core, a clean‑slate, five‑stage in‑order pipelined CPU design implementing the full RV32I integer instruction set. By targeting the affordable VSDSquadron FPGA mini board (Lattice iCE40 / Tang Nano 9K), this repository enables students and hobbyists to:  
1. **Study** a real-world RISC‑V microarchitecture end‑to‑end.  
2. **Experiment** with instruction memory, AXI4‑Lite interconnects, and a simple UART peripheral.  
3. **Deploy** compiled firmware on actual hardware, observing live UART output.  
4. **Extend** the design—adding peripherals, modifying the pipeline, or porting to other FPGA families—all using open‑source tools like Yosys, NextPNR, and Quartus.


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

This project implements a fully functional, synthesizable RISC‑V system-on-chip (SoC) around SHAKTI’s E‑Class CPU core. The design is organized into clear, reusable modules:

- **CPU Core (`eclass`)**: A parameterized, five‑stage pipeline (IF → ID → EX → MEM → WB) with separate instruction and data buses.  
- **Instruction Memory (`BRAM`)**: On‑chip block RAM preloaded with `firmware.bin`. The fetch unit reads instructions synchronously, eliminating external memory dependencies.  
- **AXI4‑Lite Interconnect (`fabric`)**: A lightweight crossbar that arbitrates access between the CPU’s instruction fetch, data load/store, and memory‑mapped peripherals.  
- **UART Peripheral (`uart_user_ifc`)**: A simple, register‑based UART transmitter/receiver mapped at address `0x9000_0000`, supporting basic TX buffering via FIFOs.  
- **Clock/Reset Generation**: A centralized module that derives the global clock and synchronous reset (active‑low) signals for all subunits.  
- **Boot Loader & Interfaces**: A minimal boot module that initializes the program counter and offers JTAG/UART download paths for firmware.  
- **Debug & Simulation Hooks**: Dump interfaces (`io_dump_get`) and simulation monitors (`mv_end_simulation`) to facilitate post‑simulation state inspection and automated testbench control.

By modularizing each function—pipeline stages, ALU, CSR, register file, memory interfaces, FIFOs—this repository becomes an ideal learning sandbox. Newcomers can trace a single instruction’s journey through fetch, decode, execute, memory, and write‑back stages, while advanced users can experiment with custom peripherals or performance optimizations. 

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

1. **Power‑On & Reset**  
   - Upon power‑up, the **Clock/Reset Generator** asserts a synchronous, active‑low reset (`RST_N`) for a few clock cycles, ensuring all registers and FIFOs initialize to known states.  
   - The **Boot Loader** then deasserts reset and programs the CPU’s Program Counter (PC) with the start address of the instruction BRAM.

2. **Instruction Fetch (IF)**  
   - The CPU core drives the AXI4‑Lite instruction bus: `awvalid`/`arvalid` signals, `awaddr`/`araddr` pointers, and `rready` handshakes.  
   - The BRAM module returns 32‑bit instructions synchronously on each clock, feeding them into the IF stage FIFO.

3. **Instruction Decode (ID)**  
   - The fetched instruction is unpacked: opcode, register addresses, immediate fields.  
   - Two register‑read ports access the **Register File**, providing operand data for the execution stage.  
   - Control signals (branch, ALU opcode, CSR flags) are generated.

4. **Execute (EX)**  
   - The **ALU** performs arithmetic/logic operations (ADD, SUB, AND, OR, SHIFT, etc.), while the **CSR Unit** handles system and control‑status register instructions.  
   - Branch decisions are evaluated; if a branch is taken, the PC is updated accordingly via the interconnect.

5. **Memory Access (MEM)**  
   - For loads/stores, the data bus issues AXI4‑Lite read (`ar*`) or write (`aw*`, `w*`) transactions to the BRAM or peripherals.  
   - **Data FIFOs** ensure clock‑domain crossing safety and decouple back‑to‑back transactions.

6. **Write‑Back (WB)**  
   - Results from the ALU or loaded data are written back into the **Register File** on the rising edge of `CLK`.  
   - The core then fetches the next instruction, restarting the pipeline.

7. **UART I/O & Debug**  
   - Firmware writes ASCII values to the UART’s TX register; the **UART Peripheral** serializes and emits bits at the configured baud rate.  
   - Optional dump interface (`EN_io_dump_get` / `io_dump_get`) can snapshot internal state (registers, FIFOs) for offline analysis.  
   - A simulation monitor (`mv_end_simulation`) flags testbench completion, enabling fully automated CI integration.


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
- Lattice Semiconductor for guidance

---

## 📜 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.



