#!/bin/sh
# rosette-binfmt.sh - Register x86-64 Linux ELF handler via binfmt_misc.
#
# After registration, the kernel automatically routes x86-64 ELF binaries
# through Rosette's elf_processor, making ./binary work transparently.
#
# Usage:
#   sudo ./rosette-binfmt.sh [/path/to/elf_processor]
#
# The default elf_processor path is `elf_processor` (resolved via PATH).
# Pass an explicit path if elf_processor is not on PATH.

set -e

if [ "$(uname -s)" != "Linux" ]; then
    echo "This script is for Linux only."
    exit 1
fi

ELF_PROC="${1:-elf_processor}"

if ! command -v "$ELF_PROC" >/dev/null 2>&1 && [ ! -x "$ELF_PROC" ]; then
    echo "error: elf_processor not found at: $ELF_PROC"
    echo "Install Rosette or pass the correct path."
    exit 1
fi

if [ ! -f /proc/sys/fs/binfmt_misc/register ]; then
    echo "error: binfmt_misc not available."
    echo "Enable CONFIG_BINFMT_MISC in your kernel or use:"
    echo "  mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc"
    exit 1
fi

# Resolve to absolute path if possible
ELF_PROC_ABS="$(command -v "$ELF_PROC" 2>/dev/null || readlink -f "$ELF_PROC" 2>/dev/null || echo "$ELF_PROC")"

# ELF64 header bytes we match:
#   00-03: 7f 45 4c 46  (magic)
#   04:    02           (ELFCLASS64)
#   05:    01           (ELFDATA2LSB)
#   06:    01           (EV_CURRENT)
#   07:    --           (OSABI, wildcard)
#   08-0f: --           (padding, wildcard)
#   10-11: 02 00 or 03 00 (ET_EXEC or ET_DYN, LE)
#   12-13: 3e 00        (EM_X86_64, LE)
#
# The mask: 0xff for required bytes, 0x00 for wildcard bytes.
# For e_type byte 0: 0xfe mask ignores bit 0 (difference between
# ET_EXEC=2 and ET_DYN=3).

printf ':Rosette-ELF-x86_64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x3e\x00:\xff\xff\xff\xff\xff\xff\xff\x00\x00\x00\x00\x00\x00\x00\x00\x00\xfe\xff\xff\xff:%s:OC\n' \
    "$ELF_PROC_ABS" > /proc/sys/fs/binfmt_misc/register

echo "Registered x86-64 ELF handler: $ELF_PROC_ABS"
