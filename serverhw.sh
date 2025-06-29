#!/bin/bash


##########################################################
#    Server Hardware Information                         #
#    https://github.com/Har-Kuun/ServerHardware/         #
#    Thank you for using this script.                    #
##########################################################

# Script adapted from https://github.com/Yuri-NagaSaki/Bash/blob/main/hardware_info_script.sh

# Display hardware information (for Debian/Ubuntu/CentOS)
# This script requires root privilege

# Set display color
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


    echo 
    echo '***********************************************************'
    echo '*       Server Hardware Information v0.1                  *'
    echo '*       https://github.com/Har-Kuun/ServerHardware/       *'
    echo '*       Thank you for using this script.                  *'
    echo '***********************************************************'
    echo 

# Check root user
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script can only be run by root user.${NC}"
    echo "Please use sudo or switch to root user."
    exit 1
fi

# Temporary data path
TEMP_DIR=$(mktemp -d)
OUTPUT_FILE="$TEMP_DIR/hardware_info_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

# Clean up temp directory on exit
trap 'rm -rf -- "$TEMP_DIR"' EXIT

# Check Linux distro
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        DISTRO=$(cat /etc/redhat-release | cut -d ' ' -f 1 | tr '[:upper:]' '[:lower:]')
        if [[ $DISTRO == "centos" ]]; then
            VERSION=$(cat /etc/redhat-release | sed 's/.*release \([0-9]\).*/\1/')
        fi
    else
        DISTRO="unknown"
        VERSION="unknown"
    fi
    
    echo -e "${GREEN}Your Linux distro is: ${NC}$DISTRO $VERSION"
}

# Install prerequisites
install_tools() {
    echo -e "\n${BLUE}=== Installing prerequisites... ===${NC}"
    
    case $DISTRO in
        debian|ubuntu)
            apt-get update -qq
            apt-get install -y -qq dmidecode lshw hdparm smartmontools util-linux lsscsi pciutils usbutils ipmitool bc > /dev/null 2>&1
            ;;
        centos|rhel|fedora)
            if [ "$VERSION" -ge 8 ]; then
                dnf install -y -q dmidecode lshw hdparm smartmontools util-linux lsscsi pciutils usbutils ipmitool bc > /dev/null 2>&1
            else
                yum install -y -q dmidecode lshw hdparm smartmontools util-linux lsscsi pciutils usbutils ipmitool bc > /dev/null 2>&1
            fi
            ;;
        *)
            echo -e "${YELLOW}Unknown distro; attempting to install prerequisites...${NC}"
            if command -v apt-get > /dev/null; then
                apt-get update -qq
                apt-get install -y -qq dmidecode lshw hdparm smartmontools util-linux lsscsi pciutils usbutils ipmitool bc > /dev/null 2>&1
            elif command -v dnf > /dev/null; then
                dnf install -y -q dmidecode lshw hdparm smartmontools util-linux lsscsi pciutils usbutils ipmitool bc > /dev/null 2>&1
            elif command -v yum > /dev/null; then
                yum install -y -q dmidecode lshw hdparm smartmontools util-linux lsscsi pciutils usbutils ipmitool bc > /dev/null 2>&1
            else
                echo -e "${RED}Installation failed.  Some hardware information may not be correctly displayed.${NC}"
            fi
            ;;
    esac
    
    echo -e "${GREEN}Successfully installed prerequisites.${NC}"
}

# Obtain basic OS info
get_system_info() {
    {
        echo "=============================================="
        echo "            Basic System Info"
        echo "=============================================="
        echo "hostname: $(hostname -f)"
        echo "OS: $(cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2 | tr -d \")"
        echo "Kernal Version: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "System Time: $(date)"
        echo "Start Time: $(uptime -s)"
        echo "Uptime: $(uptime -p)"
        echo "System Load: $(cat /proc/loadavg)"
    } >> "$OUTPUT_FILE"
}

# Obtain CPU info
get_cpu_info() {
    {
        echo -e "\n=============================================="
        echo "                  CPU Info"
        echo "=============================================="
        
        # CPU Model and basic info
        echo "CPU Model:"
        lscpu | grep "Model name" | sed 's/^[^:]*: *//' | head -1
        
        
        SOCKETS=$(lscpu | grep "Socket(s)" | awk '{print $2}')
        CORES_PER_SOCKET=$(lscpu | grep "Core(s) per socket" | awk '{print $NF}')
        THREADS_PER_CORE=$(lscpu | grep "Thread(s) per core" | awk '{print $NF}')
        TOTAL_CORES=$((SOCKETS * CORES_PER_SOCKET))
        TOTAL_THREADS=$((TOTAL_CORES * THREADS_PER_CORE))
        
        echo -e "\nNumber of CPU: $SOCKETS"
        if [ "$SOCKETS" -gt 1 ]; then
            echo "CPU configuration: Dual or multi-socket CPU"
        else
            echo "CPU configuration: Single CPU"
        fi
        echo "Cores per CPU: $CORES_PER_SOCKET"
        echo "Threads per Core: $THREADS_PER_CORE"
        echo "Total physical cores: $TOTAL_CORES"
        echo "Total threads: $TOTAL_THREADS"
        
        # CPU Frequency info
        CPU_FREQ=$(lscpu | grep "CPU MHz\|CPU 最大 MHz\|CPU max MHz" | head -1 | awk '{print $NF}')
        if [ -n "$CPU_FREQ" ]; then
            
            if command -v bc > /dev/null; then
                CPU_FREQ_GHZ=$(echo "scale=2; $CPU_FREQ/1000" | bc)
                echo "CPU Frequency: ${CPU_FREQ_GHZ}GHz"
            else
                
                CPU_FREQ_GHZ=$(awk "BEGIN {printf \"%.2f\", $CPU_FREQ/1000}")
                echo "CPU Frequency: ${CPU_FREQ_GHZ}GHz"
            fi
        fi
        
        # CPU Cache info
        echo -e "\nCPU Cache info:"
        lscpu | grep "cache"
        
        # More info from dmidecode
        echo -e "\nCPU details (dmidecode):"
        dmidecode -t processor | grep -E "Socket Designation|Version|Serial Number|Core Count|Thread Count|Max Speed|Status"
    } >> "$OUTPUT_FILE"
}

