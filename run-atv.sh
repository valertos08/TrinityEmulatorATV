#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QEMU="$SCRIPT_DIR/build/x86_64-softmmu/qemu-system-x86_64"

DISK=""
ISO=""
RAM="8192"
CPUS="2"
DISPLAY_BACKEND="gtk"
ACCEL="auto"
QMP_PORT="4444"

usage() {
    cat <<EOF
Trinity ATV launcher

Usage: $0 [options]

Options:
  -d, --disk PATH    Virtual disk image (required for storage, e.g. -hda)
  -i, --iso PATH     Bootable ISO image (Android-x86 / Android TV installer)
  -m, --ram MB       RAM in MiB (default: $RAM)
  -c, --cpus N       Number of vCPUs (default: $CPUS)
  -D, --display      Display backend: gtk | sdl | none (default: $DISPLAY_BACKEND)
  -A, --accel MODE   Accel: auto | kvm | tcg (default: $ACCEL)
  -q, --qmp PORT     QMP TCP port (default: $QMP_PORT)
  -h, --help         Show this help

Examples:
  $0 -i android-x86.iso -d android-tv.img
  $0 -d android-tv.img -m 8192 -c 2
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -d|--disk) DISK="${2:-}"; shift 2 ;;
        -i|--iso) ISO="${2:-}"; shift 2 ;;
        -m|--ram) RAM="${2:-}"; shift 2 ;;
        -c|--cpus) CPUS="${2:-}"; shift 2 ;;
        -D|--display) DISPLAY_BACKEND="${2:-}"; shift 2 ;;
        -A|--accel) ACCEL="${2:-}"; shift 2 ;;
        -q|--qmp) QMP_PORT="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

if [ -z "$DISK" ] && [ -z "$ISO" ]; then
    echo "Error: at least one of --disk or --iso is required." >&2
    usage >&2
    exit 1
fi

if [ ! -x "$QEMU" ]; then
    echo "Error: QEMU binary not found: $QEMU" >&2
    echo "Build it first in $SCRIPT_DIR/build" >&2
    exit 1
fi

for f in "$DISK" "$ISO"; do
    if [ -n "$f" ] && [ ! -f "$f" ]; then
        echo "Error: file not found: $f" >&2
        exit 1
    fi
done

case "$ACCEL" in
    auto)
        if [ -w /dev/kvm ] 2>/dev/null; then
            ACCEL="kvm"
        else
            ACCEL="tcg"
        fi
        ;;
    kvm|tcg) ;;
    *) echo "Error: bad accel: $ACCEL" >&2; exit 1 ;;
esac

ARGS=( -accel "$ACCEL" )
ARGS+=( -cpu android64 )
ARGS+=( -m "$RAM" -smp "$CPUS" )
ARGS+=( -machine usb=on )
ARGS+=( -device usb-kbd )
ARGS+=( -device usb-tablet )
ARGS+=( -boot menu=on )
ARGS+=( -soundhw hda )
ARGS+=( -netdev user,id=n1,hostfwd=tcp::5555-:5555 -device e1000,netdev=n1 )
ARGS+=( -device direct-express-pci )
ARGS+=( -display "$DISPLAY_BACKEND" )

if [ -n "$DISK" ]; then
    ARGS+=( -hda "$DISK" )
fi

if [ -n "$ISO" ]; then
    ARGS+=( -cdrom "$ISO" )
fi

ARGS+=( -qmp "tcp:127.0.0.1:${QMP_PORT},server,nowait" )
ARGS+=( -monitor stdio )

echo "==== Trinity ATV ===="
echo "QEMU:   $QEMU"
echo "Disk:   ${DISK:-none}"
echo "ISO:    ${ISO:-none}"
echo "RAM:    ${RAM} MiB"
echo "CPUs:   $CPUS"
echo "Accel:  $ACCEL"
echo "Display: $DISPLAY_BACKEND"
echo "ADB:    localhost:5555 -> guest:5555"
echo "QMP:    tcp:127.0.0.1:${QMP_PORT}"
echo "====================="
exec "$QEMU" "${ARGS[@]}"