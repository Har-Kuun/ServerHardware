# Server Hardware
A one-click script that generates all detailed hardware information of a Linux dedicated server.
This script was adapted from [Yuri-NagaSaki/Bash](https://github.com/Yuri-NagaSaki/Bash/blob/main/hardware_info_script.sh)

## Usage
This script works for Ubuntu/Debian, and may also work for CentOS-based OS.
Root privilege is required for this script to run.
Please run one of the following commands in SSH.

```
wget -qO- https://raw.githubusercontent.com/Har-Kuun/ServerHardware/refs/heads/main/serverhw.sh | bash
```
or
```
curl -Lso https://raw.githubusercontent.com/Har-Kuun/ServerHardware/refs/heads/main/serverhw.sh | bash
```

## Features
Automatically obtain hardware information of your Linux dedicated server, including:
* CPU
* RAM sticks
* GPU
* Disk Drives
* RAID controller
* NIC
* Motherboard
* PSU
* Fans
* Other hardware info

A brief summary report will be generated and output to the terminal, whereas a more detailed report will be saved to your local folder.

An example summary report is like below.

```
==============================================
             Hardware Info Summary
==============================================

System Info
--------------------------------------------------
System         : Supermicro Super Server
BIOS           : American Megatrends Inc. 3.4.V1 (03/09/2023)
Motherboard    : Supermicro X10SRi-F 1.01B
--------------------------------------------------

CPU Info
--------------------------------------------------
Model          : Intel(R) Xeon(R) CPU E5-1650 v4 @ 3.60GHz
BIOS Intel(R) Xeon(R) CPU E5-1650 v4 @ 3.60GHz  CPU @ 3.6GHz
Topology       : 1 Socket(s), 6 Cores, 12 Threads
--------------------------------------------------

Memory Info
--------------------------------------------------
RAM            : 125Gi Total

Installed RAM Sticks:
------------------------------------------------------------------------------------------------------
| Size    | Type      | Speed         | Configured Speed    | Manufacturer   | Part Number          |
------------------------------------------------------------------------------------------------------
| 32 GB   | DDR4      | 2667 MT/s     | 2400 MT/s           | Micron         | 36ASF4G72PZ-2G6E1    |
| 32 GB   | DDR4      | 2667 MT/s     | 2400 MT/s           | Micron         | 36ASF4G72PZ-2G6E1    |
| 32 GB   | DDR4      | 2667 MT/s     | 2400 MT/s           | Micron         | 36ASF4G72PZ-2G6E1    |
| 32 GB   | DDR4      | 2667 MT/s     | 2400 MT/s           | Micron         | 36ASF4G72PZ-2G6E1    |
------------------------------------------------------------------------------------------------------

Disk Info
------------------------------------------------------------------------------------------------------------------------
| Name     | Size     | Model                          | Power On Hours  | Data Read (GB)  | Data Written (GB) |
------------------------------------------------------------------------------------------------------------------------
| nvme0n1  |  1.7T    | SAMSUNG MZQL21T9HCJR-00A07     | 405             | 155.28          | 779.18          |
| nvme1n1  |  1.7T    | SAMSUNG MZQL21T9HCJR-00A07     | 405             | 152.30          | 779.33          |
------------------------------------------------------------------------------------------------------------------------

RAID Info
--------------------------------------------------
Software RAID  : raid1 (Personalities : [raid1] [raid0] [raid6] [raid5] [raid4] [raid10] )
--------------------------------------------------

Network Info
--------------------------------------------------
eno1           : network I350 Gigabit Network Connection (1000Mb/s)
eno2           : network I350 Gigabit Network Connection
--------------------------------------------------
```

Enjoy!
