[[!meta title="Endless upgrades"]]

Currently automatic upgrades have the limitation that only some N
number of them can be performed in a row before the system partition
runs out of space and automatic upgrades cannot be done further, but a
full, manual upgrade is needed.

Automatic upgrades should be possible forever. This would:

  - Improve UX as currently full upgrades are one of the most complicated and
    long scenario, requiring at least 2 USB sticks and 2 restarts.

  - Improve security by eliminating the need for recurring verifications
    of ISO images and reducing cross-contamination by limiting the
    number of times you might want to clone or rely on another operating
    system for downloading or upgrading.

[[!toc levels=2]]

# Different approaches to endless upgrades

While examining these approaches, let's forget about IUKs for a while,
and only consider full automatic upgrades ([[!tails_ticket 7499]]):

## Extract upgrade from ISO

Keeping our current partition layout and filesystems, a full upgrade of
a running system can be done by extracting the required parts from the
new version's .iso. Here we'd need at least 3 times the size of an
installation available:

1. one for the old, running installation
2. one for the new ISO
3. one for the extracted contents of the new ISO

We would unlink the old squashfs, kernel, initrd etc. then copying in
their place new version's ones, so the new version will run next time
we reboot.

### Disk images instead of ISOs

Note that if we switch to using disk images as the primary way to
install Tails ([[!tails_ticket 8550]], comment 9) we can similarly
extract the needed parts just like above: replace "(ISO|.iso)" with
"disk image" and it still works.

## Streaming decompression

An improved version of the above idea would be to serve "upgrade
packs" using some compression method friendly to streaming
decompression, so the need to download a the full archive (ISO or disk
image above) is avoided, which reduces the amount of temporary disk
space needed from 3 to 2 times the size of an installation when
performing the upgrade.

## ISOBoot

Grub and syslinux supports booting directly from an ISO so we could
switch to a strategy where Tails USB/SD installation means that we
dump the ISO image into the system partition, and configure the
bootloader to boot from it. If we make the system partition large
enough to store two ISOs (= 2 times the size of an installation, when
comparing o the above methods) we can keep the older, running version
in place while downloading the new one, and then safely switch to the
new one at next boot. Since the old version is kept, there's a
fallback in case the new version doesn't boot. Older versions can be
cleaned up at the next upgrade.

Depending on how Grub/syslinux does the ISOBoot, this may make all
running Tails instances more consistent, i.e. we now do not have the
three cases of what type of medium Tails has booted from: DVD; USB
drive; or SD card -- in all cases we have a ISO9660 filesystem. OTOH,
the magic employed for the ISOBoot may hide too much about underlying
real device, which we still probably will need information about.

Some more details (some perhaps wrong) can be read in comment 16 on
[[!tails_ticket 7496]].

## Apply upgrade in initramfs

By storing the ISO (or disk image) that the upgrade is gonna be
extracted from on a scratch partition, and then apply the upgrade in
initramfs on next boot, we only need 2 times the size of an
installation in total, and can safely download the ISO to the scratch
partition while keeping the system partition read-only.

Ideally, let's also save the files used to authenticate the upgrade on
the scratch partition, and make check the authenticity during
initramfs, before starting the upgrade.

Also, with the scratch partition we will never have to mount it
read-write outside of initramfs, it can be made read-only in a
slightly stronger sense on the block dev level. This is not really a
security feature, but more a foolproof things, but why not?

<a id="non-nih"></a>

## How others do i.e. non-NIH solutions

This survey will be updated in a while with [[!tails_ticket 15277]].

