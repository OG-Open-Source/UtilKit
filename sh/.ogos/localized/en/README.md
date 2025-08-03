# UtilKit.sh

A comprehensive Shell function library that provides functions for system administration, monitoring, and network configuration.

---

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Contributors](#contributors)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

UtilKit.sh is a comprehensive Shell function library designed for system administrators and developers. It provides a rich set of functions, including package management, system monitoring, network configuration, etc., which greatly simplifies daily system maintenance tasks.

| Available Functions     |                       |                         |                       |
| ----------------------- | --------------------- | ----------------------- | --------------------- |
| [Add](#add)             | [Ask](#ask)           | [ChkDeps](#chkdeps)     | [ChkOs](#chkos)       |
| [ChkRoot](#chkroot)     | [ChkVirt](#chkvirt)   | [Clear](#clear)         | [ConvSz](#convsz)     |
| [Copyright](#copyright) | [CpuCache](#cpucache) | [CpuFreq](#cpufreq)     | [CpuModel](#cpumodel) |
| [CpuUsage](#cpuusage)   | [Del](#del)           | [DiskUsage](#diskusage) | [DnsAddr](#dnsaddr)   |
| [Err](#err)             | [Find](#find)         | [Font](#font)           | [Format](#format)     |
| [Get](#get)             | [Iface](#iface)       | [IpAddr](#ipaddr)       | [LastUpd](#lastupd)   |
| [Linet](#linet)         | [LoadAvg](#loadavg)   | [Loc](#loc)             | [MacAddr](#macaddr)   |
| [MemUsage](#memusage)   | [NetProv](#netprov)   | [PkgCnt](#pkgcnt)       | [Press](#press)       |
| [Prog](#prog)           | [PubIp](#pubip)       | [Run](#run)             | [ShellVer](#shellver) |
| [SwapUsage](#swapusage) | [SysClean](#sysclean) | [SysInfo](#sysinfo)     | [SysOptz](#sysoptz)   |
| [SysRboot](#sysrboot)   | [SysUpd](#sysupd)     | [SysUpg](#sysupg)       | [Task](#task)         |
| [TimeZn](#timezn)       | [Txt](#txt)           |                         |                       |

## Features

- Complete set of system management functions
- Real-time system performance monitoring
- Network configuration and diagnostic tools
- Automated system optimization
- Complete error handling mechanism
- Support for multiple Linux distributions
- Rich text processing functions
- Automatic update mechanism

## Installation

### Prerequisites

- Unix-like operating system (Linux, macOS)
- Bash Shell 4.0 or higher
- Basic system tools (tr, bc, curl)
- root privileges (required for some functions)

```bash
# Use the installation script
[ -f ~/utilkit.sh ] && source ~/utilkit.sh || bash <(curl -sL utilkit.ogtt.tk/sh) && source ~/utilkit.sh
```

## Usage

### Basic Command Format

```bash
source utilkit.sh
FUNCTION_NAME [ARGUMENTS]
```

### Function Descriptions

#### Add

- Function: Add a file, install a package, or install a local .deb file.
- Usage: `Add [-f/-d] <item>` or `Add <path/to/package.deb>`
- Parameters:
  - `-f` or `--file`: Create a file
  - `-d` or `--directory`: Create a directory
  - Default is to install a package if no options are provided.
- Examples:

```bash
Add nginx # Install the nginx package
Add -f /path/file.txt # Create a file
Add -d /path/dir # Create a directory
Add package.deb # Install a local .deb package
```

#### ChkDeps

- Function: Check if dependencies are installed.
- Usage: `ChkDeps [-i | -a]`
- Parameters:
  - `-i` or `--interactive`: Prompt to install missing dependencies.
  - `-a` or `--automatic`: Automatically install missing dependencies.
  - No option: Display the status of dependencies only.
- Note: The `deps` array variable must be set before running the check.
- Examples:

```bash
deps=("curl" "wget" "git") # Set the dependencies to check
ChkDeps # Display dependency status
ChkDeps -i # Interactively prompt to install missing dependencies
ChkDeps -a # Automatically install missing dependencies
```

#### ChkOs

- Function: Check and display operating system information.
- Usage: `ChkOs [option]`
- Parameters:
  - `-v` or `--version`: Display version number only
  - `-n` or `--name`: Display distribution name only
  - No option: Display full operating system information
- Examples:

```bash
ChkOs # Output: Ubuntu 22.04 LTS
ChkOs -v # Output: 22.04
ChkOs -n # Output: Ubuntu
```

#### ChkRoot

- Function: Check for root privileges.
- Usage: `ChkRoot`
- Note: Exits with an error if not run as the root user.

#### ChkVirt

- Function: Check the virtualization environment.
- Usage: `ChkVirt`
- Output: Displays the virtualization type (e.g., KVM, Docker, physical machine).

#### Clear

- Function: Clear the terminal screen and change to a specified directory.
- Usage: `Clear [directory]`
- Note: Equivalent to the `clear` command, but also changes to the specified directory (defaults to the user's home directory).

#### ConvSz

- Function: Convert file size units.
- Usage: `ConvSz <size> [unit]`
- Parameters:
  - `size`: A numerical value
  - `unit`:
    - Binary: B/KiB/MiB/GiB/TiB/PiB
    - Decimal: B/KB/MB/GB/TB/PB
- Examples:

```bash
ConvSz 1024 # Defaults to binary (1.000 KiB)
ConvSz 1000 KB # Uses decimal (1000 KB = 1.000 MB)
```

#### Copyright

- Function: Display copyright information.
- Usage: `Copyright`
- Output: Displays the script version and copyright notice.

#### CpuCache

- Function: Display CPU cache size.
- Usage: `CpuCache`
- Output: Displays the cache size in KB.

#### CpuFreq

- Function: Display CPU frequency.
- Usage: `CpuFreq`
- Output: Displays the frequency in GHz.

#### CpuModel

- Function: Display CPU model.
- Usage: `CpuModel`
- Output: Displays the full processor model name.

#### CpuUsage

- Function: Display CPU usage.
- Usage: `CpuUsage`
- Output: Displays the current CPU usage as a percentage.

#### Del

- Function: Delete a file or remove a package.
- Usage: `Del [-f/-d] <item>`
- Parameters:
  - `-f`: Delete a file
  - `-d`: Delete a directory
  - Default is to remove a package if no options are provided.
- Examples:

```bash
Del nginx # Remove the nginx package
Del -f /path/file.txt # Delete a file
Del -d /path/dir # Delete a directory
```

#### DiskUsage

- Function: Display disk usage.
- Usage: `DiskUsage [-u/-t/-p]`
- Parameters:
  - `-u`: Display used space only
  - `-t`: Display total space only
  - `-p`: Display usage percentage only
- Output: Displays used/total space and usage percentage.

#### DnsAddr

- Function: Display DNS server addresses.
- Usage: `DnsAddr [-4/-6]`
- Parameters:
  - `-4`: Display IPv4 DNS only
  - `-6`: Display IPv6 DNS only
  - No option: Display all

#### Find

- Function: Search for packages.
- Usage: `Find <keyword>`
- Note: Searches the package repository for packages matching the keyword.

#### Font

- Function: Set text style and color.
- Usage: `Font [style] [color] [background] <text>`
- Parameters:
  - `style`: B (bold), U (underline)
  - `color`:
    - Basic: BLACK, RED, GREEN, YELLOW, BLUE, PURPLE, CYAN, WHITE
    - Light: L.BLACK, L.RED, L.GREEN, L.YELLOW, L.BLUE, L.PURPLE, L.CYAN, L.WHITE
  - `background`:
    - Basic: BG.BLACK, BG.RED, BG.GREEN, BG.YELLOW, BG.BLUE, BG.PURPLE, BG.CYAN, BG.WHITE
    - Light: L.BG.BLACK, L.BG.RED, L.BG.GREEN, L.BG.YELLOW, L.BG.BLUE, L.BG.PURPLE, L.BG.CYAN, L.BG.WHITE
  - `RGB`: Can use RGB values for foreground and background.
- Examples:

```bash
Font B RED "Error" # Bold red
Font B RED BG.WHITE "Warning" # Bold red on a white background
Font RGB 255,0,0 "Red" # RGB foreground
Font B RGB 255,0,0 BG.RGB 0,0,255 "Red text on blue background" # RGB foreground and background
```

#### Format

- Function: Format text.
- Usage: `Format <option> <text>`
- Parameters:
  - `-AA`: Convert to all uppercase
  - `-aa`: Convert to all lowercase
  - `-Aa`: Capitalize the first letter
- Examples:

```bash
Format -AA "hello" # Output: HELLO
Format -aa "WORLD" # Output: world
Format -Aa "hELLo" # Output: Hello
```

#### Get

- Function: Download a file.
- Usage: `Get <URL> [-r new_name] [-x] [target_directory]`
- Parameters:
  - `-r`: Specify a new filename (optional)
  - `-x`: Automatically extract after downloading (optional)
  - `target_directory`: Specify the download location (optional, defaults to the current directory)
- Supported formats:
  - tar.gz, tgz
  - tar
  - tar.bz2, tbz2
  - tar.xz, txz
  - zip
  - 7z
  - rar
  - zst
- Examples:

```bash
Get https://example.com/file.txt # Download to the current directory
Get https://example.com/file.txt downloads # Download to a specific directory
Get https://example.com/file.txt -r new.txt downloads # Download and rename
Get https://example.com/archive.tar.gz -x # Download and automatically extract
```

#### Ask

- Function: Read user input.
- Usage: `Ask <prompt> <variable_name>`
- Example: `Ask "Enter your name: " name`

#### Iface

- Function: Display network interface information.
- Usage: `Iface [option]`
- Parameters:
  - `-i`: Display detailed information
  - Traffic statistics:
    - `RX_BYTES`: Received bytes
    - `RX_PACKETS`: Received packets
    - `RX_DROP`: Dropped received packets
    - `TX_BYTES`: Transmitted bytes
    - `TX_PACKETS`: Transmitted packets
    - `TX_DROP`: Dropped transmitted packets
  - No option: Display the name of the physical network interface (automatically filters virtual interfaces)
- Examples:

```bash
Iface # Display the name of the physical network interface
Iface -i # Display detailed information
Iface RX_BYTES # Display received bytes
Iface TX_PACKETS # Display transmitted packets
```

- Note:
  - Automatically filters the following virtual interfaces:
    - lo, sit, stf, gif, dummy
    - vmnet, vir, gre, ipip
    - ppp, bond, tun, tap
    - ip6gre, ip6tnl, teql
    - ocserv, vpn, warp, wgcf
    - wg, docker

#### IpAddr

- Function: Display IP address.
- Usage: `IpAddr [-4/-6]`
- Parameters:
  - `-4`: Display IPv4 address
  - `-6`: Display IPv6 address
  - No option: Display all

#### LastUpd

- Function: Display the last system update time.
- Usage: `LastUpd`
- Output: Displays the date and time of the last update.

#### Linet

- Function: Draw a separator line.
- Usage: `Linet [character] [length]`
- Parameters:
  - `character`: The character to use for the line (defaults to -)
  - `length`: The length of the line (defaults to 80)

#### LoadAvg

- Function: Display system load.
- Usage: `LoadAvg`
- Output: Displays the 1, 5, and 15-minute average load.

#### Loc

- Function: Display geographic location.
- Usage: `Loc`
- Output: Displays the abbreviation for the current location.

#### MacAddr

- Function: Display MAC address.
- Usage: `MacAddr`
- Output: Displays the MAC address of the primary network interface.

#### MemUsage

- Function: Display memory usage.
- Usage: `MemUsage [-u/-t/-p]`
- Parameters:
  - `-u`: Display used space only
  - `-t`: Display total space only
  - `-p`: Display usage percentage only
- Output: Displays used/total and usage percentage.

#### NetProv

- Function: Display network service provider.
- Usage: `NetProv`
- Output: Displays the name of the current network's ISP.

#### PkgCnt

- Function: Count the number of installed packages.
- Usage: `PkgCnt`
- Output: Displays the total number of installed packages on the system.

#### Prog

- Function: Display a progress bar.
- Usage:

```bash
cmds=(
 "command1"
 "command2"
 "command3"
)
Prog
```

- Note:
  - The `cmds` array variable must be set first.
  - Each command will be executed sequentially.
  - The progress bar will show the execution progress percentage.

#### PubIp

- Function: Display the public IP address.
- Usage: `PubIp`
- Output: Displays the public IP address of the current network.

#### Run

- Function: Execute a command or script.
- Usage: `Run <command/script> [-r] [-b branch] [--] [arguments]`
- Parameters:
  - `-r`: Additionally download a repository from GitHub and execute a script.
  - `-b`: Specify the GitHub repository branch (optional, defaults to main).
  - `--`: Separator for passing arguments to the script.
- Supports:
  - Local command execution
  - Local script execution
  - GitHub repository script execution
- Examples:

```bash
Run "ls -la" # Execute a local command
Run local_script.sh # Execute a local script
Run local_script.sh arg1 arg2 # Execute a local script with arguments
Run username/repo/script.sh # Execute a GitHub script (main branch)
Run username/repo/script.sh -b dev # Execute a GitHub script (specific branch)
Run username/repo/script.sh -- arg1 # Execute a GitHub script with arguments
```

#### ShellVer

- Function: Display Shell version.
- Usage: `ShellVer`
- Output: Displays the currently used Shell and its version.

#### SwapUsage

- Function: Display swap partition usage.
- Usage: `SwapUsage [-u/-t/-p]`
- Parameters:
  - `-u`: Display used space only
  - `-t`: Display total space only
  - `-p`: Display usage percentage only
- Output: Displays used/total and usage percentage.

#### SysClean

- Function: System cleanup.
- Usage: `SysClean`
- Note: Cleans system cache, temporary files, etc.

#### SysInfo

- Function: Display system information.
- Usage: `SysInfo`
- Output: Displays a complete system information report.

#### SysOptz

- Function: System optimization.
- Usage: `SysOptz`
- Note: Optimizes system settings to improve performance.

#### SysRboot

- Function: System reboot.
- Usage: `SysRboot`
- Note: Safely reboots the system.

#### SysUpd

- Function: System update.
- Usage: `SysUpd`
- Note: Updates the system and installed packages.

#### SysUpg

- Function: Upgrade the system to the next major version.
- Usage: `SysUpg`
- Note:
  - Automatically backs up important system files.
  - Updates package sources.
  - Performs a full system upgrade.
  - May require a reboot after completion.

#### Task

- Function: A helper function to display task execution status and handle command output.
- Note:
  - Displays a task description and execution status.
  - Supports single-line and multi-line command execution.
  - Automatically aborts on error and displays detailed information.
- Syntax:

```bash
Task "Description" "Command"
```

- Example:

```bash
Task "Updating package list" "sudo apt-get update"
```

#### TimeZn

- Function: Display the system timezone.
- Usage: `TimeZn`
- Output: Displays the current system timezone.

## Contributors

<a href="https://github.com/OG-Open-Source/UtilKit/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=OG-Open-Source/UtilKit" />
</a>

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## License

This repository is licensed under the [MIT License](https://opensource.org/license/MIT).

---

© 2025 [OG-Open-Source](https://github.com/OG-Open-Source). All rights reserved.

#### Err

- Function: Display a formatted error message.
- Usage: `Err <message>`
- Note: The error message will be printed in red and logged to `/var/log/utilkit.sh.log` if the directory is writable.

#### Press

- Function: Display a prompt and wait for the user to press any key to continue.
- Usage: `Press [prompt_message]`
- Example:

```bash
Press "Press any key to reboot..."
```

#### Txt

- Function: A wrapper for `echo -e` to print formatted text.
- Usage: `Txt <text>`
- Example:

```bash
Txt "This is a ${CLR2}green${CLR0} message."
```
