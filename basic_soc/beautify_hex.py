# beautify_hex.py
with open("firmware.hex", "r") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    addr = i * 4  # Since each line is a 32-bit (4-byte) instruction
    print(f"{addr:08x}: {line.strip()}")
