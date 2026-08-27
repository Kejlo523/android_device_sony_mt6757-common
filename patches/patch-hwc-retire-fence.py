#!/usr/bin/env python3
"""Disable fatal stale-fence checks in Sony's Oreo MTK HWC blob."""

import hashlib
import pathlib
import sys


ORIGINAL_SHA256 = "257ca2f9ec1e952bae2c6caa72efe4d8fff526d70aba80d703d6bb58adcafbd4"
NOP = bytes.fromhex("1f 20 03 d5")

# File offsets of the `cbnz fatal, abort_path` checks. Each function has an
# adjacent non-fatal path which logs the stale descriptor and closes it before
# installing the new fence. Android 10 legitimately reaches these paths while
# virtual displays (screen recording) are active; Oreo treated that as fatal.
PATCHES = (
    (0x23D60, bytes.fromhex("29 08 00 35"), "release fence"),
    (0x23F00, bytes.fromhex("29 08 00 35"), "previous release fence"),
    (0x240A0, bytes.fromhex("29 08 00 35"), "acquire fence"),
    (0x24234, bytes.fromhex("68 06 00 35"), "buffer after-present fence"),
    (0x252A0, bytes.fromhex("c8 0f 00 35"), "layer after-present fence"),
    (0x26D54, bytes.fromhex("08 05 00 35"), "retire fence"),
)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <hwcomposer.mt6757.so>", file=sys.stderr)
        return 2

    path = pathlib.Path(sys.argv[1])
    blob = bytearray(path.read_bytes())
    normalized = bytearray(blob)
    for offset, original, description in PATCHES:
        current = bytes(blob[offset:offset + len(original)])
        if current not in (original, NOP):
            print(
                f"{path}: unsupported {description} instruction "
                f"at 0x{offset:x} ({current.hex()})",
                file=sys.stderr,
            )
            return 1
        normalized[offset:offset + len(original)] = original

    # Normalizing already-patched instructions back to their stock values lets
    # this check remain strict while keeping the patcher idempotent.
    normalized_digest = hashlib.sha256(normalized).hexdigest()
    if normalized_digest != ORIGINAL_SHA256:
        print(
            f"{path}: unsupported HWC blob (normalized sha256={normalized_digest})",
            file=sys.stderr,
        )
        return 1

    changed = 0
    for offset, original, _ in PATCHES:
        if bytes(blob[offset:offset + len(original)]) != NOP:
            blob[offset:offset + len(original)] = NOP
            changed += 1

    if not changed:
        print(f"{path}: stale-fence workarounds already applied")
        return 0

    path.write_bytes(blob)
    print(f"{path}: applied {changed} stale-fence cleanup workaround(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
