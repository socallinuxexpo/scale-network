# Dynamic Config

Leveraged via `/root/bin/config-version.sh` which is present in all AP Images

> Note: Network and Wireless configs will always match config numbers

## Config 0

- Summary: Base config
- Use Case: We will typically use for the conference for the vast majority of APs

## Config 1

- Summary: Config for simple non-vlan configurations
- Use Case:
  - Init wireless prior to full network being up during days leading up to scale conference.
  - Tech team events where we need AP wireless but vlan 503 is not present on switch.
