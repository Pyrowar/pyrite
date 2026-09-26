ARG FEDORA_VERSION=44
ARG KERNEL_FLAVOR=main

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Novideo akmods
FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_VERSION} AS akmods-kernel
FROM ghcr.io/ublue-os/akmods-nvidia-open:${KERNEL_FLAVOR}-${FEDORA_VERSION} AS akmods-nvidia

# Base Image
FROM ghcr.io/ublue-os/silverblue-main:latest

ARG KERNEL_FLAVOR

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=akmods-kernel,src=/,dst=/tmp/akmods-kernel \
    --mount=type=bind,from=akmods-nvidia,src=/rpms,dst=/tmp/akmods-nvidia \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    KERNEL_FLAVOR=${KERNEL_FLAVOR} /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
