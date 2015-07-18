#!/bin/bash -x

latestRelease=$(wget -q -O- http://wiki.modesbeast.com/Radarcape:Firmware_Versions | grep -oE '\#Release.*[0-9]+"' | sed -e 's/.$//' -e 's/.*_//' | head -n1)

destDir=$PWD
tmpdir=$(mktemp -d)
echo $tmpdir
cd $tmpdir

wget -N http://www.modesbeast.com/resources/radarcaped-${latestRelease}.opk

mkdir opkunpack
cd opkunpack
ar -x ../*.opk

# patch the control scripts
tar xzf control.tar.gz
sed -i 's|/home/root|/root|g' postinst
sed -i 's|/home/root|/root|g' preinst
sed -i 's|/home/root|/root|g' postrm
tar czf control.tar.gz postinst postrm  preinst  prerm  # leave out the .bak files...
rm postinst  postinst.bak  postrm  preinst  preinst.bak  prerm

# patch the application
mkdir unpack
tar xzf data.tar.gz -C unpack
cd unpack
sed -i 's|/home/root|/root|g' home/root/cape.sh
sed -i 's|/home/root|/root|g' lib/systemd/system/adsb.service
cd ..
tar czf data.tar.gz -C unpack  # leave out the .bak files...
rm -r unpack

cd ..
ar -rcs *.opk opkunpack/*
mv *.opk $destDir
# rm -rf $tmpdir
