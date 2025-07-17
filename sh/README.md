# utilkit.sh

A comprehensive Shell function library that provides functions for system administration, monitoring, and network configuration.

---

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Configuration](#configuration)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## Introduction

utilkit.sh is a comprehensive Shell function library designed for system administrators and developers. It provides a rich set of functions, including package management, system monitoring, network configuration, etc., which greatly simplifies daily system maintenance tasks.

| Available Functions           |                               |                               |                           |
|-------------------------------|-------------------------------|-------------------------------|---------------------------|
| [ADD](#add)                   | [CHECK_DEPS](#check_deps)     | [CHECK_OS](#check_os)         | [CHECK_ROOT](#check_root) |
| [CHECK_VIRT](#check_virt)     | [CLEAN](#clean)               | [CONVERT_SIZE](#convert_size) | [COPYRIGHT](#copyright)   |
| [CPU_CACHE](#cpu_cache)       | [CPU_FREQ](#cpu_freq)         | [CPU_MODEL](#cpu_model)       | [CPU_USAGE](#cpu_usage)   |
| [DEL](#del)                   | [DISK_USAGE](#disk_usage)     | [DNS_ADDR](#dns_addr)         | [FIND](#find)             |
| [FONT](#font)                 | [FORMAT](#format)             | [GET](#get)                   | [INPUT](#input)           |
| [INTERFACE](#interface)       | [IP_ADDR](#ip_addr)           | [LAST_UPDATE](#last_update)   | [LINE](#line)             |
| [LOAD_AVERAGE](#load_average) | [LOCATION](#location)         | [MAC_ADDR](#mac_addr)         | [MEM_USAGE](#mem_usage)   |
| [NET_PROVIDER](#net_provider) | [PKG_COUNT](#pkg_count)       | [PROGRESS](#progress)         | [PUBLIC_IP](#public_ip)   |
| [RUN](#run)                   | [SHELL_VER](#shell_ver)       | [SWAP_USAGE](#swap_usage)     | [SYS_CLEAN](#sys_clean)   |
| [SYS_INFO](#sys_info)         | [SYS_OPTIMIZE](#sys_optimize) | [SYS_REBOOT](#sys_reboot)     | [SYS_UPDATE](#sys_update) |
| [SYS_UPGRADE](#sys_upgrade)   | [TASK](#task)                 | [TIMEZONE](#timezone)         |                           |

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
[ -f ~/utilkit.sh ] && source ~/utilkit.sh || bash <(curl -sL utilkit.ogtt.tk) && source ~/utilkit.sh
```

## Usage

### Basic Command Format

```bash
source utilkit.sh
FUNCTION_NAME [ARGUMENTS]
```

### Function Descriptions

#### ADD

- Function: Add a file or install a package.
- Usage: `ADD [-f/-d] <item>`
- Parameters:
  - `-f`: Create a file
  - `-d`: Create a directory
  - Default is to install a package if no options are provided.
- Examples:

```bash
ADD nginx              # Install the nginx package
ADD -f /path/file.txt  # Create a file
ADD -d /path/dir       # Create a directory
```

#### CHECK_DEPS

- Function: Check if dependencies are installed.
- Usage:

```bash
deps=("curl" "wget" "git")  # Set the dependencies to check
CHECK_DEPS                  # Run the check
```

- Note: The `deps` array variable must be set before running the check.

#### CHECK_OS

- Function: Check and display operating system information.
- Usage: `CHECK_OS [option]`
- Parameters:
  - `-v`: Display version number only
  - `-n`: Display distribution name only
  - No option: Display full operating system information
- Examples:

```bash
CHECK_OS        # Output: Ubuntu 22.04 LTS
CHECK_OS -v     # Output: 22.04
CHECK_OS -n     # Output: Ubuntu
```

#### CHECK_ROOT

- Function: Check for root privileges.
- Usage: `CHECK_ROOT`
- Note: Exits with an error if not run as the root user.

#### CHECK_VIRT

- Function: Check the virtualization environment.
- Usage: `CHECK_VIRT`
- Output: Displays the virtualization type (e.g., KVM, Docker, physical machine).

#### CLEAN

- Function: Clear the terminal screen.
- Usage: `CLEAN`
- Note: Equivalent to the `clear` command, but also changes to the user's home directory.

#### CONVERT_SIZE

- Function: Convert file size units.
- Usage: `CONVERT_SIZE <size> [unit]`
- Parameters:
  - `size`: A numerical value
  - `unit`:
    - Binary: B/KiB/MiB/GiB/TiB/PiB
    - Decimal: B/KB/MB/GB/TB/PB
- Examples:

```bash
CONVERT_SIZE 1024        # Defaults to binary (1.000 KiB)
CONVERT_SIZE 1000 KB     # Uses decimal (1000 KB = 1.000 MB)
```

#### COPYRIGHT

- Function: Display copyright information.
- Usage: `COPYRIGHT`
- Output: Displays the script version and copyright notice.

#### CPU_CACHE

- Function: Display CPU cache size.
- Usage: `CPU_CACHE`
- Output: Displays the cache size in KB.

#### CPU_FREQ

- Function: Display CPU frequency.
- Usage: `CPU_FREQ`
- Output: Displays the frequency in GHz.

#### CPU_MODEL

- Function: Display CPU model.
- Usage: `CPU_MODEL`
- Output: Displays the full processor model name.

#### CPU_USAGE

- Function: Display CPU usage.
- Usage: `CPU_USAGE`
- Output: Displays the current CPU usage as a percentage.

#### DEL

- Function: Delete a file or remove a package.
- Usage: `DEL [-f/-d] <item>`
- Parameters:
  - `-f`: Delete a file
  - `-d`: Delete a directory
  - Default is to remove a package if no options are provided.
- Examples:

```bash
DEL nginx              # Remove the nginx package
DEL -f /path/file.txt  # Delete a file
DEL -d /path/dir       # Delete a directory
```

#### DISK_USAGE

- Function: Display disk usage.
- Usage: `DISK_USAGE [-u/-t/-p]`
- Parameters:
  - `-u`: Display used space only
  - `-t`: Display total space only
  - `-p`: Display usage percentage only
- Output: Displays used/total space and usage percentage.

#### DNS_ADDR

- Function: Display DNS server addresses.
- Usage: `DNS_ADDR [-4/-6]`
- Parameters:
  - `-4`: Display IPv4 DNS only
  - `-6`: Display IPv6 DNS only
  - No option: Display all

#### FIND

- Function: Search for packages.
- Usage: `FIND <keyword>`
- Note: Searches the package repository for packages matching the keyword.

#### FONT

- Function: Set text style and color.
- Usage: `FONT [style] [color] [background] <text>`
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
FONT B RED "Error"                    # Bold red
FONT B RED BG.WHITE "Warning"           # Bold red on a white background
FONT RGB 255,0,0 "Red"              # RGB foreground
FONT B RGB 255,0,0 BG.RGB 0,0,255 "Red text on blue background"  # RGB foreground and background
```

#### FORMAT

- Function: Format text.
- Usage: `FORMAT <option> <text>`
- Parameters:
  - `-AA`: Convert to all uppercase
  - `-aa`: Convert to all lowercase
  - `-Aa`: Capitalize the first letter
- Examples:

```bash
FORMAT -AA "hello"    # Output: HELLO
FORMAT -aa "WORLD"    # Output: world
FORMAT -Aa "hELLo"    # Output: Hello
```

#### GET

- Function: Download a file.
- Usage: `GET <URL> [-r new_name] [-x] [target_directory]`
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
GET https://example.com/file.txt                      # Download to the current directory
GET https://example.com/file.txt downloads            # Download to a specific directory
GET https://example.com/file.txt -r new.txt downloads # Download and rename
GET https://example.com/archive.tar.gz -x             # Download and automatically extract
```

#### INPUT

- Function: Read user input.
- Usage: `INPUT <prompt> <variable_name>`
- Example: `INPUT "Enter your name: " name`

#### INTERFACE

- Function: Display network interface information.
- Usage: `INTERFACE [option]`
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
INTERFACE              # Display the name of the physical network interface
INTERFACE -i           # Display detailed information
INTERFACE RX_BYTES     # Display received bytes
INTERFACE TX_PACKETS   # Display transmitted packets
```

- Note:
  - Automatically filters the following virtual interfaces:
    - lo, sit, stf, gif, dummy
    - vmnet, vir, gre, ipip
    - ppp, bond, tun, tap
    - ip6gre, ip6tnl, teql
    - ocserv, vpn, warp, wgcf
    - wg, docker

#### IP_ADDR

- Function: Display IP address.
- Usage: `IP_ADDR [-4/-6]`
- Parameters:
  - `-4`: Display IPv4 address
  - `-6`: Display IPv6 address
  - No option: Display all

#### LAST_UPDATE

- Function: Display the last system update time.
- Usage: `LAST_UPDATE`
- Output: Displays the date and time of the last update.

#### LINE

- Function: Draw a separator line.
- Usage: `LINE [character] [length]`
- Parameters:
  - `character`: The character to use for the line (defaults to -)
  - `length`: The length of the line (defaults to 80)

#### LOAD_AVERAGE

- Function: Display system load.
- Usage: `LOAD_AVERAGE`
- Output: Displays the 1, 5, and 15-minute average load.

#### LOCATION

- Function: Display geographic location.
- Usage: `LOCATION`
- Output: Displays the abbreviation for the current location.

#### MAC_ADDR

- Function: Display MAC address.
- Usage: `MAC_ADDR`
- Output: Displays the MAC address of the primary network interface.

#### MEM_USAGE

- Function: Display memory usage.
- Usage: `MEM_USAGE [-u/-t/-p]`
- Parameters:
  - `-u`: Display used space only
  - `-t`: Display total space only
  - `-p`: Display usage percentage only
- Output: Displays used/total and usage percentage.

#### NET_PROVIDER

- Function: Display network service provider.
- Usage: `NET_PROVIDER`
- Output: Displays the name of the current network's ISP.

#### PKG_COUNT

- Function: Count the number of installed packages.
- Usage: `PKG_COUNT`
- Output: Displays the total number of installed packages on the system.

#### PROGRESS

- Function: Display a progress bar.
- Usage:

```bash
cmds=(
 "command1"
 "command2"
 "command3"
)
PROGRESS
```

- Note:
  - The `cmds` array variable must be set first.
  - Each command will be executed sequentially.
  - The progress bar will show the execution progress percentage.

#### PUBLIC_IP

- Function: Display the public IP address.
- Usage: `PUBLIC_IP`
- Output: Displays the public IP address of the current network.

#### RUN

- Function: Execute a command or script.
- Usage: `RUN <command/script> [-r] [-b branch] [--] [arguments]`
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
RUN "ls -la"                           # Execute a local command
RUN local_script.sh                    # Execute a local script
RUN local_script.sh arg1 arg2          # Execute a local script with arguments
RUN username/repo/script.sh            # Execute a GitHub script (main branch)
RUN username/repo/script.sh -b dev     # Execute a GitHub script (specific branch)
RUN username/repo/script.sh -- arg1    # Execute a GitHub script with arguments
```

#### SHELL_VER

- Function: Display Shell version.
- Usage: `SHELL_VER`
- Output: Displays the currently used Shell and its version.

#### SWAP_USAGE

- Function: Display swap partition usage.
- Usage: `SWAP_USAGE [-u/-t/-p]`
- Parameters:
  - `-u`: Display used space only
  - `-t`: Display total space only
  - `-p`: Display usage percentage only
- Output: Displays used/total and usage percentage.

#### SYS_CLEAN

- Function: System cleanup.
- Usage: `SYS_CLEAN`
- Note: Cleans system cache, temporary files, etc.

#### SYS_INFO

- Function: Display system information.
- Usage: `SYS_INFO`
- Output: Displays a complete system information report.

#### SYS_OPTIMIZE

- Function: System optimization.
- Usage: `SYS_OPTIMIZE`
- Note: Optimizes system settings to improve performance.

#### SYS_REBOOT

- Function: System reboot.
- Usage: `SYS_REBOOT`
- Note: Safely reboots the system.

#### SYS_UPDATE

- Function: System update.
- Usage: `SYS_UPDATE`
- Note: Updates the system and installed packages.

#### SYS_UPGRADE

- Function: Upgrade the system to the next major version.
- Usage: `SYS_UPGRADE`
- Note:
  - Automatically backs up important system files.
  - Updates package sources.
  - Performs a full system upgrade.
  - May require a reboot after completion.

#### TASK

- Function: A helper function to display task execution status and handle command output.
- Note:
  - Displays a task description and execution status.
  - Supports single-line and multi-line command execution.
  - Automatically aborts on error and displays detailed information.
- Syntax:

```bash
TASK "message" "command" [ignore_error]
```

- Parameters:
  - `message`: The task description to display.
  - `command`: The Shell command to execute.
  - `ignore_error`: Optional parameter; if set to `true`, it will ignore command execution failures (defaults to `false`).
- Return values:
  - `0`: Command executed successfully.
  - `1`: Command execution failed.
- Examples:

```bash
# Command examples
TASK "Updating package lists" "apt-get update"
TASK "Creating directory" "ADD -d /path/to/dir"
```

- Output format:

```bash
* Task description... Done     # On success
* Task description... Failed   # On failure
  [Error details]           # Displays specific error on failure
```

#### TIMEZONE

- Function: Display timezone information.
- Usage: `TIMEZONE [-i/-e]`
- Parameters:
  - `-i`: Display internal timezone setting.
  - `-e`: Display externally detected timezone.

## Examples

### System Information Query

```bash
source utilkit.sh
SYS_INFO
```

### System Optimization

```bash
source utilkit.sh
SYS_OPTIMIZE
```

### Text Style Settings

```bash
source utilkit.sh
# Use basic colors
FONT B RED "Error message"
FONT B GREEN BG.WHITE "Success message"

# Use RGB colors
FONT RGB 255,0,0 "Custom red"
FONT B RGB 255,0,0 BG.RGB 0,0,255 "Red text on blue background"
```

## Configuration

### Environment Variables

```bash
# Color definitions
CLR1="\033[0;31m"    # Red
CLR2="\033[0;32m"    # Green
CLR3="\033[0;33m"    # Yellow
CLR4="\033[0;34m"    # Blue
CLR5="\033[0;35m"    # Purple
CLR6="\033[0;36m"    # Cyan
CLR7="\033[0;37m"    # White
CLR8="\033[0;96m"    # Light Cyan
CLR9="\033[0;97m"    # Light White
CLR0="\033[0m"       # Reset
```

## FAQ

**Q: Why do some commands require root privileges?**
A: System-level operations (such as updating, installing packages, etc.) require root privileges to ensure security.

**Q: How to handle network connection issues?**
A:

- Confirm the network connection status.
- Check proxy settings.

**Q: Automatic updates are not working?**
A: Please check:

- crontab settings
- If the system time is correct
- Network connection status

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## License

This repository is licensed under the [MIT License](https://opensource.org/licenses/mit-license.php).

---

© 2025 [OG-Open-Source](https://github.com/OG-Open-Source). All rights reserved.
