#!/bin/bash

#############################################
# n8n Automation Installer by Vinz
# Interactive Installation Script
# Version: 2.0
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

# Configuration variables (will be set by user input)
N8N_PORT=""
N8N_DOMAIN=""
N8N_PROTOCOL=""
N8N_USER="n8n"
N8N_HOME="/home/n8n"
NODE_VERSION="18"
N8N_VERSION="latest"
INSTALL_METHOD=""
USE_SSL=""
ADMIN_EMAIL=""
N8N_BASIC_AUTH_USER=""
N8N_BASIC_AUTH_PASS=""
WEBHOOK_URL=""
INSTALL_NGINX=""
INSTALL_DOCKER=""

# Log file
LOG_FILE="/var/log/n8n-installer-$(date +%Y%m%d-%H%M%S).log"
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
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local duration=$1
    local steps=50
    local step_duration=$(echo "scale=2; $duration / $steps" | bc)
    
    echo -n "["
    for ((i=0; i<$steps; i++)); do
        echo -n "="
        sleep $step_duration
    done
    echo "] Done!"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        echo -e "${YELLOW}Please run: ${WHITE}sudo $0${NC}"
        exit 1
    fi
}

# Install neofetch if not present
install_neofetch() {
    if ! command -v neofetch &> /dev/null; then
        print_status "Installing neofetch..."
        if [[ -f /etc/debian_version ]]; then
            apt-get update &>/dev/null
            apt-get install -y neofetch &>/dev/null
        elif [[ -f /etc/redhat-release ]]; then
            yum install -y epel-release &>/dev/null
            yum install -y neofetch &>/dev/null
        fi
    fi
}

