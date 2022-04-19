#!/bin/bash


BUILD_KERNEL=
BUILD_BUSYBOX=
BUILD_MENU=
BUILD_MAKE_ARGS=
BUILD_GRUB=
if [[ $# -eq 0 ]]; then
    # --menu --kernel --busybox --grub --make-args "-j2"
    BUILD_KERNEL=true
    BUILD_BUSYBOX=true
    BUILD_MENU=true
    BUILD_GRUB=true
    BUILD_MAKE_ARGS="-j2"
else 

    while [[ $# -gt 0 ]]
    do
        case $key in
            --menu)
                BUILD_MENU=true
            ;;
            --grub)
                BUILD_GRUB=true
            ;;
            --kernel)
                BUILD_KERNEL=true
            ;;
            --busybox)
                BUILD_BUSYBOX=true
            ;; 
            --make-args)
                shift
                BUILD_MAKE_ARGS=$key
            ;;    
            *)
            ;;      
        esac
        shift
    done
fi


set -e

DIR=$(dirname $BASH_SOURCE)
source $DIR/preinstall.sh
source $DIR/kernel.sh
source $DIR/busybox.sh

# 安装工具
preinstall || exit $?

# 编译linux
if [ "$BUILD_KERNEL" == "true" ]; then
    config_kernel_init
    if [ "$BUILD_MENU" == "true" ]; then
        config_kernel_menu
    fi
    make_kernel $BUILD_MAKE_ARGS
fi


# 编译busybox
if [ "$BUILD_BUSYBOX" == "true" ]; then
    config_busybox_init
    if [ "$BUILD_MENU" == "true" ]; then
        config_busybox_menu
    fi
    make_busybox $BUILD_MAKE_ARGS
    build_base_fs
    package_base_fs
fi

# 编译打包镜像
if [ "$BUILD_GRUB" == "true" ]; then
    rm -rf ${GRUB_IMG}.disk
    dd if=/dev/zero of=${GRUB_IMG}.disk bs=1M count=128
    echo "n
p



w" | fdisk ${GRUB_IMG}.disk

    FREE_DERVE=$(losetup -f)    # 可用设备，/dev/loop0之类的
    FREE_DERV_P1=${FREE_DERVE/loop/mapper\/loop}p1     # 磁盘的第一个分区，p1,p2..表示第1第2...个分区; /dev/mapper/loop0p1
    #losetup -o 1048576 $FREE_DERVE ${GRUB_IMG}.disk    # 挂载块设备跳过引导区前1M空间
    kpartx -av   ${GRUB_IMG}.disk $FREE_DERVE  # 挂在分区
    mkfs.ext4  $FREE_DERV_P1    

    rm -rf fsm
    mkdir fsm
    mount $FREE_DERV_P1 fsm/
    grub-install --root-directory=$(pwd)/fsm --no-floppy --target=i386-pc ${GRUB_IMG}.disk  || exit $?
    cp $KERNEL_IMG $FS_IMG_PKG fsm/boot/
    if [ -d fsm/boot/grub ]; then
        # 写启动项配置
        echo 'menuentry "my_linux" {' >fsm/boot/grub/grub.cfg
        echo "    linux (hd0,msdos1)/boot/$KERNEL_IMG root=/dev/ram rw init=/bin/ash"  >>fsm/boot/grub/grub.cfg
        echo "    initrd (hd0,msdos1)/boot/$FS_IMG_PKG" >>fsm/boot/grub/grub.cfg
        echo "}" >>fsm/boot/grub/grub.cfg
    fi
    umount fsm/
    kpartx -d $FREE_DERVE  
    losetup -d $FREE_DERVE  
    rm -rf fsm
fi