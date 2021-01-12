[[!tag archived]]

[[!meta title="Tails Server"]]

[[!toc levels=3]]

# Vision

Tails Server should provide a user-friendly way to start onion services that facilitate group collaboration, communication, and data sharing.

Such services are immensely helpful for working together in groups over distance. Usually they are hosted centrally by a third party. This comes with several perils: Users have to trust that the service provider protects their information and does not use it for other purposes or disclose it, and the provider poses as a single point of attack for adversaries. In contrast, a self-hosted onion service comes with several advantages:

* It automatically provides strong encryption between the clients and the server
* It provides server authentication and optionally also client authentication
* It provides anonymity for both the clients and the server
* It's decentralized, reducing the impact fo the compromise of a single system
* It works behind NATs and firewalls
* It limits attack surface

Tails Server should be usable via both a graphical user interface (GUI) and a command line interface (CLI). The interfaces would be used from within a running Tails session (in contrast to the design in the [Legacy Blueprint](https://tails.boum.org/server_edition/). The CLI solution would make it easy to administrate Tails Server remotely via SSH.
Both interfaces should make it easy for the user to install and configure services, and automatically configure the services for the use in Tails. It should be a generic solution which makes it easy to add many different services.

In addition to service specific options, the user should be able to choose:

* Whether the server's configuration and data and the onion service's keys and address are stored persistently (i.e. being restored after reboot) or not.
* Whether the service is supposed to automatically start after booting Tails.
* Whether it should allow connections from localhost
* Whether it should allow connections from the local area network (LAN).

In order to achieve this vision, the following problems have to be solved:

* Design an extendible and robust format describing the services and how they integrate into Tails.
* Installing the server software.
* Setting up the onion service, reusing an existing onion address and keys, if chosen by the user.
* Persistently storing the data, configuration, and onion service data.
* Integrating into Tails' firewall.
* Presenting the onion address and client credentials to the user in a way that s/he can easily share them with clients.
* Implementing a proper CLI and GUI to configure and activate services.

## List of services which could be nice if integrated in Tails Server

Please add to this list!

* Collaborative text editor
  * Gobby
  * Etherpad (requires web server) (no debian package)
  * [CryptPad](https://cryptpad.fr/)
* VoIP
  * Mumble
* Web server
  * Nginx
  * lighttpd
* Filesharing (requires web server)
  * Onionshare
  * NextCloud or Owncloud
  * Cozy
* Wiki (requires web server)
  * MediaWiki
  * ikiwiki
  * DokuWiki
  * MoinMoin
* Leaking platform
  * SecureDrop
  * GlobaLeaks
* XMPP
  * Prosody
  * ejabberd
* IRC
  * charybdis
  * ngIRCd
  * IRCD-Hybrid
* Media streaming
  * Icecast
* SSH
* Surveys (LimeSurvey)
  * Being able to run surveys without relying on Google Forms seems to
    be a frequent need among the Internet freedom community. The topic
    was raised twice on OTF-Talk:

    - "Secure way to run a survey?" on 2017-10-17
    - "Secure survey tool" on 2018-04-02

    In both cases the use case was to conduct anonymous surveys of a
    target audience.

    I've also been asked by another digital security trainer about the
    same thing. The use cases could also cover organizing sensitive
    events and having a better control of personally identifiable
    information, like who registered for a given security training.

# Design

Each service is defined by a separate Python module in `/usr/share/tails-server/services/`. Each service's module must contain a subclass of the `TailsService` class, which defines all the attributes and methods required by a service, e.g. to install, configure, start and stop it. If a service needs additional functionality, the subclass can override arbitrary attributes and methods of the `TailsService` base class.

Options which can be changed by the user can be defined as subclasses of `TailsServiceOption`. Default options include for example the `PersistenceOption` and the `AllowLanOption`. To add service specific options, the `TailsService.options` attribute can be overridden.

The Tails Server GUI monitors D-Bus to get notified when one of the services starts or stops. This implies that each service in Tails Server must have a systemd service which can be monitored this way.


# Implementation

Tails Server is implemented in Python 3. 


# Service Specification

The following attributes of the `TailsService` class must be overridden by all subclasses:

## Attributes

- name: The name of the service, as used in the CLI. This should be the same as the basename of the executable file.
- description: A short description of the service.
- client_application: The name of the application which can connt to this service
- documentation: A URL pointing to the service's page in the Tails documentation. For example "file:///usr/share/doc/tails/website/doc/tails_server/mumble.en.html".
- packages: A list of packages that need to be installed for this service.
- systemd_service: The name of the service's systemd service. ¹ 
- default_target_port: The default value of the service's target port (i.e. the port opened by the service on localhost), which is used if the user does not specify a custom target port.
- icon_name: The name of the icon used for the service in the GUI.


Additionally, the following attributes might be overridden:

- persistent_paths: List of paths of files and directories that should be made persistent via the Persistence option.
- options: List of the service's options.
- systemd_service: The name of the service's systemd service.
- name_in_gui: The name of the service, as displayed in the GUI.
- client_application_in_gui: The name of the application which can connect to this service, as displayed in the GUI.
- default_virtual_port: The default value of the service's virtual port (i.e. the port exposed via the onion service), which is used if the user does not specify a custom virtual port.
- connection_info: A summary of all information necessary to connect to the service
- connection_info_in_gui: The connection as it should be displayed in the GUI


## CLI options

#### info [--details]
Print a mapping of attributes of the service to their current values. With *--details*, additional attributes will be printed.
  
##### Example

    $ mumble.py info
    description: A low-latency, high quality voice chat server
    installed: true
    running: true
    published: true
    address: null
    local-port: 64738
    remote-port: 64738
    persistent-paths:
    - /etc/mumble-server.ini
    options:
      virtual-port: 64738
      server-password: TrR4WgC29nUjNIJ5o2VI
      persistence: false
      autostart: false
      allow-localhost: true
      allow-lan: false
      welcome-message: '"<br />Welcome to this server running <b>Murmur</b>.<br />Enjoy your stay!<br />"'


#### status
Print the values of the service's *installed*, *running*, and *published* attributes.

#### enable
Enables the service, which involves starting the systemd unit and creating the onion service.

#### disable
Disables the service, which involes stopping the systemd unit and removing the onion service.

#### get-option OPTION
Prints the value of the provided option.

#### set-option OPTION VALUE
Sets the provided option to the provided value.


# Obligatory Client Authentication

My current proposal is that, until we can use a Tor version with the [next generation onion services](https://gitweb.torproject.org/torspec.git/tree/proposals/224-rend-spec-ng.txt) in Tails, Tails Server should enforce the use of client authentication, i.e. it will not be shown as an option to the user and will always be turned on. We could add a somehow hidden option (maybe a command line option) to disable client authentication, so that users who know about the risk still have a way to use Tails Server without client authentication.

The reasoning for this is that users running onion services in Tails currently face an increased risk of deanonymization. In the default Tor configuration, the first Tor node that the Tor client connects to stays the same for a longer time, currently 60 days. This node is called the entry guard. The reasoning is to reduce the risk of using a bad entry node, because the entry guard is the only node in the Tor network that knows the real IP address of the Tor user. An attacker controlling the entry guard gains important information about the Tor user, which can lead to deanonymization.

Tails currently does not [persist the Tor state](https://tails.boum.org/persistent_Tor_state/), which means that Tor chooses a new entry guard after each system boot. Thus Tails users have a much higher risk to use a bad entry guard at some point, which is bad enough in itself. But when hosting onion services in Tails, this is even worse, because it is a lot easier for a bad entry guard to deanonymize onion services than normal Tor clients. For example, if an attacker knows the onion address of an onion service A and control a Tor node which is used as an entry guard, they can just block all traffic on the entry guard and try to connect to A. If A is unreachable only while they block the traffic at their Tor node, they know that it is A who is using their Tor node as an entry guard, so they know the IP address of A.

This attack requires the attacker to know the onion address of the onion service they want to deanonymize. Unfortunately, the current implementation allows attackers controlling a directory server responsible for an onion service to learn that service's onion address. This will be fixed in the next generation onion services. So once we can use the next generation onion services in Tails, it will be sufficient for Tails Server users to keep their onion address secret and only share it with users they trust. I think this will be good enough to make the client authentication optional and display a prominent warning about keeping the onion address secret in Tails Server. 

The Tor stable release 0.3.1 with next generation onion services is [planned vaguely for August 2017](https://lists.torproject.org/pipermail/tor-dev/2016-December/011725.html). Since we don't have a release schedule for Tails Server yet, we might consider waiting for Tor 0.3.1 before releasing Tails Server.

In the long term, we should come up with a compromise between the location tracking risk of persistent entry guards and the risk of deanonymization by a bad entry guard (see [persistent_Tor_state](https://tails.boum.org/persistent_Tor_state/)).

XXX: Explain how this greatly reduces the use cases in which Tails Server is useful (all clients have to use Tails; onion addresses can't be publicly advertised)
