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
		Txt "${CLR1}未知錯誤${CLR0}"
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
			Txt "${CLR3}安裝 DEB 套件［$debFile］${CLR0}\n"
			Get "$1"
			if [ -f "$debFile" ]; then
				dpkg -i "$debFile" || {
					Err "安裝 $debFile 失敗。請檢查套件相容性和相依性\n"
					Del -f "$debFile"
					err_code_Add=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "修復相依性失敗"
					Del -f "$debFile"
					err_code_Add=1
					shift
					continue
				}
				Txt "* DEB 套件 $debFile 安裝成功"
				Del -f "$debFile"
				Txt "${CLR2}完成${CLR0}\n"
			else
				Err "找不到 DEB 套件 $debFile 或下載失敗\n"
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
			"directory")
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
			"package")
				Txt "${CLR3}安裝套件［$1］${CLR0}"
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
						Txt "* 套件 $1 尚未安裝"
						if InstallPkg "$1"; then
							if IsInst "$1"; then
								Txt "* 套件 $1 安裝成功"
								Txt "${CLR2}完成${CLR0}\n"
							else
								Err "使用 $pkg_manager 安裝 $1 失敗\n"
								err_code_Add=1
								shift
								continue
							fi
						else
							Err "使用 $pkg_manager 安裝 $1 失敗\n"
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
	return $err_code
}
function Ask() {
	read -e -p "$1" -r $2 || {
		Err "讀取使用者輸入失敗"
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
			Err "無效的選項：$1"
			return 1
			;;
		esac
		shift
	done
	for dep_ChkDep in "${deps[@]}"; do
		if command -v "${dep_ChkDep}" &>/dev/null; then
			stat_ChkDep="${CLR2}［可用］${CLR0}"
		else
			stat_ChkDep="${CLR1}［缺失］${CLR0}"
			mis_dep_ChkDep+=("${dep_ChkDep}")
		fi
		Txt "$stat_ChkDep\t${dep_ChkDep}"
	done
	[[ ${#mis_dep_ChkDep[@]} -eq 0 ]] && return 0
	case "${mod_ChkDep}" in
	"interactive")
		Txt "\n${CLR3}缺少的套件：${CLR0} ${mis_dep_ChkDep[*]}"
		Press "是否要安裝缺少的套件？(y/N) " cont_ChkDep
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
				Err "未知的發行版本"
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
				Err "未知的發行版"
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
				Err "未知的發行版"
				return 1
			}
		fi
		;;
	esac
}
function ChkRoot() {
	if [ "$EUID" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
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
	targ_dir_Clear="${1:-$HOME}"
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
	cache_CpuCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "${cache_CpuCache}" = "N/A" ] && {
		Err "無法確定 CPU 快取大小"
		return 1
	}
	Txt "${cache_CpuCache} KB"
}
function CpuFreq() {
	[ ! -f /proc/cpuinfo ] && {
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用"
		return 1
	}
	freq_CpuFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "${freq_CpuFreq}" = "N/A" ] && {
		Err "無法確定 CPU 頻率"
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
			Txt "${CLR1}未知${CLR0}"
			return 1
		}
	fi
}
function CpuUsage() {
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idel_CpuUsage io_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "從 /proc/stat 讀取 CPU 統計資料失敗"
		return 1
	}
	ttl1_CpuUsage=$((usr_CpuUsage + nice_CpuUsage + sys_CpuUsage + idel_CpuUsage + io_CpuUsage + irq_CpuUsage + softirq_CpuUsage))
	idel1_CpuUsage=${idel_CpuUsage}
	sleep 0.3
	read -r cpu_CpuUsage usr_CpuUsage nice_CpuUsage sys_CpuUsage idel_CpuUsage io_CpuUsage irq_CpuUsage softirq_CpuUsage <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "從 /proc/stat 讀取 CPU 統計資料失敗"
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
		Err "未提供要轉換的大小值"
		return 2
	}
	input_size_ConvSz=$1
	input_unit_ConvSz=${2:-B}
	unit_lower_ConvSz=$(Format -aa "${input_unit_ConvSz}")
	if ! [[ ${input_size_ConvSz} =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		{
			Err "無效的大小值。必須為數值"
			return 2
		}
	elif [[ ${input_size_ConvSz} =~ ^[-].*$ ]]; then
		{
			Err "大小值不能為負數"
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
					Err "檔案 $1 不存在\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 檔案 $1 已存在"
				rm -f "$1" || {
					Err "刪除檔案 $1 失敗\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 檔案 $1 移除成功"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"directory")
				[ ! -d "$1" ] && {
					Err "目錄 $1 不存在\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 目錄 $1 已存在"
				rm -rf "$1" || {
					Err "刪除目錄 $1 失敗\n"
					err_code_Del=1
					shift
					continue
				}
				Txt "* 目錄 $1 移除成功"
				Txt "${CLR2}完成${CLR0}\n"
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
						Err "* 套件 $1 尚未安裝\n"
						err_code_Del=1
						shift
						continue
					fi
					Txt "* Package $1 is installed"
					if ! RmPkg "$1"; then
						Err "使用 $pkg_manager 移除 $1 失敗\n"
						err_code_Del=1
						shift
						continue
					fi
					if IsInst "$1"; then
						Err "使用 $pkg_manager 移除 $1 失敗\n"
						err_code_Del=1
						shift
						continue
					fi
					Txt "* 套件 $1 移除成功"
					Txt "${CLR2}完成${CLR0}\n"
					;;
				*) {
					Err "不支援的套件管理器"
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
		Err "取得磁碟使用統計資料失敗"
		return 1
	}
	ttl_DiskUsage=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "取得總磁碟空間失敗"
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
		Err "找不到 DNS 設定檔 /etc/resolv.conf"
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
		Err "/etc/resolv.conf 中未設定 DNS 伺服器"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_DnsAddr[@]} -eq 0 ] && {
			Err "找不到 IPv4 DNS 伺服器"
			return 1
		}
		Txt "${ipv4_DnsAddr[*]}"
		;;
	-6)
		[ ${#ipv6_DnsAddr[@]} -eq 0 ] && {
			Err "找不到 IPv6 DNS 伺服器"
			return 1
		}
		Txt "${ipv6_DnsAddr[*]}"
		;;
	*)
		[ ${#ipv4_DnsAddr[@]} -eq 0 -a ${#ipv6_DnsAddr[@]} -eq 0 ] && {
			Err "找不到 DNS 伺服器"
			return 1
		}
		Txt "${ipv4_DnsAddr[*]}   ${ipv6_DnsAddr[*]}"
		;;
	esac
}
function Find() {
	[ $# -eq 0 ] && {
		Err "未指定搜尋條件。請指定要搜尋的內容"
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
		Err "找不到或不支援的套件管理器"
		return 1
	} ;;
	esac
	for target in "$@"; do
		Txt "${CLR3}搜尋［$target］${CLR0}"
		${search_command-Find} "$target" || {
			Err "找不到 $target 的結果\n"
			return 1
		}
		Txt "${CLR2}完成${CLR0}\n"
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
		Err "未提供要格式化的值"
		return 2
	}
	[ -z "$flg_Format" ] && {
		Err "未提供格式化選項"
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
				Err "-r 選項後未指定檔案名稱"
				return 2
			}
			ren_file_Get="$2"
			shift 2
			;;
		-*) {
			Err "無效的選項：$1"
			return 2
		} ;;
		*)
			[ -z "$url_Get" ] && url_Get="$1" || targ_dir_Get="$1"
			shift
			;;
		esac
	done
	[ -z "$url_Get" ] && {
		Err "未指定 URL。請提供要下載的 URL"
		return 2
	}
	[[ $url_Get =~ ^(http|https|ftp):// ]] || url_Get="https://$url_Get"
	out_file_Get="${url_Get##*/}"
	[ -z "$out_file_Get" ] && out_file_Get="index.html"
	[ "$targ_dir_Get" != "." ] && { mkdir -p "$targ_dir_Get" || {
		Err "建立目錄 $targetDirectory 失敗"
		return 1
	}; }
	[ -n "$ren_file_Get" ] && out_file_Get="$ren_file_Get"
	out_path_Get="$targ_dir_Get/$out_file_Get"
	url_Get=$(echo "$url_Get" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR3}下載［$uniformResourceLocator］${CLR0}"
	file_sz_Get=$(curl -sI "$url_Get" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "$file_sz_Get" ] && [ "$file_sz_Get" -gt "26214400" ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "$url_Get" -O "$out_path_Get" || {
			Err "使用 Wget 下載檔案失敗"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "$url_Get" -o "$out_path_Get" || {
			Err "使用 cUrl 下載檔案失敗"
			return 1
		}
	fi
	if [ -f "$out_path_Get" ]; then
		Txt "* 檔案成功下載至 $outputPath"
		if [ "$unzip_Get" = true ]; then
			case "$out_file_Get" in
			*.tar.gz | *.tgz) tar -xzf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "解壓縮 tar.gz 檔案失敗"
				return 1
			} ;;
			*.tar) tar -xf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "解壓縮 tar 檔案失敗"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "解壓縮 tar.bz2 檔案失敗"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "$out_path_Get" -C "$targ_dir_Get" || {
				Err "解壓縮 tar.xz 檔案失敗"
				return 1
			} ;;
			*.zip) unzip "$out_path_Get" -d "$targ_dir_Get" || {
				Err "解壓縮 zip 檔案失敗"
				return 1
			} ;;
			*.7z) 7z x "$out_path_Get" -o"$targ_dir_Get" || {
				Err "解壓縮 7z 檔案失敗"
				return 1
			} ;;
			*.rar) unrar x "$out_path_Get" "$targ_dir_Get" || {
				Err "解壓縮 rar 檔案失敗"
				return 1
			} ;;
			*.zst) zstd -d "$out_path_Get" -o "$targ_dir_Get" || {
				Err "解壓縮 zst 檔案失敗"
				return 1
			} ;;
			*) Txt "* 無法識別的檔案格式，不進行自動解壓縮" ;;
			esac
			[ $? -eq 0 ] && Txt "* 檔案成功解壓縮至 $targetDirectory"
		fi
		Txt "${CLR2}完成${CLR0}\n"
	else
		{
			Err "下載失敗。請檢查網路連線和 URL 有效性"
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
		Err "從 /proc/net/dev 取得網路介面失敗"
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
		Err "無效的參數：$1。有效的參數為：rx_bytes、rx_packets、rx_drop、tx_bytes、tx_packets、tx_drop、-i"
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
			Err "取得 IPv4 位址失敗。請檢查網路連線"
			return 1
		}
		;;
	-6)
		ipv6_addr_IpAddr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr_IpAddr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr_IpAddr}" ] && Txt "${ipv6_addr_IpAddr}" || {
			Err "取得 IPv6 位址失敗。請檢查網路連線"
			return 1
		}
		;;
	*)
		ipv4_addr_IpAddr=$(IpAddr -4)
		ipv6_addr_IpAddr=$(IpAddr -6)
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
		upd_dat_LastUpd=$(awk '/End-Date:/ {print $2, $3, $4; exit}' /var/log/apt/history.log 2>/dev/null)
	elif [ -f /var/log/dpkg.log ]; then
		upd_dat_LastUpd=$(tail -n 1 /var/log/dpkg.log | awk '{print $1, $2}')
	elif command -v rpm &>/dev/null; then
		upd_dat_LastUpd=$(rpm -qa --last | head -n 1 | awk '{print $3, $4, $5, $6, $7}')
	fi
	[ -z "${upd_dat_LastUpd}" ] && {
		Err "無法確定最後系統更新時間。找不到更新日誌"
		return 1
	} || Txt "${upd_dat_LastUpd}"
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
		dat_LoadAvg=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "從 uptime 指令取得負載平均值失敗"
			return 1
		}
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg <<<"${dat_LoadAvg}"
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
	get_Loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^loc=" | cut -d= -f2)
	[ -n "${get_Loc}" ] && Txt "${get_Loc}" || {
		Err "無法偵測地理位置。請檢查網路連線"
		return 1
	}
}
function MacAddr() {
	get_MacAddr=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n ${get_MacAddr} ]] && Txt "${get_MacAddr}" || {
		Err "無法取得 MAC 位址。找不到網路介面"
		return 1
	}
}
function MemUsage() {
	used_MemUsage=$(free -b | awk '/^Mem:/ {print $3}') || used_MemUsage=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "取得記憶體使用統計資料失敗"
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
		Err "無法偵測網路供應商。請檢查網路連線"
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
		Err "無法計算已安裝的套件。軟體包管理器不支援"
		return 1
	} ;;
	esac
	if ! cnt_PkgCnt=$(${cnt_cmd_PkgCnt} 2>/dev/null | wc -l) || [[ -z ${cnt_PkgCnt} || ${cnt_PkgCnt} -eq 0 ]]; then
		{
			Err "計算 ${packageManager##*/} 的套件數量失敗"
			return 1
		}
	fi
	Txt "${cnt_PkgCnt}"
}
function Progress() {
	num_cmd_Progress=${#cmds[@]}
	term_wid_Progress=$(tput cols) || {
		Err "取得終端機寬度失敗"
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
				Err "命令執行失敗：${commands[$i]}"
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
		Err "無法偵測公開 IP 位址。請檢查網路連線"
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
		Err "未指定命令"
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
			Txt "${CLR3}正在從 URL 下載並執行腳本 [${scriptName}]${CLR0}"
			Task "* 下載腳本" "
				curl -sSLf "${url_Run}" -o "${script_Run}" || { Err "下載腳本 $scriptName 失敗"; return 1; }
				chmod +x "${script_Run}" || { Err "設定腳本 $scriptName 執行權限失敗"; return 1; }
			"
			Txt "${CLR8}$(Linet = "24")${CLR0}"
			if [[ $1 == "--" ]]; then
				shift
				./"${script_Run}" "$@" || {
					Err "執行腳本 $scriptName 失敗"
					return 1
				}
			else
				./"${script_Run}" || {
					Err "執行腳本 $scriptName 失敗"
					return 1
				}
			fi
			Txt "${CLR8}$(Linet = "24")${CLR0}"
			Txt "${CLR2}完成${CLR0}\n"
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
						Err "-b 後需要分支名稱"
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
				Txt "${CLR3}正在克隆儲存庫 ${repositoryOwner}/${repositoryName}${CLR0}"
				[[ -d ${repo_name_Run} ]] && {
					Err "目錄 $repositoryName 已存在"
					return 1
				}
				temp_dir_Run=$(mktemp -d)
				if [[ ${repo_branch_Run} != "main" ]]; then
					Task "* 正在從分支 $repositoryBranch 克隆" "git clone --branch ${repo_branch_Run} https://github.com/${repo_owner_Run}/${repo_name_Run}.git "${temp_dir_Run}""
					if [ $? -ne 0 ]; then
						rm -rf "${temp_dir_Run}"
						{
							Err "從分支 $repositoryBranch 克隆儲存庫失敗"
							return 1
						}
					fi
				else
					Task "* 檢查 main 分支" "git clone --branch main https://github.com/${repo_owner_Run}/${repo_name_Run}.git "${temp_dir_Run}"" true
					if [ $? -ne 0 ]; then
						Task "* 嘗試 master 分支" "git clone --branch master https://github.com/${repo_owner_Run}/${repo_name_Run}.git "${temp_dir_Run}""
						if [ $? -ne 0 ]; then
							rm -rf "${temp_dir_Run}"
							{
								Err "從 main 或 master 分支克隆儲存庫失敗"
								return 1
							}
						fi
					fi
				fi
				Task "* 建立目標目錄" "Add -d "${repo_name_Run}" && cp -r "${temp_dir_Run}"/* "${repo_name_Run}"/"
				Task "* 清理暫存檔案" "rm -rf "${temp_dir_Run}""
				Txt "儲存庫已克隆到目錄：${CLR2}$repositoryName"
				if [[ -f "${repo_name_Run}/${script_path_Run}" ]]; then
					Task "* 設定執行權限" "chmod +x "${repo_name_Run}/${script_path_Run}""
					Txt "${CLR8}$(Linet = "24")${CLR0}"
					if [[ $1 == "--" ]]; then
						shift
						./"${repo_name_Run}/${script_path_Run}" "$@" || {
							Err "執行腳本 $scriptName 失敗"
							return 1
						}
					else
						./"${repo_name_Run}/${script_path_Run}" || {
							Err "執行腳本 $scriptName 失敗"
							return 1
						}
					fi
					Txt "${CLR8}$(Linet = "24")${CLR0}"
					Txt "${CLR2}完成${CLR0}\n"
					[[ ${del_after_Run} == true ]] && rm -rf "${repo_name_Run}"
				fi
			else
				Txt "${CLR3}正在從 ${repositoryOwner}/${repositoryName} 下載並執行腳本 [${scriptName}]${CLR0}"
				github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/refs/heads/${repo_branch_Run}/${script_path_Run}"
				if [[ ${repo_branch_Run} != "main" ]]; then
					Task "* 檢查分支 $repositoryBranch" "curl -sLf "${github_url_Run}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "在分支 $repositoryBranch 中找不到腳本"
						return 1
					}
				else
					Task "* 檢查 main 分支" "curl -sLf "${github_url_Run}" >/dev/null" true
					if [ $? -ne 0 ]; then
						Task "* 檢查 master 分支" "
							repo_branch_Run="master"
							github_url_Run="https://raw.githubusercontent.com/${repo_owner_Run}/${repo_name_Run}/refs/heads/master/${script_path_Run}"
							curl -sLf "${github_url_Run}" >/dev/null
						"
						[ $? -ne 0 ] && {
							Err "在 main 或 master 分支中找不到腳本"
							return 1
						}
					fi
				fi
				Task "* 下載腳本" "
					curl -sSLf \"${github_url_Run}\" -o \"${script_Run}\" || { 
						Err \"下載腳本 $scriptName 失敗\"
						Err \"從 $github_uniformResourceLocator 下載失敗\"
						return 1
					}

					if [[ ! -f \"${script_Run}\" ]]; then
						Err \"下載失敗：未建立檔案\"
						return 1
					fi

					if [[ ! -s \"${script_Run}\" ]]; then
						Err \"下載的檔案為空\"
						cat \"${script_Run}\" 2>/dev/null || echo \"（無法顯示檔案內容）\"
						return 1
					fi

					if ! grep -q '[^[:space:]]' \"${script_Run}\"; then
						Err \"下載的檔案僅包含空白字元\"
						return 1
					fi

					chmod +x \"${script_Run}\" || { 
						Err \"設定腳本 $scriptName 執行權限失敗\"
						Err \"無法設定 $scriptName 的執行權限\"
						ls -la \"${script_Run}\"
						return 1
					}
				"

				Txt "${CLR8}$(Linet = "24")${CLR0}"
				if [[ -f ${script_Run} ]]; then
					if [[ $1 == "--" ]]; then
						shift
						./"${script_Run}" "$@" || {
							Err "執行腳本 $scriptName 失敗"
							return 1
						}
					else
						./"${script_Run}" || {
							Err "執行腳本 $scriptName 失敗"
							return 1
						}
					fi
				else
					Err "腳本檔案 '$scriptName' 未成功下載"
					return 1
				fi
				Txt "${CLR8}$(Linet = "24")${CLR0}"
				Txt "${CLR2}完成${CLR0}\n"
				[[ ${del_after_Run} == true ]] && rm -rf "${script_Run}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path_Run="$1"
			if [[ $2 == "--" ]]; then
				shift 2
				"${script_path_Run}" "$@" || {
					Err "執行腳本 $scriptName 失敗"
					return 1
				}
			else
				shift
				"${script_path_Run}" "$@" || {
					Err "執行腳本 $scriptName 失敗"
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
	Txt "${CLR3}正在執行系統清理...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
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
			((waiting_time_SysClean++))
			[ "${waiting_time_SysClean}" -gt 300 ] && {
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
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SysInfo() {
	Txt "${CLR3}系統資訊${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"

	Txt "- 主機名稱：		${CLR2}$(uname -n || {
		Err "取得主機名稱失敗"
		return 1
	})${CLR0}"
	Txt "- 作業系統：		${CLR2}$(ChkOs)${CLR0}"
	Txt "- 核心版本：		${CLR2}$(uname -r)${CLR0}"
	Txt "- 系統語言：		${CLR2}$LANG${CLR0}"
	Txt "- Shell 版本：		${CLR2}$(ShellVer)${CLR0}"
	Txt "- 最後系統更新：	${CLR2}$(LastUpd)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- 架構：		${CLR2}$(uname -m)${CLR0}"
	Txt "- CPU 型號：		${CLR2}$(CpuModel)${CLR0}"
	Txt "- CPU 核心數：		${CLR2}$(nproc)${CLR0}"
	Txt "- CPU 頻率：		${CLR2}$(CpuFreq)${CLR0}"
	Txt "- CPU 使用率：		${CLR2}$(CpuUsage)%${CLR0}"
	Txt "- CPU 快取：		${CLR2}$(CpuCache)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- 記憶體使用率：	${CLR2}$(MemUsage)${CLR0}"
	Txt "- Swap 使用率：		${CLR2}$(SwapUsage)${CLR0}"
	Txt "- 磁碟使用率：		${CLR2}$(DiskUsage)${CLR0}"
	Txt "- 檔案系統類型：	${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- IPv4 地址：		${CLR2}$(IpAddr -4)${CLR0}"
	Txt "- IPv6 地址：		${CLR2}$(IpAddr -6)${CLR0}"
	Txt "- MAC 位址：		${CLR2}$(MacAddr)${CLR0}"
	Txt "- 網路供應商：		${CLR2}$(Provider)${CLR0}"
	Txt "- DNS 伺服器：		${CLR2}$(DnsAddr)${CLR0}"
	Txt "- 公開 IP：		${CLR2}$(PublicIp)${CLR0}"
	Txt "- 網路介面：		${CLR2}$(Iface -i)${CLR0}"
	Txt "- 內部時區：		${CLR2}$(TimeZone -i)${CLR0}"
	Txt "- 外部時區：		${CLR2}$(TimeZone -e)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- 負載平均：		${CLR2}$(LoadAvg)${CLR0}"
	Txt "- 程序數量：		${CLR2}$(ps aux | wc -l)${CLR0}"
	Txt "- 已安裝套件：		${CLR2}$(PkgCnt)${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- 運行時間：		${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	Txt "- 啟動時間：		${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	Txt "${CLR8}$(Linet - "32")${CLR0}"

	Txt "- 虛擬化：		${CLR2}$(ChkVirt)${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
}
function SysOptimize() {
	ChkRoot
	Txt "${CLR3}正在優化長期運行伺服器的系統設定...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
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

	Task "* 停用非必要服務" '
		for service in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service 2>/dev/null || true
		done
	' || {
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

	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SysRboot() {
	ChkRoot
	Txt "${CLR3}正在準備重新啟動系統...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	active_usr_SysRboot=$(who | wc -l) || {
		Err "取得活動使用者數量失敗"
		return 1
	}
	if [ "${active_usr_SysRboot}" -gt 1 ]; then
		Txt "${CLR1}警告：目前系統有 $activeUsers 個活動使用者${CLR0}\n"
		Txt "活動使用者："
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_proc_SysRboot=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "檢查執行中的程序失敗"
		return 1
	}
	if [ "${important_proc_SysRboot}" -gt 0 ]; then
		Txt "${CLR1}警告：有 $importantProcesses 個重要程序正在執行${CLR0}\n"
		Txt "${CLR8}CPU 使用率最高的 5 個程序：${CLR0}"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	Press "您確定要立即重新啟動系統嗎？(y/N) " cont_SysRboot
	Txt
	[[ ! "${cont_SysRboot}" =~ ^[Yy]$ ]] && {
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
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	UpdPkg() {
		upd_cmd_SysUpd="$1"
		upg_cmd_SysUpd="$2"
		Txt "* 正在更新套件清單"
		${upd_cmd_SysUpd} || {
			Err "使用 $cmd 更新套件清單失敗"
			return 1
		}
		Txt "* 正在升級套件"
		${upg_cmd_SysUpd} || {
			Err "使用 $cmd 升級套件失敗"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) UpdPkg "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			Task "* 等待 dpkg 鎖定" "sleep 1" || return 1
			((waiting_time_SysUpd++))
			[ "$waiting_time_SysUpd" -gt 10 ] && {
				Err "等待 dpkg 鎖定釋放超時"
				return 1
			}
		done
		Task "* 設定待處理的套件" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "設定待處理的套件失敗"
			return 1
		}
		UpdPkg "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) UpdPkg "opkg update" "opkg upgrade" ;;
	*pacman) Task "* 更新和升級套件" "pacman -Syu --noconfirm" || {
		Err "使用 pacman 更新和升級套件失敗"
		return 1
	} ;;
	*yum) UpdPkg "yum check-update" "yum -y update" ;;
	*zypper) UpdPkg "zypper refresh" "zypper update -y" ;;
	*dnf) UpdPkg "dnf check-update" "dnf -y update" ;;
	*) {
		Err "不支援的套件管理器"
		return 1
	} ;;
	esac
	Txt "* 正在更新 $SCRIPTS"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/refs/heads/main/sh/get_utilkit.sh) || {
		Err "更新 $SCRIPTS 失敗"
		return 1
	}
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SysUpg() {
	ChkRoot
	Txt "${CLR3}正在升級系統至下一個主要版本...${CLR0}"
	Txt "${CLR8}$(Linet = "24")${CLR0}"
	os_nm_SysUpg=$(ChkOs -n)
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
		[ "${curr_codenm_SysUpg}" = "${targ_codenm_SysUpg}" ] && {
			Err "系統已經是最新的穩定版本 (${targ_codenm_SysUpg})"
			return 1
		}
		Txt "* 正在從 ${CLR2}${currentCodename}${CLR0} 升級到 ${CLR3}${targetCodename}${CLR0}"
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
	Txt "${CLR8}$(Linet = "24")${CLR0}"
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
		Txt "${CLR1}失敗${CLR0} ("${ret_Task}")"
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
			Err "從外部服務偵測時區失敗"
			return 1
		}
		;;
	-i | *)
		ans_TimeZone=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			ans_TimeZone=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			ans_TimeZone=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${ans_TimeZone}" ] && Txt "$ans_TimeZone" || {
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
