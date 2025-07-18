#!/bin/bash

ANTHORS="OG-Open-Source"
SCRIPTS="UtilKit.sh"
VERSION="7.043.009"

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
		log_file="/var/log/utilkit.sh.log"
		timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry="${timestamp} | ${SCRIPTS} - ${VERSION} - $(Txt "$1" | tr -d '\n')"
		Txt "${log_entry}" >>"${log_file}" 2>/dev/null
	fi
}

function ADD() {
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
	mode="pkg"
	failed=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f)
			mode="file"
			shift
			continue
			;;
		-d)
			mode="dir"
			shift
			continue
			;;
		*.deb)
			CHECK_ROOT
			deb_file=$(basename "$1")
			Txt "${CLR3}安裝 DEB 套件［$deb_file］${CLR0}\n"
			GET "$1"
			if [ -f "$deb_file" ]; then
				dpkg -i "$deb_file" || {
					Err "安裝 $deb_file 失敗。請檢查套件相容性和相依性\n"
					rm -f "$deb_file"
					failed=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					Err "修復相依性失敗"
					rm -f "$deb_file"
					failed=1
					shift
					continue
				}
				Txt "* DEB 套件 $deb_file 安裝成功"
				rm -f "$deb_file"
				Txt "${CLR2}完成${CLR0}\n"
			else
				Err "找不到 DEB 套件 $deb_file 或下載失敗\n"
				failed=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "$mode" in
			"file")
				Txt "${CLR3}新增檔案［$1］${CLR0}"
				[ -d "$1" ] && {
					Err "目錄 $1 已存在。無法建立同名檔案\n"
					failed=1
					shift
					continue
				}
				[ -f "$1" ] && {
					Err "檔案 $1 已存在\n"
					failed=1
					shift
					continue
				}
				touch "$1" || {
					Err "建立檔案 $1 失敗。請檢查權限和磁碟空間\n"
					failed=1
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
					failed=1
					shift
					continue
				}
				[ -d "$1" ] && {
					Err "目錄 $1 已存在\n"
					failed=1
					shift
					continue
				}
				mkdir -p "$1" || {
					Err "建立目錄 $1 失敗。請檢查權限和路徑有效性\n"
					failed=1
					shift
					continue
				}
				Txt "* 目錄 $1 建立成功"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"pkg")
				Txt "${CLR3}安裝套件［$1］${CLR0}"
				CHECK_ROOT
				pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf | head -n1)
				pkg_manager=${pkg_manager##*/}
				case $pkg_manager in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					is_installed() {
						case $pkg_manager in
						apk) apk info -e "$1" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "$1" &>/dev/null ;;
						yum | dnf) $pkg_manager list installed "$1" &>/dev/null ;;
						zypper) zypper se -i -x "$1" &>/dev/null ;;
						esac
					}
					install_pkg() {
						case $pkg_manager in
						apk) apk update && apk add "$1" ;;
						apt) apt install -y "$1" ;;
						opkg) opkg update && opkg install "$1" ;;
						pacman) pacman -Sy && pacman -S --noconfirm "$1" ;;
						yum | dnf) $pkg_manager install -y "$1" ;;
						zypper) zypper refresh && zypper install -y "$1" ;;
						esac
					}
					if ! is_installed "$1"; then
						Txt "* 套件 $1 尚未安裝"
						if install_pkg "$1"; then
							if is_installed "$1"; then
								Txt "* 套件 $1 安裝成功"
								Txt "${CLR2}完成${CLR0}\n"
							else
								Err "使用 $pkg_manager 安裝 $1 失敗\n"
								failed=1
								shift
								continue
							fi
						else
							Err "使用 $pkg_manager 安裝 $1 失敗\n"
							failed=1
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
					failed=1
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
	return $failed
}

