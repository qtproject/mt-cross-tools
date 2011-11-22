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

if [ ! -d "$1"/sysroot ]; then
    echo "need dir of mt-cross-tools"
    exit 1
fi

MT_CROSS_TOOLS=$1

TOOLCHAIN_ROOT=/usr/armv7hl-redhat-linux-gnueabi
SYSROOT=${TOOLCHAIN_ROOT}/sys-root
ARCH=armv7hl
EXTRA_ARCHES=""

echo "#### Setting up XXX-${ARCH} commands for the sys-root"
mkdir -p $HOME/bin
cd $HOME/bin
for t_arch in $ARCH $EXTRA_ARCHES; do
    for cmdhead in rpm-noarch rpmbuild-noarch zypper-noarch zypper-download zypper-build-dep ; do
	CMD=$(which ${cmdhead})
	if [ ! -e "$CMD" ] ; then
	    echo "Unable to find ${CMD}.  Did you run setupDeveloper.sh and put ~/bin in your path?"
	    exit 1
	fi
	ln -s ${CMD} ${cmdhead%-noarch}-${t_arch}
    done
done

echo "#### Setting up sysroot $SYSROOT"
sudo mkdir -p $SYSROOT
sudo rsync -av $MT_CROSS_TOOLS/sysroot/$ARCH/* $SYSROOT/
# make a pkgconfig dir, which we will eventually need.
# and put a dummy file in
sudo mkdir -p ${SYSROOT}/usr/lib/pkgconfig
echo $SYSROOT >> /tmp/faux-nrcc.pc
sudo mv /tmp/faux-nrcc.pc ${SYSROOT}/usr/lib/pkgconfig/faux-nrcc.pc

# add the certificate for the private repo on mt-fedora
curl http://mt-fedora.nrcc.noklab.com/mt-fedora.nrcc.noklab.com.ssl.crt | sudo tee -a  /etc/pki/tls/certs/ca-bundle.crt


# install a base filesystem
zypper-noarch ${ARCH} refresh
zypper-noarch ${ARCH} lr


sudo mkdir -p ${SYSROOT}/${HOME}
group=$GROUPS
sudo chown $USER.$GROUP $SYSROOT/$HOME
for t_arch in $ARCH $EXTRA_ARCHES; do
    echo "#### Linking $HOME/rpmbuild$-{t_arch} to the sysroot"
# link your rpmbuild to the one the sysroot sees.
    mkdir -p $HOME/rpmbuild-${t_arch}
    cd $SYSROOT/$HOME
    ln -s $HOME/rpmbuild-${t_arch} rpmbuild-${t_arch}
    sudo ln -s $HOME/rpmbuild-${t_arch} $SYSROOT/root/rpmbuild-${t_arch}

done


#link the rpm db so it is consistent in and out of the sysroot
# i know this is weird.

sudo mkdir -p $SYSROOT/$SYSROOT/var/lib
cd $SYSROOT/$SYSROOT/var/lib
sudo ln -s $SYSROOT/var/lib/rpm rpm

# even wierder, we need the link for all the extra arches.
# this is partly from bad planning early on.  the arch in the toolchain
# name is misleading since the arm 4.5.1 cross is happy to compile for
# armv3,4,5,6,7
for t_arch in  $EXTRA_ARCHES; do
    extra_toochainroot_dir=`echo $TOOLCHAIN_ROOT | sed -e "s/${ARCH}/${t_arch}/g"`
    sudo ln -s $TOOLCHAIN_ROOT $extra_toochainroot_dir
    extra_rpmtop_dir=`echo $SYSROOT/var/lib | sed -e "s/${ARCH}/${t_arch}/g"`
    extra_rpm_dir=`echo $SYSROOT/$SYSROOT/var/lib | sed -e "s/${ARCH}/${t_arch}/g"`

    sudo mkdir -p $extra_rpm_dir 
    cd $extra_rpm_dir 
    sudo ln -s $extra_rpmtop_dir/rpm rpm
done



echo "#### Installing glibc into $SYSROOT"
# install the glibc we need as well as coreutils and bash
#libstdc++-devel
zypper-noarch ${ARCH} -n install -n setup glibc glibc-common glibc-devel glibc-headers  kernel-headers 

