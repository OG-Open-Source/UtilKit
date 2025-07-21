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
		Txt "*#JN7OF8#*"
		return 1
	}
	Txt "*#p31hpL#*"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "*#BBWI2f#*" | tr -d '\n')"
		Txt "*#JhyxV1#*" >>"${log_file_Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "*#2DXcpk#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#F4IE8u#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "*#F4IE8u#*"
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
			Txt "*#9IznAR#*"
			Get "$1"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "*#11gFNL#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "*#dYIE7S#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#F1ml2g#*"
				rm -f "${deb_file_Add}"
				Txt "*#N5XmKY#*"
			else
				Err "*#weWDSj#*"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "*#XUes5e#*"
				[ -d "$1" ] && {
					Err "*#U1TXyc#*"
					err_code_Add=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "*#NeTd9E#*"
					err_code_Add=1
					shift
					continue
				}
				touch "$1" || {
					Err "*#P0rzjR#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#Z0ReeX#*"
				Txt "*#N5XmKY#*"
				;;
			"dir")
				Txt "*#K8efOa#*"
				[ -f "$1" ] && {
					Err "*#2nMB7J#*"
					err_code_Add=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "*#yLuO5u#*"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "*#EiT1GZ#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#TPtyyJ#*"
				Txt "*#N5XmKY#*"
				;;
			"pkg")
				Txt "*#oXjfpl#*"
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
						Txt "*#6IfDu5#*"
						if inst_pkg_Add "$1"; then
							if is_instd_Add "$1"; then
								Txt "*#PCksb5#*"
								Txt "*#N5XmKY#*"
							else
								Err "*#BKc849#*"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "*#BKc849#*"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "*#M4FyPW#*"
						Txt "*#N5XmKY#*"
					fi
					;;
				*)
					Err "*#b4VFCx#*"
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
			Err "*#2jCXMa#*"
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
		Txt "*#TbC7Cq#*"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "*#87zAGR#*"
		Ask "*#9uag4w#*" -n 1 cont_inst_ChkDeps
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
			[ "${ID}" = "debian" ] && cat /etc/debian_version || Txt "*#aCwTZA#*"
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
				Err "*#eYA9ym#*"
				return 1
			}
		fi
		;;
	-n | --name)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			Txt "*#2URj8W#*" | sed 's/.*/\u&/'
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2 | awk '{print $1}'
		else
			{
				Err "*#3r69o2#*"
				return 1
			}
		fi
		;;
	*)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "${ID}" = "debian" ] && Txt "*#A040Kn#*" || Txt "*#xHwdt5#*"
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
		else
			{
				Err "*#3r69o2#*"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "*#O6CJoI#*"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "*#7wy9CA#*"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "*#eZyMAB#*" || Txt "*#utmr2h#*" ;;
		microsoft) Txt "*#qEsqrq#*" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "*#KThA77#*"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "*#RzExvW#*"
			else
				Txt "*#D0sSYd#*"
			fi
			;;
		*) Txt "*#ADMPS1#*" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "*#XvK1G8#*" || Txt "*#MKOAYp#*")
	else
		virt_typ_ChkVirt="未知"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "*#GyPyMn#*"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#bzI0MP#*"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "*#p4sdJb#*"
		return 1
	}
	Txt "*#FIP0sZ#*"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#bzI0MP#*"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "*#jdEYbE#*"
		return 1
	}
	Txt "*#Cg0LOL#*"
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
			Txt "*#pRhfTW#*"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#yYphkl#*"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#yYphkl#*"
		return 1
	}
	curr_tot_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	curr_idle_CpuUsage=${idle_CpuUsage}
	tot_delta_CpuUsage=$((curr_tot_CpuUsage - prev_total_CpuUsage))
	idle_delta_CpuUsage=$((curr_idle_CpuUsage - prev_idle_CpuUsage))
	cpu_usage_CpuUsage=$((100 * (tot_delta_CpuUsage - idle_delta_CpuUsage) / tot_delta_CpuUsage))
	Txt "*#32XIBl#*"
}
function ConvSz() {
	[ -z "$1" ] && {
		Err "*#j3Sl3m#*"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-iB}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "*#RiLgIN#*"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "*#VoZ8ov#*"
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
		Err "*#el1FFi#*"
		return 2
	fi
}
function Copyright() {
	Txt "*#G48QZi#*"
	Txt "*#KKMnvS#*"
}
function Del() {
	[ $# -eq 0 ] && {
		Err "*#NEQNWO#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#F4IE8u#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "*#F4IE8u#*"
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
				Txt "*#0ef46Q#*"
				[ ! -f "$1" ] && {
					Err "*#ZNUM7a#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#8wFHIy#*"
				rm -f "$1" || {
					Err "*#NnhOr4#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#bZIoq5#*"
				Txt "*#N5XmKY#*"
				;;
			"dir")
				Txt "*#EQ4SCl#*"
				[ ! -d "$1" ] && {
					Err "*#Ysecfa#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#eidAYV#*"
				rm -rf "$1" || {
					Err "*#pDRRSB#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#FJwwaB#*"
				Txt "*#N5XmKY#*"
				;;
			"pkg")
				Txt "*#NZkQcD#*"
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
						Txt "*#GmJyfV#*"
						Txt "*#N5XmKY#*"
					else
						if rm_pkg_Del "$1"; then
							if ! is_instd_Del "$1"; then
								Txt "*#sHtE9U#*"
								Txt "*#N5XmKY#*"
							else
								Err "*#9W56uo#*"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "*#9W56uo#*"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "*#b4VFCx#*"
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
		Err "*#ahd2cB#*"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "*#83GVIp#*"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) Txt "*#icBEye#*" ;;
	-t) Txt "*#JzaCZ3#*" ;;
	-p) Txt "*#0SuxSC#*" ;;
	*) Txt "*#LZZhrv#*" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "*#CqIBWC#*"
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
		Err "*#mz00Yg#*"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#uoyU8t#*"
			return 1
		}
		Txt "*#S8VX2U#*"
		;;
	-6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#aGHAG8#*"
			return 1
		}
		Txt "*#PUr1Lp#*"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#7Gj904#*"
			return 1
		}
		Txt "*#Q1tl4C#*"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "*#00pJWo#*"
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
		Err "*#PTfxVs#*"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "*#sDu9ET#*"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "*#POaqQ6#*"
			return 1
		}
		Txt "*#N5XmKY#*"
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
	Txt "*#oyDu7t#*"
}
function Format() {
	flg_Format="$1"
	val_Format="$2"
	res_Format=""
	[ -z "${val_Format}" ] && {
		Err "*#BNh5zV#*"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "*#yDD8Zy#*"
		return 2
	}
	case "${flg_Format}" in
	-AA) res_Format=$(Txt "*#3FRT4J#*" | tr '[:lower:]' '[:upper:]') ;;
	-aa) res_Format=$(Txt "*#3FRT4J#*" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) res_Format=$(Txt "*#3FRT4J#*" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) res_Format="${val_Format}" ;;
	esac
	Txt "*#uXYbV6#*"
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
				Err "*#ZVvghI#*"
				return 2
			}
			rnm_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "*#2jCXMa#*"
			return 2
		} ;;
		*)
			[ -z "${url_Get}" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "${url_Get}" ] && {
		Err "*#4gFVN0#*"
		return 2
	}
	[[ ${url_Get} =~ ^(http|https|ftp):// ]] || url_Get="https://${url_Get}"
	oup_file_Get="${url_Get##*/}"
	[ -z "${oup_file_Get}" ] && oup_file_Get="index.html"
	[ "${targ_dir_Get}" != "." ] && { mkdir -p "${targ_dir_Get}" || {
		Err "*#9CKNnL#*"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && oup_file_Get="${rnm_file_Get}"
	oup_path_Get="${targ_dir_Get}/${oup_file_Get}"
	url_Get=$(Txt "*#PrtTQ2#*" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "*#W1i0IC#*"
	file_sz_Get=$(curl -sI "${url_Get}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url_Get}" -O "${oup_path_Get}" || {
			Err "*#GxWv2g#*"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url_Get}" -o "${oup_path_Get}" || {
			Err "*#S9TiYJ#*"
			return 1
		}
	fi
	if [ -f "${oup_path_Get}" ]; then
		Txt "*#9JTj2e#*"
		if [ "${unzip_Get}" = true ]; then
			case "${oup_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#Qn0hpv#*"
				return 1
			} ;;
			*.tar) tar -xf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#VT6RaZ#*"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#WBih2y#*"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#c4NVtG#*"
				return 1
			} ;;
			*.zip) unzip "${oup_path_Get}" -d "${targ_dir_Get}" || {
				Err "*#Bncgit#*"
				return 1
			} ;;
			*.7z) 7z x "${oup_path_Get}" -o"${targ_dir_Get}" || {
				Err "*#k7wBgK#*"
				return 1
			} ;;
			*.rar) unrar x "${oup_path_Get}" "${targ_dir_Get}" || {
				Err "*#5bzJGt#*"
				return 1
			} ;;
			*.zst) zstd -d "${oup_path_Get}" -o "${targ_dir_Get}" || {
				Err "*#CA4XGp#*"
				return 1
			} ;;
			*) Txt "*#OHcPnT#*" ;;
			esac
			[ $? -eq 0 ] && Txt "*#L8BPV9#*"
		fi
		Txt "*#N5XmKY#*"
	else
		{
			Err "*#sGHaT9#*"
			return 1
		}
	fi
}
function Ask() {
	prompt_msg_Ask="$1"
	shift
	read -e -p "$prompt_msg_Ask" -r "$@" || {
		Err "*#g8HFO5#*"
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
		Err "*#oH37uY#*"
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
				Txt "*#aQy2PZ#*"
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
		interface_Iface=$(Txt "*#NfZsmF#*" | tr -s ' ' | xargs)
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
					Txt "*#6CSuGJ#*"
					break
					;;
				--rx_packets)
					Txt "*#mYf0eL#*"
					break
					;;
				--rx_drop)
					Txt "*#pjvdii#*"
					break
					;;
				--tx_bytes)
					Txt "*#GdK6Bw#*"
					break
					;;
				--tx_packets)
					Txt "*#j3fPWv#*"
					break
					;;
				--tx_drop)
					Txt "*#tr59jR#*"
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
				Txt "*#3wu33z#*"
			fi
		done
		;;
	*) Txt "*#NfZsmF#*" ;;
	esac
}
function IpAddr() {
	flg_IpAddr="$1"
	case "${flg_IpAddr}" in
	-4 | --ipv4)
		ipv4_addr_IpAddr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv4_addr_IpAddr}" ] && Txt "*#J7F0DX#*" || {
			Err "*#P1lccB#*"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "*#NE7T0m#*" || {
			Err "*#evJY6m#*"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "*#6U9lq6#*"
			return 1
		}
		[ -n "${ipv4_addr_IpAddr}" ] && Txt "*#sXAtXh#*"
		[ -n "${ipv6_addr_IpAddr}" ] && Txt "*#9ON1ki#*"
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
		Err "*#nNbyKv#*"
		return 1
	} || Txt "*#ElekW6#*"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "*#ryma5D#*"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "*#sWKYWF#*"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "*#xgNB8Q#*"
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
	[ -n "${data_Loc}" ] && Txt "*#wUbU3C#*" || {
		Err "*#IQQmKA#*"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "*#RgsKW2#*" || {
		Err "*#NJ8ojH#*"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "*#XXwlnC#*"
		return 1
	}
	tot_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || tot_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) Txt "*#pXTGkt#*" ;;
	-t) Txt "*#4h7Pmz#*" ;;
	-p) Txt "*#pq11B5#*" ;;
	*) Txt "*#VAIaRZ#*" ;;
	esac
}
function NetProv() {
	data_NetProv=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${data_NetProv}" ] && Txt "*#FR4suC#*" || {
		Err "*#MGYJjY#*"
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
		Err "*#Yhx30E#*"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "*#lzxpX3#*"
			return 1
		}
	fi
	Txt "*#nMV66p#*"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "*#JQgZL2#*"
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
			Txt "*#CNlL69#*"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "*#PzECjx#*"
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
	[ -n "${data_PubIp}" ] && Txt "*#1kkbnw#*" || {
		Err "*#UhtzmO#*"
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
		Err "*#aM3PXv#*"
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
			Txt "*#kG7dm0#*"
			Task "*#e0kNdt#*" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "*#C3TDBj#*"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "*#Izqara#*"; return 1; }
			"
			Txt "*#3aqncY#*"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "*#Btc4ac#*"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "*#Btc4ac#*"
					return 1
				}
			fi
			Txt "*#3aqncY#*"
			Txt "*#N5XmKY#*"
			[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
		elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner_Run=$(Txt "*#BBWI2f#*" | cut -d'/' -f1)
			repo_name_Run=$(Txt "*#BBWI2f#*" | cut -d'/' -f2)
			script_path_Run=$(Txt "*#BBWI2f#*" | cut -d'/' -f3-)
			script_nm_Run=$(basename "${script_path_Run}")
			branch_Run="main"
			dnload_repo_Run=false
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-b | --branch)
					[[ -z $2 || $2 == -* ]] && {
						Err "*#KQHeek#*"
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
				Txt "*#1WpvvI#*"
				[[ -d ${repo_name_Run} ]] && {
					Err "*#DHj2uz#*"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#vJHePS#*" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "*#u32hSw#*"
							return 1
						}
					fi
				else
					Task "*#Sr5z6Q#*" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "*#GjSPbD#*" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "*#fWdnhP#*"
								return 1
							}
						fi
					fi
				fi
				Task "*#kiBHqy#*" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "*#TkiIf8#*" "rm -rf "${tmp_dir_Run}""
				Txt "*#sV81QY#*"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "*#1fiDZJ#*" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "*#3aqncY#*"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "*#Btc4ac#*"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "*#Btc4ac#*"
							return 1
						}
					fi
					Txt "*#3aqncY#*"
					Txt "*#N5XmKY#*"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "*#ZyhSPM#*"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#R7Eija#*" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "*#nKUpRk#*"
						return 1
					}
				else
					Task "*#Sr5z6Q#*" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "*#llcI7v#*" "
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
				Task "*#e0kNdt#*" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || {
						Err "*#C3TDBj#*"
						Err "*#UJJYJK#*"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "*#bBCkDc#*"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "*#B2kKzx#*"
						cat "${script_nm_Run}" 2>/dev/null || Txt "*#9a0PXY#*"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "*#EqQwPE#*"
						return 1
					fi
					chmod +x "${script_nm_Run}" || {
						Err "*#Izqara#*"
						Err "*#MebCyo#*"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "*#3aqncY#*"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "*#Btc4ac#*"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "*#Btc4ac#*"
							return 1
						}
					fi
				else
					Err "*#noVVXM#*"
					return 1
				fi
				Txt "*#3aqncY#*"
				Txt "*#N5XmKY#*"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "*#Btc4ac#*"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "*#Btc4ac#*"
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
		Txt "*#G0ezQU#*"
	elif [ -n "${ZSH_VERSION-}" ]; then
		Txt "*#WM3hQS#*"
	else
		{
			Err "*#5XEpF1#*"
			return 1
		}
	fi
}
function SwapUsage() {
	usd_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	tot_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) Txt "*#Ngsqfo#*" ;;
	-t) Txt "*#ujbLuY#*" ;;
	-p) Txt "*#aiAiqw#*" ;;
	*) Txt "*#PD7nYI#*" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "*#jgi3KQ#*"
	Txt "*#3aqncY#*"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "*#B0p5FM#*"
		apk cache clean || {
			Err "*#rAgG8U#*"
			return 1
		}
		Txt "*#mYzL0s#*"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "*#uM0D88#*"
			return 1
		}
		Txt "*#rvfsqn#*"
		apk fix || {
			Err "*#zi5PsW#*"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "*#5AdBYd#*"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "*#2lY6Xj#*"
				return 1
			}
		done
		Txt "*#omePJZ#*"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "*#NOvU21#*"
			return 1
		}
		Txt "*#m91E2X#*"
		apt autoremove --purge -y || {
			Err "*#qa7OIB#*"
			return 1
		}
		Txt "*#9E52TT#*"
		apt clean -y || {
			Err "*#l0VlWB#*"
			return 1
		}
		Txt "*#vtzusT#*"
		apt autoclean -y || {
			Err "*#30azVx#*"
			return 1
		}
		;;
	*opkg)
		Txt "*#mYzL0s#*"
		rm -rf /tmp/* || {
			Err "*#uM0D88#*"
			return 1
		}
		Txt "*#dkgSCY#*"
		opkg update || {
			Err "*#NxNuwh#*"
			return 1
		}
		Txt "*#ZOtj8g#*"
		opkg clean || {
			Err "*#sfdPJi#*"
			return 1
		}
		;;
	*pacman)
		Txt "*#MGhJcI#*"
		pacman -Syu --noconfirm || {
			Err "*#G6Ysxx#*"
			return 1
		}
		Txt "*#ELWSML#*"
		pacman -Sc --noconfirm || {
			Err "*#w2VDHK#*"
			return 1
		}
		Txt "*#uqnoxt#*"
		pacman -Scc --noconfirm || {
			Err "*#GxQRG1#*"
			return 1
		}
		;;
	*yum)
		Txt "*#m91E2X#*"
		yum autoremove -y || {
			Err "*#qa7OIB#*"
			return 1
		}
		Txt "*#gU3SgJ#*"
		yum clean all || {
			Err "*#24m4ku#*"
			return 1
		}
		Txt "*#Vthn0H#*"
		yum makecache || {
			Err "*#Uc2GAp#*"
			return 1
		}
		;;
	*zypper)
		Txt "*#OwGDe1#*"
		zypper clean --all || {
			Err "*#Mj1wCF#*"
			return 1
		}
		Txt "*#nbBY6i#*"
		zypper refresh || {
			Err "*#3fSDBh#*"
			return 1
		}
		;;
	*dnf)
		Txt "*#m91E2X#*"
		dnf autoremove -y || {
			Err "*#qa7OIB#*"
			return 1
		}
		Txt "*#B3Z2IR#*"
		dnf clean all || {
			Err "*#Jme6vV#*"
			return 1
		}
		Txt "*#Wyds0L#*"
		dnf makecache || {
			Err "*#fm1Dyz#*"
			return 1
		}
		;;
	*) {
		Err "*#GNwZH0#*"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "*#PCf5sG#*" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "*#6VQ9MW#*"
			return 1
		}
	fi
	Task "*#mYzL0s#*" "rm -rf /tmp/*" || {
		Err "*#uM0D88#*"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "*#XRmYz5#*" "docker system prune -af" || {
				Err "*#rDheQ5#*"
				return 1
			} ;;
			npm) Task "*#59RUSZ#*" "npm cache clean --force" || {
				Err "*#2t2o9M#*"
				return 1
			} ;;
			pip) Task "*#1xy0y6#*" "pip cache purge" || {
				Err "*#Ngheq7#*"
				return 1
			} ;;
			esac
		fi
	done
	Task "*#XB7S9B#*" "rm -rf ~/.cache/*" || {
		Err "*#K1TSmP#*"
		return 1
	}
	Task "*#SxzDBG#*" "rm -rf ~/.thumbnails/*" || {
		Err "*#zH7yiP#*"
		return 1
	}
	Txt "*#3aqncY#*"
	Txt "*#N5XmKY#*"
}
function SysInfo() {
	Txt "*#B7H8Ca#*"
	Txt "*#3aqncY#*"
	Txt "*#zFGkCd#*"
	Txt "*#OEr66z#*"
	Txt "*#sS0bxI#*"
	Txt "*#ArhySi#*"
	Txt "*#bIhEHI#*"
	Txt "*#ilUobu#*"
	Txt "*#uccsqK#*"
	Txt "*#e4w5NA#*"
	Txt "*#pOtT4I#*"
	Txt "*#EXpFAL#*"
	Txt "*#hC5OkN#*"
	Txt "*#hBqFgT#*"
	Txt "*#v3xy3X#*"
	Txt "*#uccsqK#*"
	Txt "*#JyK471#*"
	Txt "*#Jsqaee#*"
	Txt "*#Ck9dqS#*"
	Txt "*#gybU8R#*"
	Txt "*#uccsqK#*"
	Txt "*#4fSsQE#*"
	Txt "*#EHNFMf#*"
	Txt "*#2eUYgd#*"
	Txt "*#SugaaD#*"
	Txt "*#zyHc0J#*"
	Txt "*#2bMqrB#*"
	Txt "*#j2qQXO#*"
	Txt "*#eovGJ2#*"
	Txt "*#PdwiU8#*"
	Txt "*#uccsqK#*"
	Txt "*#WoLVgE#*"
	Txt "*#6Dm6uD#*"
	Txt "*#GIqzKs#*"
	Txt "*#uccsqK#*"
	Txt "*#obJdPr#*"
	Txt "*#crUH6b#*"
	Txt "*#uccsqK#*"
	Txt "*#V7LWRK#*"
	Txt "*#3aqncY#*"
}
function SysOptz() {
	ChkRoot
	Txt "*#b404TK#*"
	Txt "*#3aqncY#*"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "*#4X6IjK#*" >"${sysctl_conf_SysOptimize}"
	Task "*#B3FuSA#*" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#VuQTeM#*"
		return 1
	}
	Task "*#h4uWNv#*" "
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
		Err "*#XlxUw0#*"
		return 1
	}
	Task "*#R9r1Uq#*" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#MR1PfN#*"
		return 1
	}
	Task "*#ZnRYiH#*" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#U3cW8Z#*"
		return 1
	}
	Task "*#5yr0RH#*" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "*#J5S3n7#*"
		return 1
	}
	Task "*#KiPA6A#*" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "*#IKRjPi#*"
		return 1
	}
	Task "*#rh28Pa#*" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
		Err "*#mRsgfe#*"
		return 1
	}
	Task "*#zUaYdw#*" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "*#8cD7CP#*"
		return 1
	}
	Task "*#xa4yEM#*" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "*#bzNa05#*"
		return 1
	}
	Txt "*#3aqncY#*"
	Txt "*#N5XmKY#*"
}
function SysRboot() {
	ChkRoot
	Txt "*#vhY7IF#*"
	Txt "*#3aqncY#*"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "*#4KNsUm#*"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "*#SNfTXH#*"
		Txt "*#VbLepD#*"
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "*#xTZFpv#*"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "*#dKkJa4#*"
		Txt "*#L4tOau#*"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "*#ZiTuo9#*" -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "*#C0PN47#*"
		return 0
	}
	Task "*#N5Nut3#*" "sync" || {
		Err "*#aRndkC#*"
		return 1
	}
	Task "*#qwGnGV#*" "reboot || sudo reboot" || {
		Err "*#8TGr77#*"
		return 1
	}
	Txt "*#EycvpF#*"
}
function SysUpd() {
	ChkRoot
	Txt "*#XuRD1L#*"
	Txt "*#3aqncY#*"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="$1"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "*#e8cVHK#*"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "*#AeXNRn#*"
			return 1
		}
		Txt "*#HBBy9m#*"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "*#AhR6xr#*"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "*#5AdBYd#*" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "*#2lY6Xj#*"
				return 1
			}
		done
		Task "*#omePJZ#*" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "*#z2fj2q#*"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "*#MGhJcI#*" "pacman -Syu --noconfirm" || {
		Err "*#G6Ysxx#*"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "*#Oc7uIL#*"
		return 1
	} ;;
	esac
	Txt "*#dY8eCq#*"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "*#Iu4Fb2#*"
		return 1
	}
	Txt "*#3aqncY#*"
	Txt "*#N5XmKY#*"
}
function SysUpg() {
	ChkRoot
	Txt "*#aYZPAf#*"
	Txt "*#3aqncY#*"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "*#QbCRGx#*"
		Txt "*#e8cVHK#*"
		apt update -y || {
			Err "*#KIvTRO#*"
			return 1
		}
		Txt "*#2HZQml#*"
		apt full-upgrade -y || {
			Err "*#90mah1#*"
			return 1
		}
		Txt "*#JXz1KM#*"
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "*#bpT0GN#*"
			return 1
		}
		Txt "*#4Z0gUi#*"
		Task "*#kWBWoK#*" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "*#JDDUCL#*"
			return 1
		}
		Task "*#R30P89#*" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "*#Eu00pR#*"
			return 1
		}
		Task "*#xHIHjQ#*" "apt update -y" || {
			Err "*#Kutl7V#*"
			return 1
		}
		Task "*#TnZWiO#*" "apt full-upgrade -y" || {
			Err "*#Nf3Z5N#*"
			return 1
		}
		;;
	Ubuntu)
		Txt "*#oXnInY#*"
		Task "*#e8cVHK#*" "apt update -y" || {
			Err "*#KIvTRO#*"
			return 1
		}
		Task "*#2HZQml#*" "apt full-upgrade -y" || {
			Err "*#90mah1#*"
			return 1
		}
		Task "*#1JQvQE#*" "apt install -y update-manager-core" || {
			Err "*#pxwFCE#*"
			return 1
		}
		Task "*#qMU7aE#*" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "*#Xx3RLX#*"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "*#P72LS9#*"
		return 1
	} ;;
	esac
	Txt "*#3aqncY#*"
	Txt "*#DDHP4E#*"
}
function Task() {
	msg_Task="$1"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "*#Fa3yjh#*"
		ret_Task=0
	else
		ret_Task=$?
		Txt "*#M0Pc2d#*"
		[[ -s ${tmp_file_Task} ]] && Txt "*#XsvIrG#*"
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
			[ -n "${data_TimeZn}" ] && Txt "*#lh5NLN#*" || {
			Err "*#6cslII#*"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${data_TimeZn}" ] && Txt "*#lh5NLN#*" || {
			Err "*#qubKRG#*"
			return 1
		}
		;;
	esac
}
function Press() {
	read -p "$1" -n 1 -r || {
		Err "*#g8HFO5#*"
		return 1
	}
}