function CHECK_DEPS() {
	mode="display"
	missing_deps=()
	while [[ "$1" == -* ]]; do
		case "$1" in
		-i) mode="interactive" ;;
		-a) mode="auto" ;;
		*)
			Err "無效的選項：$1"
			return 1
			;;
		esac
		shift
	done
	for dep in "${deps[@]}"; do
		if command -v "$dep" &>/dev/null; then
			status="${CLR2}［可用］${CLR0}"
		else
			status="${CLR1}［缺失］${CLR0}"
			missing_deps+=("$dep")
		fi
		Txt "$status\t$dep"
	done
	[[ ${#missing_deps[@]} -eq 0 ]] && return 0
	case "$mode" in
	"interactive")
		Txt "\n${CLR3}缺少的套件：${CLR0} ${missing_deps[*]}"
		read -p "是否要安裝缺少的套件？(y/N) " -n 1 -r
		Txt
		[[ $REPLY =~ ^[Yy] ]] && ADD "${missing_deps[@]}"
		;;
	"auto")
		Txt
		ADD "${missing_deps[@]}"
		;;
	esac
}
function CHECK_OS() {
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
function CHECK_ROOT() {
	if [ "$EUID" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		Err "請以 root 使用者執行此腳本"
		exit 1
	fi
}
function CHECK_VIRT() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_type=$(systemd-detect-virt 2>/dev/null)
		[ -z "$virt_type" ] && {
			Err "無法偵測虛擬化環境"
			return 1
		}
		case "$virt_type" in
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
		*) Txt "${virt_type:-未偵測到（可能為實體機器）}" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_type=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && Txt "虛擬機器" || Txt "無")
	else
		virt_type="未知"
	fi
}
function CLEAN() {
	cd "$HOME" || {
		Err "切換到 HOME 目錄失敗"
		return 1
	}
	clear
}
function CPU_CACHE() {
	[ ! -f /proc/cpuinfo ] && {
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用"
		return 1
	}
	cpu_cache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "$cpu_cache" = "N/A" ] && {
		Err "無法確定 CPU 快取大小"
		return 1
	}
	Txt "${cpu_cache} KB"
}
function CPU_FREQ() {
	[ ! -f /proc/cpuinfo ] && {
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用"
		return 1
	}
	cpu_freq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "$cpu_freq" = "N/A" ] && {
		Err "無法確定 CPU 頻率"
		return 1
	}
	Txt "${cpu_freq} GHz"
}
function CPU_MODEL() {
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
function CPU_USAGE() {
	read -r cpu user nice system idle iowait irq softirq <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "從 /proc/stat 讀取 CPU 統計資料失敗"
		return 1
	}
	total1=$((user + nice + system + idle + iowait + irq + softirq))
	idle1=$idle
	sleep 0.3
	read -r cpu user nice system idle iowait irq softirq <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		Err "從 /proc/stat 讀取 CPU 統計資料失敗"
		return 1
	}
	total2=$((user + nice + system + idle + iowait + irq + softirq))
	idle2=$idle
	total_diff=$((total2 - total1))
	idle_diff=$((idle2 - idle1))
	usage=$((100 * (total_diff - idle_diff) / total_diff))
	Txt "$usage"
}
function CONVERT_SIZE() {
	[ -z "$1" ] && {
		Err "未提供要轉換的大小值"
		return 2
	}
	size=$1
	unit=${2:-iB}
	unit_lower=$(FORMAT -aa "$unit")
	if ! [[ "$size" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		{
			Err "無效的大小值。必須為數值"
			return 2
		}
	elif [[ "$size" =~ ^[-].*$ ]]; then
		{
			Err "大小值不能為負數"
			return 2
		}
	elif [[ "$size" =~ ^[+].*$ ]]; then
		size=${size#+}
	fi
	case "$unit_lower" in
	b) bytes=$size ;;
	kb | kib) bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "kb" ? 1000 : 1024)}') ;;
	mb | mib) bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "mb" ? 1000000 : 1048576)}') ;;
	gb | gib) bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "gb" ? 1000000000 : 1073741824)}') ;;
	tb | tib) bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "tb" ? 1000000000000 : 1099511627776)}') ;;
	pb | pib) bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "pb" ? 1000000000000000 : 1125899906842624)}') ;;
	*) bytes=$size ;;
	esac
	[[ ! "$bytes" =~ ^[0-9]+\.?[0-9]*$ ]] && {
		Err "轉換大小值失敗"
		return 1
	}
	LC_NUMERIC=C awk -v bytes="$bytes" -v is_binary="$([[ $unit_lower =~ ^.*ib$ ]] && Txt 1 || Txt 0)" '
	BEGIN {
		base = is_binary ? 1024 : 1000
		units = is_binary ? "B KiB MiB GiB TiB PiB" : "B KB MB GB TB PB"
		split(units, unit_array, " ")
		power = 0
		value = bytes
		while (value >= base && power < 5) {
			value /= base
			power++
		}
		if (power == 0) {
			printf "%d %s\n", bytes, unit_array[power + 1]
		} else {
			if (value >= 100) {
				printf "%.1f %s\n", value, unit_array[power + 1]
			} else if (value >= 10) {
				printf "%.2f %s\n", value, unit_array[power + 1]
			} else {
				printf "%.3f %s\n", value, unit_array[power + 1]
			}
		}
	}'
}
function COPYRIGHT() {
	Txt "${SCRIPTS} ${VERSION}"
	Txt "Copyright (C) $(date +%Y) ${ANTHORS}."
}

function DEL() {
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
	mode="pkg"
	failed=0
	while [ $# -gt 0 ]; do
		case "$1" in
		-f)
			mode="file"
			shift
			continue
			;;
		-d)
			mode="dir"
			shift
			continue
			;;
		*)
			Txt "${CLR3}REMOVE $(FORMAT -AA "$mode") [$1]${CLR0}"
			case "$mode" in
			"file")
				[ ! -f "$1" ] && {
					Err "檔案 $1 不存在\n"
					failed=1
					shift
					continue
				}
				Txt "* File $1 exists"
				rm -f "$1" || {
					Err "刪除檔案 $1 失敗\n"
					failed=1
					shift
					continue
				}
				Txt "* File $1 removed successfully"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"dir")
				[ ! -d "$1" ] && {
					Err "目錄 $1 不存在\n"
					failed=1
					shift
					continue
				}
				Txt "* Directory $1 exists"
				rm -rf "$1" || {
					Err "刪除目錄 $1 失敗\n"
					failed=1
					shift
					continue
				}
				Txt "* Directory $1 removed successfully"
				Txt "${CLR2}完成${CLR0}\n"
				;;
			"pkg")
				CHECK_ROOT
				pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf | head -n1)
				pkg_manager=${pkg_manager##*/}
				case $pkg_manager in
				apk | apt | opkg | pacman | yum | zypper | dnf)
					is_installed() {
						case $pkg_manager in
						apk) apk info -e "$1" &>/dev/null ;;
						apt) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "ok installed" ;;
						opkg) opkg list-installed | grep -q "^$1 " ;;
						pacman) pacman -Qi "$1" &>/dev/null ;;
						yum | dnf) $pkg_manager list installed "$1" &>/dev/null ;;
						zypper) zypper se -i -x "$1" &>/dev/null ;;
						esac
					}
					remove_pkg() {
						case $pkg_manager in
						apk) apk del "$1" ;;
						apt) apt purge -y "$1" && apt autoremove -y ;;
						opkg) opkg remove "$1" ;;
						pacman) pacman -Rns --noconfirm "$1" ;;
						yum | dnf) $pkg_manager remove -y "$1" ;;
						zypper) zypper remove -y "$1" ;;
						esac
					}
					if ! is_installed "$1"; then
						Err "* 套件 $1 尚未安裝\n"
						failed=1
						shift
						continue
					fi
					Txt "* Package $1 is installed"
					if ! remove_pkg "$1"; then
						Err "使用 $pkg_manager 移除 $1 失敗\n"
						failed=1
						shift
						continue
					fi
					if is_installed "$1"; then
						Err "使用 $pkg_manager 移除 $1 失敗\n"
						failed=1
						shift
						continue
					fi
					Txt "* Package $1 removed successfully"
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
	return $failed
}
function DISK_USAGE() {
	used=$(df -B1 / | awk '/^\/dev/ {print $3}') || {
		Err "取得磁碟使用統計資料失敗"
		return 1
	}
	total=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		Err "取得總磁碟空間失敗"
		return 1
	}
	percentage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) Txt "${used}" ;;
	-t) Txt "${total}" ;;
	-p) Txt "${percentage}" ;;
	*) Txt "$(CONVERT_SIZE ${used}) / $(CONVERT_SIZE ${total}) (${percentage}%)" ;;
	esac
}
function DNS_ADDR() {
	[ ! -f /etc/resolv.conf ] && {
		Err "找不到 DNS 設定檔 /etc/resolv.conf"
		return 1
	}
	ipv4_servers=()
	ipv6_servers=()
	while read -r server; do
		if [[ ${server} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			ipv4_servers+=("${server}")
		elif [[ ${server} =~ ^[0-9a-fA-F:]+$ ]]; then
			ipv6_servers+=("${server}")
		fi
	done < <(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')
	[[ ${#ipv4_servers[@]} -eq 0 && ${#ipv6_servers[@]} -eq 0 ]] && {
		Err "/etc/resolv.conf 中未設定 DNS 伺服器"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers[@]} -eq 0 ] && {
			Err "找不到 IPv4 DNS 伺服器"
			return 1
		}
		Txt "${ipv4_servers[*]}"
		;;
	-6)
		[ ${#ipv6_servers[@]} -eq 0 ] && {
			Err "找不到 IPv6 DNS 伺服器"
			return 1
		}
		Txt "${ipv6_servers[*]}"
		;;
	*)
		[ ${#ipv4_servers[@]} -eq 0 -a ${#ipv6_servers[@]} -eq 0 ] && {
			Err "找不到 DNS 伺服器"
			return 1
		}
		Txt "${ipv4_servers[*]}   ${ipv6_servers[*]}"
		;;
	esac
}

function FIND() {
	[ $# -eq 0 ] && {
		Err "未指定搜尋條件。請指定要搜尋的內容"
		return 2
	}
	pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf | head -n1)
	case ${pkg_manager##*/} in
	apk) search_command="apk search" ;;
	apt) search_command="apt-cache search" ;;
	opkg) search_command="opkg search" ;;
	pacman) search_command="pacman -Ss" ;;
	yum) search_command="yum search" ;;
	zypper) search_command="zypper search" ;;
	dnf) search_command="dnf search" ;;
	*) {
		Err "找不到或不支援的套件管理器"
		return 1
	} ;;
	esac
	for target in "$@"; do
		Txt "${CLR3}搜尋［$target］${CLR0}"
		${search_command} "${target}" || {
			Err "找不到 $target 的結果\n"
			return 1
		}
		Txt "${CLR2}完成${CLR0}\n"
	done
}
function FONT() {
	font=""
	declare -A style=(
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
			[[ "$1" =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]] && font+="\033[38;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
			;;
		BG.RGB)
			shift
			[[ "$1" =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]] && font+="\033[48;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
			;;
		*) font+="${style[$1]:-}" ;;
		esac
		shift
	done
	Txt "${font}${1}${CLR0}"
}
function FORMAT() {
	option="$1"
	value="$2"
	result=""
	[ -z "$value" ] && {
		Err "未提供要格式化的值"
		return 2
	}
	[ -z "$option" ] && {
		Err "未提供格式化選項"
		return 2
	}
	case "$option" in
	-AA) result=$(Txt "$value" | tr '[:lower:]' '[:upper:]') ;;
	-aa) result=$(Txt "$value" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) result=$(Txt "$value" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) result="$value" ;;
	esac
	Txt "${result}"
}

