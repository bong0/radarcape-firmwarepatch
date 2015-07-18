#!/bin/bash
# turn on debug mode
set -x
# set -e

DRIVE=$1

uid=$(id -u)
if [ $uid -ne 0 ]; then
  echo "please run this script as root."
  exit 1
fi

tmpmount_1=$(mktemp -d)
tmpmount_2=$(mktemp -d)

function cleanup(){
	echo "Cleaning up $BUILD" 
	#rm -rf $BUILD
	umount $tmpmount_1 $tmpmount_2 || true
	rmdir $tmpmount_1 $tmpmount_2
}
function error(){
	local parent_lineno="$1"
	local message="$2"
	local code="${3:-1}"
	if [[ -n "$message" ]] ; then
		echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
	else
		echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
	fi
	cleanup
	exit "${code}"
}
trap 'error ${LINENO}' ERR

trap cleanup SIGINT SIGTERM # register trap for unusual quits



if [ ! -b "/dev/$DRIVE" ] ; then
	echo Couldn\'t find \'${DRIVE}\'. You must specify a valid block device.
	exit
fi

if [ "$DRIVE" = "sda" ] ; then
	echo You probably don\'t want to use /dev/sda...
	exit
fi

if echo ${DRIVE} | grep "mmcblk" ; then
	DRIVE_P="${DRIVE}p"
elif echo ${DRIVE} | grep "sd" ; then
	DRIVE_P="${DRIVE}"
else
	echo Invalid destination, must be either an mmcblkX or sdX device.
	exit
fi

echo "Please enter your desired hostname. Mostly this is present on a sticker on your Radarcape."
echo "For example, rc11"
read MY_HOSTNAME

rm -rf format_sd.sh
wget http://www.modesbeast.com/resources/format_sd.sh
sync
if [ ! -f format_sd.sh ]; then
        echo "Cannot find format_sd.sh"
        exit 1
fi

sudo bash ./format_sd.sh /dev/$DRIVE


sudo umount /dev/${DRIVE_P}1 || true # fake exit status because we only try
sudo umount /dev/${DRIVE_P}2 || true

sudo mount /dev/${DRIVE_P}1 $tmpmount_1
sudo mount /dev/${DRIVE_P}2 $tmpmount_2

sudo cp -v MLO-beaglebone-2013.04-2013.05.20 $tmpmount_1/MLO

sudo cp -v u-boot-beaglebone-2013.04-dirty.img $tmpmount_1/u-boot.img

# image on local system sudo tar xf Angstrom-systemd-image-eglibc-ipk-v2012.12-beaglebone.rootfs.tar.xz -C /media/${DRIVE_P}2

rm -f /tmp/rootfs.tar.xz
wget http://dominion.thruhere.net/angstrom/nightlies/v2015.12/beaglebone/Angstrom-systemd-image-glibc-ipk-v2015.07-beaglebone.rootfs.tar.gz \
-O /tmp/rootfs.tar.xz
xz -d /tmp/rootfs.tar.xz
tar xf /tmp/rootfs.tar -C $tmpmount_2/


echo "The new SD card will be accessible via network with the hostname ${MY_HOSTNAME}"
echo $MY_HOSTNAME > $tmpmount_2/etc/hostname

sudo umount /dev/${DRIVE_P}1
sudo umount /dev/${DRIVE_P}2
