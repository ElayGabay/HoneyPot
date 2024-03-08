#!/bin/bash



GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)
RED=$(tput setaf 1)

# Record the start time when the script starts
start_time=$(date +%s)

function INSTALL_FIGLET() {
    if ! command -v figlet &> /dev/null; then
        sudo apt-get install -y figlet &> /dev/null 
    fi
    echo -e "\e[31m$(figlet HoneyPot :0)\e[0m"
}

function INSTALL_APP() {
    if ! command -v ssh &>/dev/null; then 
        echo "[@]Downloading ssh...."
        sudo apt-get install -y ssh >/dev/null
    fi

    if ! command -v samba &>/dev/null; then 
        echo "[@]Downloading samba...."
        sudo apt-get install -y samba >/dev/null
    fi

    if ! command -v vsftpd &>/dev/null; then 
        echo "[@]Downloading vsftpd...."
        sudo apt-get install -y vsftpd >/dev/null
    fi
}

function START_TIME () {
    echo -e ""
    echo "${GREEN}[*]${RESET}HoneyPot started at: ${BLUE}[$(date -d @$start_time '+%Y-%m-%d %H:%M:%S')]${RESET}"
    echo -e ""
}

function CHOOSE_ANSWER() {
    while true; do
        read -rp "${BLUE}[?]${RESET}Would you like to make a weak user and password (Yes/No)? " answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        if [[ "$answer" == "yes" ]]; then
            read -rp "${BLUE}[?]${RESET}What username would you like to recommend? " username
            break
        elif [[ "$answer" == "no" ]]; then
            break
        else
            echo "${RED}[-]${RESET}Error: Please enter either 'Yes' or 'No'." >/dev/null
        fi
    done
}

function ADDUSER() {
    username="$1"
    if ! id "$username" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$username" >/dev/null 2>&1
        echo "$username:$username" | sudo chpasswd >/dev/null 2>&1
        echo "${GREEN}[*]${RESET}User '$username' created with password '$username'." >/dev/null
        sudo chown "$username:$username" "/home/$username/.bashrc" >/dev/null 2>&1
        echo "${GREEN}[*]${RESET}Adjusted permissions for '$username'." >/dev/null
    else
        echo "User '$username' already exists."
    fi
}

function CHOSE() {
    echo -e ""
    echo "${GREEN}[*]${RESET}Alerter - Network HoneyPot"
    echo -e ""
    echo -e "1. SSH\n2. FTP\n3. SMB\n4. Start all Services"
    echo -e ""

    while true; do
        read -rp "${BLUE}[?]${RESET}Enter your Choice: " choice

        case $choice in
            1)
                echo "${GREEN}[*]${RESET}Starting SSH service..."
                SERVEICE_SSH
                echo "${GREEN}[*]${RESET}Monitoring SSH services..."
                echo -e ""
                break  # Exit the loop after starting the service
                ;;
            2)
                echo "${GREEN}[*]${RESET}Starting FTP service..."
                SERVEICE_VSFTPD
                echo "${GREEN}[*]${RESET}Monitoring FTP services..."
                echo -e ""
                break
                ;;
            3)
                echo "${GREEN}[*]${RESET}Starting SMB service..."
                SERVEICE_SMB
                SHARE
                echo "${GREEN}[*]${RESET}Monitoring SMB services..."
                echo -e ""
                break
                ;;
            4)
                echo "${GREEN}[*]${RESET}Starting all services..."
                SERVEICE_SSH
                SERVEICE_VSFTPD
                SERVEICE_SMB
                SHARE
                echo "${GREEN}[*]${RESET}Monitoring SSH, FTP, and SMB services..."
                echo -e ""
                break
                ;;
            *)
                echo "${RED}[-]${RESET}Error: Please enter a valid option (1, 2, 3, or 4)."
                ;;
        esac
    done
}

function SERVEICE_SSH() {
    service="ssh"
    sudo systemctl is-active --quiet $service
    if [ $? -ne 0 ]; then
        echo "${RED}[!]${RESET}Service $service is not running, attempting to start..." &>/dev/null
        sudo systemctl start $service
        sleep 2
        sudo systemctl is-active --quiet $service
        if [ $? -ne 0 ]; then
            echo "${RED}[-]${RESET}Failed to start service $service" &>/dev/null
        else
            echo "${GREEN}[*]${RESET}Service $service started successfully" &>/dev/null
        fi
    else
        echo "${GREEN}[*]${RESET}Service $service is already running" &>/dev/null
    fi
}

