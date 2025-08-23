# LegacyAppCycle

---
<p align="center">
  <img src="/legacyApp.gif" width="600" alt="Demo Preview">
</p>

---

## Overview

BARQ Lite automates the deployment of a Java application across multiple Ubuntu servers using **Bash**, **Ansible**, and optionally **Docker**. It integrates centralized logging, TLS certificate management, and load balancing via **Nginx** (with bridge networking), making it ideal for professional DevOps portfolios or robust production setups.

---

---

## Key Features

| Area                | Native JAR         | Dockerized           | Ansible/Bash         | Nginx LB             | Cloud Integration    |
|---------------------|--------------------|----------------------|----------------------|----------------------|---------------------|
| Java setup          | OpenJDK role       | Dockerfile           | Automated install    |                      |                     |
| Deployment          | `java -jar`        | `docker run`         | Playbooks/scripts    |                      |                     |
| Logging             | File+logrotate     | Bind/log drivers     | Logrotate config     | Proxy logs           |                     |
| TLS/SSL             | Certbot/manual     | Mounted/scripted     | Certbot role/cron    | SNI/termination      | Let's Encrypt       |
| App updates         | Scripted restart   | Docker restart       | Systemd/Bash         | Automatic reload     |                     |
| LB/networking       | Nginx upstream     | Docker bridge        |                      | Bridge verification  |                     |
| Cloud exposure      | SSH/firewall       | Host networking      |                      | UFW/firewall         | AWS/Static IP       |
| Automation/report   | Cron/log alerts    | Health check         | Ansible cron         | Uptime alerts        | Webhook/email       |

---

## Getting Started

### Prerequisites

- **Ubuntu 20.04/22.04 LTS** (app servers & Nginx LB)
- **Ansible** installed (`pip install ansible`)
- (Optional) **Docker** installed for containerized deployment

### Server Preparation

1. **Update System**
   ```sh
   sudo apt update && sudo apt upgrade -y
   ```
2. **Add Deployment User**
   ```sh
   sudo adduser deploy
   sudo usermod -aG sudo deploy
   ```
3. **Enable SSH and Firewall**
   ```sh
   sudo apt install openssh-server
   sudo systemctl enable --now ssh
   sudo ufw allow OpenSSH
   sudo ufw enable
   ```

---

## Folder Structure

```text
barq-lite/
├─ ansible/
|  ├─Fetchlog.yml                 #fetch the logs back to the local host
|  ├─KillprocessBarq.yml          #kill the native barq process befor run docker
|  ├─KillOricessDocker.yml        #kill the docker process before run the native app
│  ├─ inventory.ini               # the main inventory must encrypt it using vault
│  ├─ site.yml                    #The main play book
│  ├─ group_vars/
│  │  └─ all.yml 
│  ├─ roles/
│  │  ├─ common/                # users, dirs, initial logs, TLS folder
│  │  │  └─ tasks/main.yml
│  │  ├─ scripts/               # bash scripts + cron
│  │  │  ├─ tasks/main.yml
│  │  │  └─ files/
│  │  │     ├─ log-lite.sh
│  │  │     └─ cert-lite.sh
│  │  ├─ tls/                   # self-signed cert(s)
│  │  │  └─ tasks/main.yml
│  │  ├─ app_native/            # JAR deploy + systemd
│  │  │  ├─ tasks/main.yml
│  │  │  └─ templates/barq.service.j2
│  │  ├─ app_docker/            # Docker mode (optional)
│  │  │  ├─ tasks/main.yml
│  │  │  └─ templates/Dockerfile.j2
│  │  └─ nginx_lb/              # LB on third VM
│  │     ├─ tasks/main.yml
│  │     └─ templates/barq.conf.j2
│  └─ files/
│     └─ barq-lite.jar          # build locally & drop here (or keep sources below)
├─ app/
│  ├─ src/BarqLite.java
│  ├─ manifest.mf
│  └─ build.sh                  # helper to build barq-lite.jar locally
│  ├─ testcode.sh
│  ├─ ValidateJar.sh
└─ README.md
```
```

### File/Folder Explanations

- **fetchLogs.yml**: Playbook to automate retrieval of application, proxy, or system logs from all hosts.
- **files/**: Static resources (config files, scripts) copied to servers during deployments.
- **group_vars/**: Variable definitions for Ansible host groups, controlling environment, app settings, etc.
- **inventory.ini**: Defines target hosts and groupings for playbook execution.
- **killprocessBarq.yml**: Playbook for stopping or killing Barq-related processes (for maintenance or emergency recovery).
- **logs/**: Local storage for logs fetched from servers.
- **roles/**: Modularized Ansible roles (see below for typical role breakdown).
- **site.yml**: Aggregates all roles/playbooks for end-to-end infrastructure rollout.

---

## Deployment Methods

### Native JAR Deployment

- **Java Install**: Automated via Ansible or manually via `apt`.
- **App Rollout**: Copy JAR, start via Systemd or Bash script.
- **Sample Bash Script**:
    ```bash
    #!/bin/bash
    JAR="barq-lite.jar"
    DIR="/opt/barq-lite"
    HOSTS=("server1" "server2")
    for h in "${HOSTS[@]}"; do
      scp "$JAR" deploy@"$h":"$DIR"/
      ssh deploy@"$h" "sudo systemctl restart barq-lite || nohup java -jar $DIR/$JAR > $DIR/app.log 2>&1 &"
    done
    ```

- **Ansible Playbook (Excerpt)**:
    ```- name: Prep servers (users, dirs, TLS, scripts, cron, app)
  hosts: srv
  become: true
  serial: 1

  roles:
    - role: common
    - role: tls
    - role: scripts
    - { role: app_native, when: deploy_mode == 'native' }
    - { role: app_docker, when: deploy_mode == 'docker' }
      
