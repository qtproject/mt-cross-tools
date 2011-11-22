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

ARCH=armv5tel

# since some of the naming conventions in rpms are a bit unpredictable, 
# this script will mv the rpmbuild-$ARCH/SOURCES/foo-version to 
# rpmbuild-$ARCH/SOURCES/DONE and the local src rpm to 
# ./DONE once we have processed it.

zypper-${ARCH} refresh

## first we grab the starting set of sysroot packages so we know what we want to start from
# this is ok, but kept growing over time
#BASE_SYSROOT_PACKAGES=`rpm-${ARCH} -qa `
BASE_SYSROOT_PACKAGES="libgcc-4.5.1-4.fc14.armv5tel \
tzdata-2010k-1.fc14.noarch \
basesystem-10.0-3.noarch \
nss-softokn-freebl-3.12.10-1.fc14.armv5tel \
bash-4.1.7-1.fc14.armv5tel \
coreutils-libs-8.5-7.fc14.armv5tel \
glibc-headers-2.13-2.1.armv5tel \
kernel-headers-2.6.35.6-45.fc14.armv5tel \
glibc-devel-2.13-2.1.armv5tel \
libstdc++-devel-4.5.1-4.fc14.armv5tel \
ncurses-base-5.7-8.20100703.fc14.armv5tel \
setup-2.8.23-1.fc14.noarch \
filesystem-2.4.35-1.fc14.armv5tel \
glibc-2.13-2.1.armv5tel \
ncurses-libs-5.7-8.20100703.fc14.armv5tel \
glibc-common-2.13-2.1.armv5tel \
coreutils-8.5-7.fc14.armv5tel \
zlib-1.2.5-2.fc14.armv5tel \
info-4.13a-10.fc14.armv5tel \
libstdc++-4.5.1-4.fc14.armv5tel"

# removes the offending rpm if its not in the base set
function cleanToBase(){
    RPM=$1
    for k in $BASE_SYSROOT_PACKAGES; do
	if [ $RPM = $k ]; then
	    return 0
	fi
    done
    echo "cleaning out $RPM"
    zypper-${ARCH} -n  remove  $RPM

}

function revertSysroot(){
    CURRENT_SYSROOT_PACKAGES=`rpm-${ARCH} -qa `
    for j in $CURRENT_SYSROOT_PACKAGES; do
	echo "checking $j"
	cleanToBase $j       
    done
#    for j in $BASE_SYSROOT_PACKAGES; do 
#	echo "readding $j"
#	#zypper-${ARCH}  -n install --no-recommends $j
#    done
}

revertSysroot    

