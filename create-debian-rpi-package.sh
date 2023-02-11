#!/usr/bin/bash
#
#   @Ephemeral
#
#   USAGE:
#
#   sudo bash create-debian-rpi-package.sh create PACKAGENAME
#   sudo dpkg -i PACKAGENAME.deb
#   sudo bash create-debian-rpi-package.sh clean PACKAGENAME
#
# sudo tail -f /var/log/dpkg.log


ARCHITECTURE="aarch64" # RPi3B, test: raspbian buster
KERNEL=kernel8.img
PROJECT=/home/carl/dev/build-kernel/


function CREATE(){
if [ ! -d "${PROJECT}/package/DEBIAN" ];then
    mkdir -p "${PROJECT}/package/DEBIAN"
else
    echo "A temporary directory ${PROJECT}/package already exists !"
    echo "You can use 'sudo bash create-debian-rpi-package.sh clean'"
    exit 0
fi;
cd "${PROJECT}/package"




echo "creating embeded files..."
mkdir -p ./boot/overlays
cp arch/arm64/boot/dts/*dtb ./boot
cp arch/arm64/boot/dts/overlays/*.dtb* ./boot/overlays/
cp arch/arm64/boot/dts/overlays/README ./boot/overlays/
cp arch/arm64/boot/zImage ./boot/$KERNEL.img
#mkdir -p ./usr/bin/
#echo "ip a" > ./usr/bin/mytool.sh


cd "DEBIAN"


echo "creating pre install file, use this for saving KERNEL..."
cat << EOF > preinst
#!/bin/sh
echo "pre install job"
BACKUP_DIR="/home/pi/boot-backup-\$(date +%m-%d-%Y_%H-%M-%S)"
echo "Creating /boot backup in \${BACKUP_DIR}"
if [ ! -d "\${BACKUP_DIR}" ];then
    mkdir "\${BACKUP_DIR}"
    cp -R /boot "\${BACKUP_DIR}"
fi;
exit 0
EOF
chmod 0755 preinst



echo "creating control file..."
cat << EOF > control
Package: ${PACKAGENAME}
Version: 0.1-0
Architecture: ${ARCHITECTURE}
Maintainer: ${PACKAGENAME} <${PACKAGENAME}@debian.org>
Description: utility package
EOF


echo "creating post install file..."
cat << EOF > postinst
!/bin/sh
echo "post install job"
chmod -R +x /boot/overlays
chmod +x /boot/$KERNEL.img
chmod +x /boot/*.dtb
exit 0
EOF
chmod 0755 postinst


echo "building debian package ${PACKAGENAME}.deb ..."
cd ..
dpkg-deb --build {$PROJECT}package
if [ ${?} -eq "0" ];then
    mv {$PROJECT}package.deb {$PROJECT}${PACKAGENAME}.deb
    echo "SUCCESS building {$PROJECT}${PACKAGENAME}.deb"
    echo -e "\nINSTALL\nsudo dpkg -i {$PROJECT}${PACKAGENAME}.deb\n\n"
fi
}

function CLEAN(){
    rm -R {$PROJECT}package
    rm -R {$PROJECT}${PACKAGENAME}.deb
    dpkg --purge ${PACKAGENAME}
}



if [ -z "${SUDO_USER}" ];then
    echo "Sorry you must an sudo user for running this script."
    exit 0
fi
case ${1} in
    create|CREATE|Create)if [ -z "${2}" ];then echo "You must provide the package name."; exit 0; else PACKAGENAME="${2}";fi; CREATE;;
    clean|CLEAN|Clean)if [ -z "${2}" ];then echo "You must provide the package name."; exit 0;else PACKAGENAME="${2}";fi; CLEAN;;
    *)echo -e "Unknown option ${1}\nOptions are: CREATE or CLEAN";;
esac
