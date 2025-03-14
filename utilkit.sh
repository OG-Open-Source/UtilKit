#!/bin/bash

Authors="OG-Open-Source"
Scripts="utilkit.sh"
Version="6.043.008.238"

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

LC_ALL=C
LANG=C

text() { echo -e "$1"; }
error() {
	[ -z "$1" ] && {
		text "*#Xk9pL2#*"
		return 1
	}
	text "${CLR1}$1${CLR0}"
	if [ -w "/var/log" ]; then
		log_file="/var/log/ogos-error.log"
		timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry="${timestamp} | ${Scripts} - ${Version} - $(text "$1" | tr -d '\n')"
		text "${log_entry}" >>"${log_file}" 2>/dev/null
	fi
}

function ADD() {
	[ $# -eq 0 ] && {
		error "*#Ht5mK8#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		error "*#Qw3nR7#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		error "*#Qw3nR7#*"
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
			text "*#Ym6pN4#*\n"
			GET "$1"
			if [ -f "$deb_file" ]; then
				dpkg -i "$deb_file" || {
					error "*#Bx5kM9#*\n"
					rm -f "$deb_file"
					failed=1
					shift
					continue
				}
				apt --fix-broken install -y || {
					error "*#Vt4jK7#*"
					rm -f "$deb_file"
					failed=1
					shift
					continue
				}
				text "*#Gz7tP5#*"
				rm -f "$deb_file"
				text "*#Rt9nK6#*\n"
			else
				error "*#Jh2mP8#*\n"
				failed=1
				shift
				continue
			fi
			shift
			;;
		*)
			case "$mode" in
			"file")
				text "*#Wn5tM9#*"
				[ -d "$1" ] && {
					error "*#Cx7kR4#*\n"
					failed=1
					shift
					continue
				}
				[ -f "$1" ] && {
					error "*#Fx3pL8#*\n"
					failed=1
					shift
					continue
				}
				touch "$1" || {
					error "*#Dw9nM5#*\n"
					failed=1
					shift
					continue
				}
				text "*#Uz2xK7#*"
				text "*#Rt9nK6#*\n"
				;;
			"dir")
				text "*#Yt6mK2#*"
				[ -f "$1" ] && {
					error "*#Lp5tR2#*\n"
					failed=1
					shift
					continue
				}
				[ -d "$1" ] && {
					error "*#Wx7nJ4#*\n"
					failed=1
					shift
					continue
				}
				mkdir -p "$1" || {
					error "*#Ht5kM8#*\n"
					failed=1
					shift
					continue
				}
				text "*#Kz9pR4#*"
				text "*#Rt9nK6#*\n"
				;;
			"pkg")
				text "*#Kt7vL2#*"
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
						text "*#Pn8kR5#*"
						if install_pkg "$1"; then
							if is_installed "$1"; then
								text "*#Jt6mN4#*"
								text "*#Rt9nK6#*\n"
							else
								error "*#Hv7pL3#*\n"
								failed=1
								shift
								continue
							fi
						else
							error "*#Hv7pL3#*\n"
							failed=1
							shift
							continue
						fi
					else
						text "*#Bk4nM7#*"
						text "*#Rt9nK6#*\n"
					fi
					;;
				*)
					error "*#Zx7mP4#*\n"
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
			error "*#Kp7mN4#*"
			return 1
			;;
		esac
		shift
	done
	for dep in "${deps[@]}"; do
		if command -v "$dep" &>/dev/null; then
			status="*#Bw5tR9#*"
		else
			status="*#Ht6pL2#*"
			missing_deps+=("$dep")
		fi
		text "$status\t$dep"
	done
	[[ ${#missing_deps[@]} -eq 0 ]] && return 0
	case "$mode" in
	"interactive")
		text "\n*#Jk4nR7#* ${missing_deps[*]}"
		read -p "*#Ym6tK8#*" -n 1 -r
		text "\n"
		[[ $REPLY =~ ^[Yy] ]] && ADD "${missing_deps[@]}"
		;;
	"auto")
		text
		ADD "${missing_deps[@]}"
		;;
	esac
}
function CHECK_OS() {
	case "$1" in
	-v)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "$ID" = "debian" ] && cat /etc/debian_version || text "$VERSION_ID"
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
				error "*#Rn5kP8#*"
				return 1
			}
		fi
		;;
	-n)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			text "$ID" | sed 's/.*/\u&/'
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2 | awk '{print $1}'
		else
			{
				error "*#Wm7tL4#*"
				return 1
			}
		fi
		;;
	*)
		if [ -f /etc/os-release ]; then
			source /etc/os-release
			[ "$ID" = "debian" ] && text "$NAME $(cat /etc/debian_version)" || text "$PRETTY_NAME"
		elif [ -f /etc/DISTRO_SPECS ]; then
			grep -i "DISTRO_NAME" /etc/DISTRO_SPECS | cut -d'=' -f2
		else
			{
				error "*#Wm7tL4#*"
				return 1
			}
		fi
		;;
	esac
}
function CHECK_ROOT() {
	if [ "$EUID" -ne 0 ] || [ "$(id -u)" -ne 0 ]; then
		error "*#Yk4mN8#*"
		exit 1
	fi
}
function CHECK_VIRT() {
	if command -v systemd-detect-virt >/dev/null 2>&1; then
		virt_type=$(systemd-detect-virt 2>/dev/null)
		[ -z "$virt_type" ] && {
			error "*#Vt8nP4#*"
			return 1
		}
		case "$virt_type" in
		kvm) grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null && text "Proxmox VE (KVM)" || text "KVM" ;;
		microsoft) text "Microsoft Hyper-V" ;;
		none)
			if grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
				text "*#Zx6mL2#*"
			elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
				text "*#Yt4pM7#*"
			else
				text "*#Fn2kP5#*"
			fi
			;;
		*) text "${virt_type:-*#Fn2kP5#*}" ;;
		esac
	elif [ -f /proc/cpuinfo ]; then
		virt_type=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null && text "*#Hk9nR2#*" || text "*#Qw8kL5#*")
	else
		virt_type="*#Dn6tM3#*"
	fi
}
function CLEAN() {
	cd "$HOME" || {
		error "*#Jm5tK8#*"
		return 1
	}
	clear
}
function CPU_CACHE() {
	[ ! -f /proc/cpuinfo ] && {
		error "*#Kw7nP5#*"
		return 1
	}
	cpu_cache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
	[ "$cpu_cache" = "N/A" ] && {
		error "*#Bx5tR9#*"
		return 1
	}
	text "${cpu_cache} KB"
}
function CPU_FREQ() {
	[ ! -f /proc/cpuinfo ] && {
		error "*#Kw7nP5#*"
		return 1
	}
	cpu_freq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	[ "$cpu_freq" = "N/A" ] && {
		error "*#Rw6tK9#*"
		return 1
	}
	text "${cpu_freq} GHz"
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
			text "${CLR1}*#Dn6tM3#*${CLR0}"
			return 1
		}
	fi
}
function CPU_USAGE() {
	read -r cpu user nice system idle iowait irq softirq <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		error "*#Ht7mK4#*"
		return 1
	}
	total1=$((user + nice + system + idle + iowait + irq + softirq))
	idle1=$idle
	sleep 0.3
	read -r cpu user nice system idle iowait irq softirq <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat) || {
		error "*#Ht7mK4#*"
		return 1
	}
	total2=$((user + nice + system + idle + iowait + irq + softirq))
	idle2=$idle
	total_diff=$((total2 - total1))
	idle_diff=$((idle2 - idle1))
	usage=$((100 * (total_diff - idle_diff) / total_diff))
	text "$usage"
}
function CONVERT_SIZE() {
	[ -z "$1" ] && {
		error "*#Jk4mN8#*"
		return 2
	}
	size=$1
	unit=${2:-iB}
	unit_lower=$(FORMAT -aa "$unit")
	if ! [[ "$size" =~ ^[+-]?[0-9]*\.?[0-9]+$ ]]; then
		{
			error "*#Wx5vR7#*"
			return 2
		}
	elif [[ "$size" =~ ^[-].*$ ]]; then
		{
			error "*#Bm2kL6#*"
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
		error "*#Dn7tR4#*"
		return 1
	}
	LC_NUMERIC=C awk -v bytes="$bytes" -v is_binary="$([[ $unit_lower =~ ^.*ib$ ]] && text 1 || text 0)" '
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
	text "$Scripts $Version"
	text "Copyright (C) $(date +%Y) $Authors."
}

