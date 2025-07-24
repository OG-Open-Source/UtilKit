#!/bin/bash

ANTHORS="OG-Open-Source"
SCRIPTS="UtilKit.sh"
VERSION="7.046.005"

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

PKG_MGR=""
UNIT_PREF="iB"

function Txt() { echo -e "$1" "$2"; }
function Err() {
	[ -z "$1" ] && {
		Txt "${CLR1}Unknown error${CLR0}"
		return 1
	}
	Txt "${CLR1}$1${CLR0}"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "$1" | tr -d '\n')"
		Txt "${log_entry_Err}" >>"${log_file_Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "No items specified to add. Please provide at least one item to add"
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
	mod_Add="pkg"
	err_code_Add=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f | --file)
			mod_Add="file"
			shift
			continue
			;;
		-d | --directory)
			mod_Add="dir"
			shift
			continue
			;;
		*.deb)
			ChkRoot
			deb_file_Add=$(basename "$1")
			Txt "${CLR3}Installing DEB package [${deb_file_Add}]${CLR0}\n"
			Get "$1"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "Failed to install ${deb_file_Add}. Please check package compatibility and dependencies\n"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "Failed to fix dependencies"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "* DEB package ${deb_file_Add} installed successfully"
				rm -f "${deb_file_Add}"
				Txt "${CLR2}Done${CLR0}\n"
			else
				Err "DEB package ${deb_file_Add} not found or download failed\n"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "${CLR3}Adding file [$1]${CLR0}"
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
					Err "Failed to create file $1. Please check permissions and disk space\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* File $1 created successfully"
				Txt "${CLR2}Done${CLR0}\n"
				;;
			"dir")
				Txt "${CLR3}Adding directory [$1]${CLR0}"
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
					Err "Failed to create directory $1. Please check permissions and path validity\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* Directory $1 created successfully"
				Txt "${CLR2}Done${CLR0}\n"
				;;
			"pkg")
				Txt "${CLR3}Installing package [$1]${CLR0}"
				ChkRoot
				case ${PKG_MGR} in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					is_instd_Add() {
						case ${PKG_MGR} in
						apk) apk info -e "$1" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "$1" &>/dev/null ;;
						yum | dnf) ${PKG_MGR} list installed "$1" &>/dev/null ;;
						zypper) zypper se -i -x "$1" &>/dev/null ;;
						esac
					}
					inst_pkg_Add() {
						case ${PKG_MGR} in
						apk) apk update && apk add "$1" ;;
						apt) apt install -y "$1" ;;
						opkg) opkg update && opkg install "$1" ;;
						pacman) pacman -Sy && pacman -S --noconfirm "$1" ;;
						yum | dnf) ${PKG_MGR} install -y "$1" ;;
						zypper) zypper refresh && zypper install -y "$1" ;;
						esac
					}
					if ! is_instd_Add "$1"; then
						Txt "* Package $1 is not installed"
						if inst_pkg_Add "$1"; then
							if is_instd_Add "$1"; then
								Txt "* Package $1 installed successfully"
								Txt "${CLR2}Done${CLR0}\n"
							else
								Err "Failed to install $1 using ${PKG_MGR}\n"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "Failed to install $1 using ${PKG_MGR}\n"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "* Package $1 is already installed"
						Txt "${CLR2}Done${CLR0}\n"
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
	return "${err_code_Add}"
}
function ChkDeps() {
	mod_ChkDeps="display"
	missg_deps_ChkDeps=()
	while [[ $1 == -* ]]; do
		case "$1" in
		-i | --interactive) mod_ChkDeps="interactive" ;;
		-a | --automatic) mod_ChkDeps="automatic" ;;
		*)
			Err "Invalid option: $1"
			return 1
			;;
		esac
		shift
	done
	for dep_ChkDeps in "${deps[@]}"; do
		if command -v "${dep_ChkDeps}" &>/dev/null; then
			status_ChkDeps="${CLR2}[Available]${CLR0}"
		else
			status_ChkDeps="${CLR1}[Missing]${CLR0}"
			missg_deps_ChkDeps+=("${dep_ChkDeps}")
		fi
		Txt "${status_ChkDeps}\t${dep_ChkDeps}"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "\n${CLR3}Missing packages:${CLR0} ${missg_deps_ChkDeps[*]}"
		Ask "Install missing packages? (y/N) " -n 1 cont_inst_ChkDeps
		Txt
		[[ ${cont_inst_ChkDeps} =~ ^[Yy]$ ]] && Add "${missg_deps_ChkDeps[@]}"
		;;
	"automatic")
		Txt
		Add "${missg_deps_ChkDeps[@]}"
		;;
	esac
}
function ChkOs() {
	case "$1" in
	-v | --version)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "${ID}" = "debian" ] && cat /etc/debian_version || Txt "${VERSION_ID}"
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
				Err "Unknown distribution"
				return 1
			}
		fi
		;;
	-n | --name)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			Txt "${ID}" | sed 's/.*/\u&/'
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
			[ "${ID}" = "debian" ] && Txt "${NAME} $(cat /etc/debian_version)" || Txt "${PRETTY_NAME}"
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
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "Please run this script as root user"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "Could not detect virtualization environment"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "Proxmox VE (KVM)" || Txt "KVM" ;;
		microsoft) Txt "Microsoft Hyper-V" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "LXC Container"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "Virtual Machine (Unknown Type)"
			else
				Txt "Not detected (likely physical machine)"
			fi
			;;
		*) Txt "${virt_typ_ChkVirt:-Not detected (likely physical machine)}" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "Virtual Machine" || Txt "None")
	else
		virt_typ_ChkVirt="Unknown"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "Failed to change directory"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "Could not access CPU information. /proc/cpuinfo is unavailable"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "Could not determine CPU cache size"
		return 1
	}
	Txt "${cpu_cache_CpuCache} KB"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "Could not access CPU information. /proc/cpuinfo is unavailable"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "Could not determine CPU frequency"
		return 1
	}
	Txt "${cpu_freq_CpuFreq} GHz"
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
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "Failed to read CPU statistics from /proc/stat"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "Failed to read CPU statistics from /proc/stat"
		return 1
	}
	curr_tot_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	curr_idle_CpuUsage=${idle_CpuUsage}
	tot_delta_CpuUsage=$((curr_tot_CpuUsage - prev_total_CpuUsage))
	idle_delta_CpuUsage=$((curr_idle_CpuUsage - prev_idle_CpuUsage))
	cpu_usage_CpuUsage=$((100 * (tot_delta_CpuUsage - idle_delta_CpuUsage) / tot_delta_CpuUsage))
	Txt "${cpu_usage_CpuUsage}"
}
function ConvSz() {
	[ -z "$1" ] && {
		Err "No size value provided for conversion"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-$UNIT_PREF}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "Invalid size value. Must be a number"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "Size value cannot be negative"
		return 2
	elif [[ ${size_ConvSz} =~ ^[+].*$ ]]; then
		size_ConvSz=${size_ConvSz#+}
	fi
	LC_NUMERIC=C awk -v size="${size_ConvSz}" -v unit="${unit_ConvSz}" '
		function toBytes(val, u,   _u) {
			_u = tolower(u);
			if (_u == "b" || _u == "ib") return val;
			if (_u == "kb")  return val * 1000;
			if (_u == "mb")  return val * 1000^2;
			if (_u == "gb")  return val * 1000^3;
			if (_u == "tb")  return val * 1000^4;
			if (_u == "pb")  return val * 1000^5;
			if (_u == "kib") return val * 1024;
			if (_u == "mib") return val * 1024^2;
			if (_u == "gib") return val * 1024^3;
			if (_u == "tib") return val * 1024^4;
			if (_u == "pib") return val * 1024^5;
			return -1;
		}
		BEGIN {
			bytes = toBytes(size, unit);
			if (bytes < 0) {
				exit 1;
			}
			is_binary = (index(tolower(unit), "ib") > 0);
			if (is_binary) {
				base = 1024;
				units_str = "B KiB MiB GiB TiB PiB";
			} else {
				base = 1000;
				units_str = "B KB MB GB TB PB";
			}
			split(units_str, units_arr, " ");
			power = 0;
			value = bytes;
			if (bytes > 0) {
				power = int(log(bytes)/log(base));
				if (power > 5) power = 5;
				if (power > 0) {
					value = bytes / (base^power);
				}
			}
			if (power == 0) {
				printf "%d %s", bytes, units_arr[1];
			} else {
				if (value >= 100) {
					printf "%.1f %s", value, units_arr[power + 1];
				} else if (value >= 10) {
					printf "%.2f %s", value, units_arr[power + 1];
				} else {
					printf "%.3f %s", value, units_arr[power + 1];
				}
			}
		}
	'
	if [ $? -eq 1 ]; then
		Err "Unsupported unit: ${unit_ConvSz}"
		return 2
	fi
}
function Copyright() {
	Txt "${SCRIPTS} ${VERSION}"
	Txt "Copyright (C) $(date +%Y) ${ANTHORS}."
}
function Del() {
	[ $# -eq 0 ] && {
		Err "No items specified to delete. Please provide at least one item to delete"
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
	mod_Del="pkg"
	err_code_Del=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f | --file)
			mod_Del="file"
			shift
			continue
			;;
		-d | --directory)
			mod_Del="dir"
			shift
			continue
			;;
		*)
			case "${mod_Del}" in
			"file")
				Txt "${CLR3}Deleting file [$1]${CLR0}"
				[ ! -f "$1" ] && {
					Err "File $1 does not exist\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* File $1 exists"
				rm -f "$1" || {
					Err "Failed to delete file $1\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* File $1 deleted successfully"
				Txt "${CLR2}Done${CLR0}\n"
				;;
			"dir")
				Txt "${CLR3}Deleting directory [$1]${CLR0}"
				[ ! -d "$1" ] && {
					Err "Directory $1 does not exist\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* Directory $1 exists"
				rm -rf "$1" || {
					Err "Failed to delete directory $1\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* Directory $1 deleted successfully"
				Txt "${CLR2}Done${CLR0}\n"
				;;
			"pkg")
				Txt "${CLR3}Removing package [$1]${CLR0}"
				ChkRoot
				case ${PKG_MGR} in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					is_instd_Del() {
						case ${PKG_MGR} in
						apk) apk info -e "$1" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "$1" &>/dev/null ;;
						yum | dnf) ${PKG_MGR} list installed "$1" &>/dev/null ;;
						zypper) zypper se -i -x "$1" &>/dev/null ;;
						esac
					}
					rm_pkg_Del() {
						case ${PKG_MGR} in
						apk) apk del "$1" ;;
						apt) apt purge -y "$1" && apt autoremove -y ;;
						opkg) opkg remove "$1" ;;
						pacman) pacman -Rns --noconfirm "$1" ;;
						yum | dnf) ${PKG_MGR} remove -y "$1" ;;
						zypper) zypper remove -y "$1" ;;
						esac
					}
					if ! is_instd_Del "$1"; then
						Txt "* Package $1 does not exist"
						Txt "${CLR2}Done${CLR0}\n"
					else
						if rm_pkg_Del "$1"; then
							if ! is_instd_Del "$1"; then
								Txt "* Package $1 removed successfully"
								Txt "${CLR2}Done${CLR0}\n"
							else
								Err "Failed to remove $1 using ${PKG_MGR}\n"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "Failed to remove $1 using ${PKG_MGR}\n"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "Unsupported package manager\n"
					err_code_Del=1
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
	return "${err_code_Del}"
}
function DiskUsage() {
	usd_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $3}') || {
		Err "Failed to get disk usage statistics"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "Failed to get total disk space"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u | --used) Txt "${usd_DiskUsage}" ;;
	-t | --total) Txt "${tot_DiskUsage}" ;;
	-p | --percentage) Txt "${pct_DiskUsage}" ;;
	*) Txt "$(ConvSz ${usd_DiskUsage}) / $(ConvSz ${tot_DiskUsage}) (${pct_DiskUsage}%)" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "DNS configuration file /etc/resolv.conf not found"
		return 1
	}
	ipv4_servers_DnsAddr=()
	ipv6_servers_DnsAddr=()
	while read -r servers_DnsAddr; do
		if [[ ${servers_DnsAddr} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			ipv4_servers_DnsAddr+=("${servers_DnsAddr}")
		elif [[ ${servers_DnsAddr} =~ ^[0-9a-fA-F:]+$ ]]; then
			ipv6_servers_DnsAddr+=("${servers_DnsAddr}")
		fi
	done < <(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')
	[[ ${#ipv4_servers_DnsAddr[@]} -eq 0 && ${#ipv6_servers_DnsAddr[@]} -eq 0 ]] && {
		Err "No DNS servers configured in /etc/resolv.conf"
		return 1
	}
	case "$1" in
	-4 | --ipv4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "No IPv4 DNS servers found"
			return 1
		}
		Txt "${ipv4_servers_DnsAddr[*]}"
		;;
	-6 | --ipv6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "No IPv6 DNS servers found"
			return 1
		}
		Txt "${ipv6_servers_DnsAddr[*]}"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "No DNS servers found"
			return 1
		}
		Txt "${ipv4_servers_DnsAddr[*]}   ${ipv6_servers_DnsAddr[*]}"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "No search criteria specified. Please specify what to search for"
		return 2
	}
	case ${PKG_MGR} in
	apk) srch_cmd_Find="apk search" ;;
	apt) srch_cmd_Find="apt-cache search" ;;
	opkg) srch_cmd_Find="opkg search" ;;
	pacman) srch_cmd_Find="pacman -Ss" ;;
	yum) srch_cmd_Find="yum search" ;;
	zypper) srch_cmd_Find="zypper search" ;;
	dnf) srch_cmd_Find="dnf search" ;;
	*) {
		Err "Package manager not found or unsupported"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "${CLR3}Searching for [${targ_Find}]${CLR0}"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "No results found for ${targ_Find}\n"
			return 1
		}
		Txt "${CLR2}Done${CLR0}\n"
	done
}
function Font() {
	font_style_Font=""
	declare -A style_Font=(
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
			[[ $1 =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]] && font_style_Font+="\033[38;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
			;;
		BG.RGB)
			shift
			[[ $1 =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]] && font_style_Font+="\033[48;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
			;;
		*) font_style_Font+="${style_Font[$1]:-}" ;;
		esac
		shift
	done
	Txt "${font_style_Font}${1}${CLR0}"
}
function Format() {
	flg_Format="$1"
	val_Format="$2"
	res_Format=""
	[ -z "${val_Format}" ] && {
		Err "No value provided for formatting"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "No formatting option provided"
		return 2
	}
	case "${flg_Format}" in
	-AA) res_Format=$(Txt "${val_Format}" | tr '[:lower:]' '[:upper:]') ;;
	-aa) res_Format=$(Txt "${val_Format}" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) res_Format=$(Txt "${val_Format}" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) res_Format="${val_Format}" ;;
	esac
	Txt "${res_Format}"
}
function Get() {
	unzip_Get="false"
	targ_dir_Get="."
	rnm_file_Get=""
	url_Get=""
	while [ $# -gt 0 ]; do
		case "$1" in
		-x | --unzip)
			unzip_Get=true
			shift
			;;
		-r | --rename)
			[ -z "$2" ] || [[ $2 == -* ]] && {
				Err "No filename specified after -r option"
				return 2
			}
			rnm_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "Invalid option: $1"
			return 2
		} ;;
		*)
			[ -z "${url_Get}" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "${url_Get}" ] && {
		Err "No URL specified. Please provide the URL to download"
		return 2
	}
	[[ ${url_Get} =~ ^(http|https|ftp):// ]] || url_Get="https://${url_Get}"
	oup_file_Get="${url_Get##*/}"
	[ -z "${oup_file_Get}" ] && oup_file_Get="index.html"
	[ "${targ_dir_Get}" != "." ] && { mkdir -p "${targ_dir_Get}" || {
		Err "Failed to create directory ${targ_dir_Get}"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && oup_file_Get="${rnm_file_Get}"
	oup_path_Get="${targ_dir_Get}/${oup_file_Get}"
	url_Get=$(Txt "${url_Get}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR3}Downloading [${url_Get}]${CLR0}"
	file_sz_Get=$(curl -sI "${url_Get}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url_Get}" -O "${oup_path_Get}" || {
			Err "Failed to download file using Wget"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url_Get}" -o "${oup_path_Get}" || {
			Err "Failed to download file using cUrl"
			return 1
		}
	fi
	if [ -f "${oup_path_Get}" ]; then
		Txt "* File successfully downloaded to ${oup_path_Get}"
		if [ "${unzip_Get}" = true ]; then
			case "${oup_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Failed to decompress tar.gz file"
				return 1
			} ;;
			*.tar) tar -xf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Failed to decompress tar file"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Failed to decompress tar.bz2 file"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Failed to decompress tar.xz file"
				return 1
			} ;;
			*.zip) unzip "${oup_path_Get}" -d "${targ_dir_Get}" || {
				Err "Failed to decompress zip file"
				return 1
			} ;;
			*.7z) 7z x "${oup_path_Get}" -o"${targ_dir_Get}" || {
				Err "Failed to decompress 7z file"
				return 1
			} ;;
			*.rar) unrar x "${oup_path_Get}" "${targ_dir_Get}" || {
				Err "Failed to decompress rar file"
				return 1
			} ;;
			*.zst) zstd -d "${oup_path_Get}" -o "${targ_dir_Get}" || {
				Err "Failed to decompress zst file"
				return 1
			} ;;
			*) Txt "* Unrecognized file format, automatic decompression skipped" ;;
			esac
			[ $? -eq 0 ] && Txt "* File successfully decompressed to ${targ_dir_Get}"
		fi
		Txt "${CLR2}Done${CLR0}\n"
	else
		{
			Err "Download failed. Please check network connection and URL validity"
			return 1
		}
	fi
}
function Ask() {
	prompt_msg_Ask="$1"
	shift
	read -e -p "$(Txt "${prompt_msg_Ask}")" -r "$@" || {
		Err "Failed to read user input"
		return 1
	}
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
		Err "Failed to get network interface from /proc/net/dev"
		return 1
	}
	i=1
	while read -r interface_item_Iface; do
		[ -n "${interface_item_Iface}" ] && interfaces_Iface[$i]="${interface_item_Iface}"
		((i++))
	done <<<"${all_interfaces_Iface}"
	interfaces_num_Iface="${#interfaces_Iface[*]}"
	default4_route_Iface=$(ip -4 route show default 2>/dev/null | grep -A 3 "^default" || Txt)
	default6_route_Iface=$(ip -6 route show default 2>/dev/null | grep -A 3 "^default" || Txt)
	get_arr_item_idx_Iface() {
		item_Iface="$1"
		shift
		arr_Iface=("$@")
		for ((i = 1; i <= ${#arr_Iface[@]}; i++)); do
			if [ "${item_Iface}" = "${arr_Iface[$i]}" ]; then
				Txt "$i"
				return 0
			fi
		done
		return 255
	}
	interface4_Iface=""
	interface6_Iface=""
	for ((i = 1; i <= ${#interfaces_Iface[@]}; i++)); do
		item_Iface="${interfaces_Iface[$i]}"
		[ -z "${item_Iface}" ] && continue
		if [[ -n $default4_route_Iface && $default4_route_Iface == *"${item_Iface}"* ]] && [ -z "${interface4_Iface}" ]; then
			interface4_Iface="${item_Iface}"
			interface4_device_order_Iface=$(get_arr_item_idx_Iface "${item_Iface}" "${interfaces_Iface[@]}")
		fi
		if [[ -n $default6_route_Iface && $default6_route_Iface == *"${item_Iface}"* ]] && [ -z "${interface6_Iface}" ]; then
			interface6_Iface="${item_Iface}"
			interface6_device_order_Iface=$(get_arr_item_idx_Iface "${item_Iface}" "${interfaces_Iface[@]}")
		fi
		[ -n "${interface4_Iface}" ] && [ -n "${interface6_Iface}" ] && break
	done
	if [ -z "${interface4_Iface}" ] && [ -z "${interface6_Iface}" ]; then
		for ((i = 1; i <= ${#interfaces_Iface[@]}; i++)); do
			item_Iface="${interfaces_Iface[$i]}"
			if [[ ${item_Iface} =~ ^en ]]; then
				interface4_Iface="${item_Iface}"
				interface6_Iface="${item_Iface}"
				break
			fi
		done
		if [ -z "${interface4_Iface}" ] && [ -z "${interface6_Iface}" ] && [ "${interfaces_num_Iface}" -gt 0 ]; then
			interface4_Iface="${interfaces_Iface[1]}"
			interface6_Iface="${interfaces_Iface[1]}"
		fi
	fi
	if [ -n "${interface4_Iface}" ] || [ -n "${interface6_Iface}" ]; then
		interface_Iface="${interface4_Iface} ${interface6_Iface}"
		[[ ${interface4_Iface} == "${interface6_Iface}" ]] && interface_Iface="${interface4_Iface}"
		interface_Iface=$(Txt "${interface_Iface}" | tr -s ' ' | xargs)
	else
		physical_iface_Iface=$(ip -o link show | grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | grep 'state UP' | head -n 1 | awk -F': ' '{print $2}')
		if [ -n "${physical_iface_Iface}" ]; then
			interface_Iface="${physical_iface_Iface}"
		else
			interface_Iface=$(ip -o link show | grep -v 'lo:' | head -n 1 | awk -F': ' '{print $2}')
		fi
	fi
	case "$1" in
	--rx_bytes | --rx_packets | --rx_drop | --tx_bytes | --tx_packets | --tx_drop)
		for iface_Iface in ${interface_Iface}; do
			if stats_Iface=$(awk -v iface="${iface_Iface}" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes_Iface rx_packets_Iface rx_drop_Iface tx_bytes_Iface tx_packets_Iface tx_drop_Iface <<<"${stats_Iface}"
				case "$1" in
				--rx_bytes)
					Txt "${rx_bytes_Iface}"
					break
					;;
				--rx_packets)
					Txt "${rx_packets_Iface}"
					break
					;;
				--rx_drop)
					Txt "${rx_drop_Iface}"
					break
					;;
				--tx_bytes)
					Txt "${tx_bytes_Iface}"
					break
					;;
				--tx_packets)
					Txt "${tx_packets_Iface}"
					break
					;;
				--tx_drop)
					Txt "${tx_drop_Iface}"
					break
					;;
				esac
			fi
		done
		;;
	-i | --information)
		for iface_Iface in ${interface_Iface}; do
			if stats_Iface=$(awk -v iface="${iface_Iface}" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes_Iface rx_packets_Iface rx_drop_Iface tx_bytes_Iface tx_packets_Iface tx_drop_Iface <<<"${stats_Iface}"
				Txt "${iface_Iface}: In: $(ConvSz ${rx_bytes_Iface}), Out: $(ConvSz ${tx_bytes_Iface})"
			fi
		done
		;;
	*) Txt "${interface_Iface}" ;;
	esac
}
function IpAddr() {
	flg_IpAddr="$1"
	case "${flg_IpAddr}" in
	-4 | --ipv4)
		ipv4_addr_IpAddr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv4_addr_IpAddr}" ] && Txt "${ipv4_addr_IpAddr}" || {
			Err "Failed to get IPv4 address. Please check network connection"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "${ipv6_addr_IpAddr}" || {
			Err "Failed to get IPv6 address. Please check network connection"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "Failed to get IP address"
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
		data_LastUpd=$(awk '/End-Date:/ {print $2, $3, $4; exit}' /var/log/apt/history.log 2>/dev/null)
	elif [ -f /var/log/dpkg.log ]; then
		data_LastUpd=$(tail -n 1 /var/log/dpkg.log | awk '{print $1, $2}')
	elif command -v rpm &>/dev/null; then
		data_LastUpd=$(rpm -qa --last | head -n 1 | awk '{print $3, $4, $5, $6, $7}')
	fi
	[ -z "${data_LastUpd}" ] && {
		Err "Could not determine last system update time. Update log not found"
		return 1
	} || Txt "${data_LastUpd}"
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
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "Failed to get load average from uptime command"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
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
	case "$1" in
	--city)
		data_Loc=$(curl -s "ipinfo.io/city")
		;;
	--country | *)
		data_Loc=$(curl -s "ipinfo.io/country")
		;;
	esac
	[ -n "${data_Loc}" ] && Txt "${data_Loc}" || {
		Err "Could not detect geolocation. Please check network connection"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "${data_MacAddr}" || {
		Err "Could not get MAC address. Network interface not found"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "Failed to get memory usage statistics"
		return 1
	}
	tot_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || tot_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u | --used) Txt "${usd_MemUsage}" ;;
	-t | --total) Txt "${tot_MemUsage}" ;;
	-p | --percentage) Txt "${pct_MemUsage}" ;;
	*) Txt "$(ConvSz ${usd_MemUsage}) / $(ConvSz ${tot_MemUsage}) (${pct_MemUsage}%)" ;;
	esac
}
function NetProv() {
	data_NetProv=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${data_NetProv}" ] && Txt "${data_NetProv}" || {
		Err "Could not detect network provider. Please check network connection"
		return 1
	}
}
function PkgCnt() {
	case ${PKG_MGR} in
	apk) cnt_cmd_PkgCnt="apk info" ;;
	apt) cnt_cmd_PkgCnt="dpkg --get-selections" ;;
	opkg) cnt_cmd_PkgCnt="opkg list-installed" ;;
	pacman) cnt_cmd_PkgCnt="pacman -Q" ;;
	yum | dnf) cnt_cmd_PkgCnt="rpm -qa" ;;
	zypper) cnt_cmd_PkgCnt="zypper se --installed-only" ;;
	*) {
		Err "Could not calculate installed packages. Package manager not supported"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "Failed to count packages for ${PKG_MGR}"
			return 1
		}
	fi
	Txt "${data_PkgCnt}"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "Failed to get terminal width"
		return 1
	}
	bar_wid_Prog=$((term_wid_Prog - 23))
	stty -echo
	trap '' SIGINT SIGQUIT SIGTSTP
	for ((i = 0; i < num_cmds_Prog; i++)); do
		prog_Prog=$((i * 100 / num_cmds_Prog))
		fild_wid_Prog=$((prog_Prog * bar_wid_Prog / 100))
		printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "${prog_Prog}" "$(printf "%${fild_wid_Prog}s" | tr ' ' '#')" "$(printf "%$((bar_wid_Prog - fild_wid_Prog))s" | tr ' ' '.')"
		if ! cmd_oup_Prog=$(eval "${cmds[$i]}" 2>&1); then
			Txt "\n${cmd_oup_Prog}"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "Command execution failed: ${cmds[$i]}"
				return 1
			}
		fi
	done
	printf "\r\033[30;42mProgress: [100%%]\033[0m [%s]" "$(printf "%${bar_wid_Prog}s" | tr ' ' '#')"
	printf "\r%${term_wid_Prog}s\r"
	stty echo
	trap - SIGINT SIGQUIT SIGTSTP
}
function PubIp() {
	data_PubIp=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^ip=" | cut -d= -f2)
	[ -n "${data_PubIp}" ] && Txt "${data_PubIp}" || {
		Err "Could not detect public IP address. Please check network connection"
		return 1
	}
}
function Run() {
	cmds_Run=()
	# Add bash-completion &>/dev/null
	_run_completions() {
		curr_word_Run="${COMP_WORDS[COMP_CWORD]}"
		prev_word_Run="${COMP_WORDS[COMP_CWORD - 1]}"
		opts_word_Run="${cmds_Run[*]}"
		COMPREPLY=($(compgen -W "${opts_word_Run}" -- "${curr_word_Run}"))
		[[ ${#COMPREPLY[@]} -eq 0 ]] && COMPREPLY=($(compgen -c -- "${curr_word_Run}"))
	}
	complete -F _run_completions RUN
	[ $# -eq 0 ] && {
		Err "No command specified"
		return 2
	}
	if [[ $1 == *"/"* ]]; then
		if [[ $1 =~ ^https?:// ]]; then
			url_Run="$1"
			script_nm_Run=$(basename "$1")
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-d | --delete-after)
					rm_aftr_Run=true
					shift
					;;
				*) break ;;
				esac
			done
			Txt "${CLR3}Downloading and executing script from URL [${script_nm_Run}]${CLR0}"
			Task "* Downloading script" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "Failed to download script ${script_nm_Run}"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "Failed to set execute permission for script ${script_nm_Run}"; return 1; }
			"
			Txt "${CLR8}$(Linet = 24)${CLR0}"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "Failed to execute script ${script_nm_Run}"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "Failed to execute script ${script_nm_Run}"
					return 1
				}
			fi
			Txt "${CLR8}$(Linet = 24)${CLR0}"
			Txt "${CLR2}Done${CLR0}\n"
			[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
		elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner_Run=$(Txt "$1" | cut -d'/' -f1)
			repo_name_Run=$(Txt "$1" | cut -d'/' -f2)
			script_path_Run=$(Txt "$1" | cut -d'/' -f3-)
			script_nm_Run=$(basename "${script_path_Run}")
			branch_Run="main"
			dnload_repo_Run=false
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-b | --branch)
					[[ -z $2 || $2 == -* ]] && {
						Err "Branch name required after -b"
						return 2
					}
					branch_Run="$2"
					shift 2
					;;
				-d | --download)
					dnload_repo_Run=true
					shift
					;;
				-r | --remove)
					rm_aftr_Run=true
					shift
					;;
				*) break ;;
				esac
			done
			if [[ $dnload_repo_Run == true ]]; then
				Txt "${CLR3}Cloning repository ${repo_owner_Run}/${repo_name_Run}${CLR0}"
				[[ -d ${repo_name_Run} ]] && {
					Err "Directory ${repo_name_Run} already exists"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "* Cloning from branch ${branch_Run}" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "Failed to clone repository from branch ${branch_Run}"
							return 1
						}
					fi
				else
					Task "* Checking main branch" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "* Trying master branch" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "Failed to clone repository from main or master branch"
								return 1
							}
						fi
					fi
				fi
				Task "* Creating target directory" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "* Cleaning up temporary files" "rm -rf "${tmp_dir_Run}""
				Txt "Repository cloned to directory: ${CLR2}${repo_name_Run}"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "* Setting execute permissions" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "${CLR8}$(Linet = 24)${CLR0}"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "Failed to execute script ${script_nm_Run}"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "Failed to execute script ${script_nm_Run}"
							return 1
						}
					fi
					Txt "${CLR8}$(Linet = 24)${CLR0}"
					Txt "${CLR2}Done${CLR0}\n"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "${CLR3}Downloading and executing script from ${repo_owner_Run}/${repo_name_Run} [${script_nm_Run}]${CLR0}"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "* Checking branch ${branch_Run}" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "Script not found in branch ${branch_Run}"
						return 1
					}
				else
					Task "* Checking main branch" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "* Checking master branch" "
							branch_Run="master"
							github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/master/${script_path_Run}"
							curl -sLf "${github_url_Run}" >/dev/null
						"
						[ $? -ne 0 ] && {
							SCRIPTS
							return 1
						}
					fi
				fi
				Task "* Downloading script" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || {
						Err "Failed to download script ${script_nm_Run}"
						Err "Failed to download from ${github_url_Run}"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "Download failed: file not created"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "Downloaded file is empty"
						cat "${script_nm_Run}" 2>/dev/null || Txt "Could not display file content"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "Downloaded file contains only whitespace characters"
						return 1
					fi
					chmod +x "${script_nm_Run}" || {
						Err "Failed to set execute permission for script ${script_nm_Run}"
						Err "Failed to set execute permission for ${script_nm_Run}"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "${CLR8}$(Linet = 24)${CLR0}"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "Failed to execute script ${script_nm_Run}"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "Failed to execute script ${script_nm_Run}"
							return 1
						}
					fi
				else
					Err "Script file '${script_nm_Run}' not downloaded successfully"
					return 1
				fi
				Txt "${CLR8}$(Linet = 24)${CLR0}"
				Txt "${CLR2}Done${CLR0}\n"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "Failed to execute script ${script_nm_Run}"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "Failed to execute script ${script_nm_Run}"
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
	usd_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	tot_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u | --used) Txt "${usd_SwapUsage}" ;;
	-t | --total) Txt "${tot_SwapUsage}" ;;
	-p | --percentage) Txt "${pct_SwapUsage}" ;;
	*) Txt "$(ConvSz ${usd_SwapUsage}) / $(ConvSz ${tot_SwapUsage}) (${pct_SwapUsage}%)" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "${CLR3}Performing system cleanup...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
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
		Txt "* Repairing APK packages"
		apk fix || {
			Err "Failed to repair APK packages"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "* Waiting for dpkg lock"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "Timeout waiting for dpkg lock to be released"
				return 1
			}
		done
		Txt "* Setting pending packages"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "Failed to set pending packages"
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
		Txt "* Cleaning all pacman caches"
		pacman -Scc --noconfirm || {
			Err "Failed to clean all pacman caches"
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
		Txt "* Creating YUM cache"
		yum makecache || {
			Err "Failed to create YUM cache"
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
		Txt "* Creating DNF cache"
		dnf makecache || {
			Err "Failed to create DNF cache"
			return 1
		}
		;;
	*) {
		Err "Unsupported package manager. Skipping system-specific cleanup"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "* Rotating and cleaning journalctl logs" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "Failed to rotate and clean journalctl logs"
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
			pip) Task "* Clearing PIP cache" "pip cache purge" || {
				Err "Failed to clear PIP cache"
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
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}Done${CLR0}\n"
}
function SysInfo() {
	Txt "${CLR3}System Information${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "- Hostname:\t\t${CLR2}$(uname -n || hostname)${CLR0}"
	Txt "- Operating System:\t\t${CLR2}$(ChkOs)${CLR0}"
	Txt "- Kernel Version:\t\t${CLR2}$(uname -r)${CLR0}"
	Txt "- System Language:\t\t${CLR2}$LANG${CLR0}"
	Txt "- Shell Version:\t\t${CLR2}$(ShellVer)${CLR0}"
	Txt "- Last System Update:\t${CLR2}$(LastUpd)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Architecture:\t\t${CLR2}$(uname -m)${CLR0}"
	Txt "- CPU Model:\t\t${CLR2}$(CpuModel)${CLR0}"
	Txt "- CPU Cores:\t\t${CLR2}$(nproc)${CLR0}"
	Txt "- CPU Frequency:\t\t${CLR2}$(CpuFreq)${CLR0}"
	Txt "- CPU Usage:\t\t${CLR2}$(CpuUsage)%${CLR0}"
	Txt "- CPU Cache:\t\t${CLR2}$(CpuCache)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Memory Usage:\t\t${CLR2}$(MemUsage)${CLR0}"
	Txt "- SWAP Usage:\t\t${CLR2}$(SwapUsage)${CLR0}"
	Txt "- Disk Usage:\t\t${CLR2}$(DiskUsage)${CLR0}"
	Txt "- File System Type:\t${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- IPv4 Address:\t\t${CLR2}$(IpAddr --ipv4)${CLR0}"
	Txt "- IPv6 Address:\t\t${CLR2}$(IpAddr --ipv6)${CLR0}"
	Txt "- MAC Address:\t\t${CLR2}$(MacAddr)${CLR0}"
	Txt "- Network Provider:\t\t${CLR2}$(NetProv)${CLR0}"
	Txt "- DNS Servers:\t\t${CLR2}$(DnsAddr)${CLR0}"
	Txt "- Public IP:\t\t${CLR2}$(PubIp)${CLR0}"
	Txt "- Network Interface:\t\t${CLR2}$(Iface -i)${CLR0}"
	Txt "- Internal Timezone:\t\t${CLR2}$(TimeZn --internal)${CLR0}"
	Txt "- External Timezone:\t\t${CLR2}$(TimeZn --external)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Load Average:\t\t${CLR2}$(LoadAvg)${CLR0}"
	Txt "- Process Count:\t\t${CLR2}$(ps aux | wc -l)${CLR0}"
	Txt "- Installed Packages:\t\t${CLR2}$(PkgCnt)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Uptime:\t\t${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	Txt "- Boot Time:\t\t${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Virtualization:\t\t${CLR2}$(ChkVirt)${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
}
function SysOptz() {
	ChkRoot
	Txt "${CLR3}Optimizing system settings for long-running servers...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
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
	Task "* Disabling unnecessary services" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
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
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}Done${CLR0}\n"
}
function SysRboot() {
	ChkRoot
	Txt "${CLR3}Preparing to restart the system...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "Failed to get active user count"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "${CLR1}Warning: There are ${active_usrs_SysRboot} active users on the system${CLR0}\n"
		Txt "Active users: "
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "Failed to check running processes"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "${CLR1}Warning: ${important_procs_SysRboot} important processes are running${CLR0}\n"
		Txt "${CLR8}Top 5 CPU consuming processes:${CLR0}"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "Are you sure you want to restart the system immediately? (y/N) " -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "${CLR2}Restart cancelled${CLR0}\n"
		return 0
	}
	Task "* Performing final checks" "sync" || {
		Err "Failed to sync file systems"
		return 1
	}
	Task "* Initiating restart" "reboot || sudo reboot" || {
		Err "Failed to start restart"
		return 1
	}
	Txt "${CLR2}Restart command issued successfully. The system will restart immediately${CLR0}"
}
function SysUpd() {
	ChkRoot
	Txt "${CLR3}Updating system software...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="$1"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "* Updating package list"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "Failed to update package list using ${cmd_SysUpd_UpdPkg}"
			return 1
		}
		Txt "* Upgrading packages"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "Failed to upgrade packages using ${cmd_SysUpd_UpdPkg}"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "* Waiting for dpkg lock" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "Timeout waiting for dpkg lock to be released"
				return 1
			}
		done
		Task "* Setting pending packages" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "Failed to set pending packages"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "* Updating and upgrading packages" "pacman -Syu --noconfirm" || {
		Err "Failed to update and upgrade packages using pacman"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "Unsupported package manager"
		return 1
	} ;;
	esac
	Txt "* Updating ${SCRIPTS}"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "Failed to update ${SCRIPTS}"
		return 1
	}
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}Done${CLR0}\n"
}
function SysUpg() {
	ChkRoot
	Txt "${CLR3}Upgrading system to the next major release...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "* Detected 'Debian' system"
		Txt "* Updating package list"
		apt update -y || {
			Err "Failed to update package list using apt"
			return 1
		}
		Txt "* Upgrading current packages"
		apt full-upgrade -y || {
			Err "Failed to upgrade current packages"
			return 1
		}
		Txt "* Starting 'Debian' distribution upgrade..."
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "System is already on the latest stable release (${targ_codenm_SysUpg})"
			return 1
		}
		Txt "* Upgrading from ${CLR2}${curr_codenm_SysUpg}${CLR0} to ${CLR3}${targ_codenm_SysUpg}${CLR0}"
		Task "* Backing up sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "Failed to back up sources.list"
			return 1
		}
		Task "* Updating sources.list" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "Failed to update sources.list"
			return 1
		}
		Task "* Updating package list for new release" "apt update -y" || {
			Err "Failed to update package list for new release"
			return 1
		}
		Task "* Upgrading to new Debian release" "apt full-upgrade -y" || {
			Err "Failed to upgrade to new Debian release"
			return 1
		}
		;;
	Ubuntu)
		Txt "* Detected 'Ubuntu' system"
		Task "* Updating package list" "apt update -y" || {
			Err "Failed to update package list using apt"
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
		Err "Your system does not support major version upgrades yet"
		return 1
	} ;;
	esac
	Txt "${CLR8}$(Linet = 24)${CLR0}"
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
		Txt "${CLR1}Failed${CLR0} (${ret_Task})"
		[[ -s ${tmp_file_Task} ]] && Txt "${CLR1}$(cat ${tmp_file_Task})${CLR0}"
		[[ ${ign_err_Task} != "true" ]] && return "${ret_Task}"
	fi
	rm -f "${tmp_file_Task}"
	return "${ret_Task}"
}
function TimeZn() {
	case "$1" in
	-e | --external)
		data_TimeZn=$(timeout 1s curl -sL ipapi.co/timezone) ||
			data_TimeZn=$(timeout 1s curl -sL worldtimeapi.org/api/ip | grep -oP '"timezone":"\K[^"]+') ||
			data_TimeZn=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"timezone":"\K[^"]+') ||
			[ -n "${data_TimeZn}" ] && Txt "${data_TimeZn}" || {
			Err "Failed to detect timezone from external service"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${data_TimeZn}" ] && Txt "${data_TimeZn}" || {
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
