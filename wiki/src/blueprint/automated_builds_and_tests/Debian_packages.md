[[!tag archived]]

See the
[[reproducible builds blueprint|blueprint/reproducible_builds#custom-Debian-packages]],
that documents why we want to build our Debian packages automatically,
and raises a number of questions about it.

- <http://jenkins-debian-glue.org/> (uploaded to Debian on 2015-08-22)
- [debile](http://anonscm.debian.org/gitweb/?p=pkg-debile/debile.git)
  is used by Tanglu
- [Jenkins configuration for Kamailio Debian
  Packaging](https://github.com/sipwise/kamailio-deb-jenkins):
  glueing Jenkins, pbuilder, reprepro, jjb, nginx,
  jenkins-debian-glue, piuparts, DEP-8, and more together.
- SuSE's [Open Build Service](http://openbuildservice.org/) is now
  [[!debpts open-build-service desc="in Debian"]]. Resources relevant
  to Debian package building:
  - [Build a Debian package against Debian 8.0 using Download On Demand (DoD) service](http://nibbles.halon.org.uk/2016/10/build-a-debian-package-against-debian-8-0-using-download-on-demand-dod-service/)
  - [Deploying OBS](https://suihkulokki.blogspot.com/2017/04/deploying-obs.html)