# Show system information
show_system_info() {
    print_header
    print_section "${SERVER} SYSTEM INFORMATION"
    
    if command -v neofetch &> /dev/null; then
        neofetch --config none --ascii_distro linux --color_blocks off \
                 --cpu_temp on --memory_percent on --disk_percent on \
                 --underline_enabled off --bold on
    else
        # Fallback if neofetch is not available
        echo -e "${WHITE}${BOLD}System Information:${NC}"
        echo -e "${CYAN}OS:${NC} $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo -e "${CYAN}Kernel:${NC} $(uname -r)"
        echo -e "${CYAN}CPU:${NC} $(lscpu | grep 'Model name' | sed 's/Model name://g' | xargs)"
        echo -e "${CYAN}Memory:${NC} $(free -h | awk '/^Mem:/ {print $2 " total, " $3 " used"}')"
        echo -e "${CYAN}Disk:${NC} $(df -h / | awk 'NR==2 {print $2 " total, " $3 " used (" $5 ")"}')"
        echo -e "${CYAN}Hostname:${NC} $(hostname)"
        echo -e "${CYAN}IP Address:${NC} $(hostname -I | awk '{print $1}')"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Input form for configuration
input_form() {
    print_header
    print_section "${GEAR} CONFIGURATION SETUP"
    
    # Port configuration
    echo -e "${WHITE}${BOLD}1. Network Configuration${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────┐${NC}"
    
    while true; do
        echo -ne "${CYAN}│${NC} ${WHITE}Port Number${NC} [${GREEN}8000${NC}]: "
        read N8N_PORT
        N8N_PORT=${N8N_PORT:-8000}
        if [[ "$N8N_PORT" =~ ^[0-9]+$ ]] && [ "$N8N_PORT" -ge 1 ] && [ "$N8N_PORT" -le 65535 ]; then
            break
        else
            print_error "Invalid port number. Please enter a number between 1-65535"
        fi
    done
    
    echo -ne "${CYAN}│${NC} ${WHITE}Domain Name${NC} [${GREEN}optional${NC}]: "
    read N8N_DOMAIN
    
    if [ -n "$N8N_DOMAIN" ]; then
        echo -ne "${CYAN}│${NC} ${WHITE}Use HTTPS?${NC} [${GREEN}y${NC}/n]: "
        read USE_SSL
        USE_SSL=${USE_SSL:-y}
        
        if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
            N8N_PROTOCOL="https"
            echo -ne "${CYAN}│${NC} ${WHITE}Email for SSL${NC}: "
            read ADMIN_EMAIL
        else
            N8N_PROTOCOL="http"
        fi
        WEBHOOK_URL="${N8N_PROTOCOL}://${N8N_DOMAIN}/"
    else
        N8N_PROTOCOL="http"
        SERVER_IP=$(hostname -I | awk '{print $1}')
        WEBHOOK_URL="http://${SERVER_IP}:${N8N_PORT}/"
    fi
    
    echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"
    echo ""
    
    # Security configuration
    echo -e "${WHITE}${BOLD}2. Security Configuration${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────┐${NC}"
    
    echo -ne "${CYAN}│${NC} ${WHITE}Enable Basic Auth?${NC} [${GREEN}y${NC}/n]: "
    read ENABLE_AUTH
    ENABLE_AUTH=${ENABLE_AUTH:-y}
    
    if [[ "$ENABLE_AUTH" =~ ^[Yy]$ ]]; then
        echo -ne "${CYAN}│${NC} ${WHITE}Admin Username${NC}: "
        read N8N_BASIC_AUTH_USER
        
        echo -ne "${CYAN}│${NC} ${WHITE}Admin Password${NC}: "
        read -s N8N_BASIC_AUTH_PASS
        echo ""
    fi
    
    echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"
    echo ""
    
    # Installation options
    echo -e "${WHITE}${BOLD}3. Installation Options${NC}"
    echo -e "${CYAN}┌─────────────────────────────────────────┐${NC}"
    
    echo -ne "${CYAN}│${NC} ${WHITE}Install Nginx Proxy?${NC} [${GREEN}y${NC}/n]: "
    read INSTALL_NGINX
    INSTALL_NGINX=${INSTALL_NGINX:-y}
    
    echo -ne "${CYAN}│${NC} ${WHITE}Use Docker if needed?${NC} [${GREEN}y${NC}/n]: "
    read INSTALL_DOCKER
    INSTALL_DOCKER=${INSTALL_DOCKER:-y}
    
    echo -ne "${CYAN}│${NC} ${WHITE}n8n Version${NC} [${GREEN}latest${NC}]: "
    read N8N_VERSION
    N8N_VERSION=${N8N_VERSION:-latest}
    
    echo -e "${CYAN}└─────────────────────────────────────────┘${NC}"
    echo ""
}

# Confirmation screen
confirm_settings() {
    print_header
    print_section "${LOCK} CONFIRMATION"
    
    echo -e "${WHITE}${BOLD}Your Configuration:${NC}"
    echo ""
    echo -e "${CYAN}┌─────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Port:${NC}              ${GREEN}${N8N_PORT}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Domain:${NC}            ${GREEN}${N8N_DOMAIN:-Not configured}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Protocol:${NC}          ${GREEN}${N8N_PROTOCOL}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Webhook URL:${NC}       ${GREEN}${WEBHOOK_URL}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Basic Auth:${NC}        ${GREEN}${N8N_BASIC_AUTH_USER:-Disabled}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Install Nginx:${NC}     ${GREEN}${INSTALL_NGINX}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Docker Fallback:${NC}   ${GREEN}${INSTALL_DOCKER}${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}n8n Version:${NC}       ${GREEN}${N8N_VERSION}${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -ne "${YELLOW}${BOLD}Proceed with installation? [y/N]:${NC} "
    read CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi
}

# Progress display
show_progress() {
    local task=$1
    echo -ne "${CYAN}${ARROW}${NC} ${task}..."
}

complete_progress() {
    echo -e " ${GREEN}${CHECK_MARK}${NC}"
}

fail_progress() {
    echo -e " ${RED}${CROSS_MARK}${NC}"
}

# Install dependencies
install_dependencies() {
    show_progress "Installing system dependencies"
    
    if [[ -f /etc/debian_version ]]; then
        apt-get update &>/dev/null
        apt-get install -y curl wget git build-essential python3 gcc g++ make bc &>/dev/null
    elif [[ -f /etc/redhat-release ]]; then
        yum update -y &>/dev/null
        yum groupinstall -y "Development Tools" &>/dev/null
        yum install -y curl wget git python3 bc &>/dev/null
    fi
    
    complete_progress
}

# Install Node.js
install_nodejs() {
    show_progress "Installing Node.js ${NODE_VERSION}"
    
    if [[ -f /etc/debian_version ]]; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - &>/dev/null
        apt-get install -y nodejs &>/dev/null
    elif [[ -f /etc/redhat-release ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - &>/dev/null
        yum install -y nodejs &>/dev/null
    fi
    
    complete_progress
    print_info "Node.js $(node -v) installed"
}

# Create n8n user
create_n8n_user() {
    show_progress "Creating n8n user environment"
    
    if ! id "$N8N_USER" &>/dev/null; then
        useradd -m -d "$N8N_HOME" -s /bin/bash "$N8N_USER"
    fi
    
    mkdir -p "$N8N_HOME/.n8n"
    chown -R "$N8N_USER:$N8N_USER" "$N8N_HOME"
    chmod 755 "$N8N_HOME/.n8n"
    
    complete_progress
}

# Try to install n8n
install_n8n() {
    show_progress "Installing n8n (${N8N_VERSION})"
    
    # Try local installation first
    cd "$N8N_HOME"
    sudo -u "$N8N_USER" npm init -y &>/dev/null
    
    if sudo -u "$N8N_USER" npm install n8n@${N8N_VERSION} &>/dev/null; then
        INSTALL_METHOD="local"
        complete_progress
        print_success "n8n installed successfully (local installation)"
    elif [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
        fail_progress
        show_progress "Falling back to Docker installation"
        
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com | sh &>/dev/null
            systemctl start docker
            systemctl enable docker &>/dev/null
        fi
        
        docker pull n8nio/n8n:latest &>/dev/null
        INSTALL_METHOD="docker"
        complete_progress
        print_success "n8n installed successfully (Docker)"
    else
        fail_progress
        print_error "Failed to install n8n"
        exit 1
    fi
}

# Create systemd service
create_service() {
    show_progress "Creating systemd service"
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        # Create Docker container
        docker run -d \
            --name n8n \
            --restart unless-stopped \
            -p ${N8N_PORT}:5678 \
            -e N8N_PORT=5678 \
            -e N8N_PROTOCOL=${N8N_PROTOCOL} \
            -e WEBHOOK_URL=${WEBHOOK_URL} \
            -e N8N_BASIC_AUTH_ACTIVE=$([ -n "$N8N_BASIC_AUTH_USER" ] && echo "true" || echo "false") \
            -e N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER} \
            -e N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASS} \
            -v /var/lib/n8n:/home/node/.n8n \
            n8nio/n8n:latest &>/dev/null
    else
        # Create systemd service
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
Environment="N8N_PROTOCOL=${N8N_PROTOCOL}"
Environment="N8N_HOST=0.0.0.0"
Environment="WEBHOOK_URL=${WEBHOOK_URL}"
Environment="N8N_BASIC_AUTH_ACTIVE=$([ -n "$N8N_BASIC_AUTH_USER" ] && echo "true" || echo "false")"
Environment="N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}"
Environment="N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASS}"
ExecStart=${N8N_HOME}/node_modules/.bin/n8n
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl enable n8n &>/dev/null
        systemctl start n8n
    fi
    
    complete_progress
}

# Configure Nginx
configure_nginx() {
    if [[ ! "$INSTALL_NGINX" =~ ^[Yy]$ ]]; then
        return
    fi
    
    show_progress "Configuring Nginx proxy"
    
    if ! command -v nginx &> /dev/null; then
        if [[ -f /etc/debian_version ]]; then
            apt-get install -y nginx &>/dev/null
        elif [[ -f /etc/redhat-release ]]; then
            yum install -y nginx &>/dev/null
        fi
    fi
    
    if [ -n "$N8N_DOMAIN" ]; then
        cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name ${N8N_DOMAIN};

    location / {
        proxy_pass http://127.0.0.1:${N8N_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
    }
}
EOF
        
        ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n 2>/dev/null
        nginx -t &>/dev/null && systemctl reload nginx &>/dev/null
        
        # Install SSL if requested
        if [[ "$USE_SSL" =~ ^[Yy]$ ]] && [ -n "$ADMIN_EMAIL" ]; then
            if ! command -v certbot &> /dev/null; then
                if [[ -f /etc/debian_version ]]; then
                    apt-get install -y certbot python3-certbot-nginx &>/dev/null
                fi
            fi
            
            certbot --nginx -d ${N8N_DOMAIN} --non-interactive --agree-tos -m ${ADMIN_EMAIL} --redirect &>/dev/null || true
        fi
    fi
    
    complete_progress
}

# Configure firewall
configure_firewall() {
    show_progress "Configuring firewall"
    
    if command -v ufw &> /dev/null; then
        ufw allow ${N8N_PORT}/tcp &>/dev/null
        ufw allow 80/tcp &>/dev/null
        ufw allow 443/tcp &>/dev/null
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${N8N_PORT}/tcp &>/dev/null
        firewall-cmd --permanent --add-port=80/tcp &>/dev/null
        firewall-cmd --permanent --add-port=443/tcp &>/dev/null
        firewall-cmd --reload &>/dev/null
    fi
    
    complete_progress
}

# Final summary
show_summary() {
    print_header
    print_section "${ROCKET} INSTALLATION COMPLETE!"
    
    echo -e "${GREEN}${BOLD}${CHECK_MARK} n8n has been successfully installed!${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Access Information:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [ -n "$N8N_DOMAIN" ]; then
        echo -e "${GLOBE} URL: ${GREEN}${N8N_PROTOCOL}://${N8N_DOMAIN}${NC}"
    else
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "${GLOBE} URL: ${GREEN}http://${SERVER_IP}:${N8N_PORT}${NC}"
    fi
    
    if [ -n "$N8N_BASIC_AUTH_USER" ]; then
        echo -e "${LOCK} Username: ${GREEN}${N8N_BASIC_AUTH_USER}${NC}"
        echo -e "${LOCK} Password: ${GREEN}[Hidden for security]${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Useful Commands:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ "$INSTALL_METHOD" == "docker" ]]; then
        echo -e "${PACKAGE} View logs:     ${WHITE}docker logs n8n -f${NC}"
        echo -e "${PACKAGE} Restart:       ${WHITE}docker restart n8n${NC}"
        echo -e "${PACKAGE} Stop:          ${WHITE}docker stop n8n${NC}"
        echo -e "${PACKAGE} Start:         ${WHITE}docker start n8n${NC}"
    else
        echo -e "${PACKAGE} View logs:     ${WHITE}journalctl -u n8n -f${NC}"
        echo -e "${PACKAGE} Status:        ${WHITE}systemctl status n8n${NC}"
        echo -e "${PACKAGE} Restart:       ${WHITE}systemctl restart n8n${NC}"
        echo -e "${PACKAGE} Stop:          ${WHITE}systemctl stop n8n${NC}"
        echo -e "${PACKAGE} Start:         ${WHITE}systemctl start n8n${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${WHITE}${BOLD}Installation Details:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Method:        ${GREEN}${INSTALL_METHOD}${NC}"
    echo -e "Version:       ${GREEN}${N8N_VERSION}${NC}"
    echo -e "User:          ${GREEN}${N8N_USER}${NC}"
    echo -e "Home:          ${GREEN}${N8N_HOME}${NC}"
    echo -e "Log file:      ${GREEN}${LOG_FILE}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo -e "${YELLOW}${STAR}${NC} Thank you for using ${MAGENTA}${BOLD}n8n Automation Installer by Vinz${NC}"
    echo -e "${YELLOW}${STAR}${NC} Happy Automating! ${ROCKET}"
    echo ""
}

# Main installation flow
main_installation() {
    print_header
    print_section "${PACKAGE} STARTING INSTALLATION"
    
    # Create installation steps array
    declare -a steps=(
        "install_dependencies"
        "install_nodejs"
        "create_n8n_user"
        "install_n8n"
        "create_service"
        "configure_nginx"
        "configure_firewall"
    )
    
    total_steps=${#steps[@]}
    current_step=0
    
    for step in "${steps[@]}"; do
        ((current_step++))
        echo -e "${WHITE}${BOLD}[${current_step}/${total_steps}]${NC} "
        $step
    done
    
    echo ""
    print_success "All installation steps completed!"
    sleep 2
}

# Error handler
handle_error() {
    print_error "An error occurred during installation"
    print_info "Check the log file: ${LOG_FILE}"
    exit 1
}

# Set error trap
trap handle_error ERR

# Main execution
main() {
    check_root
    install_neofetch
    show_system_info
    input_form
    confirm_settings
    main_installation
    show_summary
}

# Run main function
main "$@"