function GET() {
	extract="false"
	target_dir="."
	rename_file=""
	url=""
	while [ $# -gt 0 ]; do
		case "$1" in
		-x)
			extract=true
			shift
			;;
		-r)
			[ -z "$2" ] || [[ "$2" == -* ]] && {
				Err "-r 選項後未指定檔案名稱"
				return 2
			}
			rename_file="$2"
			shift 2
			;;
		-*) {
			Err "無效的選項：$1"
			return 2
		} ;;
		*)
			[ -z "${url}" ] && url="$1" || target_dir="$1"
			shift
			;;
		esac
	done
	[ -z "${url}" ] && {
		Err "未指定 URL。請提供要下載的 URL"
		return 2
	}
	[[ "${url}" =~ ^(http|https|ftp):// ]] || url="https://${url}"
	output_file="${url##*/}"
	[ -z "${output_file}" ] && output_file="index.html"
	[ "${target_dir}" != "." ] && { mkdir -p "${target_dir}" || {
		Err "建立目錄 $target_dir 失敗"
		return 1
	}; }
	[ -n "${rename_file}" ] && output_file="${rename_file}"
	output_path="${target_dir}/${output_file}"
	url=$(Txt "${url}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR3}下載［$url］${CLR0}"
	file_size=$(curl -sI "${url}" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	if [ -n "${file_size}" ] && [ "${file_size}" -gt 26214400 ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "${url}" -O "${output_path}" || {
			Err "使用 wget 下載檔案失敗"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url}" -o "${output_path}" || {
			Err "使用 curl 下載檔案失敗"
			return 1
		}
	fi
	if [ -f "${output_path}" ]; then
		Txt "* 檔案成功下載至 $output_path"
		if [ "${extract}" = true ]; then
			case "${output_file}" in
			*.tar.gz | *.tgz) tar -xzf "${output_path}" -C "${target_dir}" || {
				Err "解壓縮 tar.gz 檔案失敗"
				return 1
			} ;;
			*.tar) tar -xf "${output_path}" -C "${target_dir}" || {
				Err "解壓縮 tar 檔案失敗"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "${output_path}" -C "${target_dir}" || {
				Err "解壓縮 tar.bz2 檔案失敗"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "${output_path}" -C "${target_dir}" || {
				Err "解壓縮 tar.xz 檔案失敗"
				return 1
			} ;;
			*.zip) unzip "${output_path}" -d "${target_dir}" || {
				Err "解壓縮 zip 檔案失敗"
				return 1
			} ;;
			*.7z) 7z x "${output_path}" -o"${target_dir}" || {
				Err "解壓縮 7z 檔案失敗"
				return 1
			} ;;
			*.rar) unrar x "${output_path}" "${target_dir}" || {
				Err "解壓縮 rar 檔案失敗"
				return 1
			} ;;
			*.zst) zstd -d "${output_path}" -o "${target_dir}" || {
				Err "解壓縮 zst 檔案失敗"
				return 1
			} ;;
			*) Txt "* 無法識別的檔案格式，不進行自動解壓縮" ;;
			esac
			[ $? -eq 0 ] && Txt "* 檔案成功解壓縮至 $target_dir"
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
function INTERFACE() {
	interface=""
	declare -a interfaces=()
	all_interfaces=$(
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
	while read -r interface_item; do
		[ -n "${interface_item}" ] && interfaces[$i]="${interface_item}"
		((i++))
	done <<<"${all_interfaces}"
	interfaces_num="${#interfaces[*]}"
	default4_route=$(ip -4 route show default 2>/dev/null | grep -A 3 "^default" || Txt)
	default6_route=$(ip -6 route show default 2>/dev/null | grep -A 3 "^default" || Txt)
	get_arr_item_idx() {
		item="$1"
		shift
		arr=("$@")
		for ((i = 1; i <= ${#arr[@]}; i++)); do
			if [ "${item}" = "${arr[$i]}" ]; then
				Txt "$i"
				return 0
			fi
		done
		return 255
	}
	interface4=""
	interface6=""
	for ((i = 1; i <= ${#interfaces[@]}; i++)); do
		item="${interfaces[$i]}"
		[ -z "${item}" ] && continue
		if [[ -n "$default4_route" && "$default4_route" == *"${item}"* ]] && [ -z "${interface4}" ]; then
			interface4="${item}"
			interface4_device_order=$(get_arr_item_idx "${item}" "${interfaces[@]}")
		fi
		if [[ -n "$default6_route" && "$default6_route" == *"${item}"* ]] && [ -z "${interface6}" ]; then
			interface6="${item}"
			interface6_device_order=$(get_arr_item_idx "${item}" "${interfaces[@]}")
		fi
		[ -n "${interface4}" ] && [ -n "${interface6}" ] && break
	done
	if [ -z "${interface4}" ] && [ -z "${interface6}" ]; then
		for ((i = 1; i <= ${#interfaces[@]}; i++)); do
			item="${interfaces[$i]}"
			if [[ "${item}" =~ ^en ]]; then
				interface4="${item}"
				interface6="${item}"
				break
			fi
		done
		if [ -z "${interface4}" ] && [ -z "${interface6}" ] && [ "${interfaces_num}" -gt 0 ]; then
			interface4="${interfaces[1]}"
			interface6="${interfaces[1]}"
		fi
	fi
	if [ -n "${interface4}" ] || [ -n "${interface6}" ]; then
		interface="${interface4} ${interface6}"
		[[ "${interface4}" == "${interface6}" ]] && interface="${interface4}"
		interface=$(Txt "${interface}" | tr -s ' ' | xargs)
	else
		physical_iface=$(ip -o link show | grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | grep 'state UP' | head -n 1 | awk -F': ' '{print $2}')
		if [ -n "${physical_iface}" ]; then
			interface="${physical_iface}"
		else
			interface=$(ip -o link show | grep -v 'lo:' | head -n 1 | awk -F': ' '{print $2}')
		fi
	fi
	case "$1" in
	RX_BYTES | RX_PACKETS | RX_DROP | TX_BYTES | TX_PACKETS | TX_DROP)
		for iface in ${interface}; do
			if stats=$(awk -v iface="${iface}" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"${stats}"
				case "$1" in
				RX_BYTES)
					Txt "${rx_bytes}"
					break
					;;
				RX_PACKETS)
					Txt "${rx_packets}"
					break
					;;
				RX_DROP)
					Txt "${rx_drop}"
					break
					;;
				TX_BYTES)
					Txt "${tx_bytes}"
					break
					;;
				TX_PACKETS)
					Txt "${tx_packets}"
					break
					;;
				TX_DROP)
					Txt "${tx_drop}"
					break
					;;
				esac
			fi
		done
		;;
	-i)
		for iface in ${interface}; do
			if stats=$(awk -v iface="${iface}" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"${stats}"
				Txt "${iface}: RX: $(CONVERT_SIZE ${rx_bytes}), TX: $(CONVERT_SIZE ${tx_bytes})"
			fi
		done
		;;
	"") Txt "${interface}" ;;
	*)
		Err "無效的參數：$1。有效的參數為：RX_BYTES、RX_PACKETS、RX_DROP、TX_BYTES、TX_PACKETS、TX_DROP、-i"
		return 2
		;;
	esac
}
function IP_ADDR() {
	flg_IpAddr="$1"
	case "${flg_IpAddr}" in
	-4)
		ipv4_addr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv4_addr}" ] && Txt "${ipv4_addr}" || {
			Err "取得 IPv4 位址失敗。請檢查網路連線"
			return 1
		}
		;;
	-6)
		ipv6_addr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "${ipv6_addr}" ] && Txt "${ipv6_addr}" || {
			Err "取得 IPv6 位址失敗。請檢查網路連線"
			return 1
		}
		;;
	*)
		ipv4_addr=$(IP_ADDR -4)
		ipv6_addr=$(IP_ADDR -6)
		[ -z "${ipv4_addr}${ipv6_addr}" ] && {
			Err "取得 IP 位址失敗"
			return 1
		}
		[ -n "${ipv4_addr}" ] && Txt "IPv4: ${ipv4_addr}"
		[ -n "${ipv6_addr}" ] && Txt "IPv6: ${ipv6_addr}"
		return
		;;
	esac
}

