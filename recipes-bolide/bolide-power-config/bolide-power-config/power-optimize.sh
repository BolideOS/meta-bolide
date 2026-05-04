#!/bin/sh
# BolideOS Power Optimization — runs at boot (before bolide-powerd)
# Sets up low-level kernel tunables that powerd cannot control.
# CPU governor, CPU cores, and audio modules are managed by bolide-powerd
# via power profiles — do NOT set them here.

# --- Set minimum CPU frequency when idle ---
# Force lowest freq as floor — governor will scale up as needed
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
    cat "$(dirname "$f")/cpuinfo_min_freq" > "$f" 2>/dev/null
done

# --- Enable kernel autosleep ---
# [DISABLED]: This forces the watch into deep sleep before the UI can even load, 
# breaking hardware buttons and causing a permanent black screen.
# if [ -f /sys/power/autosleep ]; then
#     echo mem > /sys/power/autosleep
# fi


# --- Console suspend (don't wake for printk) ---
if [ -f /sys/module/printk/parameters/console_suspend ]; then
    echo 1 > /sys/module/printk/parameters/console_suspend
fi

# --- Reduce kernel log level (fewer wakeups from printk) ---
echo 4 > /proc/sys/kernel/printk 2>/dev/null

# --- Enable LPM deep sleep at runtime ---
# (safety net in case kernel cmdline still has sleep_disabled=1)
if [ -f /sys/module/lpm_levels/parameters/sleep_disabled ]; then
    echo N > /sys/module/lpm_levels/parameters/sleep_disabled
fi
if [ -f /sys/module/lpm_levels_legacy/parameters/sleep_disabled ]; then
    echo N > /sys/module/lpm_levels_legacy/parameters/sleep_disabled
fi

# --- IO Scheduler: noop for flash storage ---
# cfq wastes CPU on seek optimization that flash doesn't need
for q in /sys/block/mmcblk*/queue/scheduler; do
    echo noop > "$q" 2>/dev/null
done

# --- Reduce IO readahead (flash has no seek penalty) ---
for q in /sys/block/mmcblk*/queue/read_ahead_kb; do
    echo 64 > "$q" 2>/dev/null
done

# --- Disable IO stats collection (fewer timer interrupts) ---
for q in /sys/block/mmcblk*/queue/iostats; do
    echo 0 > "$q" 2>/dev/null
done

# --- Disable add_random entropy from block devices ---
for q in /sys/block/mmcblk*/queue/add_random; do
    echo 0 > "$q" 2>/dev/null
done

# --- VM tuning: reduce dirty page writeback frequency ---
echo 30 > /proc/sys/vm/dirty_ratio 2>/dev/null
echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null
echo 6000 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null
echo 6000 > /proc/sys/vm/dirty_expire_centisecs 2>/dev/null
echo 50 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
echo 0 > /proc/sys/vm/page-cluster 2>/dev/null
echo 1 > /proc/sys/vm/laptop_mode 2>/dev/null

# --- Disable kernel watchdog (saves timer wakeups) ---
echo 0 > /proc/sys/kernel/watchdog 2>/dev/null
echo 0 > /proc/sys/kernel/nmi_watchdog 2>/dev/null
# Disable hung task detector (another source of timer wakeups)
echo 0 > /proc/sys/kernel/hung_task_timeout_secs 2>/dev/null

# --- Reduce scheduler wakeups ---
echo 1 > /proc/sys/kernel/sched_child_runs_first 2>/dev/null
# Increase scheduler migration cost to reduce cross-CPU wakeups
echo 5000000 > /proc/sys/kernel/sched_migration_cost_ns 2>/dev/null

# --- Reduce stat collection overhead ---
echo 0 > /proc/sys/kernel/sched_schedstats 2>/dev/null

# --- Timer slack: allow kernel to coalesce timer wakeups ---
# Default 50us is too aggressive; 100ms lets timers batch
echo 100000 > /proc/sys/kernel/timer_migration 2>/dev/null

# --- WiFi power save ---
if [ -d /sys/class/net/wlan0 ]; then
    iw dev wlan0 set power_save on 2>/dev/null
fi

# --- Bluetooth power management ---
for f in /sys/class/bluetooth/hci*/idle_timeout; do
    echo 3000 > "$f" 2>/dev/null
done

