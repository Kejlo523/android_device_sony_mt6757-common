#!/usr/bin/env python3
"""Expose the stock MTK indication-base constructor to a shared-library client.

Android treats packages loaded by different class loaders as different runtime
packages.  The Oreo MTK jar leaves MtkRadioIndicationBase(RIL) package-private,
which prevents the Hinoki system bridge APK from subclassing it.  This script
changes only that constructor's DEX access flag by round-tripping the jar with
the AOSP smali tools.
"""

import argparse
import pathlib
import shutil
import subprocess
import tempfile
import zipfile


TARGET = pathlib.Path(
    "com/mediatek/internal/telephony/MtkRadioIndicationBase.smali"
)
OLD = ".method constructor <init>(Lcom/android/internal/telephony/RIL;)V"
NEW = ".method public constructor <init>(Lcom/android/internal/telephony/RIL;)V"


def run(*args: str) -> None:
    subprocess.run(args, check=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("jar", type=pathlib.Path)
    parser.add_argument("--java", required=True)
    parser.add_argument("--baksmali", required=True)
    parser.add_argument("--smali", required=True)
    args = parser.parse_args()

    jar = args.jar.resolve()
    with tempfile.TemporaryDirectory(prefix="hinoki-mtk-radio-") as temp_name:
        temp = pathlib.Path(temp_name)
        dex = temp / "classes.dex"
        smali_dir = temp / "smali"
        rebuilt_dex = temp / "classes-patched.dex"
        rebuilt_jar = temp / jar.name

        with zipfile.ZipFile(jar, "r") as source:
            dex.write_bytes(source.read("classes.dex"))

        run(args.java, "-jar", args.baksmali, "disassemble", str(dex),
            "-o", str(smali_dir))

        target = smali_dir / TARGET
        text = target.read_text()
        if NEW in text:
            print(f"{jar}: constructor is already public")
            return
        if text.count(OLD) != 1:
            raise RuntimeError("expected exactly one MTK indication constructor")
        target.write_text(text.replace(OLD, NEW))

        run(args.java, "-jar", args.smali, "assemble", str(smali_dir),
            "-o", str(rebuilt_dex))

        with zipfile.ZipFile(jar, "r") as source, zipfile.ZipFile(
                rebuilt_jar, "w") as output:
            for entry in source.infolist():
                data = rebuilt_dex.read_bytes() if entry.filename == "classes.dex" \
                    else source.read(entry.filename)
                output.writestr(entry, data)

        shutil.copymode(jar, rebuilt_jar)
        rebuilt_jar.replace(jar)
        print(f"Patched {jar}")


if __name__ == "__main__":
    main()
