# Ansible Roles

## Description
This is a repository of reusable ansible roles for automating common system activities. Roles can be used for provisioning and maintenance.

All roles are contained within one git repository following the ansible monorepo guidance. The roles have been made as generic as possible.

## Requirements
Ansible => 2.9

## Install
Your `requirements.yml` is used by the `ansible-galaxy` tool to understand what sources to use. It should list *this* github repository as the source.

Note: you can extend this file to pull from multiple sources.

### Create requirements.yml
```yaml
---
- src: git://github.com/hobbsAU/ansible-roles.git
  name: hobbsAU
  scm: git
  version: master
```

### Install with ansible-galaxy
```bash
$ ansible-galaxy install -r requirements.yml
```

## Usage
See [Examples](#examples) for extended usage.

Use the roles within a play as per the following example.
```yaml
---
# File: System update
# Desc: Play for updating systems

- hosts: "{{ target }}"
  gather_facts: true
  become: true
  
  roles:
    - hobbsAU/sysupdate
```

## Examples

### Provisioning a Hetzner Cloud VM

This example demonstrates how to provision and configure a VM on Hetzner Cloud from scratch.

#### Step 1: Create userdata.yml

Create a cloud-init configuration file for initial setup:

```yaml
#cloud-config
users:
  - name: yourusername
    groups: users, admin, sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD... your-public-key-here

package_upgrade: true
```

#### Step 2: Provision VM with hcloud CLI

```bash
# Create the server
hcloud server create --name server1 \
  --image debian-13 \
  --type cx23 \
  --ssh-key <yourkey> \
  --location nbg1 \
  --user-data-from-file userdata.yml

# Optional: Create and attach a volume
hcloud volume create --name server1-data --size 100 --location nbg1
hcloud volume attach --server server1 server1-data

# Optional: Create and assign a floating IP
hcloud floating-ip create --type ipv4 --home-location nbg1 --name server1-ip
hcloud floating-ip assign server1-ip server1
```

#### Step 3: Configure Ansible Inventory

Create `inventory/hetzner.yml`:

```yaml
all:
  children:
    hetzner_vms:
      hosts:
        xde1:
          ansible_host: <server-ip-address>
          ansible_user: yourusername
          ansible_python_interpreter: /usr/bin/python3
          
          # Base user configuration
          base_user_name: yourusername
          base_user_groups: ['sudo', 'docker', 'wireguard']
          
          # Hetzner-specific settings
          hetzner_automount: true
          hetzner_floatingip: true
          hetzner_floating_ip: "<floating-ip-address>"
          
          # Docker configuration
          docker_users: ['yourusername']
          
          # WireGuard configuration
          wireguard_interface: wg0
          wireguard_listen_port: 51820
          wireguard_address: "10.10.0.1/24"
```

#### Step 4: Create Ansible Playbook

Create `playbooks/hetzner-provision.yml`:

```yaml
---
- name: Provision Hetzner Cloud VM
  hosts: hetzner_vms
  gather_facts: true
  become: true
  
  roles:
    - role: hobbsAU/sysbase
      tags: ['sysbase', 'base']
      
    - role: hobbsAU/hetzner
      tags: ['hetzner']
      
    - role: hobbsAU/docker
      tags: ['docker']
      
    - role: hobbsAU/wireguard
      tags: ['wireguard', 'vpn']
```

#### Step 5: Create Host Variables (Optional)

For more complex configurations, create `host_vars/xde1.yml`:

```yaml
---
# System base configuration
base_install_software: true
base_config_sshd: true
base_config_fail2ban: true
base_harden_system: true
base_autopdate_system: true

# Additional packages to install
base_packages:
  - vim
  - htop
  - curl
  - wget
  - git
  - rsync

# SSH hardening
base_sshd_port: "22"
base_sshd_listen_address: "0.0.0.0"

# Sysctl tweaks for Docker and WireGuard
base_sysctl_overrides:
  - { name: "net.ipv4.ip_forward", value: "1" }
  - { name: "net.ipv6.conf.all.forwarding", value: "1" }

# Docker daemon configuration
docker_daemon_options:
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "3"

# WireGuard peers (add your client configurations)
wireguard_peers:
  - name: laptop
    public_key: "client-public-key-here"
    allowed_ips: "10.10.0.2/32"
  - name: phone
    public_key: "client-public-key-here"
    allowed_ips: "10.10.0.3/32"
```

#### Step 6: Run Ansible Playbook

```bash
# Test connection
ansible hetzner_vms -i inventory/hetzner.yml -m ping

# Run the full playbook
ansible-playbook -i inventory/hetzner.yml playbooks/hetzner-provision.yml

# Run with verbose output
ansible-playbook -i inventory/hetzner.yml playbooks/hetzner-provision.yml -v

# Run only specific roles using tags
ansible-playbook -i inventory/hetzner.yml playbooks/hetzner-provision.yml --tags "sysbase,docker"

# Run in check mode (dry-run)
ansible-playbook -i inventory/hetzner.yml playbooks/hetzner-provision.yml --check

# Run and limit to specific host
ansible-playbook -i inventory/hetzner.yml playbooks/hetzner-provision.yml --limit xde1
```

#### What This Setup Provides

- **sysbase**: System hardening, fail2ban, auto-updates, SSH configuration, user setup
- **hetzner**: Automatic volume mounting, floating IP configuration, Hetzner-specific optimizations
- **docker**: Docker CE installation with compose plugin, user group permissions
- **wireguard**: VPN server setup for secure remote access

#### Post-Installation

After successful provisioning, your VM will have:
- Hardened SSH configuration with fail2ban
- Automatic security updates
- Docker ready for container deployments
- WireGuard VPN for secure access
- Hetzner volumes auto-mounted at `/mnt/HC_Volume_*`
- Optional floating IP configured

## Authors
Module is created and maintained by [hobbsAU](https://github.com/hobbsAU).

