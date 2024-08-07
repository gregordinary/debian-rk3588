#!/bin/sh

# Copyright (C) 2023, John Clark <inindev@gmail.com>

set -e

# script exit codes:
#   1: missing utility
#   5: invalid file hash
#   7: use screen session
#   8: superuser disallowed

config_fixups() {
    local lpath=$1

    #echo 6 > "$lpath/.version"
}

main() {
    local linux='https://git.kernel.org/torvalds/t/linux-6.11-rc2.tar.gz'
    local lxsha='93fb8e28003edfd42b47b87447a19c36013e7b1f6b8a74fc2c292d47198ffee9'

    local lf="$(basename "$linux")"
    local lv="$(echo "$lf" | sed -nE 's/linux-(.*)\.tar\..z/\1/p')"

    if [ '_clean' = "_$1" ]; then
        echo -e "\n${h1}cleaning...${rst}"
        rm -fv *.deb
        rm -rfv kernel-$lv/*.deb
        rm -rfv kernel-$lv/*.buildinfo
        rm -rfv kernel-$lv/*.changes
        rm -rf "kernel-$lv/linux-$lv"
        echo -e '\nclean complete\n'
        exit 0
    fi

    check_installed 'screen' 'build-essential' 'python3' 'flex' 'bison' 'pahole' 'debhelper'  'bc' 'rsync' 'libncurses-dev' 'libelf-dev' 'libssl-dev' 'lz4' 'zstd'

    if [ -z "$STY$TMUX" ]; then
        echo -e 'reminder: run from a screen or a tmux session, this can take a while...'
        exit 7
    fi

    mkdir -p "kernel-$lv"
    if ! [ -e "kernel-$lv/$lf" ]; then
        if [ -e "./$lf" ]; then
            echo -e "linking local copy of linux $lv"
            ln -sv "../$lf" "kernel-$lv/$lf"
        elif [ -e "../dtb/$lf" ]; then
            echo -e "using local copy of linux $lv"
            cp -v "../dtb/$lf" "kernel-$lv"
        else
            echo -e "downloading linux $lv"
            wget "$linux" -P "kernel-$lv"
        fi
    fi

    if [ "_$lxsha" != "_$(sha256sum "kernel-$lv/$lf" | cut -c1-64)" ]; then
        echo -e "invalid hash for linux source file: $lf"
        exit 5
    fi

    if [ ! -d "kernel-$lv/linux-$lv" ]; then
        tar -C "kernel-$lv" -xavf "kernel-$lv/$lf"

        for patch in patches/*.patch; do
            patch -p1 -d "kernel-$lv/linux-$lv" -i "../../$patch"
        done
    fi

    # build
    if [ '_inc' != "_$1" ]; then
        echo -e "\n${h1}configuring source tree...${rst}"
        make -C "kernel-$lv/linux-$lv" mrproper
        [ -z "$1" ] || echo "$1" > "kernel-$lv/linux-$lv/.version"
        config_fixups "kernel-$lv/linux-$lv"
        cp ./r6s_config "kernel-$lv/linux-$lv/.config"
        make -C "kernel-$lv/linux-$lv" ARCH=arm64 olddefconfig
    fi

    echo -e "\n${h1}beginning compile...${rst}"
    rm -f linux-*.deb
    local kv="$(make --no-print-directory -C "kernel-$lv/linux-$lv" kernelversion)"
    local bv="$(expr "$(cat "kernel-$lv/linux-$lv/.version" 2>/dev/null || echo 0)" + 1 2>/dev/null)"
    export SOURCE_DATE_EPOCH="$(stat -c %Y "kernel-$lv/linux-$lv/README")"
    export KDEB_CHANGELOG_DIST='stable'
    export KBUILD_BUILD_TIMESTAMP="Debian $kv-$bv $(date -d @$SOURCE_DATE_EPOCH +'(%Y-%m-%d)')"
    export KBUILD_BUILD_HOST='github.com/gregordinary'
    export KBUILD_BUILD_USER='linux-kernel'
    export KBUILD_BUILD_VERSION="$bv"

    local t1=$(date +%s)
    nice make -C "kernel-$lv/linux-$lv" -j"$(nproc)" CC="$(readlink /usr/bin/gcc)" bindeb-pkg KBUILD_IMAGE='arch/arm64/boot/Image' LOCALVERSION="-$bv-arm64"
    local t2=$(date +%s)
    echo -e "\n${cya}kernel package ready (elapsed: $(date -d@$((t2-t1)) '+%H:%M:%S'))${mag}"
    ln -sfv "kernel-$lv/linux-image-$kv-$bv-arm64_$kv-${bv}_arm64.deb"
    ln -sfv "kernel-$lv/linux-headers-$kv-$bv-arm64_$kv-${bv}_arm64.deb"
    echo -e "${rst}"
}

check_installed() {
    local todo
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
    done

    if [ ! -z "$todo" ]; then
        echo -e "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo -e "   run: ${bld}${grn}sudo apt update && sudo apt -y install$todo${rst}\n"
        exit 1
    fi
}

rst='\033[m'
bld='\033[1m'
red='\033[31m'
grn='\033[32m'
yel='\033[33m'
blu='\033[34m'
mag='\033[35m'
cya='\033[36m'
h1="${blu}==>${rst} ${bld}"

if [ 0 -eq $(id -u) ]; then
    echo -e 'do not compile as root'
    exit 8
fi

cd "$(dirname "$(realpath "$0")")"
main "$@"