# RAM info
get_memory_info() {
    {
        echo -e "\n=============================================="
        echo "                 RAM Info"
        echo "=============================================="
        
        # General RAM info
        echo "Total RAM: $(free -h | grep "Mem:" | awk '{print $2}')"
        echo "Used RAM: $(free -h | grep "Mem:" | awk '{print $3}')"
        echo "Free RAM: $(free -h | grep "Mem:" | awk '{print $7}')"
        
        # RAM stick info
        echo -e "\nRAM slots info:"
        MEM_SLOTS=$(dmidecode -t memory | grep -c "Memory Device")
        USED_SLOTS=$(dmidecode -t memory | grep -A16 "Memory Device" | grep -c "Size:.*[0-9]")
        
        echo "Total RAM slots: $MEM_SLOTS"
        echo "Used RAM slots: $USED_SLOTS"
        echo "Free RAM slots: $((MEM_SLOTS - USED_SLOTS))"
        
        echo -e "\nDetailed RAM info:"
        dmidecode -t memory | grep -A16 "Memory Device" | grep -v "^$" | while read -r line; do
            if [[ $line == *"Memory Device"* ]]; then
                echo -e "\n$line"
            elif [[ $line == *"Size:"* ]]; then
                if [[ $line != *"No Module Installed"* && $line != *"Size: 0"* ]]; then
                    echo "$line"
                    HAS_MEM=1
                else
                    HAS_MEM=0
                fi
            elif [[ $line == *"Type:"* || $line == *"Speed:"* || $line == *"Manufacturer:"* || $line == *"Serial Number:"* || $line == *"Part Number:"* || $line == *"Configured Memory Speed:"* || $line == *"Configured Clock Speed:"* || $line == *"Form Factor:"* ]] && [[ $HAS_MEM -eq 1 ]]; then
                echo "$line"
            fi
        done
        
        # All RAM info
        echo -e "\nConsolidated RAM info:"
        dmidecode -t memory | grep -A16 "Memory Device" | grep -v "^$" | awk 'BEGIN {
            slot=0
            printf "%-5s %-10s %-10s %-20s %-20s %-20s\n", "Slot", "Size", "Type", "Speed", "Make", "Model"
        }
        /Memory Device/ {slot++}
        /Size:/ {size=$2" "$3}
        /Type:/ {type=$2}
        /Speed:/ {speed=$2" "$3}
        /Manufacturer:/ {manu=$2}
        /Part Number:/ {
            part=$3
            if (size != "No" && size != "0 B" && size != "0") {
                printf "%-5s %-10s %-10s %-20s %-20s %-20s\n", slot, size, type, speed, manu, part
            }
        }'
    } >> "$OUTPUT_FILE"
}

