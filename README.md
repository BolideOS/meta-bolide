# BolideOS

Standalone apps for [AsteroidOS](https://asteroidos.org/) watches.

BolideOS is not a fork of AsteroidOS — these are independent apps that install and run on stock AsteroidOS via `.ipk` packages. The `meta-bolide` Yocto layer can also be used to build custom images that include these apps.

## Repos

| Repo | Description |
|------|-------------|
| [bolide-powerd](https://github.com/BolideOS/bolide-powerd) | Power management daemon — battery health, coulomb counting, power profiles |
| [bolide-settings](https://github.com/BolideOS/bolide-settings) | Settings app — power profiles UI, battery health display, airplane mode |
| [meta-bolide](https://github.com/BolideOS/meta-bolide) | Yocto/OE layer for building BolideOS apps |

## Install on a watch

```bash
# Build the .ipk (or grab from releases)
scp bolide-powerd_*.ipk root@192.168.2.15:/tmp/
ssh root@192.168.2.15 opkg install /tmp/bolide-powerd_*.ipk
```

## Build with Yocto

Add `meta-bolide` to your `bblayers.conf`:

```
BBLAYERS += "/path/to/meta-bolide"
```

Then build:

```bash
bitbake bolide-powerd bolide-settings
```