function DEL() {
	[ $# -eq 0 ] && {
		error "*#Yt5mP8#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ $# -eq 1 ] && {
		error "*#Qw3nR7#*"
		return 2
	}
	[ "$1" = "-f" -o "$1" = "-d" ] && [ "$2" = "" ] && {
		error "*#Qw3nR7#*"
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
			text "${CLR3}REMOVE $(FORMAT -AA "$mode") [$1]${CLR0}"
			case "$mode" in
			"file")
				[ ! -f "$1" ] && {
					error "*#Lm7tK4#*\n"
					failed=1
					shift
					continue
				}
				text "* File $1 exists"
				rm -f "$1" || {
					error "*#Wx9nL6#*\n"
					failed=1
					shift
					continue
				}
				text "* File $1 removed successfully"
				text "*#Rt9nK6#*\n"
				;;
			"dir")
				[ ! -d "$1" ] && {
					error "*#Dn6kP3#*\n"
					failed=1
					shift
					continue
				}
				text "* Directory $1 exists"
				rm -rf "$1" || {
					error "*#Hm8wR5#*\n"
					failed=1
					shift
					continue
				}
				text "* Directory $1 removed successfully"
				text "*#Rt9nK6#*\n"
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
						error "*#Pn8kR5#*\n"
						failed=1
						shift
						continue
					fi
					text "* Package $1 is installed"
					if ! remove_pkg "$1"; then
						error "*#Qn5tR2#*\n"
						failed=1
						shift
						continue
					fi
					if is_installed "$1"; then
						error "*#Qn5tR2#*\n"
						failed=1
						shift
						continue
					fi
					text "* Package $1 removed successfully"
					text "*#Rt9nK6#*\n"
					;;
				*) {
					error "*#Zx7mP4#*"
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
		error "*#Ht5nK9#*"
		return 1
	}
	total=$(df -B1 / | awk '/^\/dev/ {print $2}') || {
		error "*#Yt8pR2#*"
		return 1
	}
	percentage=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "$1" in
	-u) text "$used" ;;
	-t) text "$total" ;;
	-p) text "$percentage" ;;
	*) text "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)" ;;
	esac
}
function DNS_ADDR() {
	[ ! -f /etc/resolv.conf ] && {
		error "*#Rw6nK8#*"
		return 1
	}
	ipv4_servers=()
	ipv6_servers=()
	while read -r server; do
		if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			ipv4_servers+=("$server")
		elif [[ $server =~ ^[0-9a-fA-F:]+$ ]]; then
			ipv6_servers+=("$server")
		fi
	done < <(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')
	[[ ${#ipv4_servers[@]} -eq 0 && ${#ipv6_servers[@]} -eq 0 ]] && {
		error "*#Bx5tP7#*"
		return 1
	}
	case "$1" in
	-4)
		[ ${#ipv4_servers[@]} -eq 0 ] && {
			error "*#Vt7mR3#*"
			return 1
		}
		text "${ipv4_servers[*]}"
		;;
	-6)
		[ ${#ipv6_servers[@]} -eq 0 ] && {
			error "*#Qw8kL6#*"
			return 1
		}
		text "${ipv6_servers[*]}"
		;;
	*)
		[ ${#ipv4_servers[@]} -eq 0 -a ${#ipv6_servers[@]} -eq 0 ] && {
			error "*#Jn3vK7#*"
			return 1
		}
		text "${ipv4_servers[*]}   ${ipv6_servers[*]}"
		;;
	esac
}

function FIND() {
	[ $# -eq 0 ] && {
		error "*#Zt5kP8#*"
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
		error "*#Bx9nK5#*"
		return 1
	} ;;
	esac
	for target in "$@"; do
		text "*#Hk7mP4#*"
		$search_command "$target" || {
			error "*#Jt6nR3#*\n"
			return 1
		}
		text "*#Rt9nK6#*\n"
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
	text "${font}${1}${CLR0}"
}
function FORMAT() {
	option="$1"
	value="$2"
	result=""
	[ -z "$value" ] && {
		error "*#Yt7nK4#*"
		return 2
	}
	[ -z "$option" ] && {
		error "*#Bk8mR5#*"
		return 2
	}
	case "$option" in
	-AA) result=$(text "$value" | tr '[:lower:]' '[:upper:]') ;;
	-aa) result=$(text "$value" | tr '[:upper:]' '[:lower:]') ;;
	-Aa) result=$(text "$value" | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/') ;;
	*) result="$value" ;;
	esac
	text "$result"
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
				error "*#Kp8nR4#*"
				return 2
			}
			rename_file="$2"
			shift 2
			;;
		-*) {
			error "*#Wx5mL9#*"
			return 2
		} ;;
		*)
			[ -z "$url" ] && url="$1" || target_dir="$1"
			shift
			;;
		esac
	done
	[ -z "$url" ] && {
		error "*#Yt6nR8#*"
		return 2
	}
	[[ "$url" =~ ^(http|https|ftp):// ]] || url="https://$url"
	output_file="${url##*/}"
	[ -z "$output_file" ] && output_file="index.html"
	[ "$target_dir" != "." ] && { mkdir -p "$target_dir" || {
		error "*#Hx7mK5#*"
		return 1
	}; }
	[ -n "$rename_file" ] && output_file="$rename_file"
	output_path="$target_dir/$output_file"
	url=$(text "$url" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	text "*#Bw4nP7#*"
	file_size=$(curl -sI "$url" | grep -i content-length | awk '{print $2}' | tr -d '\r')
	size_limit="26214400"
	if [ -n "$file_size" ] && [ "$file_size" -gt "$size_limit" ]; then
		wget --no-check-certificate --timeout=5 --tries=2 "$url" -O "$output_path" || {
			error "*#Vt5kR8#*"
			return 1
		}
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "$url" -o "$output_path" || {
			error "*#Mx6nL4#*"
			return 1
		}
	fi
	if [ -f "$output_path" ]; then
		text "*#Jt7mP5#*"
		if [ "$extract" = true ]; then
			case "$output_file" in
			*.tar.gz | *.tgz) tar -xzf "$output_path" -C "$target_dir" || {
				error "*#Nx5kR7#*"
				return 1
			} ;;
			*.tar) tar -xf "$output_path" -C "$target_dir" || {
				error "*#Qw6mL8#*"
				return 1
			} ;;
			*.tar.bz2 | *.tbz2) tar -xjf "$output_path" -C "$target_dir" || {
				error "*#Yx3nP6#*"
				return 1
			} ;;
			*.tar.xz | *.txz) tar -xJf "$output_path" -C "$target_dir" || {
				error "*#Zx8kM4#*"
				return 1
			} ;;
			*.zip) unzip "$output_path" -d "$target_dir" || {
				error "*#Lw5nR9#*"
				return 1
			} ;;
			*.7z) 7z x "$output_path" -o"$target_dir" || {
				error "*#Px7mK3#*"
				return 1
			} ;;
			*.rar) unrar x "$output_path" "$target_dir" || {
				error "*#Tx4nL6#*"
				return 1
			} ;;
			*.zst) zstd -d "$output_path" -o "$target_dir" || {
				error "*#Gx9kP5#*"
				return 1
			} ;;
			*) text "*#Wx6mR8#*" ;;
			esac
			[ $? -eq 0 ] && text "*#Cx5nL7#*"
		fi
		text "*#Rt9nK6#*\n"
	else
		{
			error "*#Bx7mP4#*"
			return 1
		}
	fi
}

