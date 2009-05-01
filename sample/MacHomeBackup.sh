#!/bin/sh
#
# Copyright (c) 2007, Gerhard Poul All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer. Redistributions in binary
# form must reproduce the above copyright notice, this list of conditions and
# the following disclaimer in the documentation and/or other materials
# provided with the distribution. Neither the name of the ORGANIZATION nor
# the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

# NOTES:
#   Incremental backups can be created with: --listed-incremental=file

# Define s3util command location and parameters
S3UTILCMD="/Users/gpoul/Projects/objc-s3/build/Release/s3util --accessKeyID ADD_KEYID_HERE --bucket ADD_BUCKET_HERE"

cd ~

# Create target directory

BACKUPNAME=backup-`date +%Y%m%d`
TARGETDIR=~/Desktop/$BACKUPNAME

if [ -e "$TARGETDIR.dmg" ];
then
	echo "There is already a backup on your Desktop, not creating new backup."
	exit 0
fi

rm -rf $TARGETDIR
mkdir $TARGETDIR

# Backup AdiumX

tar czf $TARGETDIR/AdiumX.tar.gz Library/Application\ Support/Adium\ 2.0 \
	Library/Preferences/com.adiumX.adiumX.plist

# Backup NetNewsWire

tar czf $TARGETDIR/NetNewsWire.tar.gz Library/Application\ Support/NetNewsWire/Subscriptions.plist \
	Library/Preferences/com.ranchero.NetNewsWire.plist

# Backup iTunes

tar czf $TARGETDIR/iTunes.tar.gz Music/iTunes/iTunes\ Library \
	Music/iTunes/iTunes\ Music\ Library.xml

# Backup iPhoto

tar czf $TARGETDIR/iPhoto.tar.gz Pictures/iPhoto\ Library/Library6.iPhoto

# Backup Data Files in Home

tar czf $TARGETDIR/HomeData.tar.gz Documents .profile .ssh .mbackup

# Backup Keychain

tar czf $TARGETDIR/Keychains.tar.gz Library/Keychains/login.keychain

# Backup Stickies

killall Stickies
tar czf $TARGETDIR/Stickies.tar.gz Library/StickiesDatabase
open /Applications/Stickies.app

# Move data in encrypted volume on the Desktop

hdiutil create -srcfolder $TARGETDIR -fs HFS+ -encryption -volname "$BACKUPNAME" $TARGETDIR

rm -rf $TARGETDIR

# Upload stuff to S3 and if it worked, remove it locally
cd Desktop
$S3UTILCMD --persistMD5 /Users/gpoul/.mbackup/backupsums --upload $BACKUPNAME.dmg

if [ $? == 0 ]
then
	rm $TARGETDIR.dmg
else
	echo Something went wrong while uploading. Please try again manually.
fi

cd ~