- name: NGINX load balancer
    hosts: lb
    become: true
    roles:
     - nginx_lb
    ```

### Docker Deployment
- **Run App**:
    ```sh
    docker build -t barq-lite:latest .
    docker run -d --name barq1 --network barq-net -p 8080:8080 barq-lite:latest
    ```

- **Bridge Networking**:
    ```sh
    docker network create barq-net
    docker run --network barq-net --name app1 barq-lite:latest
    ```

---

## Nginx Load Balancer

- **Basic Config**:
    ```nginx
    upstream barq_app {
        server 10.10.10.2:8080;
        server 10.10.10.3:8080;
    }

    server {
        listen 80;
        server_name _;
        location / {
            proxy_pass http://barq_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
    ```

- **Install & Enable**:
    ```sh
    sudo apt-get install nginx
    sudo cp nginx/barq-lite.conf /etc/nginx/sites-available/
    sudo ln -s /etc/nginx/sites-available/barq-lite.conf /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    ```

---

## TLS Certificate Management

- **Automated via Certbot & Ansible**
    ```yaml
    - name: Setup TLS
      import_role:
        name: geerlingguy.certbot
    ```
- **Renewal**: Cron jobs or Certbot’s built-in scheduling.
- **Failure Alerts**: Certbot sends renewal failure notifications to configured email.

---

## Log Management

- **Logrotate Example**:
    ```conf
    /var/log/barq-lite/*.log {
        daily
        rotate 14
        compress
        delaycompress
        missingok
        notifempty
        create 0640 app app
        postrotate
            systemctl reload barq-lite > /dev/null 2>&1 || true
        endscript
    }
    ```
- **Automated via Cron**:
    - Log rotation
    - TLS renewal
    - Health reporting

---

## Ansible Roles

- **java**: Installs and configures OpenJDK
- **app**: Deploys JAR or container, configures service
- **docker**: Installs Docker, manages bridge networks
- **nginx**: Configures and manages Nginx as load balancer/reverse proxy
- **tls**: Manages Certbot/Let's Encrypt certificates
- **logrotate**: Sets up log rotation for app and proxy logs

---

## Cloud/Public Exposure

- Deploy Nginx LB VM to a cloud provider (AWS, Azure, GCP)
- Harden SSH, configure firewalls
- Use static IP and DNS for public endpoint
- Secure with TLS and restrict access as needed

---

## Comparison: Native JAR vs Docker

| Feature            | Native JAR             | Docker Container        |
|--------------------|------------------------|------------------------|
| Setup/Deploy       | Simple, direct         | Portable, isolated     |
| Upgrades           | Manual restart         | Image swap/restart     |
| Isolation          | OS-level               | Container-level        |
| Scaling            | VM/service             | Compose/Swarm/K8s      |
| Logging            | Host file/logrotate    | Volume or driver       |
| Security           | Relies on host         | Container controls     |
| Dev/Prod Parity    | Prone to drift         | Immutable              |

---

## Quickstart

1. **Clone repo**
    ```sh
    git clone https://github.com/Omariibrahem/LegacyAppCycle.git
    cd LegacyAppCycle/ansible
    ```
2. **Edit inventory and variables**
    - Update `inventory.ini` and `group_vars/*` as needed.
3. **Deploy (Native JAR)**
    ```sh
    ansible-playbook -i inventory.ini site.yml --tags "app,java"
    ```
4. **Deploy (Docker)**
    ```sh
    ansible-playbook -i inventory.ini site.yml --tags "docker,app"
    ```
5. **Set up Nginx Load Balancer**
    ```sh
    ansible-playbook -i inventory.ini site.yml --tags "nginx"
    ```
6. **Review logs and verify**
    ```sh
    tail -f /var/log/barq/app.log
    tail -f /var/log/nginx/access.log
    curl -Ik https://<nginx-public-ip>/
    ```

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


## Contribution & Extension

- Add new app nodes by updating inventory and rerunning playbooks.
- Extend roles for additional infrastructure (DB, monitoring, etc.).
- Use modular roles for maintainability and collaboration.

---

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Certbot Documentation](https://certbot.eff.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

**BARQ Lite** demonstrates best practices in automated deployment, observability, and cloud readiness. Its modular Ansible roles and clear separation of concerns make it a resilient foundation for Java apps—whether in development or production.


---



