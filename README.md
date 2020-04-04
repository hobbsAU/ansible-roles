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
See examples in ansible-roles/examples.

## Authors
Module is created and maintained by [hobbsAU](https://github.com/hobbsAU).

