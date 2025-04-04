#!/bin/bash

set -eu -o pipefail

KERNEL_REL=6.8.0
UBUNTU_REL=58.60
PKGREL=1
KERNEL_BRANCH="Ubuntu-${KERNEL_REL}-${UBUNTU_REL}"
KERNEL_VERSION="${KERNEL_REL}-${UBUNTU_REL}-generic"
KERNEL_REPOSITORY=git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/noble
REPO_PATH=$(pwd)
WORKING_PATH=/root/work
KERNEL_PATH="${WORKING_PATH}/linux-kernel"

### Debug commands
echo "KERNEL_VERSION=$KERNEL_VERSION"
echo "${WORKING_PATH}"
echo "Current path: ${REPO_PATH}"
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

get_next_version () {
  echo $PKGREL
}

### Clean up
rm -rfv ./*.deb

mkdir "${WORKING_PATH}" && cd "${WORKING_PATH}"
cp -rf "${REPO_PATH}"/{patches,templates} "${WORKING_PATH}"
rm -rf "${KERNEL_PATH}"

### Dependencies
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y build-essential fakeroot libncurses-dev bison flex libssl-dev libelf-dev \
  openssl dkms libudev-dev libpci-dev libiberty-dev autoconf wget xz-utils git \
  libcap-dev bc rsync cpio debhelper kernel-wedge curl gawk dwarves zstd python3

### get Kernel
git clone --depth 1 --single-branch --branch "${KERNEL_BRANCH}" \
  "${KERNEL_REPOSITORY}" "${KERNEL_PATH}"
cd "${KERNEL_PATH}" || exit

#### Create patch file with custom drivers
echo >&2 "===]> Info: Creating patch file... "
KERNEL_VERSION="${KERNEL_VERSION}" WORKING_PATH="${WORKING_PATH}" "${REPO_PATH}/patch_driver.sh"

#### Apply patches
cd "${KERNEL_PATH}" || exit

echo >&2 "===]> Info: Applying patches... "
[ ! -d "${WORKING_PATH}/patches" ] && {
  echo 'Patches directory not found!'
  exit 1
}


while IFS= read -r file; do
  echo "==> Adding $file"
  patch -p1 <"$file"
done < <(find "${WORKING_PATH}/patches" -type f -name "*.patch" | sort)

chmod a+x "${KERNEL_PATH}"/debian/rules
chmod a+x "${KERNEL_PATH}"/debian/scripts/*
chmod a+x "${KERNEL_PATH}"/debian/scripts/misc/*

echo >&2 "===]> Info: Bulding src... "

cd "${KERNEL_PATH}"

for i in amd64 arm64 armhf ppc64el riscv64 s390x
do

./debian/scripts/misc/annotations -c CONFIG_HID_APPLETB_BL --arch $i --flavour generic --write m
./debian/scripts/misc/annotations -c CONFIG_HID_APPLETB_KBD --arch $i --flavour generic --write m
./debian/scripts/misc/annotations -c CONFIG_DRM_APPLETBDRM --arch $i --flavour generic --write m
./debian/scripts/misc/annotations -c CONFIG_BT_HCIBCM4377 --arch $i --flavour generic --write m
./debian/scripts/misc/annotations -c CONFIG_APPLE_BCE --arch $i --flavour generic --write m
./debian/scripts/misc/annotations -c CONFIG_APFS_FS --arch $i --flavour generic --write m
./debian/scripts/misc/annotations -c CONFIG_MODULE_FORCE_UNLOAD --arch $i --flavour generic --write y
./debian/scripts/misc/annotations -c CONFIG_HID_APPLE_MAGIC_BACKLIGHT --arch $i --flavour generic --write m

done

# Build Deb packages
sed -i "s/${KERNEL_REL}-${UBUNTU_REL}/${KERNEL_REL}-${UBUNTU_REL}+t2/g" debian.master/changelog
fakeroot debian/rules clean updateconfigs
fakeroot debian/rules binary-headers binary-generic binary-perarch

#### Copy artifacts to shared volume
echo >&2 "===]> Info: Copying debs and calculating SHA256 ... "
#cp -rfv ../*.deb "${REPO_PATH}/"
#cp -rfv "${KERNEL_PATH}/.config" "${REPO_PATH}/kernel_config_${KERNEL_VERSION}"
cp -rfv "${KERNEL_PATH}/debian/build/build-generic/.config" "/tmp/artifacts/kernel_config_${KERNEL_VERSION}"
cp -rfv ../*.deb /tmp/artifacts/
sha256sum ../*.deb >/tmp/artifacts/sha256
