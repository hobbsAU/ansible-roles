sysupdate
=========

Updates all packages on a host and reboots it if required.

Supports Debian/Ubuntu (`apt`) and Arch Linux (`pacman`).

Docker handling
---------------

Stopping the Docker daemon out from under running containers is disruptive, and
upgrading the Docker packages while the daemon is running leaves containers in
an inconsistent state. When Docker is present on the host, this role will:

* stop Docker **before** the upgrade, if the upgrade includes any Docker
  packages (`docker*`, `containerd*`, `runc` by default);
* stop Docker **before** a reboot, so containers shut down cleanly rather than
  being killed by the reboot;
* start Docker **after** the upgrade and/or reboot.

`docker.socket` is stopped before `docker.service` so socket activation cannot
bring the daemon straight back up, and they are started again in reverse order.

Docker is only started again if it was running before the role touched it, so a
deliberately stopped daemon stays stopped.

Requirements
------------

None beyond a systemd-based host. Docker handling is skipped automatically on
hosts where no Docker units are installed.

Role Variables
--------------

| Variable | Default | Description |
| --- | --- | --- |
| `sysupdate__enable` | `true` | Master switch for the role. |
| `sysupdate__reboot` | `true` | Reboot the host if the update requires it. |
| `sysupdate__docker_manage` | `true` | Stop/start Docker around upgrades and reboots. |
| `sysupdate__docker_units` | `[docker.socket, docker.service]` | Units to stop, in order. Started again in reverse. |
| `sysupdate__docker_packages` | `[docker, containerd, runc]` | Package name prefixes that count as a Docker upgrade. |

Tags
----

All tasks carry the `sysupdate` tag. Additional tags: `apt`, `pacman`, `docker`,
`reboot`.

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: servers
      become: true
      roles:
        - role: sysupdate

Update everything but never reboot, and leave Docker alone:

    - hosts: servers
      become: true
      roles:
        - role: sysupdate
          sysupdate__reboot: false
          sysupdate__docker_manage: false

License
-------

BSD
