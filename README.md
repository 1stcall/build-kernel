# build-kernel

Tool used to build a Raspberry Pi OS kernel.


## Dependencies

build-kernel runs on Debian-based operating systems. Currently it is only supported on
either Debian Bullseye and has not been tested on any other.

To install the required dependencies for `build-kernel` you should run:

```bash
**TODO**
```

The file `depends` contains a list of tools needed.  The format of this
package is `<tool>[:<debian-package>]`. **\*\*TODO\*\***

## Getting started with building your kernel

Getting started is as simple as cloning this repository on your build machine. You
can do so with:

```bash
**TODO**
```

`--depth 1` can be added afer `git clone` to create a shallow clone, only containing
the latest revision of the repository. Do not do this on your development machine.

Also, be careful to clone the repository to a base path **NOT** containing spaces.
This configuration is not supported by debootstrap and will lead to `build-kernel` not
running. **\*\*TODO\*\***

After cloning the repository, you can move to the next step and start configuring
your build.

## Config

**\*\*TODO\*\***

## Credits
**\*\*WIP\*\***


Thanks to [ephemeral](https://raspberrypi.stackexchange.com/users/103638/ephemeral) for the head start with [create-debian-rpi-package](create-debian-rpi-package.sh).  (See https://raspberrypi.stackexchange.com/questions/100732/how-to-package-custom-rpi-kernel-into-deb)

Thanks to [RonR](https://forums.raspberrypi.com/memberlist.php?mode=viewprofile&u=186692&sid=b8e7117279301c67cebe9029051f2bc2) for the head start with [build-kernel](build-kernel.sh). (See https://forums.raspberrypi.com/viewtopic.php?t=330358 & https://www.raspberrypi.com/documentation/computers/linux_kernel.html#building-the-kernel-locally)

