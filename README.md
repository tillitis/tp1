# TKey Programmer 1

The TKey Programmer 1 (TP1) board is a tool used to program the FPGA
on a TKey. It consists of a RPI Pico and a jig where the TKey can be
placed.

## General usage

The board is interfaced using USB, and it will display itself as ID
`1209:8886 Generic TP-1`. The TKey is supposed to be placed in the jig
and one closes the lid carefully by pressing in the middle of the jig
(by the hole). To open the lid of the jig, it is easiest to simply
lift up on the lever.

The TP1 board supports two host computer tools to accommodate
programming of the TKey, either `iceprog` or `pynvcm`. See the chapter
in the [TKey Developer Handbook](https://dev.tillitis.se/tp1/) for a
more elaborate description on how to use it.

## Linux device permissions

To allow sudo-less programming, you need to be able to access the TKey
Programmer USB device. This is a raw USB device that is probably not
taken care of by your distribution.

You can install an udev rule that will assign the TP1 to the dialout
group. You will also need to add your user to the dialout group.

Create the following udev rule at `/etc/udev/rules.d`:

```
# TP-1 programmer
SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1209", ATTR{idProduct}=="8886", MODE="0666", GROUP="dialout"
```

To reload the rules run:

```
sudo udevadm control --reload-rules
sudo usermod -aG dialout ${USER}
```

To apply the new group, log out and then log back in, or run the
command `newgrp dialout` in the terminal that you are working in.

You can check the device permissions to determine if the group was
successfully applied. First, use `lsusb` to find the location of the
programmer:

```
lsusb -d 1209:8886
Bus 001 Device 023: ID 1209:8886 Generic TP-1
```

Then, you can check the permissions by using the bus and device
numbers reported above like this:

```
ls -l /dev/bus/usb/001/023
crw-rw---- 1 root dialout 189, 22 Feb 16 14:58 /dev/bus/usb/001/023
```

Note that this pair of numbers is ephemeral and may change after every
device insertion.

## Firmware
The TP1 board runs a custom firmware developed by Blinkinlabs for
Tillitis. There is also a pre-built firmware binary at
`fw/bin/main.uf2`.

To update the firmware, either build the file `main.uf2` (more
instructions below) or get the pre-built file to your host computer.
Then do the following:

1. Disconnect the programming board from the host computer
2. Press and hold the "BOOTSEL" button on the RPi2040 sub-board on the
programming board
3. Reconnect the programming board to the host computer
4. Release the "BOOTSEL" button after connecting the programming board
to the host. The board should now appear to the host as a USB
connected storage device
5. Open the storage device and drop the firmware file `main.uf2` into
the storage device

The programmer will update its firmware with the file and restart
itself. After rebooting, the storage device will automatically be
disconnected.

### Building the firmware

The firmware requires the Raspberry Pi Pico SDK, the build script
assumes this is located either in your home home directory, or in
`/usr/local`. To clone to the home directory use

```
cd ~
git clone --branch 1.5.1 https://github.com/raspberrypi/pico-sdk.git
cd pico-sdk
git submodule update --init
```

then run the build script in the `fw` folder

```
./build.sh
```

Note that our container image (tkey-builder) places the pico-sdk
directory in `/usr/local`. For normal development, it is usually left
in the user's home directory.

See
[fw/README.md](https://github.com/tillitis/tp1/blob/main/fw//README.md)
for further instructions.

## KiCad

The PCB is built using KiCad version 7. Production files are built in
CI using KiBot, see the Makefile for exact version.

## License
### Hardware
Unless otherwise noted, this project is licensed under CERN Open
Hardware License Version 2 - Strongly Reciprocal, see full license
under [LICENSE.txt](/LICENSE.txt).
```
Copyright Tillitis AB 2022-2024.

This source describes Open Hardware and is licensed under the CERN-OHL-S v2.

You may redistribute and modify this source and make products using it under
the terms of the CERN-OHL-S v2 (https://ohwr.org/cern_ohl_s_v2.txt).

This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A
PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable conditions.

Source location: https://github.com/tillitis/tp1

As per CERN-OHL-S v2 section 4, should You produce hardware based on this
source, You must where practicable maintain the Source Location visible
on the external case of the product or its packaging, and in its
documentation, even after modification.
```

The [CERN-OHL-S user guide](/User-guide-CERN-OHL-S.txt) is included to
make it easier to follow the license, both as a Licensor or a Licensee.

### Firmware
The firmware running on the TP1 is licensed under MIT License, see the
full license [fw/LICENSE](fw/LICENSE).

Copyright (c) 2023 Tillitis AB.

### Raspberry Pi Pico
TKey Programmer board uses the Raspberry Pi Pico hardware, which are
provided by Raspberry Pi Ltd. For more details, visit the official
Raspberry Pi Pico documentation at
https://www.raspberrypi.com/licensing/

## Prototypes

Under `prototypes/`, an earlier version of the TP1 can be found, such as
the `mta1-usb-v1-programmer`.


## History
This repo was created by filtering out relevant commits and files from
the [tillitis/tillits-key1](https://github.com/tillitis/tillitis-key1)
repo.

The filtering removed all files and commits that weren't related to
the tp1 hardware. This was done using
[git-filter-repo](https://github.com/newren/git-filter-repo).

To replicate the results up until commit `f1158b1` in this repo,
checkout commit `354aecb` in `tillitis/tillitis-key1` and run
`git-filter-repo --path hw/boards/tp1 --path
hw/boards/mta1-usb-v1-programmer --path hw/boards/KiCad-RP Pico`

All filtered commits have intact date, author, and code. Some
unrelated files are removed from some commits, but the commit messages
are left unchanged. Commit sha, tags and signatures are new. For
complete history, please see tillitis/tillitis-key1 from commit
`354aecb` and earlier.
