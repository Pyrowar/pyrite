#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y steam mangohud
dnf5 remove -y gnome-system-monitor
# Optional services and stuff to remove
# TODO:
# check if exists
# systemctl disable ublue-os-media-automount.service
# dnf5 remove -y ublue-os-media-automount-ude

# Rebrand
# TODO:
# Learn which files to mv

# Release
# TODO: make actual svgs

# sed -i "s/^NAME=.*/NAME=\"Pyrite\"/" /usr/lib/os-release
# sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Pyrite\"/" /usr/lib/os-release
# sed -i "s/^LOGO=.*/LOGO=pyrite-icon/" /usr/lib/os-release

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
