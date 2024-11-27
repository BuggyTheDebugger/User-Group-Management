#!/bin/bash

# User and Group Management Script
# Author: [CodeD-Roger]
# Version: 2.2
# Description: Complete automation for managing users, groups, permissions, and generating reports.

# =======================
# GLOBAL VARIABLES
# =======================
LOG_FILE="./user_group_management.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
REQUIRED_PACKAGES=("util-linux" "passwd" "openssl")

# =======================
# COMMON FUNCTIONS
# =======================

# Log actions
function log_action() {
    echo "[$DATE] $1" | tee -a "$LOG_FILE"
}

# Clear screen with pause
function pause_and_clear() {
    read -p "Press Enter to continue..."
    clear
}

# Check and install required packages
function check_and_install_dependencies() {
    log_action "[+] Checking required packages..."
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -qw "$package"; then
            log_action "[-] Package $package is missing. Installing..."
            apt-get update && apt-get install -y "$package" >/dev/null 2>&1
            if [[ $? -eq 0 ]]; then
                log_action "[+] Package $package installed successfully."
            else
                log_action "[-] Failed to install $package. Please check your system."
                exit 1
            fi
        else
            log_action "[+] Package $package is already installed."
        fi
    done
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "[-] Please run this script as root."
    exit 1
fi

# =======================
# PART 1: USER MANAGEMENT
# =======================

# Create a user
function create_user() {
    clear
    read -p "[?] Enter the username: " USERNAME
    if id "$USERNAME" &>/dev/null; then
        log_action "[-] User $USERNAME already exists."
        pause_and_clear
        return
    fi

    read -p "[?] Enter the home directory (default: /home/$USERNAME): " HOMEDIR
    HOMEDIR=${HOMEDIR:-/home/$USERNAME}
    read -p "[?] Enter the shell (default: /bin/bash): " SHELL
    SHELL=${SHELL:-/bin/bash}

    PASSWORD=$(openssl rand -base64 12)
    useradd -m -d "$HOMEDIR" -s "$SHELL" "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd

    log_action "[+] User $USERNAME successfully created."
    echo "[+] Password for $USERNAME: $PASSWORD"
    pause_and_clear
}

# Modify a user
function modify_user() {
    clear
    read -p "[?] Enter the username to modify: " USERNAME
    if ! id "$USERNAME" &>/dev/null; then
        log_action "[-] User $USERNAME does not exist."
        pause_and_clear
        return
    fi

    echo "1. Change password"
    echo "2. Change home directory"
    echo "3. Change shell"
    echo "0. Back"
    read -p "[?] Choose an option: " OPTION

    case $OPTION in
        1)
            read -p "[?] New password: " PASSWORD
            echo "$USERNAME:$PASSWORD" | chpasswd
            log_action "[+] Password changed for $USERNAME."
            ;;
        2)
            read -p "[?] New home directory: " HOMEDIR
            usermod -d "$HOMEDIR" "$USERNAME"
            log_action "[+] Home directory changed for $USERNAME."
            ;;
        3)
            read -p "[?] New shell: " SHELL
            usermod -s "$SHELL" "$USERNAME"
            log_action "[+] Shell changed for $USERNAME."
            ;;
        0) pause_and_clear; return ;;
        *) echo "[-] Invalid option." ;;
    esac
    pause_and_clear
}

# Delete a user
function delete_user() {
    clear
    read -p "[?] Enter the username to delete: " USERNAME
    if ! id "$USERNAME" &>/dev/null; then
        log_action "[-] User $USERNAME does not exist."
        pause_and_clear
        return
    fi

    read -p "[?] Delete the home directory? (y/n): " DELHOME
    if [[ "$DELHOME" == "y" ]]; then
        userdel -r "$USERNAME"
        log_action "[+] User $USERNAME and home directory deleted."
    else
        userdel "$USERNAME"
        log_action "[+] User $USERNAME deleted."
    fi
    pause_and_clear
}

# List users
function list_users() {
    clear
    echo "[+] User list:"
    cut -d: -f1 /etc/passwd | tee -a "$LOG_FILE"
    pause_and_clear
}

