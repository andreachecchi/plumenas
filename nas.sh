#!/bin/bash

# =========================================================
# NAS SAMBA MANAGER - LXC READY
# Debian Trixie / LXC Container Edition
# File: nas.sh
# =========================================================

export TERM=${TERM:-xterm}

# =========================================================
# CONFIG
# =========================================================

SAMBA_CONFIG="/etc/samba/smb.conf"
SAMBA_BACKUP="/etc/samba/smb.conf.bak"

SHARE_ROOT="/srv/shares"

LOG_FILE="/var/log/nas-manager.log"

# =========================================================
# COLORS
# =========================================================

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
NC="\e[0m"

# =========================================================
# BASIC UTILS
# =========================================================

clear_screen() {
    command -v clear &>/dev/null && clear
}

pause() {
    echo
    read -rp "Premi INVIO per continuare..."
}

log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

get_ip_address() {

    IP_ADDRESS=$(hostname -I 2>/dev/null | awk '{print $1}')

    if [[ -z "$IP_ADDRESS" ]]; then
        IP_ADDRESS="IP non disponibile"
    fi
}

header() {

    clear_screen

    get_ip_address

    echo -e "${BLUE}"
    echo "================================================="
    echo "            NAS SAMBA MANAGER"
    echo "                 LXC READY"
    echo "================================================="
    echo -e "${NC}"

    echo "Container : $CONTAINER_TYPE"
    echo "IP Address: $IP_ADDRESS"
    echo
}

# =========================================================
# ENVIRONMENT CHECKS
# =========================================================

check_root() {

    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Eseguire come root.${NC}"
        exit 1
    fi
}

check_tty() {

    if ! tty &>/dev/null; then
        echo -e "${RED}TTY non disponibile.${NC}"
        echo
        echo "Entra nel container con:"
        echo
        echo "lxc exec <container> -- bash"
        echo
        exit 1
    fi
}

detect_container() {

    if grep -qa container=lxc /proc/1/environ 2>/dev/null; then
        CONTAINER_TYPE="LXC"
    else
        CONTAINER_TYPE="UNKNOWN"
    fi
}

# =========================================================
# SERVICE MANAGEMENT
# =========================================================

service_restart() {

    local service="$1"

    if command -v systemctl &>/dev/null; then

        systemctl restart "$service" 2>/dev/null

        return
    fi

    if command -v service &>/dev/null; then

        service "$service" restart 2>/dev/null

        return
    fi

    pkill "$service" 2>/dev/null

    "$service" -D
}

restart_samba() {

    echo
    echo -e "${YELLOW}Verifica configurazione Samba...${NC}"

    testparm -s &>/dev/null

    if [[ $? -ne 0 ]]; then

        echo -e "${RED}Configurazione Samba non valida.${NC}"

        if [[ -f "$SAMBA_BACKUP" ]]; then

            echo -e "${YELLOW}Ripristino backup...${NC}"

            cp "$SAMBA_BACKUP" "$SAMBA_CONFIG"
        fi

        return 1
    fi

    service_restart smbd
    service_restart nmbd

    echo
    echo -e "${GREEN}Servizi Samba riavviati.${NC}"

    log_action "Servizi Samba riavviati"

    return 0
}

# =========================================================
# INSTALLATION
# =========================================================

install_dependencies() {

    header

    echo -e "${YELLOW}Installazione pacchetti...${NC}"
    echo

    apt update

    apt install -y \
        samba \
        smbclient \
        cifs-utils

    mkdir -p "$SHARE_ROOT"

    cp "$SAMBA_CONFIG" "$SAMBA_BACKUP" 2>/dev/null

    echo
    echo -e "${GREEN}Installazione completata.${NC}"

    log_action "Installazione Samba"

    pause
}

ensure_installed() {

    if ! command -v smbd &>/dev/null; then

        echo -e "${YELLOW}Samba non installato.${NC}"

        install_dependencies
    fi
}

# =========================================================
# VALIDATION
# =========================================================

