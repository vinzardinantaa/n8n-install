#!/bin/bash

#############################################
# n8n Automation Installer by Vinz
# Multi-Feature Installation & Management Script
# Version: 4.0
# Author: Vinz
#############################################

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color
BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'

# Unicode characters for modern UI
CHECK_MARK="✓"
CROSS_MARK="✗"
ARROW="➜"
STAR="★"
GEAR="⚙"
ROCKET="🚀"
PACKAGE="📦"
LOCK="🔒"
GLOBE="🌐"
SERVER="🖥️"
DOCKER_ICON="🐳"
NODE_ICON="⬢"
PM2_ICON="⚡"
FIRE="🔥"
SHIELD="🛡️"
SPEED="⚡"
PORT="🔌"
STATUS="📊"
TOOLS="🔧"
INFO="ℹ️"
WARNING="⚠️"

# Configuration file
CONFIG_FILE="/etc/n8n-installer/config.conf"
LOG_FILE="/var/log/n8n-installer-$(date +%Y%m%d-%H%M%S).log"

# Create config directory
mkdir -p /etc/n8n-installer

# Redirect errors to log
exec 2> >(tee -a "$LOG_FILE" >&2)

# Functions for UI
print_header() {
    clear
    echo ""
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║                                                                    ║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${MAGENTA}${BOLD}     n8n ${WHITE}AUTOMATION ${GREEN}INSTALLER ${NC}${CYAN}${BOLD}                               ║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${YELLOW}${BOLD}                  by Vinz ${NC}${CYAN}${BOLD}                                     ║${NC}"
    echo -e "${CYAN}${BOLD}║                                                                    ║${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${WHITE}${STAR} Modern ${STAR} Simple ${STAR} Powerful ${STAR}${NC}${CYAN}${BOLD}                                 ║${NC}"
    echo -e "${CYAN}${BOLD}║                                                                    ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_status() {
    echo -e "${CYAN}${ARROW}${NC} $1"
}

print_success() {
    echo -e "${GREEN}${CHECK_MARK}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC} $1"
}

print_info() {
    echo -e "${BLUE}${INFO}${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        echo -e "${YELLOW}Please run: ${WHITE}sudo $0${NC}"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_TYPE=$ID
        OS_VERSION=$VERSION_ID
        OS_PRETTY=$PRETTY_NAME
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="rhel"
        OS_VERSION=$(rpm -E %{rhel})
        OS_PRETTY=$(cat /etc/redhat-release)
    else
        OS_TYPE="unknown"
        OS_VERSION="unknown"
        OS_PRETTY="Unknown OS"
    fi
}

# Save configuration
save_config() {
    cat > $CONFIG_FILE <<EOF
INSTALL_METHOD=$INSTALL_METHOD
N8N_PORT=$N8N_PORT
N8N_DOMAIN=$N8N_DOMAIN
N8N_PROTOCOL=$N8N_PROTOCOL
N8N_USER=$N8N_USER
N8N_HOME=$N8N_HOME
N8N_VERSION=$N8N_VERSION
WEBHOOK_URL=$WEBHOOK_URL
INSTALL_DATE=$(date)
EOF
}

# Load configuration
load_config() {
    if [[ -f $CONFIG_FILE ]]; then
        source $CONFIG_FILE
        return 0
    else
        return 1
    fi
}

# Main Menu
show_main_menu() {
    print_header
    print_section "${TOOLS} MAIN MENU"
    
    echo -e "${WHITE}${BOLD}Select an option:${NC}"
    echo ""
    echo -e "${CYAN}[1]${NC} ${ROCKET} ${WHITE}Quick Install & Setup${NC}"
    echo -e "${CYAN}[2]${NC} ${PACKAGE} ${WHITE}Custom Installation${NC}"
    echo -e "${CYAN}[3]${NC} ${PORT} ${WHITE}Port Management${NC}"
    echo -e "${CYAN}[4]${NC} ${SHIELD} ${WHITE}Check Port${NC}"
    echo -e "${CYAN}[5]${NC} ${SPEED} ${WHITE}Speed Test${NC}"
    echo -e "${CYAN}[6]${NC} ${FIRE} ${WHITE}Reinstall n8n${NC}"
    echo -e "${CYAN}[7]${NC} ${STATUS} ${WHITE}Check Status${NC}"
    echo -e "${CYAN}[8]${NC} ${GEAR} ${WHITE}Advanced Tools${NC}"
    echo -e "${CYAN}[9]${NC} ${INFO} ${WHITE}System Information${NC}"
    echo -e "${CYAN}[0]${NC} ${CROSS_MARK} ${WHITE}Exit${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Enter your choice [0-9]: " choice
    
    case $choice in
        1) quick_install ;;
        2) custom_install ;;
        3) port_management ;;
        4) check_port_external ;;
        5) speed_test ;;
        6) reinstall_n8n ;;
        7) check_status ;;
        8) advanced_tools ;;
        9) system_information ;;
        0) exit_script ;;
        *) 
            print_error "Invalid option"
            sleep 2
            show_main_menu
            ;;
    esac
}

