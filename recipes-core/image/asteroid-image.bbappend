# BolideOS: Replace upstream asteroid apps with bolide equivalents
# This bbappend swaps out the AsteroidOS apps we've forked for our
# renamed BolideOS versions.

# Remove upstream apps that we're replacing
IMAGE_INSTALL:remove = "asteroid-launcher asteroid-settings"

# Remove truly unused packages (no scenario where we want these)
IMAGE_INSTALL:remove = "ofono"
IMAGE_INSTALL:remove = "openssh-sftp-server openssh-scp"

# Keep but service-mask these — bolide-powerd can enable them via profiles:
#   pulseaudio-server — needed when audio_enabled profile is active
#   ngfd — haptic/notification feedback, re-enable if needed
#   polkit — security framework, re-enable for multi-user scenarios
#   nfcd — NFC, re-enable when NFC profile support lands

# Trim indirect dependencies that are wasteful on a watch
BAD_RECOMMENDATIONS += "systemd-networkd"
BAD_RECOMMENDATIONS += "systemd-resolved"
BAD_RECOMMENDATIONS += "kernel-module-nf-conntrack-ipv6"
BAD_RECOMMENDATIONS += "kernel-module-nf-conntrack-ipv4"

# Add bolide replacements + new apps
# bolide-shell combines launcher + settings in one process for faster settings access
IMAGE_INSTALL:append = " bolide-shell bolide-powerd bolide-fitness bolide-power-config fonts-roboto-condensed bolide-journald-persistent"
