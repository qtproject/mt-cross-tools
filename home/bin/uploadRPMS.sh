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

REPO_SERVER=mt-fedora.nrcc.noklab.com
REPO_PATH=/srv/www/repos/f14-


USAGE="Usage: $0 [shared|sysroot|platform|private] rpm1 rpm2 rpm3 rpmN"

if [ "$#" == "0" ]; then
	echo "$USAGE"
	exit 1
fi



DEST=$1
shift

if [ "$DEST" != "shared" -a "$DEST" != "platform"  -a "$DEST" != "sysroot" -a "$DEST" != "private" ]; then
	echo "$USAGE"
	exit 1
fi
REPO_PATH="${REPO_PATH}${DEST}/incoming/"

# copy over the rpms
while (( "$#" )); do
    echo "working on $1"
    if [ ! -e "$1" ]; then
	echo "can't find file $1 to upload"
	exit
    fi;
    rsync -av $1 $REPO_SERVER:$REPO_PATH
    shift
done


# and make them available
#ssh $REPO_SERVER "sudo /root/bin/make.repos.incoming"  >>/dev/null &
# better to know when it is done...
ssh $REPO_SERVER "sudo /root/bin/make.repos.incoming" 