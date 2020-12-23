#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions

# --- Add Packages
ubuntu_bundles="openssh-server"
ubuntu_packages="wget"

# --- List out any docker images you want pre-installed separated by spaces. ---
pull_sysdockerimagelist="http://${PROVISIONER}${param_httppath}/files/docker-minion.tar"

# --- List out any docker tar images you want pre-installed separated by spaces.  We be pulled by wget. ---
wget_sysdockerimagelist=""

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
        tasksel install ${ubuntu_bundles} && \
        apt install -y ${ubuntu_packages}\"'" \
    ${PROVISION_LOG}

# --- Get kernel parameters ---
kernel_params=$(cat /proc/cmdline)

if [[ $kernel_params == *"token="* ]]; then
    tmp="${kernel_params##*token=}"
    export param_token="${tmp%% *}"
fi

if [[ $kernel_params == *"bootstrap="* ]]; then
    tmp="${kernel_params##*bootstrap=}"
    export param_bootstrap="${tmp%% *}"
    export param_bootstrapurl=$(echo $param_bootstrap | sed "s#/$(basename $param_bootstrap)\$##g")
fi

wget --header "Authorization: token ${param_token}" -O - ${param_bootstrapurl}/profile.sh