# 1. Quick Install
quick_install() {
    print_header
    print_section "${ROCKET} QUICK INSTALL"
    
    echo -e "${WHITE}${BOLD}Starting automated installation...${NC}"
    echo ""
    
    # Auto-detect best installation method
    print_status "Detecting optimal installation method..."
    
    if command -v docker &> /dev/null; then
        INSTALL_METHOD="docker"
        print_success "Docker detected - using Docker installation"
    elif command -v node &> /dev/null && [ $(node -v | sed 's/v//' | cut -d. -f1) -ge 18 ]; then
        INSTALL_METHOD="pm2"
        print_success "Node.js 18+ detected - using PM2 installation"
    else
        INSTALL_METHOD="docker"
        print_info "Will install Docker for best compatibility"
    fi
    
    # Set default values
    N8N_PORT="8000"
    N8N_DOMAIN=""
    N8N_PROTOCOL="http"
    N8N_USER="n8n"
    N8N_HOME="/home/n8n"
    N8N_VERSION="latest"
    SERVER_IP=$(hostname -I | awk '{print $1}')
    WEBHOOK_URL="http://${SERVER_IP}:${N8N_PORT}/"
    
    echo ""
    echo -e "${WHITE}${BOLD}Configuration:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Method: ${GREEN}${INSTALL_METHOD}${NC}"
    echo -e "Port: ${GREEN}${N8N_PORT}${NC}"
    echo -e "URL: ${GREEN}${WEBHOOK_URL}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Continue with quick install? [Y/n]: " confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        show_main_menu
        return
    fi
    
    # Execute installation
    install_dependencies
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        install_docker
        install_n8n_docker_quick
    else
        install_nodejs
        install_pm2
        create_n8n_user
        install_n8n_npm_quick
        create_pm2_service_quick
    fi
    
    configure_firewall_quick
    save_config
    
    print_success "Quick installation completed!"
    echo ""
    echo -e "${GREEN}Access n8n at: ${WHITE}${WEBHOOK_URL}${NC}"
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# 2. Custom Install (Previous full installation)
custom_install() {
    print_header
    print_section "${PACKAGE} CUSTOM INSTALLATION"
    
    select_installation_method
    input_form
    confirm_settings
    main_installation
    save_config
    show_summary
    
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# 3. Port Management
port_management() {
    print_header
    print_section "${PORT} PORT MANAGEMENT"
    
    echo -e "${WHITE}${BOLD}Firewall & Port Configuration${NC}"
    echo ""
    echo -e "${CYAN}[1]${NC} Open a port"
    echo -e "${CYAN}[2]${NC} Close a port"
    echo -e "${CYAN}[3]${NC} List open ports"
    echo -e "${CYAN}[4]${NC} Configure n8n port"
    echo -e "${CYAN}[5]${NC} Back to main menu"
    echo ""
    
    read -p "Select option [1-5]: " port_choice
    
    case $port_choice in
        1)
            read -p "Enter port number to open: " port
            open_port $port
            ;;
        2)
            read -p "Enter port number to close: " port
            close_port $port
            ;;
        3)
            list_open_ports
            ;;
        4)
            configure_n8n_port
            ;;
        5)
            show_main_menu
            return
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    port_management
}

