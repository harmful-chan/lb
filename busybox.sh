#!/bin/bash

source $(dirname $BASH_SOURCE)/.env

function config_busybox_init(){
    if [ ! -e busybox-1.30.0.tar.bz2 ]; then 
        wget https://busybox.net/downloads/busybox-1.30.0.tar.bz2
        rm -rf $BUSYBOX_DIR
    fi
    if [[ ! -d $BUSYBOX_DIR && -e busybox-1.30.0.tar.bz2 ]]; then
        tar -xvf busybox-1.30.0.tar.bz2
        mv -f busybox-1.30.0 $BUSYBOX_DIR
    fi
}

function config_busybox_menu(){

    if [ -d $BUSYBOX_DIR ]; then 
        cd $BUSYBOX_DIR 
        make menuconfig
         
        cd - >/dev/null
    fi
}

function make_busybox(){
    if [ -d $BUSYBOX_DIR ]; then 
        cd $BUSYBOX_DIR 
        make $@
        make install
        cd - >/dev/null
    fi
}

function build_base_fs(){
    if [ ! -d $BUSYBOX_DIR ]; then  
        return 1
    fi
    
    rm -rf bsfs
    mkdir bsfs 
    cp -rf $BUSYBOX_DIR/_install/* bsfs
    cd bsfs

    mkdir etc dev mnt
    mkdir -p proc sys tmp mnt
    mkdir -p etc/init.d/

    echo "config etc/fstab."
    cat >etc/fstab <<-EOF
proc        /proc           proc         defaults        0        0
tmpfs       /tmp            tmpfs    　　defaults        0        0
sysfs       /sys            sysfs        defaults        0        0
EOF

    echo "config etc/init.d/rcS."
    cat >etc/init.d/rcS <<-EOF
echo -e "Welcome to tinyLinux"
/bin/mount -a
echo -e "Remounting the root filesystem"
mount  -o  remount,rw  /
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
EOF
    chmod 755 etc/init.d/rcS

    echo "config etc/inittab."
    cat  >etc/inittab <<-EOF
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::ctrlaltdel:/bin/umount -a -r
EOF
    chmod 755 etc/inittab
    cd dev
    sudo mknod console c 5 1
    sudo mknod null c 1 3
    sudo mknod tty1 c 4 1 
    cd ../..
}

function package_base_fs(){
    if [ -d bsfs ]; then 
        rm -rf ${FS_IMG}.disk
        rm -rf fsm
        dd if=/dev/zero of=${FS_IMG}.disk bs=1M count=32
        mkfs.ext3 ${FS_IMG}.disk
        mkdir fsm
        sudo mount -o loop ${FS_IMG}.disk ./fsm
        sudo cp -rf ./bsfs/* fsm
        sudo umount ./fsm
        gzip --best -c ${FS_IMG}.disk > ${FS_IMG_PKG}
        rm -rf fsm
    fi
}