# Obtain disk info
get_disk_info() {
    {
        echo -e "\n=============================================="
        echo "                 Disk Info"
        echo "=============================================="
        
        # List all disks
        echo "All drives:"
        lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,TYPE | grep -v "loop"
        
        echo -e "\nDetailed disk info:"
        
        # List physical drives
        DISKS=$(lsblk -d -n -o NAME | grep -v "loop")
        
        for DISK in $DISKS; do
            echo -e "\n# Drive /dev/$DISK info:"
            
            # Basic drive info
            SIZE=$(lsblk -d -n -o SIZE /dev/$DISK)
            MODEL=$(lsblk -d -n -o MODEL /dev/$DISK)
            SERIAL=$(lsblk -d -n -o SERIAL /dev/$DISK 2>/dev/null || echo "Cannot be accessed")
            TRANSPORT=$(lsblk -d -n -o TRAN /dev/$DISK 2>/dev/null || echo "Cannot be accessed")
            
            echo "Disk name: /dev/$DISK"
            echo "Disk size: $SIZE"
            echo "Disk model: $MODEL"
            echo "Disk SN: $SERIAL"
            echo "Port Type: $TRANSPORT"
            
            # Try to access SMART info for Power On Hours
            if command -v smartctl > /dev/null; then
                POWER_ON_HOURS_LINE=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Power.On.Hours")
                if [ -n "$POWER_ON_HOURS_LINE" ]; then
                    POWER_ON_HOURS=$(echo "$POWER_ON_HOURS_LINE" | awk '{print $NF}')
                    echo "Power On Hours: $POWER_ON_HOURS"
                fi
            fi
            
            # Check port info
            if [[ $TRANSPORT == "sata" ]]; then
                # Find form factor
                FORM_FACTOR=$(smartctl -i /dev/$DISK | grep "Form Factor" | cut -d: -f2 | tr -d ' ')
                
                if [[ -z "$FORM_FACTOR" ]]; then
                    # Check rotation rate
                    RPM=$(smartctl -i /dev/$DISK | grep "Rotation Rate" | cut -d: -f2 | tr -d ' ')
                    
                    if [[ "$RPM" == *"Solid"* || "$RPM" == *"SSD"* ]]; then
                        echo "Disk type: SSD"
                        # Get Data Units Read/Written for SSDs
                        if command -v smartctl > /dev/null; then
                           DATA_READ=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Total_LBAs_Read" | awk '{print $NF}')
                           DATA_WRITTEN=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Total_LBAs_Written" | awk '{print $NF}')
                           if [ -z "$DATA_READ" ]; then
                               DATA_READ=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Data Units Read" | cut -d: -f2 | tr -d ' ,')
                               DATA_WRITTEN=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Data Units Written" | cut -d: -f2 | tr -d ' ,')
                           fi
                           [ -n "$DATA_READ" ] && echo "Data Units Read: $DATA_READ"
                           [ -n "$DATA_WRITTEN" ] && echo "Data Units Written: $DATA_WRITTEN"
                        fi
                        echo "Form factor: Unknown (SSD)"
                    elif [[ -n "$RPM" ]]; then
                        echo "Disk type: HDD ($RPM)"
                        
                        # Form factor
                        if [[ "$MODEL" == *"2.5"* ]]; then
                            echo "Form factor: 2.5 inch"
                        elif [[ "$SIZE" > "4T" && "$RPM" != *"10K"* && "$RPM" != *"15K"* ]]; then
                            echo "Form factor: (likely) 3.5 inch"
                        elif [[ "$RPM" == *"7200"* && "$SIZE" > "1T" ]]; then
                            echo "Form factor: (likely) 3.5 inch"
                        elif [[ "$RPM" == *"5400"* ]]; then
                            echo "Form factor: (likely) 2.5 inch"
                        else
                            echo "Form factor: cannot be determined"
                        fi
                    else
                        echo "Form factor: cannot be determined"
                    fi
                else
                    if [[ "$FORM_FACTOR" == *"2.5"* ]]; then
                        echo "Form factor: 2.5 inch"
                    elif [[ "$FORM_FACTOR" == *"3.5"* ]]; then
                        echo "Form factor: 3.5 inch"
                    else
                        echo "Form factor: $FORM_FACTOR"
                    fi
                fi
            elif [[ $TRANSPORT == "nvme" ]]; then
                echo "Disk type: NVMe SSD"
                
                # Get Data Units Read/Written for NVMe SSDs
                if command -v smartctl > /dev/null; then
                    DATA_READ=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Data Units Read" | cut -d: -f2 | tr -d ' ,' | sed 's/\[.*//')
                    DATA_WRITTEN=$(smartctl -a /dev/$DISK 2>/dev/null | grep -i "Data Units Written" | cut -d: -f2 | tr -d ' ,' | sed 's/\[.*//')
                    [ -n "$DATA_READ" ] && echo "Data Units Read: $DATA_READ"
                    [ -n "$DATA_WRITTEN" ] && echo "Data Units Written: $DATA_WRITTEN"
                fi
                
                # Get NVMe info
                if command -v nvme > /dev/null; then
                    echo -e "\nNVMe details:"
                    nvme list-ns /dev/$DISK -H 2>/dev/null || echo "Cannot access NVMe namespace info"
                    nvme smart-log /dev/$DISK 2>/dev/null || echo "Cannot access NVMe SMART info"
                    
                    # Check U.2 or M.2
                    NVME_INFO=$(nvme id-ctrl /dev/$DISK 2>/dev/null || echo "")
                    if [[ "$NVME_INFO" == *"Form Factor: 2.5\""* ]]; then
                        echo "Socket type: U.2 (2.5 inch)"
                    elif [[ "$NVME_INFO" == *"Form Factor: HHHL"* ]]; then
                        echo "Socket type: HHHL"
                    elif [[ "$NVME_INFO" == *"Form Factor: M.2"* ]]; then
                        echo "Socket type: M.2"
                    else
                        echo "Socket type: Unknown NVMe type"
                    fi
                else
                    echo "Socket type: NVMe (Install nvme-cli for more info)"
                fi
            else
                echo "Form factor: cannot be determined"
            fi
            
            # Try to access SMART info
            if command -v smartctl > /dev/null; then
                echo -e "\nDisk health:"
                SMART_STATUS=$(smartctl -H /dev/$DISK 2>/dev/null)
                if [[ $? -eq 0 ]]; then
                    echo "$SMART_STATUS" | grep -E "SMART overall-health|SMART Health Status"
                else
                    echo "Cannot access SMART info"
                fi
            fi
            
            # Try to obtain disk temperature
            if command -v smartctl > /dev/null; then
                TEMP=$(smartctl -A /dev/$DISK 2>/dev/null | grep -i "temperature" | head -1)
                if [[ -n "$TEMP" ]]; then
                    echo "Temperature: $TEMP"
                fi
            fi
        done
    } >> "$OUTPUT_FILE"
}