# Monitor user logins
function monitor_user_logins() {
    clear
    if command -v last &>/dev/null; then
        echo "[+] Monitoring user logins:"
        last | tee -a "$LOG_FILE"
    elif command -v journalctl &>/dev/null; then
        echo "[+] Monitoring SSH logins from system logs:"
        journalctl _COMM=sshd | grep "Accepted" | tee -a "$LOG_FILE"
    else
        log_action "[-] Neither 'last' nor 'journalctl' is available. Unable to monitor logins."
    fi
    pause_and_clear
}

# Set password expiration
function set_password_expiry() {
    clear
    read -p "[?] Enter the username: " USERNAME
    if ! id "$USERNAME" &>/dev/null; then
        log_action "[-] User $USERNAME does not exist."
        pause_and_clear
        return
    fi

    read -p "[?] Enter the expiration duration (in days): " DAYS
    chage -M "$DAYS" "$USERNAME" &>/dev/null
    if [[ $? -eq 0 ]]; then
        log_action "[+] Password expiration set to $DAYS days for $USERNAME."
    else
        log_action "[-] Failed to set password expiration for $USERNAME."
    fi
    pause_and_clear
}

# =======================
# PART 2: GROUP MANAGEMENT
# =======================

# Create a group
function create_group() {
    clear
    read -p "[?] Enter the group name: " GROUPNAME
    if getent group "$GROUPNAME" &>/dev/null; then
        log_action "[-] Group $GROUPNAME already exists."
        pause_and_clear
        return
    fi

    groupadd "$GROUPNAME"
    log_action "[+] Group $GROUPNAME successfully created."
    pause_and_clear
}

# Modify a group
function modify_group() {
    clear
    read -p "[?] Enter the group name to modify: " GROUPNAME
    if ! getent group "$GROUPNAME" &>/dev/null; then
        log_action "[-] Group $GROUPNAME does not exist."
        pause_and_clear
        return
    fi

    echo "1. Rename the group"
    echo "2. Add a user to the group"
    echo "3. Remove a user from the group"
    echo "0. Back"
    read -p "[?] Choose an option: " OPTION

    case $OPTION in
        1)
            read -p "[?] New group name: " NEWNAME
            groupmod -n "$NEWNAME" "$GROUPNAME"
            log_action "[+] Group $GROUPNAME renamed to $NEWNAME."
            ;;
        2)
            read -p "[?] Enter the username: " USERNAME
            usermod -aG "$GROUPNAME" "$USERNAME"
            log_action "[+] User $USERNAME added to group $GROUPNAME."
            ;;
        3)
            read -p "[?] Enter the username: " USERNAME
            gpasswd -d "$USERNAME" "$GROUPNAME"
            log_action "[+] User $USERNAME removed from group $GROUPNAME."
            ;;
        0) pause_and_clear; return ;;
        *) echo "[-] Invalid option." ;;
    esac
    pause_and_clear
}

# Delete a group
function delete_group() {
    clear
    read -p "[?] Enter the group name to delete: " GROUPNAME
    if ! getent group "$GROUPNAME" &>/dev/null; then
        log_action "[-] Group $GROUPNAME does not exist."
        pause_and_clear
        return
    fi

    groupdel "$GROUPNAME"
    log_action "[+] Group $GROUPNAME successfully deleted."
    pause_and_clear
}

# List groups
function list_groups() {
    clear
    echo "[+] Group list:"
    cut -d: -f1 /etc/group | tee -a "$LOG_FILE"
    pause_and_clear
}

# Audit user groups
function audit_user_groups() {
    clear
    read -p "[?] Enter the username: " USERNAME
    if ! id "$USERNAME" &>/dev/null; then
        log_action "[-] User $USERNAME does not exist."
        pause_and_clear
        return
    fi

    echo "[+] Groups for $USERNAME:"
    groups "$USERNAME" | tee -a "$LOG_FILE"
    pause_and_clear
}

# =======================
# PART 3: PERMISSION MANAGEMENT
# =======================

# Set permissions
function set_permissions() {
    clear
    read -p "[?] Enter the file or directory path: " PATH
    read -p "[?] Enter the permissions (e.g., 755): " PERMISSIONS
    chmod "$PERMISSIONS" "$PATH"
    log_action "[+] Permissions $PERMISSIONS set for $PATH."
    pause_and_clear
}

