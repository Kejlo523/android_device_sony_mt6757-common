#!/system/bin/sh

# Connect immediately so Android can request radio power before the Oreo RIL
# leaves its command channels dormant in CFUN=4.
setprop ctl.start ril-proxy
