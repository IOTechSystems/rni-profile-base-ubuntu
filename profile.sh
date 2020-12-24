#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions

# --- Add Packages
ubuntu_bundles="openssh-server"
ubuntu_packages="wget"

# --- List out any docker tar images you want pre-installed separated by spaces.  We be pulled by wget. ---
wget_sysdockerimagelist=""

# --- Get kernel parameters ---
kernel_params=$(cat /proc/cmdline)

if [[ $kernel_params == *"token="* ]]; then
    tmp="${kernel_params##*token=}"
    export param_token="${tmp%% *}"
fi

# --- Install Extra Packages ---
run "Installing Extra Packages on Ubuntu ${param_ubuntuversion}" \
    "docker run -i --rm --privileged --name ubuntu-installer ${DOCKER_PROXY_ENV} -v /dev:/dev -v /sys/:/sys/ -v $ROOTFS:/target/root ubuntu:${param_ubuntuversion} sh -c \
    'mount --bind dev /target/root/dev && \
    mount -t proc proc /target/root/proc && \
    mount -t sysfs sysfs /target/root/sys && \
    LANG=C.UTF-8 chroot /target/root sh -c \
        \"$(echo ${INLINE_PROXY} | sed "s#'#\\\\\"#g") export TERM=xterm-color && \
        export DEBIAN_FRONTEND=noninteractive && \
        apt install -y tasksel && \
        mkdir -p $ROOTFS/test-dir && \
        cd $ROOTFS/test-dir && \
        wget --header "Authorization: token ${param_token}" https://github.com/IOTechSystems/edgebuilder-node-components/tarball/master) && \
        tar -xf master
        mv IOTech* edgebuilder-node-components && \
        cd edgebuilder-node-components && \
        docker-compose up -d && \
        tasksel install ${ubuntu_bundles} && \
        apt install -y ${ubuntu_packages}\"'" \
    ${PROVISION_LOG}