function LAST_UPDATE() {
	if [ -f /var/log/apt/history.log ]; then
		last_update=$(awk '/End-Date:/ {print $2, $3, $4; exit}' /var/log/apt/history.log 2>/dev/null)
	elif [ -f /var/log/dpkg.log ]; then
		last_update=$(tail -n 1 /var/log/dpkg.log | awk '{print $1, $2}')
	elif command -v rpm &>/dev/null; then
		last_update=$(rpm -qa --last | head -n 1 | awk '{print $3, $4, $5, $6, $7}')
	fi
	[ -z "${last_update}" ] && {
		Err "無法確定最後系統更新時間。找不到更新日誌"
		return 1
	} || Txt "${last_update}"
}
function LINE() {
	char="${1:--}"
	length="${2:-80}"
	printf '%*s\n' "${length}" | tr ' ' "${char}" || {
		Err "打印線條失敗"
		return 1
	}
}
function LOAD_AVERAGE() {
	if [ ! -f /proc/loadavg ]; then
		load_data=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			Err "從 uptime 指令取得負載平均值失敗"
			return 1
		}
	else
		read -r zo_mi_LoadAvg zv_mi_LoadAvg ov_mi_LoadAvg _ _ </proc/loadavg || {
			Err "從 /proc/loadavg 讀取負載平均值失敗"
			return 1
		}
	fi
	[[ "${zo_mi_LoadAvg}" =~ ^[0-9.]+$ ]] || zo_mi_LoadAvg=0
	[[ "${zv_mi_LoadAvg}" =~ ^[0-9.]+$ ]] || zv_mi_LoadAvg=0
	[[ "${ov_mi_LoadAvg}" =~ ^[0-9.]+$ ]] || ov_mi_LoadAvg=0
	LC_ALL=C printf "%.2f, %.2f, %.2f (%d cores)" "${zo_mi_LoadAvg}" "${zv_mi_LoadAvg}" "${ov_mi_LoadAvg}" "$(nproc)"
}
function LOCATION() {
	loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^loc=" | cut -d= -f2)
	[ -n "${loc}" ] && Txt "${loc}" || {
		Err "無法偵測地理位置。請檢查網路連線"
		return 1
	}
}

