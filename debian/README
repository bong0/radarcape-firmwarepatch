# Radarcape on beagleboard.org debian (jessie) 8.1 beaglebone-black
# The procedure

* Flash full SD-Image from beagleboard.org (kernel >=4.1.1, console)

* Opkg-Static compilation
  * https://github.com/pfalcon/opkg-static (see README)
  * optionally change the toolchain url to a newer one in `setup-toolchain.sh` e.g. `arm-2014.05-29-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2`
    * the links are not official but I found some here https://github.com/maximeh/buildroot/blob/master/toolchain/toolchain-external/toolchain-external.mk
  * copy the opkg-static binary to the target board

* opkg has hardcoded strings to overlayfs, those need to be symliked: script: symlink_opkg_dirs.sh

* Auto-trigger (~disable) watchdog for development **YOU WANT TO DO THIS NOW, else our bit apt-get will never finish**
cat <<EOF

echo 60 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio60/direction
echo 1 > /sys/class/gpio/gpio60/value
echo 0 > /sys/class/gpio/gpio60/value
(while `true`; do echo 1 > /sys/class/gpio/gpio60/value; echo 0 > /sys/class/gpio/gpio60/value; sleep 30; done)&
EOF > /etc/rc.local

* Installation of the radarcape software:
* Dependencies `apt-get update; apt-get -y install libsqlite0 connman psmisc`

* **opkg file from the modesbeast wiki page has to be patched!**
  * RADARCAPE_DIR=/home/root in preinst und postinst script has to be changed to /root => see patchscript
  * `download_and_patch_opkg.sh`
  * transfer build _.opk_ file to target
  * `opkg-static install *.opk --force-depends`

* beaglebone dts-overlay installation: (this also adds the missing files in /lib/firmware, e.g. BB-UART5 and BB-UART2)
```cd /tmp
git clone https://github.com/beagleboard/bb.org-overlays.git
cd bb.org-overlays
./dtc-overlay.sh
./install.sh
cd ..
rm -rf bb.org-overlays
dtc -O dtb -o BB-B-Radarcape-00A0.dtbo -b 0 -@ BB-B-Radarcape.dts # recompile dts file for the new dtc version!
reboot
```
