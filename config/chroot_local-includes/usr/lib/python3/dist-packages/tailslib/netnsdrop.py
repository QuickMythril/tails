#!/usr/bin/env python3
"""
This module is useful for all those scripts that are meant to run a specific application inside a network namespace.

This functions make many assumptions about the working of it; that's in the hope that those scripts will keep
a somewhat similar structure. This is:
    - the netns has already been created, of course
    - somewhere in /etc/sudoers.d/ the wrapper can be run as root
    - the systemd user unit tails-a11y-proxy-netns@$NETNS is running
"""
import os
import logging
import sh

from tailslib.gnome import gnome_env_vars
from tailslib import LIVE_USERNAME


def run_in_netns(*args, netns, user="amnesia", root="/", bind_mounts=[], flatpak_info: str = None, app_id: str = None):
    # base bwrap sharing most of the system
    bwrap = ["bwrap"]

    if flatpak_info and root == "/":
        bwrap += [
             "--proc", "/proc",
             "--dev", "/dev",
             # TODO: We might be able to drop some of these bindings
             "--bind", "/bin", "/bin",
             "--bind", "/etc", "/etc",
             "--bind", "/home", "/home",
             "--bind", "/lib", "/lib",
             "--bind", "/lib64", "/lib64",
             "--bind", "/live", "/live",
             "--bind", "/media", "/media",
             "--bind", "/tmp", "/tmp",
             "--bind", "/usr", "/usr",
             "--bind", "/run", "/run",
             "--bind", "/sbin", "/sbin",
             "--bind", "/sys", "/sys",
             "--bind", "/var", "/var",
        ]
    else:
        bwrap += ["--bind", root, "/", "--proc", "/proc", "--dev", "/dev"]

    if flatpak_info:
        bwrap += ["--bind", flatpak_info, "/.flatpak-info"]

    if app_id:
        bwrap += ["--bind", f"/run/user/1000/doc/by-app/{app_id}", "/run/user/1000/doc"]

    for src, dest in bind_mounts:
        bwrap += ["--bind", src, dest]
    # passes data to us
    bwrap += [
        "--bind",
        os.path.join("/tmp/netns-specific/", netns),
        "/tmp/shared-with-me/",
    ]
    # hide data not for us
    bwrap += ["--tmpfs", "/tmp/netns-specific/"]

    ch_netns = ["ip", "netns", "exec", netns]
    runuser = ["/sbin/runuser", "-u", LIVE_USERNAME]
    envcmd = [
        "/usr/bin/env", "--",
        *gnome_env_vars(),
        "AT_SPI_BUS_ADDRESS=unix:path=/tmp/shared-with-me/at.sock",
        "IBUS_ADDRESS=unix:path=/tmp/shared-with-me/ibus.sock",
    ]
    # We run tca with several wrappers to accomplish our privilege-isolation-magic:
    # connect_drop: opens a privileged file and pass FD to new process
    # ch_netns: enter the new namespace
    # runuser: change back to unprivileged user
    # bwrap: this is probably the most complicated; what it does is sharing /tmp/netns-specific/$NETNS on
    # /tmp/shared-with-me/ and hide /tmp/netns-specific/ . The result is that TCA will be able to access
    # sockets that would otherwise be unreachable. See also tails-{a11y,ibus}-proxy-netns@.service
    # envcmd: set the "right" environment; this means getting all "normal" gnome variables, AND clarifying
    #         where is the {a11y,ibus} bus, which is related to bwrap

    cmd = [*ch_netns, *runuser, "--", *bwrap, "--", *envcmd, *args]
    logging.info("Running %s", cmd)
    os.execvp(cmd[0], cmd)


def run(
    real_executable: str,
    netns: str,
    wrapper_executable: str,
    keep_env=True,
    app_id: str = None,
    flatpak_info: str = None,
    extra_env={},
    extra_args=[],
):
    if os.getuid() == 0:
        run_in_netns(real_executable, *extra_args, netns=netns, app_id=app_id, flatpak_info=flatpak_info)
    else:
        env = os.environ.copy() if keep_env else {}
        env.update(extra_env)
        args = ["sudo", "--non-interactive", wrapper_executable] + extra_args
        os.execvpe(args[0], args, env=env)
