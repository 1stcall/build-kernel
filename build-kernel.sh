#!/bin/bash

trap '{ stty sane; echo ""; errexit "Aborted"; }' SIGINT SIGTERM

CONFIG1="Raspberry Pi 1, Zero and Zero W, and Raspberry Pi Compute Module 1 (32-bit)"
CONFIG2="Raspberry Pi 2, 3, 3+ and Zero 2 W, and Raspberry Pi Compute Modules 3 and 3+ (32-bit)"
CONFIG3="Raspberry Pi 4 and 400, and Raspberry Pi Compute Module 4 (32-bit)"
CONFIG4="Raspberry Pi 3, 3+, 4, 400 and Zero 2 W, and Raspberry Pi Compute Modules 3, 3+ and 4 (64-bit)"

errexit()
{
  echo ""
  echo "$1"
  echo ""
  exit 1
}

instpkgs()
{
  local i
  local PKGS

  PKGS=("$@")
  for i in ${!PKGS[@]}; do
    dpkg -s "${PKGS[i]}" &> /dev/null
    if [ $? -eq 0 ]; then
      unset PKGS[i]
    fi
  done
  if [ ${#PKGS[@]} -ne 0 ]; then
    echo ""
    echo -n "Ok to install ${PKGS[@]} (y/n)? "
    while read -r -n 1 -s answer; do
      if [[ ${answer} = [yYnN] ]]; then
        echo "${answer}"
        if [[ ${answer} = [nN] ]]; then
          errexit "Aborted"
        fi
        break
      fi
    done
    echo ""
    apt-get -y update
    apt-get -y install "${PKGS[@]}"
  fi
}

usage()
{
  cat <<EOF

Usage: $0 [options]
-b,--branch       Branch to use
-c,--config       Configuration to build:
   1 = ${CONFIG1}
   2 = ${CONFIG2}
   3 = ${CONFIG3}
   4 = ${CONFIG4}
-d,--delete       Delete existing source files
-h,--help         This usage description
-k,--keep         Keep old kernel as .bak
-m,--menuconfig   Run menuconfig
-p,--purge        Purge source files upon completion
-r,--reboot       Reboot upon completion
-s,--suffix       Append modules suffix
-u,--unattended   Unattended operation, defaults:
   Branch = default
   Config = ${CONFIG4}
   Delete = auto
   Keep = no
   Menuconfig = no
   Purge = no
   Reboot = no
   Suffix = none

EOF
}

if [ $(id -u) -ne 0 ]; then
  errexit "Must be run as root user: sudo $0"
fi
PGMNAME="$(basename $0)"
for PID in $(pidof -x -o %PPID "${PGMNAME}"); do
  if [ ${PID} -ne $$ ]; then
    errexit "${PGMNAME} is already running"
  fi
done
BRANCH="rpi-6.2.y"
CONFIG="4"
DELETE=false
KEEP=true
MNUCFG=false
PURGE=false
REBOOT=false
SUFFIX=""
UNATND=true
while [ $# -gt 0 ]; do
  case "$1" in

    -b|--branch)
      BRANCH="$2"
      shift 2
      ;;

    -c|--config)
      CONFIG="$2"
      shift 2
      ;;

    -d|--delete)
      DELETE=true
      shift
      ;;

    -h|--help)
      usage
      exit
      ;;

    -k|--keep)
      KEEP=true
      shift
      ;;

    -m|--menuconfig)
      MNUCFG=true
      shift
      ;;

    -p|--purge)
      PURGE=true
      shift
      ;;

    -r|--reboot)
      REBOOT=true
      shift
      ;;

    -s|--suffix)
      SUFFIX="$2"
      shift 2
      ;;

    -u|--unattended)
      UNATND=true
      shift
      ;;

    -*|--*)
      errexit "Unrecognized option"
      ;;

    *)
      errexit "Unrecognized parameter"
      ;;

  esac
done
instpkgs bc bison flex git libssl-dev make
if [[ "${UNATND}" = "false" && "${CONFIG}" = "" ]]; then
  echo ""
  echo -e -n "\
1) ${CONFIG1}\n\
2) ${CONFIG2}\n\
3) ${CONFIG3}\n\
4) ${CONFIG4}\n\
Configuration: "
  while read -r -n 1 -s answer; do
    if [[ ${answer} = [1234] ]]; then
      echo "${answer}"
      CONFIG="${answer}"
      break
    fi
  done