function SERVEICE_SMB() {
    service="smbd"
    sudo systemctl is-active --quiet $service
    if [ $? -ne 0 ]; then
        echo "${RED}[!]${RESET}Service $service is not running, attempting to start..." &>/dev/null
        sudo systemctl start $service
        sleep 2
        sudo systemctl is-active --quiet $service
        if [ $? -ne 0 ]; then
            echo "${RED}[-]${RESET}Failed to start service $service" &>/dev/null
        else
            echo "${GREEN}[*]${RESET}Service $service started successfully" &>/dev/null
        fi
    else
        echo "${GREEN}[*]${RESET}Service $service is already running" &>/dev/null
    fi

    # Add log level configuration to smb.conf
    log_level_conf="log level = 2 auth:3 smbd:3 tdb:4"
    if ! sudo grep -qF "$log_level_conf" /etc/samba/smb.conf; then
        echo "$log_level_conf" | sudo tee -a /etc/samba/smb.conf >/dev/null
        echo "${GREEN}[*]${RESET}Added log level configuration to smb.conf" &>/dev/null
        # Restart smbd service after updating smb.conf
        sudo systemctl restart smbd >/dev/null
        echo "${GREEN}[*]${RESET}Restarted smbd service for configuration changes to take effect" &>/dev/null
    else
        echo "${GREEN}[*]${RESET}Log level configuration is already present in smb.conf" &>/dev/null
    fi
}

function SERVEICE_VSFTPD() {
    service="vsftpd"
    sudo systemctl is-active --quiet $service
    if [ $? -ne 0 ]; then
        echo "${RED}[!]${RESET}Service $service is not running, attempting to start..." &>/dev/null
        sudo systemctl start $service
        sleep 2
        sudo systemctl is-active --quiet $service
        if [ $? -ne 0 ]; then
            echo "${RED}[-]${RESET}Failed to start service $service" &>/dev/null
        else
            echo "${GREEN}[*]${RESET}Service $service started successfully" &>/dev/null
        fi
    else
        echo "${GREEN}[*]${RESET}Service $service is already running" &>/dev/null
    fi
}

function SHARE() {

    # Define the directory path
    local directory_path=$(realpath -q -s ./admin2)

    # Check if the directory already exists
    if [ -d "$directory_path" ]; then
        echo "Directory '$directory_path' already exists. Skipping creation." >/dev/null
    else
        # Step 1: Create directory
        mkdir -p "$directory_path" >/dev/null
        
        # Step 2: Set permissions
        chmod -R 777 "$directory_path" >/dev/null
        
        # Step 4: Edit Samba configuration
        sudo tee -a /etc/samba/smb.conf >/dev/null <<EOT
[admin2]
    comment = Shared Directory
    path = $directory_path
    browseable = yes
    read only = no
    guest ok = yes
EOT
        
        # Step 5: Restart Samba service
        sudo systemctl restart smbd >/dev/null
        
        echo "Shared directory '$directory_path' created successfully!" >/dev/null
    fi
}


function DIRECTORY() {

    processed_ips_loction=$(sudo find / -type f -name processed_ips.txt 2>/dev/null)
    Nmap_scan_loction=$(sudo find / -type f -name Nmap_scan.txt 2>/dev/null)


    if [ ! -f "$Nmap_scan_loction" ]; then
        touch Nmap_scan.txt
    else
        exit
    fi

    if [ ! -f "$processed_ips_loction" ]; then
        touch processed_ips.txt
        echo "127.0.0.1" >> processed_ips.txt
        echo "0.0.0.0" >> processed_ips.txt
    else
        exit
    fi

}

function MONITOR_AND_INFO() {
    while true; do
        tail -n 0 -F port_monitor.log 2>/dev/null | while read -r line; do 
            ip_address=$(echo "$line" | awk '{print $5}' | grep -oP '(\d{1,3}\.){3}\d{1,3}')
            if [ -n "$ip_address" ]; then
                if ! awk -v ip="$ip_address" '$0 ~ ip { found=1; exit } END { exit !found }' processed_ips.txt; then
                    timestamp=$(date +"%Y-%m-%d %T")
                    country=$(curl -s "https://ipwhois.app/json/$ip_address" | grep -oP '(?<="country":")[^"]+')
                    organisation=$(curl -s "https://ipwhois.app/json/$ip_address" | grep -oP '(?<="org":")[^"]+')
                    phone_number=$(curl -s "https://ipwhois.app/json/$ip_address" | grep -oP '(?<="country_phone":")[^"]+')
                    echo -e "[$timestamp]IP address:$ip_address The Country:$country Org name:$organisation Phone-number:$phone_number"
                    echo -e "" >> country_info.txt
                    echo -e "IP address: $ip_address\nCountry: $country\nOrg: $organisation\nPhone: $phone_number" >> country_info.txt
                    sudo nmap -sV  $ip_address >> Nmap_scan.txt
                    echo -e "" >> Nmap_scan.txt  
                    echo "$ip_address" >> processed_ips.txt
                fi
            fi
        done
        sleep 1
    done
}


function MAIN (){

    INSTALL_FIGLET
    START_TIME
    CHOOSE_ANSWER
    ADDUSER "$username"
    CHOSE

    DIRECTORY
    MONITOR_AND_INFO &

    # Start the netstat loop
    while true; do
       sudo netstat -natp -t | grep -E "(:21|:22|:445)" | grep "ESTABLISHED" >> port_monitor.log
        sleep 1

        # Delete the first 10 lines of the file after 2 seconds
        sleep 5
        sed -i '1,5d' port_monitor.log
    done


    DISPLAY_ELAPSED_TIME
}

# Capture interrupt signal to stop the netstat loop
trap 'jobs -p | xargs -r kill; exit' INT &>/dev/null

MAIN