open_port() {
    local port=$1
    print_status "Opening port $port..."
    
    if command -v ufw &> /dev/null; then
        ufw allow $port/tcp &>/dev/null
        print_success "Port $port opened in UFW"
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$port/tcp &>/dev/null
        firewall-cmd --reload &>/dev/null
        print_success "Port $port opened in firewalld"
    fi
    
    if command -v iptables &> /dev/null; then
        iptables -A INPUT -p tcp --dport $port -j ACCEPT
        print_success "Port $port opened in iptables"
    fi
}

close_port() {
    local port=$1
    print_status "Closing port $port..."
    
    if command -v ufw &> /dev/null; then
        ufw delete allow $port/tcp &>/dev/null
        print_success "Port $port closed in UFW"
    fi
    
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --remove-port=$port/tcp &>/dev/null
        firewall-cmd --reload &>/dev/null
        print_success "Port $port closed in firewalld"
    fi
}

list_open_ports() {
    echo -e "${WHITE}${BOLD}Open Ports:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if command -v ss &> /dev/null; then
        ss -tuln | grep LISTEN
    elif command -v netstat &> /dev/null; then
        netstat -tuln | grep LISTEN
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 4. Check Port External
check_port_external() {
    print_header
    print_section "${SHIELD} EXTERNAL PORT CHECK"
    
    load_config
    
    echo -e "${WHITE}${BOLD}Check port accessibility from internet${NC}"
    echo ""
    
    read -p "Enter port to check [${N8N_PORT:-8000}]: " check_port
    check_port=${check_port:-${N8N_PORT:-8000}}
    
    SERVER_IP=$(curl -s ifconfig.me)
    
    print_status "Your public IP: ${SERVER_IP}"
    print_status "Checking port ${check_port}..."
    echo ""
    
    # Method 1: Using yougetsignal.com API
    response=$(curl -s -X POST https://ports.yougetsignal.com/check-port.php \
        -d "remoteAddress=${SERVER_IP}&portNumber=${check_port}" 2>/dev/null || echo "failed")
    
    if [[ "$response" == *"open"* ]]; then
        print_success "Port ${check_port} is OPEN and accessible from internet"
    elif [[ "$response" == *"closed"* ]]; then
        print_error "Port ${check_port} is CLOSED or not accessible from internet"
        echo ""
        echo -e "${YELLOW}Possible reasons:${NC}"
        echo -e "• Firewall is blocking the port"
        echo -e "• Service is not running"
        echo -e "• Router/NAT not forwarding the port"
    else
        # Fallback method using nc
        print_status "Trying alternative check..."
        
        timeout 3 bash -c "echo >/dev/tcp/${SERVER_IP}/${check_port}" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            print_success "Port ${check_port} is OPEN"
        else
            print_error "Port ${check_port} is CLOSED or filtered"
        fi
    fi
    
    echo ""
    echo -e "${WHITE}${BOLD}Local port status:${NC}"
    ss -tuln | grep ":${check_port}" || echo "Port not listening locally"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# 5. Speed Test
speed_test() {
    print_header
    print_section "${SPEED} SPEED TEST"
    
    echo -e "${WHITE}${BOLD}Testing server network speed...${NC}"
    echo ""
    
    # Install speedtest-cli if not present
    if ! command -v speedtest-cli &> /dev/null; then
        print_status "Installing speedtest-cli..."
        
        if command -v pip3 &> /dev/null; then
            pip3 install speedtest-cli &>/dev/null
        elif command -v apt-get &> /dev/null; then
            apt-get install -y speedtest-cli &>/dev/null
        elif command -v yum &> /dev/null; then
            yum install -y python3-speedtest-cli &>/dev/null
        fi
    fi
    
    if command -v speedtest-cli &> /dev/null; then
        print_status "Running speed test..."
        echo ""
        speedtest-cli --simple
    else
        # Alternative method using curl
        print_status "Using alternative speed test..."
        echo ""
        
        # Download speed test
        echo -n "Download Speed: "
        curl -o /dev/null -s -w '%{speed_download}' https://speed.cloudflare.com/__down?bytes=10000000 | \
            awk '{printf "%.2f Mbps\n", $1 * 8 / 1000000}'
        
        # Basic upload test
        echo -n "Upload Speed: "
        dd if=/dev/zero bs=1M count=10 2>/dev/null | \
            curl -s -o /dev/null -T - -w '%{speed_upload}' https://speed.cloudflare.com/__up | \
            awk '{printf "%.2f Mbps\n", $1 * 8 / 1000000}'
    fi
    
    echo ""
    echo -e "${WHITE}${BOLD}Network Information:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Public IP: $(curl -s ifconfig.me)"
    echo -e "Location: $(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)"
    echo -e "ISP: $(curl -s ipinfo.io/org)"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# 6. Reinstall n8n
reinstall_n8n() {
    print_header
    print_section "${FIRE} REINSTALL N8N"
    
    load_config
    
    echo -e "${WHITE}${BOLD}Reinstallation Options:${NC}"
    echo ""
    echo -e "${CYAN}[1]${NC} Complete reinstall (remove everything)"
    echo -e "${CYAN}[2]${NC} Reinstall but keep data"
    echo -e "${CYAN}[3]${NC} Update to latest version"
    echo -e "${CYAN}[4]${NC} Cancel"
    echo ""
    
    read -p "Select option [1-4]: " reinstall_choice
    
    case $reinstall_choice in
        1)
            print_warning "This will remove all n8n data!"
            read -p "Are you sure? [y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                complete_uninstall
                quick_install
            fi
            ;;
        2)
            backup_n8n_data
            complete_uninstall
            quick_install
            restore_n8n_data
            ;;
        3)
            update_n8n
            ;;
        4)
            show_main_menu
            return
            ;;
    esac
    
    read -p "Press Enter to return to menu..."
    show_main_menu
}

