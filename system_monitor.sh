#!/bin/bash

# =========================================
# SYSTEM HEALTH MONITOR v1.0
# Interactive real-time terminal dashboard
# =========================================

LOG_FILE="./system_health_alerts.log"
REFRESH_RATE=3
FILTER="all"

# ANSI color codes
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

# Thresholds
CPU_WARN=70
CPU_CRIT=85
MEM_WARN=70
MEM_CRIT=85
DISK_WARN=70
DISK_CRIT=85

# Keyboard shortcuts
trap "exit" SIGINT

draw_bar() {
    local value=$1
    local max=100
    local width=30
    local color=$2

    local filled=$((value * width / max))
    local empty=$((width - filled))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo -e "${color}${bar}${RESET}"
}

log_alert() {
    local message=$1
    local timestamp=$(date +"%H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

show_help() {
    echo -e "${CYAN}Keyboard Shortcuts:${RESET}"
    echo "  q : Quit"
    echo "  r : Change refresh rate"
    echo "  f : Change filter (all/cpu/mem/disk/net)"
    echo "  h : Help"
    read -n1 -r
}

while true; do
    clear

    # Header
    HOSTNAME=$(hostname)
    DATE=$(date +"%Y-%m-%d")
    UPTIME=$(uptime -p)
    echo -e "╔════════════ SYSTEM HEALTH MONITOR v1.0 ════════════╗  [R]efresh rate: ${REFRESH_RATE}s"
    echo -e "║ Hostname: $HOSTNAME          Date: $DATE ║  [F]ilter: ${FILTER^}"
    echo -e "║ Uptime: $UPTIME               ║  [Q]uit"
    echo -e "╚═══════════════════════════════════════════════════════════════════════╝"
    echo

    # CPU
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4+$6)}')
    if (( CPU >= CPU_CRIT )); then CPU_COLOR=$RED; STATUS="CRITICAL"; log_alert "CPU usage exceeded $CPU_CRIT% (${CPU}%)"
    elif (( CPU >= CPU_WARN )); then CPU_COLOR=$YELLOW; STATUS="WARNING"; log_alert "CPU usage exceeded $CPU_WARN% (${CPU}%)"
    else CPU_COLOR=$GREEN; STATUS="OK"; fi
    CPU_TOP=$(ps -eo comm,%cpu --sort=-%cpu | head -n 4 | tail -n 3 | awk '{printf "%s (%s%%), ", $1, $2}')
    echo -e "CPU USAGE: $CPU% $(draw_bar $CPU $CPU_COLOR) [$STATUS]"
    echo "  Process: ${CPU_TOP%, }"
    echo

    # Memory
    MEM_TOTAL=$(free -g | awk '/Mem/ {print $2}')
    MEM_USED=$(free -g | awk '/Mem/ {printf "%d", $3}')
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    MEM_COLOR=$GREEN
    STATUS="OK"
    if (( MEM_PERCENT >= MEM_CRIT )); then MEM_COLOR=$RED; STATUS="CRITICAL"; log_alert "Memory usage exceeded $MEM_CRIT% (${MEM_PERCENT}%)"
    elif (( MEM_PERCENT >= MEM_WARN )); then MEM_COLOR=$YELLOW; STATUS="WARNING"; log_alert "Memory usage exceeded $MEM_WARN% (${MEM_PERCENT}%)"; fi
    MEM_FREE=$(free -h | awk '/Mem/ {print $4}')
    MEM_CACHE=$(free -h | awk '/Mem/ {print $6}')
    MEM_BUFFERS=$(free -h | awk '/Mem/ {print $7}')
    echo -e "MEMORY: ${MEM_USED}GB/${MEM_TOTAL}GB ($MEM_PERCENT%) $(draw_bar $MEM_PERCENT $MEM_COLOR) [$STATUS]"
    echo "  Free: $MEM_FREE | Cache: $MEM_CACHE | Buffers: $MEM_BUFFERS"
    echo

    # Disk
    echo "DISK USAGE:"
    df -h --output=target,pcent | tail -n +2 | while read line; do
        MOUNT=$(echo $line | awk '{print $1}')
        PERC=$(echo $line | awk '{print $2}' | tr -d '%')
        COLOR=$GREEN
        STATUS="OK"
        if (( PERC >= DISK_CRIT )); then COLOR=$RED; STATUS="CRITICAL"; log_alert "Disk usage on $MOUNT exceeded $DISK_CRIT% (${PERC}%)"
        elif (( PERC >= DISK_WARN )); then COLOR=$YELLOW; STATUS="WARNING"; log_alert "Disk usage on $MOUNT exceeded $DISK_WARN% (${PERC}%)"; fi
        echo -e "  $MOUNT : $PERC% $(draw_bar $PERC $COLOR) [$STATUS]"
    done
    echo

    # Network
    echo "NETWORK:"
    INTERFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
    RX1=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    sleep 0.1
    RX2=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
    RX_RATE=$(( (RX2-RX1)/1024/1024*10 ))
    TX_RATE=$(( (TX2-TX1)/1024/1024*10 ))
    echo -e "  $INTERFACE (in) : $RX_RATE MB/s $(draw_bar $RX_RATE $GREEN) [OK]"
    echo -e "  $INTERFACE (out): $TX_RATE MB/s $(draw_bar $TX_RATE $GREEN) [OK]"
    echo

    # Load average
    LOAD=$(uptime | awk -F 'load average: ' '{print $2}')
    echo "LOAD AVERAGE: $LOAD"
    echo

    # Recent alerts
    echo "RECENT ALERTS:"
    tail -n 5 "$LOG_FILE" 2>/dev/null
    echo
    echo "Press 'h' for help, 'q' to quit"

    # Keyboard shortcuts
    read -t $REFRESH_RATE -n1 key
    case "$key" in
        q) exit ;;
        h) show_help ;;
        r)
            echo -n "Enter new refresh rate in seconds: "
            read REFRESH_RATE ;;
        f)
            echo -n "Enter filter (all/cpu/mem/disk/net): "
            read FILTER ;;
    esac
done
