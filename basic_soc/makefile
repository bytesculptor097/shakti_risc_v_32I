# === Top‑level settings ===
TOP         = mkeclass_axi4
DEVICE      = up5k
PACKAGE     = sg48
FREQ        = 12
PCF         = $(TOP).pcf

# === RISC-V Toolchain Settings ===
CC          = riscv32-unknown-elf-gcc
OBJCOPY     = riscv32-unknown-elf-objcopy
CFLAGS      = -nostdlib -march=rv32i -mabi=ilp32 -T linker.ld

FIRMWARE_ELF = firmware.elf
FIRMWARE_HEX = firmware.hex

# === Build RISC-V Firmware Only ===
risc:
	$(MAKE) $(FIRMWARE_HEX)

$(FIRMWARE_ELF): main.c linker.ld
	$(CC) $(CFLAGS) -o $@ main.c

$(FIRMWARE_HEX): $(FIRMWARE_ELF)
	$(OBJCOPY) -O ihex $< $@

# === RTL Sources ===
SRCS = \
	mkeclass_axi4.v \
	axi4_uart_bridge.v \
	uart_tx_minimal.v \
	bram.v \
	mkeclass.v \
	mkriscv.v \
	mkstage1.v \
	mkstage2.v \
	mkstage3.v \
	mkalu.v \
	mkcsrfile.v \
	mkcsr.v \
	RegFile.v \
	SyncResetA.v \
	SyncReset0.v \
	SyncRegister.v \
	SyncFIFO.v \
	SyncHandshake.v \
	FIFO2.v \
	FIFO1.v \
	FIFO10.v \
	FIFO20.v \
	FIFOL1.v \
	MakeClock.v \
	ClockInverter.v \
	module_decoder_func_32.v \
	module_fn_alu.v \
	uart_tx_8n1.v \
	module_address_valid.v \
	module_chk_interrupt.v \
	module_decode_word32.v

# === Build Targets ===
all: $(TOP).bin

# Ensure firmware.hex is built before synthesis
$(TOP).json: $(SRCS) $(PCF) $(FIRMWARE_HEX)
	@echo "Running Yosys synthesis..."
	yosys -p " \
		read_verilog -lib +/ice40/cells_sim.v; \
		read_verilog -sv $(SRCS); \
		hierarchy -top $(TOP); \
		synth_ice40 -top $(TOP) -json $@ \
	" 2>&1 | tee yosys.log

$(TOP).asc: $(TOP).json
	@echo "Running place and route with nextpnr..."
	nextpnr-ice40 --$(DEVICE) --package $(PACKAGE) \
		--json $< --pcf $(PCF) --asc $@ --freq $(FREQ)

$(TOP).bin: $(TOP).asc
	@echo "Packing bitstream with icepack..."
	icepack $< $@

# === Flash to FPGA ===
flash: $(TOP).bin
	@echo "Flashing bitstream to FPGA..."
	iceprog $(TOP).bin

# === UART Terminal (9600 baud) ===
terminal:
	sudo picocom -b 9600 /dev/ttyUSB0 --imap lfcrlf,crcrlf --omap delbs,crlf

# === Clean Build Files ===
clean:
	rm -f mkeclass_axi4.json mkeclass_axi4.asc mkeclass_axi4.bin yosys.log \
	      firmware.elf firmware.hex

.PHONY: all risc flash terminal clean