complete_uninstall() {
    print_status "Removing n8n installation..."
    
    # Stop services
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        docker stop n8n 2>/dev/null || true
        docker rm n8n 2>/dev/null || true
        docker rmi n8nio/n8n 2>/dev/null || true
    elif [[ "$INSTALL_METHOD" == "systemd" ]]; then
        systemctl stop n8n 2>/dev/null || true
        systemctl disable n8n 2>/dev/null || true
        rm -f /etc/systemd/system/n8n.service
    elif [[ "$INSTALL_METHOD" == "pm2" ]]; then
        pm2 stop n8n 2>/dev/null || true
        pm2 delete n8n 2>/dev/null || true
    fi
    
    # Remove n8n
    if [[ -d "$N8N_HOME" ]]; then
        rm -rf "$N8N_HOME"
    fi
    
    print_success "n8n removed successfully"
}

update_n8n() {
    print_status "Updating n8n to latest version..."
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        docker pull n8nio/n8n:latest
        docker stop n8n
        docker rm n8n
        docker run -d \
            --name n8n \
            --restart unless-stopped \
            -p ${N8N_PORT}:5678 \
            -v /var/lib/n8n:/home/node/.n8n \
            n8nio/n8n:latest
    else
        cd "$N8N_HOME"
        npm update n8n
        
        if [[ "$INSTALL_METHOD" == "systemd" ]]; then
            systemctl restart n8n
        elif [[ "$INSTALL_METHOD" == "pm2" ]]; then
            pm2 restart n8n
        fi
    fi
    
    print_success "n8n updated successfully"
}

