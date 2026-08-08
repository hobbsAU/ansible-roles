dockermakeupdate
================

Runs a whole-host update pass over the Docker Compose projects managed by the
host's own Makefile (by default in `/opt/docker`), automating the manual
workflow:

1. `make pull` — download new images while services keep running, so downtime
   is limited to the restart itself;
2. `make down` — stop every project (the Makefile's own teardown ordering);
3. `make up` — start every project;
4. wait until every compose container is running and, where a healthcheck is
   defined, healthy;
5. `make prune` — reclaim disk space, **only** if step 4 passed.

The Makefile is treated as the single source of truth: the role never inspects
or manages it, and each host's project lists stay host-owned. Each step is a
separate `make` invocation because the Makefile selects its project group from
`$(MAKECMDGOALS)`.

Any failed step fails the play for that host immediately and leaves it as-is
for inspection. If the health gate fails, prune is skipped, so the previous
images remain available for a rollback. Prune never removes volumes
(`docker system prune` does not touch them without `--volumes`).

Requirements
------------

* Docker with the compose plugin, `make`, and a Makefile in
  `dockermakeupdate__dir` providing `pull`, `down`, `up` and `prune` targets.
* The Makefile's `prune` target must use `docker system prune -af`: without
  `-f` the confirmation prompt aborts in a non-interactive session.
* Run with `become: true`; the Makefile's embedded `sudo` is then a no-op.
* No compose project may have containers that normally sit in `exited` state —
  the health gate treats every non-running compose container as a failure.

Role Variables
--------------

| Variable | Default | Description |
| --- | --- | --- |
| `dockermakeupdate__enable` | `true` | Master switch for the role. |
| `dockermakeupdate__dir` | `/opt/docker` | Directory containing the Makefile. |
| `dockermakeupdate__prune` | `true` | Run `make prune` after a healthy update. |
| `dockermakeupdate__health_timeout` | `300` | Seconds to wait for all containers to be running and healthy. |
| `dockermakeupdate__health_delay` | `10` | Seconds between health polls. |
| `dockermakeupdate__make_timeout` | `3600` | Upper bound in seconds for a single make step (steps run async). |

Tags
----

All tasks carry the `dockermakeupdate` tag. Additional tags: `pull`, `down`,
`up`, `prune`. Preflight checks run under every tag, and the health gate runs
under both `up` and `prune`, so e.g. `--tags prune` still refuses to prune an
unhealthy host.

Dependencies
------------

None. Composes naturally with `sysupdate` — run that first so OS updates and
any reboot land before the containers are restarted:

    - hosts: dockerhosts
      become: true
      roles:
        - role: sysupdate
        - role: dockermakeupdate

Example Playbook
----------------

    - hosts: dockerhosts
      become: true
      roles:
        - role: dockermakeupdate

Pull and restart but never prune:

    - hosts: dockerhosts
      become: true
      roles:
        - role: dockermakeupdate
          dockermakeupdate__prune: false

License
-------

GPL-3.0-only
