[[!meta title="Network connection (configuration and startup)"]]

This is about [[!tails_ticket 10491]].

[[!toc levels=2]]

Current issues in Tails
=======================

* A. After Tails Greeter, it might be hard for some people to understand where
  to click on the GNOME desktop to connect to a Wi-Fi network.

* B. It's impossible to go from direct Tor connection to bridge mode in case
  you realize once in the session that you actually need bridges to connect.

* C. It's hard to know whether you need to log in through a captive portal.
  ([[!tails_ticket 5785]])

* D. There's no way of triggering Tor to reconnect after logging in through a
  captive portal, except by closing the Unsafe Browser (which is not obvious).

* E. Once cannot set up bridges if they need the Unsafe Browser (to log into a captive
  portal or to get bridges), if they close
  the Unsafe Browser (that restarts Tor which breaks Tor Launcher).
  Too bad, for non-bridge use cases one has to close the Unsafe Browser
  to make Tor connect. ([[!tails_ticket 11535]])

* F. It can be scary for people who cannot afford
  connecting without obfuscated PTs (to hide they're using Tor) to postpone
  this choice after the session is started.

* G. Bridges, firewall and proxy have to be configured again each time.
  ([[!tails_ticket 5461]])

* H. It's not clear how one is supposed to get bridges if they need some.

* I. One can't get bridges automatically if one needs some to connect.

* J. There is no visual feedback on whether the connection to Tor is making
 progress.

* K. If MAC spoofing fails but I decide that it's OK not to spoof MAC in my
  situation, then I have to reboot Tails all the way.

* L. The Unsafe Browser allows to retrieve the public IP address by a compromised amnesia user with no user interaction. ([[!tails_ticket 15635]])

* M. No audio in Unsafe Browser breaks accessible CAPTCHAs. ([[!tails_ticket 16795]])

* N. People use the Unsafe Browser to browser the Internet.

* O. A persistent network connection is associated to a specific network interface
  (via its MAC address) so it cannot be reused easily when hoping between computers
  with the same Tails. ([[!tails_ticket 10803]])

* P. People who cannot afford connecting without obfuscated PTs (to hide
  they're using Tor) have very little margin for error: if they forget
  to choose the right option in the Greeter, their last chance is to notice
  their mistake before connecting to a network (which might be automatic).

* Q. Hard to connect using PTs when the computer's hardware clock is
  not set to the current, correct UTC time ([[!tails_ticket 15548]],
  [upstream issue](https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/obfs4/-/issues/32439))

  This is one of the top
  complaints we get from censored users. tor's improvements wrt.
  accepting a consensus that's a little in the past or in the future
  should help, but will probably not fix all these problems, that
  stem from the fact Tails can't easily tell whether the hardware
  clock is in UTC or local time, combined with the fact Tails can't
  tell what the local timezone is.

Open questions
==============

  - What's left from this configuration process on the desktop after Tor is
    started? Do we allow changing or visualizing the current settings?

  - In the current mockups, to use a wired DHCP connection or a Wi-Fi network saved in persistence with the default
    settings (direct Tor, MAC spoofing), one needs to click twice. While
    in current Tails, it works automatically with no user interaction.
    Both have pros and cons.


Out of scope
============

- Adversary who blocks access to the captive portal they control once they notice
  you're using Tor: they can as well forbid your MAC address from connecting to
  their Wi-Fi AP.

- People who have to disable MAC spoofing all the time as this is pretty
  uncommon, cf. [[!tails_ticket 16385#note-5]]. As long as they can do this manually
  every time they start Tails (as they do currently), or for each new Wi-Fi network
  they connect to, that will be good enough. That is, we don't improve UX for
  this use case, but we don't make it worse either.

- Problem O: it's fully orthogonal to the other problems and the solutions to
  it are orthogonal to the solutions envisioned for the other problems.


Iterations
==========

<a id="iterations-first-batch"></a>

First batch
-----------

1. Enable "bridge mode" by default and remove it from the Greeter
   That is, start Tor Launcher on every connection to a network,
   if we never successfully connected to tor during this session,
   or if our last attempt to connect to tor during this session failed. ([[!tails_ticket 17330]])

   And then:

    - Don't restart Tor anymore when exiting the Unsafe Browser,
      otherwise this breaks Tor Launcher.
    - If time allows, we can consider removing the "Tor is ready"
      notification, now that we have feedback wrt. the status of
      connecting to Tor ([[!tails_ticket 8061]]).

   - Solves issues: B, J.
   - Improves issues:
     - P: the prompt for bridges will get in your way while connecting
       to the network, which is better than the current workflow where
       you have to remember to activate it in Tails Greeter
     - C: you know it's not worth waiting longer
     - D and E: Tor Launcher lets you retrigger tor bootstrap, either manually
       or after a timeout
   - Bonus points: makes UX closer to the one in regular Tor Browser.
   - Worsens issues: F (temporarily and for 1st time users affected by issue F,
     until they understand that the new behaviour behaves by default, all of
     the time, in they way they had to opt-in for previously).
     → Add a temporary note about the change in Tails Greeter.
   - Cost:
     - Need to deal with tor's sandbox settings (currently we disable it
       in bridge mode) or accept losing some security here.
     - How to tell Tor Launcher that last settings failed and it needs to
       prompt for manual config again. Does Tor Launcher load previous
       settings from `torrc` / via the control port, or does it store
       them somewhere itself?
     - Test suite needs quite a bit of updating wrt. waiting for Tor
       to be ready.
     - Needs new automated tests for the handling of the various failure modes
       (whether or not we start Tor Launcher again on 2nd and further connections).
     - Doc probably needs updates.

2. Persistent Tor settings — [[!tails_ticket 5461]]

   - Let's assume here that iteration 1 is done already.
   - Solves issues: G.
   - Improves issues:
       - F (increases user confidence in Tails consistently doing what they need)
       - P (not fully solved as the user still can forget
         to unlock their persistent volume in the Greeter; we could improve
         further via [[!tails_ticket 15573]])
   - Cost:
      - Needs sync'ing relevant `torrc` settings to a persistent
        file, and back.
      - Needs Tor Launcher to load these settings but that should be
        handled by iteration 1 already.
      - Needs new automated test scenarios: persisting settings
        initially, updating persistent settings (in the live
        environment and in persistent storage), clearing them up.
      - Doc needs updates.

   Shall they be global or per-network? Per-network is vastly harder
   to implement and makes UX more complex. Per-network could be useful
   for:

    - I want to hide I use Tor for *this* place → solved by iteration
      1: as long as Tor Launcher pops up and I get to choose whether
      I want to diverge from my usual, persistent settings.
    - I need to use a proxy when I'm in *this* place → solved by
      iteration 1 (same as above).
    - The ISP in *this* place blocks Tor and I'd rather not use bridges
      everywhere else as I don't need them (but it does not hurt much)
      → solved by iteration 1 (same as above).

   ⇒ No, we won't do per-network persistent Tor settings, but global ones.

   With respect to allowing the user to revisit their choices that were
   persisted: we'll always persist the last choice. We will not give the user
   the option of using different settings today without modifying
   persistent ones.

3. Automatic bridges/PTs retrieval (Moat) — [[!tails_ticket 15331]]

   - Solves issues: H, I
   - Bonus points: UX closer to Tor Browser's
   - Benefit seems marginally higher than persistent Tor settings for our personas.
   - Cost: at first sight, vastly higher than persistent Tor settings
   - Blocked by Meek (to be verified)

   While designing/implementing solutions, keep Snowflake in mind ([[!tails_ticket 5494]]):
   it might require similar kludges to Moat, so better use kludges that will work for both.

Potential extra iterations
--------------------------

Not ordered yet.

* Better UX wrt. clock & timezone — [[!tails_ticket 5774]]

  Current design & iterations probably needs an update.

  - Solves issues: Q
  - Benefit: higher than Moat (would be ridiculous to help folks get PTs
    if they can't connect to tor via these PTs)
  - Cost: to be evaluated in order to prioritize this vs. Moat

* Include configuration with default bridges/PTs — [[!tails_ticket 8825]]

  Why we want to do it: it will make Tails work out-of-the-box for
  some censored users, while currently they need to find out how to
  get their own bridges before they can even try using Tails, which
  is discouraging.

  Why it's not trivial: as long as using custom bridges requires
  typing them every time they start Tails, users will use the default
  ones. So in order not to overuse these default bridges/PTs, this
  feature requires allowing Tails users to configure their own
  bridges/PTs in a persistent manner; and/or perhaps Moat support too,
  in order to encourage them even more to use their own bridges/PTs.

  But once we have Moat and/or persistent Tor settings, this should be
  mostly trivial: removing the code we have that disables the default
  bridges/PTs condition (and encouraging to get their own bridges
  and use persistence in this context?).

   - Solves issues: I

* Support Meek bridges

  Why we want to do it: it will make Tails work in some places that
  block other kinds of bridges.

  This requires first including configuration with default
  bridges/PTs and allowing Tails users to configure their own
  bridges/PTs in a persistent manner. Otherwise, if the only default
  bridges/PTs available by default are the Meek ones, users will
  (over)use them even in situations where other kinds of bridges
  would work just fine for them.

   - Cost: low (remove code we have that disables Meek default bridges)

* Replace GNOME UI to connect to new networks with our own.

  Is this still useful given previous iterations dismiss the per-network settings approach?
  Or can we skip the "select a network" step of our mockups and jump to the
  "Tor configuration mode" once we've connected to a network?

   - Solves issues: A, F (not current mockups but doable)
   - Can probably be solved in other ways.

* Option "I want to hide the fact that I'm using Tails and use Tor bridges on every network."

   - So we can jump to manual Tor configuration directly.
   - So we can avoid probing captive portals too early.

   - Solves issues: F

* Display a locked-down browser to log into a captive portal when needed

  See blueprint on [[captive portal detection|detect_captive_portals]].

  And remove the Unsafe Browser.

  - Solves issues: C, D, E, L, N (some of then only if we require the user
    to tell this system once they have successfully logged in; some of them
    only if we can keep this window somehow open for captive portals that require
    a permanent connection to them)
  - Related to:
     - Wayland in Tails 5.0 (Bullseye) ([[!tails_ticket 12213]])
     - Problem M: audio should work in that locked-down browser

* Persistent Tor state — [[!tails_ticket 5462]]

  See blueprint on [[persistent Tor state|persistent_Tor_state]].

  Related but orthogonal.

Dismissed ideas
---------------

 - Tails suggests disabling MAC spoofing if it fails

   - Solves issues: K
   - Note that "People who have to disable MAC spoofing all the time" is
     out of scope.
   - Cost: same as moving MAC spoofing to per-network (hard to get right)

- Move "Disable networking" and MAC spoofing from per-session (Greeter)
  to per-network.
  Optional, can happen at the end or never, not needed by anything else.
  Probably the hardest to get right on the implementation side.

   - Solves issues: K
   - Makes harder: P


Process
=======

- Original post-its by Lunar:
  - <https://labs.riseup.net/code/attachments/download/1250/2015.10.02.jpg>
  - <https://mailman.boum.org/pipermail/tails-dev/2015-October/009593.html>

- Digital rewrite by Spencer:
  - <https://labs.riseup.net/code/attachments/download/1251/2015.12.04.png>
  - <https://mailman.boum.org/pipermail/tails-ux/2015-December/000812.html>

<a id="iff"></a>

- We had a session at the IFF to gather feedback on mockups. See [[!tails_ticket 11245]].
  - [flowchart behind the mockups](https://labs.riseup.net/code/attachments/download/1293/network-20160306.odg)
  - [mockups](https://tails.boum.org/contribute/how/promote/material/slides/IFF-20160306/)
  - [feedback from post-if notes](https://labs.riseup.net/code/attachments/download/1291/iff-feedback.ods)


Related work
============

At Tor
------

  - Tor Launcher can now retrieve bridges automatically ("Moat") but
    this is not integrated in Tails yet: [[!tails_ticket 15331]]
  - Tor Browser might soon discover (by trial & error) whether one needs bridges/PTs.
    This breaks the "hide that I'm using Tor" use case but makes things easier
    for everyone else. This should happen in their nightlies between 2020-09 and 2021-09.
    How will we deal with that?
  - There's a chance that Tor Launcher goes away entirely at some point:
    see discussions and schemas on
    https://trac.torproject.org/projects/tor/ticket/31286
  - [A Usability Evaluation of Tor Launcher](https://trac.torproject.org/projects/tor/wiki/doc/TorLauncherUX2016)
  - [UX testing of circumvention features of Tor Browser](https://github.com/lindanlee/circumvention-ux-tor)
  - <https://github.com/lindanlee/PETS2017-paper/blob/master/lindas-ms-paper/lindas-ms-paper.pdf>
  - Tor UX team's design of new Tor launcher: <https://marvelapp.com/3f6102d>
  - [Feedback on design decision for Tor Launcher](https://lists.torproject.org/pipermail/tbb-dev/2017-February/000473.html)
    discussion on the tbb-dev mailing list (spread over 2017-02 and 2017-03)

At Whonix
---------

  - <https://forums.whonix.org/t/graphical-gui-whonix-setup-wizard-anon-connection-wizard-technical-discussion/650/303>
  - <https://github.com/irykoon/anon-connection-wizard>
    (or: <https://github.com/Whonix/anon-connection-wizard>)