function INPUT() {
	read -e -p "$1" "$2" || {
		error "*#Nt6mK8#*"
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
		error "*#Xt7nK5#*"
		return 1
	}
	i=1
	while read -r interface_item; do
		[ -n "$interface_item" ] && interfaces[$i]="$interface_item"
		((i++))
	done <<<"$all_interfaces"
	interfaces_num="${#interfaces[*]}"
	default4_route=$(ip -4 route show default 2>/dev/null | grep -A 3 "^default" || text "")
	default6_route=$(ip -6 route show default 2>/dev/null | grep -A 3 "^default" || text "")
	get_arr_item_idx() {
		item="$1"
		shift
		arr=("$@")
		for ((i = 1; i <= ${#arr[@]}; i++)); do
			if [ "$item" = "${arr[$i]}" ]; then
				text "$i"
				return 0
			fi
		done
		return 255
	}
	interface4=""
	interface6=""
	for ((i = 1; i <= ${#interfaces[@]}; i++)); do
		item="${interfaces[$i]}"
		[ -z "$item" ] && continue
		if [[ -n "$default4_route" && "$default4_route" == *"$item"* ]] && [ -z "$interface4" ]; then
			interface4="$item"
			interface4_device_order=$(get_arr_item_idx "$item" "${interfaces[@]}")
		fi
		if [[ -n "$default6_route" && "$default6_route" == *"$item"* ]] && [ -z "$interface6" ]; then
			interface6="$item"
			interface6_device_order=$(get_arr_item_idx "$item" "${interfaces[@]}")
		fi
		[ -n "$interface4" ] && [ -n "$interface6" ] && break
	done
	if [ -z "$interface4" ] && [ -z "$interface6" ]; then
		for ((i = 1; i <= ${#interfaces[@]}; i++)); do
			item="${interfaces[$i]}"
			if [[ "$item" =~ ^en ]]; then
				interface4="$item"
				interface6="$item"
				break
			fi
		done
		if [ -z "$interface4" ] && [ -z "$interface6" ] && [ "$interfaces_num" -gt 0 ]; then
			interface4="${interfaces[1]}"
			interface6="${interfaces[1]}"
		fi
	fi
	if [ -n "$interface4" ] || [ -n "$interface6" ]; then
		interface="$interface4 $interface6"
		[[ "$interface4" == "$interface6" ]] && interface="$interface4"
		interface=$(text "$interface" | tr -s ' ' | xargs)
	else
		physical_iface=$(ip -o link show | grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | grep 'state UP' | head -n 1 | awk -F': ' '{print $2}')
		if [ -n "$physical_iface" ]; then
			interface="$physical_iface"
		else
			interface=$(ip -o link show | grep -v 'lo:' | head -n 1 | awk -F': ' '{print $2}')
		fi
	fi
	case "$1" in
	RX_BYTES | RX_PACKETS | RX_DROP | TX_BYTES | TX_PACKETS | TX_DROP)
		for iface in $interface; do
			if stats=$(awk -v iface="$iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"$stats"
				case "$1" in
				RX_BYTES)
					text "$rx_bytes"
					break
					;;
				RX_PACKETS)
					text "$rx_packets"
					break
					;;
				RX_DROP)
					text "$rx_drop"
					break
					;;
				TX_BYTES)
					text "$tx_bytes"
					break
					;;
				TX_PACKETS)
					text "$tx_packets"
					break
					;;
				TX_DROP)
					text "$tx_drop"
					break
					;;
				esac
			fi
		done
		;;
	-i)
		for iface in $interface; do
			if stats=$(awk -v iface="$iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null); then
				read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"$stats"
				text "$iface: RX: $(CONVERT_SIZE $rx_bytes), TX: $(CONVERT_SIZE $tx_bytes)"
			fi
		done
		;;
	"") text "$interface" ;;
	*)
		error "*#Wx7mP5#*"
		return 2
		;;
	esac
}
function IP_ADDR() {
	version="$1"
	case "$version" in
	-4)
		ipv4_addr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null) ||
			ipv4_addr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null) ||
			ipv4_addr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null) ||
			[ -n "$ipv4_addr" ] && text "$ipv4_addr" || {
			error "*#Kt6nR9#*"
			return 1
		}
		;;
	-6)
		ipv6_addr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null) ||
			ipv6_addr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null) ||
			[ -n "$ipv6_addr" ] && text "$ipv6_addr" || {
			error "*#Mx5nK7#*"
			return 1
		}
		;;
	*)
		ipv4_addr=$(IP_ADDR -4)
		ipv6_addr=$(IP_ADDR -6)
		[ -z "$ipv4_addr$ipv6_addr" ] && {
			error "*#Px7mR4#*"
			return 1
		}
		[ -n "$ipv4_addr" ] && text "IPv4: $ipv4_addr"
		[ -n "$ipv6_addr" ] && text "IPv6: $ipv6_addr"
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
	[ -z "$last_update" ] && {
		error "*#Ht7nR5#*"
		return 1
	} || text "$last_update"
}
function LINE() {
	char="${1:--}"
	length="${2:-80}"
	printf '%*s\n' "$length" | tr ' ' "$char" || {
		error "*#Lt8nK6#*"
		return 1
	}
}
function LOAD_AVERAGE() {
	if [ ! -f /proc/loadavg ]; then
		load_data=$(uptime | sed 's/.*load average: //' | sed 's/,//g') || {
			error "*#Nt5kR8#*"
			return 1
		}
	else
		read -r one_min five_min fifteen_min _ _ </proc/loadavg || {
			error "*#Ht6mL9#*"
			return 1
		}
	fi
	[[ $one_min =~ ^[0-9.]+$ ]] || one_min=0
	[[ $five_min =~ ^[0-9.]+$ ]] || five_min=0
	[[ $fifteen_min =~ ^[0-9.]+$ ]] || fifteen_min=0
	LC_ALL=C printf "%.2f, %.2f, %.2f (%d cores)" "$one_min" "$five_min" "$fifteen_min" "$(nproc)"
}
function LOCATION() {
	loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^loc=" | cut -d= -f2)
	[ -n "$loc" ] && text "$loc" || {
		error "*#Jt9nR7#*"
		return 1
	}
}