# Try to obtain RAID info
get_raid_info() {
    {
        echo -e "\n=============================================="
        echo "              RAID Controller Info"
        echo "=============================================="
        
        # Check if RAID controller exists
        if lspci | grep -i raid > /dev/null; then
            echo "Found RAID controller:"
            lspci | grep -i raid
            
            # Detect common RAID tools
            if command -v megacli > /dev/null; then
                echo -e "\nLSI MegaRAID Controller info:"
                megacli -AdpAllInfo -aALL | grep -E "Product Name|Serial No|Firmware|RAID Level Supported"
                echo -e "\nLSI MegaRAID Virtual Disk info:"
                megacli -LDInfo -Lall -aAll | grep -E "RAID Level|Size|State"
            elif command -v storcli > /dev/null; then
                echo -e "\nLSI StorCLI Controller info:"
                storcli /call show | grep -E "Product Name|Serial Number|FW Package Build"
                echo -e "\nLSI StorCLI Virtual Disk info:"
                storcli /call/vall show | grep -E "RAID|Size|State"
            elif command -v arcconf > /dev/null; then
                echo -e "\nAdaptec RAID Controller info:"
                arcconf getconfig 1 | grep -E "Controller Model|Controller Serial Number|Firmware"
                echo -e "\nAdaptec RAID Logical Device info:"
                arcconf getconfig 1 ld | grep -E "Logical device number|RAID level|Size|Status"
            elif command -v hpssacli > /dev/null || command -v ssacli > /dev/null; then
                HPCMD="hpssacli"
                if ! command -v $HPCMD > /dev/null; then
                    HPCMD="ssacli"
                fi
                echo -e "\nHP Smart Array Controller info:"
                $HPCMD ctrl all show detail | grep -E "Model|Serial Number|Firmware Version"
                echo -e "\nHP Smart Array Logical Drive info:"
                $HPCMD ctrl all show config detail | grep -E "logicaldrive|RAID|Size|Status"
            else
                echo "RAID controller detected but no management tools found; cannot access details."
            fi
        else
            echo "No RAID controller detected"
            
            # Detect soft RAID
            if [ -e /proc/mdstat ]; then
                echo -e "\n Soft RAID info (/proc/mdstat):"
                cat /proc/mdstat
            fi
        fi
    } >> "$OUTPUT_FILE"
}

# Obtain NIC info
get_network_info() {
    {
        echo -e "\n=============================================="
        echo "                 NIC Info"
        echo "=============================================="
        
        # List all network interfaces
        echo "Network interfaces:"
        ip -br link show | grep -v "lo"
        
        # Detailed NIC info
        echo -e "\nDetailed NIC info:"
        
        # List physical NIC (excluding virtual interfaces and loopback)
        NICS=$(ip -o link show | grep -v "lo\|virbr\|docker\|veth\|bond\|bridge\|tun\|tap" | awk -F': ' '{print $2}')
        
        for NIC in $NICS; do
            echo -e "\n# Physical NIC $NIC info:"
            
            # get MAC
            MAC=$(ip link show "$NIC" | grep "link/ether" | awk '{print $2}')
            echo "MAC addr: $MAC"
            
            # Get IP
            IP_INFO=$(ip addr show "$NIC" | grep "inet " | awk '{print $2}')
            if [ -n "$IP_INFO" ]; then
                echo "IP Addr: $IP_INFO"
            else
                echo "IP Addr: not configured"
            fi
            
            # Get NIC speed and status
            if [ -d "/sys/class/net/$NIC" ]; then
                OPERSTATE=$(cat /sys/class/net/"$NIC"/operstate)
                echo "Status: $OPERSTATE"
                
                if [ -f "/sys/class/net/$NIC/speed" ]; then
                    SPEED=$(cat /sys/class/net/"$NIC"/speed 2>/dev/null || echo "unknown")
                    if [ "$SPEED" != "unknown" ]; then
                        echo "Connection speed: ${SPEED}Mb/s"
                    else
                        echo "Connection speed: unknown (interface possibly not connected)"
                    fi
                fi
            fi
            
            # Get NIC model and details from lshw
            echo -e "\nNIC hardware info:"
            lshw -class network -short | grep "$NIC"
            
            # More detailed NIC info
            NIC_PCI_INFO=$(lshw -class network -businfo 2>/dev/null | grep "$NIC" | awk '{print $1}' | cut -d@ -f2)
            if [ -n "$NIC_PCI_INFO" ]; then
                echo -e "\nNIC PCI info:"
                lspci -v | grep -A10 "$NIC_PCI_INFO" | grep -E "Subsystem|Kernel driver in use"
            fi
            
            # NIC firmware info
            if command -v ethtool > /dev/null; then
                DRIVER_INFO=$(ethtool -i "$NIC" 2>/dev/null)
                if [ $? -eq 0 ]; then
                    echo -e "\nNIC driver info:"
                    echo "$DRIVER_INFO" | grep -E "driver|version|firmware-version"
                fi
            fi
        done
    } >> "$OUTPUT_FILE"
}

