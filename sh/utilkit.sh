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
		Txt "*#CKM2np#*"
		return 1
	}
	Txt "*#kh2GBR#*"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "*#apWq1A#*" | tr -d '\n')"
		Txt "*#OuEwFs#*" >>"${log_file_Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "*#sIIDw0#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#HEQaH9#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "*#UNFK9J#*"
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
			Txt "*#08o2zM#*"
			Get "$1"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "*#XdkC4e#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "*#4USZKC#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#mc6bnI#*"
				rm -f "${deb_file_Add}"
				Txt "*#y8w45K#*"
			else
				Err "*#L806q1#*"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "*#mUoDJk#*"
				[ -d "$1" ] && {
					Err "*#PY8KHy#*"
					err_code_Add=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "*#v48iMv#*"
					err_code_Add=1
					shift
					continue
				}
				touch "$1" || {
					Err "*#Kb9eJD#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#7EFfl6#*"
				Txt "*#swO9oa#*"
				;;
			"dir")
				Txt "*#hHsV8k#*"
				[ -f "$1" ] && {
					Err "*#PGSHBP#*"
					err_code_Add=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "*#17MXlt#*"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "*#2R6Rn7#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#YgAKwa#*"
				Txt "*#JN9vwQ#*"
				;;
			"pkg")
				Txt "*#j4Y9UV#*"
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
						Txt "*#ef2tb2#*"
						if inst_pkg_Add "$1"; then
							if is_instd_Add "$1"; then
								Txt "*#LRbRnx#*"
								Txt "*#RvN4b8#*"
							else
								Err "*#KBtCvX#*"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "*#2wVRrx#*"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "*#9QkH8q#*"
						Txt "*#dBjuRf#*"
					fi
					;;
				*)
					Err "*#3PQHIb#*"
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
			Err "*#awyznG#*"
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
		Txt "*#l8D8AL#*"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "*#l9cxsu#*"
		Ask "*#CWUp9E#*" -n 1 cont_inst_ChkDeps
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
			[ "${ID}" = "debian" ] && cat /etc/debian_version || Txt "*#16aDEs#*"
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
				Err "*#VDGovN#*"
				return 1
			}
		fi
		;;
	-n | --name)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			Txt "*#sOTQzm#*" | sed 's/.*/\u&/'
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2 | awk '{print $1}'
		else
			{
				Err "*#6PijVf#*"
				return 1
			}
		fi
		;;
	*)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "${ID}" = "debian" ] && Txt "*#GlZH5s#*" || Txt "*#AnlC3p#*"
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
		else
			{
				Err "*#7VDpLd#*"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "*#vupTTp#*"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "*#Ij8Ubz#*"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "*#27P3sw#*" || Txt "*#7la3wz#*" ;;
		microsoft) Txt "*#AgxU76#*" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "*#28hJHU#*"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "*#DFiame#*"
			else
				Txt "*#9qfS5c#*"
			fi
			;;
		*) Txt "*#SbHHBg#*" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "*#d7VUch#*" || Txt "*#lD55wb#*")
	else
		virt_typ_ChkVirt="未知"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "*#Pxd2nZ#*"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#ASY6iW#*"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "*#B7msiU#*"
		return 1
	}
	Txt "*#Z3aFnC#*"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#EFe3TF#*"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "*#jGcDZR#*"
		return 1
	}
	Txt "*#fR7H08#*"
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
			Txt "*#Xs267E#*"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#ehf4tY#*"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#qCTN3O#*"
		return 1
	}
	curr_tot_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	curr_idle_CpuUsage=${idle_CpuUsage}
	tot_delta_CpuUsage=$((curr_tot_CpuUsage - prev_total_CpuUsage))
	idle_delta_CpuUsage=$((curr_idle_CpuUsage - prev_idle_CpuUsage))
	cpu_usage_CpuUsage=$((100 * (tot_delta_CpuUsage - idle_delta_CpuUsage) / tot_delta_CpuUsage))
	Txt "*#Orgd0t#*"
}
function ConvSz() {
	[ -z "$1" ] && {
		Err "*#zkoQeq#*"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-iB}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "*#O5nUTU#*"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "*#q1HIp9#*"
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
		Err "*#vz44GW#*"
		return 2
	fi
}
function Copyright() {
	Txt "*#AbSUiB#*"
	Txt "*#lLrh32#*"
}
function Del() {
	[ $# -eq 0 ] && {
		Err "*#GfKLHJ#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#i0RVu2#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "*#hM9dXE#*"
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
				Txt "*#zi4KMg#*"
				[ ! -f "$1" ] && {
					Err "*#vy0IiV#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#m9Bjv7#*"
				rm -f "$1" || {
					Err "*#gSTMpk#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#ZoaCAa#*"
				Txt "*#ntQFxp#*"
				;;
			"dir")
				Txt "*#jVQGxa#*"
				[ ! -d "$1" ] && {
					Err "*#41hEQP#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#UrTmp1#*"
				rm -rf "$1" || {
					Err "*#wWGyd2#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#JlARDO#*"
				Txt "*#9c17xQ#*"
				;;
			"pkg")
				Txt "*#3t2R8a#*"
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
						Txt "*#cVQ8EG#*"
						Txt "*#XfcRPK#*"
					else
						if rm_pkg_Del "$1"; then
							if ! is_instd_Del "$1"; then
								Txt "*#ZvjYrz#*"
								Txt "*#TNHOvk#*"
							else
								Err "*#Itw5Da#*"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "*#w2hSFT#*"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "*#Ba7cU5#*"
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
		Err "*#Xgvbph#*"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "*#Hk77iX#*"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) Txt "*#3btRnj#*" ;;
	-t) Txt "*#LrEcgr#*" ;;
	-p) Txt "*#3NUAP6#*" ;;
	*) Txt "*#iUz8gL#*" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "*#0oHLgZ#*"
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
		Err "*#QpWEZR#*"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#Ciinwp#*"
			return 1
		}
		Txt "*#AFfYIi#*"
		;;
	-6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#W5ejv3#*"
			return 1
		}
		Txt "*#mN7daQ#*"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#qdeedU#*"
			return 1
		}
		Txt "*#C9ifpE#*"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "*#nyuvEi#*"
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
		Err "*#2fjezl#*"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "*#BmDONB#*"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "*#R3F4uv#*"
			return 1
		}
		Txt "*#NAQ6Gu#*"
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
	Txt "*#ISWsxk#*"
}
function Format() {
	flg_Format="$1"
	val_Format="$2"
	res_Format=""
	[ -z "${val_Format}" ] && {
		Err "*#EPtJyp#*"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "*#t2W78a#*"
		return 2
	}
	case "${flg_Format}" in
	-AA) res_Format=$(Txt "*#KUrgYo#*" | tr '[:lower:]' '[:upper:]') ;;
	-aa) res_Format=$(Txt "*#NSMlLd#*" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) res_Format=$(Txt "*#dbY6gI#*" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) res_Format="${val_Format}" ;;
	esac
	Txt "*#G4DeR3#*"
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
				Err "*#eyItiI#*"
				return 2
			}
			rnm_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "*#VU4rO8#*"
			return 2
		} ;;
		*)
			[ -z "${url_Get}" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "${url_Get}" ] && {
		Err "*#Hx4qeB#*"
		return 2
	}
	[[ ${url_Get} =~ ^(http|https|ftp):// ]] || url_Get="https://${url_Get}"
	oup_file_Get="${url_Get##*/}"
	[ -z "${oup_file_Get}" ] && oup_file_Get="index.html"
	[ "${targ_dir_Get}" != "." ] && { mkdir -p "${targ_dir_Get}" || {
		Err "*#EEPCJZ#*"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && oup_file_Get="${rnm_file_Get}"
	oup_path_Get="${targ_dir_Get}/${oup_file_Get}"
	url_Get=$(Txt "*#6oLFLk#*" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "*#nJRCUq#*"
	file_sz_Get=$(curl -sI "${url_Get}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url_Get}" -O "${oup_path_Get}" || {
			Err "*#3WDSfy#*"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url_Get}" -o "${oup_path_Get}" || {
			Err "*#zafpVo#*"
			return 1
		}
	fi
	if [ -f "${oup_path_Get}" ]; then
		Txt "*#mw5iCq#*"
		if [ "${unzip_Get}" = true ]; then
			case "${oup_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#UaAe4n#*"
				return 1
			} ;;
			*.tar) tar -xf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#uZuxR5#*"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#jYUEYN#*"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#iQC5Lz#*"
				return 1
			} ;;
			*.zip) unzip "${oup_path_Get}" -d "${targ_dir_Get}" || {
				Err "*#jhxsYy#*"
				return 1
			} ;;
			*.7z) 7z x "${oup_path_Get}" -o"${targ_dir_Get}" || {
				Err "*#SNvyht#*"
				return 1
			} ;;
			*.rar) unrar x "${oup_path_Get}" "${targ_dir_Get}" || {
				Err "*#HMxkn6#*"
				return 1
			} ;;
			*.zst) zstd -d "${oup_path_Get}" -o "${targ_dir_Get}" || {
				Err "*#rGn5ZH#*"
				return 1
			} ;;
			*) Txt "*#NCpVKR#*" ;;
			esac
			[ $? -eq 0 ] && Txt "*#1IW1zZ#*"
		fi
		Txt "*#deyCeh#*"
	else
		{
			Err "*#KyRlnI#*"
			return 1
		}
	fi
}
function Ask() {
	prompt_msg_Ask="$1"
	shift
	read -e -p "$prompt_msg_Ask" -r "$@" || {
		Err "*#8Ek1Sk#*"
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
		Err "*#uGqari#*"
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
				Txt "*#0CgGEs#*"
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
		interface_Iface=$(Txt "*#dG4rlH#*" | tr -s ' ' | xargs)
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
					Txt "*#PWFHj6#*"
					break
					;;
				--rx_packets)
					Txt "*#UKjKLE#*"
					break
					;;
				--rx_drop)
					Txt "*#o2DzjZ#*"
					break
					;;
				--tx_bytes)
					Txt "*#zcX7wa#*"
					break
					;;
				--tx_packets)
					Txt "*#B4fyvo#*"
					break
					;;
				--tx_drop)
					Txt "*#dmatXt#*"
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
				Txt "*#ARrfKr#*"
			fi
		done
		;;
	*) Txt "*#xl8Czf#*" ;;
	esac
}
function IpAddr() {
	flg_IpAddr="$1"
	case "${flg_IpAddr}" in
	-4 | --ipv4)
		ipv4_addr_IpAddr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv4_addr_IpAddr}" ] && Txt "*#2hF2LX#*" || {
			Err "*#CwZ4OB#*"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "*#lNsEhb#*" || {
			Err "*#F2fRZW#*"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "*#8HhTcY#*"
			return 1
		}
		[ -n "${ipv4_addr_IpAddr}" ] && Txt "*#sKSu6f#*"
		[ -n "${ipv6_addr_IpAddr}" ] && Txt "*#87pHx8#*"
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
		Err "*#nRtwon#*"
		return 1
	} || Txt "*#zpl4ON#*"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "*#jbv00y#*"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "*#gfZ35q#*"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "*#6r6DSE#*"
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
	[ -n "${data_Loc}" ] && Txt "*#iaRv25#*" || {
		Err "*#4ZAK4Q#*"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "*#QCHWOh#*" || {
		Err "*#ZxYUix#*"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "*#VzwFa9#*"
		return 1
	}
	tot_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || tot_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) Txt "*#Snb6hx#*" ;;
	-t) Txt "*#H3uNYN#*" ;;
	-p) Txt "*#3uND7u#*" ;;
	*) Txt "*#RFNNWV#*" ;;
	esac
}
function NetProv() {
	data_NetProv=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${data_NetProv}" ] && Txt "*#7u4iHn#*" || {
		Err "*#xgUnIj#*"
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
		Err "*#HlgQ9F#*"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "*#lt3H7S#*"
			return 1
		}
	fi
	Txt "*#3yRgva#*"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "*#lBWpyQ#*"
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
			Txt "*#mOEOdb#*"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "*#bqQMR0#*"
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
	[ -n "${data_PubIp}" ] && Txt "*#mxVlS1#*" || {
		Err "*#SLgR2S#*"
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
		Err "*#w1zrou#*"
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
			Txt "*#3A1xLg#*"
			Task "*#t1ECem#*" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "*#92nhWx#*"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "*#jIqFSX#*"; return 1; }
			"
			Txt "*#Y5dnRi#*"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "*#ZmpEHD#*"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "*#2Z9hdi#*"
					return 1
				}
			fi
			Txt "*#SHyRbs#*"
			Txt "*#KAuAgI#*"
			[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
		elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner_Run=$(Txt "*#Em3qhU#*" | cut -d'/' -f1)
			repo_name_Run=$(Txt "*#z2PGBY#*" | cut -d'/' -f2)
			script_path_Run=$(Txt "*#3s2UX7#*" | cut -d'/' -f3-)
			script_nm_Run=$(basename "${script_path_Run}")
			branch_Run="main"
			dnload_repo_Run=false
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-b | --branch)
					[[ -z $2 || $2 == -* ]] && {
						Err "*#6Ikae5#*"
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
				Txt "*#4hTsFr#*"
				[[ -d ${repo_name_Run} ]] && {
					Err "*#CMPCSY#*"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#SqKgnE#*" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "*#IH7qe3#*"
							return 1
						}
					fi
				else
					Task "*#6QsFk4#*" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "*#G2jWPF#*" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "*#k455Fu#*"
								return 1
							}
						fi
					fi
				fi
				Task "*#MDd6FU#*" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "*#RifH42#*" "rm -rf "${tmp_dir_Run}""
				Txt "*#5DHq4l#*"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "*#Mv1dTH#*" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "*#x6AJDp#*"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "*#O7rYnt#*"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "*#ESpq0m#*"
							return 1
						}
					fi
					Txt "*#pUPT5c#*"
					Txt "*#XouSV4#*"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "*#SYTxCD#*"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#oWDllg#*" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "*#gvnTC8#*"
						return 1
					}
				else
					Task "*#ctZBdE#*" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "*#HQFImC#*" "
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
				Task "*#a7pxap#*" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || {
						Err "*#ro2ig3#*"
						Err "*#BuhkT7#*"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "*#Z0dTRw#*"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "*#O7PBmu#*"
						cat "${script_nm_Run}" 2>/dev/null || Txt "*#ZpWGh0#*"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "*#oftY7w#*"
						return 1
					fi
					chmod +x "${script_nm_Run}" || {
						Err "*#VtSExW#*"
						Err "*#KEL9Zo#*"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "*#DXmsQO#*"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "*#49ht6U#*"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "*#nR5UC9#*"
							return 1
						}
					fi
				else
					Err "*#QdsHS5#*"
					return 1
				fi
				Txt "*#aAdpRn#*"
				Txt "*#APUY8o#*"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "*#Z78gAZ#*"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "*#XWX4kh#*"
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
		Txt "*#GlahQh#*"
	elif [ -n "${ZSH_VERSION-}" ]; then
		Txt "*#gsgHk7#*"
	else
		{
			Err "*#n50EPO#*"
			return 1
		}
	fi
}
function SwapUsage() {
	usd_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	tot_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) Txt "*#1OEOJD#*" ;;
	-t) Txt "*#xOGGlF#*" ;;
	-p) Txt "*#EufSN9#*" ;;
	*) Txt "*#QjomZf#*" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "*#bZ5i9l#*"
	Txt "*#drcHMW#*"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "*#hymAKl#*"
		apk cache clean || {
			Err "*#hZLmFB#*"
			return 1
		}
		Txt "*#KS2dEt#*"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "*#U1QdqK#*"
			return 1
		}
		Txt "*#0nMJXP#*"
		apk fix || {
			Err "*#0I2WZ2#*"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "*#WIaAhE#*"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "*#hRRmKG#*"
				return 1
			}
		done
		Txt "*#AAFW4q#*"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "*#PqrENk#*"
			return 1
		}
		Txt "*#eTvn1E#*"
		apt autoremove --purge -y || {
			Err "*#Jf4avK#*"
			return 1
		}
		Txt "*#xGyrlU#*"
		apt clean -y || {
			Err "*#bJtU29#*"
			return 1
		}
		Txt "*#FD6aCT#*"
		apt autoclean -y || {
			Err "*#Pvw3nk#*"
			return 1
		}
		;;
	*opkg)
		Txt "*#MyRa9F#*"
		rm -rf /tmp/* || {
			Err "*#LkSpQU#*"
			return 1
		}
		Txt "*#XaQ6w3#*"
		opkg update || {
			Err "*#dTsLxZ#*"
			return 1
		}
		Txt "*#HXtt27#*"
		opkg clean || {
			Err "*#43Oeo0#*"
			return 1
		}
		;;
	*pacman)
		Txt "*#0uN5YG#*"
		pacman -Syu --noconfirm || {
			Err "*#ziKUAN#*"
			return 1
		}
		Txt "*#LsIEvU#*"
		pacman -Sc --noconfirm || {
			Err "*#AYQqic#*"
			return 1
		}
		Txt "*#joVW2A#*"
		pacman -Scc --noconfirm || {
			Err "*#w6Fmnw#*"
			return 1
		}
		;;
	*yum)
		Txt "*#q5Kag9#*"
		yum autoremove -y || {
			Err "*#0tvo98#*"
			return 1
		}
		Txt "*#PRVl7H#*"
		yum clean all || {
			Err "*#O15mBu#*"
			return 1
		}
		Txt "*#8IOWK6#*"
		yum makecache || {
			Err "*#rRhfAT#*"
			return 1
		}
		;;
	*zypper)
		Txt "*#Uv9bF4#*"
		zypper clean --all || {
			Err "*#OMG6LA#*"
			return 1
		}
		Txt "*#SXuTx4#*"
		zypper refresh || {
			Err "*#9Od7iR#*"
			return 1
		}
		;;
	*dnf)
		Txt "*#BQugG8#*"
		dnf autoremove -y || {
			Err "*#zUiyGz#*"
			return 1
		}
		Txt "*#vUG0Vz#*"
		dnf clean all || {
			Err "*#LLU2kL#*"
			return 1
		}
		Txt "*#di5WkU#*"
		dnf makecache || {
			Err "*#IiJR1m#*"
			return 1
		}
		;;
	*) {
		Err "*#zHoWRD#*"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "*#qU7OOm#*" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "*#1IDj6s#*"
			return 1
		}
	fi
	Task "*#CH0KGE#*" "rm -rf /tmp/*" || {
		Err "*#5w52iu#*"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "*#EJzFXx#*" "docker system prune -af" || {
				Err "*#4qtEDz#*"
				return 1
			} ;;
			npm) Task "*#1uBTeD#*" "npm cache clean --force" || {
				Err "*#5zySc3#*"
				return 1
			} ;;
			pip) Task "*#b8AjAP#*" "pip cache purge" || {
				Err "*#ev9UBI#*"
				return 1
			} ;;
			esac
		fi
	done
	Task "*#awzpKg#*" "rm -rf ~/.cache/*" || {
		Err "*#D9fMiX#*"
		return 1
	}
	Task "*#t8rosH#*" "rm -rf ~/.thumbnails/*" || {
		Err "*#j4Jjvd#*"
		return 1
	}
	Txt "*#hpTLzP#*"
	Txt "*#1aGs5e#*"
}
function SysInfo() {
	Txt "*#qG13J9#*"
	Txt "*#cofTyr#*"
	Txt "*#sKvxhI#*"
	Txt "*#Q9tHVR#*"
	Txt "*#A7IVEY#*"
	Txt "*#cuKcxA#*"
	Txt "*#vjJatv#*"
	Txt "*#YiRyZw#*"
	Txt "*#hUUzxo#*"
	Txt "*#T0jJLj#*"
	Txt "*#Y0qBdx#*"
	Txt "*#g3R9eG#*"
	Txt "*#KV7erj#*"
	Txt "*#nDxFWC#*"
	Txt "*#A40OCR#*"
	Txt "*#qvos9N#*"
	Txt "*#zdHQYZ#*"
	Txt "*#KQDvE9#*"
	Txt "*#0vDy8Y#*"
	Txt "*#XqpWp9#*"
	Txt "*#lbEGpJ#*"
	Txt "*#GcRK0Q#*"
	Txt "*#BIlcwB#*"
	Txt "*#YQCaPo#*"
	Txt "*#VS1dQA#*"
	Txt "*#9PhIYd#*"
	Txt "*#ijDpaH#*"
	Txt "*#2x8Fuo#*"
	Txt "*#tVgEgo#*"
	Txt "*#NIkked#*"
	Txt "*#Gfcz0Q#*"
	Txt "*#zehaVc#*"
	Txt "*#4FUO4X#*"
	Txt "*#CSDGsL#*"
	Txt "*#mMPCAI#*"
	Txt "*#M8dkPC#*"
	Txt "*#stsr3y#*"
	Txt "*#GmA4Me#*"
	Txt "*#nId7UE#*"
	Txt "*#ajfHwV#*"
}
function SysOptz() {
	ChkRoot
	Txt "*#AcVxna#*"
	Txt "*#7MZ3CT#*"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "*#xpVodD#*" >"${sysctl_conf_SysOptimize}"
	Task "*#Y1EKQQ#*" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#ch7vN3#*"
		return 1
	}
	Task "*#gwlGdt#*" "
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
		Err "*#iaQVs1#*"
		return 1
	}
	Task "*#YZEE8d#*" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#IhGvzt#*"
		return 1
	}
	Task "*#KhzUXf#*" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#XrBnfw#*"
		return 1
	}
	Task "*#GnRwaP#*" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "*#JuU6lM#*"
		return 1
	}
	Task "*#XQ0vTk#*" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "*#B2GNIJ#*"
		return 1
	}
	Task "*#1khHRs#*" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
		Err "*#IuPHCl#*"
		return 1
	}
	Task "*#ufVG47#*" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "*#RBJU0i#*"
		return 1
	}
	Task "*#0lLkhG#*" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "*#y6LUTG#*"
		return 1
	}
	Txt "*#dAkII7#*"
	Txt "*#riLJjg#*"
}
function SysRboot() {
	ChkRoot
	Txt "*#McM2zb#*"
	Txt "*#0Lkwt4#*"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "*#WM6WQQ#*"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "*#KYYEcH#*"
		Txt "*#cUjqpA#*"
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "*#ICtZeg#*"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "*#8mn6Yh#*"
		Txt "*#xpF3aY#*"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "*#gmz8wB#*" -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "*#WCRHvk#*"
		return 0
	}
	Task "*#tdvOBx#*" "sync" || {
		Err "*#83LQXl#*"
		return 1
	}
	Task "*#WsZ4Du#*" "reboot || sudo reboot" || {
		Err "*#LbqVjx#*"
		return 1
	}
	Txt "*#vPFoca#*"
}
function SysUpd() {
	ChkRoot
	Txt "*#Y4euHV#*"
	Txt "*#25xJW2#*"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="$1"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "*#3VRzHO#*"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "*#4m6nuK#*"
			return 1
		}
		Txt "*#WpwsYp#*"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "*#HGu2FC#*"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "*#Dzz5Zb#*" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "*#pTFE6B#*"
				return 1
			}
		done
		Task "*#DTxgvn#*" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "*#hPHXeq#*"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "*#oXCm3C#*" "pacman -Syu --noconfirm" || {
		Err "*#9xZrNB#*"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "*#6X3bkz#*"
		return 1
	} ;;
	esac
	Txt "*#VDsxp1#*"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "*#mbQJvM#*"
		return 1
	}
	Txt "*#Ql21oD#*"
	Txt "*#7DZ1Nz#*"
}
function SysUpg() {
	ChkRoot
	Txt "*#7DaFMI#*"
	Txt "*#dkmvEq#*"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "*#xRcc7r#*"
		Txt "*#BcYQy3#*"
		apt update -y || {
			Err "*#ncGcJm#*"
			return 1
		}
		Txt "*#Rceav8#*"
		apt full-upgrade -y || {
			Err "*#7njKkQ#*"
			return 1
		}
		Txt "*#pWiID1#*"
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "*#C3lOki#*"
			return 1
		}
		Txt "*#PSAGs6#*"
		Task "*#DD1t7H#*" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "*#VXKuOB#*"
			return 1
		}
		Task "*#PwoBXB#*" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "*#Wp1JLH#*"
			return 1
		}
		Task "*#DkiK0N#*" "apt update -y" || {
			Err "*#SLE2bn#*"
			return 1
		}
		Task "*#Fe99uC#*" "apt full-upgrade -y" || {
			Err "*#DUhgN8#*"
			return 1
		}
		;;
	Ubuntu)
		Txt "*#941J8m#*"
		Task "*#NK16nf#*" "apt update -y" || {
			Err "*#bdQwNF#*"
			return 1
		}
		Task "*#zB2xEx#*" "apt full-upgrade -y" || {
			Err "*#dq0z6o#*"
			return 1
		}
		Task "*#uk1xfe#*" "apt install -y update-manager-core" || {
			Err "*#XXKncw#*"
			return 1
		}
		Task "*#rzZ41g#*" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "*#vLnAYc#*"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "*#IXTqF9#*"
		return 1
	} ;;
	esac
	Txt "*#I8C88L#*"
	Txt "*#c5EjMj#*"
}
function Task() {
	msg_Task="$1"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "*#pECtyK#*"
		ret_Task=0
	else
		ret_Task=$?
		Txt "*#5aEGDr#*"
		[[ -s ${tmp_file_Task} ]] && Txt "*#Y7qDRO#*"
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
			[ -n "${data_TimeZn}" ] && Txt "*#SgEPBx#*" || {
			Err "*#onA8VF#*"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${data_TimeZn}" ] && Txt "*#leeoPG#*" || {
			Err "*#dNtGvs#*"
			return 1
		}
		;;
	esac
}
function Press() {
	read -p "$1" -n 1 -r || {
		Err "*#wkjizL#*"
		return 1
	}
}
