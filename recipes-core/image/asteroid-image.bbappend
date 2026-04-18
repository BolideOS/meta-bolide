# BolideOS: Replace upstream asteroid apps with bolide equivalents
# This bbappend swaps out the AsteroidOS apps we've forked for our
# renamed BolideOS versions.

# Remove upstream apps that we're replacing
IMAGE_INSTALL:remove = "asteroid-launcher asteroid-settings"

# Add bolide replacements + new apps
IMAGE_INSTALL:append = " bolide-launcher bolide-settings bolide-powerd bolide-fitness"