fi
if [ "${CONFIG}" = "" ]; then
  CONFIG=4
fi
case "${CONFIG}" in

  1)
    MAKCFG=bcmrpi_defconfig
    KERNEL=kernel
    ;;

  2)
    MAKCFG=bcm2709_defconfig
    KERNEL=kernel7
    ;;

  3)
    MAKCFG=bcm2711_defconfig
    KERNEL=kernel7l
    ;;

  4)
    MAKCFG=bcm2711_defconfig
    KERNEL=kernel8
    ;;

  *)
    errexit "Invalid configuration"
    ;;

esac
if [[ "${UNATND}" = "false" && "${BRANCH}" = "" ]]; then
  echo ""
  echo -n "Branch (blank = default): "
  read -r BRANCH
fi
BRANCH="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "${BRANCH}")"
if [[ "${BRANCH}" != "" && "${BRANCH}" != "$(git ls-remote --symref https://github.com/raspberrypi/linux | sed -n "s|^\S\+\s\+refs/heads/\(${BRANCH}\)$|\1|p")" ]]; then
  errexit "Branch '${BRANCH}' does not exist"
fi
if [[ "${UNATND}" = "false" && "${SUFFIX}" = "" ]]; then
  echo ""
  echo -n "Suffix (blank = none): "
  read -r SUFFIX
fi
SUFFIX="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "${SUFFIX}")"
SUFFIX="$(tr [[:blank:]] _ <<< "${SUFFIX}")"
if [[ "${UNATND}" = "false" && "${MNUCFG}" = "false" ]]; then
  echo ""
  echo -n "Run menuconfig (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ ${answer} = [yYnN] ]]; then
      echo "${answer}"
      if [[ ${answer} = [yY] ]]; then
        MNUCFG=true
      fi
      break
    fi
  done
fi
if [[ "${UNATND}" = "false" && "${KEEP}" = "false" ]]; then
  echo ""
  echo -n "Keep old kernel as .bak (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ ${answer} = [yYnN] ]]; then
      echo "${answer}"
      if [[ ${answer} = [yY] ]]; then
        KEEP=true
      fi
      break
    fi
  done
fi
if [[ "${UNATND}" = "false" && "${PURGE}" = "false" ]]; then
  echo ""
  echo -n "Purge source files upon completion (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ ${answer} = [yYnN] ]]; then
      echo "${answer}"
      if [[ ${answer} = [yY] ]]; then
        PURGE=true
      fi
      break
    fi
  done
fi
if [[ "${UNATND}" = "false" && "${REBOOT}" = "false" ]]; then
  echo ""
  echo -n "Reboot upon completion (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ ${answer} = [yYnN] ]]; then
      echo "${answer}"
      if [[ ${answer} = [yY] ]]; then
        REBOOT=true
      fi
      break
    fi
  done
fi
echo ""
echo -n "Configuration: "
case "${KERNEL}" in
  kernel)
    echo "${CONFIG1}"
    ;;

  kernel7)
    echo "${CONFIG2}"
    ;;

  kernel7l)
    echo "${CONFIG3}"
    ;;

  kernel8)
    echo "${CONFIG4}"
    ;;
esac
echo -n "Branch: "
if [ "${BRANCH}" = "" ]; then
  echo "default"
else
  echo "${BRANCH}"
fi
echo -n "Suffix: "
if [ "${SUFFIX}" = "" ]; then
  echo "none"
else
  echo "${SUFFIX}"
fi
echo -n "Run menuconfig: "
if [ "${MNUCFG}" = "true" ]; then
  echo "Yes"
else
  echo "No"
fi
echo -n "Keep old kernel as .bak: "
if [ "${KEEP}" = "true" ]; then
  echo "Yes"
else
  echo "No"
fi
echo -n "Purge source files upon completion: "
if [ "${PURGE}" = "true" ]; then
  echo "Yes"
else
  echo "No"
