#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions

# --- Add Packages
ubuntu_bundles="openssh-server"
ubuntu_packages="wget dpkg"

# --- Controller authentication
controller_address="192.168.0.40"
controller_username="iotech"
controller_password="EdgeBuilder123"

# --- Node details
node_name="Node4"
node_description="This is ${node_name}"

# --- List out any docker tar images you want pre-installed separated by spaces.  We be pulled by wget. ---
wget_sysdockerimagelist=""

# --- Install Utility OS Packages ---
run "Install Utility OS packages" \
    "apk add jq curl tar" \
    "$TMP/provisioning.log"

# --- Get JWT Token ---
run "Get JWT Token" \
    "mkdir -p $ROOTFS/controller && \
    curl -sk -X POST \"http://${controller_address}:8080/api/auth\" -H \"accept: application/json\" -H \"Content-Type: application/json\" -d '{\"Username\": \"${controller_username}\", \"Password\": \"${controller_password}\"}' | jq -r '.jwt' > $ROOTFS/controller/jwt.txt" \
    "$TMP/provisioning.log"

# -- Get Minion Keys ---
run "Get minion keys" \
    "curl -sk -X POST \"http://${controller_address}:8080/api/nodes\" -H \"Accept: application/json\" -H \"Authorization: $(cat $ROOTFS/controller/jwt.txt)\" -d '[{\"Name\": \"${node_name}\", \"Description\": \"${node_description}\"}]' > $ROOTFS/controller/keys.json && \
    mkdir -p $ROOTFS/controller/keys && \
    jq -r .Results[].MinionPrivateKey $ROOTFS/controller/keys.json > $ROOTFS/controller/keys/minion.pem && \
    jq -r .Results[].MinionPublicKey $ROOTFS/controller/keys.json > $ROOTFS/controller/keys/minion.pub && \
    tar -czvf $ROOTFS/controller/keys.tar $ROOTFS/controller/keys" \
    "$TMP/provisioning.log"

# --- Create systemd file ---
run "Create systemd file" \
    "echo -e \"[Unit]\nAfter=docker.service\n\n[Service]\nType=oneshot\nExecStart=/usr/local/bin/node-components-up.sh\n\n[Install]\nWantedBy=default.target\" >> $ROOTFS/etc/systemd/system/node-components-up.service && \
    chmod 664 $ROOTFS/etc/systemd/system/node-components-up.service" \
    "$TMP/provisioning.log"

# --- Create node components up file ---
run "Create node components up script" \
    "echo -e \"#!/bin/bash\n\ncd /controller\nedgebuilder-node up -s ${controller_address} -k /controller/keys.tar -n ${node_name}\" >> $ROOTFS/usr/local/bin/node-components-up.sh && \
    chmod 744 $ROOTFS/usr/local/bin/node-components-up.sh" \
    "$TMP/provisioning.log"

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
        mkdir /node-components && \
        cd /node-components && \
        wget https://iotech.jfrog.io/artifactory/public/edgebuilder-node-1.0.0_amd64.deb && \
        dpkg -i edgebuilder-node-1.0.0_amd64.deb && \
        systemctl daemon-reload && \
        systemctl enable node-components-up.service && \
        apt install -y tasksel\"'" \
    ${PROVISION_LOG}




