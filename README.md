# Pyrite

Pyrite is Fedora Silverblue image taken from ublue-os/silverblue-main for novideo users (only 16xx series and newer)
with custom stuff yet to be readded by me.

It's built with the wonderful ublue-image-template!

## Variants

- **liquid-pyrite:** stock Fedora kernel + Nvidia akmods
- **volatile-pyrite:** OGC kernel + Nvidia OGC akmods

You can freely rebase between them whenever you want.

## Installation

### Switch from an existing Fedora Atomic / Universal Blue system
```
# Main: liquid-pyrite
sudo bootc switch --enforce-container-sigpolicy ghcr.io/pyrowar/liquid-pyrite:latest

# OGC: volatile-pyrite
sudo bootc switch --enforce-container-sigpolicy ghcr.io/pyrowar/volatile-pyrite:latest
```

### Install via ISO

Not released yet.

### Image Verification
All images are signed with Cosign. The public key is included in this repository as cosign.pub.
```
cosign verify --key cosign.pub ghcr.io/pyrowar/liquid-pyrite:latest
```
### Changing Channels
Switch your system to a different release channel at any time:

### Rollback
If an update causes issues, you can roll back to the previous deployment without re-downloading anything:
```
sudo bootc rollback
systemctl reboot
```
### Building Locally
Pyrite uses Just for build automation (available by default on all Universal Blue images).

#### Container Images
```
soon.
```
#### ISOs
```
soon.
```
#### QCOW2 VM Images
```
soon.
```
Run `just` with no arguments to see all available recipes.

### License
Apache-2.0
