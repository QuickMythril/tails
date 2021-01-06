[[!tag archived]]

[[!meta title="Revamp the Greeter UI"]]

**Ticket**: [[!tails_ticket 5464 desc="#5464"]]

[[!toc levels=3]]

Rationale
=========

Tails-greeter works fine, and its code in not that bad anymore, so on
this side it's now feasible to add features (e.g. [[!tails_ticket
5421]], [[!tails_ticket 5479]]).

However, the greeter UI is difficult to use, and adding more options
in the current state of things would only make things worse
usability-wise.

So, we have to improve the greeter UI to make it more ergonomic and
easier to use.

Current proposal
================

After working on a prototype and doing UX testing with NUMA [[http://en.numa.paris/]], we arrived at the idea of having two main Tails-greeter flows:

- a quick setup for veteran users
- a guided setup for new users

The result of this can be found in the [[NUMA_flow]].

We refined this on the *tails-ux* mailing list to arrive at a concrete proposal for the first screen: [[design_rationale_phase1]].

The wizard is less defined. See the bottom of [[NUMA_flow]].

Roadmap
=======

## Phase 1: "Welcome" and "Advanced" screens

### Phase 1.0 [[!tails_ticket 8230]]: basic "Welcome" and "Advanced" screens

This means including a redesigned greeter that has the same functionnalities than the current one. It would be included in Tails 3.0, so the plan is to work on that during Tails/Stretch work.

* Implement the chosen proposal in a dedicated branch of the greeter repo [[!tails_ticket 10828]]
* Update documentation
* Send software and documentation for translation on tails-l10n


### Phase 1.1 [[!tails_ticket 11643]]: add options to "Welcome" and "Advanced" screens

This phase consists of improvement of the 1st phase. It would be added in 3.X releases.

## Phase 2 [[!tails_ticket 8231]]: implement a "Take a tour" wizard

This phase as about adding a wizard to guide newcomers. It has no timing yet.

* design the wizard

Resources
=========

UI / UX documentation
---------------------

* [GNOME HIG](https://developer.gnome.org/hig/stable/)

Related tickets
---------------

* Moving stuff *out of* the greeter: [[!tails_ticket 5501]]
* [[!tails_ticket 7500]] Tails Greeter is not accessible

Past discussions
----------------

* <https://mailman.boum.org/pipermail/tails-dev/2012-March/000936.html>
* thread starting at
  <https://mailman.boum.org/pipermail/tails-dev/2012-March/000972.html>
* <https://mailman.boum.org/pipermail/tails-ux/> and expecially the [greeter mockups](https://mailman.boum.org/pipermail/tails-ux/2015-February/000256.html)

Past work
---------

* [[NUMA_flow]]
* [[mockups]]
* `feature/single_toggle_button` branch in tails-greeter repo


