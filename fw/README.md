# Ice40 programmer

This firmware allows a Raspberry Pi Pico (or any RP2040) to work as a
programmer for the lattice ice40 parts.

It has been integrated into icestorm:
https://github.com/tillitis/icestorm/tree/interfaces

## Building the firmware

First, follow the details in the toolchain setup document to install
the Raspberry Pi Pico SDK. Then, the firmware can be built by running
the build script:

```
./build.sh
```

Once complete, the output binary is located in build/main.uf2

## Usage

First, program your RPi Pico using the included binary 'main.u2f'. To
do so, disconnect the pico from your computer, press down the
bootloader button, then plug the pico back in. The computer should
detect it as a memory device. Copy the main.u2f file into the root
directory of this memory device. This will program the Pico. Once
completed, the pico should restart and present itself as a USB RAW
device.

To use it with icestorm, the 'iceprog' utility will need to be built
from the above fork. Known issues:

* This version of iceprog is hard-coded to use the pico as a programmer; it
should have a command-line switch to choose the correct programmer
* SRAM programming mode (-S) is untested

TODO: Suggested wiring diagram

TODO: Permissions

## Version checking

The firmware version can be determined from the bcdDevice field in the
USB device descriptor. Known versions are:

| bcdDevice | Version | Description |
| --- | --- | --- |
| 0x0100 | 1.0 | Raw USB test version |
| 0x0200 | 2.0 | Release version |
| 0x0201 | 2.1 | Support bulk transfer |

The command set described in this document describes the version 2.1
format.

## Command set

Commands are sent to the device as control transfers, except for a few
commands that in addition to control transfer also supports bulk
transfer for increased throughput.

For control transfers the bRequest field is used to select the
commmand, and any configuration data associated with the command.
When using bulk transfer for a command the bRequest field does not
exist. Instead the protocol puts the request code as the first byte in
the data field. See each commmand below in order to see the
difference.

| Command | Direction | bRequest | wValue | wIndex | wLength | bulk wLength |
| --- | ---  | --- | --- | --- | --- | --- |
| Set pin directions    | OUT | 0x30  | 0 | 0 | 8 | NA |
| Set pullups/pulldowns | OUT | 0x31  | 0 | 0 | 12 | NA |
| Set pin values         | OUT | 0x32 | 0 | 0 | 8 | 9 |
| Get pin values         | IN  | 0x32 | 0 | 0 | 4 | NA |
| Configure SPI pins and clock speed | OUT | 0x40 | 0 | 0 | 5 | NA |
| Perform a SPI transfer | OUT | 0x41 | 0 | 0 | 5+n | 7+n |
| Read data from previous SPI transfer | IN  | 0x41 | 0 | 0 | n | n |
| Send SPI clocks        | OUT | 0x42 | 0 | 0 | 4 | 5 |
| Read ADC inputs        | IN  | 0x50 | 0 | 0 | 12 | NA |
| Enter bootloader mode  | OUT | 0xE0 | 0 | 0 | 0 | NA |

Additionally, the device supports an additional control transfer to
support driver assignment on Windows:

| Command | Direction | bRequest | wValue | wIndex | wLength | Description |
| ---  | ---  | --- |--- | --- |--- |--- |
| MS_DESCRIPTOR      | IN | 0xF8 | 0 | 0 | x | Get a Microsoft OS compatible descriptor |

### Set pin directions

This command is used to set pin directions. The first field is a mask
of pins to update, and the second is a bitmap of the resulting states.
Any pin that has a bit set in the mask will be updated.

Data packet format:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 4      | uint32: Pin mask (1=set direction) |
| 0x04   | 4      | uint32: Pin direction (1=output, 0=input) |

### Set pin pullup/pulldown resistors

This command is used to set pin pullup/pulldown resistors. The first
field is a mask of pins to update, the second is the pull-up states,
and the third is the pull-down states. Any pin that has a bit set in
the mask will be updated.

