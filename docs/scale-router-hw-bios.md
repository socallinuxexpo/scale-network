# BIOS Settings configured for the PC-based routers used for SCALE

## Routers will be used starting for SCALE 23x

This cheat sheet should be used if the BIOS settings was cleared
(eg. if the coin cell battery has died) or was reset.

- To enter Firmware setup: Hold (F2) or (DELETE) while pressing POWER.
- Load optimized BIOS defaults. (F5)
- Set the BIOS system clock to **UTC**.
- Ensure firmware is the latest version released the motherboard manufacturer.
- As of this writing on 10/18/2025: Version 3621 (2025/04/01)
- **IMPORTANT: No beta firmware** - must be the latest stable release.

## UEFI BIOS Settings (Current as of 11/9/2025)

| BIOS setting | Current Setting | Recommended Setting |
|--------------------|--------------------|--------------------|
| NVMe RAID Mode | **Disabled** | No change |
| Onboard Realtek LAN Controller | **Enabled** | No change |
| WiFi Controller | Enabled | **Disabled** |
| Bluetooth Controller | Enabled | **Disabled** |
| Virtualization (AMD-V) | | **Enabled** |
| SR-IOV Support | | **Enabled** |