fi
echo -n "Reboot upon completion: "
if [ "${REBOOT}" = "true" ]; then
  echo "Yes"
else
  echo "No"
fi
if [ "${UNATND}" = "false" ]; then
  echo ""
  echo -n "Build kernel (y/n)? "
  while read -r -n 1 -s answer; do
    if [[ ${answer} = [yYnN] ]]; then
      echo "${answer}"
      if [[ ${answer} = [nN] ]]; then
        errexit "Aborted"
      fi
      break
    fi
  done
fi
if [ -e /usr/src/linux ]; then
  SOURCE="$(sed -n 's|^\[branch "\(.*\)"\]|\1|p' /usr/src/linux/.git/config)"
  TARGET="${BRANCH}"
  if [ "${TARGET}" = "" ]; then
    TARGET="$(git ls-remote --symref https://github.com/raspberrypi/linux | head -n 1 | sed -n 's|^ref:\s\+refs/heads/\(.*\)\s\+HEAD$|\1|p')"
  fi
  if [ "${TARGET}" != "${SOURCE}" ]; then
    DELETE=true
  fi
  if [[ "${UNATND}" = "false" && "${DELETE}" = "false" ]]; then
    echo ""
    echo -n "Delete existing source files [Source/Target branch = ${SOURCE}] (y/n)? "
    while read -r -n 1 -s answer; do
      if [[ ${answer} = [yYnN] ]]; then
        echo "${answer}"
        if [[ ${answer} = [yY] ]]; then
          DELETE=true
        fi
        break
      fi
    done
  fi
  if [ "${DELETE}" = "true" ]; then
    echo ""
    echo "Deleting existing source files"
    rm -r /usr/src/linux
  fi
fi
if [ ! -e /usr/src/linux ]; then
  cd /usr/src
  echo ""
  if [ "${BRANCH}" = "" ]; then
    git clone --depth=1 https://github.com/raspberrypi/linux
  else
    git clone --depth=1 --branch "${BRANCH}" https://github.com/raspberrypi/linux
  fi
fi
cd /usr/src/linux
echo ""
make "${MAKCFG}"
if [ "${SUFFIX}" != "" ]; then
  sed -i "s|^\(CONFIG_LOCALVERSION=\".*\)\"$|\1-${SUFFIX}\"|" .config
fi
if [ "${MNUCFG}" = "true" ]; then
  instpkgs libncurses5-dev
  make menuconfig
fi
echo ""
if [ "${KERNEL}" = "kernel8" ]; then
  make -j4 Image modules dtbs
  make modules_install
  cp arch/arm64/boot/dts/broadcom/*.dtb /boot/
  cp arch/arm64/boot/dts/overlays/*.dtb* /boot/overlays/
  cp arch/arm64/boot/dts/overlays/README /boot/overlays/
  if [ "${KEEP}" = "true" ]; then
    mv /boot/${KERNEL}.img /boot/${KERNEL}.img.bak
  fi
  cp arch/arm64/boot/Image /boot/${KERNEL}.img
  gzip --best /boot/${KERNEL}.img
  mv /boot/${KERNEL}.img.gz /boot/${KERNEL}.img
else
  make -j4 zImage modules dtbs
  make modules_install
  cp arch/arm/boot/dts/*.dtb /boot/
  cp arch/arm/boot/dts/overlays/*.dtb* /boot/overlays/
  cp arch/arm/boot/dts/overlays/README /boot/overlays/
  if [ "${KEEP}" = "true" ]; then
    mv /boot/${KERNEL}.img /boot/${KERNEL}.img.bak
  fi
  cp arch/arm/boot/zImage /boot/${KERNEL}.img
fi
echo ""
echo "Kernel successfully built"
if [ "${PURGE}" = "true" ]; then
  echo ""
  echo -n "Attemping to purging source files"
#  rm -r /usr/src/linux

  while read -r -n 1 -s answer; do
    if [[ ${answer} = [1234] ]]; then
      echo "${answer}"
      CONFIG="${answer}"
      break
    fi
  done
fi
echo ""
if [ "${REBOOT}" = "true" ]; then
  echo "Rebooting"
  echo ""
  shutdown -r now
else
  echo "Reboot required to use new kernel"
  echo ""
fi