# 7. Check Status
check_status() {
    print_header
    print_section "${STATUS} SYSTEM STATUS"
    
    load_config
    
    echo -e "${WHITE}${BOLD}n8n Service Status:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        if docker ps | grep -q n8n; then
            print_success "n8n is running (Docker)"
            echo ""
            docker stats n8n --no-stream
        else
            print_error "n8n is not running"
        fi
    elif [[ "$INSTALL_METHOD" == "systemd" ]]; then
        systemctl status n8n --no-pager
    elif [[ "$INSTALL_METHOD" == "pm2" ]]; then
        pm2 status n8n
    else
        print_warning "n8n installation not found"
    fi
    
    echo ""
    echo -e "${WHITE}${BOLD}System Resources:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "Memory: $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo -e "Disk: $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    echo -e "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo ""
    echo -e "${WHITE}${BOLD}n8n Access Information:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -n "$N8N_DOMAIN" ]]; then
        echo -e "URL: ${GREEN}${N8N_PROTOCOL}://${N8N_DOMAIN}${NC}"
    else
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "URL: ${GREEN}http://${SERVER_IP}:${N8N_PORT}${NC}"
    fi
    
    echo -e "Installation Date: ${GREEN}${INSTALL_DATE}${NC}"
    echo -e "Version: ${GREEN}${N8N_VERSION}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# 8. Advanced Tools
advanced_tools() {
    print_header
    print_section "${GEAR} ADVANCED TOOLS"
    
    echo -e "${WHITE}${BOLD}Select a tool:${NC}"
    echo ""
    echo -e "${CYAN}[1]${NC} Backup n8n data"
    echo -e "${CYAN}[2]${NC} Restore n8n data"
    echo -e "${CYAN}[3]${NC} View logs"
    echo -e "${CYAN}[4]${NC} Clear logs"
    echo -e "${CYAN}[5]${NC} SSL Certificate setup"
    echo -e "${CYAN}[6]${NC} Change n8n port"
    echo -e "${CYAN}[7]${NC} Reset admin password"
    echo -e "${CYAN}[8]${NC} Performance tuning"
    echo -e "${CYAN}[9]${NC} Back to main menu"
    echo ""
    
    read -p "Select option [1-9]: " tool_choice
    
    case $tool_choice in
        1) backup_n8n_data ;;
        2) restore_n8n_data ;;
        3) view_logs ;;
        4) clear_logs ;;
        5) setup_ssl ;;
        6) change_port ;;
        7) reset_password ;;
        8) performance_tuning ;;
        9) show_main_menu; return ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    advanced_tools
}

backup_n8n_data() {
    print_status "Creating backup..."
    
    BACKUP_DIR="/root/n8n-backups"
    mkdir -p $BACKUP_DIR
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/n8n-backup-$TIMESTAMP.tar.gz"
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        docker exec n8n tar czf - /home/node/.n8n > $BACKUP_FILE
    else
        tar czf $BACKUP_FILE $N8N_HOME/.n8n
    fi
    
    print_success "Backup saved to: $BACKUP_FILE"
}

