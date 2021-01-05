[[!tag archived]]

[[!toc levels=2]]

Rationale
=========

* See [[!tails_ticket 8654]].

* Our automated builds/testing/QA/CI/whatever system [[needs
  that|blueprint/automated_builds_and_tests/autobuild_specs#how-to-build-it]].

* For example, it would be good to allow building Jessie-based topic
  branches with the `feature-jessie` APT suite. Right now, the only
  way to build a topic branch based on Jessie is to first merge it
  into `feature/jessie` locally... and our Jenkins stuff doesn't
  support that, so we cannot add Jessie-based topic branches to our
  automatic ISO build setup yet.

Random ideas and notes
======================

Storing the base branch's name elsewhere
----------------------------------------

... e.g. in `config/base_branch`, as opposed to recording the
corresponding base APT suite in `config/APT_overlays`?

This may be useful for other purposes: how CI infrastructure will soon
need to know what's the base branch for a given topic branch.

**Current conclusion**: Yes. The work done in
`feature/8654-encode-apt-suite-in-git` assumes we'll be doing that.
(Update: we finally went for `config/APT_overlays.d/*`, implemented in
`feature/8654-encode-apt-suite-in-git-with-APT-overlays-dot-d`.)

Also, it could be needed if/once we use the union merge driver for
`config/APT_overlays` (when merging a base branch into another one, the
union merge driver wouldn't DTRT, and surely another merge driver
would be more suitable for `config/base_branch`; that merge driver
should ensure that the current version of the file is left as is,
which can possibly be achieved simply with `driver = /bin/true`).

Getting rid of the base APT suites
----------------------------------

Entirely get rid of the suites for the main branches: only keep a base
branch per base-major-distro-version (`tails-wheezy`, `tails-jessie`,
etc.)?

Once we stop adding packages to main branches' APT suites except at
release time, it make little sense to merge their pile of overlays
into each base suite when we release, while we can simply merge them
into e.g. `tails-wheezy`, and in turn into the release tag's APT
suite. If we go this way, we need to encode the distribution name
somewhere in Git, e.g. `config/Debian_codename`. As a bonus, if we do
that, we could even:

 * pass the content of that file to `$RUN_LB_CONFIG --distribution` in
   `auto/config`
 * possibly generate parts of `config/chroot_sources` and
   `config/chroot_apt/preferences` dynamically at build time
 * in the end, we could almost build ISOs based on Debian sid simply
   by changing a single configuration file in Git?

**Current conclusion**: No. It makes things a little bit too
complicated e.g. during freeze time for major releases: one wonders
where the overlay APT suites merged into `testing` would
be aggregated.

gitattributes
-------------

[`gitattributes(5)`](http://git-scm.com/docs/gitattributes) files
enable us to define path-specific behaviour, such as a speficic merge
driver, or filters that shall be applied upon checkin or checkout.
For what matters here, this file should be stored in `.gitattributes`
at the root of our main Git repository; whatever is defined in-tree
can be overriden locally via `$GIT_DIR/info/attributes`. This means
that we can have:

* default settings suitable for human contributors, stored in
  `.gitattributes` in Git;
* local overrides for bits of our infrastructure that may need to
  behave differently.

Git ships with some built-in filters and merge drivers, that can
directly be used by specifying what path they should apply to via
`gitattributes(5)`. However, it's a different matter whenever one
wants to use *custom* merge drivers and filters: they have to be
defined in Git configuration, which can't be stored in the repo
itself. Then, contributors who need their Git to use custom filters
and merge drivers have to add an `[include]` section to their
`.git/config`, that points to a config file:

* that defines the needed filters and merge drivers;
* that is hosted in *another* repo: otherwise, when checking out an
  untrusted branch, arbitrary untrusted code could be run e.g.
  via a `smudge` filter.

Note that the merge driver only "affects how three versions of a file
are merged when a file-level merge is necessary during git merge".
It's not going to be used at all if only one side of the merge has
modified the file that has a merge driver defined.

Merge driver for `config/APT_overlays`
--------------------------------------

What merge driver should we use for `config/APT_overlays`?

What follows assumes that we're *not* storing the base branch's APT
suite in that file.

* When doing base-branch-into-topic-branch merges in Jenkins, we'll
  probably want to use the union merge driver for `config/APT_overlays`,
  in order to resolve trivial merge conflicts by including the lines
  from *both* sides. Ideally, we should use the union merge driver
  only when the Git merge strategy being used would leave a conflict
  unresolved. To achieve this, it might be that we can use a custom
  merge driver, that first tries running `git merge-file`, and if that
  one returns a strictly positive number, then runs it again with
  `--union`.

* When manually merging a base branch into another one, the union
  merge driver is not very good: it'll introduce duplicated lines in
  `config/APT_overlays`, e.g. when merging e.g. `stable` into `devel`.
  A `clean` filter defined in `.gitattributes` might be enough to
  de-duplicate these lines.

* When manually merging a base branch into a topic branch, there are
  several sub-cases:
  - the base branch's `config/APT_overlays` has had new suites added:
    then we want to add them in the topic branch too; in this case the
    union merge driver could work, except if the base branch's
    `config/APT_overlays` also had lines removed during the last
    release;
  - the base branch's `config/APT_overlays` has had suites removed, e.g.
    during a release: then, ideally we want to remove them from the
    topic branch as well.
  It's no big deal in practice if lines that were deleted from
  `config/APT_overlays` in the base branch are still in the topic branch
  post-merge (the same packages are in the base branch's APT suite
  anyway), but it's a bit ugly and there are chances that we end up
  mistakenly re-adding the deleted lines in `config/APT_overlays` in the
  base branch when merging the topic branch in it, and then the
  release manager would merge these APT suites into the corresponding
  base APT suite at release time, potentially downgrading packages
  that have been upgraded by other merged branches.

At this point, it doesn't feel worth analyzing all other possible
cases. It seems clear that no custom merge driver would do the right
thing in all cases of merges we do manually.

**Current conclusion**:

* human contributors will handle `config/APT_overlays` the good old way,
  as any other file in our Git tree;
* we'll use the union merge driver in Jenkins.

**Update**: all this reasoning is moot since we've moved to
`config/APT_overlays.d/*`, so we don't need the union merge
driver anymore.

And later, we can reconsider if we need something more clever, e.g.:

* We might have to use a custom merge driver to force a manual
  conflict resolution for every manual merge that involves
  `config/APT_overlays`, to avoid the case when Git tries to be clever
  and makes the wrong decision.
* For Jenkins merges, we may need to investigate using the union merge
  driver only when it's really needed.

Merge driver for `config/base_branch`
-------------------------------------

What merge driver should we use for `config/base_branch`?

When merging between branches that have the same base branch, there's
no conflict, what should be done is quite obvious and then Git will
figure it out just fine.

When merging between branches that don't have the same base branch,
the cases that matter most are:

* Merging a base branch (B1) into another one (B2): as above,
  `config/base_branch` should be left unchanged in the resulting B2.

* Changing the base branch of a topic branch T, from B1 to B2: we want
  T's old base branch to be replaced by B2. 

* Merging into B2 a topic branch T which is based on B1. In practice,
  this should only happen when B1 = stable or testing, and B2 = devel,
  and then the Right Way™ to do it would instead be to:
  - either first merge T into B1 if it's ready, and then B1 into B2:
    the first step is trivial, and the second one is the "merging
    a base branch into another one" case, which was covered above;
  - or, merge B2 into T, and then T into B2: the first step is
    essentially about "changing the base branch of a topic branch"
    case, which was covered above; the second step is trivial.
  But mistakes may arise, so ideally we would cover cases when merges
  are not done in ideal order. What should happen, then, is that
  `config/base_branch` is left unchanged in B2 after the merge.

To sum up, in all cases except "changing the base branch of a topic
branch", we want to keep whatever was in the branch we're merging
into. To achieve the general case, perhaps one can define a custom
merge driver, used for `config/base_branch`, that would simply call
`git merge-file --ours` if we're merging into a base branch, and `git
merge-file` otherwise. Git will handle the "changing the base branch
of a topic branch" corner case somehow, and it's still the
responsibility of the topic branch's developer to ensure that
`config/base_branch` is correct.

**Current conclusion**: all this feels like premature optimization, or
bonus foolproof protection. We'll see how it goes in practice.
