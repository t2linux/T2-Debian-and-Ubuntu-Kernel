#!/bin/bash

set -eu -o pipefail

BUILD_PATH=/tmp/build-kernel

# Patches
T2_PATCHES_GIT_URL=https://github.com/t2linux/linux-t2-patches.git
T2_PATCHES_BRANCH_NAME=main
T2_PATCHES_COMMIT_HASH=HEAD

rm -rf "${BUILD_PATH}"
mkdir -p "${BUILD_PATH}"
cd "${BUILD_PATH}" || exit

### AppleSMC and BT aunali fixes
git clone --single-branch --branch ${T2_PATCHES_BRANCH_NAME} ${T2_PATCHES_GIT_URL} \
  "${BUILD_PATH}/linux-mbp-arch"
git clone https://github.com/kaiT2en/KaiT2en-Fedora/
cd "${BUILD_PATH}/linux-mbp-arch" || exit
git checkout ${T2_PATCHES_COMMIT_HASH}
rm 9002*
cp ../KaiT2en-Fedora/patches/runtime/wireless/*.patch ./
rm -rf ../KaiT2en-Fedora

while IFS= read -r file; do
  echo "==> Adding ${file}"
  cp -rfv "${file}" "${WORKING_PATH}"/patches/"${file##*/}"
done < <(find "${BUILD_PATH}/linux-mbp-arch" -type f -name "*.patch")
