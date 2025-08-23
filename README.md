# LegacyAppCycle

---

![LegacyAppCycle Workflow](app/legacyApp.gif)

---

## Project Overview

**LegacyAppCycle** is an automation toolkit for deploying Java applications to target servers using a legacy approach, powered by Ansible. Initially crafted for Ubuntu 24.04, its modular design makes it adaptable to most Linux distributions. The solution combines application release/version tracking with orchestrated deployment workflows, serving teams who manage Java app lifecycles in legacy or mixed environments.

The repository is organized into two main directories:
- `ansible/`: Remote orchestration logic (playbooks, configuration, inventories)
- `app/`: Application-specific artifacts (binaries, scripts, version markers)

This structure supports scalable deployment, maintenance, and rollback for Java apps in classic IT infrastructure. While Ubuntu 24.04 is the reference, only minor changes are needed for other Linux systems.

---

## Prerequisites

### Ubuntu 24.04

- **Root or sudo privileges**
- **Update packages**
  ```bash
  sudo apt update
  sudo apt upgrade
  ```
- **Install OpenJDK**
  ```bash
  sudo apt install openjdk-11-jdk
  java -version
  ```
  Optionally configure `JAVA_HOME`:
  ```bash
  sudo nano /etc/environment
  JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
  source /etc/environment
  echo $JAVA_HOME
  ```
- **Install Ansible**
  ```bash
  sudo apt install -y software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt update
  sudo apt install -y ansible
  ansible --version
  ```
- **Set up passwordless SSH**
  ```bash
  ssh-keygen -t rsa
  ssh-copy-id user@your-target-server
  ```
- **Ensure network connectivity** (test with `ping` or `ssh`)

### Other Linux Distros

- Install Ansible and OpenJDK using your package manager:
  - CentOS: `sudo yum install java-11-openjdk-devel ansible`
  - Debian: `sudo apt install openjdk-11-jdk ansible`
  - SLES/OpenSUSE: `sudo zypper install java-11-openjdk ansible`
- Confirm SSH access and privileges

---

## Directory Structure

```text
LegacyAppCycle/
├── ansible/
│   └── ...           # Playbooks, roles, inventories, config
├── app/
│   └── ...           # Java binaries, scripts, version markers
└── README.md         # Project documentation
```

- **ansible/**: All Ansible automation logic
- **app/**: Java application artifacts, scripts, and versioning
- **README.md**: Usage and contribution guide

---

## File and Folder Descriptions

| File/Folder | Purpose |
|-------------|---------|
| `README.md` | Main project documentation |
| `ansible/`  | Ansible logic: playbooks, roles, inventories, config |
| `app/`      | Java app artifacts, scripts, releases |

### `ansible/` Directory

- `playbook.yml`: Main playbook for Java deployment
- `hosts`: Inventory of target servers
- `ansible.cfg`: (optional) Project-specific Ansible settings
- `roles/`: (optional) Reusable task sets
- `group_vars/`, `host_vars/`: (optional) Variable scoping

### `app/` Directory

- Application binaries (e.g., `.jar` files)
- Release/version markers
- Custom scripts (e.g., pre/post-deployment, health checks)

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/Omariibrahem/LegacyAppCycle.git
cd LegacyAppCycle
```

### 2. Install Prerequisites

See the [Prerequisites](#prerequisites) section for details.

### 3. Set Up Passwordless SSH

```bash
ssh-keygen -t rsa
ssh-copy-id user@target-server
ssh user@target-server
```

### 4. Configure Inventory

Edit `ansible/hosts`:
```ini
[servers]
192.168.1.101 ansible_user=adminuser
192.168.1.102 ansible_user=adminuser
```

### 5. Customize Ansible Configuration

Edit/create `ansible/ansible.cfg`:
```ini
[defaults]
inventory = ./hosts
remote_user = adminuser
host_key_checking = False

[privilege_escalation]
become=True
become_method=sudo
become_user=root
become_ask_pass=False
```

### 6. Place Java Application Files

Put your Java `.jar` files or release artifacts in `app/`.

### 7. Edit Playbooks

Review and tailor `ansible/playbook.yml` to your app’s needs.

---

## Usage Guide

- **Check connectivity**:
  ```bash
  ansible all -m ping
  ```
- **Syntax check**:
  ```bash
  ansible-playbook playbook.yml --syntax-check
  ```
- **Run playbook**:
  ```bash
  ansible-playbook playbook.yml
  ```
- **Use inventory explicitly**:
  ```bash
  ansible-playbook -i hosts playbook.yml
  ```
- **Limit execution**:
  ```bash
  ansible-playbook -i hosts playbook.yml --limit server1
  ```
---

### Cross-Distribution Consistency

Use the `package` module for automatic package manager selection:
```yaml
- name: Ensure Java runtime is present
  ansible.builtin.package:
    name: openjdk-11-jre
    state: present
```
Adjust package names per distribution.

### JAVA_HOME and Environment Variables

Set JAVA_HOME system-wide or for services:
```yaml
- name: Set JAVA_HOME in /etc/environment
  lineinfile:
    path: /etc/environment
    line: "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
    state: present
```
For systemd services, add `Environment=JAVA_HOME=...` in the unit file.

---

## IP Address Considerations

### Static vs DHCP

- Use static IPs for stability.
- For Ubuntu, edit `/etc/netplan/01-netcfg.yaml` and apply with `sudo netplan apply`.
- For CentOS/RHEL, configure `/etc/sysconfig/network-scripts/ifcfg-eth0`.

### Troubleshooting

- Check assigned IP: `ip a`
- Verify connectivity: `ping`, `ssh`, `ansible all -m ping`

---

## Troubleshooting Common Issues

- **YAML/syntax errors**: Use spaces, quote strings, validate with `yamllint`.
- **SSH failures**: Confirm key-based login, correct IPs, open firewall.
- **Variable/inventory issues**: Confirm variables exist, inventory is parsed.
- **Package management**: Match package names to OS, ensure Python compatibility.
- **Privilege escalation**: Use `become: true`, configure sudoers as needed.
- **File permissions**: Ensure writable by deploying user, use `become: true`.
- **Playbook execution**: Use `--syntax-check`, debug with `-vvv`.

For JAVA_HOME in services, add to systemd unit files and reload systemd.

---



## Security & Hardening

- Use SSH keys, restrict inventory, firewall remote hosts
- Consider containers for extra isolation
- Store sensitive variables in Ansible Vault

---

## Automation & Scaling

- Modularize playbooks, use roles for repeatability
- Use variable files for environment-specific overrides

---

## FAQ

**Q:** Why does my playbook fail with package not found?  
**A:** Check the correct Java package name for your OS and update package repos.

**Q:** App runs manually but fails as a service?  
**A:** Ensure JAVA_HOME and env vars are set in the service’s context.

**Q:** How to add custom pre/post deployment tasks?  
**A:** Add to `tasks:` in the playbook, or use `import_tasks`/`handlers`.

**Q:** How to roll back a deployment?  
**A:** Use Ansible `block`, `rescue`, and keep previous versions available on target systems.

**Q:** How to confirm affected hosts?  
**A:** Use `ansible-inventory --graph` and `ansible all -m ping`.

---
