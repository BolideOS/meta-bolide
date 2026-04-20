#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The asteroid build tree lives in a sibling 'asteroid/' directory.
# Override with ASTEROID_DIR env var if your layout differs.
ASTEROID_DIR="${ASTEROID_DIR:-$(cd "${SCRIPT_DIR}/../asteroid" 2>/dev/null && pwd || echo "${SCRIPT_DIR}")}"
BUILD_DIR="${ASTEROID_DIR}/build"
DEPLOY_DIR="${BUILD_DIR}/tmp/deploy/images/emulator"
PREPARE_BUILD="${ASTEROID_DIR}/prepare-build.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[emulator]${NC} $*"; }
warn()  { echo -e "${YELLOW}[emulator]${NC} $*"; }
error() { echo -e "${RED}[emulator]${NC} $*" >&2; }

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "  (no args)        Build image if not found, then launch emulator"
    echo "  --force-build    Force rebuild the image, then launch"
    echo "  --launch-only    Launch only (skip build, image must exist)"
    echo "  --resolution WxH Set display resolution (default: 800x800)"
    echo "                   Common watch resolutions:"
    echo "                     454x454  TicWatch Pro 3 Ultra, Galaxy Watch 4/5"
    echo "                     416x416  Apple Watch Series 7+ (45mm)"
    echo "                     466x466  Pixel Watch 2"
    echo "                     800x800  Default (scaled up for development)"
    echo "  --help           Show this help"
    echo ""
    echo "SSH access:   ssh -p 2222 root@127.0.0.1"
    exit 0
}

find_image() {
    if [ ! -d "${DEPLOY_DIR}" ]; then
        return 1
    fi
    ROOTFS=$(ls -t "${DEPLOY_DIR}"/asteroid-image-emulator.rootfs-*.ext4 2>/dev/null | head -1)
    KERNEL=$(ls -t "${DEPLOY_DIR}"/bzImage 2>/dev/null | head -1)
    if [ -z "${ROOTFS:-}" ] || [ -z "${KERNEL:-}" ]; then
        return 1
    fi
    return 0
}

build_image() {
    info "Building AsteroidOS emulator image..."
    info "This may take a while on first build."

    if [ ! -f "${PREPARE_BUILD}" ]; then
        error "prepare-build.sh not found at ${PREPARE_BUILD}"
        exit 1
    fi

    # prepare-build.sh fetches sources and sets up build/conf if needed
    cd "${ASTEROID_DIR}"
    bash "${PREPARE_BUILD}" emulator

    bash -c "
        source '${ASTEROID_DIR}/src/oe-core/oe-init-build-env' '${BUILD_DIR}' > /dev/null
        bitbake asteroid-image
    "

    if ! find_image; then
        error "Build completed but image artifacts not found in ${DEPLOY_DIR}"
        exit 1
    fi

    info "Build complete!"
    info "  Root FS: ${ROOTFS}"
    info "  Kernel:  ${KERNEL}"
}

find_qemu() {
    # The emulator image is 32-bit (core2-32), so we need qemu-system-i386.
    if command -v qemu-system-i386 &>/dev/null; then
        QEMU_BIN="qemu-system-i386"
    elif [ -x "${BUILD_DIR}/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-i386" ]; then
        QEMU_BIN="${BUILD_DIR}/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-i386"
    else
        error "qemu-system-i386 not found."
        error "Install QEMU or build it with: bitbake qemu-helper-native"
        exit 1
    fi

    DISPLAY_BACKENDS=$("${QEMU_BIN}" -display help 2>&1 | grep -oP '^\w+' || true)
    DISPLAY_OPT=""
    GPU_DEVICE=""

    if echo "${DISPLAY_BACKENDS}" | grep -q '^gtk$'; then
        DISPLAY_OPT="-display gtk,gl=on,show-cursor=on"
        GPU_DEVICE="-vga none -device virtio-vga-gl"
        info "Using GTK display with virgl 3D acceleration"
    elif echo "${DISPLAY_BACKENDS}" | grep -q '^sdl$'; then
        DISPLAY_OPT="-display sdl,gl=on"
        GPU_DEVICE="-vga none -device virtio-vga-gl"
        info "Using SDL display with virgl 3D acceleration"
    else
        warn "No GTK/SDL display backend found, trying fallback..."
        if "${QEMU_BIN}" -device help 2>&1 | grep -q 'virtio-vga-gl'; then
            GPU_DEVICE="-vga none -device virtio-vga-gl"
        elif "${QEMU_BIN}" -device help 2>&1 | grep -q 'virtio-vga'; then
            GPU_DEVICE="-vga none -device virtio-vga"
        else
            GPU_DEVICE="-vga none -device virtio-gpu-pci"
        fi
        for backend in gtk sdl spice-app; do
            if echo "${DISPLAY_BACKENDS}" | grep -q "^${backend}$"; then
                DISPLAY_OPT="-display ${backend}"
                break
            fi
        done
        if [ -z "${DISPLAY_OPT}" ]; then
            error "No graphical display backend available in ${QEMU_BIN}"
            error "Available backends: ${DISPLAY_BACKENDS}"
            error "Install QEMU with GTK or SDL support."
            exit 1
        fi
    fi

    KVM_OPT=""
    CPU_OPT="-cpu IvyBridge"
    if [ -w /dev/kvm ]; then
        KVM_OPT="-enable-kvm"
        CPU_OPT="-cpu host"
        info "KVM hardware acceleration enabled"
    else
        warn "KVM not available (no /dev/kvm or no permission). Emulation will be slower."
        warn "  To enable: sudo usermod -aG kvm \$USER && newgrp kvm"
    fi
}

