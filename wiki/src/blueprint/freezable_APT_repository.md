[[!tag archived]]

This is about [[!tails_ticket 5926]].

[[!toc levels=3]]

<a id="todo"></a>

# TODO

1. design documentation: [[!tails_ticket 11447]]

2. misc: see subtasks of [[!tails_ticket 5926]]

# Bonus for later

## Handle handle ever-growing `references.db`

This is about [[!debbug 823629]]:: if `references.db` doesn't fit in
the memory disk cache, then at least our GC process gets very slow);
the visible consequence would be: long periods of heavy disk read, and
much slower snapshots expiration process; so we added an Icinga2 check
on the file size itself. When this problem occurs, our options are:

   * add more RAM to the VM if that's still feasible and reasonable
     (likely not)
   * reset the whole `debian` repository to an empty state (simple
     and big hammer, painful as it requires lots of coordination
     with developers)
   * compact the DB with `db5.3_dump` + `db5.3_load`: it got our
     big `debian/db/references.db` down from 5.4 GB to 1.5 GB
   * compact the DB with `DB->compact()`, using
     [a script we wrote](https://git-tails.immerda.ch/puppet-tails/tree/files/reprepro/snapshots/time_based/tails-compact-reprepro-db)
     (<https://docs.oracle.com/cd/E17076_02/html/programmer_reference/am_misc_diskspace.html>,
     <https://groups.google.com/forum/#!topic/memcachedb/uiSvgStzYNY>,
     <https://docs.oracle.com/cd/E17076_02/html/api_reference/C/dbcompact.html>):
     works on small databases, but on our big `debian` the file
     doesn't shrink

## Miscellaneous

If the chosen mirroring/snapshoting tool supported re-using the Debian
signature (e.g. <https://github.com/smira/aptly/issues/37>) then we
would only have to sign ourselves the snapshots for which need to
modify `Release` — that is: when we bump (too long freeze) or remove
(at release time) `Valid-Until` — which happens rarely and can be done
manually ⇒ we can avoid storing the signing key on an online server.

We might want to use reprepro's `Tracking:` feature in
`conf/distributions` once it's stabilized.

There's a race condition when updating a local mirror with `reprepro
update`: if it's not finished before the next dinstall + mirror sync'
end, then files `reprepro` wants to download can have disappeared from
the remote mirror, and `reprepro update` will fail (exit code = 255).
So, when the first run exits with exit code 255, let's ignore the
error and run `reprepro update` a second time.

## Handle full disk

"Reprepro uses berkeley db, which was a big mistake. The most
annoying problem not yet worked around is database corruption when
the disk runs out of space. (Luckily if it happens while
downloading packages while updating, only the files database is
affected, which is easy (though time consuming) to rebuild, see
recovery file in the documentation). *Ideally put the database on
another partition to avoid that.*" (emphasis mine, from
[reprepro(1)](https://mirrorer.alioth.debian.org/reprepro.1.html#BUGS))

Note: we have an Icinga2 check monitoring the filesystem that hosts
our APT snapshots, so in theory we should not experience this situation.

## Custom APT repository

Our custom APT repository (<http://deb.tails.boum.org/>) is not part of
our APT snapshots system: it's not needed, since we already
have a process to manage it, including creating snapshots labeled with
the Git tag.

However, longer-term, ideally we would integrate it into the new
system. It will require quite some infrastructure and code, if we want
to avoid making the release process more painful (e.g. it would be nice
if this didn't require waiting up to 6 hours until the next time-based
snapshot of our custom APT repository is created, between the time we
upload a package to it, and when we can build an ISO with it; we could
solve this by automatically creating a new snapshot whenever an APT
suite corresponding to a release branch is updated).

# Discarded

## "Remote" APT repository snapshots

... i.e. using snapshot.debian.org directly, instead of mirroring the
files ourselves.

Discarded because:

* not substantially simpler than our other designs;
* having to re-implement `Valid-Until` checking is scary;
* too much reliance on an external service.

frozen mode = when building from a tag => use snapshot.d.o with
a timestamp manually set in Git => need code that tells us what's the
dinstall timestamp used at some point during a validated build (racy
but no big deal; can kill the race condition by using a local mirror
whose update is disabled during builds)

regular mode = otherwise => use ftp.us.d.o

* Directly use snapshot.d.o + dinstall ID
  - basically replaces e.g. aptly's snapshot / "reprepro pull in new
    suite" feature
  - The fastest possible way to do a new snapshot, since we don't have
    to store nor pull anything at all.
  - Doesn't introduce a database we have to maintain and trust
    software not to ever corrupt it.
  - the dinstall ID that a given mirror was last updated can be
    retrieved from that mirror, e.g. `Archive serial` in
    <http://ftp.fr.debian.org/debian/project/trace/ftp-master.debian.org>
  - Blocker: `Valid-Until` can be invalid:
    * If we don't bump the dinstall ID at least once a week as part of
      the normal development process. Seems impractical (e.g.
      we sometimes freeze for more than a week) and too rigid.
    * When rebuilding from an old tag (old > a week).
  - But do we want to depend on snapshot.d.o that much?
    * Served from two different locations.
    * Ask weasel if we can go this way. Make it clear how much we care
      about _old_ data, e.g.:
      - For reproducible rebuild check we only care about re-building
        the last release, or the last few releases.
      - GPL requires distributing the source for at least 3 years
        after we stop distributing the binaries.
  - Whonix uses that, go look/ask for pros/cons they've seen.
  - other repos e.g. deb.tpo; we can probably handle it in a very
    ad-hoc and lightweight way, by importing the packages we want into
    our own Tails-specific APT suites, or with reprepro's mirroring
    (`pull`) feature.

- to avoid relying on browsing <http://snapshot.debian.org/> for
  getting the dinstall timestamp we'll stick into Git, we need
  a script that does the browsing _and_ validates that the determined
  timestamp is not too far away in the past.

## Partial APT repository snapshots

Discarded because:

* it raises a tricky chicken'n'egg problem: managing the list of
  packages that will be needed to build a given Git branch, and
  maintaining the set of partial APT repository snapshots that these
  branches need;
* partially snapshot'ing live APT repositories (e.g.
  security.debian.org) is racy: between the time when we build an ISO
  to get the list of packages we need to import, and the time we
  actually import them, files can have disappeared on the mirrors.

 - pro: faster sync ⇒ faster snapshots ⇒ shorter time to remediation
   However, we can have something similar with full snapshots, if we
   continuously update a temporary snapshot, and then when we need it
   we only have to stick some label onto it.
 - cons: more complex... except perhaps if we want to optimize time to
   remediation for full snapshots as described above.

### Snapshots name

For partial mirroring, their name must contain:

* Debian origin (`debian`, `debian-security`)
* Debian distribution (`sid`, `jessie`, `jessie-backports`, etc.)
* name of the Tails Git release/base branch that needs this set of
  packages

## Replace index expiration check

For the remote snapshots (snapshot.d.o) solution, we _have_ to do
that. For partial and full archive snapshots, this is optional: the
only advantage is that it allows us to _not_ periodically update
`Valid-Until` and signature.

One "solution" would be to replace `Acquire::Check-Valid-Until`:

 - runtime: we point APT sources to the regular Debian archive, no
   need to disable `Acquire::Check-Valid-Until`, we're good.
 - ISO build time: we know when we've frozen ⇒ we can tell APT not to
   do that check, and check the Release files ourselves based on the
   additional info and constraints we have; a bit risky, no right to
   fail, but not totally scary; so draft a security discussion, then
   have it reviewed

## dak, britney, merge-o-matic, debile, etc.

Overkill, and not really meant to address our needs.
Let's instead write our own :P

## Handling freeze exceptions by backporting

Another option, instead of adding/removing temporary APT pinning,
would be to backport the package we want to upgrade, and make it so it
has a version greater than the one in the time-based snapshot used by
the frozen release branch, and lower than the one in more recent
time-based snapshots. This means building and uploading the package to
the relevant custom APT suite. This is appealing, because it doesn't
require any cleanup: the upgraded package will automatically be
superseded as soon as it can be. However:

 * we would not benefit from Debian features like reproducible builds;
 * it requires either manual work and bandwidth every time, or setting
   up and maintaining infrastructure to automate the whole thing;
 * the fact that the changes *have to* go through Git, with the APT
   pinning option, helps enforcing our review'n'merge processes; one
   can do it by the book with the custom backport option too, by going
   through a topic branch and `config/APT_overlays.d/`, but it still
   conveys less historical information through Git than the APT
   pinning option;
 * anonym NACK'ed this ("Please do not underestimate the added
   overhead of having to rebuild packages for trivialities like
   this"), and intrigeri agreed.
