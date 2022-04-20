#!/bin/bash

source $(dirname $BASH_SOURCE)/.env

function preinstall(){
    INSTALLER=
    DistribuID=$(lsb_release -is)
    if [ "$DistribuID" == "CentOS" ]; then
        $S yum upgrade
        $S yum -y install epel-release && yum clean all && yum makecache
        $S yum -y install  glibc glibc-utils glibc-devel
        INSTALLER=yum
    elif [ "$DistribuID" == "Ubuntu" ]; then
        $S apt-get update
        $S apt-get -y install libncurses5-dev openssl libssl-dev build-essential pkg-config libc6-dev bison flex libelf-dev zlibc minizip libidn11-dev libidn11
        INSTALLER=apt-get
    else
        echo "系统未能识别，Distributor ID:$DistribuID"
        exit 1
    fi

    $S $INSTALLER -y install qemu gcc make wget kpartx
}