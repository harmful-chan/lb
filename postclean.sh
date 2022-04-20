#!/bin/bash

source $(dirname $BASH_SOURCE)/.env

function postclean(){
    unset S
    unset BUSYBOX_DIR
    unset KERNEL_DIR
    unset GRUB_IMG
    unset FS_IMG
    unset FS_IMG_PKG
    unset KERNEL_IMG

    unset BUILD_MAKE_ARGS
    unset BUILD_MENU
    unset BUILD_KERNEL
    unset BUILD_BUSYBOX
    unset BUILD_GRUB

    unset GRUB_CONVERT_VHD
    unset GRUB_CONVERT_VHDX
    unset GRUB_CONVERT_VMDK
}


