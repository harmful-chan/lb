#!/bin/bash


BUILD_MAKE_ARGS="-j2"
BUILD_MENU=true          # 打开菜单选项
#BUILD_KERNEL=true        # 编译内核
#BUILD_BUSYBOX=true       # 编译busybox
BUILD_GRUB=true          # 打包成grub启动盘

GRUB_CONVERT_VHD=true    # 启动盘转为 hyper-v 第一代支持盘（2008-2012）
GRUB_CONVERT_VHDX=true   # 启动盘转为 hyper-v 第二代支持盘（2016+）
GRUB_CONVERT_VMDK=true   # 启动盘转为 vmware 支持盘

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

    FREE_DERVE=$($S losetup -f)    # 可用设备，/dev/loop0之类的
    FREE_DERV_P1=${FREE_DERVE/loop/mapper\/loop}p1     # 磁盘的第一个分区，p1,p2..表示第1第2...个分区; /dev/mapper/loop0p1
    #losetup -o 1048576 $FREE_DERVE ${GRUB_IMG}.disk    # 挂载块设备跳过引导区前1M空间
    $S kpartx -av   ${GRUB_IMG}.disk $FREE_DERVE  # 挂在分区
    $S mkfs.ext4  $FREE_DERV_P1    

    rm -rf fsm
    mkdir fsm
    $S mount $FREE_DERV_P1 fsm/
    $S grub-install --root-directory=$(pwd)/fsm --no-floppy --target=i386-pc ${GRUB_IMG}.disk  || exit $?
    $S cp $KERNEL_IMG $FS_IMG_PKG fsm/boot/
    if [ -d fsm/boot/grub ]; then
        # 写启动项配置
        echo 'menuentry "my_linux" {' | $S tee fsm/boot/grub/grub.cfg
        echo "    linux (hd0,msdos1)/boot/$KERNEL_IMG root=/dev/ram rw init=/bin/ash" | $S tee -a fsm/boot/grub/grub.cfg
        echo "    initrd (hd0,msdos1)/boot/$FS_IMG_PKG" | $S tee -a fsm/boot/grub/grub.cfg
        echo "}" | $S tee -a fsm/boot/grub/grub.cfg
    fi
    $S umount fsm/
    $S kpartx -d $FREE_DERVE  
    $S losetup -d $FREE_DERVE  
    rm -rf fsm
fi

if [ "$GRUB_CONVERT_VHD" == "true" ]; then
    qemu-img convert -f raw -O vpc ${GRUB_IMG}.disk ${GRUB_IMG}.vhd 
fi
if [ "$GRUB_CONVERT_VHDX" == "true" ]; then
    qemu-img convert -f raw -O vhdx ${GRUB_IMG}.disk ${GRUB_IMG}.vhdx
fi
if [ "$GRUB_CONVERT_VMDK" == "true" ]; then
    qemu-img convert -f raw -O vmdk ${GRUB_IMG}.disk ${GRUB_IMG}.vmdk
fi
