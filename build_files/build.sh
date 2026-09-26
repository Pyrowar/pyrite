#!/bin/bash

set -ouex pipefail

KERNEL_FLAVOR="${KERNEL_FLAVOR:-main}"

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Manage Fedora packages:
dnf5 install -y gnome-shell-extension-caffeine \
	gnome-shell-extension-blur-my-shell \
	gnome-shell-extension-dash-to-dock \
	gnome-shell-extension-appindicator \
	nautilus-gsconnect
	
dnf5 remove -y gnome-system-monitor
# remove weak dependencies: gnome-extensions-app

# Libvirt
# dnf5 install -y qemu libvirt guestfs-tools
# systemctl enable libvirtd.service

# Podman
systemctl enable podman.socket

# Use a COPR Example:
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

# Swap the stock Fedora kernel for the OGC kernel
if [[ "${KERNEL_FLAVOR}" == "ogc" ]]; then
    # Bypass kernel-install's automatic dracut/rpm-ostree hooks during
    # the RPM transaction. Both write through /tmp (tmpfs, a different
    # device than the overlay root) and fail with EXDEV. We regenerate
    # the initramfs explicitly ourselves, later in this script.
    
    # Modern problems require Bloatzzite solutions.
    # From bazzite/build_files/install-kernel-akmods
    
    pushd /usr/lib/kernel/install.d
    mv 05-rpmostree.install 05-rpmostree.install.bak
    mv 50-dracut.install 50-dracut.install.bak
    printf '%s\n' '#!/bin/sh' 'exit 0' > 05-rpmostree.install
    printf '%s\n' '#!/bin/sh' 'exit 0' > 50-dracut.install
    chmod +x 05-rpmostree.install 50-dracut.install
    popd

    for pkg in kernel kernel{-core,-modules,-modules-core,-modules-extra,-tools-libs,-tools}; do
        rpm --erase "${pkg}" --nodeps 2>/dev/null || true
    done

    rm -rf /usr/lib/modules

    dnf5 -y install /tmp/akmods-kernel/kernel-rpms/kernel-*.rpm

    dnf5 versionlock add kernel kernel-core kernel-modules 2>/dev/null || true
    # Do we restore the real 05-rpmostree.install/50-dracut.install? Dude, I don't know.
    
    # Kernel package layout assumes a traditional (non-ostree) /boot
    # bootc populates /boot from /usr/lib/modules at deploy time.
    find /boot -mindepth 1 -delete
fi

# SecureBoot signing key + repos for ublue-built kmods (covers the nvidia-open kmod too)
dnf5 install -y /tmp/akmods-kernel/rpms/ublue-os/ublue-os-akmods-addons-*.rpm

dnf5 -y remove --no-autoremove nvidia-gpu-firmware || true

# Nvidia-open driver delegated entirely to the installer shipped inside the akmods-nvidia-open image.
# It resolves exact kmod/driver versions, handles multilib, repo enable/disable
# and the version-match check itself.
IMAGE_NAME="silverblue" \
AKMODNV_PATH="/tmp/akmods-nvidia" \
MULTILIB=1 \
/tmp/akmods-nvidia/ublue-os/nvidia-install.sh

### Rebuild the initramfs:
# nvidia-install.sh flips dracut to force_drivers,
# which only takes effect once the initramfs is regenerated.
#
# --add fido2 pulls in FIDO2/WebAuthn support (hardware security keys) into the initramfs,
# presumably because ublue images support disk decryption unlock via FIDO2 tokens.

QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' kernel)"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v \
    --add ostree --add fido2 -f "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/usr/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

### Cleanup
rm -rf /run/dnf /run/selinux-policy /tmp/* 2>/dev/null || true
rm -rf /run/dnf /run/selinux-policy /tmp/* 2>/dev/null || true

# XKB compiled cache dir from the nvidia driver post-install.
# Declare via tmpfiles.d instead of shipping it in the image.
rm -rf /var/lib/xkb
echo 'd /var/lib/xkb 0755 root root - -' > /usr/lib/tmpfiles.d/xkb.conf