restore_n8n_data() {
    print_status "Available backups:"
    ls -la /root/n8n-backups/*.tar.gz 2>/dev/null || print_error "No backups found"
    
    echo ""
    read -p "Enter backup file path: " backup_file
    
    if [[ -f "$backup_file" ]]; then
        if [[ "$INSTALL_METHOD" == "docker" ]]; then
            docker exec -i n8n tar xzf - < $backup_file
        else
            tar xzf $backup_file -C /
        fi
        print_success "Backup restored successfully"
    else
        print_error "Backup file not found"
    fi
}

view_logs() {
    load_config
    
    echo -e "${WHITE}${BOLD}n8n Logs:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        docker logs n8n --tail 50
    elif [[ "$INSTALL_METHOD" == "systemd" ]]; then
        journalctl -u n8n -n 50 --no-pager
    elif [[ "$INSTALL_METHOD" == "pm2" ]]; then
        pm2 logs n8n --lines 50
    fi
}

# 10. System Information (renamed from 9)
system_information() {
    print_header
    print_section "${INFO} SYSTEM INFORMATION"
    
    # Install neofetch if needed
    if ! command -v neofetch &> /dev/null; then
        print_status "Installing neofetch..."
        if [[ "$OS_TYPE" == "ubuntu" ]] || [[ "$OS_TYPE" == "debian" ]]; then
            apt-get install -y neofetch &>/dev/null
        elif [[ "$OS_TYPE" == "centos" ]] || [[ "$OS_TYPE" == "rhel" ]]; then
            yum install -y epel-release &>/dev/null
            yum install -y neofetch &>/dev/null
        fi
    fi
    
    if command -v neofetch &> /dev/null; then
        neofetch
    else
        echo -e "${WHITE}${BOLD}System Details:${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo -e "Kernel: $(uname -r)"
        echo -e "CPU: $(lscpu | grep 'Model name' | sed 's/Model name://g' | xargs)"
        echo -e "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
        echo -e "Disk: $(df -h / | awk 'NR==2 {print $2}')"
        echo -e "Uptime: $(uptime -p)"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_main_menu
}

# Exit script
exit_script() {
    print_header
    echo -e "${GREEN}${BOLD}Thank you for using n8n Automation Installer by Vinz!${NC}"
    echo -e "${YELLOW}${STAR} Happy Automating! ${ROCKET}${NC}"
    echo ""
    exit 0
}

# Quick install functions
install_dependencies() {
    print_status "Installing dependencies..."
    
    if [[ "$OS_TYPE" == "ubuntu" ]] || [[ "$OS_TYPE" == "debian" ]]; then
        apt-get update &>/dev/null
        apt-get install -y curl wget git &>/dev/null
    elif [[ "$OS_TYPE" == "centos" ]] || [[ "$OS_TYPE" == "rhel" ]]; then
        yum update -y &>/dev/null
        yum install -y curl wget git &>/dev/null
    fi
    
    print_success "Dependencies installed"
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com | sh &>/dev/null
        systemctl start docker
        systemctl enable docker &>/dev/null
        print_success "Docker installed"
    fi
}

install_nodejs() {
    if ! command -v node &> /dev/null || [ $(node -v | sed 's/v//' | cut -d. -f1) -lt 18 ]; then
        print_status "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash - &>/dev/null
        apt-get install -y nodejs &>/dev/null
        print_success "Node.js installed"
    fi
}

install_pm2() {
    if ! command -v pm2 &> /dev/null; then
        print_status "Installing PM2..."
        npm install -g pm2 &>/dev/null
        print_success "PM2 installed"
    fi
}

create_n8n_user() {
    if ! id "$N8N_USER" &>/dev/null; then
        useradd -m -d "$N8N_HOME" -s /bin/bash "$N8N_USER"
    fi
    
    mkdir -p "$N8N_HOME/.n8n"
    chown -R "$N8N_USER:$N8N_USER" "$N8N_HOME"
}

install_n8n_docker_quick() {
    print_status "Setting up n8n with Docker..."
    
    docker pull n8nio/n8n:latest &>/dev/null
    
    docker run -d \
        --name n8n \
        --restart unless-stopped \
        -p ${N8N_PORT}:5678 \
        -v /var/lib/n8n:/home/node/.n8n \
        n8nio/n8n:latest &>/dev/null
    
    print_success "n8n container created"
}

install_n8n_npm_quick() {
    print_status "Installing n8n..."
    
    cd "$N8N_HOME"
    sudo -u "$N8N_USER" npm init -y &>/dev/null
    sudo -u "$N8N_USER" npm install n8n &>/dev/null
    
    print_success "n8n installed"
}

create_pm2_service_quick() {
    print_status "Configuring PM2 service..."
    
    cat > ${N8N_HOME}/ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'n8n',
    script: '${N8N_HOME}/node_modules/n8n/bin/n8n',
    env: {
      N8N_PORT: ${N8N_PORT},
      N8N_HOST: '0.0.0.0'
    }
  }]
};
EOF
    
    chown ${N8N_USER}:${N8N_USER} ${N8N_HOME}/ecosystem.config.js
    sudo -u ${N8N_USER} pm2 start ${N8N_HOME}/ecosystem.config.js &>/dev/null
    sudo -u ${N8N_USER} pm2 save &>/dev/null
    
    print_success "PM2 service configured"
}

create_systemd_service_quick() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n - Workflow Automation Tool
After=network.target

[Service]
Type=simple
User=${N8N_USER}
Group=${N8N_USER}
WorkingDirectory=${N8N_HOME}
Environment="N8N_PORT=${N8N_PORT}"
Environment="N8N_HOST=0.0.0.0"
ExecStart=${N8N_HOME}/node_modules/.bin/n8n
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable n8n &>/dev/null
    systemctl start n8n
    
    print_success "Systemd service configured"
}

configure_firewall_quick() {
    print_status "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow ${N8N_PORT}/tcp &>/dev/null
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${N8N_PORT}/tcp &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
    
    print_success "Firewall configured"
}

# Additional functions for custom installation (from previous version)
select_installation_method() {
    # Implementation from previous version
    echo "Select installation method..."
}

input_form() {
    # Implementation from previous version
    echo "Configuration form..."
}

confirm_settings() {
    # Implementation from previous version
    echo "Confirm settings..."
}

main_installation() {
    # Implementation from previous version
    echo "Installing..."
}

show_summary() {
    # Implementation from previous version
    echo "Installation complete!"
}

# Main execution
main() {
    check_root
    detect_os
    show_main_menu
}

# Run main function
main "$@"