# GPU info
get_gpu_info() {
    {
        echo -e "\n=============================================="
        echo "                 GPU Info"
        echo "=============================================="
        
        # Check if GPU exists
        if lspci | grep -E "VGA|3D|Display" > /dev/null; then
            echo "Graphic card detected:"
            lspci | grep -E "VGA|3D|Display"
            
            # Obtain Nvidia GPU info
            if command -v nvidia-smi > /dev/null; then
                echo -e "\nNVIDIA GPU info:"
                nvidia-smi -L
                echo -e "\nNVIDIA GPU status:"
                nvidia-smi
            fi
            
            # Obtain AMD GPU info
            if [ -d "/sys/class/drm" ]; then
                echo -e "\nAMD/Intel GPU info:"
                for card in /sys/class/drm/card[0-9]*; do
                    if [ -f "$card/device/vendor" ]; then
                        VENDOR=$(cat "$card/device/vendor" 2>/dev/null)
                        DEVICE=$(cat "$card/device/device" 2>/dev/null)
                        
                        # regex vendor ID
                        if [[ "$VENDOR" =~ ^0x[0-9a-fA-F]+$ ]]; then
                            NAME=$(lspci -d "$VENDOR:$DEVICE" 2>/dev/null | sed 's/.*: //g' | head -1)
                            if [ -n "$NAME" ]; then
                                echo "GPU: $NAME"
                                
                                if [ -f "$card/device/uevent" ]; then
                                    grep -E "DRIVER|PCI_ID" "$card/device/uevent"
                                fi
                            fi
                        else
                            echo "GPU: cannot access details (wrong Vendor ID format)"
                        fi
                    fi
                done
            fi
        else
            echo "No independentent GPU found"
        fi
    } >> "$OUTPUT_FILE"
}

# get power info
get_power_supply_info() {
    {
        echo -e "\n=============================================="
        echo "                  PSU Info"
        echo "=============================================="
        
        # obtain power info from IMPI
        if command -v ipmitool > /dev/null; then
            echo "PSU info from IMPI:"
            IPMI_POWER_INFO=$(ipmitool sdr type "Power Supply" 2>/dev/null)
            if [ -n "$IPMI_POWER_INFO" ]; then
                echo "$IPMI_POWER_INFO"
                
                # More detailed power info
                echo -e "\nPower FRU info:"
                ipmitool fru print 2>/dev/null | grep -E "Product Name|Product Manufacturer|Product Serial|Product Version" || echo "Cannot access FRU info"
            else
                echo "Cannot obtain PSU info from IPMI"
            fi
        fi
        
        # Check dmidecode
        echo -e "\nPSU dmidecode info:"
        DMI_POWER_INFO=$(dmidecode -t 39 2>/dev/null)
        if [ -n "$DMI_POWER_INFO" ]; then
            echo "$DMI_POWER_INFO"
        else
            echo "No PSU info from dmidecode"
        fi
        
        # Check ACPI PSU info
        if [ -d "/sys/class/power_supply" ]; then
            echo -e "\nACPI PSU info:"
            
            for psu in /sys/class/power_supply/*; do
                if [ -d "$psu" ]; then
                    PSU_NAME=$(basename "$psu")
                    echo "PSU: $PSU_NAME"
                    
                    if [ -f "$psu/manufacturer" ]; then
                        echo "Make: $(cat "$psu/manufacturer" 2>/dev/null)"
                    fi
                    
                    if [ -f "$psu/model_name" ]; then
                        echo "Model: $(cat "$psu/model_name" 2>/dev/null)"
                    fi
                    
                    if [ -f "$psu/serial_number" ]; then
                        echo "SN: $(cat "$psu/serial_number" 2>/dev/null)"
                    fi
                    
                    if [ -f "$psu/type" ]; then
                        echo "Type: $(cat "$psu/type" 2>/dev/null)"
                    fi
                    
                    if [ -f "$psu/online" ]; then
                        echo "Online Status: $(cat "$psu/online" 2>/dev/null)"
                    fi
                    
                    if [ -f "$psu/status" ]; then
                        echo "Status: $(cat "$psu/status" 2>/dev/null)"
                    fi
                    
                    echo ""
                fi
            done
        fi
    } >> "$OUTPUT_FILE"
}

# MOBO
get_motherboard_info() {
    {
        echo -e "\n=============================================="
        echo "                 MOBO Info"
        echo "=============================================="
        
        echo "Motherboard (dmidecode):"
        dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version|Serial Number|Asset Tag"
        
        echo -e "\nBIOS info:"
        dmidecode -t bios | grep -E "Vendor|Version|Release Date|BIOS Revision"
        
        echo -e "\nSystem info:"
        dmidecode -t system | grep -E "Manufacturer|Product Name|Version|Serial Number|UUID|SKU Number|Family"
    } >> "$OUTPUT_FILE"
}

# Other hardware info
get_other_hardware_info() {
    {
        echo -e "\n=============================================="
        echo "             Other Hardware Info"
        echo "=============================================="
        
        # PCI device list
        echo "PCI device list:"
        lspci | grep -v "USB\|Audio\|VGA\|Ethernet\|Network\|RAID"
        
        # USB device list
        echo -e "\nUSB device list:"
        lsusb
        
        # Sensor info
        if command -v sensors > /dev/null; then
            echo -e "\nSystem temperature sensor info:"
            sensors
        fi
    } >> "$OUTPUT_FILE"
}

# Fan info
get_fan_info() {
    {
        echo -e "\n=============================================="
        echo "                 Fan Info"
        echo "=============================================="
        
        # Fan info from IMPI
        if command -v ipmitool > /dev/null; then
            echo "Fan status (IPMI):"
            ipmitool sdr type "Fan" 2>/dev/null || echo "Cannot get fan info from IPMI"
        fi
        
        # Fan info from sensors
        if command -v sensors > /dev/null; then
            echo -e "\nFan speed (from sensors):"
            sensors | grep -i "fan" || echo "Cannot get fan info from sensors"
        fi
        
        # Fan info from hwmon
        echo -e "\nSystem fan info (from hwmon):"
        found_fans=0
        
        for path in /sys/class/hwmon/hwmon*/; do
            if [ -d "$path" ]; then
                # Check if there's fan info in hwmon
                if ls "$path"/fan* 2>/dev/null >/dev/null; then
                    found_fans=1
                    
                    # Obtain device name
                    if [ -f "$path/name" ]; then
                        echo "Device: $(cat "$path/name")"
                    else
                        echo "Device: $(basename "$path")"
                    fi
                    
                    # Get all fan input
                    for fan_input in "$path"/fan*_input; do
                        if [ -f "$fan_input" ]; then
                            fan_num=$(echo "$fan_input" | sed 's/.*fan\([0-9]\+\)_input/\1/')
                            fan_speed=$(cat "$fan_input" 2>/dev/null || echo "N/A")
                            
                            echo "Fan ${fan_num} speed: ${fan_speed} RPM"
                            
                            # Check fan label
                            if [ -f "$path/fan${fan_num}_label" ]; then
                                echo "Fan ${fan_num} label: $(cat "$path/fan${fan_num}_label")"
                            fi
                        fi
                    done
                    echo ""
                fi
            fi
        done
        
        if [ $found_fans -eq 0 ]; then
            echo "No fan info from hwmon"
        fi
    } >> "$OUTPUT_FILE"
}

