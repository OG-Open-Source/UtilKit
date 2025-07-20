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
		Txt "${CLR1}未知錯誤${CLR0}"
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
		Err "未指定要新增的項目。請提供至少一個要新增的項目"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "-f 或 -d 後未指定檔案或目錄路徑"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "-f 或 -d 後未指定檔案或目錄路徑"
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
			Txt "${CLR3}安裝 DEB 套件［${deb_file_Add}］${CLR0}\n"
			Get "$1"
			if [ -f "${deb_file_Add}" ]; then
				dpkg -i "${deb_file_Add}" || {
					Err "安裝 ${deb_file_Add} 失敗。請檢查套件相容性和相依性\n"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "修復相依性失敗"
					rm -f "${deb_file_Add}"
					err_code_Add=1
					shift
					continue
				}
				Txt "* DEB 套件 ${deb_file_Add} 安裝成功"
				rm -f "${deb_file_Add}"
				Txt "${CLR2}完成${CLR0}\n"
			else
				Err "找不到 DEB 套件 ${deb_file_Add} 或下載失敗\n"
				err_code_Add=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "${mod_Add}" in
			"file")
				Txt "${CLR3}新增檔案［$1］${CLR0}"
				[ -d "$1" ] && {
					Err "目錄 $1 已存在。無法建立同名檔案\n"
					err_code_Add=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "檔案 $1 已存在\n"
					err_code_Add=1
					shift
					continue
				}
				touch "$1" || {
					Err "建立檔案 $1 失敗。請檢查權限和磁碟空間\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* 檔案 $1 建立成功"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"dir")
				Txt "${CLR3}新增目錄［$1］${CLR0}"
				[ -f "$1" ] && {
					Err "檔案 $1 已存在。無法建立同名目錄\n"
					err_code_Add=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "目錄 $1 已存在\n"
					err_code_Add=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "建立目錄 $1 失敗。請檢查權限和路徑有效性\n"
					err_code_Add=1
					shift
					continue
				}
				Txt "* 目錄 $1 建立成功"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"pkg")
				Txt "${CLR3}安裝套件［$1］${CLR0}"
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
						Txt "* 套件 $1 尚未安裝"
						if inst_pkg_Add "$1"; then
							if is_instd_Add "$1"; then
								Txt "* 套件 $1 安裝成功"
								Txt "${CLR2}完成${CLR0}\n"
							else
								Err "使用 ${PKG_MGR} 安裝 $1 失敗\n"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "使用 ${PKG_MGR} 安裝 $1 失敗\n"
							err_code_Add=1
							shift
							continue
						fi
					else
						Txt "* 套件 $1 已經安裝"
						Txt "${CLR2}完成${CLR0}\n"
					fi
					;;
				*)
					Err "不支援的套件管理器\n"
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
			Err "無效的選項：$1"
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
		Txt "${status}\t${dep_ChkDeps}"
	done
	[[ ${#missg_deps_ChkDeps[@]} -eq 0 ]] && return 0
	case "${mod_ChkDeps}" in
	"interactive")
		Txt "\n${CLR3}缺少的套件：${CLR0} ${missg_deps_ChkDeps[*]}"
		Ask "是否要安裝缺少的套件？(y/N) " -n 1 cont_inst_ChkDeps
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
				Err "未知的發行版本"
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
				Err "未知的發行版"
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
				Err "未知的發行版"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "${EUID}" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "請以 root 使用者執行此腳本"
		exit 1
	fi
}
function ChkVirt() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_typ_ChkVirt=$(systemd-detect-virt 2>/dev/null)
		[ -z "${virt_typ_ChkVirt}" ] && {
			Err "無法偵測虛擬化環境"
			return 1
		}
		case "${virt_typ_ChkVirt}" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && Txt "Proxmox VE (KVM)" || Txt "KVM" ;;
		microsoft) Txt "Microsoft Hyper-V" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				Txt "LXC 容器"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				Txt "虛擬機器（未知類型）"
			else
				Txt "未偵測到（可能為實體機器）"
			fi
			;;
		*) Txt "${virt_typ_ChkVirt:-未偵測到（可能為實體機器）}" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_typ_ChkVirt=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "虛擬機器" || Txt "無")
	else
		virt_typ_ChkVirt="未知"
	fi
}
function Clear() {
	targ_dir_Clear="${1:-${HOME}}"
	cd "${targ_dir_Clear}" || {
		Err "切換目錄失敗"
		return 1
	}
	clear
}
function CpuCache() {
	[ ! -f /proc/cpuinfo ] && {
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用"
		return 1
	}
	cpu_cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cpu_cache_CpuCache}" = "N/A" ] && {
		Err "無法確定 CPU 快取大小"
		return 1
	}
	Txt "${cpu_cache_CpuCache} KB"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用"
		return 1
	}
	cpu_freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${cpu_freq_CpuFreq}" = "N/A" ] && {
		Err "無法確定 CPU 頻率"
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
			Txt "${CLR1}未知${CLR0}"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "從 /proc/stat 讀取 CPU 統計資料失敗"
		return 1
	}
	prev_total_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idle_CpuUsage + iowait_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	prev_idle_CpuUsage=${idle_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idle_CpuUsage iowait_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "從 /proc/stat 讀取 CPU 統計資料失敗"
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
		Err "未提供要轉換的大小值"
		return 2
	}
	size_ConvSz=$1
	unit_ConvSz=${2:-iB}
	if ! [[ ${size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		Err "無效的大小值。必須為數值"
		return 2
	elif [[ ${size_ConvSz} =~ ^[-].*$ ]]; then
		Err "大小值不能為負數"
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
		Err "不支持的單位：${unit_ConvSz}"
		return 2
	fi
}
function Copyright() {
	Txt "${SCRIPTS} ${VERSION}"
	Txt "Copyright (C) $(date +%Y) ${ANTHORS}."
}
function Del() {
	[ $# -eq 0 ] && {
		Err "未指定要刪除的項目。請提供至少一個要刪除的項目"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		Err "-f 或 -d 後未指定檔案或目錄路徑"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		Err "-f 或 -d 後未指定檔案或目錄路徑"
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
				Txt "${CLR3}刪除檔案［$1］${CLR0}"
				[ ! -f "$1" ] && {
					Err "檔案 $1 不存在\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 檔案 $1 存在"
				rm -f "$1" || {
					Err "刪除檔案 $1 失敗\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 檔案 $1 刪除成功"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"dir")
				Txt "${CLR3}刪除目錄［$1］${CLR0}"
				[ ! -d "$1" ] && {
					Err "目錄 $1 不存在\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 目錄 $1 存在"
				rm -rf "$1" || {
					Err "刪除目錄 $1 失敗\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 目錄 $1 刪除成功"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"pkg")
				Txt "${CLR3}移除套件［$1］${CLR0}"
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
						Txt "* 套件 $1 不存在"
						Txt "${CLR2}完成${CLR0}\n"
					else
						if rm_pkg_Del "$1"; then
							if ! in_instd_Del "$1"; then
								Txt "* 套件 $1 移除成功"
								Txt "${CLR2}完成${CLR0}\n"
							else
								Err "使用 ${PKG_MGR} 移除 $1 失敗\n"
								err_code_Del=1
								shift
								continue
							fi
						else
							Err "使用 ${PKG_MGR} 移除 $1 失敗\n"
							err_code_Del=1
							shift
							continue
						fi
					fi
					;;
				*)
					Err "不支援的套件管理器\n"
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
		Err "取得磁碟使用統計資料失敗"
		return 1
	}
	tot_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "取得總磁碟空間失敗"
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
		Err "找不到 DNS 設定檔 /etc/resolv.conf"
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
		Err "/etc/resolv.conf 中未設定 DNS 伺服器"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 ] && {
			Err "找不到 IPv4 DNS 伺服器"
			return 1
		}
		Txt "${ipv4_servers_DnsAddr[*]}"
		;;
	-6)
		[ ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "找不到 IPv6 DNS 伺服器"
			return 1
		}
		Txt "${ipv6_servers_DnsAddr[*]}"
		;;
	*)
		[ ${#ipv4_servers_DnsAddr[@]} -eq 0 -a ${#ipv6_servers_DnsAddr[@]} -eq 0 ] && {
			Err "找不到 DNS 伺服器"
			return 1
		}
		Txt "${ipv4_servers_DnsAddr[*]}   ${ipv6_servers_DnsAddr[*]}"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "未指定搜尋條件。請指定要搜尋的內容"
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
		Err "找不到或不支援的套件管理器"
		return 1
	} ;;
	esac
	for targ_Find in "$@"; do
		Txt "${CLR3}搜尋［${targ_Find}］${CLR0}"
		${srch_cmd_Find} "${targ_Find}" || {
			Err "找不到 ${targ_Find} 的結果\n"
			return 1
		}
		Txt "${CLR2}完成${CLR0}\n"
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
		Err "未提供要格式化的值"
		return 2
	}
	[ -z "${flg_Format}" ] && {
		Err "未提供格式化選項"
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
				Err "-r 選項後未指定檔案名稱"
				return 2
			}
			rnm_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "無效的選項：$1"
			return 2
		} ;;
		*)
			[ -z "${url_Get}" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "${url_Get}" ] && {
		Err "未指定 URL。請提供要下載的 URL"
		return 2
	}
	[[ ${url_Get} =~ ^(http|https|ftp):// ]] || url_Get="https://${url_Get}"
	ou_file_Get="${url_Get##*/}"
	[ -z "${ou_file_Get}" ] && ou_file_Get="index.html"
	[ "${targ_dir_Get}" != "." ] && { mkdir -p "${targ_dir_Get}" || {
		Err "建立目錄 ${targ_dir_Get} 失敗"
		return 1
	}; }
	[ -n "${rnm_file_Get}" ] && ou_file_Get="${rnm_file_Get}"
	ou_path_Get="${targ_dir_Get}/${ou_file_Get}"
	url_Get=$(Txt "${url_Get}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR3}下載［${url_Get}］${CLR0}"
	file_sz_Get=$(curl -sI "${url_Get}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_sz_Get}" ] && [ "${file_sz_Get}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url_Get}" -O "${ou_path_Get}" || {
			Err "使用 Wget 下載檔案失敗"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url_Get}" -o "${ou_path_Get}" || {
			Err "使用 cUrl 下載檔案失敗"
			return 1
		}
	fi
	if [ -f "${ou_path_Get}" ]; then
		Txt "* 檔案成功下載至 ${ou_path_Get}"
		if [ "${unzip_Get}" = true ]; then
			case "${ou_file_Get}" in
			*.tar.gz | *.tgz) tar -xzf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "解壓縮 tar.gz 檔案失敗"
				return 1
			} ;;
			*.tar) tar -xf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "解壓縮 tar 檔案失敗"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "解壓縮 tar.bz2 檔案失敗"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${ou_path_Get}" -C "${targ_dir_Get}" || {
				Err "解壓縮 tar.xz 檔案失敗"
				return 1
			} ;;
			*.zip) unzip "${ou_path_Get}" -d "${targ_dir_Get}" || {
				Err "解壓縮 zip 檔案失敗"
				return 1
			} ;;
			*.7z) 7z x "${ou_path_Get}" -o"${targ_dir_Get}" || {
				Err "解壓縮 7z 檔案失敗"
				return 1
			} ;;
			*.rar) unrar x "${ou_path_Get}" "${targ_dir_Get}" || {
				Err "解壓縮 rar 檔案失敗"
				return 1
			} ;;
			*.zst) zstd -d "${ou_path_Get}" -o "${targ_dir_Get}" || {
				Err "解壓縮 zst 檔案失敗"
				return 1
			} ;;
			*) Txt "* 無法識別的檔案格式，不進行自動解壓縮" ;;
			esac
			[ $? -eq 0 ] && Txt "* 檔案成功解壓縮至 ${targ_dir_Get}"
		fi
		Txt "${CLR2}完成${CLR0}\n"
	else
		{
			Err "下載失敗。請檢查網路連線和 URL 有效性"
			return 1
		}
	fi
}
function Ask() {
	read -e -p "$1" -r $2 || {
		Err "讀取使用者輸入失敗"
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
		Err "從 /proc/net/dev 取得網路介面失敗"
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
				Txt "${iface_Iface}: 輸入: $(ConvSz ${rx_bytes_Iface}), 輸出: $(ConvSz ${tx_bytes_Iface})"
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
			Err "取得 IPv4 位址失敗。請檢查網路連線"
			return 1
		}
		;;
	-6 | --ipv6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "${ipv6_addr_IpAddr}" || {
			Err "取得 IPv6 位址失敗。請檢查網路連線"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr --ipv4)
		ipv6_addr_IpAddr=$(IpAddr --ipv6)
		[ -z "${ipv4_addr_IpAddr}${ipv6_addr_IpAddr}" ] && {
			Err "取得 IP 位址失敗"
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
		Err "無法確定最後系統更新時間。找不到更新日誌"
		return 1
	} || Txt "${data_LastUpd}"
}
function Linet() {
	chr_Linet="${1:--}"
	len_Linet="${2:-80}"
	printf '%*s\n' "${len_Linet}" | tr ' ' "${chr_Linet}" || {
		Err "打印線條失敗"
		return 1
	}
}
function LoadAvg() {
	if [ ! -f /proc/loadavg ]; then
		data_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "從 uptime 指令取得負載平均值失敗"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${data_LoadAvg}"
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "從 /proc/loadavg 讀取負載平均值失敗"
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
		Err "無法偵測地理位置。請檢查網路連線"
		return 1
	}
}
function MacAddr() {
	data_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${data_MacAddr} ]] && Txt "${data_MacAddr}" || {
		Err "無法取得 MAC 位址。找不到網路介面"
		return 1
	}
}
function MemUsage() {
	usd_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || usd_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "取得記憶體使用統計資料失敗"
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
		Err "無法偵測網路供應商。請檢查網路連線"
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
		Err "無法計算已安裝的套件。軟體包管理器不支援"
		return 1
	} ;;
	esac
	if ! data_PkgCnt=$("${cnt_cmd_PkgCnt}" 2>/dev/null | wc -l) || [[ -z ${data_PkgCnt} || ${data_PkgCnt} -eq 0 ]]; then
		{
			Err "計算 ${PKG_MGR} 的套件數量失敗"
			return 1
		}
	fi
	Txt "${data_PkgCnt}"
}
function Prog() {
	num_cmds_Prog=${#cmds[@]}
	term_wid_Prog=$(tput cols) || {
		Err "取得終端機寬度失敗"
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
			Txt "\n${cmd_ou_Prog}"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "命令執行失敗：${cmds[$i]}"
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
		Err "無法偵測公開 IP 位址。請檢查網路連線"
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
		Err "未指定命令"
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
			Txt "${CLR3}正在從 URL 下載並執行腳本 [${script_nm_Run}]${CLR0}"
			Task "* 下載腳本" "
				curl -sSLf "${url_Run}" -o "${script_nm_Run}" || { Err "下載腳本 ${script_nm_Run} 失敗"; return 1; }
				chmod +x "${script_nm_Run}" || { Err "設定腳本 ${script_nm_Run} 執行權限失敗"; return 1; }
			"
			Txt "${CLR8}$(Linet = 24)${CLR0}"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_nm_Run}" "$@" || {
					Err "執行腳本 ${script_nm_Run} 失敗"
					return 1
				}
			else
				./"${script_nm_Run}" || {
					Err "執行腳本 ${script_nm_Run} 失敗"
					return 1
				}
			fi
			Txt "${CLR8}$(Linet = 24)${CLR0}"
			Txt "${CLR2}完成${CLR0}\n"
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
						Err "-b 後需要分支名稱"
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
				Txt "${CLR3}正在克隆儲存庫 ${repo_owner_Run}/${repo_name_Run}${CLR0}"
				[[ -d ${repo_name_Run} ]] && {
					Err "目錄 ${repo_name_Run} 已存在"
					return 1
				}
				tmp_dir_Run=$(mktemp -d)
				if [[ ${branch_Run} != "main" ]]; then
					Task "* 正在從分支 ${branch_Run} 克隆" "git clone --branch ${branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
					if [ $? -ne 0 ]; then
						rm -rf "${tmp_dir_Run}"
						{
							Err "從分支 ${branch_Run} 克隆儲存庫失敗"
							return 1
						}
					fi
				else
					Task "* 檢查 main 分支" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}" true
					if [ $? -ne 0 ]; then
						Task "* 嘗試 master 分支" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git ${tmp_dir_Run}"
						if [ $? -ne 0 ]; then
							rm -rf "${tmp_dir_Run}"
							{
								Err "從 main 或 master 分支克隆儲存庫失敗"
								return 1
							}
						fi
					fi
				fi
				Task "* 建立目標目錄" "Add -d "${repo_name_Run}" && cp -r "${tmp_dir_Run}"/* "${repo_name_Run}"/"
				Task "* 清理暫存檔案" "rm -rf "${tmp_dir_Run}""
				Txt "儲存庫已克隆到目錄：${CLR2}${repo_name_Run}"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "* 設定執行權限" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "${CLR8}$(Linet = 24)${CLR0}"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "執行腳本 ${script_nm_Run} 失敗"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "執行腳本 ${script_nm_Run} 失敗"
							return 1
						}
					fi
					Txt "${CLR8}$(Linet = 24)${CLR0}"
					Txt "${CLR2}完成${CLR0}\n"
					[[ ${rm_aftr_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "${CLR3}正在從 ${repo_owner_Run}/${repo_name_Run} 下載並執行腳本 [${script_nm_Run}]${CLR0}"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/${branch_Run}/${script_path_Run}"
				if [[ ${branch_Run} != "main" ]]; then
					Task "* 檢查分支 ${branch_Run}" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "在分支 ${branch_Run} 中找不到腳本"
						return 1
					}
				else
					Task "* 檢查 main 分支" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "* 檢查 master 分支" "
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
				Task "* 下載腳本" "
					curl -sSLf "${github_url_Run}" -o "${script_nm_Run}" || { 
						Err "下載腳本 ${script_nm_Run} 失敗"
						Err "從 ${github_url_Run} 下載失敗"
						return 1
					}
					if [[ ! -f "${script_nm_Run}" ]]; then
						Err "下載失敗：未建立檔案"
						return 1
					fi
					if [[ ! -s "${script_nm_Run}" ]]; then
						Err "下載的檔案為空"
						cat "${script_nm_Run}" 2>/dev/null || Txt "（無法顯示檔案內容）"
						return 1
					fi
					if ! grep -q '[^[:space:]]' "${script_nm_Run}"; then
						Err "下載的檔案僅包含空白字元"
						return 1
					fi
					chmod +x "${script_nm_Run}" || { 
						Err "設定腳本 ${script_nm_Run} 執行權限失敗"
						Err "無法設定 ${script_nm_Run} 的執行權限"
						ls -la "${script_nm_Run}"
						return 1
					}
				"
				Txt "${CLR8}$(Linet = 24)${CLR0}"
				if [[ -f ${script_nm_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_nm_Run}" "$@" || {
							Err "執行腳本 ${script_nm_Run} 失敗"
							return 1
						}
					else
						./"${script_nm_Run}" || {
							Err "執行腳本 ${script_nm_Run} 失敗"
							return 1
						}
					fi
				else
					Err "腳本檔案 '${script_nm_Run}' 未成功下載"
					return 1
				fi
				Txt "${CLR8}$(Linet = 24)${CLR0}"
				Txt "${CLR2}完成${CLR0}\n"
				[[ ${rm_aftr_Run} == true ]] && rm -rf "${script_nm_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "執行腳本 ${script_nm_Run} 失敗"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "執行腳本 ${script_nm_Run} 失敗"
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
			Err "不支援的 shell"
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
	Txt "${CLR3}正在執行系統清理...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		Txt "* 清理 APK 快取"
		apk cache clean || {
			Err "清理 APK 快取失敗"
			return 1
		}
		Txt "* 移除暫存檔案"
		rm -rf /tmp/* /var/cache/apk/* || {
			Err "移除暫存檔案失敗"
			return 1
		}
		Txt "* 修復 APK 套件"
		apk fix || {
			Err "修復 APK 套件失敗"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Txt "* 等待 dpkg 鎖定"
			sleep 1 || return 1
			((wait_time_SysClean++))
			[ "${wait_time_SysClean}" -gt 300 ] && {
				Err "等待 dpkg 鎖定釋放超時"
				return 1
			}
		done
		Txt "* 設定待處理的套件"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			Err "設定待處理套件失敗"
			return 1
		}
		Txt "* 自動移除套件"
		apt autoremove --purge -y || {
			Err "自動移除套件失敗"
			return 1
		}
		Txt "* 清理 APT 快取"
		apt clean -y || {
			Err "清理 APT 快取失敗"
			return 1
		}
		Txt "* 自動清理 APT 快取"
		apt autoclean -y || {
			Err "自動清理 APT 快取失敗"
			return 1
		}
		;;
	*opkg)
		Txt "* 移除暫存檔案"
		rm -rf /tmp/* || {
			Err "移除暫存檔案失敗"
			return 1
		}
		Txt "* 更新 OPKG"
		opkg update || {
			Err "更新 OPKG 失敗"
			return 1
		}
		Txt "* 清理 OPKG 快取"
		opkg clean || {
			Err "清理 OPKG 快取失敗"
			return 1
		}
		;;
	*pacman)
		Txt "* 更新和升級套件"
		pacman -Syu --noconfirm || {
			Err "使用 pacman 更新和升級套件失敗"
			return 1
		}
		Txt "* 清理 pacman 快取"
		pacman -Sc --noconfirm || {
			Err "清理 pacman 快取失敗"
			return 1
		}
		Txt "* 清理所有 pacman 快取"
		pacman -Scc --noconfirm || {
			Err "清理所有 pacman 快取失敗"
			return 1
		}
		;;
	*yum)
		Txt "* 自動移除套件"
		yum autoremove -y || {
			Err "自動移除套件失敗"
			return 1
		}
		Txt "* 清理 YUM 快取"
		yum clean all || {
			Err "清理 YUM 快取失敗"
			return 1
		}
		Txt "* 建立 YUM 快取"
		yum makecache || {
			Err "建立 YUM 快取失敗"
			return 1
		}
		;;
	*zypper)
		Txt "* 清理 Zypper 快取"
		zypper clean --all || {
			Err "清理 Zypper 快取失敗"
			return 1
		}
		Txt "* 重新整理 Zypper 套件庫"
		zypper refresh || {
			Err "重新整理 Zypper 套件庫失敗"
			return 1
		}
		;;
	*dnf)
		Txt "* 自動移除套件"
		dnf autoremove -y || {
			Err "自動移除套件失敗"
			return 1
		}
		Txt "* 清理 DNF 快取"
		dnf clean all || {
			Err "清理 DNF 快取失敗"
			return 1
		}
		Txt "* 建立 DNF 快取"
		dnf makecache || {
			Err "建立 DNF 快取失敗"
			return 1
		}
		;;
	*) {
		Err "不支援的套件管理器。跳過系統特定清理"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		Task "* 輪替和清理 journalctl 日誌" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "輪替和清理 journalctl 日誌失敗"
			return 1
		}
	fi
	Task "* 移除暫存檔案" "rm -rf /tmp/*" || {
		Err "移除暫存檔案失敗"
		return 1
	}
	for cmd_SysClean in docker npm pip; do
		if command -v "${cmd_SysClean}" &>/dev/null; then
			case "${cmd_SysClean}" in
			docker) Task "* 清理 Docker 系統" "docker system prune -af" || {
				Err "清理 Docker 系統失敗"
				return 1
			} ;;
			npm) Task "* 清理 NPM 快取" "npm cache clean --force" || {
				Err "清理 NPM 快取失敗"
				return 1
			} ;;
			pip) Task "* 清除 PIP 快取" "pip cache purge" || {
				Err "清除 PIP 快取失敗"
				return 1
			} ;;
			esac
		fi
	done
	Task "* 移除使用者快取檔案" "rm -rf ~/.cache/*" || {
		Err "移除使用者快取檔案失敗"
		return 1
	}
	Task "* 移除縮圖檔案" "rm -rf ~/.thumbnails/*" || {
		Err "移除縮圖檔案失敗"
		return 1
	}
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SysInfo() {
	Txt "${CLR3}系統資訊${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"

	Txt "- 主機名稱：		${CLR2}$(uname -n || hostname)${CLR0}"
	Txt "- 作業系統：		${CLR2}$(ChkOs)${CLR0}"
	Txt "- 核心版本：		${CLR2}$(uname -r)${CLR0}"
	Txt "- 系統語言：		${CLR2}$LANG${CLR0}"
	Txt "- Shell 版本：		${CLR2}$(ShellVer)${CLR0}"
	Txt "- 最後系統更新：	${CLR2}$(LastUpd)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"

	Txt "- 架構：		${CLR2}$(uname -m)${CLR0}"
	Txt "- CPU 型號：		${CLR2}$(CpuModel)${CLR0}"
	Txt "- CPU 核心數：		${CLR2}$(nproc)${CLR0}"
	Txt "- CPU 頻率：		${CLR2}$(CpuFreq)${CLR0}"
	Txt "- CPU 使用率：		${CLR2}$(CpuUsage)%${CLR0}"
	Txt "- CPU 快取：		${CLR2}$(CpuCache)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"

	Txt "- 記憶體使用率：	${CLR2}$(MemUsage)${CLR0}"
	Txt "- SWAP 使用率：		${CLR2}$(SwapUsage)${CLR0}"
	Txt "- 磁碟使用率：		${CLR2}$(DiskUsage)${CLR0}"
	Txt "- 檔案系統類型：	${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"

	Txt "- IPv4 地址：		${CLR2}$(IpAddr --ipv4)${CLR0}"
	Txt "- IPv6 地址：		${CLR2}$(IpAddr --ipv6)${CLR0}"
	Txt "- MAC 位址：		${CLR2}$(MacAddr)${CLR0}"
	Txt "- 網路供應商：		${CLR2}$(NetProv)${CLR0}"
	Txt "- DNS 伺服器：		${CLR2}$(DnsAddr)${CLR0}"
	Txt "- 公開 IP：		${CLR2}$(PubIp)${CLR0}"
	Txt "- 網路介面：		${CLR2}$(Iface -i)${CLR0}"
	Txt "- 內部時區：		${CLR2}$(TimeZn --internal)${CLR0}"
	Txt "- 外部時區：		${CLR2}$(TimeZn --external)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"

	Txt "- 負載平均：		${CLR2}$(LoadAvg)${CLR0}"
	Txt "- 程序數量：		${CLR2}$(ps aux | wc -l)${CLR0}"
	Txt "- 已安裝套件：		${CLR2}$(PkgCnt)${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"

	Txt "- 運行時間：		${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	Txt "- 啟動時間：		${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	Txt "${CLR8}$(Linet - 32)${CLR0}"

	Txt "- 虛擬化：		${CLR2}$(ChkVirt)${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
}
function SysOptz() {
	ChkRoot
	Txt "${CLR3}正在優化長期運行伺服器的系統設定...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "# 長期運行系統的伺服器優化" >"${sysctl_conf_SysOptimize}"

	Task "* 正在優化記憶體管理" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "優化記憶體管理失敗"
		return 1
	}

	Task "* 正在優化網路設定" "
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
		Err "優化網路設定失敗"
		return 1
	}

	Task "* 正在優化 TCP 緩衝區" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "優化 TCP 緩衝區失敗"
		return 1
	}

	Task "* 正在優化檔案系統設定" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "優化檔案系統設定失敗"
		return 1
	}

	Task "* 正在優化系統限制" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "優化系統限制失敗"
		return 1
	}

	Task "* 正在優化 I/O 排程器" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "優化 I/O 排程器失敗"
		return 1
	}

	Task "* 停用非必要服務" "
		for service_SysOptz in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service_SysOptz 2>/dev/null || true
		done
	" || {
		Err "停用服務失敗"
		return 1
	}

	Task "* 套用系統參數" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "套用系統參數失敗"
		return 1
	}

	Task "* 清除系統快取" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "清除系統快取失敗"
		return 1
	}

	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SysRboot() {
	ChkRoot
	Txt "${CLR3}正在準備重新啟動系統...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	active_usrs_SysRboot=$(who | wc -l) || {
		Err "取得活動使用者數量失敗"
		return 1
	}
	if [ "${active_usrs_SysRboot}" -gt 1 ]; then
		Txt "${CLR1}警告：目前系統有 ${active_usrs_SysRboot} 個活動使用者${CLR0}\n"
		Txt "活動使用者："
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_procs_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "檢查執行中的程序失敗"
		return 1
	}
	if [ "${important_procs_SysRboot}" -gt 0 ]; then
		Txt "${CLR1}警告：有 ${important_procs_SysRboot} 個重要程序正在執行${CLR0}\n"
		Txt "${CLR8}CPU 使用率最高的 5 個程序：${CLR0}"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Ask "您確定要立即重新啟動系統嗎？(y/N) " -n 1 cont_SysRboot
	Txt
	[[ ! ${cont_SysRboot} =~ ^[Yy]$ ]] && {
		Txt "${CLR2}已取消重新啟動${CLR0}\n"
		return 0
	}
	Task "* 執行最終檢查" "sync" || {
		Err "同步檔案系統失敗"
		return 1
	}
	Task "* 開始重新啟動" "reboot || sudo reboot" || {
		Err "啟動重新啟動失敗"
		return 1
	}
	Txt "${CLR2}已成功發出重新啟動命令。系統將立即重新啟動${CLR0}"
}
function SysUpd() {
	ChkRoot
	Txt "${CLR3}正在更新系統軟體...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	UpdPkg() {
		cmd_SysUpd_UpdPkg="$1"
		upd_cmd_SysUpd_UpdPkg="$2"
		upg_cmd_SysUpd_UpdPkg="$3"
		Txt "* 正在更新套件清單"
		${upd_cmd_SysUpd_UpdPkg} || {
			Err "使用 ${cmd_SysUpd_UpdPkg} 更新套件清單失敗"
			return 1
		}
		Txt "* 正在升級套件"
		${upg_cmd_SysUpd_UpdPkg} || {
			Err "使用 ${cmd_SysUpd_UpdPkg} 升級套件失敗"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "* 等待 dpkg 鎖定" "sleep 1" || return 1
			((wait_time_SysUpd++))
			[ "${wait_time_SysUpd}" -gt 10 ] && {
				Err "等待 dpkg 鎖定釋放超時"
				return 1
			}
		done
		Task "* 設定待處理的套件" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "設定待處理的套件失敗"
			return 1
		}
		UpdPkg "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) Task "* 更新和升級套件" "pacman -Syu --noconfirm" || {
		Err "使用 pacman 更新和升級套件失敗"
		return 1
	} ;;
	*yum) UpdPkg "yum" "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "不支援的套件管理器"
		return 1
	} ;;
	esac
	Txt "* 正在更新 ${SCRIPTS}"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) || {
		Err "更新 ${SCRIPTS} 失敗"
		return 1
	}
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SysUpg() {
	ChkRoot
	Txt "${CLR3}正在升級系統至下一個主要版本...${CLR0}"
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	os_nm_SysUpg=$(ChkOs --name)
	case "${os_nm_SysUpg}" in
	Debian)
		Txt "* 偵測到 'Debian' 系統"
		Txt "* 正在更新套件清單"
		apt update -y || {
			Err "使用 apt 更新套件清單失敗"
			return 1
		}
		Txt "* 正在升級目前的套件"
		apt full-upgrade -y || {
			Err "升級目前的套件失敗"
			return 1
		}
		Txt "* 開始 'Debian' 發行版升級..."
		curr_codenm_SysUpg=$(lsb_release -cs)
		targ_codenm_SysUpg=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${targ_codenm_SysUpg}" ] && {
			Err "系統已經是最新的穩定版本 (${targ_codenm_SysUpg})"
			return 1
		}
		Txt "* 正在從 ${CLR2}${curr_codenm_SysUpg}${CLR0} 升級到 ${CLR3}${targ_codenm_SysUpg}${CLR0}"
		Task "* 備份 sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "備份 sources.list 失敗"
			return 1
		}
		Task "* 更新 sources.list" "sed -i 's/${curr_codenm_SysUpg}/${targ_codenm_SysUpg}/g' /etc/apt/sources.list" || {
			Err "更新 sources.list 失敗"
			return 1
		}
		Task "* 更新新版本的套件清單" "apt update -y" || {
			Err "更新新版本的套件清單失敗"
			return 1
		}
		Task "* 升級到新的 Debian 版本" "apt full-upgrade -y" || {
			Err "升級到新的 Debian 版本失敗"
			return 1
		}
		;;
	Ubuntu)
		Txt "* 偵測到 'Ubuntu' 系統"
		Task "* 正在更新套件清單" "apt update -y" || {
			Err "使用 apt 更新套件清單失敗"
			return 1
		}
		Task "* 正在升級目前的套件" "apt full-upgrade -y" || {
			Err "升級目前的套件失敗"
			return 1
		}
		Task "* 安裝 update-manager-core" "apt install -y update-manager-core" || {
			Err "安裝 update-manager-core 失敗"
			return 1
		}
		Task "* 升級 Ubuntu 版本" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "升級 Ubuntu 版本失敗"
			return 1
		}
		SysRboot
		;;
	*) {
		Err "您的系統尚不支援主要版本升級"
		return 1
	} ;;
	esac
	Txt "${CLR8}$(Linet = 24)${CLR0}"
	Txt "${CLR2}系統升級完成${CLR0}\n"
}
function Task() {
	msg_Task="$1"
	cmd_Task="$2"
	ign_err_Task=${3:-false}
	tmp_file_Task=$(mktemp)
	Txt -n "${msg_Task}..."
	if eval "${cmd_Task}" >"${tmp_file_Task}" 2>&1; then
		Txt "${CLR2}完成${CLR0}"
		ret_Task=0
	else
		ret_Task=$?
		Txt "${CLR1}失敗${CLR0} (${ret_Task})"
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
			Err "從外部服務偵測時區失敗"
			return 1
		}
		;;
	-i | --internal | *)
		data_TimeZn=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			data_TimeZn=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			data_TimeZn=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${data_TimeZn}" ] && Txt "${data_TimeZn}" || {
			Err "偵測系統時區失敗"
			return 1
		}
		;;
	esac
}
function Press() {
	read -p "$1" -n 1 -r || {
		Err "讀取使用者輸入失敗"
		return 1
	}
}
