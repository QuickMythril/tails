[[!tag archived]]

[[!meta title="USB image"]]

Corresponding ticket: [[!tails_ticket 15292]]

[[!toc levels=2]]

# Motivation

A number of the
[[problems we've identified with the installation process|blueprint/usb_install_and_upgrade#problems]]
will be fixed by generating, distributing and installing Tails as
a disk image that, once copied bit-by-bit to a USB stick, produces
a _final Tails_ (GPT, UEFI-bootable, ready to get a persistent
volume).

# The plan

The list of tasks is being worked on in `fundraising.git`.
It should be converted into subtasks of [[!tails_ticket 15292]] at
some point.

# Specific problems

## Generating

`live-build` can generate `hdd` images. Alternatively, we can
post-process our ISO image to create a USB-bootable disk image.

Open questions:

 - What size should the system partition be? Do we grow the system
   partition on first boot (from the initramfs) e.g.
   with [[!debpts cloud-init]] or the Rasbian tools
   (<https://www.raspberrypi.org/downloads/noobs/>,
   <https://www.raspberrypi.org/downloads/raspbian/>)?
 - What about DVD support? Can we stop distributing an ISO image
   some day?

## Growing system partition during boot

Corresponding ticket: [[!tails_ticket 15319]]

The plan is to do this in a _partitioning_ script in the initramfs. There are different stages in the initramfs, which are explained in the (pretty useful) [man page for _initramfs-tools_](http://manpages.ubuntu.com/manpages/xenial/man8/initramfs-tools.8.html).

The initramfs in Tails is customized by [_live-boot_](http://manpages.ubuntu.com/manpages/xenial/man7/live-boot.7.html), which is poorly documented. 

### Some notes about the initramfs/live-boot process

This is how the scripts in `/scripts/live-realpremount` are executed:

    initramfs-tools calls mountroot ()
    /scripts/live line 12 in mountroot ()
    9990-main.sh line 124 in Live ()
    9990-overlay.sh line 85 in setup_unionfs ()

This is how `/dev/sda1` is mounted:

    9990-main.sh line 72 in Live ()
    9990-misc-helpers.sh` line 268 in find_livefs ()
    9990-misc-helpers.sh` line 128 in check_dev ()

`/dev/sda1` is mounted before the scripts in `/scripts/live-realpremount` are executed.

The last stage executed before `/dev/sda1` is mounted is `init-premount`.

### Debugging

Useful kernel command-line parameters:

* `debug`: Prints every command executed during initramfs to `/run/initramfs/initramfs.debug`
* `break=premount`: Drops into a shell before executing the `init-premount` stage

## Distributing

XXX: impact on mirrors' storage space?

## Installing

### Common bits

* Self-installable executable download:
  - We need to investigate if we can Cross-compile a 3rd party dd GUI
    tool such as Etcher and distribute it from our website.
  - Ask Etcher about self installable bundle.

### from Windows

#### Etcher

See below "from macOS".

<a id="rufus"></a>

#### Rufus

- [homepage](https://rufus.akeo.ie)
- CLI mode: [in progress](https://github.com/pbatard/rufus/issues/111) but not on priority list of the developer
- Complicated UX
  - too many options
  - need to download supplementary files for syslinux version
  - not clear which partition scheme to use even though it selects one
    automatically
  - user has to manually choose to install our ISOhybrided image either using
    ISO or DD mode.
- License: GnuGPL
- [[!tails_ticket 10984]]: Boots (tested in legacy mode)
  - When burnt in "DD" mode, the checksums match!
- [Recommended by Ubuntu for Windows](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-windows#1)

<img src="https://rufus.akeo.ie/pics/rufus_en.png"/>

<a id="win32-disk-imager"></a>

#### Win32 Disk Imager

[[!tails_ticket 14447]]

- Homepage: <https://sourceforge.net/projects/win32diskimager/>
- License: GPL
- Tested version: 1.0 from 2017-03-07
- Work on: Windows 7+
- UI is quite simple.
- Requires proper installing, clicking on the .exe is not enough (unlike
  UUI).
- Doesn't have a filter for ISO images in its file chooser (but I could
  choose to see all files and select an ISO image).
- Takes 30 minutes to do the copy.
- Checksum of the resulting USB stick matches the checksum of the ISO image.

<img src="https://labs.riseup.net/code/attachments/download/1885/Win32%20Disk%20Imager.png"/>

### from macOS

<a id="etcher"></a>

#### Etcher

 - Tested version: 1.3.1 from 2018-01-23
 - [homepage](https://etcher.io)
 - Windows, macOS, Linux (deb & rpm)
 - no official Debian images
 - CLI mode: [Etcher CLI](https://etcher.io/cli/) is experimental, it's a
   different executable than the GUI one, so we can suppose that it can't be run
   to launch the GUI with the right options.
 - License: Apache
 - [[!tails_ticket 11348]]: images created with Etcher boot (in legacy mode at least) and checksums match
 - [It is recommended by Ubuntu for macOS](https://tutorials.ubuntu.com/tutorial/tutorial-create-a-usb-stick-on-macos#3)
 - Requires macOS 10.9 (Mavericks) or newer
   ([which means a Mac from ~2007-2009 or newer](https://support.apple.com/kb/SP702?locale=en_US))
 - Takes 5 minutes to do the copy.
 - Has both a portable and installable version for Windows

<img src="https://etcher.io/static/screenshot.gif"/>

<a id="macos-disk-utility"></a>

#### macOS Disk Utility

- Tested version: Mac OS X Lion
- I get an error ("invalid source") when I try to either:
  - Copy a Tails 3.5 ISO image onto a USB stick.
  - Restore the disk image of a full USB stick installed using @dd@.
  - Restart the disk image of the system partition of a USB stick installed using @dd@.

### from Linux

* _GNOME Disks_ has a _Restore Disk Image_ feature that basically does
  `dd` with a nice progress bar.
* Investigate if we can get Etcher into Debian, which would allow all
  users to follow the same process.

## Upgrading

This approach does not make full, manual upgrades any simpler. For the
ideas we have to fix that other problem, see [[!tails_ticket 15281]].