# Set owner and group
function set_owner() {
    clear
    read -p "[?] Enter the file or directory path: " PATH
    read -p "[?] Enter the owner: " OWNER
    read -p "[?] Enter the group: " GROUP
    chown "$OWNER:$GROUP" "$PATH"
    log_action "[+] Owner and group set for $PATH."
    pause_and_clear
}

# Audit permissions
function audit_permissions() {
    clear
    read -p "[?] Enter the directory to audit: " DIR
    find "$DIR" -exec ls -ld {} \; > "permissions_audit_$(date +%Y%m%d_%H%M%S).txt"
    log_action "[+] Permissions audit saved."
    pause_and_clear
}

# =======================
# PART 4: REPORT GENERATION
# =======================

# Export user list to CSV
function export_users_to_csv() {
    clear
    cut -d: -f1,3,4 /etc/passwd | tr ':' ',' > users.csv
    log_action "[+] User list exported to users.csv."
    pause_and_clear
}

# Export group list to CSV
function export_groups_to_csv() {
    clear
    cut -d: -f1,3 /etc/group | tr ':' ',' > groups.csv
    log_action "[+] Group list exported to groups.csv."
    pause_and_clear
}

# =======================
# MAIN MENU
# =======================

function user_menu() {
    while true; do
        clear
        echo "========================="
        echo " USER MANAGEMENT"
        echo "========================="
        echo "1. Create a user"
        echo "2. Modify a user"
        echo "3. Delete a user"
        echo "4. List users"
        echo "5. Monitor user logins"
        echo "6. Set password expiration"
        echo "0. Back"
        read -p "Choose an option: " OPTION

        case $OPTION in
            1) create_user ;;
            2) modify_user ;;
            3) delete_user ;;
            4) list_users ;;
            5) monitor_user_logins ;;
            6) set_password_expiry ;;
            0) return ;;
            *) echo "[-] Invalid option." ;;
        esac
    done
}

function group_menu() {
    while true; do
        clear
        echo "========================="
        echo " GROUP MANAGEMENT"
        echo "========================="
        echo "1. Create a group"
        echo "2. Modify a group"
        echo "3. Delete a group"
        echo "4. List groups"
        echo "5. Audit user groups"
        echo "0. Back"
        read -p "Choose an option: " OPTION

        case $OPTION in
            1) create_group ;;
            2) modify_group ;;
            3) delete_group ;;
            4) list_groups ;;
            5) audit_user_groups ;;
            0) return ;;
            *) echo "[-] Invalid option." ;;
        esac
    done
}

function permission_menu() {
    while true; do
        clear
        echo "========================="
        echo " PERMISSION MANAGEMENT"
        echo "========================="
        echo "1. Set permissions"
        echo "2. Set owner and group"
        echo "3. Audit permissions"
        echo "0. Back"
        read -p "Choose an option: " OPTION

        case $OPTION in
            1) set_permissions ;;
            2) set_owner ;;
            3) audit_permissions ;;
            0) return ;;
            *) echo "[-] Invalid option." ;;
        esac
    done
}

function main_menu() {
    check_and_install_dependencies
    while true; do
        clear
        echo "========================="
        echo " USER AND GROUP MANAGEMENT"
        echo "========================="
        echo "1. User management"
        echo "2. Group management"
        echo "3. Permission management"
        echo "4. Export reports"
        echo "0. Exit"
        read -p "Choose an option: " OPTION

        case $OPTION in
            1) user_menu ;;
            2) group_menu ;;
            3) permission_menu ;;
            4)
                clear
                echo "1. Export user list to CSV"
                echo "2. Export group list to CSV"
                echo "0. Back"
                read -p "Choose an option: " REPORT_OPTION
                case $REPORT_OPTION in
                    1) export_users_to_csv ;;
                    2) export_groups_to_csv ;;
                    0) pause_and_clear ;;
                    *) echo "[-] Invalid option." ;;
                esac
                ;;
            0) log_action "[+] Exiting."; exit 0 ;;
            *) echo "[-] Invalid option." ;;
        esac
    done
}

# Execute the main menu
main_menu
