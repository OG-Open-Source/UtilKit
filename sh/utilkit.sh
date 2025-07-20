#!/bin/bash

ANTHORS="OG-Open-Source"
SCRIPTS="UtilKit.sh"
VERSION="7.046.003"

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
		Txt "*#SEtkrm#*"
		return 1
	}
	Txt "*#d2KmNh#*"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "*#NUOosQ#*" | tr -d '\n')"
		Txt "*#5sU0Wc#*" >>"${log_file_Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "*#Fug19R#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#EFgHbs#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "*#EFgHbs#*"
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
			Txt "*#4DoU2C#*"
			Get "$1"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "*#QN8njz#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "*#qDEBMQ#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#9fvsoP#*"
				rm -f "${deb_file_Add}"
				Txt "*#x17H8G#*"
			else
				Err "*#ZPWvLb#*"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "*#59RWJy#*"
				[ -d "$1" ] && {
					Err "*#nzOiPk#*"
					err_code_Add=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "*#4XxvOS#*"
					err_code_Add=1
					shift
					continue
				}
				touch "$1" || {
					Err "*#s7xCg1#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#2cvuwn#*"
				Txt "*#x17H8G#*"
				;;
			"dir")
				Txt "*#orfwZh#*"
				[ -f "$1" ] && {
					Err "*#QcW41m#*"
					err_code_Add=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "*#wnir1p#*"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "*#mN8R5Z#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#FpdNR5#*"
				Txt "*#x17H8G#*"
				;;
			"pkg")
				Txt "*#YhLzo8#*"
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
						Txt "*#mhZvSY#*"
						if inst_pkg_Add "$1"; then
							if is_instd_Add "$1"; then
								Txt "*#aUrCqM#*"
								Txt "*#x17H8G#*"
							else
								Err "*#XAouyj#*"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "*#XAouyj#*"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "*#iexMCh#*"
						Txt "*#x17H8G#*"
					fi
					;;
				*)
					Err "*#mVUgYn#*"
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
			Err "*#qg2pmX#*"
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
		Txt "*#bN41fy#*"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "*#oiZCdI#*"
		Ask "*#w9LpXZ#*" -n 1 cont_inst_ChkDeps
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
			[ "${ID}" = "debian" ] && cat /etc/debian_version || Txt "*#FZqI3Q#*"
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
				Err "*#kg8tva#*"
				return 1
			}
		fi
		;;
	-n | --name)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			Txt "*#rnF1sg#*" | sed 's/.*/\u&/'
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2 | awk '{print $1}'
		else
			{
				Err "*#FLVOxn#*"
				return 1
			}
		fi
		;;
	*)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "${ID}" = "debian" ] && Txt "*#5ErO2t#*" || Txt "*#AR65xp#*"
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
		else
			{
				Err "*#FLVOxn#*"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "*#vyuiw5#*"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "*#E9n2OL#*"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "*#AiMZWm#*" || Txt "*#01tigh#*" ;;
		microsoft) Txt "*#oqaP7F#*" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "*#wbhF34#*"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "*#kz1y8x#*"
			else
				Txt "*#tPTAZU#*"
			fi
			;;
		*) Txt "*#C9LtJb#*" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "*#3biyxT#*" || Txt "*#5YwlsA#*")
	else
		virt_typ_ChkVirt="未知"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "*#Vc5D32#*"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#rOBfXw#*"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "*#RXVCpz#*"
		return 1
	}
	Txt "*#rNL2Qf#*"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#rOBfXw#*"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "*#vHIJFG#*"
		return 1
	}
	Txt "*#DNxGcH#*"
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
			Txt "*#J9LXVQ#*"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#jOgT6i#*"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#jOgT6i#*"
		return 1
	}
	curr_tot_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	curr_idle_CpuUsage=${idle_CpuUsage}
	tot_delta_CpuUsage=$((curr_tot_CpuUsage - prev_total_CpuUsage))
	idle_delta_CpuUsage=$((curr_idle_CpuUsage - prev_idle_CpuUsage))
	cpu_usage_CpuUsage=$((100 * (tot_delta_CpuUsage - idle_delta_CpuUsage) / tot_delta_CpuUsage))
	Txt "*#thYGsz#*"
}
function ConvSz() {
	[ -z "$1" ] && {
		Err "*#iHTwRx#*"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-iB}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "*#10RPXi#*"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "*#SjLmc8#*"
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
		Err "*#SqLdTa#*"
		return 2
	fi
}
function Copyright() {
	Txt "*#OAcufz#*"
	Txt "*#GsDXiP#*"
}
function Del() {
	[ $# -eq 0 ] && {
		Err "*#2ejY0A#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#EFgHbs#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "*#EFgHbs#*"
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
				Txt "*#hA2aBD#*"
				[ ! -f "$1" ] && {
					Err "*#iT6Zby#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#XOMFHK#*"
				rm -f "$1" || {
					Err "*#Xrfu2A#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#OI1CtU#*"
				Txt "*#x17H8G#*"
				;;
			"dir")
				Txt "*#KSdZkj#*"
				[ ! -d "$1" ] && {
					Err "*#wP6K5d#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#Gtx0df#*"
				rm -rf "$1" || {
					Err "*#LrZFh9#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#Kz08GF#*"
				Txt "*#x17H8G#*"
				;;
			"pkg")
				Txt "*#hjPSo8#*"
				ChkRoot
				case ${PKG_MGR} in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					in_instd_Del() {
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
					if ! in_instd_Del "$1"; then
						Txt "*#Jc7k4s#*"
						Txt "*#x17H8G#*"
					else
						if rm_pkg_Del "$1"; then
							if ! in_instd_Del "$1"; then
								Txt "*#GEPMRf#*"
								Txt "*#x17H8G#*"
							else
								Err "*#tI2VsQ#*"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "*#tI2VsQ#*"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "*#mVUgYn#*"
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
		Err "*#OzEFQ8#*"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "*#dAMoju#*"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) Txt "*#kS9bx5#*" ;;
	-t) Txt "*#M3PAlv#*" ;;
	-p) Txt "*#vlt1c9#*" ;;
	*) Txt "*#XpTuGi#*" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "*#lkNhrS#*"
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
		Err "*#yIxt1g#*"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#tfjE9F#*"
			return 1
		}
		Txt "*#83nyps#*"
		;;
	-6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#h47HKl#*"
			return 1
		}
		Txt "*#FwmMAD#*"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#xsB5LK#*"
			return 1
		}
		Txt "*#K9OYLm#*"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "*#oqtgRQ#*"
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
		Err "*#otNnFg#*"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "*#RQecL8#*"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "*#6VNaGB#*"
			return 1
		}
		Txt "*#x17H8G#*"
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
	Txt "*#IMGywc#*"
}
function Format() {
	flg_Format="$1"
	val_Format="$2"
	res_Format=""
	[ -z "${val_Format}" ] && {
		Err "*#8v4swH#*"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "*#o8u0ZB#*"
		return 2
	}
	case "${flg_Format}" in
	-AA) res_Format=$(Txt "*#9VmLHS#*" | tr '[:lower:]' '[:upper:]') ;;
	-aa) res_Format=$(Txt "*#9VmLHS#*" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) res_Format=$(Txt "*#9VmLHS#*" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) res_Format="${val_Format}" ;;
	esac
	Txt "*#u91dRs#*"
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
				Err "*#pHsZ1k#*"
				return 2
			}
			rnm_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "*#qg2pmX#*"
			return 2
		} ;;
		*)
			[ -z "${url_Get}" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "${url_Get}" ] && {
		Err "*#M2C3ig#*"
		return 2
	}
	[[ ${url_Get} =~ ^(http|https|ftp):// ]] || url_Get="https://${url_Get}"
	ou_file_Get="${url_Get##*/}"
	[ -z "${ou_file_Get}" ] && ou_file_Get="index.html"
	[ "${targ_dir_Get}" != "." ] && { mkdir -p "${targ_dir_Get}" || {
		Err "*#xAyG4g#*"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && ou_file_Get="${rnm_file_Get}"
	ou_path_Get="${targ_dir_Get}/${ou_file_Get}"
	url_Get=$(Txt "*#PrjAn3#*" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "*#wH09OJ#*"
	file_sz_Get=$(curl -sI "${url_Get}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url_Get}" -O "${ou_path_Get}" || {
			Err "*#B8KanE#*"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url_Get}" -o "${ou_path_Get}" || {
			Err "*#2JnxZF#*"
			return 1
		}
	fi
	if [ -f "${ou_path_Get}" ]; then
		Txt "*#Ej2DvA#*"
		if [ "${unzip_Get}" = true ]; then
			case "${ou_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#L1IQ8O#*"
				return 1
			} ;;
			*.tar) tar -xf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#sVip6W#*"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#O3BeDY#*"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#Tmg1cN#*"
				return 1
			} ;;
			*.zip) unzip "${ou_path_Get}" -d "${targ_dir_Get}" || {
				Err "*#lB3pWJ#*"
				return 1
			} ;;
			*.7z) 7z x "${ou_path_Get}" -o"${targ_dir_Get}" || {
				Err "*#9yP2OS#*"
				return 1
			} ;;
			*.rar) unrar x "${ou_path_Get}" "${targ_dir_Get}" || {
				Err "*#Mweom9#*"
				return 1
			} ;;
			*.zst) zstd -d "${ou_path_Get}" -o "${targ_dir_Get}" || {
				Err "*#3BiPzX#*"
				return 1
			} ;;
			*) Txt "*#xuLHMY#*" ;;
			esac
			[ $? -eq 0 ] && Txt "*#2F9lL1#*"
		fi
		Txt "*#x17H8G#*"
	else
		{
			Err "*#OeIjbz#*"
			return 1
		}
	fi
}
function Ask() {
	read -e -p "$1" -r $2 || {
		Err "*#EmUyhn#*"
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
		Err "*#VUfwkD#*"
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
				Txt "*#JXUbGK#*"
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
		interface_Iface=$(Txt "*#6CODpo#*" | tr -s ' ' | xargs)
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
					Txt "*#0MEN4i#*"
					break
					;;
				--rx_packets)
					Txt "*#FLCZmi#*"
					break
					;;
				--rx_drop)
					Txt "*#tMLQD3#*"
					break
					;;
				--tx_bytes)
					Txt "*#tlLFJ0#*"
					break
					;;
				--tx_packets)
					Txt "*#19fQsv#*"
					break
					;;
				--tx_drop)
					Txt "*#wnxASu#*"
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
				Txt "*#83XZnE#*"
			fi
		done
		;;
	*) Txt "*#6CODpo#*" ;;
	esac
}
function IpAddr() {
	flg_IpAddr="$1"
	case "${flg_IpAddr}" in
	-4 | --ipv4)
		ipv4_addr_IpAddr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv4_addr_IpAddr}" ] && Txt "*#12YsE4#*" || {
			Err "*#NPrgKl#*"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "*#SHFfJ0#*" || {
			Err "*#EYhMeL#*"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "*#qWTkDN#*"
			return 1
		}
		[ -n "${ipv4_addr_IpAddr}" ] && Txt "*#cMvxNT#*"
		[ -n "${ipv6_addr_IpAddr}" ] && Txt "*#cJUQFj#*"
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
		Err "*#5rPSg8#*"
		return 1
	} || Txt "*#psITcL#*"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "*#74AgVM#*"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "*#BUsfHe#*"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "*#VlJsM9#*"
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
	[ -n "${data_Loc}" ] && Txt "*#QgwRLl#*" || {
		Err "*#pamBnR#*"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "*#xLnz6N#*" || {
		Err "*#ZAYbUy#*"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "*#xf8D5W#*"
		return 1
	}
	tot_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || tot_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) Txt "*#k1uh3O#*" ;;
	-t) Txt "*#fy42RG#*" ;;
	-p) Txt "*#UOTgpw#*" ;;
	*) Txt "*#0ZHU6q#*" ;;
	esac
}
function NetProv() {
	data_NetProv=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${data_NetProv}" ] && Txt "*#kUdLgh#*" || {
		Err "*#rH4B36#*"
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
		Err "*#4qR7Sv#*"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "*#NPBsJc#*"
			return 1
		}
	fi
	Txt "*#EdFesa#*"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "*#bK1egM#*"
		return 1
	}
	bar_wid_Prog=$((term_wid_Prog - 23))
	stty -echo
	trap '' SIGINT SIGQUIT SIGTSTP
	for ((i = 0; i < num_cmds_Prog; i++)); do
		prog_Prog=$((i * 100 / num_cmds_Prog))
		fild_wid_Prog=$((prog_Prog * bar_wid_Prog / 100))
		printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "${prog_Prog}" "$(printf "%${fild_wid_Prog}s" | tr ' ' '#')" "$(printf "%$((bar_wid_Prog - fild_wid_Prog))s" | tr ' ' '.')"
		if ! cmd_ou_Prog=$(eval "${cmds[$i]}" 2>&1); then
			Txt "*#sFpijo#*"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "*#taufvn#*"
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
	[ -n "${data_PubIp}" ] && Txt "*#mh1oeY#*" || {
		Err "*#ZLlpsg#*"
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
		Err "*#WKcqMb#*"
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
			Txt "*#9cb3uO#*"
			Task "*#ZUtPcB#*" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "*#lDhPgu#*"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "*#WwXeZG#*"; return 1; }
			"
			Txt "*#06acCR#*"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "*#y5dCIf#*"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "*#y5dCIf#*"
					return 1
				}
			fi
			Txt "*#06acCR#*"
			Txt "*#x17H8G#*"
			[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
		elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner_Run=$(Txt "*#NUOosQ#*" | cut -d'/' -f1)
			repo_name_Run=$(Txt "*#NUOosQ#*" | cut -d'/' -f2)
			script_path_Run=$(Txt "*#NUOosQ#*" | cut -d'/' -f3-)
			script_nm_Run=$(basename "${script_path_Run}")
			branch_Run="main"
			dnload_repo_Run=false
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "$1" in
				-b | --branch)
					[[ -z $2 || $2 == -* ]] && {
						Err "*#TLP4V0#*"
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
				Txt "*#EXR4K3#*"
				[[ -d ${repo_name_Run} ]] && {
					Err "*#qrHwpi#*"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#KIRkDq#*" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "*#ZYwhmP#*"
							return 1
						}
					fi
				else
					Task "*#qzJ50Q#*" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "*#5WDq89#*" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "*#3b0GJu#*"
								return 1
							}
						fi
					fi
				fi
				Task "*#5EC4Sr#*" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "*#m78JGy#*" "rm -rf "${tmp_dir_Run}""
				Txt "*#Zcd3w6#*"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "*#b2wFdm#*" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "*#06acCR#*"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "*#y5dCIf#*"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "*#y5dCIf#*"
							return 1
						}
					fi
					Txt "*#06acCR#*"
					Txt "*#x17H8G#*"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "*#dJAh0g#*"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#a3PRKl#*" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "*#FseCfX#*"
						return 1
					}
				else
					Task "*#qzJ50Q#*" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "*#hLoeEB#*" "
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
				Task "*#ZUtPcB#*" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || { 
						Err "*#lDhPgu#*"
						Err "*#SwXGIH#*"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "*#3mPe8K#*"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "*#hvCS6Z#*"
						cat "${script_nm_Run}" 2>/dev/null || Txt "*#vkn1rp#*"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "*#L1CI4B#*"
						return 1
					fi
					chmod +x "${script_nm_Run}" || { 
						Err "*#WwXeZG#*"
						Err "*#2WC7bF#*"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "*#06acCR#*"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "*#y5dCIf#*"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "*#y5dCIf#*"
							return 1
						}
					fi
				else
					Err "*#g05xFh#*"
					return 1
				fi
				Txt "*#06acCR#*"
				Txt "*#x17H8G#*"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "*#y5dCIf#*"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "*#y5dCIf#*"
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
		Txt "*#LywbKx#*"
	elif [ -n "${ZSH_VERSION-}" ]; then
		Txt "*#fyrVeM#*"
	else
		{
			Err "*#IjEChL#*"
			return 1
		}
	fi
}
function SwapUsage() {
	usd_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	tot_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) Txt "*#iSM9vm#*" ;;
	-t) Txt "*#AtRuoG#*" ;;
	-p) Txt "*#fz8hZw#*" ;;
	*) Txt "*#xAeMJX#*" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "*#pRXDT2#*"
	Txt "*#06acCR#*"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "*#UoRBfp#*"
		apk cache clean || {
			Err "*#PJopU2#*"
			return 1
		}
		Txt "*#lUqsgx#*"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "*#w25aZG#*"
			return 1
		}
		Txt "*#grNxeK#*"
		apk fix || {
			Err "*#I9Xsul#*"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "*#F70vsr#*"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "*#5nUJTD#*"
				return 1
			}
		done
		Txt "*#QEwsIa#*"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "*#1B6R34#*"
			return 1
		}
		Txt "*#LJZBvn#*"
		apt autoremove --purge -y || {
			Err "*#xAatkX#*"
			return 1
		}
		Txt "*#INDuUK#*"
		apt clean -y || {
			Err "*#ihctNf#*"
			return 1
		}
		Txt "*#QCt82q#*"
		apt autoclean -y || {
			Err "*#2fbDlu#*"
			return 1
		}
		;;
	*opkg)
		Txt "*#lUqsgx#*"
		rm -rf /tmp/* || {
			Err "*#w25aZG#*"
			return 1
		}
		Txt "*#aijtLE#*"
		opkg update || {
			Err "*#SaJhin#*"
			return 1
		}
		Txt "*#0aZpKD#*"
		opkg clean || {
			Err "*#lFrEyR#*"
			return 1
		}
		;;
	*pacman)
		Txt "*#GQgi8V#*"
		pacman -Syu --noconfirm || {
			Err "*#tcRKmA#*"
			return 1
		}
		Txt "*#2uQagh#*"
		pacman -Sc --noconfirm || {
			Err "*#2TzUpK#*"
			return 1
		}
		Txt "*#58ePrG#*"
		pacman -Scc --noconfirm || {
			Err "*#T7RWa1#*"
			return 1
		}
		;;
	*yum)
		Txt "*#LJZBvn#*"
		yum autoremove -y || {
			Err "*#xAatkX#*"
			return 1
		}
		Txt "*#m4FwJK#*"
		yum clean all || {
			Err "*#LpC7ga#*"
			return 1
		}
		Txt "*#OSJXqf#*"
		yum makecache || {
			Err "*#VhoD9P#*"
			return 1
		}
		;;
	*zypper)
		Txt "*#fjeLid#*"
		zypper clean --all || {
			Err "*#DfStxg#*"
			return 1
		}
		Txt "*#0YzvSd#*"
		zypper refresh || {
			Err "*#LvwKS2#*"
			return 1
		}
		;;
	*dnf)
		Txt "*#LJZBvn#*"
		dnf autoremove -y || {
			Err "*#xAatkX#*"
			return 1
		}
		Txt "*#FUdxyY#*"
		dnf clean all || {
			Err "*#MZWs40#*"
			return 1
		}
		Txt "*#4kyh2V#*"
		dnf makecache || {
			Err "*#xqIh8f#*"
			return 1
		}
		;;
	*) {
		Err "*#L5ZdVc#*"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "*#YT5eU7#*" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "*#uY17TJ#*"
			return 1
		}
	fi
	Task "*#lUqsgx#*" "rm -rf /tmp/*" || {
		Err "*#w25aZG#*"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "*#pzj8wC#*" "docker system prune -af" || {
				Err "*#InZDNA#*"
				return 1
			} ;;
			npm) Task "*#4UgGuj#*" "npm cache clean --force" || {
				Err "*#edWbLx#*"
				return 1
			} ;;
			pip) Task "*#b9G0ra#*" "pip cache purge" || {
				Err "*#lBJZtb#*"
				return 1
			} ;;
			esac
		fi
	done
	Task "*#YvhFj4#*" "rm -rf ~/.cache/*" || {
		Err "*#apoBJl#*"
		return 1
	}
	Task "*#EQLRJ4#*" "rm -rf ~/.thumbnails/*" || {
		Err "*#6oWCRN#*"
		return 1
	}
	Txt "*#06acCR#*"
	Txt "*#x17H8G#*"
}
function SysInfo() {
	Txt "*#rDT8Cx#*"
	Txt "*#06acCR#*"

	Txt "*#riIdWD#*"
	Txt "*#NzjyVD#*"
	Txt "*#o3l9B8#*"
	Txt "*#Fg86uY#*"
	Txt "*#FoqAWz#*"
	Txt "*#FSEHmk#*"
	Txt "*#SfMqhG#*"

	Txt "*#dk1Hog#*"
	Txt "*#D0GbKf#*"
	Txt "*#3MvZaG#*"
	Txt "*#2MQiql#*"
	Txt "*#OYaovQ#*"
	Txt "*#kp0LtN#*"
	Txt "*#SfMqhG#*"

	Txt "*#wv7okj#*"
	Txt "*#OJxzZ6#*"
	Txt "*#lkLPzD#*"
	Txt "*#bQ7MmO#*"
	Txt "*#SfMqhG#*"

	Txt "*#GHgp93#*"
	Txt "*#0S2MAm#*"
	Txt "*#DavdjV#*"
	Txt "*#uc5o8d#*"
	Txt "*#psK072#*"
	Txt "*#XWPmoa#*"
	Txt "*#XofKJb#*"
	Txt "*#bMZo5i#*"
	Txt "*#WUDLFp#*"
	Txt "*#SfMqhG#*"

	Txt "*#5VjE7o#*"
	Txt "*#FtZ0Cy#*"
	Txt "*#lkGB2w#*"
	Txt "*#SfMqhG#*"

	Txt "*#H0jy4o#*"
	Txt "*#5movQ0#*"
	Txt "*#SfMqhG#*"

	Txt "*#T6aHde#*"
	Txt "*#06acCR#*"
}
function SysOptz() {
	ChkRoot
	Txt "*#tS23y9#*"
	Txt "*#06acCR#*"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "*#LMicar#*" >"${sysctl_conf_SysOptimize}"

	Task "*#BJxX8f#*" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#FWJ8Vy#*"
		return 1
	}

	Task "*#OBcwWS#*" "
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
		Err "*#UtafE3#*"
		return 1
	}

	Task "*#p74CLA#*" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#5rbwUe#*"
		return 1
	}

	Task "*#jVlMQa#*" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#Pp5tmk#*"
		return 1
	}

	Task "*#9GfXBr#*" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "*#f4e1EV#*"
		return 1
	}

	Task "*#yXSCo3#*" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "*#R5LzuU#*"
		return 1
	}

	Task "*#fzea2V#*" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
		Err "*#wcGrfh#*"
		return 1
	}

	Task "*#vmAxwc#*" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "*#w3V0ph#*"
		return 1
	}

	Task "*#PgDZm4#*" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "*#5ORaVj#*"
		return 1
	}

	Txt "*#06acCR#*"
	Txt "*#x17H8G#*"
}
function SysRboot() {
	ChkRoot
	Txt "*#sECBfz#*"
	Txt "*#06acCR#*"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "*#xpiaVg#*"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "*#qj8CFi#*"
		Txt "*#AHOzUB#*"
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "*#V8vmrS#*"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "*#nZmFe4#*"
		Txt "*#nMU0eQ#*"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "*#SVAl2d#*" -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "*#0FVJwt#*"
		return 0
	}
	Task "*#9i4OUw#*" "sync" || {
		Err "*#PSwLIi#*"
		return 1
	}
	Task "*#kU7c2y#*" "reboot || sudo reboot" || {
		Err "*#lBGCEa#*"
		return 1
	}
	Txt "*#md9PEz#*"
}
function SysUpd() {
	ChkRoot
	Txt "*#DP10V4#*"
	Txt "*#06acCR#*"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="$1"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "*#ZuqMOh#*"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "*#0yQRHI#*"
			return 1
		}
		Txt "*#QIqLAH#*"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "*#vNXYU3#*"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "*#F70vsr#*" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "*#5nUJTD#*"
				return 1
			}
		done
		Task "*#QEwsIa#*" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "*#LSecUt#*"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "*#GQgi8V#*" "pacman -Syu --noconfirm" || {
		Err "*#tcRKmA#*"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "*#JzPWt5#*"
		return 1
	} ;;
	esac
	Txt "*#rjeLxl#*"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "*#uvWm4p#*"
		return 1
	}
	Txt "*#06acCR#*"
	Txt "*#x17H8G#*"
}
function SysUpg() {
	ChkRoot
	Txt "*#PqbU49#*"
	Txt "*#06acCR#*"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "*#Rzgdjc#*"
		Txt "*#ZuqMOh#*"
		apt update -y || {
			Err "*#koKvzZ#*"
			return 1
		}
		Txt "*#qZcvKd#*"
		apt full-upgrade -y || {
			Err "*#aXfDjW#*"
			return 1
		}
		Txt "*#qLxVNg#*"
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "*#A109Jk#*"
			return 1
		}
		Txt "*#FE2PGt#*"
		Task "*#6KegxR#*" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "*#WbDQ2I#*"
			return 1
		}
		Task "*#y2oJFk#*" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "*#bMNuOy#*"
			return 1
		}
		Task "*#Ck9svO#*" "apt update -y" || {
			Err "*#nVFxvJ#*"
			return 1
		}
		Task "*#yCR2qA#*" "apt full-upgrade -y" || {
			Err "*#SBu0Qa#*"
			return 1
		}
		;;
	Ubuntu)
		Txt "*#NQpb2h#*"
		Task "*#ZuqMOh#*" "apt update -y" || {
			Err "*#koKvzZ#*"
			return 1
		}
		Task "*#qZcvKd#*" "apt full-upgrade -y" || {
			Err "*#aXfDjW#*"
			return 1
		}
		Task "*#PGbrRJ#*" "apt install -y update-manager-core" || {
			Err "*#rjg4BG#*"
			return 1
		}
		Task "*#PISAvl#*" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "*#cPeHF1#*"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "*#9gAVaI#*"
		return 1
	} ;;
	esac
	Txt "*#06acCR#*"
	Txt "*#qAtyms#*"
}
function Task() {
	msg_Task="$1"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "*#js5Hyw#*"
		ret_Task=0
	else
		ret_Task=$?
		Txt "*#URehx5#*"
		[[ -s ${tmp_file_Task} ]] && Txt "*#ALsohU#*"
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
			[ -n "${data_TimeZn}" ] && Txt "*#6UBs50#*" || {
			Err "*#ADK9Bv#*"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${data_TimeZn}" ] && Txt "*#6UBs50#*" || {
			Err "*#P78zOt#*"
			return 1
		}
		;;
	esac
}
function Press() {
	read -p "$1" -n 1 -r || {
		Err "*#EmUyhn#*"
		return 1
	}
}