# Summary report
generate_summary() {
    # Add summary header
    echo "=============================================="
    echo "             Hardware Info Summary"
    echo "=============================================="
    echo ""

    # --- System Info ---
    SYS_VENDOR=$(dmidecode -s system-manufacturer)
    SYS_PRODUCT=$(dmidecode -s system-product-name)
    echo -e "System Info"
    echo -e "--------------------------------------------------"
    printf "%-15s: %s\n" "System" "$SYS_VENDOR $SYS_PRODUCT"

    # --- BIOS Info ---
    BIOS_VENDOR=$(dmidecode -s bios-vendor)
    BIOS_VERSION=$(dmidecode -s bios-version)
    BIOS_DATE=$(dmidecode -s bios-release-date)
    printf "%-15s: %s %s (%s)\n" "BIOS" "$BIOS_VENDOR" "$BIOS_VERSION" "$BIOS_DATE"

    # --- Motherboard Info ---
    MB_VENDOR=$(dmidecode -s baseboard-manufacturer)
    MB_MODEL=$(dmidecode -s baseboard-product-name)
    MB_VERSION=$(dmidecode -s baseboard-version)
    printf "%-15s: %s %s %s\n" "Motherboard" "$MB_VENDOR" "$MB_MODEL" "$MB_VERSION"
    echo -e "--------------------------------------------------\n"

    # --- CPU Info ---
    CPU_MODEL=$(lscpu | grep "Model name:" | sed 's/Model name:[ \t]*//')
    SOCKETS=$(lscpu | grep "Socket(s):" | awk '{print $2}')
    CORES_PER_SOCKET=$(lscpu | grep "Core(s) per socket:" | awk '{print $NF}')
    TOTAL_PHYSICAL_CORES=$((SOCKETS * CORES_PER_SOCKET))
    TOTAL_THREADS=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    
    CPU_FREQ_MHZ=$(lscpu | grep "CPU MHz:" | awk '{print $3}')
    if [[ "$CPU_FREQ_MHZ" =~ ^[0-9.]+$ ]]; then
        CPU_FREQ_GHZ=$(printf "%.2f" $(echo "$CPU_FREQ_MHZ / 1000" | bc -l))
    else
        CPU_FREQ_GHZ="N/A"
    fi

    echo -e "CPU Info"
    echo -e "--------------------------------------------------"
    printf "%-15s: %s\n" "Model" "$CPU_MODEL"
    printf "%-15s: %s Socket(s), %s Cores, %s Threads\n" "Topology" "$SOCKETS" "$TOTAL_PHYSICAL_CORES" "$TOTAL_THREADS"
    echo -e "--------------------------------------------------\n"

    # --- RAM Info ---
    TOTAL_MEM=$(free -h | grep "Mem:" | awk '{print $2}')
    echo -e "Memory Info"
    echo -e "--------------------------------------------------"
    printf "%-15s: %s Total\n" "RAM" "$TOTAL_MEM"
    echo -e "\nInstalled RAM Sticks:"
    echo "------------------------------------------------------------------------------------------------------"
    printf "| %-7s | %-9s | %-13s | %-19s | %-14s | %-20s |\n" "Size" "Type" "Speed" "Configured Speed" "Manufacturer" "Part Number"
    echo "------------------------------------------------------------------------------------------------------"
    dmidecode -t memory | grep -A20 "Memory Device" | awk -F': ' '
    function print_row() {
        if (size && size !~ /No Module/) {
            gsub(/^[ \t]+|[ \t]+$/, "", size);
            gsub(/^[ \t]+|[ \t]+$/, "", type);
            gsub(/^[ \t]+|[ \t]+$/, "", speed);
            gsub(/^[ \t]+|[ \t]+$/, "", clock);
            gsub(/^[ \t]+|[ \t]+$/, "", manu);
            gsub(/^[ \t]+|[ \t]+$/, "", part);
            printf "| %-7s | %-9s | %-13s | %-19s | %-14s | %-20s |\n", size, type, speed, clock, manu, part;
        }
    }
    /Memory Device/ { if (size) print_row(); size=type=speed=clock=manu=part=""; }
    /^\s+Size:/ { size = $2; }
    /^\s+Type:/ { type = $2; }
    /^\s+Speed:/ { speed = $2; }
    /^\s+Configured Memory Speed:/ { clock = $2; }
    /^\s+Configured Clock Speed:/ { if (!clock) clock = $2; }
    /^\s+Manufacturer:/ { manu = $2; }
    /^\s+Part Number:/ { part = $2; }
    END { print_row(); }' | grep -v "No Module"
    echo -e "------------------------------------------------------------------------------------------------------\n"

    # --- Disk Info ---
    echo -e "Disk Info"
    echo "------------------------------------------------------------------------------------------------------------------------"
    printf "| %-8s | %-8s | %-30s | %-15s | %-15s | %-15s |\n" "Name" "Size" "Model" "Power On Hours" "Data Read (GB)" "Data Written (GB)"
    echo "------------------------------------------------------------------------------------------------------------------------"
    DISKS=$(lsblk -d -n -o NAME,TRAN | grep -v "loop" | awk '{print $1}')
    for DISK in $DISKS; do
        SIZE=$(lsblk -d -n -o SIZE /dev/$DISK)
        MODEL=$(lsblk -d -n -o MODEL /dev/$DISK)
        TRANSPORT=$(lsblk -d -n -o TRAN /dev/$DISK)
        
        POWER_ON_HOURS="N/A"
        DATA_READ_GB="N/A"
        DATA_WRITTEN_GB="N/A"

        if command -v smartctl > /dev/null && command -v bc > /dev/null; then
            SMART_OUTPUT=$(smartctl -a /dev/$DISK 2>/dev/null)
            POWER_ON_HOURS=$(echo "$SMART_OUTPUT" | grep -i "Power.On.Hours" | awk '{print $NF}')
            [ -z "$POWER_ON_HOURS" ] && POWER_ON_HOURS="N/A"
            
            if [[ $TRANSPORT == "nvme" ]]; then
                DATA_READ=$(echo "$SMART_OUTPUT" | grep "Data Units Read" | awk -F: '{print $2}' | tr -d ' ,' | sed 's/\[.*//')
                DATA_WRITTEN=$(echo "$SMART_OUTPUT" | grep "Data Units Written" | awk -F: '{print $2}' | tr -d ' ,' | sed 's/\[.*//')
                if [[ "$DATA_READ" =~ ^[0-9]+$ ]]; then
                    DATA_READ_GB=$(echo "scale=2; $DATA_READ * 1000 * 512 / (1024*1024*1024)" | bc)
                fi
                if [[ "$DATA_WRITTEN" =~ ^[0-9]+$ ]]; then
                    DATA_WRITTEN_GB=$(echo "scale=2; $DATA_WRITTEN * 1000 * 512 / (1024*1024*1024)" | bc)
                fi
            elif [[ $TRANSPORT == "sata" ]]; then
                DATA_READ=$(echo "$SMART_OUTPUT" | grep "Total_LBAs_Read" | awk '{print $NF}')
                DATA_WRITTEN=$(echo "$SMART_OUTPUT" | grep "Total_LBAs_Written" | awk '{print $NF}')
                 if [[ "$DATA_READ" =~ ^[0-9]+$ ]]; then
                    DATA_READ_GB=$(echo "scale=2; $DATA_READ * 512 / (1024*1024*1024)" | bc)
                fi
                if [[ "$DATA_WRITTEN" =~ ^[0-9]+$ ]]; then
                    DATA_WRITTEN_GB=$(echo "scale=2; $DATA_WRITTEN * 512 / (1024*1024*1024)" | bc)
                fi
            fi
        fi
        
        printf "| %-8s | %-8s | %-30.30s | %-15s | %-15s | %-15s |\n" "$DISK" "$SIZE" "$MODEL" "$POWER_ON_HOURS" "$DATA_READ_GB" "$DATA_WRITTEN_GB"
    done
    echo -e "------------------------------------------------------------------------------------------------------------------------\n"
    
    # --- RAID Info ---
    echo -e "RAID Info"
    echo "--------------------------------------------------"
    RAID_INFO_FOUND=0
    if lspci | grep -iq raid; then
        if command -v megacli &> /dev/null; then
            RAID_INFO=$(megacli -LDInfo -Lall -aALL 2>/dev/null | grep -E 'RAID Level' | sed 's/.*: //;s/Primary-//' | tr -d '\n')
            RAID_STATE=$(megacli -LDInfo -Lall -aALL 2>/dev/null | grep -E 'State' | sed 's/.*: //' | tr -d '\n')
        elif command -v storcli &> /dev/null; then
             RAID_INFO=$(storcli /c0/vall show 2>/dev/null | grep "RAID" | awk '{print $3}')
             RAID_STATE=$(storcli /c0/vall show 2>/dev/null | grep "State" | awk '{print $3}')
        fi
        if [ -n "$RAID_INFO" ]; then
            printf "%-15s: RAID %s (%s)\n" "Hardware RAID" "$RAID_INFO" "$RAID_STATE"
            RAID_INFO_FOUND=1
        fi
    fi

    if [ -e /proc/mdstat ]; then
        if grep -q "^md" /proc/mdstat; then
            RAID_LEVEL=$(grep "^md" /proc/mdstat | head -n 1 | awk '{print $4}')
            RAID_STATUS=$(grep "\[.*\]" /proc/mdstat | head -n 1 | sed 's/.*\[\([U_]*\)\].*/\1/' | sed 's/U/Up/g; s/_/Down/g')
            printf "%-15s: %s (%s)\n" "Software RAID" "$RAID_LEVEL" "$RAID_STATUS"
            RAID_INFO_FOUND=1
        fi
    fi

    if [ $RAID_INFO_FOUND -eq 0 ]; then
        echo "No RAID configuration detected."
    fi
    echo -e "--------------------------------------------------\n"

    # --- Network Info ---
    echo -e "Network Info"
    echo "--------------------------------------------------"
    ip -o link show | grep -Ev "lo:|virbr|docker|veth|bond|bridge|tun|tap|br-|cni|flannel|calico|overlay" | awk -F': ' '{print $2}' | while read nic; do
        if [ -e "/sys/class/net/$nic/device" ]; then
            SPEED_INFO=""
            if [ -f "/sys/class/net/$nic/speed" ]; then
                SPEED=$(cat "/sys/class/net/$nic/speed" 2>/dev/null)
                if [ -n "$SPEED" ]; then
                    SPEED_INFO=" (${SPEED}Mb/s)"
                fi
            fi
            
            NIC_MODEL=$(lshw -class network -short 2>/dev/null | grep "$nic" | awk '{$1=$2=""; print}' | sed 's/^[ \t]*//' | head -n 1)
            if [ -z "$NIC_MODEL" ]; then
                NIC_MODEL="Generic"
            fi
            printf "%-15s: %s%s\n" "$nic" "$NIC_MODEL" "$SPEED_INFO"
        fi
    done
    echo -e "--------------------------------------------------"
}


