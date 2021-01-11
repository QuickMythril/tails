[[!tag archived]]

* This suppose you have either a sid/experimental system with latest GNOME packages or a pbuilder experimental setup.

  * In a VM, enable experimental sources then:

        apt-get build-dep -t experimental gnome-shell
        apt-get install quilt git-buildpackage

  * For pbuilder:

        pbuilder create --distribution experimental --override-config

* clone debian git in gnome-shell-debian

      git clone https://salsa.debian.org/gnome-team/gnome-shell.git gnome-shell-debian

* create upstream/latest branch

      git co -b upstream/latest origin/upstream/latest

* clone upstream git 

      git clone https://gitlab.gnome.org/GNOME/gnome-shell.git gnome-shell-git
      git submodule update --init

* disable upstream VCS tag checking

      commit 3f53de522495a321bb962e5b9e4ddaca66957823
      Author: user <user@debian>
      Date:   Tue Apr 2 16:31:22 2019 +0200
      
          disable upstream VCS tag checking
      
      diff --git a/debian/gbp.conf b/debian/gbp.conf
      index b24011a15..904e0e5d0 100644
      --- a/debian/gbp.conf
      +++ b/debian/gbp.conf
      @@ -2,7 +2,7 @@
       pristine-tar = True
       debian-branch = debian/master
       upstream-branch = upstream/latest
      -upstream-vcs-tag = %(version)s
      +#upstream-vcs-tag = %(version)s
       
       [buildpackage]
       sign-tags = True

* import upstream repository

      gbp import-orig --verbose --upstream-version=3.33.0-4 --filter=.git --filter=.gitignore ~/Documents/gnome-shell-git/
                                                        ^
                                            increase this at each build

* disable all patches

      commit 31962cfec99808e57404a970c59202c8e40c1c76 (HEAD -> debian/master)
      Author: user <user@debian>
      Date:   Tue Apr 2 16:38:27 2019 +0200
      
          disable all debian specific patches
      
      diff --git a/debian/patches/series b/debian/patches/series
      index 2e1f1ebb9..e69de29bb 100644
      --- a/debian/patches/series
      +++ b/debian/patches/series
      @@ -1,8 +0,0 @@
      -userWidget-Fix-avatar-size.patch
      -layout-Use-custom-actor-for-uiGroup.patch
      -texture-cache-Apply-resource-scale-to-the-right-dimension.patch
      -theme-improve-legibility-of-error-messages.patch
      -st-widget-Add-missing-g_return_val_if_fail.patch
      -st-theme-node-transition-Exclude-get_new_paint_state-from.patch
      -magnifier-Fix-color-argument.patch
      -tweener-Save-handlers-on-target-and-remove-them-on-destro.patch

* build

      gbp buildpackage

  or with pbuilder:

      BUILDER=pbuilder gbp buildpackage --git-pbuilder --git-dist=experimental --git-arch=amd64 -nc

* install

      sudo dpkg -i ../gnome-shell_3.33.0-4-1_amd64.deb ../gnome-shell-common_3.33.0-4-1_all.deb