* yocto project's
  [comparison of system update mechanisms](https://wiki.yoctoproject.org/wiki/System_Update)
* [RAUC](https://rauc.readthedocs.io/en/latest/)
  - manages
    [boot loader](https://rauc.readthedocs.io/en/latest/integration.html#interfacing-with-the-bootloader)
    and A/B partition setups, e.g.
    [GRUB](https://rauc.readthedocs.io/en/latest/integration.html#grub)
    ([example config file](https://github.com/rauc/rauc/blob/master/contrib/grub.conf))
    and
    [EFI](https://rauc.readthedocs.io/en/latest/integration.html#efi)
  - systemd integration and D-Bus API
  - super flexible
  - no support for binary delta updates yet, but there's
    a [RFC for casync support](https://github.com/rauc/rauc/pull/217)
    which downloads only missing bits and downloads/applies with
    streaming (no intermediate download of images)
  - ITP: [[!debbug 916210]]
* [Qt's Over-The-Air Update](https://doc.qt.io/QtOTA/) aka. QtOTA,
  that uses OSTree
* XXX: other OSTree based designs/implementations?
* XXX: other [casync](http://0pointer.net/blog/casync-a-tool-for-distributing-file-system-images.html) ([website](https://github.com/systemd/casync))
  based designs/implementations?
* XXX: how efficient is casync with SquashFS? in other words, do we
  need to unpack the rootfs on the target system partition?
* Chrome OS keeps the running system partition read-only, has _two_
  system partitions, and the update is applied to the non-running one.
  This has nice additional properties like allowing one to rollback if
  the upgraded system doesn't start properly. More information about
  their design and implementation:
  - [disk format](https://www.chromium.org/chromium-os/chromiumos-design-docs/disk-format)
  - [file system and autoupdate system](https://www.chromium.org/chromium-os/chromiumos-design-docs/filesystem-autoupdate)
  - [Android's A/B System Updates](https://source.android.com/devices/tech/ota/ab_updates.html)
* [Endless ostree builder](https://github.com/cosimoc/deb-ostree-builder)
* [[!debbug 824649 desc=" ostree: document how to prepare and update a .deb-based system root"]]

### Not suitable

(but could be good sources of inspiration!)

* EndlessOS'
  [OSTree based upgrader](https://github.com/endlessm/eos-updater)
  - supports separate poll/fetch/apply operations (so presumably we
    could make the relevant partition read-write only after fetching,
    as long a we can fetch to a tmpfs)
  - daemon + D-Bus API
  - systemd integration
  - supports Flatpak
  - likely too many EndlessOS-specific assumptions… and written in
    C so difficult to adapt to our needs
* [mender](https://mender.io/): downloads full update
* [swabic's swupdate](https://sbabic.github.io/swupdate/): downloads
  full update; binary delta updates are
  [on the roadmap](https://sbabic.github.io/swupdate/roadmap.html#binary-delta-updates)

# Auxiliary ideas

## Remove SYSLINUX from USB images: use GRUB for legacy boot

See [[!tails_ticket 17815]] for the rationale.

Doing this move in isolation would have a very unfavorable cost/benefit, but if
revamping our image build & upgrade system lead us to rework in depth, or even
replace, most of the affected software components, it could be a good
opportunity to do this extra work.

And actually, some of the options for [[!tails_ticket 15277]] require
integration with bootloaders, and already support GRUB but not syslinux, so it's
possible we eventually _have to_ fully migrate USB images to GRUB.

## Read-write system partition while the network is enabled

Currently we keep the system partition read-only as long as the
network is enabled. E.g. we download IUKs into the tmpfs, and when
it's finished we disable the network and only then remount the system
partition read-write to apply the upgrade.

This is problematic for full upgrades, since we cannot assume that
users' systems has over 1 GiB of free RAM available but need to
download it to disk, but cannot use the system partition. In the
"extract upgrade from ISO/Disk image" case we can simply introduce a
scratch partition where the temporary download is stored without loss
of disk usage efficiency (we still need 3 times an installation). But
for the ISOBoot and streaming decompression cases we'd then go from 2
times to 3 times the size of an installation.

It might be worth having a discussion about whether preventing the
network to be used while the system partition is mounted read-write
actually brings us any security. After all, if the system is
compromised while downloading the upgrade, it will still be
compromised when the download is finished and the system partition is
remounted read-write, and it can infect that part then.

Note that with A/B system updates this discussion is moot: the
bootloader configuration update is the only part of the process that
requires read-write access.

## What about IUKs?

If we want to support IUKs at the same time as full upgrades, we need
to allocate even more space to the system partition. Also, we need to
carefully consider the UX part of this.

For instance, we could always give users the choice to do a full or
incremental upgrade unless installing the incremental upgrade will
result in too little disk space remaining for a full upgrade to be
done *next* time -- in this case we only allow full upgrades, to
prevent users from locking themselves in a situation where they cannot
upgrade further. When both options are available, we could give users
the suggestion that they should do a full upgrade if they currently
have a lot of time and/or a fast connection.

## Self-contained verification

An interesting option for Tails installation verification
([[!tails_ticket 7496]]) is to contain all the bits needed to verify
an installation's integrity. For instance, in the ISOBoot case we'd
include the .sig for the ISO on as well as the .iso, so an external
verifier simply can verify the .sig instead of needing an external
known-good .iso to compare with.

The ISOBoot case is the simplest, probably, as the other methods would
require signed manifests of files with the expected hashes (or
similar), which of course is not such a big deal to provide.

The ISOBoot case would still require a manifest of files we extract
from the ISO (bootloader code and configuration), but indeed that
manifest could be in the ISO itself, and thus its authenticity and
integrity would be signed/verified at the same time as the ISO.

<a id="iuks-on-steroids"</a>

<a id="single-squashfs-diff"></a>

# Temporary stop gap: stack one single SquashFS diff when upgrading

(This idea was originally conceived in the comments of [[!tails_ticket
11131]].)

Without any major redesign of our current incremental upgrade system
(i.e. comparatively cheap) we can allow users upgrade only through
IUKs for much longer, probably throughout a whole Tails series,
e.g. all of Tails 2.x, which we'll use for our examples below since we
moved to 3.x already so we have all data we need to test this idea.

## Basic idea

### Inside Tails

* Tails Upgrader fetches the UDF for the version of Tails that was
  originally installed (instead of the version of the running Tails),
* We remove any previous IUK (and reference to it in `Tails.module`)
  when a new IUK is installed.

### Release management

When we release version M.N, then, for all previous versions M.X since
M.0, we generate a M.X_to_M.N IUK.

(Actually, it is not necessary to choose the first release of a series
(like M.0) as the "synchronization point". We could add another one
half way through the series, or make every tenth release a
synchronization point, or we could do it when when the IUK simply
grows too big. We have lots of options to balance this according to
our needs, but the first release of a series seems like a technically
reasonable choice according to the data we have for the 2.x series
(see below), but also nice from the user's PoV if the only time a
manual upgrade is needed is when upgrading between series.)

### Example

1. I install Tails 2.2 on a USB stick.
2. Later when Tails 2.3 is released I upgrade to it via the 2.2_to_2.3
   IUK (i.e. identical to our original scheme).
3. When Tails 2.4 is released I upgrade to it via the 2.2_to_2.4 IUK
   (whereas in our original scheme we would stack 2.3_to_2.4 on top of
   2.2_to_2.3) and remove the 2.2_to_2.3 IUK (whereas in our original scheme
   we never remove IUKs).

Notice how step 3 can be repeated for each new release, so that we in
the end reach the final release of the series, Tails 2.12. And notice
how we in step 1 could have installed any 2.x release.

## Problems due to IUK size

We'll be dealing with larger IUKs (because generally more and more
changes accumulate between different Tails versions) and only have one
present at a time, with the exception being while we are installing a
new IUK (then two will be present). Let's look at the IUK sizes
towards the end of the 2.x series as if the last manual install was
for Tails 2.0, which is the excepted worst case:

    569M Tails_i386_2.0_to_2.9.iuk
    678M Tails_i386_2.0_to_2.10.iuk
    682M Tails_i386_2.0_to_2.11.iuk
    634M Tails_i386_2.0_to_2.12.iuk

The IUK size is involved in at least four concerns:

* Disk space needs on mirrors: for 2.x there were 14 non-rc/beta/alpha
  Tails releases, so there would be 13 IUKs for the last release
  (2.12). So using the worst-case as the average case we get the upper
  bound of the space needs on each mirror: 14*682 MB ~= 10 GB.
* Disk space needs on the Tails system partition: we need to be able
  to store two large IUKs. Apparently the worst case for 2.x is the
  2.10 to 2.11 upgrade if 2.0 was the version originally installed:
  - The 2.0 installation itself uses 1082 MB, so upgraded to 2.10 the
    total usage is 1082 MB + 678 MB = 1760 MB.
  - Due to the Upgrader requiring 3x the size of the IUK on the Tails
    system partition, the actual requirement is 1760 MB + 3*682 MB =
    3806 MB of free disk space. That wouldn't have worked during the
    2.x times, when the system partition was 2.5 GB, and it barely
    would work with our current 4.0 GB partition. OTOH, during the 2.x
    series we shipped two kernels, while we don't in 3.x, so we have
    that in our favor.
  - When both IUKs are present at the same time (i.e. before rebooting
    after having applied the upgrade) the disk usage is 1760 MB + 682
    MB = 2442 MB.
  - After the old IUK is purged the disk usage is down to 2442 MB -
    678 MB = 1764 MB.
* Memory needs:
  - While performing the upgrade, 2x the size of the IUK
    of memory is needed, so 2*682 MB = 1364 MB. On a system with 2 GB of
    memory, a fresh boot of Tails pre-4.0 devel branch, even with
    [[!tails_ticket 12092]] fixed, has 900 MB of free memory
    (according to `check_free_memory()`'s calculation in
    `config/chroot_local-includes/usr/local/bin/tails-upgrade-frontend-wrapper`)
    so the upgrade would fail.
  - In the same conditions, Tails 3.15 has 672 MB of free memory, which
    allowed to apply every automatic upgrade if, and only if, one never
    skipped any: most 3.N → 3.N+2 automatic upgrades would fail with
    2 GB of RAM.
  - So this is a regression for users with 2 GB memory who never skip
    any upgrade. Those who already skipped upgrades occasionally
    already could not upgrade automatically in Tails 3.x, because we
    started advertising upgrades from N to N+2, to improve UX for
    those that have enough RAM to apply them directly (no need to
    apply 2 upgrades in a row when the user has skipped one). As we
    can see, this move also made UX worse for users with smaller
    amounts of RAM: they have to do a manual upgrade, which is probably
    more painful, for most users, than 2 automatic upgrades.
  - We can solve this regression by changing the format of the IUKs
    ([[!tails_ticket 6876]]); we should coordinate this with other changes
    that will break automated upgrades from Tails N to N+1, such as
    the migration to overlayfs ([[!tails_ticket 9373]]).
* Bandwidth needs of the RM. Uploading 10 GB of IUKs can be a pain for
  some of us, but that can be solved by making it possible to
  generate IUKs on lizard (and then compare them with the ones you
  generated locally. Thanks reproducibility!): [[!tails_ticket 15297]].

## Support upgrading very old Tails

XXX: It seems that we do want to support skipping more than one Tails
release. See the discussion on [[!tails_ticket 17069]].

We probably do not want to support upgrading very old (e.g. from six
months ago) Tails installations because our signing key might have
been updated in the meantime, and/or some critical update to Tails
Upgrader (e.g. UDF version). So unless we want to spend a lot of
resources on solving these problems, which roughly translates to "you
can take long breaks from Tails", let's guarantee our current
"you can at most skip one *planned* release" promise, and
optimistically support older versions whose key and Tails Upgrader are
still ok.

## Download requirements

tl;dr: for 2.x the new scheme would have required downloading 50% more
data than the original scheme.

### 2.x stats for original IUK scheme

Assumptions:

 * a 4 GB Tails system partition.

It would look like this:

    1082M   tails-i386-2.0.iso
    153M    Tails_i386_2.0_to_2.0.1.iuk
    315M    Tails_i386_2.0.1_to_2.2.iuk
    104M    Tails_i386_2.2_to_2.2.1.iuk
    258M    Tails_i386_2.2.1_to_2.3.iuk
    207M    Tails_i386_2.3_to_2.4.iuk
    324M    Tails_i386_2.4_to_2.5.iuk
    363M    Tails_i386_2.5_to_2.6.iuk
    328M    Tails_i386_2.6_to_2.7.iuk
    197M    Tails_i386_2.7_to_2.7.1.iuk
    176M    Tails_i386_2.7.1_to_2.9.1.iuk
    1153M   tails-i386-2.10.iso
    300M    Tails_i386_2.10_to_2.11.iuk
    296M    Tails_i386_2.11_to_2.12.iuk

Total: 5256 MB

### 2.x stats for 1BigIUK scheme

Assumptions:

 * a 4 GB Tails system partition.
 * original installing 2.0 creates the largest IUKs.

It would look like this:

    1082M   tails-i386-2.0.iso
    153M    Tails_i386_2.0_to_2.0.1.iuk
    388M    Tails_i386_2.0_to_2.2.iuk
    395M    Tails_i386_2.0_to_2.2.1.iuk
    434M    Tails_i386_2.0_to_2.3.iuk
    462M    Tails_i386_2.0_to_2.4.iuk
    515M    Tails_i386_2.0_to_2.5.iuk
    590M    Tails_i386_2.0_to_2.6.iuk
    597M    Tails_i386_2.0_to_2.7.iuk
    621M    Tails_i386_2.0_to_2.7.1.iuk
    622M    Tails_i386_2.0_to_2.9.1.iuk
    678M    Tails_i386_2.0_to_2.10.iuk
    682M    Tails_i386_2.0_to_2.11.iuk
    634M    Tails_i386_2.0_to_2.12.iuk

Total: 7853 MB

### FWIW, IUK sizes for 3.x

    200M    Tails_amd64_3.0_to_3.1.iuk
    278M    Tails_amd64_3.1_to_3.2.iuk
    260M    Tails_amd64_3.2_to_3.3.iuk
    177M    Tails_amd64_3.3_to_3.4.iuk
    213M    Tails_amd64_3.4_to_3.5.iuk

<a id="single-squashfs-diff-deployment"></a>

## Deployment

Assume we first ship in Tails version N~ the new Upgrader that supports
[[!tails_ticket 15281 desc="Endless automatic upgrades"]]. The initial
plan is N = 4.2.

When we release Tails version N:

 - We publish the following UDFs:

   - `/upgrade/v1/Tails/OLD` for every OLD = 4.x << N~,
     which advertise full and incremental upgrades to version N.

   - `/upgrade/v2/Tails/OLD` for every OLD = 4.x << N,
     which advertise full and incremental upgrades to version N.
     This includes `/upgrade/v2/Tails/N~*`.

   - `/upgrade/v2/Tails/N` and `/upgrade/v2/Tails/N+1`,
     which say there is no upgrade available.

 - We publish IUKs v1 that allow upgrading OLD = 4.x << N~
   to version N.

 - Tails version OLD << N~ uses the old Upgrader, so it fetches its UDF
   from `/upgrade/v1/Tails/OLD` and learns about the full and incremental
   upgrades to version N.

 - Tails version N~ and N uses the new Upgrader.
   We can distinguish 2 cases:

   - Either initial-install-version << N: the Upgrader fetches the
     `/upgrade/v2/Tails/X` UDF, with X = initial-install-version << N,
     that advertises an upgrade to version N.

     Then, either Tails is running version N already, and then the
     Upgrader concludes Tails is up-to-date. Or Tails is running N~*,
     and it can be automatically upgraded to N.

     XXX: ensure this logic is implemented, i.e.
     the Upgrader won't try to "upgrade" an already up-to-date Tails.

   - Or initial-install-version >= N: the Upgrader fetches the
     `/upgrade/v2/Tails/X` UDF, with X >= N, that says there is no
     upgrade available.

When we release Tails version N+1:

 - We publish the following UDFs:

   - `/upgrade/v1/Tails/OLD`, for every OLD = 4.x << N, are updated to
     advertise the full upgrade to N+1 instead of to N.

     On top of that, UX will tell RMs whether we should also keep
     advertising the incremental upgrade to N, so that users can
     automatically upgrade to N, reboot, and from there automatically
     upgrade to N+1. This boils down to: does one single full upgrade
     provide better UX than two automatic upgrades in a row?

   - `/upgrade/v2/Tails/OLD` for every OLD == initial-install-version << N,
     which advertise full and incremental upgrades to version N+1.
     This includes `/upgrade/v2/Tails/N~*`.

   - `/upgrade/v2/Tails/N`, which advertises the incremental and full
     upgrades to N+1.

   - `/upgrade/v2/Tails/N+1`, which says there is no
     upgrade available.

 - We publish IUKs v2 that can upgrade to N+1 any device where any 4.x
   was initially installed, as long as it was already upgraded to N
   (and thus has the new Upgrader).

   For example, if N = 4.2, we publish IUKs from 4.0, 4.1, and 4.2
   to N+1 = 4.3.

 - We publish no IUK v1: users of Tails << N~ must first automatically
   upgrade to version N, before they can automatically upgrade to N+1
   and newer. Alternatively, they can do a manual (full) upgrade
   to N+1.

 - Tails version OLD << N~ uses the old Upgrader, so it fetches its UDF
   from `/upgrade/v1/Tails/OLD` and learns about the full upgrade to
   version N+1 (and possibly the incremental upgrade to version N).

 - Tails versions N~* and N use the new Upgrader. Depending on
   initial-install-version, it fetches `/upgrade/v2/Tails/X` with
   X <= N. All such UDFs advertise the incremental and full upgrades to N+1.

 - Tails version N+1 uses the new Upgrader, so:

   - If initial-install-version << N+1, the Upgrader fetches
     `/upgrade/v2/Tails/X` with X <= N. All such UDFs advertise an
     "upgrade" to version N+1; given Tails is running version N+1
     already, the Upgrader concludes Tails is up-to-date.

   - If initial-install-version = N+1, the Upgrader fetches
     `/upgrade/v2/Tails/N+1`, which says there is no upgrade available.
