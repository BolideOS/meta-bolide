#!/bin/sh
# suspend-helper: Two critical fixes for suspend on BolideOS:
#
# 1. COMPOSITOR FIX: MCE misses bolide-shell's compositor interface because
#    the D-Bus interface registers ~2.8s after the bus name (lipstick race).
#    MCE's retry loop then wakes the system from suspend every ~90s forever.
#    Fix: wait for the interface to be ready, then restart MCE once so it
#    detects the compositor on startup via NameOwnerChanged. This eliminates
#    the retry loop and its 460+ RTC wakeups per 12h.
#
# 2. MCE_MUX FIX: Even with compositor detected, MCE holds the mce_mux
#    wakelock after each display-off transition (compositor ack issue).
#    Fix: release mce_mux 5s after display goes off.

WAKE_UNLOCK="/sys/power/wake_unlock"
WAKE_LOCK_FILE="/sys/power/wake_lock"
DELAY=5
TIMER_PID=""
COMPOSITOR_FIXED=0

log() { logger -t suspend-helper "$1"; }

release_mce_mux() {
    if grep -q mce_mux "$WAKE_LOCK_FILE" 2>/dev/null; then
        echo mce_mux > "$WAKE_UNLOCK"
        log "released mce_mux"
    fi
}

cancel_timer() {
    if [ -n "$TIMER_PID" ] && kill -0 "$TIMER_PID" 2>/dev/null; then
        kill "$TIMER_PID" 2>/dev/null
        wait "$TIMER_PID" 2>/dev/null
    fi
    TIMER_PID=""
}

schedule_release() {
    cancel_timer
    ( sleep "$DELAY"; release_mce_mux ) &
    TIMER_PID=$!
}

# --- Phase 1: Fix compositor detection ---
# Wait for bolide-shell's D-Bus interface to be fully registered,
# then restart MCE so it detects the compositor cleanly.
fix_compositor() {
    log "waiting for compositor interface..."
    for i in $(seq 1 60); do
        if dbus-send --system --print-reply --dest=org.nemomobile.compositor \
            / org.nemomobile.compositor.setUpdatesEnabled boolean:true \
            2>/dev/null | grep -q "method return"; then
            log "compositor interface ready after ${i}s, restarting MCE"
            systemctl restart mce
            sleep 3
            COMPOSITOR_FIXED=1
            log "MCE restarted, compositor should be detected"
            return 0
        fi
        sleep 1
    done
    log "compositor interface never appeared, MCE will run without it"
    return 1
}

# --- Phase 2: Disable fuel gauge wakeup (IRQ-only mode) ---
disable_fg_wakeup() {
    FG_WAKEUP="/sys/devices/platform/soc/200f000.qcom,spmi/spmi-0/spmi0-00/200f000.qcom,spmi:qcom,pm660@0:qpnp,fg/power/wakeup"
    if [ -f "$FG_WAKEUP" ]; then
        echo "disabled" > "$FG_WAKEUP" 2>/dev/null
        log "fuel gauge wakeup disabled (IRQ-only mode)"
    fi
}

# Ensure autosleep is set (safe to do here because display is managed by MCE)
echo mem > /sys/power/autosleep 2>/dev/null
log "started, autosleep=mem"

# Fix compositor detection (runs once at boot)
fix_compositor

# Disable FG periodic wakeup
disable_fg_wakeup

# Check initial display state
INIT_STATE=$(dbus-send --system --print-reply --dest=com.nokia.mce \
    /com/nokia/mce/request com.nokia.mce.request.get_display_status 2>/dev/null \
    | grep string | head -1 | sed 's/.*"\(.*\)"/\1/')
log "initial display state: $INIT_STATE"
if [ "$INIT_STATE" = "off" ]; then
    schedule_release
fi

# Monitor display state changes via MCE D-Bus signal
dbus-monitor --system "interface=com.nokia.mce.signal,member=display_status_ind" 2>/dev/null | \
while read -r line; do
    case "$line" in
        *string*)
            STATE=$(echo "$line" | sed 's/.*"\(.*\)"/\1/')
            case "$STATE" in
                off)
                    log "display off, scheduling mce_mux release in ${DELAY}s"
                    schedule_release
                    ;;
                on|dim)
                    log "display $STATE, cancelling timer"
                    cancel_timer
                    ;;
            esac
            ;;
    esac
done
