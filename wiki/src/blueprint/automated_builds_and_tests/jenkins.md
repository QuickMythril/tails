[[!tag archived]]

[[!meta title="Automated tests implementation details"]]

See the [[design and implementation
documentation|contribute/working_together/roles/sysadmins/Jenkins]]
of our current setup.

For Jenkins resources, see [[blueprint/automated_builds_and_tests/resources]].

[[!toc levels=2]]

<a id="chain"></a>

Chaining jobs
=============

There are several plugins that allow to chain jobs that we might use to
run the test suite job following a build job of a branch.

 * Jenkins native way: it's very simple, and cannot take arguments.
   That's what weasel
   [uses](https://gitweb.torproject.org/project/jenkins/jobs.git/tree/jobs.yaml)
   for his Tor CI stuff.
 * [BuildPipeline plugin](https://wiki.jenkins-ci.org/display/JENKINS/Build+Pipeline+Plugin):
   More a visualization tool, uses the native Jenkins way of triggering
   a downstream job if one wants this trigger to be automatic.
 * [ParameterizedTrigger plugin](https://wiki.jenkins-ci.org/display/JENKINS/Parameterized+Trigger+Plugin):
   a more complete solution than the Jenkins Native way. Can pass
   arguments from one job to another, using parameters to the call of
   the downstream job, or taking them from a file from the upstream job.
   The downstream job can also be manually triggered, and in this case
   the parameters are entered through a form in the Web interface.
   Note that the latest release as of 2015-09-01 (2.28) requires
   Jenkins 1.580.1 ([[!tails_ticket 10068]])
 * [MultiJob plugin](https://wiki.jenkins-ci.org/display/JENKINS/Multijob+Plugin):
   Seems to be a complete solution too, build on the ParameterizedTrigger plugin and
   the EnvInject one. Seems a bit less deployed than the
   ParameterizedTrigger plugin.

These are all supported by JJB v0.9+.

As we'll have to pass some parameters, the ParameterizedTrigger plugin
is the best candidate for us.

Define which $OLD_ISO to test against
=====================================

It appeared in [[!tails_ticket 10117]] that this question is not so
obvious and easy to address.

The most obvious answer would be to use the previous release for all the
branches **but** feature/jessie, which would use the previously built
ISO of the same branch.

But in some occasions, an ISO can't be tested this way, because it
contains changes that affects the "set up an old Tails", like changes in
the Persistence Assistant, the Greeter, the Tails Installer or in
syslinux.

So we may need a way to encode in the Git repo that a given branch needs
to use the same value than $ISO rather than the last release as $OLD_ISO.
We could use the same kind of trick than for the APT_overlay feature:
having a file in `config/ci.d/` that if present shows that this is the
case. OTOH, we may need something a bit more complex than a simple
boolean flag. So we may rather want to check the content of a file.

But this brings concerns about the merge of the base branch in the
feature branch and how to handle conflicts. Note that at testing time,
we'll have to merge the base branch before we look at that config
setting (because for some reason the base branch might itself require
old ISO = same).

Another option that could be considered, using existing code in the repo: use the
`OLD_TAILS_ISO` flag present in `config/default.yml`: when we release we
set its value to the released ISO, and for some branch that need it we
empty this variable so that the test use the same ISO for both
`--old-iso` and `--iso`.

In the end, we will by default use the same ISO for both `--old-iso` and
`--iso`, except for the branches used to prepare releases (`devel` and
`stable`), so that we know if the upgrades are broken long before the
next release.
