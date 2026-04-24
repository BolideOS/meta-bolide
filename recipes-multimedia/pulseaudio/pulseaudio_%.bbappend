# BolideOS: Disable PulseAudio autospawn on smartwatches.
# PA is managed by bolide-powerd via power profiles (started/stopped as needed).
# Without this, libpulse clients (e.g. Qt Multimedia) will autospawn PA
# via "pulseaudio --start", bypassing systemd and power management.

set_cfg_value () {
        sed -i -e "s/\(; *\)\?$2 =.*/$2 = $3/" "$1"
        if ! grep -q "^$2 = $3\$" "$1"; then
                die "Use of sed to set '$2' to '$3' in '$1' failed"
        fi
}

do_compile:append () {
        set_cfg_value src/pulse/client.conf autospawn no
}