function MAC_ADDR() {
	mac_address=$(ip link show | awk '/ether/ {print $2; exit}')
	[[ -n "$mac_address" ]] && text "$mac_address" || {
		error "*#Wt7nK4#*"
		return 1
	}
}
function MEM_USAGE() {
	used=$(free -b | awk '/^Mem:/ {print $3}') || used=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || {
		error "*#Zt6nR4#*"
		return 1
	}
	total=$(free -b | awk '/^Mem:/ {print $2}') || total=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	percentage=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || percentage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "$1" in
	-u) text "$used" ;;
	-t) text "$total" ;;
	-p) text "$percentage" ;;
	*) text "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)" ;;
	esac
}

function NET_PROVIDER() {
	result=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		result=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		result=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		[ -n "$result" ] && text "$result" || {
		error "*#Nt7mK5#*"
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
		error "*#Nt8mK5#*"
		return 1
	} ;;
	esac
	if ! pkg_count=$($count_cmd 2>/dev/null | wc -l) || [[ -z "$pkg_count" || "$pkg_count" -eq 0 ]]; then
		{
			error "*#Ht7nR6#*"
			return 1
		}
	fi
	text "$pkg_count"
}
function PROGRESS() {
	num_cmds=${#cmds[@]}
	term_width=$(tput cols) || {
		error "*#Nt6mR8#*"
		return 1
	}
	bar_width=$((term_width - 23))
	stty -echo
	trap '' SIGINT SIGQUIT SIGTSTP
	for ((i = 0; i < num_cmds; i++)); do
		progress=$((i * 100 / num_cmds))
		filled_width=$((progress * bar_width / 100))
		printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "$progress" "$(printf "%${filled_width}s" | tr ' ' '#')" "$(printf "%$((bar_width - filled_width))s" | tr ' ' '.')"
		if ! output=$(eval "${cmds[$i]}" 2>&1); then
			text "\n$output"
			stty echo
			trap - SIGINT SIGQUIT SIGTSTP
			{
				error "*#Ht8mK4#*"
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
	[ -n "$ip" ] && text "$ip" || {
		error "*#Xt7nK6#*"
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
		COMPREPLY=($(compgen -W "$opts" -- "$cur"))
		[[ ${#COMPREPLY[@]} -eq 0 ]] && COMPREPLY=($(compgen -c -- "$cur"))
	}
	complete -F _run_completions RUN
	[ $# -eq 0 ] && {
		error "*#Nt6mK9#*"
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
			text "*#Xt9nK5#*"
			TASK "*#Ht9mL5#*" "
				curl -sSLf "$url" -o "$script_name" || { error "*#Ht7mK5#*"; return 1; }
				chmod +x "$script_name" || { error "*#Kt8nR4#*"; return 1; }
			"
			text "${CLR8}$(LINE = "24")${CLR0}"
			if [[ "$1" == "--" ]]; then
				shift
				./"$script_name" "$@" || {
					error "*#Mt9nL5#*"
					return 1
				}
			else
				./"$script_name" || {
					error "*#Mt9nL5#*"
					return 1
				}
			fi
			text "${CLR8}$(LINE = "24")${CLR0}"
			text "*#Rt9nK6#*\n"
			[[ "$delete_after" == true ]] && rm -rf "$script_name"
		elif [[ "$1" =~ ^[^/]+/[^/]+/.+ ]]; then
			repo_owner=$(text "$1" | cut -d'/' -f1)
			repo_name=$(text "$1" | cut -d'/' -f2)
			script_path=$(text "$1" | cut -d'/' -f3-)
			script_name=$(basename "$script_path")
			branch="main"
			download_repo=false
			delete_after=false
			shift
			while [[ $# -gt 0 && "$1" == -* ]]; do
				case "$1" in
				-b)
					[[ -z "$2" || "$2" == -* ]] && {
						error "*#Pt5mK8#*"
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
				text "*#Vt9nK4#*"
				[[ -d "$repo_name" ]] && {
					error "*#Qt7nR6#*"
					return 1
				}
				temp_dir=$(mktemp -d)
				if [[ "$branch" != "main" ]]; then
					TASK "*#At9kM8#*" "git clone --branch $branch https://github.com/${repo_owner}/${repo_name}.git "$temp_dir""
					if [ $? -ne 0 ]; then
						rm -rf "$temp_dir"
						{
							error "*#Rt8mK7#*"
							return 1
						}
					fi
				else
					TASK "*#Wt8mR5#*" "git clone --branch main https://github.com/${repo_owner}/${repo_name}.git "$temp_dir"" true
					if [ $? -ne 0 ]; then
						TASK "*#Bt9nP9#*" "git clone --branch master https://github.com/${repo_owner}/${repo_name}.git "$temp_dir""
						if [ $? -ne 0 ]; then
							rm -rf "$temp_dir"
							{
								error "*#St9nL4#*"
								return 1
							}
						fi
					fi
				fi
				TASK "*#Ct9mK0#*" "ADD -d "$repo_name" && cp -r "$temp_dir"/* "$repo_name"/"
				TASK "*#Dt9pL1#*" "rm -rf "$temp_dir""
				text "*#Yt9mR6#*"
				if [[ -f "$repo_name/$script_path" ]]; then
					TASK "*#Et9nR2#*" "chmod +x "$repo_name/$script_path""
					text "${CLR8}$(LINE = "24")${CLR0}"
					if [[ "$1" == "--" ]]; then
						shift
						./"$repo_name/$script_path" "$@" || {
							error "*#Mt9nL5#*"
							return 1
						}
					else
						./"$repo_name/$script_path" || {
							error "*#Mt9nL5#*"
							return 1
						}
					fi
					text "${CLR8}$(LINE = "24")${CLR0}"
					text "*#Rt9nK6#*\n"
					[[ "$delete_after" == true ]] && rm -rf "$repo_name"
				fi
			else
				text "*#Zt9pL7#*"
				github_url="https://raw.githubusercontent.com/${repo_owner}/${repo_name}/refs/heads/${branch}/${script_path}"
				if [[ "$branch" != "main" ]]; then
					TASK "*#Ft9kM3#*" "curl -sLf "$github_url" >/dev/null"
					[ $? -ne 0 ] && {
						error "*#Tt6nK5#*"
						return 1
					}
				else
					TASK "*#Wt8mR5#*" "curl -sLf "$github_url" >/dev/null" true
					if [ $? -ne 0 ]; then
						TASK "*#Gt9pN4#*" "
							branch="master"
							github_url="https://raw.githubusercontent.com/${repo_owner}/${repo_name}/refs/heads/master/${script_path}"
							curl -sLf "$github_url" >/dev/null
						"
						[ $? -ne 0 ] && {
							error "*#Ut7mR8#*"
							return 1
						}
					fi
				fi
				TASK "*#Ht9mL5#*" "
					curl -sSLf \"$github_url\" -o \"$script_name\" || { 
						error \"*#Ht7mK5#*\"
						error \"*#Jt9pL6#*\"
						return 1
					}

					if [[ ! -f \"$script_name\" ]]; then
						error \"*#Kt9mR7#*\"
						return 1
					fi

					if [[ ! -s \"$script_name\" ]]; then
						error \"*#Lt9nS8#*\"
						cat \"$script_name\" 2>/dev/null || echo \"*#Mt9pT9#*\"
						return 1
					fi

					if ! grep -q '[^[:space:]]' \"$script_name\"; then
						error \"*#Nt9qU1#*\"
						return 1
					fi

					chmod +x \"$script_name\" || { 
						error \"*#Kt8nR4#*\"
						error \"*#Ot9rV2#*\"
						ls -la \"$script_name\"
						return 1
					}
				"

				text "${CLR8}$(LINE = "24")${CLR0}"
				if [[ -f "$script_name" ]]; then
					if [[ "$1" == "--" ]]; then
						shift
						./"$script_name" "$@" || {
							error "*#Mt9nL5#*"
							return 1
						}
					else
						./"$script_name" || {
							error "*#Mt9nL5#*"
							return 1
						}
					fi
				else
					error "*#Pt9sW3#*"
					return 1
				fi
				text "${CLR8}$(LINE = "24")${CLR0}"
				text "*#Rt9nK6#*\n"
				[[ "$delete_after" == true ]] && rm -rf "$script_name"
			fi
		else
			[ -x "$1" ] || chmod +x "$1"
			script_path="$1"
			if [[ "$2" == "--" ]]; then
				shift 2
				"$script_path" "$@" || {
					error "*#Mt9nL5#*"
					return 1
				}
			else
				shift
				"$script_path" "$@" || {
					error "*#Mt9nL5#*"
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
		text "Bash ${BASH_VERSION}"
	elif [ -n "${ZSH_VERSION-}" ]; then
		text "Zsh ${ZSH_VERSION}"
	else
		{
			error "*#Zt8nK5#*"
			return 1
		}
	fi
}
function SWAP_USAGE() {
	used=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	total=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	percentage=$(free | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	case "$1" in
	-u) text "$used" ;;
	-t) text "$total" ;;
	-p) text "$percentage" ;;
	*) text "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)" ;;
	esac
}
function SYS_CLEAN() {
	CHECK_ROOT
	text "*#Xt8nK5#*"
	text "${CLR8}$(LINE = "24")${CLR0}"
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk)
		text "*#Nt9mK4#*"
		apk cache clean || {
			error "*#Wt5nR7#*"
			return 1
		}
		text "*#Mt8pL5#*"
		rm -rf /tmp/* /var/cache/apk/* || {
			error "*#Ht6mK8#*"
			return 1
		}
		text "*#Kt7nR8#*"
		apk fix || {
			error "*#Nt7pL4#*"
			return 1
		}
		;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			text "*#Jt6mK9#*"
			sleep 1 || return 1
			((wait_time++))
			[ "$wait_time" -gt 300 ] && {
				error "*#Bx8vP5#*"
				return 1
			}
		done
		text "*#Ht5nL7#*"
		DEBIAN_FRONTEND=noninteractive dpkg --configure -a || {
			error "*#Kt7mR5#*"
			return 1
		}
		text "*#Gt4mK8#*"
		apt autoremove --purge -y || {
			error "*#Mt6nK8#*"
			return 1
		}
		text "*#Ft3nL9#*"
		apt clean -y || {
			error "*#Pt7nR4#*"
			return 1
		}
		text "*#Et2mK7#*"
		apt autoclean -y || {
			error "*#Qt8mK5#*"
			return 1
		}
		;;
	*opkg)
		text "*#Mt8pL5#*"
		rm -rf /tmp/* || {
			error "*#Ht6mK8#*"
			return 1
		}
		text "*#Dt1nL8#*"
		opkg update || {
			error "*#Rt7nK4#*"
			return 1
		}
		text "*#Ct0mK6#*"
		opkg clean || {
			error "*#St6mL5#*"
			return 1
		}
		;;
	*pacman)
		text "*#Bt9nL5#*"
		pacman -Syu --noconfirm || {
			error "*#Tt7nR6#*"
			return 1
		}
		text "*#At8mK4#*"
		pacman -Sc --noconfirm || {
			error "*#Ut8mK4#*"
			return 1
		}
		text "*#Zt7nL3#*"
		pacman -Scc --noconfirm || {
			error "*#Vt7nL5#*"
			return 1
		}
		;;
	*yum)
		text "*#Gt4mK8#*"
		yum autoremove -y || {
			error "*#Mt6nK8#*"
			return 1
		}
		text "*#Yt8aK2#*"
		yum clean all || {
			error "*#Wt8nR4#*"
			return 1
		}
		text "*#Xt5nL1#*"
		yum makecache || {
			error "*#Xt7mK5#*"
			return 1
		}
		;;
	*zypper)
		text "*#Wt4mK0#*"
		zypper clean --all || {
			error "*#Yt6nR7#*"
			return 1
		}
		text "*#Vt3nL9#*"
		zypper refresh || {
			error "*#Zt8mK4#*"
			return 1
		}
		;;
	*dnf)
		text "*#Gt4mK8#*"
		dnf autoremove -y || {
			error "*#Mt6nK8#*"
			return 1
		}
		text "*#Ut2mK8#*"
		dnf clean all || {
			error "*#At7nR5#*"
			return 1
		}
		text "*#Tt1nL7#*"
		dnf makecache || {
			error "*#Bt8mK4#*"
			return 1
		}
		;;
	*) {
		error "*#Ct7nR5#*"
		return 1
	} ;;
	esac
	if command -v journalctl &>/dev/null; then
		TASK "*#St0mK6#*" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || {
			error "*#Dt6nK7#*"
			return 1
		}
	fi
	TASK "*#Mt8pL5#*" "rm -rf /tmp/*" || {
		error "*#Ht6mK8#*"
		return 1
	}
	for cmd in docker npm pip; do
		if command -v "$cmd" &>/dev/null; then
			case "$cmd" in
			docker) TASK "*#Rt9nL5#*" "docker system prune -af" || {
				error "*#Et7nR4#*"
				return 1
			} ;;
			npm) TASK "*#Qt8mK4#*" "npm cache clean --force" || {
				error "*#Ft8mK5#*"
				return 1
			} ;;
			pip) TASK "*#Pt7nL3#*" "pip cache purge" || {
				error "*#Gt7nL6#*"
				return 1
			} ;;
			esac
		fi
	done
	TASK "*#Ot6mK2#*" "rm -rf ~/.cache/*" || {
		error "*#Ht8nR4#*"
		return 1
	}
	TASK "*#Nt5nL1#*" "rm -rf ~/.thumbnails/*" || {
		error "*#It7mK5#*"
		return 1
	}
	text "${CLR8}$(LINE = "24")${CLR0}"
	text "*#Rt9nK6#*\n"
}
function SYS_INFO() {
	text "*#Vx8nK4#*"
	text "${CLR8}$(LINE = "24")${CLR0}"

	text "*#Rx7tP5#*${CLR2}$(uname -n || {
		error "*#Bx6mL9#*"
		return 1
	})${CLR0}"
	text "*#Mx5nR8#*${CLR2}$(CHECK_OS)${CLR0}"
	text "*#Qw4tK9#*${CLR2}$(uname -r)${CLR0}"
	text "*#Lx3nP6#*${CLR2}$LANG${CLR0}"
	text "*#Yx5mK7#*${CLR2}$(SHELL_VER)${CLR0}"
	text "*#Wx9tR4#*${CLR2}$(LAST_UPDATE)${CLR0}"
	text "${CLR8}$(LINE - "32")${CLR0}"

	text "*#Hx7nP5#*${CLR2}$(uname -m)${CLR0}"
	text "*#Fx4tK8#*${CLR2}$(CPU_MODEL)${CLR0}"
	text "*#Jx6mL3#*${CLR2}$(nproc)${CLR0}"
	text "*#Bw2mK8#*${CLR2}$(CPU_FREQ)${CLR0}"
	text "*#Tx8nR2#*${CLR2}$(CPU_USAGE)%${CLR0}"
	text "*#Gx3mK6#*${CLR2}$(CPU_CACHE)${CLR0}"
	text "${CLR8}$(LINE - "32")${CLR0}"

	text "*#Px9tR5#*${CLR2}$(MEM_USAGE)${CLR0}"
	text "*#Sx4nK7#*${CLR2}$(SWAP_USAGE)${CLR0}"
	text "*#Cx7mP2#*${CLR2}$(DISK_USAGE)${CLR0}"
	text "*#Dx8tL4#*${CLR2}$(df -T / | awk 'NR==2 {print $2}')${CLR0}"
	text "${CLR8}$(LINE - "32")${CLR0}"

	text "*#Ax6nK9#*${CLR2}$(IP_ADDR -4)${CLR0}"
	text "*#Ux3tP5#*${CLR2}$(IP_ADDR -6)${CLR0}"
	text "*#Zx7mL4#*${CLR2}$(MAC_ADDR)${CLR0}"
	text "*#Kx9nP6#*${CLR2}$(NET_PROVIDER)${CLR0}"
	text "*#Ox4mK8#*${CLR2}$(DNS_ADDR)${CLR0}"
	text "*#Ex5tL7#*${CLR2}$(PUBLIC_IP)${CLR0}"
	text "*#Ix8nR4#*${CLR2}$(INTERFACE -i)${CLR0}"
	text "*#Mx7pK3#*${CLR2}$(TIMEZONE -i)${CLR0}"
	text "*#Qx2tP9#*${CLR2}$(TIMEZONE -e)${CLR0}"
	text "${CLR8}$(LINE - "32")${CLR0}"

	text "*#Wx6nL5#*${CLR2}$(LOAD_AVERAGE)${CLR0}"
	text "*#Yx3tK7#*${CLR2}$(ps aux | wc -l)${CLR0}"
	text "*#Bx8mP4#*${CLR2}$(PKG_COUNT)${CLR0}"
	text "${CLR8}$(LINE - "32")${CLR0}"

	text "*#Nx7tL3#*${CLR2}$(uptime -p | sed 's/up //')${CLR0}"
	text "*#Fx5nR9#*${CLR2}$(who -b | awk '{print $3, $4}')${CLR0}"
	text "${CLR8}$(LINE - "32")${CLR0}"

	text "*#Jx4mK7#*${CLR2}$(CHECK_VIRT)${CLR0}"
	text "${CLR8}$(LINE = "24")${CLR0}"
}
function SYS_OPTIMIZE() {
	CHECK_ROOT
	text "*#Vx7nK4#*"
	text "${CLR8}$(LINE = "24")${CLR0}"
	SYSCTL_CONF="/etc/sysctl.d/99-server-optimizations.conf"
	text "*#Bx3tR8#*" >"$SYSCTL_CONF"

	TASK "*#Ym4kL7#*" "
		text 'vm.swappiness = 1' >> $SYSCTL_CONF
		text 'vm.vfs_cache_pressure = 50' >> $SYSCTL_CONF
		text 'vm.dirty_ratio = 15' >> $SYSCTL_CONF
		text 'vm.dirty_background_ratio = 5' >> $SYSCTL_CONF
		text 'vm.min_free_kbytes = 65536' >> $SYSCTL_CONF
	" || {
		error "*#Kx8mP5#*"
		return 1
	}

	TASK "*#Rx6tK9#*" "
		text 'net.core.somaxconn = 65535' >> $SYSCTL_CONF
		text 'net.core.netdev_max_backlog = 65535' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_max_syn_backlog = 65535' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_fin_timeout = 15' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_keepalive_time = 300' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_keepalive_probes = 5' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_keepalive_intvl = 15' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_tw_reuse = 1' >> $SYSCTL_CONF
		text 'net.ipv4.ip_local_port_range = 1024 65535' >> $SYSCTL_CONF
	" || {
		error "*#Nx5vR7#*"
		return 1
	}

	TASK "*#Yt6nK2#*" "
		text 'net.core.rmem_max = 16777216' >> $SYSCTL_CONF
		text 'net.core.wmem_max = 16777216' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> $SYSCTL_CONF
		text 'net.ipv4.tcp_mtu_probing = 1' >> $SYSCTL_CONF
	" || {
		error "*#Wx9nL5#*"
		return 1
	}

	TASK "*#Ht8kP3#*" "
		text 'fs.file-max = 2097152' >> $SYSCTL_CONF
		text 'fs.nr_open = 2097152' >> $SYSCTL_CONF
		text 'fs.inotify.max_user_watches = 524288' >> $SYSCTL_CONF
	" || {
		error "*#Jx7tR4#*"
		return 1
	}

	TASK "*#Mx6nP8#*" "
		text '* soft nofile 1048576' >> /etc/security/limits.conf
		text '* hard nofile 1048576' >> /etc/security/limits.conf
		text '* soft nproc 65535' >> /etc/security/limits.conf
		text '* hard nproc 65535' >> /etc/security/limits.conf
	" || {
		error "*#Tx5mK9#*"
		return 1
	}

	TASK "*#Gx4tP7#*" "
		for disk in /sys/block/[sv]d*; do
			text 'none' > \$disk/queue/scheduler 2>/dev/null || true
			text '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	" || {
		error "*#Zx6nL8#*"
		return 1
	}

	TASK "*#Qx7tK5#*" "
		for service in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now \$service 2>/dev/null || true
		done
	" || {
		error "*#Fx3mP6#*"
		return 1
	}

	TASK "*#Dx5nR7#*" "sysctl -p $SYSCTL_CONF" || {
		error "*#Bx4tL8#*"
		return 1
	}

	TASK "*#Cx6kP9#*" "
		sync
		text 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	" || {
		error "*#Wx8mK4#*"
		return 1
	}

	text "${CLR8}$(LINE = "24")${CLR0}"
	text "*#Rt9nK6#*\n"
}
function SYS_REBOOT() {
	CHECK_ROOT
	text "*#Ht7nK4#*"
	text "${CLR8}$(LINE = "24")${CLR0}"
	active_users=$(who | wc -l) || {
		error "*#Bx6tR8#*"
		return 1
	}
	if [ "$active_users" -gt 1 ]; then
		text "*#Vx9mK5#*\n"
		text "*#Rx5nK9#*"
		who | awk '{print $1 " since " $3 " " $4}'
		text
	fi
	important_processes=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || {
		error "*#Yx6mP7#*"
		return 1
	}
	if [ "$important_processes" -gt 0 ]; then
		text "*#Zx8tK3#*\n"
		text "*#Mx3nP6#*"
		ps aux --sort=-%cpu | head -n 6
		text
	fi
	read -p "*#Dn4kR7#*" -n 1 -r
	text
	[[ ! $REPLY =~ ^[Yy]$ ]] && {
		text "*#Jx5tP8#*\n"
		return 0
	}
	TASK "*#Wx2mK9#*" "sync" || {
		error "*#Nx8vR3#*"
		return 1
	}
	TASK "*#Bx7tL5#*" "reboot || sudo reboot" || {
		error "*#Tx5mP4#*"
		return 1
	}
	text "*#Gx6nK8#*"
}
function SYS_UPDATE() {
	CHECK_ROOT
	text "*#Wx7nP5#*"
	text "${CLR8}$(LINE = "24")${CLR0}"
	update_pkgs() {
		cmd="$1"
		update_cmd="$2"
		upgrade_cmd="$3"
		text "*#Ym6tK9#*"
		$update_cmd || {
			error "*#Qn5wL7#*"
			return 1
		}
		text "*#Vx3nR8#*"
		$upgrade_cmd || {
			error "*#Ht9pL4#*"
			return 1
		}
	}
	case $(command -v apk apt opkg pacman yum zypper dnf | head -n1) in
	*apk) update_pkgs "apk" "apk update" "apk upgrade" ;;
	*apt)
		while fuser /var/lib/dpkg/lock-frontend &>/dev/null; do
			TASK "*#Rw4mK7#*" "sleep 1" || return 1
			((wait_time++))
			[ "$wait_time" -gt 10 ] && {
				error "*#Bx8vP5#*"
				return 1
			}
		done
		TASK "*#Dn3tL6#*" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || {
			error "*#Kx7mP2#*"
			return 1
		}
		update_pkgs "apt" "apt update -y" "apt full-upgrade -y"
		;;
	*opkg) update_pkgs "opkg" "opkg update" "opkg upgrade" ;;
	*pacman) TASK "*#Lw6nR9#*" "pacman -Syu --noconfirm" || {
		error "*#Yx5vP8#*"
		return 1
	} ;;
	*yum) update_pkgs "yum" "yum check-update" "yum -y update" ;;
	*zypper) update_pkgs "zypper" "zypper refresh" "zypper update -y" ;;
	*dnf) update_pkgs "dnf" "dnf check-update" "dnf -y update" ;;
	*) {
		error "*#Zx7mP4#*"
		return 1
	} ;;
	esac
	text "*#Jn5tR8#*"
	bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/utilkit.sh/refs/heads/main/get_utilkit.sh) || {
		error "*#Wx4nP9#*"
		return 1
	}
	text "${CLR8}$(LINE = "24")${CLR0}"
	text "*#Rt9nK6#*\n"
}
function SYS_UPGRADE() {
	CHECK_ROOT
	text "*#Ht6nR9#*"
	text "${CLR8}$(LINE = "24")${CLR0}"
	os_name=$(CHECK_OS -n)
	case "$os_name" in
	Debian)
		text "*#Vx8tK5#*"
		text "*#Ym6tK9#*"
		apt update -y || {
			error "*#An8zR7#*"
			return 1
		}
		text "*#Lw7mP4#*"
		apt full-upgrade -y || {
			error "*#Bx3vR6#*"
			return 1
		}
		text "*#Kx4nP7#*"
		current_codename=$(lsb_release -cs)
		target_codename=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep "^Codename:" | awk '{print $2}')
		[ "$current_codename" = "$target_codename" ] && {
			error "*#Rw5mK9#* (${target_codename})"
			return 1
		}
		text "*#Jx5mP8#*"
		TASK "*#Yx3vL7#*" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || {
			error "*#Ht6nP9#*"
			return 1
		}
		TASK "*#Wx5tR8#*" "sed -i 's/${current_codename}/${target_codename}/g' /etc/apt/sources.list" || {
			error "*#Zm7nL4#*"
			return 1
		}
		TASK "*#Kx9mP5#*" "apt update -y" || {
			error "*#Bx6tK8#*"
			return 1
		}
		TASK "*#Yw7nL5#*" "apt full-upgrade -y" || {
			error "*#Dx4kR9#*"
			return 1
		}
		;;
	Ubuntu)
		text "*#Nx5tP7#*"
		TASK "*#Ym6tK9#*" "apt update -y" || {
			error "*#An8zR7#*"
			return 1
		}
		TASK "*#Lw7mP4#*" "apt full-upgrade -y" || {
			error "*#Bx3vR6#*"
			return 1
		}
		TASK "*#Rx8nK4#*" "apt install -y update-manager-core" || {
			error "*#Jx2vL7#*"
			return 1
		}
		TASK "*#Vx7tP5#*" "do-release-upgrade -f DistUpgradeViewNonInteractive" || {
			error "*#Lw4mR8#*"
			return 1
		}
		SYS_REBOOT
		;;
	*) {
		error "*#Yx9nK6#*"
		return 1
	} ;;
	esac
	text "${CLR8}$(LINE = "24")${CLR0}"
	text "*#Mx5tR7#*\n"
}

function TASK() {
	message="$1"
	command="$2"
	ignore_error=${3:-false}
	temp_file=$(mktemp)
	echo -ne "${message}... "
	if eval "$command" >"$temp_file" 2>&1; then
		text "*#Kw5nP9#*"
		ret=0
	else
		ret=$?
		text "*#Vx8tR4#* (${ret})"
		[[ -s "$temp_file" ]] && text "${CLR1}$(cat "$temp_file")${CLR0}"
		[[ "$ignore_error" != "true" ]] && return $ret
	fi
	rm -f "$temp_file"
	return $ret
}
function TIMEZONE() {
	case "$1" in
	-e)
		result=$(timeout 1s curl -sL ipapi.co/timezone) ||
			result=$(timeout 1s curl -sL worldtimeapi.org/api/ip | grep -oP '"timezone":"\K[^"]+') ||
			result=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"timezone":"\K[^"]+') ||
			[ -n "$result" ] && text "$result" || {
			error "*#Ym7tK4#*"
			return 1
		}
		;;
	-i | *)
		result=$(readlink /etc/localtime | sed 's|^.*/zoneinfo/||') 2>/dev/null ||
			result=$(command -v timedatectl &>/dev/null && timedatectl status | awk '/Time zone:/ {print $3}') ||
			result=$(cat /etc/timezone 2>/dev/null | uniq) ||
			[ -n "$result" ] && text "$result" || {
			error "*#Bx5vR8#*"
			return 1
		}
		;;
	esac
}
