#! /bin/sh

## Backup Script
## Refs: 
## http://www.circuidipity.com/backup-home.html
## http://www.ibm.com/developerworks/aix/library/au-spunix_rsync/index.html

HOST=b.lan
SOURCE=$HOME
EXCLUSIONS="--exclude=*Virtual* --exclude=*Backups* --exclude=*[Cc]ache* --exclude=*[Tt]rash*"
PATHTOBACKUP="backup-calderwood"
DATE=`date "+%Y-%m-%dT%H:%M:%S"`
RSYNC_OPTIONS="-az --link-dest=../current"

rsync $RSYNC_OPTIONS $EXCLUSIONS $SOURCE $HOST:$PATHTOBACKUP/back-$DATE

ssh $HOST "rm -f $PATHTOBACKUP/current && ln -s back-$DATE $PATHTOBACKUP/current"
