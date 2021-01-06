[[!tag archived]]

[[!meta title="USB install and upgrade"]]

We [[!tails_ticket 11679 desc="started a process"]] of rethinking
Tails installation and upgrade process, identifying changes we can do
relatively quickly and that have a good cost/benefit ratio, and
thinking about long-term solutions.

Most of the installation issues we've identified were solved
by shipping a USB image.

[[!toc levels=3]]

<a id="problems"></a>

Problems identified in Tails installation & upgrade process
===========================================================

Tags
----

Problems below are tagged this way:

* `[fixed-by-1-big-iuk]`: would solved by a smallish change to our
  upgrade system that would allow users to automatically upgrade
  through a whole Tails series such as 3.x (this idea is also known as
  "IUKs on steroids", "1 big IUK", "endless upgrades"), i.e.
  [[!tails_ticket 15281]] and
  [[Endless_upgrades#single-squashfs-diff]]

Installation process
--------------------

* Users have to first understand a complex mental model in which they
  download an ISO image, have to use an installation program and create
  some kind of "magic USB" key.
* Users need to turn off [[UEFI Secure Boot]] to start Tails.
* There's a mess around what device is considered "removable":
  we have slightly different definitions in various places.

Upgrade process
---------------

* Regular Tails users need to go through manual upgrades twice a year.
  [fixed-by-1-big-iuk]
* It's currently not possible to autoupgrade from an older Tails
  version, i.e. It's impossible to autoupgrade from Tails 3.1 to Tails
  3.5. [fixed-by-1-big-iuk]
* IUK size is not efficient. Users have to download a big blob of data
  which can be very long over Tor.
* On upgrade failure our recovery handling is poor.
* Upon upgrades our user experience is poor.
* Manual upgrades are very complicated.
* Sometimes manual upgrades are required.
* Our upgrade system has never been audited yet.
* Because we instruct people not to use `apt upgrade` they have to wait
  for us to release bugfixes, and these are often made too late after
  the release.

Envisioned solutions to the problems that are not `fixed-by-1-big-iuk`:
[[!tails_ticket 15279]], <strike>[[!tails_ticket 15282]]</strike>,
[[!tails_ticket 7499]].

<a id="roadmap"></a>

Roadmap
=======

* improving upgrade UX: [[!tails_ticket 15281]] and
  [[Endless_upgrades#single-squashfs-diff]]
* come back to the upgrade topic later ([[!tails_ticket 15277]])

Resources
=========

* [[notes about UEFI|UEFI]]
* [[notes about GPT|usb_install_and_upgrade/gpt]]
* USB installation [[specification and design|contribute/design/installation]]
* archived [[roundup of existing tools|usb_install_and_upgrade/archive]]