validate_name() {

    local value="$1"

    if [[ ! "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then

        echo -e "${RED}Nome non valido.${NC}"

        return 1
    fi

    return 0
}

# =========================================================
# USER MANAGEMENT
# =========================================================

create_user() {

    header

    echo "=== CREA UTENTE ==="
    echo

    read -rp "Nome utente: " username

    validate_name "$username" || return

    if id "$username" &>/dev/null; then

        echo -e "${RED}Utente già esistente.${NC}"

        pause

        return
    fi

    useradd -m -s /usr/sbin/nologin "$username"

    echo
    echo "Password Linux:"
    passwd "$username"

    echo
    echo "Password Samba:"
    smbpasswd -a "$username"

    echo
    echo -e "${GREEN}Utente creato.${NC}"

    log_action "Utente creato: $username"

    pause
}

delete_user() {

    header

    echo "=== ELIMINA UTENTE ==="
    echo

    read -rp "Nome utente: " username

    if ! id "$username" &>/dev/null; then

        echo -e "${RED}Utente inesistente.${NC}"

        pause

        return
    fi

    smbpasswd -x "$username" &>/dev/null

    userdel -r "$username"

    echo
    echo -e "${GREEN}Utente eliminato.${NC}"

    log_action "Utente eliminato: $username"

    pause
}

change_user_password() {

    header

    echo "=== PASSWORD UTENTE ==="
    echo

    read -rp "Nome utente: " username

    if ! id "$username" &>/dev/null; then

        echo -e "${RED}Utente inesistente.${NC}"

        pause

        return
    fi

    echo
    echo "Password Linux:"
    passwd "$username"

    echo
    echo "Password Samba:"
    smbpasswd "$username"

    echo
    echo -e "${GREEN}Password aggiornata.${NC}"

    log_action "Password aggiornata: $username"

    pause
}

list_users() {

    header

    echo "=== UTENTI DISPONIBILI ==="
    echo

    awk -F: '$3 >= 1000 { print $1 }' /etc/passwd

    pause
}

list_users_with_groups() {

    header

    echo "=== UTENTI E GRUPPI ASSOCIATI ==="
    echo

    for user in $(awk -F: '$3 >= 1000 { print $1 }' /etc/passwd); do

        echo "Utente : $user"
        echo "Gruppi : $(id -nG "$user")"
        echo

    done

    pause
}

# =========================================================
# GROUP MANAGEMENT
# =========================================================

create_group() {

    header

    echo "=== CREA GRUPPO ==="
    echo

    read -rp "Nome gruppo: " group

    validate_name "$group" || return

    if getent group "$group" &>/dev/null; then

        echo -e "${RED}Gruppo già esistente.${NC}"

        pause

        return
    fi

    groupadd "$group"

    echo
    echo -e "${GREEN}Gruppo creato.${NC}"

    log_action "Gruppo creato: $group"

    pause
}

delete_group() {

    header

    echo "=== ELIMINA GRUPPO ==="
    echo

    read -rp "Nome gruppo: " group

    if ! getent group "$group" &>/dev/null; then

        echo -e "${RED}Gruppo inesistente.${NC}"

        pause

        return
    fi

    groupdel "$group"

    echo
    echo -e "${GREEN}Gruppo eliminato.${NC}"

    log_action "Gruppo eliminato: $group"

    pause
}

add_user_to_group() {

    header

    echo "=== ASSOCIA UTENTE A GRUPPO ==="
    echo

    read -rp "Utente: " username
    read -rp "Gruppo: " group

    if ! id "$username" &>/dev/null; then

        echo -e "${RED}Utente inesistente.${NC}"

        pause

        return
    fi

    if ! getent group "$group" &>/dev/null; then

        echo -e "${RED}Gruppo inesistente.${NC}"

        pause

        return
    fi

    usermod -aG "$group" "$username"

    echo
    echo -e "${GREEN}Utente associato al gruppo.${NC}"

    log_action "$username aggiunto a $group"

    pause
}

list_groups() {

    header

    echo "=== GRUPPI DISPONIBILI ==="
    echo

    cut -d: -f1 /etc/group

    pause
}

# =========================================================
# SHARE MANAGEMENT
# =========================================================

create_share() {

    header

    echo "=== CREA SHARE ==="
    echo

    read -rp "Nome share: " share

    validate_name "$share" || return

    read -rp "Gruppo autorizzato: " group

    if ! getent group "$group" &>/dev/null; then

        echo -e "${RED}Gruppo inesistente.${NC}"

        pause

        return
    fi

    path="${SHARE_ROOT}/${share}"

    if [[ -d "$path" ]]; then

        echo -e "${RED}Share già esistente.${NC}"

        pause

        return
    fi

    mkdir -p "$path"

    chown root:"$group" "$path"

    chmod 2770 "$path"

    cp "$SAMBA_CONFIG" "$SAMBA_BACKUP"

    cat <<EOF >> "$SAMBA_CONFIG"

[$share]
   path = $path
   browseable = yes
   writable = yes
   read only = no
   guest ok = no

   valid users = @$group
   force group = $group

   create mask = 0770
   directory mask = 2770
EOF

    echo
    echo -e "${GREEN}Share creata.${NC}"

    log_action "Share creata: $share"

    restart_samba

    pause
}

delete_share() {

    header

    echo "=== ELIMINA SHARE ==="
    echo

    read -rp "Nome share: " share

    path="${SHARE_ROOT}/${share}"

    if [[ ! -d "$path" ]]; then

        echo -e "${RED}Share inesistente.${NC}"

        pause

        return
    fi

    echo
    read -rp "Eliminare anche i file? (s/n): " answer

    if [[ "$answer" =~ ^[sS]$ ]]; then

        rm -rf "$path"
    fi

    cp "$SAMBA_CONFIG" "$SAMBA_BACKUP"

    sed -i "/^\[$share\]/,/^$/d" "$SAMBA_CONFIG"

    restart_samba

    echo
    echo -e "${GREEN}Share eliminata.${NC}"

    log_action "Share eliminata: $share"

    pause
}

list_shares() {

    header

    echo "=== SHARE DISPONIBILI ==="
    echo

    ls -l "$SHARE_ROOT"

    pause
}

list_shares_with_groups() {

    header

    echo "=== SHARE E GRUPPI ASSOCIATI ==="
    echo

    for share in "$SHARE_ROOT"/*; do

        [[ -d "$share" ]] || continue

        share_name=$(basename "$share")

        group=$(stat -c '%G' "$share")

        echo "Share  : $share_name"
        echo "Path   : $share"
        echo "Gruppo : $group"
        echo

    done

    pause
}

# =========================================================
# MONITORING
# =========================================================

disk_monitor() {

    header

    echo "=== SPAZIO DISCO ==="
    echo

    df -h

    pause
}

samba_connections() {

    header

    echo "=== CONNESSIONI SAMBA ==="
    echo

    smbstatus

    pause
}

samba_logs() {

    header

    echo "=== LOG SAMBA ==="
    echo

    tail -n 50 /var/log/samba/log.smbd 2>/dev/null

    pause
}

# =========================================================
# SYSTEM
# =========================================================

reboot_host() {

    header

    echo -e "${RED}Riavviare il container? (s/n)${NC}"
    echo

    read -r answer

    if [[ "$answer" =~ ^[sS]$ ]]; then

        reboot
    fi
}

# =========================================================
# MENUS
# =========================================================

menu_users() {

    while true; do

        header

        echo "1) Crea utente"
        echo "2) Elimina utente"
        echo "3) Cambia password"
        echo "4) Lista utenti"
        echo "5) Utenti e gruppi associati"
        echo "6) Torna indietro"
        echo

        read -rp "Scelta: " choice

        case $choice in

            1) create_user ;;
            2) delete_user ;;
            3) change_user_password ;;
            4) list_users ;;
            5) list_users_with_groups ;;
            6) break ;;

            *)
                echo "Scelta non valida"
                pause
                ;;

        esac

    done
}

menu_groups() {

    while true; do

        header

        echo "1) Crea gruppo"
        echo "2) Elimina gruppo"
        echo "3) Associa utente a gruppo"
        echo "4) Lista gruppi"
        echo "5) Torna indietro"
        echo

        read -rp "Scelta: " choice

        case $choice in

            1) create_group ;;
            2) delete_group ;;
            3) add_user_to_group ;;
            4) list_groups ;;
            5) break ;;

            *)
                echo "Scelta non valida"
                pause
                ;;

        esac

    done
}

menu_shares() {

    while true; do

        header

        echo "1) Crea share"
        echo "2) Elimina share"
        echo "3) Lista share"
        echo "4) Share e gruppi associati"
        echo "5) Riavvia Samba"
        echo "6) Torna indietro"
        echo

        read -rp "Scelta: " choice

        case $choice in

            1) create_share ;;
            2) delete_share ;;
            3) list_shares ;;
            4) list_shares_with_groups ;;

            5)
                restart_samba
                pause
                ;;

            6) break ;;

            *)
                echo "Scelta non valida"
                pause
                ;;

        esac

    done
}

menu_monitor() {

    while true; do

        header

        echo "1) Spazio disco"
        echo "2) Connessioni Samba"
        echo "3) Log Samba"
        echo "4) Torna indietro"
        echo

        read -rp "Scelta: " choice

        case $choice in

            1) disk_monitor ;;
            2) samba_connections ;;
            3) samba_logs ;;
            4) break ;;

            *)
                echo "Scelta non valida"
                pause
                ;;

        esac

    done
}

# =========================================================
# MAIN MENU
# =========================================================

main_menu() {

    while true; do

        header

        echo "1) Gestione utenti"
        echo "2) Gestione gruppi"
        echo "3) Gestione share"
        echo "4) Monitoraggio"
        echo "5) Installa Samba"
        echo "6) Riavvia Samba"
        echo "7) Riavvia container"
        echo "8) Esci"
        echo

        read -rp "Scelta: " choice

        case $choice in

            1) menu_users ;;
            2) menu_groups ;;
            3) menu_shares ;;
            4) menu_monitor ;;
            5) install_dependencies ;;

            6)
                restart_samba
                pause
                ;;

            7) reboot_host ;;

            8)
                clear_screen
                exit 0
                ;;

            *)
                echo "Scelta non valida"
                pause
                ;;

        esac

    done
}

# =========================================================
# STARTUP
# =========================================================

check_root

check_tty

detect_container

mkdir -p "$SHARE_ROOT"

touch "$LOG_FILE"

ensure_installed

main_menu
