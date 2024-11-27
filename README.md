# User and Group Management Script

## Overview

This is a robust Bash script designed to automate user and group management tasks on Linux systems. It provides a feature-rich interactive menu for handling users, groups, permissions, and generating detailed reports. Ideal for system administrators and DevOps teams.

## Features

- **User Management**:
  - Create, modify, delete, and list users.
  - Monitor user logins.
  - Set password expiration policies.

- **Group Management**:
  - Create, rename, delete groups.
  - Add/remove users in groups.
  - Audit group memberships.

- **Permission Management**:
  - Set file/directory permissions.
  - Assign ownership and groups.
  - Audit file permissions.

- **Report Generation**:
  - Export user and group information to CSV files.

- **Logging**:
  - All actions are logged in a detailed log file for audit purposes.

## Requirements

- **Operating System**: Linux-based distributions (e.g., Ubuntu, Debian).
- **Privileges**: Root or sudo access.
- **Dependencies**:
  - Required packages: `util-linux`, `passwd`, `openssl`.

## Installation 
   ```bash
git clone https://github.com/BuggyTheDebugger/User-Group-Management.git
cd User-Group-Management
chmod +x usergroupmanager.sh
sudo ./usergroupmanager.sh
```

## Usage

1. Clone the repository:
   ```bash
   cd User-Group-Management
   sudo ./usergroupmanager.sh
```
