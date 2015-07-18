#!/bin/bash
# turn on debug mode
set -x
# set -e

# Component URLS
MLO_BEAGLEBONE=/tmp/mlo_beaglebone
MLO_BEAGLEBONE_URL=http://dominion.thruhere.net/angstrom/nightlies/v2015.12/beaglebone/MLO-beaglebone-2014.07

UBOOT_BEAGLEBONE_IMG=/tmp/u-boot-beaglebone.img
UBOOT_BEAGLEBONE_IMG_URL=http://dominion.thruhere.net/angstrom/nightlies/v2015.12/beaglebone/u-boot-beaglebone.img


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
	rm -f $MLO_BEAGLEBONE
	rm -f $UBOOT_BEAGLEBONE_IMG
	rm -f /tmp/rootfs.tar.xz
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

# checks for required tools
reqs_passed=1
which mke2fs >/dev/null
if [ $? -ne 0 ]; then echo "Please install mke2fs (e2fsprogs)";reqs_passed=0; fi
which mkfs.ext4 >/dev/null
if [ $? -ne 0 ]; then echo "Please install mkfs.ext4";reqs_passed=0; fi
which mkfs.vfat >/dev/null
if [ $? -ne 0 ]; then echo "Please install mkfs.vfat (dosfstools)";reqs_passed=0; fi
which xz >/dev/null
if [ $? -ne 0 ]; then echo "Please install xz";reqs_passed=0; fi
which bc >/dev/null
if [ $? -ne 0 ]; then echo "Please install bc";reqs_passed=0; fi
which sfdisk >/dev/null
if [ $? -ne 0 ]; then echo "Please install sfdisk";reqs_passed=0; fi
which fdisk >/dev/null
if [ $? -ne 0 ]; then echo "Please install fdisk";reqs_passed=0; fi
which awk >/dev/null
if [ $? -ne 0 ]; then echo "Please install awk";reqs_passed=0; fi
which kpartx >/dev/null
if [ $? -ne 0 ]; then echo "Please install kpartx";reqs_passed=0; fi

if [ $reqs_passed -ne 1 ]; then exit 1; fi


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

if [ ! -f format_sd.sh ]; then
        echo "Cannot find format_sd.sh"
        exit 1
fi

# Download resources
wget $MLO_BEAGLEBONE_URL -O $MLO_BEAGLEBONE
wget $UBOOT_BEAGLEBONE_IMG_URL -O $UBOOT_BEAGLEBONE_IMG
echo "Downloading rootfs"
wget -nv http://dominion.thruhere.net/angstrom/nightlies/v2015.12/beaglebone/Angstrom-systemd-image-glibc-ipk-v2015.07-beaglebone.rootfs.tar.xz -O /tmp/rootfs.tar.xz

# format SDcard
sudo bash ./format_sd.sh /dev/$DRIVE ERASE


sudo umount /dev/${DRIVE_P}1 || true # fake exit status because we only try
sudo umount /dev/${DRIVE_P}2 || true

sudo mount /dev/${DRIVE_P}1 $tmpmount_1
sudo mount /dev/${DRIVE_P}2 $tmpmount_2

sudo cp -v $MLO_BEAGLEBONE $tmpmount_1/MLO

sudo cp -v $UBOOT_BEAGLEBONE_IMG $tmpmount_1/u-boot.img

# image on local system sudo tar xf Angstrom-systemd-image-eglibc-ipk-v2012.12-beaglebone.rootfs.tar.xz -C /media/${DRIVE_P}2

echo "Extracting rootfs"
tar xJf /tmp/rootfs.tar.xz -C $tmpmount_2/


echo "The new SD card will be accessible via network with the hostname ${MY_HOSTNAME}"
echo $MY_HOSTNAME > $tmpmount_2/etc/hostname

echo "Umounting and syncing file systems. This can take a while..."
sudo umount /dev/${DRIVE_P}1
sudo umount /dev/${DRIVE_P}2

cleanup
