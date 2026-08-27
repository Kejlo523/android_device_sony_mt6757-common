#!/usr/bin/env python3
"""Pin legacy MTK RIL callbacks to the working command proxy.

The Oreo librilmtk implementation tries to infer the command proxy from the
calling thread.  With Android 10's HIDL bridge that lookup is unreliable and
can route SIM/call requests to the wrong channel.  The working G3112 runtime
uses proxy 2, which is also where the modem exposes the call-control channel.
"""

import pathlib
import struct
import sys


EXPECTED_BUILD_ID = bytes.fromhex("32b3f9837660442c82cdac2a5e8ec3ba")
QUERY_PROXY_ID_VA = 0x0001B318
ORIGINAL = bytes.fromhex("f50f1df8f44f01a9")
PATCHED = bytes.fromhex(
    "40008052"  # mov w0, #2
    "c0035fd6"  # ret
)


def virtual_to_file_offset(data: bytes, address: int) -> int:
    if data[:4] != b"\x7fELF" or data[4] != 2 or data[5] != 1:
        raise SystemExit("expected a 64-bit little-endian ELF")
    program_offset = struct.unpack_from("<Q", data, 0x20)[0]
    program_entry_size = struct.unpack_from("<H", data, 0x36)[0]
    program_count = struct.unpack_from("<H", data, 0x38)[0]
    for index in range(program_count):
        offset = program_offset + index * program_entry_size
        kind, flags, file_offset, virtual_address, _, file_size, _, _ = (
            struct.unpack_from("<IIQQQQQQ", data, offset)
        )
        if kind == 1 and virtual_address <= address < virtual_address + file_size:
            return file_offset + address - virtual_address
    raise SystemExit(f"virtual address 0x{address:x} is outside file-backed LOAD segments")


source = pathlib.Path(sys.argv[1])
target = pathlib.Path(sys.argv[2])
blob = bytearray(source.read_bytes())

if EXPECTED_BUILD_ID not in blob:
    raise SystemExit("unexpected librilmtk.so build ID")

patch_offset = virtual_to_file_offset(blob, QUERY_PROXY_ID_VA)
current = bytes(blob[patch_offset:patch_offset + len(PATCHED)])
if current == PATCHED:
    print(f"RIL proxy channel already patched at file offset 0x{patch_offset:x}")
elif current == ORIGINAL:
    blob[patch_offset:patch_offset + len(PATCHED)] = PATCHED
    print(f"RIL proxy channel pinned to 2 at file offset 0x{patch_offset:x}")
else:
    raise SystemExit(f"unexpected RIL_queryMyProxyIdByThread prologue: {current.hex()}")

target.write_bytes(blob)