launch_emulator() {
    info "Launching AsteroidOS emulator..."
    info "  Root FS: $(basename "${ROOTFS}")"
    info "  Kernel:  $(basename "${KERNEL}")"
    info ""
    info "  SSH:     ssh -p 2222 root@127.0.0.1"
    info ""
    info "Close the QEMU window or press Ctrl+C to stop."
    echo ""

    # On Wayland compositors (Hyprland), the QEMU window size determines the
    # guest display resolution. We set window rules to float and resize QEMU to
    # the target resolution so AsteroidOS gets a square viewport matching real
    # watch displays.
    if [ -f "${SCRIPT_DIR}/resize_qemu.py" ]; then
        python3 "${SCRIPT_DIR}/resize_qemu.py" ${DISPLAY_RES} || true
    fi

    # GPU flags mirror emulator.conf QB_GRAPHICS / QB_OPT_APPEND so this script
    # works the same way as Yocto's runqemu but without requiring the OE
    # environment to be sourced.
    #
    # On Wayland compositors (e.g. Hyprland), QEMU GTK's native Wayland backend
    # does not route absolute mouse events to the USB tablet device unless
    # grab-on-hover is used (which traps the pointer).  XWayland (GDK_BACKEND=x11)
    # crashes with EGL.  Solution: use virtio-tablet-pci + virtio-keyboard-pci
    # instead of usb-tablet/usb-kbd — virtio input devices work natively with
    # the Wayland pointer protocol without needing grab.
    local QEMU_DISPLAY_OPT="${DISPLAY_OPT}"
    local INPUT_DEVICES="-usb -device usb-tablet -usb -device usb-kbd"
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && echo "${DISPLAY_OPT}" | grep -q '^-display gtk'; then
        INPUT_DEVICES="-device virtio-tablet-pci -device virtio-keyboard-pci"
        info "Wayland detected: using virtio input devices (no grab needed)"
    fi

    "${QEMU_BIN}" \
        -device virtio-net-pci,netdev=net0,mac=52:54:00:12:35:02 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
        -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 \
        -drive file="${ROOTFS}",if=virtio,format=raw,snapshot=on \
        ${INPUT_DEVICES} \
        ${CPU_OPT} -machine q35,i8042=off ${KVM_OPT} -smp 4 -m 512 \
        ${GPU_DEVICE} \
        ${QEMU_DISPLAY_OPT} \
        -kernel "${KERNEL}" \
        -append "root=/dev/vda rw ip=dhcp video=Virtual-1:${DISPLAY_RES}" &
    QEMU_PID=$!

    # Wait for the emulator to boot and SSH to become available, then update the
    # KMS config to match the actual QEMU display resolution.
    # Qt's eglfs_kms defaults to the "preferred" DRM mode (typically 800x873 from
    # the virtual EDID) which mismatches the actual window size, breaking mouse
    # coordinate mapping and making swiping impossible.
    # SSH options: accept new host keys automatically (emulator image changes
    # frequently), use a dedicated known_hosts file to avoid polluting the
    # user's main file, and skip password auth.
    local SSH_OPTS="-o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new -o BatchMode=yes -o UserKnownHostsFile=${HOME}/.ssh/known_hosts_bolideos_emu"

    info "Waiting for emulator to boot..."
    local retries=0
    while [ $retries -lt 30 ]; do
        if ssh ${SSH_OPTS} -p 2222 root@localhost true 2>/dev/null; then
            # Read the actual framebuffer size the DRM driver settled on
            local fbsize
            fbsize=$(ssh ${SSH_OPTS} -p 2222 root@localhost \
                     'cat /sys/class/graphics/fb0/virtual_size' 2>/dev/null)
            if [ -n "${fbsize}" ]; then
                local fbw="${fbsize%%,*}"
                local fbh="${fbsize##*,}"
                info "Detected display: ${fbw}x${fbh}"
                # Update KMS config and restart compositor.
                # Must use 'su - ceres' because 'systemctl --user -M ceres@'
                # evaluates ConditionUser= in root's context, always failing.
                ssh ${SSH_OPTS} -p 2222 root@localhost \
                    "printf '{\"device\":\"/dev/dri/card0\",\"outputs\":[{\"name\":\"Virtual1\",\"mode\":\"${fbw}x${fbh}\"}]}' > /var/lib/environment/compositor/kms.json && su - ceres -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart bolide-launcher' 2>/dev/null || su - ceres -c 'XDG_RUNTIME_DIR=/run/user/1000 systemctl --user restart asteroid-launcher' 2>/dev/null" || true
                info "KMS config updated to ${fbw}x${fbh}, compositor restarted."
            fi

            # Disable MCE display blanking — in the emulator there's no
            # power button to wake the screen and inactivity timeout will
            # blank the display making it look broken.
            ssh ${SSH_OPTS} -p 2222 root@localhost \
                "mcetool --set-never-blank=enabled --set-inhibit-mode=stay-on -P 2>/dev/null; \
                 dbus-send --system --type=method_call --dest=com.nokia.mce \
                 /com/nokia/mce/request com.nokia.mce.request.req_display_state_on 2>/dev/null" || true
            info "MCE display blanking disabled."

            # Deploy BolideOS wallpapers — the base image doesn't have them
            # until rebuilt.  SCP the real files from the bolide-launcher repo.
            local LAUNCHER_REPO="${SCRIPT_DIR}/../bolide-launcher"
            if [ -d "${LAUNCHER_REPO}/wallpapers/full" ]; then
                ssh ${SSH_OPTS} -p 2222 root@localhost \
                    "rm -rf /usr/share/bolide-launcher/wallpapers /usr/share/asteroid-launcher/wallpapers; \
                     mkdir -p /usr/share/bolide-launcher/wallpapers/{full,140,160,180,200,227}" || true
                local SCP_OPTS="-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=${HOME}/.ssh/known_hosts_bolideos_emu"
                scp ${SCP_OPTS} -P 2222 "${LAUNCHER_REPO}"/wallpapers/full/* root@localhost:/usr/share/bolide-launcher/wallpapers/full/ 2>/dev/null || true
                for sz in 140 160 180 200 227; do
                    scp ${SCP_OPTS} -P 2222 "${LAUNCHER_REPO}"/wallpapers/${sz}/* root@localhost:/usr/share/bolide-launcher/wallpapers/${sz}/ 2>/dev/null || true
                done
                info "BolideOS wallpapers deployed."
            fi

            break
        fi
        retries=$((retries + 1))
        sleep 2
    done

    if [ $retries -ge 30 ]; then
        warn "Could not reach emulator via SSH. KMS config may need manual update."
        warn "  ssh -p 2222 root@localhost"
    fi

    info "Emulator running (PID ${QEMU_PID}). Press Ctrl+C to stop."
    wait "${QEMU_PID}"
}

FORCE_BUILD=false
LAUNCH_ONLY=false
DISPLAY_RES="800x800"

while [ $# -gt 0 ]; do
    case "$1" in
        --force-build)  FORCE_BUILD=true ;;
        --launch-only)  LAUNCH_ONLY=true ;;
        --resolution)
            shift
            if [ -z "${1:-}" ]; then
                error "--resolution requires a WxH argument (e.g. 454x454)"
                exit 1
            fi
            DISPLAY_RES="$1"
            ;;
        --help|-h) usage ;;
        *) error "Unknown option: $1"; usage ;;
    esac
    shift
done

info "Display resolution: ${DISPLAY_RES}"

if [ "${LAUNCH_ONLY}" = true ]; then
    if ! find_image; then
        error "No emulator image found. Run without --launch-only to build first."
        exit 1
    fi
elif [ "${FORCE_BUILD}" = true ] || ! find_image; then
    if ! find_image; then
        info "No existing image found, building..."
    fi
    build_image
else
    info "Using existing image (use --force-build to force rebuild)"
fi

find_qemu
launch_emulator
