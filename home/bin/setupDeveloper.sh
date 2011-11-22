#!/bin/sh
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

RPM_SERVER=mt-fedora.nrcc.noklab.com
RPM_CROSS_REPO=repos/f14-cross/
VERSIONLOCK_FILE=/etc/yum/pluginconf.d/versionlock.list
FRELEASEVER=" --releasever 14"

# some of these are for documentation, some are because configure is hardcoded to /usr/include.
# sigh.
# needed for docs:
#   xmlto 
#   docbook2ps 
# needed to build wayland:
#   libffi-devel 
#   expat-devel

#   
# the rest are needed for cross env/rpmbuild

# note, tcl is *only* needed if you want to build tcl for arm
YUMLIST_NRCC="zypper \
cross-rpm-config \
redhat-rpm-config \
armv5tel-redhat-linux-gnueabi-binutils \
armv5tel-redhat-linux-gnueabi-cpp \
armv5tel-redhat-linux-gnueabi-gcc \
armv5tel-redhat-linux-gnueabi-gcc-c++ \
armv5tel-redhat-linux-gnueabi-libgcc \
armv5tel-redhat-linux-gnueabi-libgomp \
armv5tel-redhat-linux-gnueabi-libmudflap \
armv5tel-redhat-linux-gnueabi-libmudflap-devel \
armv5tel-redhat-linux-gnueabi-libstdc++ \
armv5tel-redhat-linux-gnueabi-libstdc++-devel \
armv7hl-redhat-linux-gnueabi-binutils \
armv7hl-redhat-linux-gnueabi-gcc \
xmlto \
docbook2ps \
rpmdevtools \
libffi-devel \
docbook-utils-pdf \
chrpath \
glib2-devel \
gtk-doc \
compat-flex \
linuxdoc-tools \
w3m \
docbook-style-xsl \
docbook-dtds \
tcl \
asciidoc \
sharutils \
fdupes \
expat-devel"


RPMLIST_NRCC="redhat-rpm-config-9.1.0-5.fc14.nrcc.2 \
rpm-build-4.8.1-5.fc14.nrcc.9 \
rpm-4.8.1-5.fc14.nrcc.9 \
rpm-apidocs-4.8.1-5.fc14.nrcc.9 \
rpm-python-4.8.1-5.fc14.nrcc.9 \
rpm-cron-4.8.1-5.fc14.nrcc.9 \
rpm-libs-4.8.1-5.fc14.nrcc.9 "


if [ ! -d "$1"/sysroot ]; then
    echo "need dir of mt-cross-tools"
    exit 1
fi

## add in the private repo certificate so zypper will play nice with it.
## this goes in the host machine certs, not the sysroots
curl http://mt-fedora/mt-fedora.nrcc.noklab.com.ssl.crt | sudo tee -a /etc/pki/tls/certs/ca-bundle.crt


SPHONE_DIR=$1

mkdir -p ~/bin
rsync -av $SPHONE_DIR/home/.rpm* ~/

cd ~/bin
for i in $SPHONE_DIR/home/bin/* ; do
    echo "linking $i to $(basename $i) in `pwd`"
    ln -sf $i $(basename $i)
done



#force in basic needed packages
echo "Installing Development Tools"
sudo yum ${FRELEASEVER} -y groupinstall "Development Tools"
rpm -q wget || (echo "Installing wget"; sudo yum -y install wget)

# yum-plugin-versionlock allows pinning for yum 
sudo yum -y install yum-plugin-versionlock

# the doofy plugin doesnt make an empty one nor does it work w/o one
sudo touch $VERSIONLOCK_FILE
sudo chmod 644 $VERSIONLOCK_FILE

echo "Installing /etc/yum.repos.d/f14-cross.repo"
# grab the nrcc repo 
if [ ! -e /etc/yum.repos.d/f14-cross.repo ]; then
    cd /tmp
    rm -f f14-cross.repo
    wget http://$RPM_SERVER/f14-cross.repo
    if [  -e /tmp/f14-cross.repo ]; then
	sudo mv f14-cross.repo /etc/yum.repos.d/f14-cross.repo
    else
	echo "Couldnt retrieve the nrcc repo file"
	echo "baggin out"
	exit 1
    fi
fi

for i in $YUMLIST_NRCC; do
    rpm -q $i || (echo YUMMING $i; sudo yum -y install $i)
done




echo "Installing and Pinning NRCC Versions"
# we are making a manifest file so dependencies are all resolved at once
RPM_MANIFEST=/tmp/`mktemp RPM_MANIFEST_XXXXX` 
for i in $RPMLIST_NRCC; do
    cd /tmp
    #check for our file in versionlock
    BASE_NAME=`echo $i | sed -e 's/-[0-9]/ /' | cut -f1 -d ' '`
    BASE_NAME_VERSIONED=`echo $i | sed -e 's/-[0-9]/& /' | cut -f1 -d ' '`
    if sudo yum versionlock list | egrep $BASE_NAME_VERSIONED ; then
	# remove it from the version lock. so we can grab the one we want.
	VENTRY=`sudo yum versionlock list | egrep $BASE_NAME_VERSIONED`
	sudo yum versionlock delete $VENTRY
    fi
    #   the doofy plugin *sometimes* reverts the permissions to 600 instead of 644
    sudo chmod 644 $VERSIONLOCK_FILE
    # using yumdownloader meand we get i686 or x86_64 whichever is correct
    yumdownloader --disablerepo=* --enablerepo=f14-cross $BASE_NAME
    echo "$i*rpm" >> $RPM_MANIFEST
    sudo yum versionlock  $i
done

# the doofy plugin *sometimes* reverts the permissions to 600 instead of 644
sudo chmod 644 $VERSIONLOCK_FILE
sudo rpm -Uv --force $RPM_MANIFEST  
rm -f $RPM_MANIFEST
rm -rf /tmp/*rpm

echo "Making ARM links"
cd ~/bin
for base_name in armv5tel-redhat armv7hl-redhat; do
    for newprefix in arm arm-none ; do
	for i in /usr/bin/${base_name}*; do
	    oldname=$(basename $i)
	    linkname=${newprefix}${oldname#${base_name}}
	    echo Redirecting to $i from ${linkname}
	    ln -sf $i ${linkname}
	done
    done
done
NUM_CPUS=`grep processor  /proc/cpuinfo  | tail -1  | cut -f2 -d ':'`

if [ "$NUM_CPUS" == "0" ]; then
echo "# %_smp_mflags -j${NUM_CPUS}" >> ~/.rpmmacros
else
echo "%_smp_mflags -j${NUM_CPUS}" >> ~/.rpmmacros
fi




