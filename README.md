# HoneyPot Script

This script sets up a honeypot on your machine by starting SSH, FTP, and SMB services. It also creates a weak user and password for potential attackers to interact with the system. The script monitors network connections to these services and logs information about connected IP addresses.

## Warning

Running this script makes your machine vulnerable to attack. It creates a user with a weak password and opens services that could potentially be exploited by attackers. Use it only for educational or research purposes in a controlled environment.

## Usage

1. **Clone the Repository**:

    ```bash
    git clone <repository_url>
    ```

2. **Navigate to the Script Directory**:

    ```bash
    cd HoneyPot-Script
    ```

3. **Run the Script**:

    ```bash
    sudo ./honeypot.sh
    ```
   must run as root 

4. **Follow the On-Screen Instructions**:

    The script will prompt you to choose whether you want to create a weak user and password. You can also choose which services to start (SSH, FTP, SMB, or all services).

5. **Monitor Connections**:

    The script will continuously monitor network connections to the selected services and log information about connected IP addresses.

