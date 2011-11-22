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

CHROOT_DIR=$(readlink -e $1)

# Should fix up the bind mounts if they don't already exist
if ! mount | egrep ${CHROOT_DIR}/proc; then
  echo "not mounted, rebinding"
  rebindChroot.sh ${CHROOT_DIR}
fi

# so you can run X from w/in the chroot over ssh.
if [ -e ~/.Xauthority ] ; then
    cp -f ~/.Xauthority ${CHROOT_DIR}/home/`whoami`
fi

sudo chroot ${CHROOT_DIR} sudo su - `whoami`