# main function
main() {
    echo -e "${BLUE}=== Collecting hardware info... ===${NC}"
    
    detect_distro
    install_tools
    
    echo -e "\n${BLUE}=== Collecting system info... ===${NC}"
    get_system_info
    
    echo -e "\n${BLUE}=== Collecting CPU info... ===${NC}"
    get_cpu_info
    
    echo -e "\n${BLUE}=== Collecting RAM info... ===${NC}"
    get_memory_info
    
    echo -e "\n${BLUE}=== Collecting disk info... ===${NC}"
    get_disk_info
    
    echo -e "\n${BLUE}=== Collecting RAID info... ===${NC}"
    get_raid_info
    
    echo -e "\n${BLUE}=== Collecting NIC info... ===${NC}"
    get_network_info
    
    echo -e "\n${BLUE}=== Collecting GPU info... ===${NC}"
    get_gpu_info
    
    echo -e "\n${BLUE}=== Collecting MOBO info... ===${NC}"
    get_motherboard_info
    
    echo -e "\n${BLUE}=== Collecting PSU info... ===${NC}"
    get_power_supply_info
    
    echo -e "\n${BLUE}=== Collecting other hardware info... ===${NC}"
    get_other_hardware_info
    
    echo -e "\n${BLUE}=== Collecting fan info... ===${NC}"
    get_fan_info
    
    echo -e "\n${BLUE}=== Generating summary... ===${NC}"
    
    # Generate summary and store in a variable
    SUMMARY_CONTENT=$(generate_summary)
    
    # Append summary to the main report file
    echo "$SUMMARY_CONTENT" >> "$OUTPUT_FILE"
    
    # Output summary to SSH
    echo -e "\n${GREEN}Hardware Info Summary:${NC}"
    echo -e "${YELLOW}$SUMMARY_CONTENT${NC}"
    
    # Copy to current directory
    FINAL_REPORT="hardware_info_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"
    cp "$OUTPUT_FILE" ./"$FINAL_REPORT"
    
    echo -e "\n${GREEN}Hardware info collection finished!${NC}"
    echo -e "Check detailed reports at: ${YELLOW}$(pwd)/${FINAL_REPORT}${NC}"
}

# main
main