# --- Modem subsystem: shut down entirely (no LTE on this watch) ---
# The modem PIL firmware loads at boot and causes periodic wakeups even
# with ofono masked. Find the modem subsystem and request shutdown.
for d in /sys/bus/msm_subsys/devices/subsys*; do
    if [ -f "$d/name" ] && [ "$(cat "$d/name" 2>/dev/null)" = "modem" ]; then
        if [ -f "$d/shutdown" ]; then
            echo 1 > "$d/shutdown" 2>/dev/null
            echo "power-optimize: modem subsystem shut down"
        fi
        break
    fi
done

# --- USB autosuspend ---
# [DISABLED]: This forcibly unbinds ADB and kills USB connectivity
# immediately on boot!
# for f in /sys/bus/usb/devices/*/power/autosuspend; do
#     echo 1 > "$f" 2>/dev/null
# done
# for f in /sys/bus/usb/devices/*/power/control; do
#     echo auto > "$f" 2>/dev/null
# done

# --- PCI/bus power management ---
# [DISABLED]: Blindly putting all platform devices on "auto" suspends the
# touchscreen controller, display controller, and hardware buttons!
# for f in /sys/bus/platform/devices/*/power/control; do
#     echo auto > "$f" 2>/dev/null
# done

# --- Disable kernel tracing ---
if [ -f /sys/kernel/debug/tracing/tracing_on ]; then
    echo 0 > /sys/kernel/debug/tracing/tracing_on 2>/dev/null
fi
# Disable all trace events
if [ -d /sys/kernel/debug/tracing/events ]; then
    echo 0 > /sys/kernel/debug/tracing/events/enable 2>/dev/null
fi

# --- Remount with noatime to reduce write IO ---
mount -o remount,noatime,nodiratime / 2>/dev/null
mount -o remount,noatime,nodiratime /persist 2>/dev/null
mount -o remount,noatime,nodiratime /vendor 2>/dev/null

# --- Disable core dumps (save flash writes) ---
echo 0 > /proc/sys/kernel/core_pattern 2>/dev/null
ulimit -c 0 2>/dev/null

# --- Reduce inotify limits (fewer watcher wakeups) ---
echo 128 > /proc/sys/fs/inotify/max_user_watches 2>/dev/null
echo 64 > /proc/sys/fs/inotify/max_user_instances 2>/dev/null

# --- GPU power: force lowest power state when idle ---
for f in /sys/class/kgsl/kgsl-3d0/default_pwrlevel; do
    # Set to highest numbered level (lowest power)
    max=$(cat /sys/class/kgsl/kgsl-3d0/num_pwrlevels 2>/dev/null)
    if [ -n "$max" ] && [ "$max" -gt 0 ]; then
        echo $((max - 1)) > "$f" 2>/dev/null
    fi
done
# Enable GPU NAP and power collapse
for f in /sys/class/kgsl/kgsl-3d0/force_no_nap; do
    echo 0 > "$f" 2>/dev/null
done
for f in /sys/class/kgsl/kgsl-3d0/force_rail_on; do
    echo 0 > "$f" 2>/dev/null
done
for f in /sys/class/kgsl/kgsl-3d0/force_clk_on; do
    echo 0 > "$f" 2>/dev/null
done
for f in /sys/class/kgsl/kgsl-3d0/force_bus_on; do
    echo 0 > "$f" 2>/dev/null
done
for f in /sys/class/kgsl/kgsl-3d0/idle_timer; do
    echo 64 > "$f" 2>/dev/null
done

# --- DEVFREQ: set memory/bus to powersave ---
for f in /sys/class/devfreq/*/governor; do
    echo "powersave" > "$f" 2>/dev/null
done

# --- Mask services that can't be masked at image build time ---
for svc in iptables.service systemd-networkd.service systemd-resolved.service \
           systemd-networkd-wait-online.service systemd-networkd.socket; do
    if [ ! -L "/etc/systemd/system/$svc" ]; then
        ln -sf /dev/null "/etc/systemd/system/$svc" 2>/dev/null
        systemctl stop "$svc" 2>/dev/null
    fi
done

# --- Stop and disable any running timers we don't need ---
for timer in systemd-tmpfiles-clean.timer logrotate.timer; do
    systemctl stop "$timer" 2>/dev/null
    systemctl disable "$timer" 2>/dev/null
done

# --- Reduce systemd runtime journal size ---
journalctl --vacuum-size=4M 2>/dev/null
