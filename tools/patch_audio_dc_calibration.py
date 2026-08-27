#!/usr/bin/env python3
"""Apply Android 10 compatibility fixes to the legacy 32-bit MT6757 audio HAL."""

import pathlib
import struct
import sys

EXPECTED_BUILD_ID = bytes.fromhex("50dc2458d20fc8be7dca2553a0b4ebc0")

# ARM virtual addresses from the symbol table in this exact proprietary blob.
INIT_DC_REMOVAL_VA = 0x000C3AC0
DO_DC_REMOVAL_VA = 0x000C3C74
BGS_NULL_DEREF_VA = 0x00095E58

# int initDcRemoval() { return 0; }
INIT_PATCH = bytes.fromhex(
    "0000a0e3"  # mov r0, #0
    "1eff2fe1"  # bx lr
)

# int doDcRemoval(in, bytes, &out, &outBytes) {
#     *out = in; *outBytes = bytes; return 0;
# }
PASSTHROUGH_PATCH = bytes.fromhex(
    "001083e5"  # str r1, [r3]
    "00009de5"  # ldr r0, [sp]
    "002080e5"  # str r2, [r0]
    "0000a0e3"  # mov r0, #0
    "1eff2fe1"  # bx lr
)

# BGSPlayBuffer asks an old framework factory for an audio source.  Android 10
# can return nullptr here, but the Oreo blob dereferences it before its existing
# nullptr error path.  Move the check in front of the virtual call while keeping
# the original call intact for the non-null case.  The final branch skips only a
# debug log and rejoins the blob's original nullptr check at 0x95e84.
BGS_NULL_GUARD_PATCH = bytes.fromhex(
    "000050e3"  # cmp r0, #0
    "0b00000a"  # beq 0x95e90
    "001090e5"  # ldr r1, [r0]
    "081091e5"  # ldr r1, [r1, #8]
    "31ff2fe1"  # blx r1
    "040000ea"  # b 0x95e84
)


def virtual_to_file_offset(data: bytes, address: int) -> int:
    if data[:4] != b"\x7fELF" or data[4] != 1 or data[5] != 1:
        raise SystemExit("expected a 32-bit little-endian ELF")
    program_offset = struct.unpack_from("<I", data, 0x1C)[0]
    program_entry_size = struct.unpack_from("<H", data, 0x2A)[0]
    program_count = struct.unpack_from("<H", data, 0x2C)[0]
    for index in range(program_count):
        offset = program_offset + index * program_entry_size
        kind, file_offset, virtual_address, _, file_size, _, _, _ = (
            struct.unpack_from("<IIIIIIII", data, offset)
        )
        if kind == 1 and virtual_address <= address < virtual_address + file_size:
            return file_offset + address - virtual_address
    raise SystemExit(f"virtual address 0x{address:x} is outside file-backed LOAD segments")


source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
blob = bytearray(source.read_bytes())

if EXPECTED_BUILD_ID not in blob:
    raise SystemExit("unexpected audio.primary.mt6757.so build ID")

init_offset = virtual_to_file_offset(blob, INIT_DC_REMOVAL_VA)
passthrough_offset = virtual_to_file_offset(blob, DO_DC_REMOVAL_VA)
bgs_null_deref_offset = virtual_to_file_offset(blob, BGS_NULL_DEREF_VA)

if blob[init_offset:init_offset + 4] != bytes.fromhex("f0482de9"):
    raise SystemExit("unexpected initDcRemoval prologue")
if blob[passthrough_offset:passthrough_offset + 4] != bytes.fromhex("f0482de9"):
    raise SystemExit("unexpected doDcRemoval prologue")
if blob[bgs_null_deref_offset:bgs_null_deref_offset + 12] != bytes.fromhex(
        "001090e5081091e531ff2fe1"):
    raise SystemExit("unexpected BGSPlayBuffer nullptr dereference")

blob[init_offset:init_offset + len(INIT_PATCH)] = INIT_PATCH
blob[passthrough_offset:passthrough_offset + len(PASSTHROUGH_PATCH)] = PASSTHROUGH_PATCH
blob[bgs_null_deref_offset:bgs_null_deref_offset + len(BGS_NULL_GUARD_PATCH)] = (
    BGS_NULL_GUARD_PATCH
)
target.write_bytes(blob)

print(f"initDcRemoval: VA 0x{INIT_DC_REMOVAL_VA:x} -> file 0x{init_offset:x}")
print(f"doDcRemoval: VA 0x{DO_DC_REMOVAL_VA:x} -> file 0x{passthrough_offset:x}")
print(f"BGS nullptr guard: VA 0x{BGS_NULL_DEREF_VA:x} -> file 0x{bgs_null_deref_offset:x}")
