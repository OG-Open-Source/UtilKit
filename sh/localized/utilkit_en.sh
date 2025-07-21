#!/bin/bash

ANTHORS="OG-Open-Source"
SCRIPTS="UtilKit.sh"
VERSION="7.046.004"

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

function Txt() { echo -e "$1" "$2"; }
function Err() {
	[ -z "$1" ] && {
		Txt "${CLR1}Unknown error ${CLR0}"
		return 1
	}
	Txt "${CLR1}$1${CLR0}"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "$1" | tr -d '\n')"
		Txt "${log_entry_Err}" >>"${log_file_Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "No new items to be added were specified. Please provide at least one new project to be added"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "No archive or directory path was specified after -f or -d"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "No archive or directory path was specified after -f or -d"
		return 2
	}
	mod_Add="pkg"
	err_code_Add=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f)
			mod_Add="file"
			shift
			continue
			;;
		-d)
			mod_Add="dir"
			shift
			continue
			;;
		*.deb)
			ChkRoot
			deb_file_Add=$(basename "$1")
			Txt "${CLR3}install DEB kit [${deb_file_Add}]${CLR0}\\n"
			Get "$1"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "Installation of ${deb_file_Add} failed. Please check the kit compatibility and dependency\\n"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "Failed to fix dependency"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "* DEB suite ${deb_file_Add} installed successfully"
				rm -f "${deb_file_Add}"
				Txt "${CLR2}Complete ${CLR0}\\n"
			else
				Err "DEB suite ${deb_file_Add} not found or download failed\\n"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "${CLR3}New File [$1]${CLR0}"
				[ -d "$1" ] && {
					Err "Directory $1 already exists. Unable to create file of the same name\\n"
					err_code_Add=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "File $1 already exists\\n"
					err_code_Add=1
					shift
					continue
				}
				touch "$1" || {
					Err "File creation $1 failed. Please check permissions and disk space\\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* File $1 Created successfully"
				Txt "${CLR2}Complete ${CLR0}\\n"
				;;
			"dir")
				Txt "${CLR3}New directory [$1]${CLR0}"
				[ -f "$1" ] && {
					Err "File $1 already exists. Unable to create directory with the same name\\n"
					err_code_Add=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "Directory $1 already exists\\n"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "Creating directory $1 failed. Please check permissions and path validity\\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* Table of Contents $1 Created successfully"
				Txt "${CLR2}Complete ${CLR0}\\n"
				;;
			"pkg")
				Txt "${CLR3}Installation Kit [$1]${CLR0}"
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
						Txt "* Kit $1 Not installed yet"
						if inst_pkg_Add "$1"; then
							if is_instd_Add "$1"; then
								Txt "* Kit $1 Installed successfully"
								Txt "${CLR2}Complete ${CLR0}\\n"
							else
								Err "Installing $1 using ${PKG_MGR} failed\\n"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "Installing $1 using ${PKG_MGR} failed\\n"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "* Kit $1 installed"
						Txt "${CLR2}Complete ${CLR0}\\n"
					fi
					;;
				*)
					Err "Unsupported suite manager\\n"
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
		-i) mod_ChkDeps="interactive" ;;
		-a) mod_ChkDeps="auto" ;;
		*)
			Err "Invalid option: $1"
			return 1
			;;
		esac
		shift
	done
	for dep_ChkDeps in "${deps[@]}"; do
		if command -v "${dep_ChkDeps}" &>/dev/null; then
			status="${CLR2}［可用］${CLR0}"
		else
			status="${CLR1}［缺失］${CLR0}"
			missg_deps_ChkDeps+=("${dep_ChkDeps}")
		fi
		Txt "${status}\\t${dep_ChkDeps}"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "\\n${CLR3} Missing suite: ${CLR0} ${missg_deps_ChkDeps[*]}"
		Ask "Do you want to install the missing kit? (y/N)" -n 1 cont_inst_ChkDeps
		Txt
		[[ ${cont_inst_ChkDeps} =~ ^[Yy]$ ]] && Add "${missg_deps_ChkDeps[@]}"
		;;
	"auto")
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
				Err "Unknown release version"
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
				Err "Unknown releases"
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
				Err "Unknown releases"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "Please execute this script as root user"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "Unable to detect virtualized environments"
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
				Txt "Not detected (possibly physical machine)"
			fi
			;;
		*) Txt "${virt_typ_ChkVirt:-Not detected (possibly physical machine)}" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "Virtual Machine" || Txt "none")
	else
		virt_typ_ChkVirt="未知"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "Failed to switch directory"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "CPU information cannot be accessed. /proc/cpuinfo is not available"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "Unable to determine CPU cache size"
		return 1
	}
	Txt "${cpu_cache_CpuCache} KB"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "CPU information cannot be accessed. /proc/cpuinfo is not available"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "Unable to determine the CPU frequency"
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
		Err "Read CPU statistics from /proc/stat failed"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "Read CPU statistics from /proc/stat failed"
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
		Err "The size value to be converted is not provided"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-iB}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "Invalid size value. Must be numerical"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "The size value cannot be negative"
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
		Err "Unsupported units: ${unit_ConvSz}"
		return 2
	fi
}
function Copyright() {
	Txt "${SCRIPTS} ${VERSION}"
	Txt "Copyright (C) $(date +%Y) ${ANTHORS}."
}
function Del() {
	[ $# -eq 0 ] && {
		Err "The item to be deleted is not specified. Please provide at least one item to delete"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "No archive or directory path was specified after -f or -d"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "No archive or directory path was specified after -f or -d"
		return 2
	}
	mod_Del="pkg"
	err_code_Del=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f)
			mod_Del="file"
			shift
			continue
			;;
		-d)
			mod_Del="dir"
			shift
			continue
			;;
		*)
			case "${mod_Del}" in
			"file")
				Txt "${CLR3}Delete file [$1]${CLR0}"
				[ ! -f "$1" ] && {
					Err "File $1 does not exist\\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* File $1 exists"
				rm -f "$1" || {
					Err "Delete file $1 failed\\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* File $1 Delete successfully"
				Txt "${CLR2}Complete ${CLR0}\\n"
				;;
			"dir")
				Txt "${CLR3}Delete directory [$1]${CLR0}"
				[ ! -d "$1" ] && {
					Err "Directory $1 does not exist\\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* Directory $1 exists"
				rm -rf "$1" || {
					Err "Delete directory $1 failed\\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* Directory $1 Delete successfully"
				Txt "${CLR2}Complete ${CLR0}\\n"
				;;
			"pkg")
				Txt "${CLR3}Remove Kit [$1]${CLR0}"
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
						Txt "* Kit $1 does not exist"
						Txt "${CLR2}Complete ${CLR0}\\n"
					else
						if rm_pkg_Del "$1"; then
							if ! is_instd_Del "$1"; then
								Txt "* Kit $1 Removal successfully"
								Txt "${CLR2}Complete ${CLR0}\\n"
							else
								Err "Removing $1 failed with ${PKG_MGR}\\n"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "Removing $1 failed with ${PKG_MGR}\\n"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "Unsupported suite manager\\n"
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
		Err "Failed to obtain disk usage statistics"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "Failed to obtain total disk space"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) Txt "${usd_DiskUsage}" ;;
	-t) Txt "${tot_DiskUsage}" ;;
	-p) Txt "${pct_DiskUsage}" ;;
	*) Txt "$(ConvSz ${usd_DiskUsage}) / $(ConvSz ${tot_DiskUsage}) (${pct_DiskUsage}%)" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "DNS settings not found /etc/resolv.conf"
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
		Err "DNS server is not set in /etc/resolv.conf"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "IPv4 DNS server not found"
			return 1
		}
		Txt "${ipv4_servers_DnsAddr[*]}"
		;;
	-6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "IPv6 DNS server not found"
			return 1
		}
		Txt "${ipv6_servers_DnsAddr[*]}"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "DNS server not found"
			return 1
		}
		Txt "${ipv4_servers_DnsAddr[*]} ${ipv6_servers_DnsAddr[*]}"
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
		Err "Suite Manager Not Found or Not Supported"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "${CLR3}Search [${targ_Find}]${CLR0}"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "The result of ${targ_Find} cannot be found\\n"
			return 1
		}
		Txt "${CLR2}Complete ${CLR0}\\n"
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
		Err "The value to be formatted is not provided"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "No formatting options provided"
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
		-x)
			unzip_Get=true
			shift
			;;
		-r)
			[ -z "$2" ] || [[ $2 == -* ]] && {
				Err "The file name is not specified after the -r option"
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
		Err "Create directory ${targ_dir_Get} failed"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && oup_file_Get="${rnm_file_Get}"
	oup_path_Get="${targ_dir_Get}/${oup_file_Get}"
	url_Get=$(Txt "${url_Get}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR3}Download [${url_Get}]${CLR0}"
	file_sz_Get=$(curl -sI "${url_Get}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url_Get}" -O "${oup_path_Get}" || {
			Err "Failed to download archives using Wget"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url_Get}" -o "${oup_path_Get}" || {
			Err "Failed to download archives using cUrl"
			return 1
		}
	fi
	if [ -f "${oup_path_Get}" ]; then
		Txt "* The file was successfully downloaded to ${oup_path_Get}"
		if [ "${unzip_Get}" = true ]; then
			case "${oup_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Decompressing tar.gz file failed"
				return 1
			} ;;
			*.tar) tar -xf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Decompressing tar files failed"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Decompressing tar.bz2 file failed"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "Decompressing tar.xz file failed"
				return 1
			} ;;
			*.zip) unzip "${oup_path_Get}" -d "${targ_dir_Get}" || {
				Err "Unzip zip file failed"
				return 1
			} ;;
			*.7z) 7z x "${oup_path_Get}" -o"${targ_dir_Get}" || {
				Err "Unzip 7z file failed"
				return 1
			} ;;
			*.rar) unrar x "${oup_path_Get}" "${targ_dir_Get}" || {
				Err "Decompressing rar file failed"
				return 1
			} ;;
			*.zst) zstd -d "${oup_path_Get}" -o "${targ_dir_Get}" || {
				Err "Unzip zst file failed"
				return 1
			} ;;
			*) Txt "* Unrecognized file format, no automatic decompression" ;;
			esac
			[ $? -eq 0 ] && Txt "* The file was successfully decompressed to ${targ_dir_Get}"
		fi
		Txt "${CLR2}Complete ${CLR0}\\n"
	else
		{
			Err "Download failed. Please check the validity of network connections and URLs"
			return 1
		}
	fi
}
function Ask() {
	prompt_msg_Ask="$1"
	shift
	read -e -p "$prompt_msg_Ask" -r "$@" || {
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
		Err "Failed to get the network interface from /proc/net/dev"
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
	-i)
		for iface_Iface in ${interface_Iface}; do
			if stats_Iface=$(awk -v iface="${iface_Iface}" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes_Iface rx_packets_Iface rx_drop_Iface tx_bytes_Iface tx_packets_Iface tx_drop_Iface <<<"${stats_Iface}"
				Txt "${iface_Iface}: Input: $(ConvSz ${rx_bytes_Iface}), Output: $(ConvSz ${tx_bytes_Iface})"
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
			Err "Failed to obtain the IPv4 address. Please check the network connection"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "${ipv6_addr_IpAddr}" || {
			Err "Failed to obtain the IPv6 address. Please check the network connection"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "Failed to obtain IP address"
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
		Err "The last system update time cannot be determined. The update log cannot be found"
		return 1
	} || Txt "${data_LastUpd}"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "Failed to print lines"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "Failed to get load average from uptime instruction"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "Reading load average from /proc/loadavg failed"
			return 1
		}
	fi
	[[ ${zo_mi_LoadAvg} =~ ^[0-9.]+$ ]] || zo_mi_LoadAvg=0
	[[ ${zv_mi_LoadAvg} =~ ^[0-9.]+$ ]] || zv_mi_LoadAvg=0
	[[ ${ov_mi_LoadAvg} =~ ^[0-9.]+$ ]] || ov_mi_LoadAvg=0
	LC_ALL=C printf "%.2f, %.2f, %.2f (%d cores)" "${zo_mi_LoadAvg}" "${zv_mi_LoadAvg}" "${ov_mi_LoadAvg}" "$(nproc)"
}
function Loc() {
	data_Loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^loc=" | cut -d= -f2)
	[ -n "${data_Loc}" ] && Txt "${data_Loc}" || {
		Err "Unable to detect geographic location. Please check the network connection"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "${data_MacAddr}" || {
		Err "The MAC address cannot be obtained. The Internet interface cannot be found"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "Failed to obtain memory usage statistics"
		return 1
	}
	tot_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || tot_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) Txt "${usd_MemUsage}" ;;
	-t) Txt "${tot_MemUsage}" ;;
	-p) Txt "${pct_MemUsage}" ;;
	*) Txt "$(ConvSz ${usd_MemUsage}) / $(ConvSz ${tot_MemUsage}) (${pct_MemUsage}%)" ;;
	esac
}
function NetProv() {
	data_NetProv=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${data_NetProv}" ] && Txt "${data_NetProv}" || {
		Err "Unable to detect network suppliers. Please check the network connection"
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
		Err "Installed kits cannot be calculated. The software package manager does not support it"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "Failed to calculate the number of kits for ${PKG_MGR}"
			return 1
		}
	fi
	Txt "${data_PkgCnt}"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "Failed to obtain terminal width"
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
			Txt "\\n${cmd_oup_Prog}"
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
		Err "Public IP address cannot be detected. Please check the network connection"
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
				-d)
					rm_aftr_Run=true
					shift
					;;
				*) break ;;
				esac
			done
			Txt "${CLR3} is downloading and executing script from the URL [${script_nm_Run}]${CLR0}"
			Task "* Download script" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "Download script ${script_nm_Run} failed"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "Setting script ${script_nm_Run} failed to execute permission"; return 1; }
			"
			Txt "${CLR8}$(Linet = 24)${CLR0}"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "Execution script ${script_nm_Run} failed"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "Execution script ${script_nm_Run} failed"
					return 1
				}
			fi
			Txt "${CLR8}$(Linet = 24)${CLR0}"
			Txt "${CLR2}Complete ${CLR0}\\n"
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
						Err "-b requires branch name"
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
				Txt "${CLR3}Clone the repository ${repo_owner_Run}/${repo_name_Run}${CLR0}"
				[[ -d ${repo_name_Run} ]] && {
					Err "Directory ${repo_name_Run} already exists"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "*Clone from branch ${branch_Run}" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "Cloning repository from branch ${branch_Run} failed"
							return 1
						}
					fi
				else
					Task "* Check main branch" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "* Try the master branch" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "Cloning repository from main or master branch failed"
								return 1
							}
						fi
					fi
				fi
				Task "* Create a target directory" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "* Clean up temporary archives" "rm -rf "${tmp_dir_Run}""
				Txt "The repository has been cloned to the directory: ${CLR2}${repo_name_Run}"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "* Set execution permissions" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "${CLR8}$(Linet = 24)${CLR0}"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "Execution script ${script_nm_Run} failed"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "Execution script ${script_nm_Run} failed"
							return 1
						}
					fi
					Txt "${CLR8}$(Linet = 24)${CLR0}"
					Txt "${CLR2}Complete ${CLR0}\\n"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "${CLR3} is downloading and executing script from ${repo_owner_Run}/${repo_name_Run} [${script_nm_Run}]${CLR0}"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "* Check branch ${branch_Run}" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "Script not found in branch ${branch_Run}"
						return 1
					}
				else
					Task "* Check main branch" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "* Check the master branch" "
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
				Task "* Download script" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || {
						Err "Download script ${script_nm_Run} failed"
						Err "Download from ${github_url_Run} failed"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "Download failed: File not created"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "The downloaded file is empty"
						cat "${script_nm_Run}" 2>/dev/null || Txt "(The file content cannot be displayed)"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "The downloaded file contains only blank characters"
						return 1
					fi
					chmod +x "${script_nm_Run}" || {
						Err "Setting script ${script_nm_Run} failed to execute permission"
						Err "Unable to set execution permissions for ${script_nm_Run}"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "${CLR8}$(Linet = 24)${CLR0}"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "Execution script ${script_nm_Run} failed"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "Execution script ${script_nm_Run} failed"
							return 1
						}
					fi
				else
					Err "Script Archive '${script_nm_Run}' was not successfully downloaded"
					return 1
				fi
				Txt "${CLR8}$(Linet = 24)${CLR0}"
				Txt "${CLR2}Complete ${CLR0}\\n"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "Execution script ${script_nm_Run} failed"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "Execution script ${script_nm_Run} failed"
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
			Err "Not supported shell"
			return 1
		}
	fi
}
function SwapUsage() {
	usd_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	tot_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) Txt "${usd_SwapUsage}" ;;
	-t) Txt "${tot_SwapUsage}" ;;
	-p) Txt "${pct_SwapUsage}" ;;
	*) Txt "$(ConvSz ${usd_SwapUsage}) / $(ConvSz ${tot_SwapUsage}) (${pct_SwapUsage}%)" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "${CLR3}System cleaning is being performed...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "* Clean up APK cache"
		apk cache clean || {
			Err "Cleaning up APK cache failed"
			return 1
		}
		Txt "* Remove temporary archives"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "Failed to remove temporary archives"
			return 1
		}
		Txt "* Fix APK Suite"
		apk fix || {
			Err "Fix APK suite failure"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "* Wait for dpkg to lock"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "Wait for dpkg lock release timeout"
				return 1
			}
		done
		Txt "* Set up the pending kit"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "Failed to set up pending suite"
			return 1
		}
		Txt "* Automatic removal kit"
		apt autoremove --purge -y || {
			Err "Automatic kit removal failed"
			return 1
		}
		Txt "* Clean APT cache"
		apt clean -y || {
			Err "Cleaning APT cache failed"
			return 1
		}
		Txt "* Automatically clean APT cache"
		apt autoclean -y || {
			Err "Automatically clean up APT cache failed"
			return 1
		}
		;;
	*opkg)
		Txt "* Remove temporary archives"
		rm -rf /tmp/* || {
			Err "Failed to remove temporary archives"
			return 1
		}
		Txt "* Update OPKG"
		opkg update || {
			Err "Update OPKG failed"
			return 1
		}
		Txt "* Clean OPKG cache"
		opkg clean || {
			Err "Cleaning up OPKG cache failed"
			return 1
		}
		;;
	*pacman)
		Txt "* Update and upgrade kit"
		pacman -Syu --noconfirm || {
			Err "Update and upgrade suite using pacman failed"
			return 1
		}
		Txt "* Clean up pacman cache"
		pacman -Sc --noconfirm || {
			Err "Cleaning pacman cache failed"
			return 1
		}
		Txt "* Clean all pacman cache"
		pacman -Scc --noconfirm || {
			Err "Clean all pacman cache failed"
			return 1
		}
		;;
	*yum)
		Txt "* Automatic removal kit"
		yum autoremove -y || {
			Err "Automatic kit removal failed"
			return 1
		}
		Txt "* Clean up YUM cache"
		yum clean all || {
			Err "Cleaning YUM cache failed"
			return 1
		}
		Txt "* Create YUM cache"
		yum makecache || {
			Err "Failed to create YUM cache"
			return 1
		}
		;;
	*zypper)
		Txt "* Clean up Zypper cache"
		zypper clean --all || {
			Err "Cleaning up Zypper cache failed"
			return 1
		}
		Txt "* Reorganize the Zypper suite library"
		zypper refresh || {
			Err "Reorganizing the Zypper suite library failed"
			return 1
		}
		;;
	*dnf)
		Txt "* Automatic removal kit"
		dnf autoremove -y || {
			Err "Automatic kit removal failed"
			return 1
		}
		Txt "* Clean up DNF cache"
		dnf clean all || {
			Err "Cleaning DNF cache failed"
			return 1
		}
		Txt "* Create DNF cache"
		dnf makecache || {
			Err "DNF cache failed"
			return 1
		}
		;;
	*) {
		Err "Unsupported suite manager. Skip system-specific cleaning"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "* Rotate and clean journalctl logs" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "Rotate and clean up journalctl logs failed"
			return 1
		}
	fi
	Task "* Remove temporary archives" "rm -rf /tmp/*" || {
		Err "Failed to remove temporary archives"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "* Clean up the Docker system" "docker system prune -af" || {
				Err "Cleaning up Docker system failed"
				return 1
			} ;;
			npm) Task "* Clean up NPM cache" "npm cache clean --force" || {
				Err "Cleaning NPM cache failed"
				return 1
			} ;;
			pip) Task "* Clear PIP cache" "pip cache purge" || {
				Err "Clear PIP cache failed"
				return 1
			} ;;
			esac
		fi
	done
	Task "* Remove user cache file" "rm -rf ~/.cache/*" || {
		Err "Failed to remove user cache files"
		return 1
	}
	Task "* Remove thumbnail file" "rm -rf ~/.thumbnails/*" || {
		Err "Failed to remove the thumbnail file"
		return 1
	}
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}Complete ${CLR0}\\n"
}
function SysInfo() {
	Txt "${CLR3}System Information${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "- Host name: ${CLR2}$(uname -n || hostname)${CLR0}"
	Txt "- Operating system: ${CLR2}$(ChkOs)${CLR0}"
	Txt "- Core version: ${CLR2}$(uname -r)${CLR0}"
	Txt "- System language: ${CLR2}$LANG${CLR0}"
	Txt "- Shell version: ${CLR2}$(ShellVer)${CLR0}"
	Txt "- Last system update: ${CLR2}$(LastUpd)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Architecture: ${CLR2}$(uname -m)${CLR0}"
	Txt "- CPU Model: ${CLR2}$(CpuModel)${CLR0}"
	Txt "- Number of CPU cores: ${CLR2}$(nproc)${CLR0}"
	Txt "- CPU frequency: ${CLR2}$(CpuFreq)${CLR0}"
	Txt "- CPU usage: ${CLR2}$(CpuUsage)%${CLR0}"
	Txt "- CPU cache: ${CLR2}$(CpuCache)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Memory usage: ${CLR2}$(MemUsage)${CLR0}"
	Txt "- SWAP usage: ${CLR2}$(SwapUsage)${CLR0}"
	Txt "- Disk Usage: ${CLR2}$(DiskUsage)${CLR0}"
	Txt "- Archive system type: ${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- IPv4 address: ${CLR2}$(IpAddr --ipv4)${CLR0}"
	Txt "- IPv6 address: ${CLR2}$(IpAddr --ipv6)${CLR0}"
	Txt "- MAC address: ${CLR2}$(MacAddr)${CLR0}"
	Txt "- Network supplier: ${CLR2}$(NetProv)${CLR0}"
	Txt "- DNS server: ${CLR2}$(DnsAddr)${CLR0}"
	Txt "- Public IP: ${CLR2}$(PubIp)${CLR0}"
	Txt "- Network interface: ${CLR2}$(Iface -i)${CLR0}"
	Txt "- Internal time zone: ${CLR2}$(TimeZn --internal)${CLR0}"
	Txt "- External time zone: ${CLR2}$(TimeZn --external)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Load Average: ${CLR2}$(LoadAvg)${CLR0}"
	Txt "- Number of programs: ${CLR2}$(ps aux | wc -l)${CLR0}"
	Txt "- Installed kit: ${CLR2}$(PkgCnt)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Runtime: ${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	Txt "- Start time: ${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"
	Txt "- Virtualization: ${CLR2}$(ChkVirt)${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
}
function SysOptz() {
	ChkRoot
	Txt "${CLR3} is optimizing system settings for long-term servers...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "# Server optimization for long-term running systems" >"${sysctl_conf_SysOptimize}"
	Task "* Memory management is being optimized" "
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
	Task "* TCP buffer is being optimized" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "Optimizing TCP buffer failed"
		return 1
	}
	Task "* Optimizing the file system settings" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "Failed to optimize the file system settings"
		return 1
	}
	Task "* Optimizing system restrictions" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "Optimization system restrictions failed"
		return 1
	}
	Task "* I/O Scheduler Is Optimizing" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "Optimization of I/O Scheduler Failed"
		return 1
	}
	Task "* Disable non-essential services" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
		Err "Failed to deactivate service"
		return 1
	}
	Task "* Apply system parameters" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "Failed to apply system parameters"
		return 1
	}
	Task "* Clear system cache" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "Clear system cache failed"
		return 1
	}
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}Complete ${CLR0}\\n"
}
function SysRboot() {
	ChkRoot
	Txt "${CLR3} is preparing to restart the system...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "Failed to obtain the number of users of the event"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "${CLR1}Warning: Currently the system has ${active_usrs_SysRboot} active users ${CLR0}\\n"
		Txt "Activity User:"
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "Checking for execution of programs failed"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "${CLR1}Warning: There are ${important_procs_SysRboot} important programs that are executing ${CLR0}\\n"
		Txt "${CLR8}The 5 programs with the highest CPU usage: ${CLR0}"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "Are you sure you want to restart the system immediately? (y/N)" -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "${CLR2}Restarted ${CLR0}\\n"
		return 0
	}
	Task "* Perform a final check" "sync" || {
		Err "Synchronization of archive system failed"
		return 1
	}
	Task "* Start restarting" "reboot || sudo reboot" || {
		Err "Starting and restarting failed"
		return 1
	}
	Txt "${CLR2} has successfully issued a restart command. The system will restart ${CLR0} immediately"
}
function SysUpd() {
	ChkRoot
	Txt "${CLR3} is updating the system software...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="$1"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "* Updated kit list"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "Updated suite inventory using ${cmd_SysUpd_UpdPkg} failed"
			return 1
		}
		Txt "* Upgrading the kit"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "Upgrading the suite failed with ${cmd_SysUpd_UpdPkg}"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "* Wait for dpkg to lock" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "Wait for dpkg lock release timeout"
				return 1
			}
		done
		Task "* Set up the pending kit" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "Failed to set up pending kits"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "* Update and upgrade kit" "pacman -Syu --noconfirm" || {
		Err "Update and upgrade suite using pacman failed"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "Unsupported suite manager"
		return 1
	} ;;
	esac
	Txt "* Updated ${SCRIPTS}"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "Update ${SCRIPTS} failed"
		return 1
	}
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}Complete ${CLR0}\\n"
}
function SysUpg() {
	ChkRoot
	Txt "${CLR3} is upgrading the system to the next major version...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "* 'Debian' system detected"
		Txt "* Updated kit list"
		apt update -y || {
			Err "Failed to update the suite manifest using apt"
			return 1
		}
		Txt "* Upgrading the current kit"
		apt full-upgrade -y || {
			Err "Upgrading the current suite failed"
			return 1
		}
		Txt "* Start the 'Debian' distribution upgrade..."
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "The system is already the latest stable version (${targ_codenm_SysUpg})"
			return 1
		}
		Txt "* Upgrading from ${CLR2}${curr_codenm_SysUpg}${CLR0} to ${CLR3}${targ_codenm_SysUpg}${CLR0}"
		Task "* Backup sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "Backup sources.list failed"
			return 1
		}
		Task "* Update sources.list" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "Update sources.list failed"
			return 1
		}
		Task "* Updated new version of the suite list" "apt update -y" || {
			Err "Updated new version of the suite list failed"
			return 1
		}
		Task "* Upgrade to a new Debian version" "apt full-upgrade -y" || {
			Err "Upgrading to a new Debian version failed"
			return 1
		}
		;;
	Ubuntu)
		Txt "* 'Ubuntu' system detected"
		Task "* Updated kit list" "apt update -y" || {
			Err "Failed to update the suite manifest using apt"
			return 1
		}
		Task "* Upgrading the current kit" "apt full-upgrade -y" || {
			Err "Upgrading the current suite failed"
			return 1
		}
		Task "* Install update-manager-core" "apt install -y update-manager-core" || {
			Err "Install update-manager-core failed"
			return 1
		}
		Task "* Upgrade Ubuntu version" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "Ubuntu version upgrade failed"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "Your system does not support major version upgrades"
		return 1
	} ;;
	esac
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2} system upgrade completed ${CLR0}\\n"
}
function Task() {
	msg_Task="$1"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "${CLR2}Complete ${CLR0}"
		ret_Task=0
	else
		ret_Task=$?
		Txt "${CLR1} failed ${CLR0} (${ret_Task})"
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
			Err "Detecting time zone from external service failed"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${data_TimeZn}" ] && Txt "${data_TimeZn}" || {
			Err "Detecting system time zone failed"
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
