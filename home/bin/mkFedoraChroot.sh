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

if [ "$1" == "" ]; then
    echo "Usage: $(basename $0) PATH-TO-CHROOT"
    exit 1
fi

CHROOT_DIR=$(readlink -m $1)

if [ -d ${CHROOT_DIR} ]; then
    echo "chroot dir exists, try again"
    exit 1
fi

FORCE_DEB=""
# debian/ubuntu want you to really tell it to use rpm
if  uname -a | egrep -i ubuntu  ; then
    echo setting up Ubuntu
    FORCE_DEB="--force-debian"
    sudo apt-get install yum rpm m2crypto psmisc
fi

function sadExit
{
    echo $1;
    exit -1;
}

sudo mkdir -p ${CHROOT_DIR}/var/lib/rpm
sudo rpm --root ${CHROOT_DIR} --initdb
rm -f fedora-rel*rpm
# ubuntu doesnt support yum-utils so it doesnt have 
# yumdownloader...
#yumdownloader  fedora-release | head -1 | awk '{print $1}'
wget http://mt-fedora.nrcc.noklab.com/repos/f14-mirror/all/fedora-release-14-1.noarch.rpm || sadExit "failed to wget fedora release 14"

echo "FD= $FORCE_DEB"
sudo rpm --root ${CHROOT_DIR} -ivh $FORCE_DEB fedora-rel*rpm

if [ "$FORCE_DEB" != "" ]; then
    sudo mkdir -p /etc/pki/rpm-gpg/
    sudo rsync -av ${CHROOT_DIR}/etc/pki/rpm-gpg/ /etc/pki/rpm-gpg/
fi

sudo yum -y --installroot=${CHROOT_DIR}  install bash || sadExit "yum install bash failed :("
sudo yum -y --installroot=${CHROOT_DIR} install util-linux-ng || sadExit "yum install util=linux-ng failed :("
sudo yum -y --installroot=${CHROOT_DIR} install rpm yum yum-utils git-core || sadExit "yum install git failed :("
sudo yum -y --installroot=${CHROOT_DIR} install sudo wget || sadExit "yum install wget :("

# set up the bind mounts
sudo mkdir -p ${CHROOT_DIR}/dev/pts
sudo mkdir -p ${CHROOT_DIR}/sys
sudo mkdir -p ${CHROOT_DIR}/tmp
sudo mount -o bind /proc/ ${CHROOT_DIR}/proc
sudo mount -o bind /dev/pts ${CHROOT_DIR}/dev/pts
sudo mount -o bind /dev ${CHROOT_DIR}/dev/
sudo mount -o bind /sys ${CHROOT_DIR}/sys/
sudo mount -o bind /tmp ${CHROOT_DIR}/tmp

# for dns
sudo cp /etc/resolv.conf ${CHROOT_DIR}/etc/
# so we can sudo
sudo cp /etc/sudoers ${CHROOT_DIR}/etc


# for convenience....
MUSER=`whoami`
MUID=`id -u ${USER}`
MGID=`id -g ${USER}`

sudo chroot ${CHROOT_DIR} groupadd -g $MGID $MUSER
sudo chroot ${CHROOT_DIR} useradd -u $MUID -g $MGID -G wheel $MUSER

sudo rsync -av ~/.ssh ${CHROOT_DIR}/home/${MUSER}
# so you can run X from w/in the chroot over ssh.
cp -f ~/.Xauthority ${CHROOT_DIR}/home/`whoami`

echo 'export PS1="\\[\\033[01;31m\\]chroot\\[\\033[0m\\]-\\[\\033[01;32m\\]\\u@\\h\\[\\033[0m\\]:\\[\\033[01;34m\\]\\w\\[\\033[0m\\]$ "' | sudo tee -a ${CHROOT_DIR}/home/${MUSER}/.bashrc


