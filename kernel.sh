#!/bin/bash

source $(dirname $BASH_SOURCE)/.env

function config_kernel_init(){
    if [ ! -e linux-4.12.tar.gz ]; then 
        wget http://ftp.sjtu.edu.cn/sites/ftp.kernel.org/pub/linux/kernel/v4.x/linux-4.12.tar.gz
        rm -rf $KERNEL_DIR

    fi
    if [[ ! -d $KERNEL_DIR && -e linux-4.12.tar.gz ]]; then
        tar -xvf linux-4.12.tar.gz 
        mv -f linux-4.12 $KERNEL_DIR
        cd $KERNEL_DIR
        make x86_64_defconfig 
        cd - >/dev/null
    fi
}

function config_kernel_menu(){
    if [ -d $KERNEL_DIR ]; then 
        cd $KERNEL_DIR 
        make menuconfig 
        cd - >/dev/null
    fi
}

function make_kernel(){
    if [ -d $KERNEL_DIR ]; then 
        cd $KERNEL_DIR 
        make $@
        cd - >/dev/null
        cp $KERNEL_DIR/arch/x86/boot/bzImage $KERNEL_IMG
    fi
}