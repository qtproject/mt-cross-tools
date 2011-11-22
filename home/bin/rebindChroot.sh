#!/bin/bash
####
# Copyright (c) 2011 Nokia Corporation
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without
# limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
####

# reset up the bind mounts


if [ "$1" == "" ]; then
    echo "need abs path of chroot"
    exit 1
fi

CHROOT_DIR=$1

# set up the bind mounts
sudo mkdir -p ${CHROOT_DIR}/sys
sudo mount -o bind /proc/ ${CHROOT_DIR}/proc
sudo mount -o bind /dev/pts ${CHROOT_DIR}/dev/pts
sudo mount -o bind /dev ${CHROOT_DIR}/dev/
sudo mount -o bind /sys ${CHROOT_DIR}/sys/
sudo mount -o bind /tmp ${CHROOT_DIR}/tmp

# for dns
sudo cp /etc/resolv.conf ${CHROOT_DIR}/etc/
