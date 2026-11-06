#!/bin/sh
# Lists the sysfs paths SysInfo reads, because QML can't glob:
#   hwmon <dir> <name>   every hardware monitor (SysInfo picks the CPU sensor by name)
#   gpu <dir>            every PCI device bound to the nvidia driver
for h in /sys/class/hwmon/hwmon*; do
    [ -r "$h/name" ] && echo "hwmon $h $(cat "$h/name")"
done
for g in /sys/bus/pci/drivers/nvidia/0000:*; do
    [ -e "$g" ] && echo "gpu $(readlink -f "$g")"
done
exit 0
