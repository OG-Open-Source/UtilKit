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

function Txt() { echo -e "*#06d3730e#*" "$2"; }
function Err() {
	[ -z "*#06d3730e#*" ] && {
		Txt "*#6ade5a1b#*"
		return 1
	}
	Txt "*#5df313eb#*"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "*#06d3730e#*" | tr -d '\n')"
		Txt "*#239adc39#*" >>"${log_file_Err}" 2>/dev/null
	fi
}
function Add() {
	[ $# -eq 0 ] && {
		Err "*#e328246e#*"
		return 2
	}
	[ "*#06d3730e#*" = "-f" -o "*#06d3730e#*" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#c204991e#*"
		return 2
	}
	[ "*#06d3730e#*" = "-f" -o "*#06d3730e#*" = "-d" ] && [ "$2" = "" ] && {
		Err "*#c204991e#*"
		return 2
	}
	mod_Add="pkg"
	err_code_Add=0
	while [ $# -gt 0 ]; do
		case "*#06d3730e#*" in
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
			deb_file_Add=$(basename "*#06d3730e#*")
			Txt "*#db7f683e#*"
			Get "*#06d3730e#*"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "*#2ef6a9ff#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "*#1b45beff#*"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#026dadc9#*"
				rm -f "${deb_file_Add}"
				Txt "*#00a1ecb5#*"
			else
				Err "*#b5ac0a18#*"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "*#311c911b#*"
				[ -d "*#06d3730e#*" ] && {
					Err "*#508c93c9#*"
					err_code_Add=1
					shift
					continue
				}
				[ -f "*#06d3730e#*" ] && {
					Err "*#bf31763e#*"
					err_code_Add=1
					shift
					continue
				}
				touch "*#06d3730e#*" || {
					Err "*#1de82876#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#325e758b#*"
				Txt "*#00a1ecb5#*"
				;;
			"dir")
				Txt "*#f41b049c#*"
				[ -f "*#06d3730e#*" ] && {
					Err "*#a25d1480#*"
					err_code_Add=1
					shift
					continue
				}
				[ -d "*#06d3730e#*" ] && {
					Err "*#954165c1#*"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "*#06d3730e#*" || {
					Err "*#0a72af62#*"
					err_code_Add=1
					shift
					continue
				}
				Txt "*#96ab563c#*"
				Txt "*#00a1ecb5#*"
				;;
			"pkg")
				Txt "*#4d5a51fa#*"
				ChkRoot
				case ${PKG_MGR} in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					is_instd_Add() {
						case ${PKG_MGR} in
						apk) apk info -e "*#06d3730e#*" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "*#06d3730e#*" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "*#06d3730e#*" &>/dev/null ;;
						yum | dnf) ${PKG_MGR} list installed "*#06d3730e#*" &>/dev/null ;;
						zypper) zypper se -i -x "*#06d3730e#*" &>/dev/null ;;
						esac
					}
					inst_pkg_Add() {
						case ${PKG_MGR} in
						apk) apk update && apk add "*#06d3730e#*" ;;
						apt) apt install -y "*#06d3730e#*" ;;
						opkg) opkg update && opkg install "*#06d3730e#*" ;;
						pacman) pacman -Sy && pacman -S --noconfirm "*#06d3730e#*" ;;
						yum | dnf) ${PKG_MGR} install -y "*#06d3730e#*" ;;
						zypper) zypper refresh && zypper install -y "*#06d3730e#*" ;;
						esac
					}
					if ! is_instd_Add "*#06d3730e#*"; then
						Txt "*#0544853d#*"
						if inst_pkg_Add "*#06d3730e#*"; then
							if is_instd_Add "*#06d3730e#*"; then
								Txt "*#6333ef53#*"
								Txt "*#00a1ecb5#*"
							else
								Err "*#bfa744bc#*"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "*#bfa744bc#*"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "*#b1d73dee#*"
						Txt "*#00a1ecb5#*"
					fi
					;;
				*)
					Err "*#fdb5afa2#*"
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
		case "*#06d3730e#*" in
		-i) mod_ChkDeps="interactive" ;;
		-a) mod_ChkDeps="auto" ;;
		*)
			Err "*#77ce1b5e#*"
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
		Txt "*#1165ef02#*"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "*#a305ed44#*"
		Ask "*#911945a9#*" -n 1 cont_inst_ChkDeps
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
	case "*#06d3730e#*" in
	-v | --version)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "*#93ffb057#*" = "debian" ] && cat /etc/debian_version || Txt "*#55b40ca6#*"
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
				Err "*#4127874a#*"
				return 1
			}
		fi
		;;
	-n | --name)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			Txt "*#93ffb057#*" | sed 's/.*/\u&/'
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2 | awk '{print $1}'
		else
			{
				Err "*#d703e2a3#*"
				return 1
			}
		fi
		;;
	*)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "*#93ffb057#*" = "debian" ] && Txt "*#5c07da45#*" || Txt "*#1ff88cc0#*"
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
		else
			{
				Err "*#d703e2a3#*"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "*#ba674a23#*"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "*#0fb00c46#*"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "*#08a7f7df#*" || Txt "*#d9817ded#*" ;;
		microsoft) Txt "*#bbc2d665#*" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "*#a9ce7b73#*"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "*#d6bcda22#*"
			else
				Txt "*#377151b3#*"
			fi
			;;
		*) Txt "*#6908a88d#*" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "*#b5452d72#*" || Txt "*#9e108af5#*")
	else
		virt_typ_ChkVirt="未知"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "*#319e8928#*"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#180f3797#*"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "*#1c0992fc#*"
		return 1
	}
	Txt "*#7fd3467c#*"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "*#180f3797#*"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "*#e48fa922#*"
		return 1
	}
	Txt "*#737f56c0#*"
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
			Txt "*#822ce62b#*"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#cd5d80a5#*"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "*#cd5d80a5#*"
		return 1
	}
	curr_tot_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	curr_idle_CpuUsage=${idle_CpuUsage}
	tot_delta_CpuUsage=$((curr_tot_CpuUsage - prev_total_CpuUsage))
	idle_delta_CpuUsage=$((curr_idle_CpuUsage - prev_idle_CpuUsage))
	cpu_usage_CpuUsage=$((100 * (tot_delta_CpuUsage - idle_delta_CpuUsage) / tot_delta_CpuUsage))
	Txt "*#abdb88f5#*"
}
function ConvSz() {
	[ -z "*#06d3730e#*" ] && {
		Err "*#ec08e8fc#*"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-iB}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "*#1ba8a64a#*"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "*#278eb9b9#*"
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
		Err "*#cc6867fb#*"
		return 2
	fi
}
function Copyright() {
	Txt "*#9d24691b#*"
	Txt "*#8aace614#*"
}
function Del() {
	[ $# -eq 0 ] && {
		Err "*#dd69ccb0#*"
		return 2
	}
	[ "*#06d3730e#*" = "-f" -o "*#06d3730e#*" = "-d" ] && [ $# -eq 1 ] && {
		Err "*#c204991e#*"
		return 2
	}
	[ "*#06d3730e#*" = "-f" -o "*#06d3730e#*" = "-d" ] && [ "$2" = "" ] && {
		Err "*#c204991e#*"
		return 2
	}
	mod_Del="pkg"
	err_code_Del=0
	while [ $# -gt 0 ]; do
		case "*#06d3730e#*" in
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
				Txt "*#bc6c7e41#*"
				[ ! -f "*#06d3730e#*" ] && {
					Err "*#42e52925#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#eae1bb96#*"
				rm -f "*#06d3730e#*" || {
					Err "*#0bc853f5#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#52305304#*"
				Txt "*#00a1ecb5#*"
				;;
			"dir")
				Txt "*#01dbcdad#*"
				[ ! -d "*#06d3730e#*" ] && {
					Err "*#d179402f#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#cfad843e#*"
				rm -rf "*#06d3730e#*" || {
					Err "*#2918ec31#*"
					err_code_Del=1
					shift
					continue
				}
				Txt "*#9cfa8c67#*"
				Txt "*#00a1ecb5#*"
				;;
			"pkg")
				Txt "*#3105b315#*"
				ChkRoot
				case ${PKG_MGR} in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					is_instd_Del() {
						case ${PKG_MGR} in
						apk) apk info -e "*#06d3730e#*" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "*#06d3730e#*" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "*#06d3730e#*" &>/dev/null ;;
						yum | dnf) ${PKG_MGR} list installed "*#06d3730e#*" &>/dev/null ;;
						zypper) zypper se -i -x "*#06d3730e#*" &>/dev/null ;;
						esac
					}
					rm_pkg_Del() {
						case ${PKG_MGR} in
						apk) apk del "*#06d3730e#*" ;;
						apt) apt purge -y "*#06d3730e#*" && apt autoremove -y ;;
						opkg) opkg remove "*#06d3730e#*" ;;
						pacman) pacman -Rns --noconfirm "*#06d3730e#*" ;;
						yum | dnf) ${PKG_MGR} remove -y "*#06d3730e#*" ;;
						zypper) zypper remove -y "*#06d3730e#*" ;;
						esac
					}
					if ! is_instd_Del "*#06d3730e#*"; then
						Txt "*#cbd98a0f#*"
						Txt "*#00a1ecb5#*"
					else
						if rm_pkg_Del "*#06d3730e#*"; then
							if ! is_instd_Del "*#06d3730e#*"; then
								Txt "*#5f9c4433#*"
								Txt "*#00a1ecb5#*"
							else
								Err "*#0b0e1a1e#*"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "*#0b0e1a1e#*"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "*#fdb5afa2#*"
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
		Err "*#30806bb2#*"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "*#78b9a307#*"
		return 1
	}
	pct_DiskUsage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "*#06d3730e#*" in
	-u) Txt "*#c52f5801#*" ;;
	-t) Txt "*#43232f63#*" ;;
	-p) Txt "*#650082ed#*" ;;
	*) Txt "*#ae8cf336#*" ;;
	esac
}
function DnsAddr() {
	[ ! -f /etc/resolv.conf ] && {
		Err "*#71445036#*"
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
		Err "*#5702e01e#*"
		return 1
	}
	case "*#06d3730e#*" in
	-4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#ae140750#*"
			return 1
		}
		Txt "*#71ea4653#*"
		;;
	-6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#238d3730#*"
			return 1
		}
		Txt "*#ee23b217#*"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "*#af5ed2eb#*"
			return 1
		}
		Txt "*#e44967c4#*"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "*#d3a8ea6c#*"
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
		Err "*#22bb4447#*"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "*#ace5f8a0#*"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "*#54217be7#*"
			return 1
		}
		Txt "*#00a1ecb5#*"
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
		case "*#06d3730e#*" in
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
	Txt "*#f4706fcd#*"
}
function Format() {
	flg_Format="*#06d3730e#*"
	val_Format="$2"
	res_Format=""
	[ -z "*#c52eb213#*" ] && {
		Err "*#e679c4c4#*"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "*#08aae833#*"
		return 2
	}
	case "${flg_Format}" in
	-AA) res_Format=$(Txt "*#c52eb213#*" | tr '[:lower:]' '[:upper:]') ;;
	-aa) res_Format=$(Txt "*#c52eb213#*" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) res_Format=$(Txt "*#c52eb213#*" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) res_Format="*#c52eb213#*" ;;
	esac
	Txt "*#715267f9#*"
}
function Get() {
	unzip_Get="false"
	targ_dir_Get="."
	rnm_file_Get=""
	url_Get=""
	while [ $# -gt 0 ]; do
		case "*#06d3730e#*" in
		-x)
			unzip_Get=true
			shift
			;;
		-r)
			[ -z "$2" ] || [[ $2 == -* ]] && {
				Err "*#bba73100#*"
				return 2
			}
			rnm_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "*#77ce1b5e#*"
			return 2
		} ;;
		*)
			[ -z "*#93fc1d70#*" ] && url_Get="*#06d3730e#*" || targ_dir_Get="*#06d3730e#*"
			shift
			;;
		esac
	done
	[ -z "*#93fc1d70#*" ] && {
		Err "*#ff00c106#*"
		return 2
	}
	[[ ${url_Get} =~ ^(http|https|ftp):// ]] || url_Get="https://${url_Get}"
	oup_file_Get="${url_Get##*/}"
	[ -z "${oup_file_Get}" ] && oup_file_Get="index.html"
	[ "${targ_dir_Get}" != "." ] && { mkdir -p "${targ_dir_Get}" || {
		Err "*#0d5beff1#*"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && oup_file_Get="${rnm_file_Get}"
	oup_path_Get="${targ_dir_Get}/${oup_file_Get}"
	url_Get=$(Txt "*#93fc1d70#*" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "*#2698a95e#*"
	file_sz_Get=$(curl -sI "*#93fc1d70#*" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "*#93fc1d70#*" -O "${oup_path_Get}" || {
			Err "*#ea1441f6#*"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "*#93fc1d70#*" -o "${oup_path_Get}" || {
			Err "*#fdc6d9f6#*"
			return 1
		}
	fi
	if [ -f "${oup_path_Get}" ]; then
		Txt "*#4fca41b3#*"
		if [ "${unzip_Get}" = true ]; then
			case "${oup_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#77821272#*"
				return 1
			} ;;
			*.tar) tar -xf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#eb347b2e#*"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#649d6f02#*"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${oup_path_Get}" -C "${targ_dir_Get}" || {
				Err "*#e3fe105b#*"
				return 1
			} ;;
			*.zip) unzip "${oup_path_Get}" -d "${targ_dir_Get}" || {
				Err "*#61a6e7ff#*"
				return 1
			} ;;
			*.7z) 7z x "${oup_path_Get}" -o"${targ_dir_Get}" || {
				Err "*#e3b03fcf#*"
				return 1
			} ;;
			*.rar) unrar x "${oup_path_Get}" "${targ_dir_Get}" || {
				Err "*#4b6582b3#*"
				return 1
			} ;;
			*.zst) zstd -d "${oup_path_Get}" -o "${targ_dir_Get}" || {
				Err "*#869161b3#*"
				return 1
			} ;;
			*) Txt "*#d17f44a7#*" ;;
			esac
			[ $? -eq 0 ] && Txt "*#2829cd86#*"
		fi
		Txt "*#00a1ecb5#*"
	else
		{
			Err "*#789d7f3b#*"
			return 1
		}
	fi
}
function Ask() {
	prompt_msg_Ask="*#06d3730e#*"
	shift
	read -e -p "$prompt_msg_Ask" -r "$@" || {
		Err "*#0cc80919#*"
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
		Err "*#5b7f41e5#*"
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
		item_Iface="*#06d3730e#*"
		shift
		arr_Iface=("$@")
		for ((i = 1; i <= ${#arr_Iface[@]}; i++)); do
			if [ "${item_Iface}" = "${arr_Iface[$i]}" ]; then
				Txt "*#a16d2280#*"
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
		interface_Iface=$(Txt "*#606b15df#*" | tr -s ' ' | xargs)
	else
		physical_iface_Iface=$(ip -o link show | grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | grep 'state UP' | head -n 1 | awk -F': ' '{print $2}')
		if [ -n "${physical_iface_Iface}" ]; then
			interface_Iface="${physical_iface_Iface}"
		else
			interface_Iface=$(ip -o link show | grep -v 'lo:' | head -n 1 | awk -F': ' '{print $2}')
		fi
	fi
	case "*#06d3730e#*" in
	--rx_bytes | --rx_packets | --rx_drop | --tx_bytes | --tx_packets | --tx_drop)
		for iface_Iface in ${interface_Iface}; do
			if stats_Iface=$(awk -v iface="${iface_Iface}" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes_Iface rx_packets_Iface rx_drop_Iface tx_bytes_Iface tx_packets_Iface tx_drop_Iface <<<"${stats_Iface}"
				case "*#06d3730e#*" in
				--rx_bytes)
					Txt "*#7006bdd8#*"
					break
					;;
				--rx_packets)
					Txt "*#5a485ab3#*"
					break
					;;
				--rx_drop)
					Txt "*#52b9f2ab#*"
					break
					;;
				--tx_bytes)
					Txt "*#444c521d#*"
					break
					;;
				--tx_packets)
					Txt "*#8331f883#*"
					break
					;;
				--tx_drop)
					Txt "*#c79672a7#*"
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
				Txt "*#49d9af89#*"
			fi
		done
		;;
	*) Txt "*#606b15df#*" ;;
	esac
}
function IpAddr() {
	flg_IpAddr="*#06d3730e#*"
	case "${flg_IpAddr}" in
	-4 | --ipv4)
		ipv4_addr_IpAddr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr_IpAddr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "*#2f10d152#*" ] && Txt "*#2f10d152#*" || {
			Err "*#0423fbf2#*"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "*#ebfa0e8c#*" ] && Txt "*#ebfa0e8c#*" || {
			Err "*#0d7a61c6#*"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "*#038f0ec8#*"
			return 1
		}
		[ -n "*#2f10d152#*" ] && Txt "*#5d179ea0#*"
		[ -n "*#ebfa0e8c#*" ] && Txt "*#f6c184c5#*"
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
	[ -z "*#c61a4918#*" ] && {
		Err "*#7040de29#*"
		return 1
	} || Txt "*#c61a4918#*"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "*#5ea39da5#*"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "*#ac9d854b#*"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "*#f018e3ec#*"
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
	[ -n "*#93ea94bd#*" ] && Txt "*#93ea94bd#*" || {
		Err "*#5d50fd32#*"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "*#dbc7afec#*" || {
		Err "*#d04c71eb#*"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "*#5258e7cf#*"
		return 1
	}
	tot_MemUsage=$(free -b | awk '/^Mem:/ {print $2}') || tot_MemUsage=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct_MemUsage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct_MemUsage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "*#06d3730e#*" in
	-u) Txt "*#f544f757#*" ;;
	-t) Txt "*#abd3784b#*" ;;
	-p) Txt "*#7abfb7ae#*" ;;
	*) Txt "*#328e6932#*" ;;
	esac
}
function NetProv() {
	data_NetProv=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data_NetProv=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "*#30750776#*" ] && Txt "*#30750776#*" || {
		Err "*#4b75df70#*"
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
		Err "*#6c0f7fb2#*"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "*#326cb1b5#*"
			return 1
		}
	fi
	Txt "*#07ec7904#*"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "*#dfc2d2ed#*"
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
			Txt "*#6121a672#*"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "*#e9030b4b#*"
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
	[ -n "*#e5a787af#*" ] && Txt "*#e5a787af#*" || {
		Err "*#8f392f02#*"
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
		Err "*#2399e25d#*"
		return 2
	}
	if [[ $1 == *"/"* ]]; then
		if [[ $1 =~ ^https?:// ]]; then
			url_Run="*#06d3730e#*"
			script_nm_Run=$(basename "*#06d3730e#*")
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "*#06d3730e#*" in
				-d)
					rm_aftr_Run=true
					shift
					;;
				*) break ;;
				esac
			done
			Txt "*#c4740284#*"
			Task "*#8159291c#*" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "*#834d7c2a#*"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "*#84904664#*"; return 1; }
			"
			Txt "*#f04b868b#*"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "*#d12fea31#*"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "*#d12fea31#*"
					return 1
				}
			fi
			Txt "*#f04b868b#*"
			Txt "*#00a1ecb5#*"
			[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
		elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner_Run=$(Txt "*#06d3730e#*" | cut -d'/' -f1)
			repo_name_Run=$(Txt "*#06d3730e#*" | cut -d'/' -f2)
			script_path_Run=$(Txt "*#06d3730e#*" | cut -d'/' -f3-)
			script_nm_Run=$(basename "${script_path_Run}")
			branch_Run="main"
			dnload_repo_Run=false
			rm_aftr_Run=false
			shift
			while [[ $# -gt 0 && $1 == -* ]]; do
				case "*#06d3730e#*" in
				-b | --branch)
					[[ -z $2 || $2 == -* ]] && {
						Err "*#6d26fc9a#*"
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
				Txt "*#7af4d7c2#*"
				[[ -d ${repo_name_Run} ]] && {
					Err "*#c31b92fe#*"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#29e43e6d#*" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "*#e3db3752#*"
							return 1
						}
					fi
				else
					Task "*#d6835be2#*" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "*#53e2acb6#*" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "*#3a14a3ae#*"
								return 1
							}
						fi
					fi
				fi
				Task "*#e68ee68a#*" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "*#f3000db7#*" "rm -rf "${tmp_dir_Run}""
				Txt "*#de8883e5#*"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "*#c2b0357b#*" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "*#f04b868b#*"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "*#d12fea31#*"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "*#d12fea31#*"
							return 1
						}
					fi
					Txt "*#f04b868b#*"
					Txt "*#00a1ecb5#*"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "*#a86ac78e#*"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "*#0fbf0a85#*" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "*#ed0ac386#*"
						return 1
					}
				else
					Task "*#d6835be2#*" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "*#73f4b9e8#*" "
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
				Task "*#8159291c#*" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || {
						Err "*#834d7c2a#*"
						Err "*#f9876397#*"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "*#9e23a153#*"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "*#33ac860c#*"
						cat "${script_nm_Run}" 2>/dev/null || Txt "*#303e9430#*"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "*#0329b080#*"
						return 1
					fi
					chmod +x "${script_nm_Run}" || {
						Err "*#84904664#*"
						Err "*#1cc453a9#*"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "*#f04b868b#*"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "*#d12fea31#*"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "*#d12fea31#*"
							return 1
						}
					fi
				else
					Err "*#d470fcb4#*"
					return 1
				fi
				Txt "*#f04b868b#*"
				Txt "*#00a1ecb5#*"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "*#06d3730e#*" ] || chmod +x "*#06d3730e#*"
			script_path_Run="*#06d3730e#*"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "*#d12fea31#*"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "*#d12fea31#*"
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
		Txt "*#bbc43288#*"
	elif [ -n "${ZSH_VERSION-}" ]; then
		Txt "*#f0ef20f8#*"
	else
		{
			Err "*#6c4083a9#*"
			return 1
		}
	fi
}
function SwapUsage() {
	usd_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	tot_SwapUsage=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	pct_SwapUsage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "*#06d3730e#*" in
	-u) Txt "*#3d1609ce#*" ;;
	-t) Txt "*#af757bdf#*" ;;
	-p) Txt "*#d61ce802#*" ;;
	*) Txt "*#fc20f0d7#*" ;;
	esac
}
function SysClean() {
	ChkRoot
	Txt "*#326f9977#*"
	Txt "*#f04b868b#*"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "*#d6b490c8#*"
		apk cache clean || {
			Err "*#9b4f9cf6#*"
			return 1
		}
		Txt "*#bf22b2f9#*"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "*#5a06ca00#*"
			return 1
		}
		Txt "*#2bd53981#*"
		apk fix || {
			Err "*#58e1ba44#*"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "*#ef808281#*"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "*#9f81bd3d#*"
				return 1
			}
		done
		Txt "*#61000812#*"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "*#d59ca489#*"
			return 1
		}
		Txt "*#04f8e791#*"
		apt autoremove --purge -y || {
			Err "*#5d5ef825#*"
			return 1
		}
		Txt "*#497f673a#*"
		apt clean -y || {
			Err "*#80698b1d#*"
			return 1
		}
		Txt "*#cecd3c8a#*"
		apt autoclean -y || {
			Err "*#a630ee0a#*"
			return 1
		}
		;;
	*opkg)
		Txt "*#bf22b2f9#*"
		rm -rf /tmp/* || {
			Err "*#5a06ca00#*"
			return 1
		}
		Txt "*#37c9dcd7#*"
		opkg update || {
			Err "*#38e9d4e2#*"
			return 1
		}
		Txt "*#74a51e77#*"
		opkg clean || {
			Err "*#cc5299b8#*"
			return 1
		}
		;;
	*pacman)
		Txt "*#ad4079d3#*"
		pacman -Syu --noconfirm || {
			Err "*#0a310a9d#*"
			return 1
		}
		Txt "*#34afd401#*"
		pacman -Sc --noconfirm || {
			Err "*#975e881c#*"
			return 1
		}
		Txt "*#f97db81c#*"
		pacman -Scc --noconfirm || {
			Err "*#7ffa6771#*"
			return 1
		}
		;;
	*yum)
		Txt "*#04f8e791#*"
		yum autoremove -y || {
			Err "*#5d5ef825#*"
			return 1
		}
		Txt "*#325b8187#*"
		yum clean all || {
			Err "*#c0d3b8c0#*"
			return 1
		}
		Txt "*#4f712445#*"
		yum makecache || {
			Err "*#fda5d97c#*"
			return 1
		}
		;;
	*zypper)
		Txt "*#da7d292c#*"
		zypper clean --all || {
			Err "*#a92f7771#*"
			return 1
		}
		Txt "*#22de019e#*"
		zypper refresh || {
			Err "*#369682dd#*"
			return 1
		}
		;;
	*dnf)
		Txt "*#04f8e791#*"
		dnf autoremove -y || {
			Err "*#5d5ef825#*"
			return 1
		}
		Txt "*#ea65c1a1#*"
		dnf clean all || {
			Err "*#838d5a91#*"
			return 1
		}
		Txt "*#13bb4ed7#*"
		dnf makecache || {
			Err "*#65656035#*"
			return 1
		}
		;;
	*) {
		Err "*#3c3d4210#*"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "*#f08daebe#*" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "*#2c5427ed#*"
			return 1
		}
	fi
	Task "*#bf22b2f9#*" "rm -rf /tmp/*" || {
		Err "*#5a06ca00#*"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "*#272f7fb5#*" "docker system prune -af" || {
				Err "*#20e9e2fd#*"
				return 1
			} ;;
			npm) Task "*#4f02f369#*" "npm cache clean --force" || {
				Err "*#fdfc1360#*"
				return 1
			} ;;
			pip) Task "*#80809eda#*" "pip cache purge" || {
				Err "*#49ead4af#*"
				return 1
			} ;;
			esac
		fi
	done
	Task "*#fe48837d#*" "rm -rf ~/.cache/*" || {
		Err "*#d85f4153#*"
		return 1
	}
	Task "*#7f9f7f94#*" "rm -rf ~/.thumbnails/*" || {
		Err "*#00451a04#*"
		return 1
	}
	Txt "*#f04b868b#*"
	Txt "*#00a1ecb5#*"
}
function SysInfo() {
	Txt "*#86bc12bf#*"
	Txt "*#f04b868b#*"
	Txt "*#d8c03ddb#*"
	Txt "*#e6e96e99#*"
	Txt "*#90a61a96#*"
	Txt "*#baab44df#*"
	Txt "*#ca6358c7#*"
	Txt "*#d564cf00#*"
	Txt "*#0d430fe6#*"
	Txt "*#c6471f29#*"
	Txt "*#19dfe3b4#*"
	Txt "*#8f465f1b#*"
	Txt "*#f882046a#*"
	Txt "*#030e571c#*"
	Txt "*#cad757bd#*"
	Txt "*#0d430fe6#*"
	Txt "*#4f3998df#*"
	Txt "*#59affb53#*"
	Txt "*#217f11e6#*"
	Txt "*#08877dd4#*"
	Txt "*#0d430fe6#*"
	Txt "*#30b11a19#*"
	Txt "*#3ebd6fd6#*"
	Txt "*#891947ac#*"
	Txt "*#419569eb#*"
	Txt "*#16cd328d#*"
	Txt "*#f7566e5f#*"
	Txt "*#8a6feb6a#*"
	Txt "*#ea6a8162#*"
	Txt "*#c580aa75#*"
	Txt "*#0d430fe6#*"
	Txt "*#2a930793#*"
	Txt "*#48691ca9#*"
	Txt "*#143e4e0c#*"
	Txt "*#0d430fe6#*"
	Txt "*#b8b39456#*"
	Txt "*#d54cc1e9#*"
	Txt "*#0d430fe6#*"
	Txt "*#96f87804#*"
	Txt "*#f04b868b#*"
}
function SysOptz() {
	ChkRoot
	Txt "*#b6ff6922#*"
	Txt "*#f04b868b#*"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "*#4dd2fd44#*" >"${sysctl_conf_SysOptimize}"
	Task "*#aa315aa4#*" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#c5d855d8#*"
		return 1
	}
	Task "*#77c1d67a#*" "
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
		Err "*#c537a024#*"
		return 1
	}
	Task "*#b4555a48#*" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#06963405#*"
		return 1
	}
	Task "*#f1b59a08#*" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "*#2204219f#*"
		return 1
	}
	Task "*#e36f4e6b#*" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "*#44a53c26#*"
		return 1
	}
	Task "*#f68160b9#*" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "*#002fb94a#*"
		return 1
	}
	Task "*#6cd7c632#*" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
		Err "*#e67980ca#*"
		return 1
	}
	Task "*#464e4abc#*" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "*#49c0329b#*"
		return 1
	}
	Task "*#78b0bf33#*" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "*#981f3711#*"
		return 1
	}
	Txt "*#f04b868b#*"
	Txt "*#00a1ecb5#*"
}
function SysRboot() {
	ChkRoot
	Txt "*#766dd107#*"
	Txt "*#f04b868b#*"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "*#308414c3#*"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "*#a5d133bd#*"
		Txt "*#037ca788#*"
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "*#09dea842#*"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "*#14a455b6#*"
		Txt "*#507f4385#*"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "*#dc6209ac#*" -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "*#7df6b754#*"
		return 0
	}
	Task "*#7fd2f7c4#*" "sync" || {
		Err "*#10e9f44b#*"
		return 1
	}
	Task "*#423319ef#*" "reboot || sudo reboot" || {
		Err "*#8a0c01c9#*"
		return 1
	}
	Txt "*#4d788042#*"
}
function SysUpd() {
	ChkRoot
	Txt "*#1d3db136#*"
	Txt "*#f04b868b#*"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="*#06d3730e#*"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "*#f90c9b7d#*"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "*#b1127232#*"
			return 1
		}
		Txt "*#b5651c8c#*"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "*#7f171fba#*"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "*#ef808281#*" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "*#9f81bd3d#*"
				return 1
			}
		done
		Task "*#61000812#*" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "*#47ac2276#*"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "*#ad4079d3#*" "pacman -Syu --noconfirm" || {
		Err "*#0a310a9d#*"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "*#6097d1f8#*"
		return 1
	} ;;
	esac
	Txt "*#993faf8f#*"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "*#d56016d7#*"
		return 1
	}
	Txt "*#f04b868b#*"
	Txt "*#00a1ecb5#*"
}
function SysUpg() {
	ChkRoot
	Txt "*#78db8481#*"
	Txt "*#f04b868b#*"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "*#1ebb8524#*"
		Txt "*#f90c9b7d#*"
		apt update -y || {
			Err "*#94fc6935#*"
			return 1
		}
		Txt "*#812974f1#*"
		apt full-upgrade -y || {
			Err "*#cf6f0082#*"
			return 1
		}
		Txt "*#584eb0a5#*"
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "*#7b2c9a1b#*"
			return 1
		}
		Txt "*#c81acd6a#*"
		Task "*#53f141cb#*" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "*#0d70fa31#*"
			return 1
		}
		Task "*#28e2b984#*" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "*#d32a9e1b#*"
			return 1
		}
		Task "*#5d46232e#*" "apt update -y" || {
			Err "*#8f408d0c#*"
			return 1
		}
		Task "*#fc5972e4#*" "apt full-upgrade -y" || {
			Err "*#52757d2a#*"
			return 1
		}
		;;
	Ubuntu)
		Txt "*#422098f6#*"
		Task "*#f90c9b7d#*" "apt update -y" || {
			Err "*#94fc6935#*"
			return 1
		}
		Task "*#812974f1#*" "apt full-upgrade -y" || {
			Err "*#cf6f0082#*"
			return 1
		}
		Task "*#8f56686b#*" "apt install -y update-manager-core" || {
			Err "*#e5db6f65#*"
			return 1
		}
		Task "*#67bec312#*" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "*#9cbe8092#*"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "*#b03442f2#*"
		return 1
	} ;;
	esac
	Txt "*#f04b868b#*"
	Txt "*#18631ecd#*"
}
function Task() {
	msg_Task="*#06d3730e#*"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "*#d57979d2#*"
		ret_Task=0
	else
		ret_Task=$?
		Txt "*#ce3287ab#*"
		[[ -s ${tmp_file_Task} ]] && Txt "*#b499955d#*"
		[[ ${ign_err_Task} != "true" ]] && return "${ret_Task}"
	fi
	rm -f "${tmp_file_Task}"
	return "${ret_Task}"
}
function TimeZn() {
	case "*#06d3730e#*" in
	-e | --external)
		data_TimeZn=$(timeout 1s curl -sL ipapi.co/timezone) ||
			data_TimeZn=$(timeout 1s curl -sL worldtimeapi.org/api/ip | grep -oP '"timezone":"\K[^"]+') ||
			data_TimeZn=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"timezone":"\K[^"]+') ||
			[ -n "*#348e4b28#*" ] && Txt "*#348e4b28#*" || {
			Err "*#e14fb233#*"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "*#348e4b28#*" ] && Txt "*#348e4b28#*" || {
			Err "*#da544d6c#*"
			return 1
		}
		;;
	esac
}
function Press() {
	read -p "*#06d3730e#*" -n 1 -r || {
		Err "*#0cc80919#*"
		return 1
	}
}
