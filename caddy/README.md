# Caddy Forward Proxy Role

This Ansible role installs and configures Caddy with forward proxy support using Docker Compose.

## Requirements

- Docker and docker-compose must be installed (role has dependency on `docker` role)
- The `community.docker` Ansible collection must be installed

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

### Installation Settings

```yaml
caddy_install_dir: "/opt/caddy"
caddy_config_dir: "/etc/caddy"
caddy_site_dir: "/var/www/html"
```

Directories where Caddy files will be stored.

### Docker Settings

```yaml
caddy_docker_image: "ghcr.io/hobbsau/caddy-forwardproxy:latest"
caddy_container_name: "caddy"
caddy_restart_policy: "unless-stopped"
```

Docker image and container configuration.

### Port Mappings

```yaml
caddy_http_port: "80"
caddy_https_port: "443"
caddy_https_udp_port: "443"
```

Port mappings for HTTP, HTTPS, and HTTP/3 (QUIC).

### Caddy Configuration

```yaml
caddy_domain: "perth.amivah.com"
caddy_email: "perth@amivah.com"
```

Domain name and email for TLS certificates.

### Forward Proxy Settings

**Important:** Change these default values for security!

```yaml
caddy_proxy_username: "admin"
caddy_proxy_password: "changeme"
caddy_proxy_secret_domain: "secret.example.com"
```

Credentials and probe resistance domain for the forward proxy.

### Service Management

```yaml
caddy_enable_service: true
caddy_service_state: "started"
```

Control whether the Caddy container should be started automatically.

## Dependencies

- `docker` role (defined in meta/main.yml)

## Example Playbook

```yaml
---
- hosts: proxy_servers
  become: yes
  roles:
    - role: caddy
      vars:
        caddy_domain: "proxy.example.com"
        caddy_email: "admin@example.com"
        caddy_proxy_username: "myuser"
        caddy_proxy_password: "securepassword123"
        caddy_proxy_secret_domain: "mysecret.example.com"
```

## Security Notes

1. **Change default credentials**: Always override `caddy_proxy_username` and `caddy_proxy_password`
2. **Use Ansible Vault**: Store sensitive variables in an encrypted vault file
3. **Probe resistance**: The `caddy_proxy_secret_domain` helps hide your proxy from automated scans

## Files Created

The role creates the following structure:

```
/opt/caddy/
├── docker-compose.yml
├── conf/
│   └── Caddyfile
└── site/

/etc/caddy/
└── Caddyfile

/var/www/html/
└── (static site files)

/var/log/caddy/
└── access.log
```

## License

GPL-3.0-only

## Author Information

Created by hobbsAU
