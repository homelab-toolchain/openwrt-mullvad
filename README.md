<h1 align="center">OpenWrt Mullvad</h1>

<p align="center">
<a href="#">
<img src="https://img.shields.io/github/last-commit/homelab-toolchain/openwrt-mullvad?style=for-the-badge"/>
</a>
</p>

---

## Quick Start

**Step 1:** Install `git`
```
opkg update && opkg install git git-http jq
```

**Step 2:** Clone repository and make each script executable
```
mkdir -p /homelab-toolchain && cd /homelab-toolchain && \
git clone https://github.com/homelab-toolchain/openwrt-mullvad.git && cd openwrt-mullvad && \
chmod +x checker.sh && ash checker.sh
```

**Step 3:** Add cronjob to periodically pull repository updates
```
0 * * * * ash /homelab-toolchain/openwrt-mullvad/checker.sh
```

---

> [!Warning]
> **Disclaimer**: This project is not affiliated with any WireGuard provider. No affiliate links are used or included in this repository.
All actions demonstrated here could have been carried out by anyone and are not intended to be, nor should they be interpreted as, hacking.
If certain servers or functionalities do not work as expected, this repository is not responsible.
For typical use cases, it is recommended to use the official files and documentation provided by your chosen WireGuard provider.

> [!Tip]
> Do you have an idea for this to be better/faster/more useful, please create an issue.