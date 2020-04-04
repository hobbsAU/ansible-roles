# Ansible Roles

## Description
This is a repository of reusable ansible roles for automating common system activities. Roles can be used for provisioning and maintenance.

All roles are contained within one git repository following the ansible monorepo guidance. The roles have been made as generic as possible.

## Requirements
Ansible => 2.9

## Usage
See [Examples](#examples) for extended usage.

### Install roles
Your `requirements.yml` is used by the `ansible-galaxy` tool to understand what sources to use. It should list *this* github repository as the source.

Note: you can extend this file to pull from multiple sources.

### Create requirements.yml
```yaml
---
- src: https://github.com/hobbsAU/ansible-roles/
  name: ansible-roles
  version: master
  scm: git
```

### Use the roles
Use the roles within a play as per the following example.
```yaml
---
# File: System update
# Desc: Play for updating systems

- hosts: "{{ target }}"
  gather_facts: true
  become: true
  
  roles:
    - ansible-roles/sysupdate
```

### Examples
See examples in ansible-roles/examples.

## Authors
Module is created and maintained by [hobbsAU](https://github.com/hobbsAU).

