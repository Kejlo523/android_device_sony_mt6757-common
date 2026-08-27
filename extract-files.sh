#!/bin/bash
#
# Copyright (C) 2020 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=mt6757-common
VENDOR=sony

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

LINEAGE_ROOT="$MY_DIR"/../../..

HELPER="$LINEAGE_ROOT"/vendor/lineage/build/tools/extract_utils.sh
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
. "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

while [ "$1" != "" ]; do
    case $1 in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -s | --section )        shift
                                SECTION=$1
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC=$1
                                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$LINEAGE_ROOT" false "$CLEAN_VENDOR"

extract "$MY_DIR"/proprietary-files.txt "$SRC" "$SECTION"

# Android 10 no longer supports Beam/P2P, and the Oreo discovery mask includes
# legacy technologies that make the PN553 HAL wait forever on hinoki.
NFC_CONFIG="$LINEAGE_ROOT"/vendor/$VENDOR/$DEVICE/proprietary/vendor/etc/libnfc-brcm.conf
sed -i \
    -e 's/^POLLING_TECH_MASK=.*/POLLING_TECH_MASK=0x01/' \
    -e 's/^P2P_LISTEN_TECH_MASK=.*/P2P_LISTEN_TECH_MASK=0x00/' \
    "$NFC_CONFIG"

# The Oreo MTK HWC aborts instead of cleaning up stale acquire/release/retire
# fences under Android 10. This is reproducible with virtual displays.
python3 "$MY_DIR"/patches/patch-hwc-retire-fence.py \
    "$LINEAGE_ROOT"/vendor/$VENDOR/$DEVICE/proprietary/vendor/lib64/hw/hwcomposer.mt6757.so

# Do not advertise Oreo video decoder blobs whose Vcodec userspace ABI is
# incompatible with Android 10. Google's software codecs provide the formats
# used by current applications without crashing the OMX service.
OMX_CONFIG="$LINEAGE_ROOT"/vendor/$VENDOR/$DEVICE/proprietary/vendor/etc/mtk_omx_core.cfg
sed -i '/^OMX\.MTK\.VIDEO\.DECODER\./d' "$OMX_CONFIG"

"$MY_DIR"/setup-makefiles.sh
