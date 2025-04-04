#!/bin/bash

set -eu -o pipefail

BUILD_PATH=/tmp/build-kernel

### Apple T2 drivers commit hashes
# Patches
APPLE_SMC_DRIVER_GIT_URL=https://github.com/t2linux/linux-t2-patches.git
APPLE_SMC_DRIVER_BRANCH_NAME=main
APPLE_SMC_DRIVER_COMMIT_HASH=ce8bf6a23fff560b72606da67c63104d3dd03ccb
##BCE
#APPLE_BCE_DRIVER_GIT_URL=https://github.com/aunali1/mbp2018-bridge-drv.git
#APPLE_BCE_DRIVER_BRANCH_NAME=aur
#APPLE_BCE_DRIVER_COMMIT_HASH=c884d9ca731f2118a58c28bb78202a0007935998
## SPI
#APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
#APPLE_IB_DRIVER_BRANCH_NAME=mbp15
#APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871

rm -rf "${BUILD_PATH}"
mkdir -p "${BUILD_PATH}"
cd "${BUILD_PATH}" || exit

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} ${APPLE_SMC_DRIVER_GIT_URL} \
  "${BUILD_PATH}/linux-mbp-arch"
cd "${BUILD_PATH}/linux-mbp-arch" || exit
git checkout ${APPLE_SMC_DRIVER_COMMIT_HASH}
rm 2008*
wget https://raw.githubusercontent.com/t2linux/linux-t2-patches/refs/heads/main/2008-i915-4-lane-quirk-for-mbp15-1.patch

while IFS= read -r file; do
  echo "==> Adding ${file}"
  cp -rfv "${file}" "${WORKING_PATH}"/patches/"${file##*/}"
done < <(find "${BUILD_PATH}/linux-mbp-arch" -type f -name "*.patch" | grep -vE '000[0-9]')

#### Add custom drivers to kernel
#echo -e "From: \"Kernel Builder (sita)\" <ubuntu-kernel-bot@canonical.com>\nSubject: patch custom drivers\n" >"${WORKING_PATH}/patches/custom-drivers.patch"
#
#git clone --depth 1 --single-branch --branch v"${KERNEL_VERSION}" \
#  git://kernel.ubuntu.com/virgin/linux-stable.git "${BUILD_PATH}/linux-stable"
#cd "${BUILD_PATH}/linux-stable/drivers" || exit
#
#### apple-bce
#git clone --depth 1 --single-branch --branch "${APPLE_BCE_DRIVER_BRANCH_NAME}" \
#  "${APPLE_BCE_DRIVER_GIT_URL}" "${BUILD_PATH}/linux-stable/drivers/apple-bce"
#cd "${BUILD_PATH}/linux-stable/drivers/apple-bce" || exit
#git checkout "${APPLE_BCE_DRIVER_COMMIT_HASH}" && rm -rf .git
#
#cd "${BUILD_PATH}/linux-stable/drivers"
#cp -rfv "${WORKING_PATH}/templates/Kconfig" "${BUILD_PATH}/linux-stable/drivers/apple-bce/Kconfig"
#sed -i "s/TEST_DRIVER/APPLE_BCE_DRIVER/g" "${BUILD_PATH}/linux-stable/drivers/apple-bce/Kconfig"
## shellcheck disable=SC2016
#sed -i 's/obj-m/obj-$(CONFIG_APPLE_BCE)/g' "${BUILD_PATH}/linux-stable/drivers/apple-bce/Makefile"
## shellcheck disable=SC2016
#echo 'obj-$(CONFIG_APPLE_BCE)           += apple-bce/' >>"${BUILD_PATH}/linux-stable/drivers/Makefile"
#sed -i "\$i source \"drivers/apple-bce/Kconfig\"\n" "${BUILD_PATH}/linux-stable/drivers/Kconfig"
#
#### apple-ib
#git clone --single-branch --branch "${APPLE_IB_DRIVER_BRANCH_NAME}" \
#  "${APPLE_IB_DRIVER_GIT_URL}" "${BUILD_PATH}/linux-stable/drivers/apple-touchbar"
#cd "${BUILD_PATH}/linux-stable/drivers/apple-touchbar" || exit
#git checkout "${APPLE_IB_DRIVER_COMMIT_HASH}" && rm -rf .git
#
#cd "${BUILD_PATH}/linux-stable/drivers"
#cp -rfv "${WORKING_PATH}/templates/Kconfig" "${BUILD_PATH}/linux-stable/drivers/apple-touchbar/Kconfig"
#sed -i "s/TEST_DRIVER/APPLE_TOUCHBAR_DRIVER/g" "${BUILD_PATH}/linux-stable/drivers/apple-touchbar/Kconfig"
## shellcheck disable=SC2016
#sed -i 's/obj-m/obj-$(CONFIG_APPLE_TOUCHBAR)/g' "${BUILD_PATH}/linux-stable/drivers/apple-touchbar/Makefile"
## shellcheck disable=SC2016
#echo 'obj-$(CONFIG_APPLE_TOUCHBAR)      += apple-touchbar/' >>"${BUILD_PATH}/linux-stable/drivers/Makefile"
#sed -i "\$i source \"drivers/apple-touchbar/Kconfig\"\n" "${BUILD_PATH}/linux-stable/drivers/Kconfig"
#
### Prepare patch
#git add .
#git diff HEAD >> "${WORKING_PATH}/patches/custom-drivers.patch"