function MAC_ADDR() {
	mac_address=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n "${mac_address}" ]] && Txt "${mac_address}" || {
		Err "無法取得 MAC 位址。找不到網路介面"
		return 1
	}
}
function MEM_USAGE() {
	used=$(free -b | awk '/^Mem:/ {print $3}') || used=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		Err "取得記憶體使用統計資料失敗"
		return 1
	}
	total=$(free -b | awk '/^Mem:/ {print $2}') || total=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	percentage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || percentage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) Txt "${used}" ;;
	-t) Txt "${total}" ;;
	-p) Txt "${percentage}" ;;
	*) Txt "$(CONVERT_SIZE ${used}) / $(CONVERT_SIZE ${total}) (${percentage}%)" ;;
	esac
}

function NET_PROVIDER() {
	result=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		result=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		result=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "${result}" ] && Txt "${result}" || {
		Err "無法偵測網路供應商。請檢查網路連線"
		return 1
	}
}

function PKG_COUNT() {
	pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf 2>/dev/null | head -n1)
	case ${pkg_manager##*/} in
	apk) count_cmd="apk info" ;;
	apt) count_cmd="dpkg --get-selections" ;;
	opkg) count_cmd="opkg list-installed" ;;
	pacman) count_cmd="pacman -Q" ;;
	yum | dnf) count_cmd="rpm -qa" ;;
	zypper) count_cmd="zypper se --installed-only" ;;
	*) {
		Err "無法計算已安裝的套件。軟體包管理器不支援"
		return 1
	} ;;
	esac
	if ! pkg_count=$("${count_cmd}" 2>/dev/null | wc -l) || [[ -z "${pkg_count}" || "${pkg_count}" -eq 0 ]]; then
		{
			Err "計算 ${pkg_manager##*/} 的套件數量失敗"
			return 1
		}
	fi
	Txt "${pkg_count}"
}
function PROGRESS() {
	num_cmds=${#cmds[@]}
	term_width=$(tput cols) || {
		Err "取得終端機寬度失敗"
		return 1
	}
	bar_width=$((term_width - 23))
	stty -echo
	trap '' SIGINT SIGQUIT SIGTSTP
	for ((i = 0; i < num_cmds; i++)); do
		progress=$((i * 100 / num_cmds))
		filled_width=$((progress * bar_width / 100))
		printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "${progress}" "$(printf "%${filled_width}s" | tr ' ' '#')" "$(printf "%$((bar_width - filled_width))s" | tr ' ' '.')"
		if ! output=$(eval "${cmds[$i]}" 2>&1); then
			Txt "\n$output"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				Err "命令執行失敗：${cmds[$i]}"
				return 1
			}
		fi
	done
	printf "\r\033[30;42mProgress: [100%%]\033[0m [%s]" "$(printf "%${bar_width}s" | tr ' ' '#')"
	printf "\r%${term_width}s\r"
	stty echo
	trap - SIGINT SIGQUIT SIGTSTP
}
function PUBLIC_IP() {
	ip=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^ip=" | cut -d= -f2)
	[ -n "${ip}" ] && Txt "${ip}" || {
		Err "無法偵測公開 IP 位址。請檢查網路連線"
		return 1
	}
}

