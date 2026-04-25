# Plume NAS 🪶

**Plume NAS** is a lightweight Bash-based Samba NAS manager with a simple Text User Interface (TUI) designed for Debian-based systems (tested on Debian Trixie).

It provides an interactive way to manage users, groups, shares, and Samba configuration without needing a web interface or external control panel.

> ⚠️ This project is intentionally simple, lightweight, and educational. It is NOT an enterprise NAS solution.

---

## 📌 What is Plume NAS?

Plume NAS is a single Bash script that acts as a minimal NAS management tool for Samba on Linux.

It allows you to:

- Manage Linux users and Samba users
- Create and manage groups
- Create and manage Samba shares under `/srv/shares`
- Automatically configure Samba (`smb.conf`)
- Restart Samba services safely
- Monitor disk usage and active Samba connections
- View system logs related to Samba

The interface is entirely terminal-based and menu-driven.

---

## ⚙️ Features

### 👤 User Management
- Create system + Samba users
- Delete users
- Change passwords (Linux + Samba)
- View users and group membership

### 👥 Group Management
- Create and delete groups
- Assign users to groups
- List all groups

### 📁 Share Management
- Create Samba shares in `/srv/shares`
- Assign group-based permissions
- Automatically update `smb.conf`
- Remove shares safely

### 📊 Monitoring
- Disk usage (`df -h`)
- Active Samba connections (`smbstatus`)
- Samba logs (`/var/log/samba/`)

### 🔧 System Integration
- Automatic Samba installation (if missing)
- Safe restart of `smbd` and `nmbd`
- Configuration backup before changes
- Basic validation of inputs

---

## 🧠 Design Philosophy

Plume NAS is built around:

- Simplicity over complexity
- Bash-only implementation (no external UI frameworks)
- Direct integration with native Linux tools
- Minimal dependencies
- Easy readability and hackability

It is meant to be:

> “A NAS manager you can fully understand in one file.”

---

## 🧪 Target Environment

Plume NAS is designed for:

- Debian 12+ (Trixie tested)
- Minimal installations
- LXC / LXD containers
- Home servers
- Small office NAS setups

It relies on standard Debian packages:

- `samba`
- `smbclient`
- `cifs-utils`

---

## 💡 Pros

✔ Extremely lightweight (single Bash script)  
✔ No web server required  
✔ Easy to debug and modify  
✔ Uses stable Debian + Samba packages  
✔ Fast setup (minutes)  
✔ Transparent configuration (no abstraction layers)  
✔ Works well in containers and minimal systems  

---

## ⚠️ Cons / Limitations

❌ Not suitable for enterprise environments  
❌ No RBAC system beyond Unix groups  
❌ No GUI / web dashboard  
❌ No LDAP/Active Directory integration  
❌ No encryption management layer  
❌ Limited auditing capabilities  
❌ Basic error handling  
❌ Manual terminal-based interaction only  

---

## 🚨 Disclaimer

Plume NAS is:

- A **learning / hobby / home lab project**
- Not a production-grade NAS solution
- Not audited for enterprise security compliance
- Not designed for high-scale or multi-tenant environments

Use it at your own risk.

For serious enterprise NAS deployments, consider:

- TrueNAS
- OpenMediaVault
- Enterprise Samba with LDAP/AD integration

---

## 🪶 Why “Plume”?

It represents the goal of this project:

> A NAS management tool that is light, simple, and minimal.

---

## 📦 Installation

```bash
chmod +x nas.sh
sudo ./nas.sh
