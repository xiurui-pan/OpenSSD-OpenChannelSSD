#!/usr/bin/env bash
set -euo pipefail

DOORBELL_FIFO=${1:-doorbell.fifo}
DRAM_IMAGE=${2:-dram.img}

if [[ ! -p "$DOORBELL_FIFO" ]]; then
  rm -f "$DOORBELL_FIFO"
  mkfifo "$DOORBELL_FIFO"
fi

if [[ ! -f "$DRAM_IMAGE" ]]; then
  dd if=/dev/zero of="$DRAM_IMAGE" bs=1M count=2 status=none
fi

echo "Doorbell FIFO: $DOORBELL_FIFO"
echo "DRAM image   : $DRAM_IMAGE"
echo "Run ./wop_gpu_daemon $DOORBELL_FIFO $DRAM_IMAGE in another terminal."

echo "Press Enter to send sample descriptor..."
read -r

python3 - "$DRAM_IMAGE" <<'PY'
import sys, struct

path = sys.argv[1]
# Populate descriptor at WOP_DESC_RING_BASE_ADDR (0x00300000 -> offset 0x300000)
offset = 0x300000
cmd_id = 0x1234
mode = 2
flags = 1
base = 0x00100000

# TLWE words
words = 16

desc = struct.pack('<HBBQQQHBx', cmd_id, mode, flags,
                   base, base + 0x1000, base + 0x2000,
                   words, words)
with open(path, 'r+b') as f:
    f.seek(offset)
    f.write(desc)

# populate TLWE data
data = bytes(range(64))
with open(path, 'r+b') as f:
    f.seek(base)
    f.write(data)
PY

echo "Descriptor and TLWE data written. Sending doorbell token..."
python3 - "$DOORBELL_FIFO" <<'PY'
import sys, struct
fifo = sys.argv[1]
token = struct.pack('<HB', 0x1234, 2) + b'\x00'
with open(fifo, 'wb', buffering=0) as f:
    f.write(token)
PY

echo "Token sent. Check daemon output."