Data packet format:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 4      | uint32: Pin mask (1=set direction) |
| 0x04   | 4      | uint32: Pin pullups (1=enable, 0=disable) |
| 0x08   | 4      | uint32: Pin pulldowns (1=enable, 0=disable) |

### Set pin values

This command is used to set the value of output pins. The first field
is a mask of pins to update, and the second is a bitmap of new output
values to apply. Any pin that has a bit set in the mask will be
updated.

This command supports both control and bulk transfer.

Data packet format for control transfer:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 4      | uint32: Pin mask (1=set direction) |
| 0x04   | 4      | uint32: Pin value (1=high, 0=low) |

Data packet format for bulk transfer:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 4      | Request code |
| 0x01   | 4      | uint32: Pin mask (1=set direction) |
| 0x05   | 4      | uint32: Pin value (1=high, 0=low) |

### Read pin values

This command is used to read the value of all pins. Note that pins
which are confgured as outputs will report their current output
setting.

Data packet format:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x05   | 4      | uint32: Pin values (1=high, 0=low) |

### Set SPI configuration

This command is used to configure the SPI engine.

Data packet format:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 1      | GPIO pin number for SCK |
| 0x01   | 1      | GPIO pin number for CS |
| 0x02   | 1      | GPIO pin number for MOSI |
| 0x03   | 1      | GPIO pin number for MISO |
| 0x04   | 1      | SPI clock frequency, in MHz |

### Transfer SPI data

This command is used to send data over the pins currently configured
as the SPI interface. This command performs a full-duplex read/write
operation, and stores the read data in a buffer. To retrieve the data
read during this operation, issue a read command.

This command supports both control and bulk transfer.

Data packet format for control transfer:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 1      | 0: don't toggle CS; any other value: toggle CS |
| 0x01   | 4      | Bytes to transfer |
| 0x05   | 1-2040 | SPI data to transfer |

Data packet format for bulk transfer:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 1      | Requst code |
| 0x01   | 1      | 0x00: No intent of doing a read. 0x01: intending to read, do a bulk IN transfer |
| 0x02   | 1      | 0: don't toggle CS; any other value: toggle CS |
| 0x03   | 4      | Bytes to transfer |
| 0x07   | 1-2040 | SPI data to transfer |

When using bulk transfer one has to signal the intent that one wants
SPI data back in this command, so the IN endpoint can be prepared. If
one wants the read data, one has to perorm a bulk IN transfer right
after this command. It is not guaranted that the data is available if
one do any other command in between the transfer and the read.

### Get data read during previous SPI transaction

This command is used to retrieve any data transferred during the
previous SPI transaction.

This command supports both control and bulk transfer.

Data packet format for control transfer:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 1-2040 | SPI data to transfer |

Data packet format for bulk transfer:
| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 1-2040 | SPI data to transfer |

Note that the request code is omitted here, the intent to read data
back from a previous SPI transction is signaled with the second byte
of the SPI transfer command (0x41). So one simply do a bulk transfer
IN. It is not guaranted that the data is available if one do any other
command in between the transfer and the read.

### SPI clock out

This command is used to toggle the SPI clock pin, but doesn't transfer
any data.

This command supports both control and bulk transfer.

Data packet format for control transfer:

| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 4      | Number of SPI bytes to clock |


Data packet format for bulk transfer:
| Offset | Length | Description |
| ---    | ---    | ---         |
| 0x00   | 1      | Requst code |
| 0x01   | 4      | Number of SPI bytes to clock |

### Read ADCs

This command is used to read the analog value of analog input pins
0-2. Each value is returned as a uint32_t value representing the
reading in microvolts.

Data packet format:

| Offset | Length | Description |
| ---    | ---    | ---         | 
| 0x01   | 4      | ADC channel 0 value, in microvolts |
| 0x05   | 4      | ADC channel 1 value, in microvolts |
| 0x09   | 4      | ADC channel 2 value, in microvolts |

### Bootloader

This command is used to put the device in bootloader mode. No data is
sent during this 
