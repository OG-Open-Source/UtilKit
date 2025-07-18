#!/bin/bash

AUTHORS="OG-Open-Source"
SCRIPTS="UtilKit.sh"
VERSION="7.044.002.284"

CLR1="\033[0;31m"
CLR2="\033[0;32m"
CLR3="\033[0;33m"
CLR4="\033[0;34m"
CLR5="\033[0;35m"
CLR6="\033[0;36m"
CLR7="\033[0;37m"
CLR8="\033[0;96m"
CLR9="\033[0;97m"
CLR0="\033[0m"

Txt() { echo -e "$1" "$2"; }
Err() {
	[ -z "$1" ] && {
		Txt "${CLR1}Unknown error${CLR0}"
		return 1
	}
	Txt "${CLR1}$1${CLR0}"
	if [ -w "/var/log" ]; then
		log_file-Err="/var/log/utilkit.sh.log"
		timestamp-Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry-Err="${timestamp-Err} | ${SCRIPTS} - ${VERSION} - $(Txt "$1" | tr -d '\n')"
		Txt "${log_entry-Err}" >>"${log_file-Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "No items specified for insertion. Please provide at least one item to add"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "No file or directory path specified after -f or -d"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "No file or directory path specified after -f or -d"
		return 2
	}
	mod_Add="package"
	err_code_Add=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f)
			mod_Add="file"
			shift
			continue
			;;
		-d)
			mod_Add="directory"
			shift
			continue
			;;
		*.deb)
			ChkRoot
			debFile=$(basename "$1")
			Txt "${CLR3}INSERT DEB PACKAGE [$debFile]${CLR0}\n"
			Get "$1"
			if [ -f "$debFile" ]; then
				dpkg -i "$debFile" || {
					Err "Failed to install $debFile. Check package compatibility and dependencies\n"
					Del -f "$debFile"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "Failed to fix dependencies"
					Del -f "$debFile"
					err_code_Add=1
					shift
					continue
				}
				Txt "* DEB package $debFile installed successfully"
				Del -f "$debFile"
				Txt "${CLR2}FINISHED${CLR0}\n"
			else
				Err "DEB package $debFile not found or download failed\n"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "${CLR3}INSERT FILE [$1]${CLR0}"
				[ -d "$1" ] && {
					Err "Directory $1 already exists. Cannot create file with the same name\n"
					err_code_Add=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "File $1 already exists\n"
					err_code_Add=1
					shift
					continue
				}
				touch "$1" || {
					Err "Failed to create file $1. Check permissions and disk space\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* File $1 created successfully"
				Txt "${CLR2}FINISHED${CLR0}\n"
				;;
			"directory")
				Txt "${CLR3}INSERT DIRECTORY [$1]${CLR0}"
				[ -f "$1" ] && {
					Err "File $1 already exists. Cannot create directory with the same name\n"
					err_code_Add=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "Directory $1 already exists\n"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "Failed to create directory $1. Check permissions and path validity\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* Directory $1 created successfully"
				Txt "${CLR2}FINISHED${CLR0}\n"
				;;
			"package")
				Txt "${CLR3}INSERT PACKAGE [$1]${CLR0}"
				ChkRoot
				pkg_mgr_Add=$(command -v apk apt opkg pacman yum zypper dnf | head -n1)
				pkg_mgr_Add=${pkg_mgr_Add##*/}
				case $pkg_mgr_Add in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					IsInst() {
						case $pkg_mgr_Add_IsInst in
						apk) apk info -e "$1" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "$1" &>/dev/null ;;
						yum | dnf) $pkg_mgr_Add_IsInst list installed "$1" &>/dev/null ;;
						zypper) zypper se -i -x "$1" &>/dev/null ;;
						esac
					}
					InstallPkg() {
						case $pkg_mgr_Add_InstallPkg in
						apk) apk update && apk add "$1" ;;
						apt) apt install -y "$1" ;;
						opkg) opkg update && opkg install "$1" ;;
						pacman) pacman -Sy && pacman -S --noconfirm "$1" ;;
						yum | dnf) $pkg_mgr_Add_InstallPkg install -y "$1" ;;
						zypper) zypper refresh && zypper install -y "$1" ;;
						esac
					}
					if ! IsInst "$1"; then
						Txt "* Package $1 is not installed"
						if InstallPkg "$1"; then
							if IsInst "$1"; then
								Txt "* Package $1 installed successfully"
								Txt "${CLR2}FINISHED${CLR0}\n"
							else
								Err "Failed to install $1 using $pkg_manager\n"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "Failed to install $1 using $pkg_manager\n"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "* Package $1 is already installed"
						Txt "${CLR2}FINISHED${CLR0}\n"
					fi
					;;
				*)
					Err "Unsupported package manager\n"
					err_code_Add=1
					shift
					continue
					;;
				esac
				;;
			esac
			shift
			;;
		esac
	done
	return $err_code
}
function Ask() {
	read -e -p "$1" -r $2 || {
		Err "Failed to read user input"
		return 1
	}
}
function ChkDep() {
	mod_ChkDep="display"
	mis_dep_ChkDep=()
	while [[ $1 == -* ]]; do
		case "$1" in
		-i) mod_ChkDep="interactive" ;;
		-a) mod_ChkDep="auto" ;;
		*)
			Err "Invalid option: $1"
			return 1
			;;
		esac
		shift
	done
	for dep_ChkDep in "${deps[@]}"; do
		if command -v "${dep_ChkDep}" &>/dev/null; then
			stat_ChkDep="${CLR2}[Available]${CLR0}"
		else
			stat_ChkDep="${CLR1}[Not Found]${CLR0}"
			mis_dep_ChkDep+=("${dep_ChkDep}")
		fi
		Txt "$stat_ChkDep\t${dep_ChkDep}"
	done
	[[ ${#mis_dep_ChkDep[@]} -eq 0 ]] && return 0
	case "${mod_ChkDep}" in
	"interactive")
		Txt "\n${CLR3}Missing packages:${CLR0} ${mis_dep_ChkDep[*]}"
		Press "Do you want to install the missing packages? (y/N) " cont_ChkDep
		Txt "\n"
		[[ "${cont_ChkDep}" =~ ^[Yy] ]] && Add "${mis_dep_ChkDep[@]}"
		;;
	"auto")
		Txt
		Add "${mis_dep_ChkDep[@]}"
		;;
	esac
}
function ChkOs() {
	case "$1" in
	-v)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "$ID" = "debian" ] && cat /etc/debian_version || Txt "$VERSION_ID"
		elif [ -f /etc/debian_version ]; then
			cat /etc/debian_version
		elif [ -f /etc/fedora-release ]; then
			grep -oE '[0-9]+' /etc/fedora-release
		elif [ -f /etc/centos-release ]; then
			grep -oE '[0-9]+\.[0-9]+' /etc/centos-release
		elif [ -f /etc/alpine-release ]; then
			cat /etc/alpine-release
		else
			{
				Err "Unknown distribution version"
				return 1
			}
		fi
		;;
	-n)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			Txt "$ID" | sed 's/.*/\u&/'
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2 | awk '{print $1}'
		else
			{
				Err "Unknown distribution"
				return 1
			}
		fi
		;;
	*)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "$ID" = "debian" ] && Txt "$NAME $(cat /etc/debian_version)" || Txt "$PRETTY_NAME"
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
		else
			{
				Err "Unknown distribution"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "$EUID" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "Please run this script as root user"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "Unable to detect virtualization environment"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "Proxmox VE (KVM)" || Txt "KVM" ;;
		microsoft) Txt "Microsoft Hyper-V" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "LXC container"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "Virtual machine (Unknown type)"
			else
				Txt "Not detected (possibly bare metal)"
			fi
			;;
		*) Txt "${virt_typ_ChkVirt:-Not detected (possibly bare metal)}" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "VM" || Txt "None")
	else
		virt_typ_ChkVirt="Unknown"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-$HOME}"
	cd "${targ_dir_Clear}" || {
		Err "Failed to change directory"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "Cannot access CPU information. /proc/cpuinfo not available"
		return 1
	}
	cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cache_CpuCache}" = "N/A" ] && {
		Err "Unable to determine CPU cache size"
		return 1
	}
	Txt "${cache_CpuCache} KB"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "Cannot access CPU information. /proc/cpuinfo not available"
		return 1
	}
	freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${freq_CpuFreq}" = "N/A" ] && {
		Err "Unable to determine CPU frequency"
		return 1
	}
	Txt "${freq_CpuFreq} GHz"
}
function CpuModel() {
	if command -v lscpu &>/dev/null; then
		lscpu | awk -F': +' '/Model name/ {print $2; exit}'
	elif [ -f /proc/cpuinfo ]; then
		sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -n1
	elif command -v sysctl &>/dev/null && sysctl -n machdep.cpu.brand_string &>/dev/null; then
		sysctl -n machdep.cpu.brand_string
	else
		{
			Txt "${CLR1}Unknown${CLR0}"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idel_CpuUsage io_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "Failed to read CPU statistics from /proc/stat"
		return 1
	}
	ttl1_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idel_CpuUsage + io_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	idel1_CpuUsage=${idel_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idel_CpuUsage io_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "Failed to read CPU statistics from /proc/stat"
		return 1
	}
	ttl2_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idel_CpuUsage + io_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	idel2_CpuUsage=${idel_CpuUsage}
	ttl_diff_CpuUsage=$((ttl2_CpuUsage - ttl1_CpuUsage))
	idle_diff_CpuUsage=$((idel2_CpuUsage - idel1_CpuUsage))
	usage_CpuUsage=$((100 * (ttl_diff_CpuUsage - idle_diff_CpuUsage) / ttl_diff_CpuUsage))
	Txt "$usage_CpuUsage"
}
function ConvSz() {
	[ -z "$1" ] && {
		Err "No size value provided for conversion"
		return 2
	}
	input_size_ConvSz=$1
	input_unit_ConvSz=${2:-B}
	unit_lower_ConvSz=$(Format -aa "${input_unit_ConvSz}")
	if ! [[ ${input_size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		{
			Err "Invalid size value. Must be a numeric value"
			return 2
		}
	elif [[ ${input_size_ConvSz} =~ ^[-].*$ ]]; then
		{
			Err "Size value cannot be negative"
			return 2
		}
	elif [[ ${input_size_ConvSz} =~ ^[+].*$ ]]; then
		input_size_ConvSz=${input_size_ConvSz#+}
	fi
	LC_NUMERIC=C awk -v size="${input_size_ConvSz}" -v unit="${unit_lower_ConvSz}" '
	BEGIN {
		is_binary = 0
		if (unit ~ /ib$/ || unit == "b") {
			is_binary = 1
		}

		base = is_binary ? 1024 : 1000
		units_str = is_binary ? "B KiB MiB GiB TiB PiB" : "B KB MB GB TB PB"
		split(units_str, units, " ")

		bytes = size
		if (unit == "kb") { bytes = size * 1000 }
		else if (unit == "mb") { bytes = size * 1000000 }
		else if (unit == "gb") { bytes = size * 1000000000 }
		else if (unit == "tb") { bytes = size * 1000000000000 }
		else if (unit == "pb") { bytes = size * 1000000000000000 }
		else if (unit == "kib") { bytes = size * 1024 }
		else if (unit == "mib") { bytes = size * 1048576 }
		else if (unit == "gib") { bytes = size * 1073741824 }
		else if (unit == "tib") { bytes = size * 1099511627776 }
		else if (unit == "pib") { bytes = size * 1125899906842624 }

		power = 0
		value = bytes
		if (bytes > 0) {
			power = int(log(bytes) / log(base))
			if (power > 5) { power = 5 }
			value = bytes / (base ^ power)
		}

		if (power == 0) {
			printf "%.0f %s\n", bytes, units[1]
		} else {
			if (value >= 100) {
				printf "%.1f %s\n", value, units[power + 1]
			} else if (value >= 10) {
				printf "%.2f %s\n", value, units[power + 1]
			} else {
				printf "%.3f %s\n", value, units[power + 1]
			}
		}
	}'
}
function Copyright() {
	Txt "${SCRIPTS} ${VERSION}"
	Txt "Copyright (c) $(date +%Y) ${AUTHORS}."
}
function Del() {
	[ $# -eq 0 ] && {
		Err "No items specified for deletion. Please provide at least one item to delete"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "No file or directory path specified after -f or -d"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "No file or directory path specified after -f or -d"
		return 2
	}
	mod_Del="package"
	err_code_Del=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f)
			mod_Del="file"
			shift
			continue
			;;
		-d)
			mod_Del="directory"
			shift
			continue
			;;
		*)
			Txt "${CLR3}REMOVE $(Format -AA "${mod_Del}") [$1]${CLR0}"
			case "${mod_Del}" in
			"file")
				[ ! -f "$1" ] && {
					Err "File $1 does not exist\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* File $1 exists"
				rm -f "$1" || {
					Err "Failed to remove file $1\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* File $1 removed successfully"
				Txt "${CLR2}FINISHED${CLR0}\n"
				;;
			"directory")
				[ ! -d "$1" ] && {
					Err "Directory $1 does not exist\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* Directory $1 exists"
				rm -rf "$1" || {
					Err "Failed to remove directory $1\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* Directory $1 removed successfully"
				Txt "${CLR2}FINISHED${CLR0}\n"
				;;
			"package")
				ChkRoot
				pkg_mgr_Del=$(command -v apk apt opkg pacman yum zypper dnf | head -n1)
				pkg_mgr_Del=${pkg_mgr_Del##*/}
				case $pkg_mgr_Del in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					IsInst() {
						case $pkg_mgr_Del_IsInst in
						apk) apk info -e "$1" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "$1" &>/dev/null ;;
						yum | dnf) $pkg_mgr_Del_IsInst list installed "$1" &>/dev/null ;;
						zypper) zypper se -i -x "$1" &>/dev/null ;;
						esac
					}
					RmPkg() {
						case $pkg_mgr_Del_RmPkg in
						apk) apk del "$1" ;;
						apt) apt purge -y "$1" && apt autoremove -y ;;
						opkg) opkg remove "$1" ;;
						pacman) pacman -Rns --noconfirm "$1" ;;
						yum | dnf) $pkg_mgr_Del_RmPkg remove -y "$1" ;;
						zypper) zypper remove -y "$1" ;;
						esac
					}
					if ! IsInst "$1"; then
						Err "* Package $1 is not installed\n"
						err_code_Del=1
						shift
						continue
					fi
					Txt "* Package $1 is installed"
					if ! RmPkg "$1"; then
						Err "Failed to remove $1 using $pkg_manager\n"
						err_code_Del=1
						shift
						continue
					fi
					if IsInst "$1"; then
						Err "Failed to remove $1 using $pkg_manager\n"
						err_code_Del=1
						shift
						continue
					fi
					Txt "* Package $1 removed successfully"
					Txt "${CLR2}FINISHED${CLR0}\n"
					;;
				*) {
					Err "Unsupported package manager"
					return 1
				} ;;
				esac
				;;
			esac
			shift
			;;
		esac
	done
	return $err_code_Del
}
function DiskUsage() {
	used_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $3}') || {
		Err "Failed to get disk usage statistics"
		return 1
	}
	ttl_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "Failed to get total disk space"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) Txt "$used_DiskUsage" ;;
	-t) Txt "$ttl_DiskUsage" ;;
	-p) Txt "$pct_DiskUsage" ;;
	*) Txt "$(ConvSz "$used_DiskUsage") / $(ConvSz "$ttl_DiskUsage") ($pct_DiskUsage%)" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "DNS configuration file /etc/resolv.conf not found"
		return 1
	}
	ipv4_DnsAddr=()
	ipv6_DnsAddr=()
	while read -r server_DnsAddr; do
		if [[ $server_DnsAddr =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			ipv4_DnsAddr+=("$server_DnsAddr")
		elif [[ $server_DnsAddr =~ ^[0-9a-fA-F:]+$ ]]; then
			ipv6_DnsAddr+=("$server_DnsAddr")
		fi
	done < <(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')
	[[ ${#ipv4_DnsAddr[@]} -eq 0 && ${#ipv6_DnsAddr[@]} -eq 0 ]] && {
		Err "No DNS servers configured in /etc/resolv.conf"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_DnsAddr[@]} -eq 0 ] && {
			Err "No IPv4 DNS servers found"
			return 1
		}
		Txt "${ipv4_DnsAddr[*]}"
		;;
	-6)
		[ ${#ipv6_DnsAddr[@]} -eq 0 ] && {
			Err "No IPv6 DNS servers found"
			return 1
		}
		Txt "${ipv6_DnsAddr[*]}"
		;;
	*)
		[ ${#ipv4_DnsAddr[@]} -eq 0 -a ${#ipv6_DnsAddr[@]} -eq 0 ] && {
			Err "No DNS servers found"
			return 1
		}
		Txt "${ipv4_DnsAddr[*]}   ${ipv6_DnsAddr[*]}"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "No search terms provided. Please specify what to search for"
		return 2
	}
	pkg_mgr_Find=$(command -v apk apt opkg pacman yum zypper dnf | head -n1)
	case ${pkg_mgr_Find##*/} in
	apk) search_command-Find="apk search" ;;
	apt) search_command-Find="apt-cache search" ;;
	opkg) search_command-Find="opkg search" ;;
	pacman) search_command-Find="pacman -Ss" ;;
	yum) search_command-Find="yum search" ;;
	zypper) search_command-Find="zypper search" ;;
	dnf) search_command-Find="dnf search" ;;
	*) {
		Err "Package manager not found or unsupported"
		return 1
	} ;;
	esac
	for target in "$@"; do
		Txt "${CLR3}SEARCH [$target]${CLR0}"
		${search_command-Find} "$target" || {
			Err "No results found for $target\n"
			return 1
		}
		Txt "${CLR2}FINISHED${CLR0}\n"
	done
}
function Font() {
	font_style-Font=""
	declare -A font_style_list-Font=(
		[B]="\033[1m" [U]="\033[4m"
		[BLACK]="\033[30m" [RED]="\033[31m" [GREEN]="\033[32m" [YELLOW]="\033[33m"
		[BLUE]="\033[34m" [PURPLE]="\033[35m" [CYAN]="\033[36m" [WHITE]="\033[37m"
		[L.BLACK]="\033[90m" [L.RED]="\033[91m" [L.GREEN]="\033[92m" [L.YELLOW]="\033[93m"
		[L.BLUE]="\033[94m" [L.PURPLE]="\033[95m" [L.CYAN]="\033[96m" [L.WHITE]="\033[97m"
		[BG.BLACK]="\033[40m" [BG.RED]="\033[41m" [BG.GREEN]="\033[42m" [BG.YELLOW]="\033[43m"
		[BG.BLUE]="\033[44m" [BG.PURPLE]="\033[45m" [BG.CYAN]="\033[46m" [BG.WHITE]="\033[47m"
		[L.BG.BLACK]="\033[100m" [L.BG.RED]="\033[101m" [L.BG.GREEN]="\033[102m" [L.BG.YELLOW]="\033[103m"
		[L.BG.BLUE]="\033[104m" [L.BG.PURPLE]="\033[105m" [L.BG.CYAN]="\033[106m" [L.BG.WHITE]="\033[107m"
	)
	while [[ $# -gt 1 ]]; do
		case "$1" in
		RGB)
			shift
			[[ $1 =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]] && font_style-Font+="\033[38;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
			;;
		BG.RGB)
			shift
			[[ $1 =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]] && font_style-Font+="\033[48;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
			;;
		*) font_style-Font+="${font_style_list-Font[$1]:-}" ;;
		esac
		shift
	done
	Txt "${font_style-Font}$1${CLR0}"
}
function Format() {
	flg_Format="$1"
	value="$2"
	ans_Format=""
	[ -z "$value" ] && {
		Err "No value provided for formatting"
		return 2
	}
	[ -z "$flg_Format" ] && {
		Err "No formatting option provided"
		return 2
	}
	case "$flg_Format" in
	-AA) ans_Format=$(Txt "$value" | tr '[:lower:]' '[:upper:]') ;;
	-aa) ans_Format=$(Txt "$value" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) ans_Format=$(Txt "$value" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) ans_Format="$value" ;;
	esac
	Txt "$ans_Format"
}
function Get() {
	unzip_Get="false"
	targ_dir_Get="."
	ren_file_Get=""
	url_Get=""
	while [ $# -gt 0 ]; do
		case "$1" in
		-x)
			unzip_Get=true
			shift
			;;
		-r)
			[ -z "$2" ] || [[ $2 == -* ]] && {
				Err "No filename specified after -r option"
				return 2
			}
			ren_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "Invalid option: $1"
			return 2
		} ;;
		*)
			[ -z "$url_Get" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "$url_Get" ] && {
		Err "No URL specified. Please provide a URL to download"
		return 2
	}
	[[ $url_Get =~ ^(http|https|ftp):// ]] || url_Get="https://$url_Get"
	out_file_Get="${url_Get##*/}"
	[ -z "$out_file_Get" ] && out_file_Get="index.html"
	[ "$targ_dir_Get" != "." ] && { mkdir -p "$targ_dir_Get" || {
		Err "Failed to create directory $targetDirectory"
		return 1
	}; }
	[ -n "$ren_file_Get" ] && out_file_Get="$ren_file_Get"
	out_path_Get="$targ_dir_Get/$out_file_Get"
	url_Get=$(echo "$url_Get" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR3}DOWNLOAD [$uniformResourceLocator]${CLR0}"
	file_sz_Get=$(curl -sI "$url_Get" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "$file_sz_Get" ] && [ "$file_sz_Get" -gt "26214400" ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "$url_Get" -O "$out_path_Get" || {
			Err "Failed to download file using Wget"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "$url_Get" -o "$out_path_Get" || {
			Err "Failed to download file using cUrl"
			return 1
		}
	fi
	if [ -f "$out_path_Get" ]; then
		Txt "* File downloaded successfully to $outputPath"
		if [ "$unzip_Get" = true ]; then
			case "$out_file_Get" in
			*.tar.gz | *.tgz) tar -xzf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "Failed to extract tar.gz file"
				return 1
			} ;;
			*.tar) tar -xf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "Failed to extract tar file"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "Failed to extract tar.bz2 file"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "Failed to extract tar.xz file"
				return 1
			} ;;
			*.zip) unzip "$out_path_Get" -d "$targ_dir_Get" || {
				Err "Failed to extract zip file"
				return 1
			} ;;
			*.7z) 7z x "$out_path_Get" -o"$targ_dir_Get" || {
				Err "Failed to extract 7z file"
				return 1
			} ;;
			*.rar) unrar x "$out_path_Get" "$targ_dir_Get" || {
				Err "Failed to extract rar file"
				return 1
			} ;;
			*.zst) zstd -d "$out_path_Get" -o "$targ_dir_Get" || {
				Err "Failed to extract zst file"
				return 1
			} ;;
			*) Txt "* File format not recognized for auto-extraction" ;;
			esac
			[ $? -eq 0 ] && Txt "* File extracted successfully to $targetDirectory"
		fi
		Txt "${CLR2}FINISHED${CLR0}\n"
	else
		{
			Err "Download failed. Check your internet connection and URL validity"
			return 1
		}
	fi
}
function Iface() {
	interface_Iface=""
	declare -a interfaces_Iface=()
	all_interfaces_Iface=$(
		cat /proc/net/dev |
			grep ':' |
			cut -d':' -f1 |
			sed 's/\s//g' |
			grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker\|^br-\|^veth' |
			sort -n
	) || {
		Err "Failed to get network interfaces from /proc/net/dev"
		return 1
	}
	i=1
	while read -r interface_item_Iface; do
		[ -n "$interface_item_Iface" ] && interfaces_Iface[$i]="$interface_item_Iface"
		((i++))
	done <<<"$allInterfaces"
	interfaces_number_Iface="${#interfaces_Iface[*]}"
	default4_route_Iface=$(ip -4 route show default 2>/dev/null | grep -A 3 "^default" || Txt)
	default6_route_Iface=$(ip -6 route show default 2>/dev/null | grep -A 3 "^default" || Txt)
	interface4_Iface=""
	interface6_Iface=""
	for ((i = 1; i <= ${#interfaces_Iface[@]}; i++)); do
		item_Iface="${interfaces_Iface[$i]}"
		[ -z "$item_Iface" ] && continue
		if [[ -n $interface4_Iface && $interface4_Iface == *"$item_Iface"* ]] && [ -z "$interface4_Iface" ]; then
			interface4_Iface="$item_Iface"
		fi
		if [[ -n $interface6_Iface && $interface6_Iface == *"$item_Iface"* ]] && [ -z "$interface6_Iface" ]; then
			interface6_Iface="$item_Iface"
		fi
		[ -n "$interface4_Iface" ] && [ -n "$interface6_Iface" ] && break
	done
	if [ -z "$interface4_Iface" ] && [ -z "$interface6_Iface" ]; then
		for ((i = 1; i <= ${#interfaces_Iface[@]}; i++)); do
			item_Iface="${interfaces_Iface[$i]}"
			if [[ $item_Iface =~ ^en ]]; then
				interface4_Iface="$item_Iface"
				interface6_Iface="$item_Iface"
				break
			fi
		done
		if [ -z "$interface4_Iface" ] && [ -z "$interface6_Iface" ] && [ "$interfaces_number_Iface" -gt 0 ]; then
			interface4_Iface="${interfaces_Iface[1]}"
			interface6_Iface="${interfaces_Iface[1]}"
		fi
	fi
	if [ -n "$interface4_Iface" ] || [ -n "$interface6_Iface" ]; then
		interface_Iface="$interface4_Iface $interface6_Iface"
		[[ $interface4_Iface == "$interface6_Iface" ]] && interface_Iface="$interface4_Iface"
		interface_Iface=$(Txt "$interface_Iface" | tr -s ' ' | xargs)
	else
		phys_insterface_Iface=$(ip -o link show | grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | grep 'state UP' | head -n 1 | awk -F': ' '{print $2}')
		if [ -n "$phys_insterface_Iface" ]; then
			interface_Iface="$phys_insterface_Iface"
		else
			interface_Iface=$(ip -o link show | grep -v 'lo:' | head -n 1 | awk -F': ' '{print $2}')
		fi
	fi
	case "$1" in
	rx_bytes | rx_packets | rx_drop | tx_bytes | tx_packets | tx_drop)
		for iface_Iface in $interface_Iface; do
			if stats_Iface=$(awk -v iface="$iface_Iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes_Iface rx_packets_Iface rx_drop_Iface tx_bytes_Iface tx_packets_Iface tx_drop_Iface <<<"$stats_Iface"
				case "$1" in
				rx_bytes)
					Txt "$rx_bytes_Iface"
					break
					;;
				rx_packets)
					Txt "$rx_packets_Iface"
					break
					;;
				rx_drop)
					Txt "$rx_drop_Iface"
					break
					;;
				tx_bytes)
					Txt "$tx_bytes_Iface"
					break
					;;
				tx_packets)
					Txt "$tx_packets_Iface"
					break
					;;
				tx_drop)
					Txt "$tx_drop_Iface"
					break
					;;
				esac
			fi
		done
		;;
	-i)
		for iface_Iface in $interface_Iface; do
			if stats_Iface=$(awk -v iface="$iface_Iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes_Iface rx_packets_Iface rx_drop_Iface tx_bytes_Iface tx_packets_Iface tx_drop_Iface <<<"$stats_Iface"
				Txt "$iface_Iface: RX: $(ConvSz $rx_bytes_Iface), TX: $(ConvSz $tx_bytes_Iface)"
			fi
		done
		;;
	"") Txt "$interface_Iface" ;;
	*)
		Err "Invalid parameter: $1. Valid parameters are: rx_bytes, rx_packets, rx_drop, tx_bytes, tx_packets, tx_drop, -i"
		return 2
		;;
	esac
}
function IpAddr() {
	ver_IpAddr="$1"
	case "${ver_IpAddr}" in
	-4)
		ipv4_addr_IpAddr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv4_addr_IpAddr}" ] && Txt "${ipv4_addr_IpAddr}" || {
			Err "Failed to retrieve IPv4 address. Check your internet connection"
			return 1
		}
		;;
	-6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "${ipv6_addr_IpAddr}" || {
			Err "Failed to retrieve IPv6 address. Check your internet connection"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr -4)
		ipv6_addr_IpAddr=$(IpAddr -6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "Failed to retrieve IP addresses"
			return 1
		}
		[ -n "${ipv4_addr_IpAddr}" ] && Txt "IPv4: ${ipv4_addr_IpAddr}"
		[ -n "${ipv6_addr_IpAddr}" ] && Txt "IPv6: ${ipv6_addr_IpAddr}"
		return
		;;
	esac
}
function LastUpd() {
	if [ -f /var/log/apt/history.log ]; then
		upd_dat_LastUpd=$(awk '/End-Date:/ {print $2, $3, $4; exit}' /var/log/apt/history.log 2>/dev/null)
	elif [ -f /var/log/dpkg.log ]; then
		upd_dat_LastUpd=$(tail -n 1 /var/log/dpkg.log | awk '{print $1, $2}')
	elif command -v rpm &>/dev/null; then
		upd_dat_LastUpd=$(rpm -qa --last | head -n 1 | awk '{print $3, $4, $5, $6, $7}')
	fi
	[ -z "${upd_dat_LastUpd}" ] && {
		Err "Unable to determine last system update time. Update logs not found"
		return 1
	} || Txt "${upd_dat_LastUpd}"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "Failed to print line"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		dat_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "Failed to get load average from uptime command"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${dat_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "Failed to read load average from /proc/loadavg"
			return 1
		}
	fi
	[[ ${zo_mi_LoadAvg} =~ ^[0-9.]+$ ]] || zo_mi_LoadAvg=0
	[[ ${zv_mi_LoadAvg} =~ ^[0-9.]+$ ]] || zv_mi_LoadAvg=0
	[[ ${ov_mi_LoadAvg} =~ ^[0-9.]+$ ]] || ov_mi_LoadAvg=0
	LC_ALL=C printf "%.2f, %.2f, %.2f (%d cores)" "${zo_mi_LoadAvg}" "${zv_mi_LoadAvg}" "${ov_mi_LoadAvg}" "$(nproc)"
}
function Loc() {
	get_Loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^loc=" | cut -d= -f2)
	[ -n "${get_Loc}" ] && Txt "${get_Loc}" || {
		Err "Unable to detect location. Check your internet connection"
		return 1
	}
}
function MacAddr() {
	get_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${get_MacAddr} ]] && Txt "${get_MacAddr}" || {
		Err "Unable to retrieve MAC address. Network interface not found"
		return 1
	}
}
function MemUsage() {
	used_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || used_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "Failed to get memory usage statistics"
		return 1
	}
	ttl_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || ttl_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) Txt "${used_MemUsage}" ;;
	-t) Txt "${ttl_MemUsage}" ;;
	-p) Txt "${pct_MemUsage}" ;;
	*) Txt "$(ConvSz "${used_MemUsage}") / $(ConvSz "${ttl_MemUsage}") (${pct_MemUsage}%)" ;;
	esac
}
function Provider() {
	ans_Provider=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		ans_Provider=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		ans_Provider=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${ans_Provider}" ] && Txt "${ans_Provider}" || {
		Err "Unable to detect network provider. Check your internet connection"
		return 1
	}
}
function PkgCnt() {
	pkg_mgr_PkgCnt=$(command -v apk apt opkg pacman yum zypper dnf 2>/dev/null | head -n1)
	case ${pkg_mgr_PkgCnt##*/} in
	apk) cnt_cmd_PkgCnt="apk info" ;;
	apt) cnt_cmd_PkgCnt="dpkg --get-selections" ;;
	opkg) cnt_cmd_PkgCnt="opkg list-installed" ;;
	pacman) cnt_cmd_PkgCnt="pacman -Q" ;;
	yum | dnf) cnt_cmd_PkgCnt="rpm -qa" ;;
	zypper) cnt_cmd_PkgCnt="zypper se --installed-only" ;;
	*) {
		Err "Unable to count installed packages. Package manager not supported"
		return 1
	} ;;
	esac
	if ! cnt_PkgCnt=$(${cnt_cmd_PkgCnt} 2>/dev/null | wc -l) || [[ -z ${cnt_PkgCnt} || ${cnt_PkgCnt} -eq 0 ]]; then
		{
			Err "Failed to count packages for ${packageManager##*/}"
			return 1
		}
	fi
	Txt "${cnt_PkgCnt}"
}
function Progress() {
	num_cmd_Progress=${#cmds[@]}
	term_wid_Progress=$(tput cols) || {
		Err "Failed to get terminal width"
		return 1
	}
	bar_wid_Progress=$((term_wid_Progress - 23))
	stty -echo
	trap '' SIGINT SIGQUIT SIGTSTP
	for ((i = 0; i < num_cmd_Progress; i++)); do
		prog_Progress=$((i * 100 / num_cmd_Progress))
		fild_wid_Progress=$((prog_Progress * bar_wid_Progress / 100))
		printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "${prog_Progress}" "$(printf "%${fild_wid_Progress}s" | tr ' ' '#')" "$(printf "%$((bar_wid_Progress - fild_wid_Progress))s" | tr ' ' '.')"
		if ! out_Progress=$(eval "${cmds[$i]}" 2>&1); then
			Txt "\n${out_Progress}"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "Command execution failed: ${commands[$i]}"
				return 1
			}
		fi
	done
	printf "\r\033[30;42mProgress: [100%%]\033[0m [%s]" "$(printf "%${bar_wid_Progress}s" | tr ' ' '#')"
	printf "\r%${term_wid_Progress}s\r"
	stty echo
	trap - SIGINT SIGQUIT SIGTSTP
}
function PublicIp() {
	ip_PublicIp=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^ip=" | cut -d= -f2)
	[ -n "${ip_PublicIp}" ] && Txt "${ip_PublicIp}" || {
		Err "Unable to detect public IP address. Check your internet connection"
		return 1
	}
}
function Run() {
	cmd_Run=()
	# Add bash-completion &>/dev/null
	RunCompletions() {
		curr_word_Run="${COMP_WORDS[COMP_CWORD]}"
		prev_word_Run="${COMP_WORDS[COMP_CWORD - 1]}"
		completion_opt_Run="${cmd_Run[*]}"
		compreply_Run=($(compgen -W "${completion_opt_Run}" -- "${curr_word_Run}"))
		[[ ${#compreply_Run[@]} -eq 0 ]] && compreply_Run=($(compgen -c -- "${curr_word_Run}"))
	}
	complete -F RunCompletions RUN
	[ $# -eq 0 ] && {
		Err "No command specified"
		return 2
	}
	if [[ $1 == *"/"* ]]; then
		if [[ $1 =~ ^https?:// ]]; then
			url_Run="$1"
			script_Run=$(basename "$1")
			del_after_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-d)
					del_after_Run=true
					shift
					;;
				*) break ;;
				esac
			done
			Txt "${CLR3}Downloading and executing script [${scriptName}] from URL${CLR0}"
			Task "* Downloading script" "
				curl -sSLf "${url_Run}" -o "${script_Run}" || { Err "Failed to download script $scriptName"; return 1; }
				chmod +x "${script_Run}" || { Err "Failed to set execute permission for $scriptName"; return 1; }
			"
			Txt "${CLR8}$(Linet = "24")${CLR0}"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_Run}" "$@" || {
					Err "Failed to execute script $scriptName"
					return 1
				}
			else
				./"${script_Run}" || {
					Err "Failed to execute script $scriptName"
					return 1
				}
			fi
			Txt "${CLR8}$(Linet = "24")${CLR0}"
			Txt "${CLR2}FINISHED${CLR0}\n"
			[[ ${del_after_Run} == true ]] && rm -rf "${script_Run}"
		elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner_Run=$(Txt "$1" | cut -d'/' -f1)
			repo_name_Run=$(Txt "$1" | cut -d'/' -f2)
			script_path_Run=$(Txt "$1" | cut -d'/' -f3-)
			script_Run=$(basename "${script_path_Run}")
			dnload_repo_Run=false
			repo_branch_Run="main"
			del_after_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-b)
					[[ -z $2 || $2 == -* ]] && {
						Err "Branch name required after -b"
						return 2
					}
					repo_branch_Run="$2"
					shift 2
					;;
				-r)
					dnload_repo_Run=true
					shift
					;;
				-d)
					del_after_Run=true
					shift
					;;
				*) break ;;
				esac
			done
			if [[ ${dnload_repo_Run} == true ]]; then
				Txt "${CLR3}Cloning repository ${repositoryOwner}/${repositoryName}${CLR0}"
				[[ -d ${repo_name_Run} ]] && {
					Err "Directory $repositoryName already exists"
					return 1
				}
				temp_dir_Run=$(mktemp -d)
				if [[ ${repo_branch_Run} != "main" ]]; then
					Task "* Cloning from repositoryBranch $repositoryBranch" "git clone --branch ${repo_branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git "${temp_dir_Run}""
					if [ $? -ne 0 ]; then
						rm -rf "${temp_dir_Run}"
						{
							Err "Failed to clone repository from $repositoryBranch repositoryBranch"
							return 1
						}
					fi
				else
					Task "* Checking main repositoryBranch" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git "${temp_dir_Run}"" true
					if [ $? -ne 0 ]; then
						Task "* Trying master repositoryBranch" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git "${temp_dir_Run}""
						if [ $? -ne 0 ]; then
							rm -rf "${temp_dir_Run}"
							{
								Err "Failed to clone repository from either main or master repositoryBranch"
								return 1
							}
						fi
					fi
				fi
				Task "* Creating target directory" "Add -d "${repo_name_Run}" && cp -r "${temp_dir_Run}"/* "${repo_name_Run}"/"
				Task "* Cleaning up temporary files" "rm -rf "${temp_dir_Run}""
				Txt "Repository cloned to directory: ${CLR2}$repositoryName${CLR0}"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "* Setting execute permissions" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "${CLR8}$(Linet = "24")${CLR0}"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "Failed to execute script $scriptName"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "Failed to execute script $scriptName"
							return 1
						}
					fi
					Txt "${CLR8}$(Linet = "24")${CLR0}"
					Txt "${CLR2}FINISHED${CLR0}\n"
					[[ ${del_after_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "${CLR3}Downloading and executing script [${scriptName}] from ${repositoryOwner}/${repositoryName}${CLR0}"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/refs/heads/${repo_branch_Run}/${script_path_Run}"
				if [[ ${repo_branch_Run} != "main" ]]; then
					Task "* Checking $repositoryBranch repositoryBranch" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "Script not found in $repositoryBranch repositoryBranch"
						return 1
					}
				else
					Task "* Checking main repositoryBranch" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "* Checking master repositoryBranch" "
							repo_branch_Run="master"
							github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/refs/heads/master/${script_path_Run}"
							curl -sLf "${github_url_Run}" >/dev/null
						"
						[ $? -ne 0 ] && {
							Err "Script not found in either main or master repositoryBranch"
							return 1
						}
					fi
				fi
				Task "* Downloading script" "
					curl -sSLf \"${github_url_Run}\" -o \"${script_Run}\" || { 
						Err \"Failed to download script $scriptName\"
						Err \"Failed to download from: $github_uniformResourceLocator\"
						return 1
					}

					if [[ ! -f \"${script_Run}\" ]]; then
						Err \"Download failed: File not created\"
						return 1
					fi

					if [[ ! -s \"${script_Run}\" ]]; then
						Err \"Downloaded file is empty\"
						cat \"${script_Run}\" 2>/dev/null || echo \"(cannot display file content)\"
						return 1
					fi

					if ! grep -q '[^[:space:]]' \"${script_Run}\"; then
						Err \"Downloaded file contains only whitespace\"
						return 1
					fi

					chmod +x \"${script_Run}\" || { 
						Err \"Failed to set execute permission for $scriptName\"
						Err \"Failed to set execute permission on $scriptName\"
						ls -la \"${script_Run}\"
						return 1
					}
				"

				Txt "${CLR8}$(Linet = "24")${CLR0}"
				if [[ -f ${script_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_Run}" "$@" || {
							Err "Failed to execute script $scriptName"
							return 1
						}
					else
						./"${script_Run}" || {
							Err "Failed to execute script $scriptName"
							return 1
						}
					fi
				else
					Err "Script file '$scriptName' was not downloaded successfully"
					return 1
				fi
				Txt "${CLR8}$(Linet = "24")${CLR0}"
				Txt "${CLR2}FINISHED${CLR0}\n"
				[[ ${del_after_Run} == true ]] && rm -rf "${script_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "Failed to execute script $scriptName"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "Failed to execute script $scriptName"
					return 1
				}
			fi
		fi
	else
		eval "$*"
	fi
	rm -rf /tmp/* &>/dev/null
}
function ShellVer() {
	LC_ALL=C
	if [ -n "${BASH_VERSION-}" ]; then
		Txt "Bash ${BASH_VERSION}"
	elif [ -n "${ZSH_VERSION-}" ]; then
		Txt "Zsh ${ZSH_VERSION}"
	else
		{
			Err "Unsupported shell"
			return 1
		}
	fi
}
function SwapUsage() {
	used_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	ttl_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) Txt "${used_SwapUsage}" ;;
	-t) Txt "${ttl_SwapUsage}" ;;
	-p) Txt "${pct_SwapUsage}" ;;
	*) Txt "$(ConvSz "${used_SwapUsage}") / $(ConvSz "${ttl_SwapUsage}") (${pct_SwapUsage}%)" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "${CLR3}Performing system cleanup...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "* Cleaning APK cache"
		apk cache clean || {
			Err "Failed to clean APK cache"
			return 1
		}
		Txt "* Removing temporary files"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "Failed to remove temporary files"
			return 1
		}
		Txt "* Fixing APK packages"
		apk fix || {
			Err "Failed to fix APK packages"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "* Waiting for dpkg lock"
			sleep 1 || return 1
			((waiting_time_SysClean++))
			[ "${waiting_time_SysClean}" -gt 300 ] && {
				Err "Timeout waiting for dpkg lock to be released"
				return 1
			}
		done
		Txt "* Configuring pending packages"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "Failed to configure pending packages"
			return 1
		}
		Txt "* Autoremoving packages"
		apt autoremove --purge -y || {
			Err "Failed to autoremove packages"
			return 1
		}
		Txt "* Cleaning APT cache"
		apt clean -y || {
			Err "Failed to clean APT cache"
			return 1
		}
		Txt "* Autocleaning APT cache"
		apt autoclean -y || {
			Err "Failed to autoclean APT cache"
			return 1
		}
		;;
	*opkg)
		Txt "* Removing temporary files"
		rm -rf /tmp/* || {
			Err "Failed to remove temporary files"
			return 1
		}
		Txt "* Updating OPKG"
		opkg update || {
			Err "Failed to update OPKG"
			return 1
		}
		Txt "* Cleaning OPKG cache"
		opkg clean || {
			Err "Failed to clean OPKG cache"
			return 1
		}
		;;
	*pacman)
		Txt "* Updating and upgrading packages"
		pacman -Syu --noconfirm || {
			Err "Failed to update and upgrade packages using pacman"
			return 1
		}
		Txt "* Cleaning pacman cache"
		pacman -Sc --noconfirm || {
			Err "Failed to clean pacman cache"
			return 1
		}
		Txt "* Cleaning all pacman cache"
		pacman -Scc --noconfirm || {
			Err "Failed to clean all pacman cache"
			return 1
		}
		;;
	*yum)
		Txt "* Autoremoving packages"
		yum autoremove -y || {
			Err "Failed to autoremove packages"
			return 1
		}
		Txt "* Cleaning YUM cache"
		yum clean all || {
			Err "Failed to clean YUM cache"
			return 1
		}
		Txt "* Making YUM cache"
		yum makecache || {
			Err "Failed to make YUM cache"
			return 1
		}
		;;
	*zypper)
		Txt "* Cleaning Zypper cache"
		zypper clean --all || {
			Err "Failed to clean Zypper cache"
			return 1
		}
		Txt "* Refreshing Zypper repositories"
		zypper refresh || {
			Err "Failed to refresh Zypper repositories"
			return 1
		}
		;;
	*dnf)
		Txt "* Autoremoving packages"
		dnf autoremove -y || {
			Err "Failed to autoremove packages"
			return 1
		}
		Txt "* Cleaning DNF cache"
		dnf clean all || {
			Err "Failed to clean DNF cache"
			return 1
		}
		Txt "* Making DNF cache"
		dnf makecache || {
			Err "Failed to make DNF cache"
			return 1
		}
		;;
	*) {
		Err "Unsupported package manager. Skipping system-specific cleanup"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "* Rotating and vacuuming journalctl logs" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "Failed to rotate and vacuum journalctl logs"
			return 1
		}
	fi
	Task "* Removing temporary files" "rm -rf /tmp/*" || {
		Err "Failed to remove temporary files"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "* Cleaning Docker system" "docker system prune -af" || {
				Err "Failed to clean Docker system"
				return 1
			} ;;
			npm) Task "* Cleaning NPM cache" "npm cache clean --force" || {
				Err "Failed to clean NPM cache"
				return 1
			} ;;
			pip) Task "* Purging PIP cache" "pip cache purge" || {
				Err "Failed to purge PIP cache"
				return 1
			} ;;
			esac
		fi
	done
	Task "* Removing user cache files" "rm -rf ~/.cache/*" || {
		Err "Failed to remove user cache files"
		return 1
	}
	Task "* Removing thumbnail files" "rm -rf ~/.thumbnails/*" || {
		Err "Failed to remove thumbnail files"
		return 1
	}
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}FINISHED${CLR0}\n"
}
function SysInfo() {
	Txt "${CLR3}System Information${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"

	Txt "- Hostname:		${CLR2}$(uname -n || {
		Err "Failed to get hostname"
		return 1
	})${CLR0}"
	Txt "- Operating System:	${CLR2}$(ChkOs)${CLR0}"
	Txt "- Kernel Version:	${CLR2}$(uname -r)${CLR0}"
	Txt "- System Language:	${CLR2}$LANG${CLR0}"
	Txt "- Shell Version:	${CLR2}$(ShellVer)${CLR0}"
	Txt "- Last System Update:	${CLR2}$(LastUpd)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- Architecture:		${CLR2}$(uname -m)${CLR0}"
	Txt "- CPU Model:		${CLR2}$(CpuModel)${CLR0}"
	Txt "- CPU Cores:		${CLR2}$(nproc)${CLR0}"
	Txt "- CPU Frequency:	${CLR2}$(CpuFreq)${CLR0}"
	Txt "- CPU Usage:		${CLR2}$(CpuUsage)%${CLR0}"
	Txt "- CPU Cache:		${CLR2}$(CpuCache)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- Memory Usage:		${CLR2}$(MemUsage)${CLR0}"
	Txt "- Swap Usage:		${CLR2}$(SwapUsage)${CLR0}"
	Txt "- Disk Usage:		${CLR2}$(DiskUsage)${CLR0}"
	Txt "- File System Type:	${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- IPv4 Address:		${CLR2}$(IpAddr -4)${CLR0}"
	Txt "- IPv6 Address:		${CLR2}$(IpAddr -6)${CLR0}"
	Txt "- MAC Address:		${CLR2}$(MacAddr)${CLR0}"
	Txt "- Network Provider:	${CLR2}$(Provider)${CLR0}"
	Txt "- DNS Servers:		${CLR2}$(DnsAddr)${CLR0}"
	Txt "- Public IP:		${CLR2}$(PublicIp)${CLR0}"
	Txt "- Network Interface:	${CLR2}$(Iface -i)${CLR0}"
	Txt "- Internal Timezone:	${CLR2}$(TimeZone -i)${CLR0}"
	Txt "- External Timezone:	${CLR2}$(TimeZone -e)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- Load Average:		${CLR2}$(LoadAvg)${CLR0}"
	Txt "- Process Count:	${CLR2}$(ps aux | wc -l)${CLR0}"
	Txt "- Packages Installed:	${CLR2}$(PkgCnt)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- Uptime:		${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	Txt "- Boot Time:		${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- Virtualization:	${CLR2}$(ChkVirt)${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
}
function SysOptimize() {
	ChkRoot
	Txt "${CLR3}Optimizing system configuration for long-running servers...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "# Server optimizations for long-running systems" >"${sysctl_conf_SysOptimize}"

	Task "* Optimizing memory management" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "Failed to optimize memory management"
		return 1
	}

	Task "* Optimizing network settings" "
		Txt 'net.core.somaxconn = 65535' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.netdev_max_backlog = 65535' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_max_syn_backlog = 65535' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_fin_timeout = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_keepalive_time = 300' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_keepalive_probes = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_keepalive_intvl = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_tw_reuse = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.ip_local_port_range = 1024 65535' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "Failed to optimize network settings"
		return 1
	}

	Task "* Optimizing TCP buffers" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "Failed to optimize TCP buffers"
		return 1
	}

	Task "* Optimizing filesystem settings" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "Failed to optimize filesystem settings"
		return 1
	}

	Task "* Optimizing system limits" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "Failed to optimize system limits"
		return 1
	}

	Task "* Optimizing I/O scheduler" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "Failed to optimize I/O scheduler"
		return 1
	}

	Task "* Disabling non-essential services" '
		for service in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service 2>/dev/null || true
		done
	' || {
		Err "Failed to disable services"
		return 1
	}

	Task "* Applying system parameters" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "Failed to apply system parameters"
		return 1
	}

	Task "* Clearing system cache" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "Failed to clear system cache"
		return 1
	}

	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}FINISHED${CLR0}\n"
}
function SysRboot() {
	ChkRoot
	Txt "${CLR3}Preparing to reboot system...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	active_usr_SysRboot=$(who | wc -l) || {
		Err "Failed to get active user count"
		return 1
	}
	if [ "${active_usr_SysRboot}" -gt 1 ]; then
		Txt "${CLR1}Warning: There are currently $activeUsers active users on the system${CLR0}\n"
		Txt "Active users:"
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_proc_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "Failed to check running processes"
		return 1
	}
	if [ "${important_proc_SysRboot}" -gt 0 ]; then
		Txt "${CLR1}Warning: There are $importantProcesses important processes running${CLR0}\n"
		Txt "${CLR8}Top 5 processes by CPU usage:${CLR0}"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Press "Are you sure you want to reboot the system now? (y/N) " cont_SysRboot
	Txt
	[[ ! "${cont_SysRboot}" =~ ^[Yy]$ ]] && {
		Txt "${CLR2}Reboot cancelled${CLR0}\n"
		return 0
	}
	Task "* Performing final checks" "sync" || {
		Err "Failed to sync filesystems"
		return 1
	}
	Task "* Initiating reboot" "reboot || sudo reboot" || {
		Err "Failed to initiate reboot"
		return 1
	}
	Txt "${CLR2}Reboot command issued successfully. The system will reboot momentarily${CLR0}"
}
function SysUpd() {
	ChkRoot
	Txt "${CLR3}Updating system software...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	UpdPkg() {
		upd_cmd_SysUpd="$1"
		upg_cmd_SysUpd="$2"
		Txt "* Updating package lists"
		${upd_cmd_SysUpd} || {
			Err "Failed to update package lists using $cmd"
			return 1
		}
		Txt "* Upgrading packages"
		${upg_cmd_SysUpd} || {
			Err "Failed to upgrade packages using $cmd"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "* Waiting for dpkg lock" "sleep 1" || return 1
			((waiting_time_SysUpd++))
			[ "$waiting_time_SysUpd" -gt 10 ] && {
				Err "Timeout waiting for dpkg lock to be released"
				return 1
			}
		done
		Task "* Configuring pending packages" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "Failed to configure pending packages"
			return 1
		}
		UpdPkg "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg update" "opkg upgrade" ;;
	*pacman) Task "* Updating and upgrading packages" "pacman -Syu --noconfirm" || {
		Err "Failed to update and upgrade packages using pacman"
		return 1
	} ;;
	*yum) UpdPkg "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf check-update" "dnf -y update" ;;
	*) {
		Err "Unsupported package manager"
		return 1
	} ;;
	esac
	Txt "* Updating $SCRIPTS"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/refs/heads/main/sh/get_utilkit.sh) || {
		Err "Failed to update $SCRIPTS"
		return 1
	}
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}FINISHED${CLR0}\n"
}
function SysUpg() {
	ChkRoot
	Txt "${CLR3}Upgrading system to next major version...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	os_nm_SysUpg=$(ChkOs -n)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "* Detected 'Debian' system"
		Txt "* Updating package lists"
		apt update -y || {
			Err "Failed to update package lists using apt"
			return 1
		}
		Txt "* Upgrading current packages"
		apt full-upgrade -y || {
			Err "Failed to upgrade current packages"
			return 1
		}
		Txt "* Starting 'Debian' release upgrade..."
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${curr_codenm_SysUpg}" = "${targ_codenm_SysUpg}" ] && {
			Err "System is already running the latest stable version (${targ_codenm_SysUpg})"
			return 1
		}
		Txt "* Upgrading from ${CLR2}${currentCodename}${CLR0} to ${CLR3}${targetCodename}${CLR0}"
		Task "* Backing up sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "Failed to backup sources.list"
			return 1
		}
		Task "* Updating sources.list" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "Failed to update sources.list"
			return 1
		}
		Task "* Updating package lists for new release" "apt update -y" || {
			Err "Failed to update package lists for new release"
			return 1
		}
		Task "* Upgrading to new Debian release" "apt full-upgrade -y" || {
			Err "Failed to upgrade to new Debian release"
			return 1
		}
		;;
	Ubuntu)
		Txt "* Detected 'Ubuntu' system"
		Task "* Updating package lists" "apt update -y" || {
			Err "Failed to update package lists using apt"
			return 1
		}
		Task "* Upgrading current packages" "apt full-upgrade -y" || {
			Err "Failed to upgrade current packages"
			return 1
		}
		Task "* Installing update-manager-core" "apt install -y update-manager-core" || {
			Err "Failed to install update-manager-core"
			return 1
		}
		Task "* Upgrading Ubuntu release" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "Failed to upgrade Ubuntu release"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "Your system is not yet supported for major version upgrades"
		return 1
	} ;;
	esac
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}System upgrade completed${CLR0}\n"
}
function Task() {
	msg_Task="$1"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "${CLR2}Done${CLR0}"
		ret_Task=0
	else
		ret_Task=$?
		Txt "${CLR1}Failed${CLR0} ("${ret_Task}")"
		[[ -s "${tmp_file_Task}" ]] && Txt "${CLR1}$(cat "${tmp_file_Task}")${CLR0}"
		[[ "${ign_err_Task}" != "true" ]] && return "${ret_Task}"
	fi
	Del -f "${tmp_file_Task}"
	return "${ret_Task}"
}
function TimeZone() {
	case "$1" in
	-e)
		ans_TimeZone=$(timeout 1s curl -sL ipapi.co/timezone) ||
			ans_TimeZone=$(timeout 1s curl -sL worldtimeapi.org/api/ip | grep -oP '"timezone":"\K[^"]+') ||
			ans_TimeZone=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"timezone":"\K[^"]+') ||
			[ -n "${ans_TimeZone}" ] && Txt "${ans_TimeZone}" || {
			Err "Failed to detect timezone from external services"
			return 1
		}
		;;
	-i | *)
		ans_TimeZone=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			ans_TimeZone=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			ans_TimeZone=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${ans_TimeZone}" ] && Txt "$ans_TimeZone" || {
			Err "Failed to detect system timezone"
			return 1
		}
		;;
	esac
}
function Press() {
	read -p "$1" -n 1 -r || {
		Err "Failed to read user input"
		return 1
	}
}

function TEST() {
	Txt "${CLR8}--- Starting UtilKit Test Suite ---${CLR0}"

	Linet "=" 40
	Txt "Testing Basic I/O Functions"
	Linet "-" 40
	Txt "Testing Txt:"
	Txt "  Hello World"
	Txt "Testing Err:"
	Err "  This is a test error message."
	Txt "Testing Font:"
	Font BOLD "  Bold Text"
	Font GREEN "  Green Text"
	Font BG.RED WHITE "  White text on Red background"
	Font RGB "100,150,200" "  Custom RGB color text"
	Txt "Testing Linet:"
	Linet "*" 20

	Linet "=" 40
	Txt "Testing File and Directory Operations"
	Linet "-" 40
	Txt "Testing Add -f (file):"
	Add -f test_file.tmp
	Txt "Testing Add -d (directory):"
	Add -d test_dir.tmp
	Txt "Listing created items:"
	ls -ld test_file.tmp test_dir.tmp
	Txt "Testing Del -f (file):"
	Del -f test_file.tmp
	Txt "Testing Del -d (directory):"
	Del -d test_dir.tmp
	Txt "Listing items after deletion:"
	ls -ld test_file.tmp test_dir.tmp 2>/dev/null || Txt "  Items successfully deleted."

	Linet "=" 40
	Txt "Testing System Information Functions"
	Linet "-" 40
	Txt "Authors: ${AUTHORS}"
	Txt "Script: ${SCRIPTS}"
	Txt "Version: ${VERSION}"
	Copyright
	Txt "OS Info: $(ChkOs)"
	Txt "OS Name: $(ChkOs -n)"
	Txt "OS Version: $(ChkOs -v)"
	Txt "Virt-Type: $(ChkVirt)"
	Txt "CPU Model: $(CpuModel)"
	Txt "CPU Freq: $(CpuFreq)"
	Txt "CPU Cache: $(CpuCache)"
	Txt "CPU Usage: $(CpuUsage)%"
	Txt "Shell: $(ShellVer)"
	Txt "Uptime: $(uptime -p)"
	Txt "Last Update: $(LastUpd)"
	Txt "Load Average: $(LoadAvg)"
	Txt "Package Count: $(PkgCnt)"

	Linet "=" 40
	Txt "Testing Resource Usage Functions"
	Linet "-" 40
	Txt "Memory Usage: $(MemUsage)"
	Txt "Swap Usage: $(SwapUsage)"
	Txt "Disk Usage: $(DiskUsage)"

	Linet "=" 40
	Txt "Testing Network Functions"
	Linet "-" 40
	Txt "Interface: $(Iface)"
	Txt "Interface Stats: $(Iface -i)"
	Txt "Public IP: $(PublicIp)"
	Txt "IP Address (v4): $(IpAddr -4)"
	Txt "IP Address (v6): $(IpAddr -6)"
	Txt "MAC Address: $(MacAddr)"
	Txt "DNS Servers: $(DnsAddr)"
	Txt "Location: $(Loc)"
	Txt "Provider: $(Provider)"
	Txt "Internal Timezone: $(TimeZone -i)"
	Txt "External Timezone: $(TimeZone -e)"

	Linet "=" 40
	Txt "Testing Utility Functions"
	Linet "-" 40
	Txt "Testing ConvSz:"
	Txt "  1024 B -> $(ConvSz 1024 B)"
	Txt "  2048000 KB -> $(ConvSz 2048000 KB)"
	Txt "  5.5 GiB -> $(ConvSz 5.5 GiB)"
	Txt "Testing Format:"
	Txt "  Format -AA 'hello world' -> $(Format -AA 'hello world')"
	Txt "  Format -aa 'HELLO WORLD' -> $(Format -aa 'HELLO WORLD')"
	Txt "  Format -Aa 'hello world' -> $(Format -Aa 'hello world')"
	Txt "Testing Get (small file):"
	Get https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/LICENSE -r test_license.tmp
	cat test_license.tmp
	Del -f test_license.tmp
	Txt "Testing Find (package 'curl'):"
	Find curl
	Txt "Testing ChkDep (dependency 'bash'):"
	deps=("bash" "non_existent_command")
	ChkDep

	Linet "=" 40
	Txt "Testing Interactive and Task Functions"
	Linet "-" 40
	Txt "Testing Task:"
	Task "  Running 'echo test' command" "echo test"
	Txt "Testing Progress:"
	cmds=("sleep 0.1" "sleep 0.2" "sleep 0.1")
	Progress
	Txt "\nTesting Run:"
	Run echo "  'Run' command executed successfully."
	# Txt "Testing Ask (will prompt for input):"
	# Ask "  Please enter your name: " myname
	# Txt "  Hello, \$myname"
	# Txt "Testing Press (will wait for a key press):"
	# Press "  Press any key to continue..."

	Linet "=" 40
	Txt "Testing Potentially Destructive Functions (COMMENTED OUT)"
	Linet "-" 40
	Txt "  The following functions are not executed automatically to prevent unwanted system changes."
	Txt "  Uncomment them in the TEST function to test them manually."
	# Txt "Testing SysClean:"
	# SysClean
	# Txt "Testing SysUpd:"
	# SysUpd
	# Txt "Testing SysUpg:"
	# SysUpg
	# Txt "Testing SysOptimize:"
	# SysOptimize
	# Txt "Testing SysRboot:"
	# SysRboot

	Linet "=" 40
	Txt "${CLR8}--- UtilKit Test Suite Finished ---${CLR0}"
}
