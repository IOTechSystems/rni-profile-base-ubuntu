#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions

# --- Add Packages
ubuntu_bundles="openssh-server"
ubuntu_packages="wget dpkg zip"
controller_address="192.168.0.40"
username_arg="Username"
password_arg="Password"
controller_username="iotech"
controller_password="EdgeBuilder123"

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
        tasksel install ${ubuntu_bundles} && \
        apt install -y ${ubuntu_packages} && \
        mkdir $ROOTFS/node-components
        cd $ROOTFS/node-components && \
        wget https://iotech.jfrog.io/artifactory/public/edgebuilder-node-1.0.0_amd64.deb && \
        dpkg -i edgebuilder-node-1.0.0_amd64.deb && \
        apt install -y tasksel\"'" \
    ${PROVISION_LOG}

# --- Get JWT Token ---
run "Get JWT Token" \
    "cd $ROOTFS/node-components && \
    curl -ski -X POST \"http://192.168.0.40:8080/api/auth\" -H \"accept: application/json\" -H \"Content-Type: application/json\" -d '{\"Username\": \"iotech\", \"Password\": \"EdgeBuilder123\"}' | jq -r '.jwt' > jwt.txt" \
    "$TMP/provisioning.log"