function RUN() {
	commands=()
	# ADD bash-completion &>/dev/null
	_run_completions() {
		cur="${COMP_WORDS[COMP_CWORD]}"
		prev="${COMP_WORDS[COMP_CWORD - 1]}"
		opts="${commands[*]}"
		COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
		[[ ${#COMPREPLY[@]} -eq 0 ]] && COMPREPLY=($(compgen -c -- "${cur}"))
	}
	complete -F _run_completions RUN
	[ $# -eq 0 ] && {
		Err "未指定命令"
		return 2
	}
	if [[ "$1" == *"/"* ]]; then
		if [[ "$1" =~ ^https?:// ]]; then
			url="$1"
			script_name=$(basename "$1")
			delete_after=false
			shift
			while [[ $# -gt 0 && "$1" == -* ]]; do
				case "$1" in
				-d)
					delete_after=true
					shift
					;;
				*) break ;;
				esac
			done
			Txt "${CLR3}正在從 URL 下載並執行腳本 [${script_name}]${CLR0}"
			TASK "* 下載腳本" "
				curl -sSLf "${url}" -o "${script_name}" || { Err "下載腳本 $script_name 失敗"; return 1; }
				chmod +x "${script_name}" || { Err "設定腳本 $script_name 執行權限失敗"; return 1; }
			"
			Txt "${CLR8}$(LINE = "24")${CLR0}"
			if [[ "$1" == "--" ]]; then
				shift
				./"${script_name}" "$@" || {
					Err "執行腳本 $script_name 失敗"
					return 1
				}
			else
				./"${script_name}" || {
					Err "執行腳本 $script_name 失敗"
					return 1
				}
			fi
			Txt "${CLR8}$(LINE = "24")${CLR0}"
			Txt "${CLR2}完成${CLR0}\n"
			[[ "${delete_after}" == true ]] && rm -rf "${script_name}"
		elif [[ "$1" =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner=$(Txt "$1" | cut -d'/' -f1)
			repo_name=$(Txt "$1" | cut -d'/' -f2)
			script_path=$(Txt "$1" | cut -d'/' -f3-)
			script_name=$(basename "${script_path}")
			branch="main"
			download_repo=false
			delete_after=false
			shift
			while [[ $# -gt 0 && "$1" == -* ]]; do
				case "$1" in
				-b)
					[[ -z "$2" || "$2" == -* ]] && {
						Err "-b 後需要分支名稱"
						return 2
					}
					branch="$2"
					shift 2
					;;
				-r)
					download_repo=true
					shift
					;;
				-d)
					delete_after=true
					shift
					;;
				*) break ;;
				esac
			done
			if [[ "$download_repo" == true ]]; then
				Txt "${CLR3}正在克隆儲存庫 ${repo_owner}/${repo_name}${CLR0}"
				[[ -d "${repo_name}" ]] && {
					Err "目錄 $repo_name 已存在"
					return 1
				}
				temp_dir=$(mktemp -d)
				if [[ "${branch}" != "main" ]]; then
					TASK "* 正在從分支 $branch 克隆" "git clone --branch ${branch} https://github.com/${repo_owner}/${repo_name}.git ${temp_dir}"
					if [ $? -ne 0 ]; then
						rm -rf "${temp_dir}"
						{
							Err "從分支 $branch 克隆儲存庫失敗"
							return 1
						}
					fi
				else
					TASK "* 檢查 main 分支" "git clone --branch main https://github.com/${repo_owner}/${repo_name}.git ${temp_dir}" true
					if [ $? -ne 0 ]; then
						TASK "* 嘗試 master 分支" "git clone --branch master https://github.com/${repo_owner}/${repo_name}.git ${temp_dir}"
						if [ $? -ne 0 ]; then
							rm -rf "${temp_dir}"
							{
								Err "從 main 或 master 分支克隆儲存庫失敗"
								return 1
							}
						fi
					fi
				fi
				TASK "* 建立目標目錄" "ADD -d "${repo_name}" && cp -r "${temp_dir}"/* "${repo_name}"/"
				TASK "* 清理暫存檔案" "rm -rf "${temp_dir}""
				Txt "儲存庫已克隆到目錄：${CLR2}$repo_name"
				if [[ -f "${repo_name}/${script_path}" ]]; then
					TASK "* 設定執行權限" "chmod +x "${repo_name}/${script_path}""
					Txt "${CLR8}$(LINE = "24")${CLR0}"
					if [[ "$1" == "--" ]]; then
						shift
						./"${repo_name}/${script_path}" "$@" || {
							Err "執行腳本 $script_name 失敗"
							return 1
						}
					else
						./"${repo_name}/${script_path}" || {
							Err "執行腳本 $script_name 失敗"
							return 1
						}
					fi
					Txt "${CLR8}$(LINE = "24")${CLR0}"
					Txt "${CLR2}完成${CLR0}\n"
					[[ "${delete_after}" == true ]] && rm -rf "${repo_name}"
				fi
			else
				Txt "${CLR3}正在從 ${repo_owner}/${repo_name} 下載並執行腳本 [${script_name}]${CLR0}"
				github_url="https://raw.githubusercontent.com/${repo_owner}/${repo_name}/refs/heads/${branch}/${script_path}"
				if [[ "${branch}" != "main" ]]; then
					TASK "* 檢查分支 $branch" "curl -sLf "${github_url}" >/dev/null"
					[ $? -ne 0 ] && {
						Err "在分支 $branch 中找不到腳本"
						return 1
					}
				else
					TASK "* 檢查 main 分支" "curl -sLf "${github_url}" >/dev/null" true
					if [ $? -ne 0 ]; then
						TASK "* 檢查 master 分支" "
							branch="master"
							github_url="https://raw.githubusercontent.com/${repo_owner}/${repo_name}/refs/heads/master/${script_path}"
							curl -sLf "${github_url}" >/dev/null
						"
						[ $? -ne 0 ] && {
							Err "在 main 或 master 分支中找不到腳本"
							return 1
						}
					fi
				fi
				TASK "* 下載腳本" "
					curl -sSLf \"${github_url}\" -o \"${script_name}\" || { 
						Err \"下載腳本 $script_name 失敗\"
						Err \"從 $github_url 下載失敗\"
						return 1
					}

					if [[ ! -f \"${script_name}\" ]]; then
						Err \"下載失敗：未建立檔案\"
						return 1
					fi

					if [[ ! -s \"${script_name}\" ]]; then
						Err \"下載的檔案為空\"
						cat \"${script_name}\" 2>/dev/null || Txt \"（無法顯示檔案內容）\"
						return 1
					fi

					if ! grep -q '[^[:space:]]' \"${script_name}\"; then
						Err \"下載的檔案僅包含空白字元\"
						return 1
					fi

					chmod +x \"${script_name}\" || { 
						Err \"設定腳本 $script_name 執行權限失敗\"
						Err \"無法設定 $script_name 的執行權限\"
						ls -la \"${script_name}\"
						return 1
					}
				"

				Txt "${CLR8}$(LINE = "24")${CLR0}"
				if [[ -f "${script_name}" ]]; then
					if [[ "$1" == "--" ]]; then
						shift
						./"${script_name}" "$@" || {
							Err "執行腳本 $script_name 失敗"
							return 1
						}
					else
						./"${script_name}" || {
							Err "執行腳本 $script_name 失敗"
							return 1
						}
					fi
				else
					Err "腳本檔案 '$script_name' 未成功下載"
					return 1
				fi
				Txt "${CLR8}$(LINE = "24")${CLR0}"
				Txt "${CLR2}完成${CLR0}\n"
				[[ "${delete_after}" == true ]] && rm -rf "${script_name}"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path="$1"
			if [[ "$2" == "--" ]]; then
				shift 2
				"${script_path}" "$@" || {
					Err "執行腳本 $script_name 失敗"
					return 1
				}
			else
				shift
				"${script_path}" "$@" || {
					Err "執行腳本 $script_name 失敗"
					return 1
				}
			fi
		fi
	else
		eval "$*"
	fi
	rm -rf /tmp/* &>/dev/null
}

function SHELL_VER() {
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
function SWAP_USAGE() {
	used=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	total=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	percentage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) Txt "${used}" ;;
	-t) Txt "${total}" ;;
	-p) Txt "${percentage}" ;;
	*) Txt "$(CONVERT_SIZE ${used}) / $(CONVERT_SIZE ${total}) (${percentage}%)" ;;
	esac
}
function SYS_CLEAN() {
	CHECK_ROOT
	Txt "${CLR3}正在執行系統清理...${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"
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
			((wait_time++))
			[ "${wait_time}" -gt 300 ] && {
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
		TASK "* 輪替和清理 journalctl 日誌" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			Err "輪替和清理 journalctl 日誌失敗"
			return 1
		}
	fi
	TASK "* 移除暫存檔案" "rm -rf /tmp/*" || {
		Err "移除暫存檔案失敗"
		return 1
	}
	for cmd in docker npm pip; do
		if command -v "${cmd}" &>/dev/null; then
			case "${cmd}" in
			docker) TASK "* 清理 Docker 系統" "docker system prune -af" || {
				Err "清理 Docker 系統失敗"
				return 1
			} ;;
			npm) TASK "* 清理 NPM 快取" "npm cache clean --force" || {
				Err "清理 NPM 快取失敗"
				return 1
			} ;;
			pip) TASK "* 清除 PIP 快取" "pip cache purge" || {
				Err "清除 PIP 快取失敗"
				return 1
			} ;;
			esac
		fi
	done
	TASK "* 移除使用者快取檔案" "rm -rf ~/.cache/*" || {
		Err "移除使用者快取檔案失敗"
		return 1
	}
	TASK "* 移除縮圖檔案" "rm -rf ~/.thumbnails/*" || {
		Err "移除縮圖檔案失敗"
		return 1
	}
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SYS_INFO() {
	Txt "${CLR3}系統資訊${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"

	Txt "- 主機名稱：		${CLR2}$(uname -n || {
		Err "取得主機名稱失敗"
		return 1
	})${CLR0}"
	Txt "- 作業系統：		${CLR2}$(CHECK_OS)${CLR0}"
	Txt "- 核心版本：		${CLR2}$(uname -r)${CLR0}"
	Txt "- 系統語言：		${CLR2}$LANG${CLR0}"
	Txt "- Shell 版本：		${CLR2}$(SHELL_VER)${CLR0}"
	Txt "- 最後系統更新：	${CLR2}$(LAST_UPDATE)${CLR0}"
	Txt "${CLR8}$(LINE - "32")${CLR0}"

	Txt "- 架構：		${CLR2}$(uname -m)${CLR0}"
	Txt "- CPU 型號：		${CLR2}$(CPU_MODEL)${CLR0}"
	Txt "- CPU 核心數：		${CLR2}$(nproc)${CLR0}"
	Txt "- CPU 頻率：		${CLR2}$(CPU_FREQ)${CLR0}"
	Txt "- CPU 使用率：		${CLR2}$(CPU_USAGE)%${CLR0}"
	Txt "- CPU 快取：		${CLR2}$(CPU_CACHE)${CLR0}"
	Txt "${CLR8}$(LINE - "32")${CLR0}"

	Txt "- 記憶體使用率：	${CLR2}$(MEM_USAGE)${CLR0}"
	Txt "- Swap 使用率：		${CLR2}$(SWAP_USAGE)${CLR0}"
	Txt "- 磁碟使用率：		${CLR2}$(DISK_USAGE)${CLR0}"
	Txt "- 檔案系統類型：	${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	Txt "${CLR8}$(LINE - "32")${CLR0}"

	Txt "- IPv4 地址：		${CLR2}$(IP_ADDR -4)${CLR0}"
	Txt "- IPv6 地址：		${CLR2}$(IP_ADDR -6)${CLR0}"
	Txt "- MAC 位址：		${CLR2}$(MAC_ADDR)${CLR0}"
	Txt "- 網路供應商：		${CLR2}$(NET_PROVIDER)${CLR0}"
	Txt "- DNS 伺服器：		${CLR2}$(DNS_ADDR)${CLR0}"
	Txt "- 公開 IP：		${CLR2}$(PUBLIC_IP)${CLR0}"
	Txt "- 網路介面：		${CLR2}$(INTERFACE -i)${CLR0}"
	Txt "- 內部時區：		${CLR2}$(TIMEZONE -i)${CLR0}"
	Txt "- 外部時區：		${CLR2}$(TIMEZONE -e)${CLR0}"
	Txt "${CLR8}$(LINE - "32")${CLR0}"

	Txt "- 負載平均：		${CLR2}$(LOAD_AVERAGE)${CLR0}"
	Txt "- 程序數量：		${CLR2}$(ps aux | wc -l)${CLR0}"
	Txt "- 已安裝套件：		${CLR2}$(PKG_COUNT)${CLR0}"
	Txt "${CLR8}$(LINE - "32")${CLR0}"

	Txt "- 運行時間：		${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	Txt "- 啟動時間：		${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	Txt "${CLR8}$(LINE - "32")${CLR0}"

	Txt "- 虛擬化：		${CLR2}$(CHECK_VIRT)${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"
}
function SYS_OPTIMIZE() {
	CHECK_ROOT
	Txt "${CLR3}正在優化長期運行伺服器的系統設定...${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	sysctl_conf_SysOptimize="/etc/sysctl.d/99-server-optimizations.conf"
	Txt "# 長期運行系統的伺服器優化" >"${sysctl_conf_SysOptimize}"

	TASK "* 正在優化記憶體管理" "
		Txt 'vm.swappiness = 1' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.vfs_cache_pressure = 50' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_ratio = 15' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.dirty_background_ratio = 5' >> ${sysctl_conf_SysOptimize}
		Txt 'vm.min_free_kbytes = 65536' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "優化記憶體管理失敗"
		return 1
	}

	TASK "* 正在優化網路設定" "
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

	TASK "* 正在優化 TCP 緩衝區" "
		Txt 'net.core.rmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.core.wmem_max = 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> ${sysctl_conf_SysOptimize}
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "優化 TCP 緩衝區失敗"
		return 1
	}

	TASK "* 正在優化檔案系統設定" "
		Txt 'fs.file-max = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.nr_open = 2097152' >> ${sysctl_conf_SysOptimize}
		Txt 'fs.inotify.max_user_watches = 524288' >> ${sysctl_conf_SysOptimize}
	" || {
		Err "優化檔案系統設定失敗"
		return 1
	}

	TASK "* 正在優化系統限制" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		Err "優化系統限制失敗"
		return 1
	}

	TASK "* 正在優化 I/O 排程器" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		Err "優化 I/O 排程器失敗"
		return 1
	}

	TASK "* 停用非必要服務" "
		for service in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now \$service 2>/dev/null || true
		done
	" || {
		Err "停用服務失敗"
		return 1
	}

	TASK "* 套用系統參數" "sysctl -p ${sysctl_conf_SysOptimize}" || {
		Err "套用系統參數失敗"
		return 1
	}

	TASK "* 清除系統快取" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		Err "清除系統快取失敗"
		return 1
	}

	Txt "${CLR8}$(LINE = "24")${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SYS_REBOOT() {
	CHECK_ROOT
	Txt "${CLR3}正在準備重新啟動系統...${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	active_users=$(who | wc -l) || {
		Err "取得活動使用者數量失敗"
		return 1
	}
	if [ "${active_users}" -gt 1 ]; then
		Txt "${CLR1}警告：目前系統有 $active_users 個活動使用者${CLR0}\n"
		Txt "活動使用者："
		who | awk '{print $1 " since " $3 " " $4}'
		Txt
	fi
	important_processes=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		Err "檢查執行中的程序失敗"
		return 1
	}
	if [ "${important_processes}" -gt 0 ]; then
		Txt "${CLR1}警告：有 $important_processes 個重要程序正在執行${CLR0}\n"
		Txt "${CLR8}CPU 使用率最高的 5 個程序：${CLR0}"
		ps aux --sort=-%cpu | head -n 6
		Txt
	fi
	read -p "您確定要立即重新啟動系統嗎？(y/N) " -n 1 -r continue_reboot
	Txt
	[[ ! "${continue_reboot}" =~ ^[Yy]$ ]] && {
		Txt "${CLR2}已取消重新啟動${CLR0}\n"
		return 0
	}
	TASK "* 執行最終檢查" "sync" || {
		Err "同步檔案系統失敗"
		return 1
	}
	TASK "* 開始重新啟動" "reboot || sudo reboot" || {
		Err "啟動重新啟動失敗"
		return 1
	}
	Txt "${CLR2}已成功發出重新啟動命令。系統將立即重新啟動${CLR0}"
}
function SYS_UPDATE() {
	CHECK_ROOT
	Txt "${CLR3}正在更新系統軟體...${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	update_pkgs() {
		cmd="$1"
		update_cmd="$2"
		upgrade_cmd="$3"
		Txt "* 正在更新套件清單"
		${update_cmd} || {
			Err "使用 $cmd 更新套件清單失敗"
			return 1
		}
		Txt "* 正在升級套件"
		${upgrade_cmd} || {
			Err "使用 $cmd 升級套件失敗"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) update_pkgs "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			TASK "* 等待 dpkg 鎖定" "sleep 1" || return 1
			((wait_time++))
			[ "${wait_time}" -gt 10 ] && {
				Err "等待 dpkg 鎖定釋放超時"
				return 1
			}
		done
		TASK "* 設定待處理的套件" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			Err "設定待處理的套件失敗"
			return 1
		}
		update_pkgs "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) update_pkgs "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) TASK "* 更新和升級套件" "pacman -Syu --noconfirm" || {
		Err "使用 pacman 更新和升級套件失敗"
		return 1
	} ;;
	*yum) update_pkgs "yum" "yum check-update" "yum -y update" ;;
	*zypper) update_pkgs "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) update_pkgs "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		Err "不支援的套件管理器"
		return 1
	} ;;
	esac
	Txt "* 正在更新 $Scripts"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/get_utilkit.sh) || {
		Err "更新 $Scripts 失敗"
		return 1
	}
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	Txt "${CLR2}完成${CLR0}\n"
}
function SYS_UPGRADE() {
	CHECK_ROOT
	Txt "${CLR3}正在升級系統至下一個主要版本...${CLR0}"
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	os_name=$(CHECK_OS -n)
	case "${os_name}" in
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
		current_codename=$(lsb_release -cs)
		target_codename=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "${cur}rent_codename" = "${target_codename}" ] && {
			Err "系統已經是最新的穩定版本 (${target_codename})"
			return 1
		}
		Txt "* 正在從 ${CLR2}${current_codename}${CLR0} 升級到 ${CLR3}${target_codename}${CLR0}"
		TASK "* 備份 sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			Err "備份 sources.list 失敗"
			return 1
		}
		TASK "* 更新 sources.list" "sed -i 's/${current_codename}/${target_codename}/g' /etc/apt/sources.list" || {
			Err "更新 sources.list 失敗"
			return 1
		}
		TASK "* 更新新版本的套件清單" "apt update -y" || {
			Err "更新新版本的套件清單失敗"
			return 1
		}
		TASK "* 升級到新的 Debian 版本" "apt full-upgrade -y" || {
			Err "升級到新的 Debian 版本失敗"
			return 1
		}
		;;
	Ubuntu)
		Txt "* 偵測到 'Ubuntu' 系統"
		TASK "* 正在更新套件清單" "apt update -y" || {
			Err "使用 apt 更新套件清單失敗"
			return 1
		}
		TASK "* 正在升級目前的套件" "apt full-upgrade -y" || {
			Err "升級目前的套件失敗"
			return 1
		}
		TASK "* 安裝 update-manager-core" "apt install -y update-manager-core" || {
			Err "安裝 update-manager-core 失敗"
			return 1
		}
		TASK "* 升級 Ubuntu 版本" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			Err "升級 Ubuntu 版本失敗"
			return 1
		}
		SYS_REBOOT
		;;
	*) {
		Err "您的系統尚不支援主要版本升級"
		return 1
	} ;;
	esac
	Txt "${CLR8}$(LINE = "24")${CLR0}"
	Txt "${CLR2}系統升級完成${CLR0}\n"
}

function TASK() {
	message="$1"
	command="$2"
	ignore_error=${3:-false}
	temp_file=$(mktemp)
	Txt -n "${message}..."
	if eval "${command}" >"${temp_file}" 2>&1; then
		Txt "${CLR2}完成${CLR0}"
		ret=0
	else
		ret=$?
		Txt "${CLR1}失敗${CLR0} (${ret})"
		[[ -s "${temp_file}" ]] && Txt "${CLR1}$(cat ${temp_file})${CLR0}"
		[[ "${ignore_error}" != "true" ]] && return "${ret}"
	fi
	rm -f "${temp_file}"
	return "${ret}"
}
function TIMEZONE() {
	case "$1" in
	-e)
		result=$(timeout 1s curl -sL ipapi.co/timezone) ||
			result=$(timeout 1s curl -sL worldtimeapi.org/api/ip | grep -oP '"timezone":"\K[^"]+') ||
			result=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"timezone":"\K[^"]+') ||
			[ -n "${result}" ] && Txt "${result}" || {
			Err "從外部服務偵測時區失敗"
			return 1
		}
		;;
	-i | *)
		result=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			result=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			result=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "${result}" ] && Txt "${result}" || {
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