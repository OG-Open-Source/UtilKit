#!/usr/bin/env bash
# VERSION="8.0.0a2"

set +u
shopt -s expand_aliases

declare _ PKG_MGR="" LANG="en" UNIT_PREF="IB"

declare CLR=(
	"\033[0m"    # [0] 重置
	"\033[0;31m" # [1] 紅
	"\033[0;32m" # [2] 綠
	"\033[0;33m" # [3] 黃
	"\033[0;34m" # [4] 藍
	"\033[0;35m" # [5] 紫
	"\033[0;36m" # [6] 青
	"\033[0;37m" # [7] 白
	"\033[0;96m" # [8] 高亮青
	"\033[0;97m" # [9] 高亮白
)

alias .Flag='(($# == 0)) && return 1'
alias .Root='((EUID != 0 || $(id -u) != 0)) && return 1'
alias .Root.Flag='.Root; .Flag'

function DLine() { printf "%b\n" "${1:-${CLR[8]}}========================${CLR[0]}"; }
function SLine() { printf "%b\n" "${1:-${CLR[8]}}--------------------------------${CLR[0]}"; }
function Finish() { printf "%b\n" "${CLR[2]}完成${CLR[0]}"; }
function Err() { if [[ -n "$*" ]]; then printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2 && return 1; fi; }
function Raw() { if [[ -n "$*" ]]; then printf "%b" "$*" || return 1; fi; }
function Txt() { if [[ -n "$*" ]]; then printf "%b\n" "$*" || return 1; fi; }
function Cmdd() {
	.Flag
	command -v "$1" &>/dev/null || return 127
}
function Trim() {
	.Flag
	local stdin_buffer
	stdin_buffer=$(cat)

	[[ -n "${1:-}" ]] && stdin_buffer="${stdin_buffer#*"$1"}"
	[[ -n "${2:-}" ]] && stdin_buffer="${stdin_buffer%%"$2"*}"

	Txt "${stdin_buffer}"
}
function Extract() {
	# 可變整數宣告 (-i 優先)
	local -i i
	i=0
	# 可變字串宣告 (僅鍵名宣告，後賦值)
	local dir_v dir_h
	dir_v="tb"
	dir_h="lr"

	# 解析 OPTIONS (數值比較使用 (( ... )) 與 > 運算子)
	while (($# > 0)); do
		# 遵循規範：非整數輸入以 "" 包裹，但 case 選項因支援正則故「不包裹」
		case "$1" in
			--bt)
				dir_v="bt"
				shift
				;;
			--tb)
				dir_v="tb"
				shift
				;;
			--rl)
				dir_h="rl"
				shift
				;;
			--lr)
				dir_h="lr"
				shift
				;;
			*) break ;;
		esac
	done

	# 讀取位置參數 (宣告即賦值視為不可變，遵循 -i > -r 順序)
	local -ir target_row="${1:-1}" target_col="${2:-1}"
	local -r delimiter="${3:-}"

	# 1. 讀取標準輸入並切分成「行」陣列 (可變陣列規範：先鍵名，後用=()初始化)
	local mapfile_lines
	mapfile_lines=()
	mapfile -t mapfile_lines

	# 2. 處理垂直方向
	local lines
	lines=()
	if [[ "${dir_v}" == "bt" ]]; then
		# 數值運算子內部直接使用裸變數名稱 i
		for ((i = ${#mapfile_lines[@]} - 1; i >= 0; i--)); do
			lines+=("${mapfile_lines[i]}")
		done
	else
		lines=("${mapfile_lines[@]}")
	fi

	# 檢查行數是否超出範圍 (純數值判斷改用 (( ))，並以簡潔控制子取代 if)
	((target_row > ${#lines[@]} || target_row < 1)) && return 1

	# 取得目標行的文本 (不可變字串，使用 C 風格 $(( )) 運算子)
	local -r raw_line="${lines[$((target_row - 1))]}"

	# 3. 使用 IFS 精確解析該行的欄位
	local mapfile_cols
	mapfile_cols=()

	if [[ -z "${delimiter}" ]]; then
		read -r -a mapfile_cols <<<"${raw_line}"
	else
		local -r old_ifs="${IFS}"
		IFS="${delimiter}"
		read -r -a mapfile_cols <<<"${raw_line}"
		IFS="${old_ifs}"

		# temp_cols 宣告後不再變更，為不可變陣列
		local -r temp_cols=("${mapfile_cols[@]}")
		mapfile_cols=()

		local item
		item=""
		for item in "${temp_cols[@]}"; do
			# 字串賦值必須以 "" 包裹
			item="$(echo "${item}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
			[[ -n "${item}" ]] && mapfile_cols+=("${item}")
		done
	fi

	# 4. 處理水平方向
	local cols
	cols=()
	if [[ "${dir_h}" == "rl" ]]; then
		for ((i = ${#mapfile_cols[@]} - 1; i >= 0; i--)); do
			cols+=("${mapfile_cols[i]}")
		done
	else
		cols=("${mapfile_cols[@]}")
	fi

	# 檢查欄位數是否超出範圍
	((target_col > ${#cols[@]} || target_col < 1)) && return 1

	# 5. 輸出最終結果
	Txt "${cols[$((target_col - 1))]}"
}
function GetValue() {
	local -r key="$1" data_source="${2:-}"
	local pattern
	pattern="(^|[[:space:],'{ \"])(\"${key}\"|'${key}'|\<${key}\>)[[:space:]]*[:=][[:space:]]*(\"([^\"]*)\"|'([^']*)'|([^,[:space:]#]+))"

	_Parse() {
		local line
		pattern="$1"

		while read -r line; do
			if [[ "${line}" =~ ${pattern} ]]; then
				if [[ -n "${BASH_REMATCH[4]}" ]]; then
					printf "%s\n" "${BASH_REMATCH[4]}"
				elif [[ -n "${BASH_REMATCH[5]}" ]]; then
					printf "%s\n" "${BASH_REMATCH[5]}"
				else
					printf "%s\n" "${BASH_REMATCH[6]}"
				fi
				return 0
			fi
		done
		return 1
	}

	if [[ -z "${data_source}" ]]; then
		_Parse "${pattern}"
	elif [[ -f "${data_source}" ]]; then
		_Parse "${pattern}" <"${data_source}"
	else
		_Parse "${pattern}" <<<"${data_source}"
	fi
}
function ChkApt() {
	local -ir wait_time=0 max_timeout=180

	Cmdd "fuser" || return 1
	while fuser "/var/lib/dpkg/lock-frontend" "/var/lib/dpkg/lock" &>/dev/null; do
		Task "- 等待 DPKG 鎖定釋放 (${wait_time}s)" "sleep 1" || return 1
		((wait_time++))
		if ((wait_time > max_timeout)); then
			Err "等待 DPKG 鎖定釋放超時" || return 1
		fi
	done
}

function pkg::count() {
	case "${PKG_MGR^^}" in
		APK) data=$(apk info | wc -l) ;;
		APT) data=$(dpkg --get-selections | wc -l) ;;
		DNF) data=$(rpm -qa | wc -l) ;;
		OPKG) data=$(opkg list-installed | wc -l) ;;
		PACMAN) data=$(pacman -Q | wc -l) ;;
		YUM) data=$(rpm -qa | wc -l) ;;
		ZYPPER) data=$(rpm -qa | wc -l) ;;
		*) return 127 ;;
	esac

	if ! Txt "${data}"; then
		Err "計算 ${PKG_MGR} 的套件數量失敗" || return 1
	fi
}
function pkg::is_installed() {
	.Flag

	case "${PKG_MGR^^}" in
		APK) apk info -e "${1,,}" &>/dev/null ;;
		APT) dpkg -s "${1,,}" &>/dev/null ;;
		DNF) rpm -q "${1,,}" &>/dev/null ;;
		OPKG) opkg status "${1,,}" 2>/dev/null | grep -q "Status:.*installed" ;;
		PACMAN) pacman -Qq "${1,,}" &>/dev/null ;;
		YUM) rpm -q "${1,,}" &>/dev/null ;;
		ZYPPER) rpm -q "${1,,}" &>/dev/null ;;
		*) return 127 ;;
	esac
}
function pkg::installl() {
	.Flag

	case "${PKG_MGR^^}" in
		APK) apk add "${1,,}" ;;
		APT) ChkApt && DEBIAN_FRONTEND=noninteractive apt-get install -y "${1,,}" ;;
		DNF) dnf install -y "${1,,}" ;;
		OPKG) opkg install "${1,,}" ;;
		PACMAN) pacman -S --noconfirm "${1,,}" ;;
		YUM) yum install -y "${1,,}" ;;
		ZYPPER) zypper --non-interactive install -y "${1,,}" ;;
		*) return 127 ;;
	esac
}
function pkg::remove() {
	.Flag

	case "${PKG_MGR^^}" in
		APK) apk del "${1,,}" ;;
		APT) ChkApt && DEBIAN_FRONTEND=noninteractive apt-get purge -y "${1,,}" && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y ;;
		DNF) dnf remove -y "${1,,}" ;;
		OPKG) opkg remove "${1,,}" ;;
		PACMAN) pacman -Rns --noconfirm "${1,,}" ;;
		YUM) yum remove -y "${1,,}" ;;
		ZYPPER) zypper --non-interactive remove -y "${1,,}" ;;
		*) return 127 ;;
	esac
}
function pkg::update() {
	.Root

	case "${PKG_MGR^^}" in
		APK) apk update ;;
		APT) ChkApt && DEBIAN_FRONTEND=noninteractive apt-get update -y ;;
		DNF) dnf check-update -y ;;
		OPKG) opkg update ;;
		PACMAN) : ;;
		YUM) yum check-update -y ;;
		ZYPPER) zypper refresh ;;
		*) return 127 ;;
	esac
}
function pkg::upgrade() {
	.Root

	if pkg::update; then
		case "${PKG_MGR^^}" in
			APK) apk upgrade ;;
			APT) ChkApt && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y ;;
			DNF) dnf upgrade -y ;;
			OPKG) : ;;
			PACMAN) pacman -Syu --noconfirm ;;
			YUM) yum upgrade -y ;;
			ZYPPER) zypper dup -y --no-allow-vendor-change ;;
			*) return 127 ;;
		esac
	fi
}

function AddFile() {
	.Flag
	local item parent_dir

	for item in "$@"; do
		Txt "${CLR[3]}新增檔案 '${item}'${CLR[0]}"
		if [[ -e "${item}" ]]; then
			Err "檔案或目錄 '${item}' 已存在" || return 1
		fi
		parent_dir="${item%/*}"

		if [[ "${parent_dir}" != "${item}" && ! -d "${parent_dir}" ]]; then
			if ! mkdir -p "${parent_dir}"; then
				Err "無法建立父目錄 '${parent_dir}'。請檢查權限" || return 1
			fi
		fi

		if : >"${item}"; then
			Txt "- 檔案 '${item}' 建立成功"
		else
			Err "建立檔案 '${item}' 失敗。請檢查權限和磁碟空間" || return 1
		fi
	done
	Finish
}
function AddDir() {
	.Flag
	local item

	for item in "$@"; do
		Txt "${CLR[3]}新增目錄 '${item}'${CLR[0]}"

		if [[ -e "${item}" ]]; then
			Err "檔案或目錄 '${item}' 已存在" || return 1
		fi

		if mkdir -p "${item}"; then
			Txt "- 目錄 '${item}' 建立成功"
		else
			Err "建立目錄 '${item}' 失敗。請檢查權限和路徑有效性" || return 1
		fi
	done
	Finish
}
function AddPkg() {
	.Root.Flag
	local pkg

	case "${PKG_MGR^^}" in
		APK) : ;;
		APT) : ;;
		DNF) : ;;
		OPKG) : ;;
		PACMAN) : ;;
		YUM) : ;;
		ZYPPER) : ;;
		*) Err "不支援的套件管理器" || return 1 ;;
	esac

	for pkg in "$@"; do
		Txt "${CLR[3]}安裝套件 '${pkg}'${CLR[0]}"

		if pkg::is_installed "${pkg}"; then
			Txt "- 套件 ${pkg} 已經安裝"
		else
			if pkg::installl "${item}"; then
				Txt "- 套件 ${pkg} 安裝成功"
			else
				Err "使用 ${PKG_MGR} 安裝 ${pkg} 失敗" || return 1
			fi
		fi
	done
	Finish
}
function ChkDeps() {
	local -i mode
	mode=0
	local cont_inst dep msg
	cont_inst="" dep="" msg=""
	local missg_deps target_deps
	missg_deps=() target_deps=()

	while (($# > 0)); do
		case "$1" in
			-a | --automatic) mode=1 ;;
			-i | --interactive) mode=2 ;;
			-*) Err "無效的選項：$1" || return 1 ;;
			*) target_deps+=("${1}") ;;
		esac
		shift
	done

	((${#target_deps[@]} == 0)) && return 0

	for dep in "${target_deps[@]}"; do
		if command -v "${dep}" &>/dev/null; then
			msg="${CLR[2]}［可執行］${CLR[0]}"
		elif pkg::is_installed "${dep}"; then
			msg="${CLR[3]}［僅存在］${CLR[0]}"
		else
			msg="${CLR[1]}［未能知］${CLR[0]}"
			missg_deps+=("${dep}")
		fi
		Txt "${msg}\t${dep}"
	done

	((${#missg_deps[@]} == 0)) && return 0

	case "${mode}" in
		1)
			Raw "\n"
			AddPkg "${missg_deps[@]}"
			;;
		2)
			Txt "\n${CLR[3]}缺少的套件：${CLR[0]} ${missg_deps[*]}"
			Ask "是否要安裝缺少的套件？(y/N) " -n 1 cont_inst
			Raw "\n"
			[[ "${cont_inst}" =~ ^[Yy]$ ]] && AddPkg "${missg_deps[@]}"
			;;
	esac
}
function ChkOs() {
	local os_id

	case "$1" in
		-v | --version)
			if [[ -f "/etc/os-release" ]]; then
				os_id=$(cat "/etc/os-release" | GetValue "ID")

				case "${os_id^^}" in
					DEBIAN) cat "/etc/debian_version" ;;
					FEDORA) grep -oE '[0-9]+' "/etc/fedora-release" ;;
					CENTOS) grep -oE '[0-9]+\.[0-9]+' "/etc/centos-release" ;;
					ALPINE) cat "/etc/alpine-release" ;;
					*) Txt "${VERSION_ID}" ;;
				esac
			elif [[ -f "/etc/debian_version" ]]; then
				cat "/etc/debian_version"
			elif [[ -f "/etc/fedora-release" ]]; then
				grep -oE '[0-9]+' "/etc/fedora-release"
			elif [[ -f "/etc/centos-release" ]]; then
				grep -oE '[0-9]+\.[0-9]+' "/etc/centos-release"
			elif [[ -f "/etc/alpine-release" ]]; then
				cat "/etc/alpine-release"
			else
				Err "未知的發行版" || return 1
			fi
			;;
		-n | --name)
			if [[ -f "/etc/os-release" ]]; then
				cat "/etc/os-release" | GetValue "NAME"
			elif [[ -f "/etc/DISTRO_SPECS" ]]; then
				cat "/etc/DISTRO_SPECS" | GetValue "DISTRO_NAME"
			else
				Err "未知的發行版" || return 1
			fi
			;;
		*)

			if [[ -f "/etc/os-release" ]]; then
				cat "/etc/os-release" | GetValue "NAME"
			elif [[ -f "/etc/DISTRO_SPECS" ]]; then
				cat "/etc/DISTRO_SPECS" | GetValue "DISTRO_NAME"
			else
				Err "未知的發行版" || return 1
			fi
			;;
	esac
}
function sys::virt() {
	if Cmdd "systemd-detect-virt"; then
		local -r virt_typ="$(systemd-detect-virt 2>/dev/null)"

		if [[ -z "${virt_typ}" ]]; then
			Err "無法偵測虛擬化環境" || return 1
		fi

		case "${virt_typ^^}" in
			KVM)
				if [[ "$(cat "/sys/class/dmi/id/product_name" 2>/dev/null)" == *[Pp]roxmox* ]]; then
					Txt "Proxmox VE (KVM)"
				else
					Txt "KVM"
				fi
				;;
			MICROSOFT) Txt "Microsoft Hyper-V" ;;
			WSL) Txt "適用於 Linux 的 Windows 子系統" ;;
			NONE)
				if [[ -r "/proc/1/environ" ]] && grep -q "container=lxc" "/proc/1/environ" 2>/dev/null; then
					Txt "LXC 容器"
				elif [[ -r "/proc/cpuinfo" ]] && grep -qi "hypervisor" "/proc/cpuinfo" 2>/dev/null; then
					Txt "虛擬機器（未知類型）"
				else
					Txt "未偵測到（可能為實體機器）"
				fi
				;;
			*) Txt "${virt_typ}" ;;
		esac
	elif [[ -f "/proc/cpuinfo" ]]; then
		if grep -qi "hypervisor" "/proc/cpuinfo" 2>/dev/null; then
			Txt "虛擬機器（未知類型）"
		else
			Txt "未偵測到（可能為實體機器）"
		fi
	else
		Txt "未知環境"
	fi
}
function Clear() {
	if ! cd "${1:-${HOME}}"; then
		Err "切換目錄失敗" || return 1
	fi
	clear
}
function cpu::cache() {
	local cpu_cache

	if [[ -f "/proc/cpuinfo" ]]; then
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用" || return 1
	fi
	cpu_cache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' "/proc/cpuinfo")
	if [[ "${cpu_cache}" == "N/A" ]]; then
		Err "無法確定 CPU 快取大小" || return 1
	fi
	Txt "${cpu_cache} KB"
}
function cpu::frequency() {
	local cpu_freq
	if [[ -f "/proc/cpuinfo" ]]; then
		Err "無法存取 CPU 資訊。/proc/cpuinfo 不可用" || return 1
	fi
	cpu_freq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
	if [[ ${cpu_freq} == "N/A" ]]; then
		Err "無法確定 CPU 頻率" || return 1
	fi
	Txt "${cpu_freq} GHz"
}
function cpu::model() {
	local cpuspec model_name
	if Cmdd lscpu; then
		cpuspec=$(lscpu)
		model_name="${cpuspec##*Model name:}"
		model_name="${model_name%%$'\n'*}"
		Txt "${model_name}"
	elif [[ -f "/proc/cpuinfo" ]]; then
		sed -n 's/^model name[[:space:]]*: //p' "/proc/cpuinfo" | head -n1
	elif Cmdd "sysctl"; then
		sysctl -n machdep.cpu.brand_string
	fi || { Err "${CLR[1]}未知${CLR[0]}" || return 1; }
}
function cpu::usage() {
	local _
	local -i usr nice sys idle iowait irq softirq steal guest guest_nice
	local -i prev_total prev_idle curr_total curr_idle tot_delta idle_delta cpu_usage

	if read -r _ usr nice sys idle iowait irq softirq steal guest guest_nice <<<"$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' /proc/stat)"; then
		[[ -n "${idle}" ]] || { Err "從 /proc/stat 讀取第一階段 CPU 統計失敗" || return 1; }
	fi
	prev_total=$((usr + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice))
	prev_idle=idle

	sleep 0.3

	if read -r _ usr nice sys idle iowait irq softirq steal guest guest_nice <<<"$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' /proc/stat)"; then
		[[ -n "${idle}" ]] || { Err "從 /proc/stat 讀取第二階段 CPU 統計失敗" || return 1; }
	fi
	curr_total=$((usr + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice))
	curr_idle=idle

	tot_delta=$((curr_total - prev_total))
	idle_delta=$((curr_idle - prev_idle))

	((tot_delta == 0)) && Txt "0"
	cpu_usage=$((100 * (tot_delta - idle_delta) / tot_delta))
	Txt "${cpu_usage}"
}
function ConvSz() {
	.Flag
	local size="$1" default_pref="${UNIT_PREF:-b}" && local unit="${2:-${default_pref}}"

	if [[ ${size} == -* ]]; then
		Err "大小值不能為負數：${size}" || return 1
	fi

	LC_NUMERIC=C
	awk -v size="${size}" -v unit="${unit}" '
        function ToBytes(val, u) {
            if (u == "b" || u == "ib")      return val;
            if (u == "kb")                  return val * 1000;
            if (u == "mb")                  return val * 1000^2;
            if (u == "gb")                  return val * 1000^3;
            if (u == "tb")                  return val * 1000^4;
            if (u == "pb")                  return val * 1000^5;
            if (u == "kib")                 return val * 1024;
            if (u == "mib")                 return val * 1024^2;
            if (u == "gib")                 return val * 1024^3;
            if (u == "tib")                 return val * 1024^4;
            if (u == "pib")                 return val * 1024^5;
            return -1;
        }
        BEGIN {
            bytes = ToBytes(size, unit);
            if (bytes < 0) exit 1;

            is_binary = (index(unit, "ib") > 0);
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
                if (power > 0) value = bytes / (base^power);
            }
            if (power == 0) {
                printf "%d %s", bytes, units_arr[1];
            } else {
                if (value >= 100)       printf "%.1f %s", value, units_arr[power + 1];
                else if (value >= 10)   printf "%.2f %s", value, units_arr[power + 1];
                else                    printf "%.3f %s", value, units_arr[power + 1];
            }
        }
    ' || { Err "不支持的單位或格式錯誤：size=${size} unit=${unit}" || return 1; }
}
function DelFile() {
	.Flag

	local item
	for item in "$@"; do
		Txt "${CLR[3]}刪除檔案 '${item}'${CLR[0]}"
		if [[ -f "${item}" ]]; then
			if rm -f "${item}"; then
				Txt "- 檔案 '${item}' 刪除成功"
			else
				Err "刪除檔案 ${item} 失敗。請檢查權限" || return 1
			fi
		else
			Err "- 檔案 '${item}' 不存在\n" || return 1
		fi
	done
	Finish
}
function DelDir() {
	.Flag

	local item
	for item in "$@"; do
		Txt "${CLR[3]}刪除目錄 '${item}'${CLR[0]}"
		if [[ -d "${item}" ]]; then
			if rm -rf "${item}"; then
				Txt "- 目錄 '${item}' 刪除成功"
			else
				Err "刪除目錄 '${item}' 失敗。請檢查權限\n" || return 1
			fi
		else
			Err "目錄 '${item}' 不存在\n" || return 1
		fi
		Finish
	done
}
function DelPkg() {
	.Root.Flag
	local pkg

	case "${PKG_MGR^^}" in
		APK) : ;;
		APT) : ;;
		DNF) : ;;
		OPKG) : ;;
		PACMAN) : ;;
		YUM) : ;;
		ZYPPER) : ;;
		*) Err "不支援的套件管理器" || return 1 ;;
	esac

	for pkg in "$@"; do
		Txt "${CLR[3]}移除套件 '${pkg}'${CLR[0]}"

		if pkg::is_installed "${pkg}"; then
			if pkg::remove "${pkg}"; then
				Txt "- 套件 ${pkg} 移除成功"
			else
				Err "使用 ${PKG_MGR} 移除 ${pkg} 失敗" || return 1
			fi
		else
			Txt "- 套件 ${pkg} 不存在"
		fi
	done
	Finish
}
function disk::info() {
	local usd tot pct
	usd=$(df -B1 / | awk '/^\/dev/ {print $3}') || { Err "取得磁碟使用統計資料失敗" || return 1; }
	tot=$(df -B1 / | awk '/^\/dev/ {print $2}') || { Err "取得總磁碟空間失敗" || return 1; }
	pct=$(df / | awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
	case "${1:-}" in
		-p | --percentage) Txt "${pct}" ;;
		-t | --total) Txt "${tot}" ;;
		-u | --used) Txt "${usd}" ;;
		*) Txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function net::dns() {
	local -r file='/etc/resolv.conf'
	[[ -f "${file}" ]] || { Err "找不到 DNS 設定檔 ${file}" || return 1; }
	local dns4=()
	local dns6=()

	while read -r servers; do
		if [[ "${servers}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
			dns4+=("${servers}")
		elif [[ "${servers}" =~ ^[0-9a-fA-F:]+$ ]]; then
			dns6+=("${servers}")
		fi
	done < <(grep -E '^nameserver' "${file}" | awk '{print $2}')

	if ((${#dns4[@]} == 0 && ${#dns6[@]} == 0)); then
		Err "${file} 中未設定 DNS 伺服器" || return 1
	fi
	case "${1:-}" in
		-4 | --ipv4)
			if ((${#dns4[@]} == 0)); then
				Err "找不到 IPv4 DNS 伺服器" || return 1
			fi
			Txt "${dns4[*]}"
			;;
		-6 | --ipv6)
			if ((${#dns6[@]} == 0)); then
				Err "找不到 IPv6 DNS 伺服器" || return 1
			fi
			Txt "${dns6[*]}"
			;;
		*)
			if ((${#dns4[@]} == 0 && ${#dns6[@]} == 0)); then
				Err "找不到 DNS 伺服器" || return 1
			fi
			Txt "${dns4[*]}   ${dns6[*]}"
			;;
	esac
}
function FindPkg() {
	.Flag
	local srch_cmd

	case "${PKG_MGR^^}" in
		APK) srch_cmd="apk search" ;;
		APT) srch_cmd="apt-cache search" ;;
		DNF) srch_cmd="dnf search" ;;
		OPKG) srch_cmd="opkg search" ;;
		PACMAN) srch_cmd="pacman -Ss" ;;
		YUM) srch_cmd="yum search" ;;
		ZYPPER) srch_cmd="zypper search" ;;
		*) Err "找不到或不支援的套件管理器" || return 1 ;;
	esac
	for targ in "$@"; do
		Txt "${CLR[3]}搜尋 '${targ}'${CLR[0]}"
		${srch_cmd} "${targ}" || { Err "找不到 '${targ}' 的結果\n" || return 1; }
	done
	Finish
}
function file::download() {
	local unzip targ_dir rnm_file url oup_file oup_path file_sz
	unzip=false
	targ_dir="."
	while (($# > 0)); do
		case "$1" in
			-x | --unzip) unzip=true && shift ;;
			-r | --rename)
				if [[ -z "$1" || "$1" == -* ]]; then
					Err "-r 選項後未指定檔案名稱" || return 1
				fi
				rnm_file="$1"
				shift 2
				;;
			-*) Err "無效的選項：$1" || return 1 ;;
			*)
				if [[ -z "${url}" ]]; then
					url="$1" || targ_dir="$1"
				fi
				shift
				;;
		esac
	done

	if [[ -z "${url}" ]]; then
		Err "未指定 URL。請提供要下載的 URL" || return 1
	fi
	[[ "${url}" =~ ^(http|https|ftp):// ]] || url="https://${url}"
	oup_file="${url##*/}"
	[[ -z "${oup_file}" ]] && oup_file="index.html"
	if [[ ${targ_dir} != "." ]]; then
		mkdir -p "${targ_dir}"
	else
		Err "建立目錄 ${targ_dir} 失敗" || return 1
	fi
	[[ -n "${rnm_file}" ]] && oup_file="${rnm_file}"
	oup_path="${targ_dir}/${oup_file}"
	url=$(Txt "${url}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR[3]}下載 '${url}'${CLR[0]}"

	file_sz=$(wget --spider "${url}" 2>&1 | Trim "Length: " "(")

	if ((file_sz > 26214400)); then
		wget --no-check-certificate --timeout=5 --tries=2 "${url}" -O "${oup_path}" || { Err "使用 Wget 下載檔案失敗" || return 1; }
	else
		curl --location --insecure --connect-timeout 5 --retry 2 "${url}" -o "${oup_path}" || { Err "使用 cUrl 下載檔案失敗" || return 1; }
	fi

	if [[ -f "${oup_path}" ]]; then
		Txt "- 檔案成功下載至 ${oup_path}"
		if [[ ${unzip} == true ]]; then
			if case ${oup_file} in
				*.tar.gz | *.tgz) tar -xzf "${oup_path}" -C "${targ_dir}" ;;
				*.tar) tar -xf "${oup_path}" -C "${targ_dir}" ;;
				*.tar.bz2 | *.tbz2) tar -xjf "${oup_path}" -C "${targ_dir}" ;;
				*.tar.xz | *.txz) tar -xJf "${oup_path}" -C "${targ_dir}" ;;
				*.zip) unzip "${oup_path}" -d "${targ_dir}" ;;
				*.7z) 7z x "${oup_path}" -o"${targ_dir}" ;;
				*.rar) unrar x "${oup_path}" "${targ_dir}" ;;
				*.zst) zstd -d "${oup_path}" -o "${targ_dir}" ;;
				*) Txt "- 無法識別的檔案格式，不進行自動解壓縮" && false ;; # 回傳 false 阻止印出成功訊息
			esac then
				Txt "- 檔案成功解壓縮至 ${targ_dir}"
			else
				Err "解壓縮失敗！" || return 1
			fi
		fi
	else
		Err "下載失敗。請檢查網路連線和 URL 有效性" || return 1
	fi
	Finish
}
function Ask() {
	shift
	if read -e -p "$(Txt "$1")" -r "$@"; then
		Err "讀取使用者輸入失敗" || return 1
	fi
}
function net::interface() {
	local all_interfaces default4_route default6_route interface interfaces=() interfaces_num items=()
	local i item interface4 interface6 physical_iface iface stats
	local rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop

	all_interfaces=$(
		cat /proc/net/dev |
			grep ':' |
			cut -d':' -f1 |
			sed 's/\s//g' |
			grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker\|^br-\|^veth' |
			sort -n
	) || { Err "從 /proc/net/dev 取得網路介面失敗" || return 1; }

	mapfile -t items <<<"${all_interfaces}"
	interfaces=([0]="placeholder")
	for item in "${items[@]}"; do
		[[ -n "${item}" ]] && interfaces+=("${item}")
	done
	unset 'interfaces[0]'
	interfaces_num=${#interfaces[@]}

	default4_route=$(ip -4 route show default 2>/dev/null || Txt "")
	default6_route=$(ip -6 route show default 2>/dev/null || Txt "")

	for ((i = 1; i <= ${#interfaces[@]}; i++)); do
		item="${interfaces[i]}"
		[[ -z "${item}" ]] && continue

		if [[ -n "${default4_route}" && -z "${interface4}" ]]; then
			Txt "${default4_route}" | grep -qE "\bdev ${item}\b"
			interface4="${item}"
		fi
		if [[ -n "${default6_route}" && -z "${interface6}" ]]; then
			Txt "${default6_route}" | grep -qE "\bdev ${item}\b"
			interface6="${item}"
		fi
		[[ -n "${interface4}" && -n "${interface6}" ]] && break
	done

	if [[ -z "${interface4}"${interface6} ]]; then
		for ((i = 1; i <= ${#interfaces[@]}; i++)); do
			item="${interfaces[i]}"
			if [[ "${item}" =~ ^en ]]; then
				interface4="${item}"
				interface6="${item}"
				break
			fi
		done
		if [[ -z "${interface4}"${interface6} && ${interfaces_num} -eq 0 ]]; then
			interface4="${interfaces[1]}"
			interface6="${interfaces[1]}"
		fi
	fi

	if [[ -n "${interface4}" || -n "${interface6}" ]]; then
		interface="${interface4} ${interface6}"
		[[ "${interface4}" == "${interface6}" ]] && interface="${interface4}"
		interface=$(Txt "${interface}" | tr -s ' ' | xargs)
	else
		physical_iface=$(ip -o link show | grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | grep 'state UP' | head -n 1 | awk -F': ' '{print $2}')
		if [[ -n "${physical_iface}" ]]; then
			interface="${physical_iface}"
		else
			interface=$(ip -o link show | grep -v 'lo:' | head -n 1 | awk -F': ' '{print $2}')
		fi
	fi

	case "$1" in
		--rx_bytes | --rx_packets | --rx_drop | --tx_bytes | --tx_packets | --tx_drop)
			for iface in ${interface}; do
				while read -r line; do
					if [[ "$line" =~ ^[[:space:]]*"${iface}": ]]; then
						read -r -a arr <<<"$line"
						stats="${arr[1]} ${arr[2]} ${arr[4]} ${arr[9]} ${arr[10]} ${arr[12]}"
						break
					fi
				done </proc/net/dev 2>/dev/null
				if [[ -n "${stats}" ]]; then
					read -r rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"${stats}"
					case "$1" in
						--rx_bytes) Txt "${rx_bytes}" && break ;;
						--rx_packets) Txt "${rx_packets}" && break ;;
						--rx_drop) Txt "${rx_drop}" && break ;;
						--tx_bytes) Txt "${tx_bytes}" && break ;;
						--tx_packets) Txt "${tx_packets}" && break ;;
						--tx_drop) Txt "${tx_drop}" && break ;;
					esac
				fi
			done
			;;
		-i | --information)
			for iface in ${interface}; do
				while read -r line; do
					if [[ "${line}" =~ ^[[:space:]]*"${iface}": ]]; then
						read -r -a arr <<<"${line}"
						stats="${arr[1]} ${arr[2]} ${arr[4]} ${arr[9]} ${arr[10]} ${arr[12]}"
						break
					fi
				done <"/proc/net/dev" 2>/dev/null
				if [[ -n "${stats}" ]]; then
					read -r rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"${stats}"
					Txt "${iface}：輸入：$(ConvSz "${rx_bytes}")，輸出：$(ConvSz "${tx_bytes}")"
				fi
			done
			;;
		*) Txt "${interface}" ;;
	esac
}
function net::ip() {
	local -r apis=("api64.ipify.org" "ifconfig.me" "ipinfo.io") ip4_regex="(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}"
	local -r ip6_regex="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"
	local ip4_addr ip6_addr
	case "$1" in
		-4 | --ipv4)
			for api in "${apis[@]}"; do
				ip4_addr=$(timeout 1s curl -s4L "${api}" 2>/dev/null)
				break
			done

			ip4_addr=$(grep -oE "${ip4_regex}" <<<"${ip4_addr}")
			if ! Txt "${ip4_addr:-N/A}"; then
				Err "取得 IPv4 位址失敗" || return 1
			fi
			;;
		-6 | --ipv6)
			for api in "${apis[@]}"; do
				ip6_addr=$(timeout 1s curl -s6L "${api}" 2>/dev/null)
				break
			done
			ip6_addr=$(grep -oE "${ip6_regex}" <<<"${ip6_addr}")
			if ! Txt "${ip6_addr:-N/A}"; then
				Err "取得 IPv6 位址失敗" || return 1
			fi
			;;
		-p | --public)
			data=$(wget -qO- "https://developers.cloudflare.com/cdn-cgi/trace" | GetValue "ip")
			if ! Txt "${data}"; then
				Err "無法偵測公開 IP 位址。請檢查網路連線" || return 1
			fi
			;;
		*)
			for api in "${apis[@]}"; do
				ip4_addr=$(timeout 1s curl -s4L "${api}" 2>/dev/null)
				break
			done
			ip4_addr=$(grep -oE "${ip4_regex}" <<<"${ip4_addr}")

			for api in "${apis[@]}"; do
				ip6_addr=$(timeout 1s curl -s6L "${api}" 2>/dev/null)
				break
			done
			ip6_addr=$(grep -oE "${ip6_regex}" <<<"${ip6_addr}")

			if [[ -z "${ip4_addr}"${ip6_addr} ]]; then
				Err "取得 IP 位址失敗" || return 1
			fi
			Raw "IPv4: " && Txt "${ip4_addr:-N/A}"
			Raw "IPv6: " && Txt "${ip6_addr:-N/A}"
			;;
	esac
}
function LastUpd() {
	if [[ -f "/var/log/apt/history.log" ]]; then
		data=$(awk '/End-Date:/ {print $2, $3, $4; exit}' "/var/log/apt/history.log" 2>/dev/null)
	elif [[ -f /var/log/dpkg.log ]]; then
		data=$(tail -n 1 /var/log/dpkg.log | awk '{print $1, $2}')
	elif Cmdd rpm; then
		data=$(rpm -qa --last | head -n 1 | awk '{print $3, $4, $5, $6, $7}')
	fi
	Txt "${data}" || { Err "無法確定最後系統更新時間。找不到更新日誌" || return 1; }
}
function sys::load() {
	local -r LC_ALL=C
	local data zo_mi zv_mi ov_mi

	if read -r zo_mi zv_mi ov_mi _ _ </proc/loadavg 2>/dev/null; then
		data="${zo_mi}, ${zv_mi}, ${ov_mi}"
	elif Cmdd uptime; then
		data=$(uptime 2>/dev/null | awk -F'load average?: ' '{print $2}' | sed 's/,//g')
		[[ -z "${data}" ]] && data=$(uptime 2>/dev/null | awk '{print $(NF-2), $(NF-1), ${NF}}' | sed 's/,//g')
		read -r zo_mi zv_mi ov_mi <<<"${data}"
	else
		Err "缺失取得方法" || return 1
	fi

	if [[ -z ${zo_mi-} || -z ${zv_mi-} || -z ${ov_mi-} ]]; then
		Err "取得負載平均值失敗" || return 1
	fi

	Txt "${data} ($(nproc) Cores)"
}
function Loc() {
	ChkDeps curl

	case "$1" in
		--city) data=$(curl -s "https://ipinfo.io/city") ;;
		--country | *) data=$(curl -s "https://ipinfo.io/country") ;;
	esac

	if ! Txt "${data}"; then
		Err "無法偵測地理位置。請檢查網路連線" || return 1
	fi
}
function net::mac() {
	data=$(ip link show | awk '/ether/ {print $2; exit}')
	if ! Txt "${data}"; then
		Err "無法取得 MAC 位址。找不到網路介面" || return 1
	fi
}
function mem::info() {
	usd=$(free -b | awk '/^Mem:/ {print $3}') || usd=$(vmstat -s | grep 'used memory' | awk '{print $1*1024}') || { Err "取得記憶體使用統計資料失敗" || return 1; }
	tot=$(free -b | awk '/^Mem:/ {print $2}') || tot=$(grep MemTotal /proc/meminfo | awk '{print $2*1024}')
	pct=$(free | awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}') || pct=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
	case "${1:-}" in
		-u | --used) Txt "${usd}" ;;
		-t | --total) Txt "${tot}" ;;
		-p | --percentage) Txt "${pct}" ;;
		*) Txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function net::provider() {
	data=$(timeout 1s curl -sL ipinfo.io | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data=$(timeout 1s curl -sL ipwhois.app/json | grep -oP '"org"\s*:\s*"\K[^"]+') ||
		data=$(timeout 1s curl -sL ip-api.com/json | grep -oP '"org"\s*:\s*"\K[^"]+')
	Txt "${data}" || { Err "無法偵測網路供應商。請檢查網路連線" || return 1; }
}

function sys::shell_version() {
	local LC_ALL="C"

	if [[ -n "${BASH_VERSION:-}" ]]; then
		Txt "Bash ${BASH_VERSION}"
	elif [[ -n "${ZSH_VERSION:-}" ]]; then
		Txt "Zsh ${ZSH_VERSION}"
	else
		Err "不支援的 Shell" || return 1
	fi
}
function swap::info() {
	local usd tot pct
	pct=$(free -b | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
	tot=$(free -b | awk '/^Swap:/ {printf "%.0f", $2}')
	usd=$(free -b | awk '/^Swap:/ {printf "%.0f", $3}')
	case "${1:-}" in
		-p | --percentage) Txt "${pct}" ;;
		-t | --total) Txt "${tot}" ;;
		-u | --used) Txt "${usd}" ;;
		*) Txt "$(ConvSz "${usd}")/$(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function SysClean() {
	.Root
	Txt "${CLR[3]}正在執行系統清理...${CLR[0]}"
	DLine

	case "${PKG_MGR^^}" in
		APK)
			Task "- 清理 ${PKG_MGR} 快取" "apk cache clean" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			Task "- 移除暫存檔案" "rm -rf /tmp/* /var/cache/apk/*" || { Err "移除暫存檔案失敗" || return 1; }
			Task "- 修復 ${PKG_MGR} 套件" "apk fix" || { Err "修復 ${PKG_MGR} 套件失敗" || return 1; }
			;;
		APT)
			ChkApt
			Task "- 設定待處理的套件" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || { Err "設定待處理套件失敗" || return 1; }
			Task "- 自動移除套件" "DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y" || { Err "自動移除套件失敗" || return 1; }
			Task "- 清理 ${PKG_MGR} 快取" "DEBIAN_FRONTEND=noninteractive apt-get clean -y" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			Task "- 自動清理 ${PKG_MGR} 快取" "DEBIAN_FRONTEND=noninteractive apt-get autoclean -y" || { Err "自動清理 ${PKG_MGR} 快取失敗" || return 1; }
			;;
		OPKG)
			Task "- 移除暫存檔案" "rm -rf /tmp/*" || { Err "移除暫存檔案失敗" || return 1; }
			Task "- 更新 ${PKG_MGR}" "opkg update" || { Err "更新 ${PKG_MGR} 失敗" || return 1; }
			Task "- 清理 ${PKG_MGR} 快取" "opkg clean" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			;;
		PACMAN)
			Task "- 更新和升級套件" "pacman -Syu --noconfirm" || { Err "使用 ${PKG_MGR} 更新和升級套件失敗" || return 1; }
			Task "- 清理 ${PKG_MGR} 快取" "pacman -Sc --noconfirm" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			Task "- 清理所有 ${PKG_MGR} 快取" "pacman -Scc --noconfirm" || { Err "清理所有 ${PKG_MGR} 快取失敗" || return 1; }
			;;
		DNF)
			Task "- 自動移除套件" "dnf autoremove -y" || { Err "自動移除套件失敗" || return 1; }
			Task "- 清理 ${PKG_MGR} 快取" "dnf clean all" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			Task "- 建立 ${PKG_MGR} 快取" "dnf makecache" || { Err "建立 ${PKG_MGR} 快取失敗" || return 1; }
			;;
		YUM)
			Task "- 自動移除套件" "yum autoremove -y" || { Err "自動移除套件失敗" || return 1; }
			Task "- 清理 ${PKG_MGR} 快取" "yum clean all" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			Task "- 建立 ${PKG_MGR} 快取" "yum makecache" || { Err "建立 ${PKG_MGR} 快取失敗" || return 1; }
			;;
		ZYPPER)
			Task "- 清理 ${PKG_MGR} 快取" "zypper clean --all" || { Err "清理 ${PKG_MGR} 快取失敗" || return 1; }
			Task "- 重新整理 ${PKG_MGR} 套件庫" "zypper refresh" || { Err "重新整理 ${PKG_MGR} 套件庫失敗" || return 1; }
			;;
		*) Err "不支援的套件管理器。跳過系統特定清理" || return 1 ;;
	esac

	if Cmdd journalctl; then
		if ! Task "- 輪替和清理 journalctl 日誌" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M"; then
			Err "輪替和清理 journalctl 日誌失敗（系統找不到 journalctl 指令）" || return 1
		fi
	fi

	local cmd
	for cmd in docker npm pip; do
		Cmdd "${cmd}" && case "${cmd^^}" in
			DOCKER)
				if ! Task "- 清理 DOCKER 系統" "docker system prune -af"; then
					Err "清理 DOCKER 系統失敗" || return 1
				fi
				;;
			NPM)
				if ! Task "- 清理 NPM 快取" "npm cache clean --force"; then
					Err "清理 NPM 快取失敗" || return 1
				fi
				;;
			PIP)
				if ! Task "- 清除 PIP 快取" "pip cache purge"; then
					Err "清除 PIP 快取失敗" || return 1
				fi
				;;
		esac
	done

	Task "- 移除使用者快取檔案" "rm -rf ~/.cache/*" || { Err "移除使用者快取檔案失敗" || return 1; }
	Task "- 移除暫存檔案" "rm -rf /tmp/*" || { Err "移除暫存檔案失敗" || return 1; }
	Task "- 移除縮圖檔案" "rm -rf ~/.thumbnails/*" || { Err "移除縮圖檔案失敗" || return 1; }

	DLine && Finish
}
function SysInfo() {
	Txt "${CLR[3]}系統資訊${CLR[0]}"
	DLine

	Txt "- 主機名稱：            ${CLR[2]}$(uname -n || hostname)${CLR[0]}"
	Txt "- 作業系統：            ${CLR[2]}$(ChkOs)${CLR[0]}"
	Txt "- 核心版本：            ${CLR[2]}$(uname -r)${CLR[0]}"
	Txt "- 系統語言：            ${CLR[2]}${LANG}${CLR[0]}"
	Txt "- Shell 版本：          ${CLR[2]}$(sys::shell_version)${CLR[0]}"
	Txt "- 最後系統更新：        ${CLR[2]}$(LastUpd)${CLR[0]}"

	SLine

	Txt "- 架構：                ${CLR[2]}$(uname -m)${CLR[0]}"
	Txt "- CPU 型號：            ${CLR[2]}$(cpu::model)${CLR[0]}"
	Txt "- CPU 核心數：          ${CLR[2]}$(nproc)${CLR[0]}"
	Txt "- CPU 頻率：            ${CLR[2]}$(cpu::frequency)${CLR[0]}"
	Txt "- CPU 使用率：          ${CLR[2]}$(cpu::usage)%${CLR[0]}"
	Txt "- CPU 快取：            ${CLR[2]}$(cpu::cache)${CLR[0]}"

	SLine

	Txt "- 記憶體使用率：        ${CLR[2]}$(mem::info)${CLR[0]}"
	Txt "- SWAP 使用率：         ${CLR[2]}$(swap::info)${CLR[0]}"
	Txt "- 磁碟使用率：          ${CLR[2]}$(disk::info)${CLR[0]}"
	Txt "- 檔案系統類型：        ${CLR[2]}$(df -T / | awk 'NR==2 {print $2}')${CLR[0]}"

	SLine

	Txt "- IPv4 地址：           ${CLR[2]}$(net::ip --ipv4)${CLR[0]}"
	Txt "- IPv6 地址：           ${CLR[2]}$(net::ip --ipv6)${CLR[0]}"
	Txt "- MAC 位址：            ${CLR[2]}$(net::mac)${CLR[0]}"
	Txt "- 網路供應商：          ${CLR[2]}$(net::provider)${CLR[0]}"
	Txt "- DNS 伺服器：          ${CLR[2]}$(net::dns)${CLR[0]}"
	Txt "- 公開 IP：             ${CLR[2]}$(net::ip --public)${CLR[0]}"
	Txt "- 網路介面：            ${CLR[2]}$(net::interface -i)${CLR[0]}"
	Txt "- 內部時區：            ${CLR[2]}$(sys::timezone --internal)${CLR[0]}"
	Txt "- 外部時區：            ${CLR[2]}$(sys::timezone --external)${CLR[0]}"

	SLine

	Txt "- 負載平均：            ${CLR[2]}$(sys::load)${CLR[0]}"
	Txt "- 程序數量：            ${CLR[2]}$(ps aux | wc -l)${CLR[0]}"
	Txt "- 已安裝套件：          ${CLR[2]}$(pkg::count)${CLR[0]}"

	SLine

	Txt "- 啟動時刻：            ${CLR[2]}$(who -b | Trim "boot  ")${CLR[0]}"
	Txt "- 運行時間：            ${CLR[2]}$(uptime -p | Trim "up ")${CLR[0]}"

	SLine

	Txt "- 虛擬化：              ${CLR[2]}$(sys::virt)${CLR[0]}"

	DLine
}
function SysOptz() {
	.Root
	local sysctl_conf="/etc/sysctl.d/99-server-optimizations.conf"

	Txt "${CLR[3]}正在優化長期運行伺服器的系統設定...${CLR[0]}" && DLine
	file::add "${sysctl_conf}"
	Txt "# 長期運行系統的伺服器優化" >"${sysctl_conf}"
	_mem() {
		local sysctl_conf="$1"
		{
			Txt 'vm.dirty_background_ratio = 5'
			Txt 'vm.dirty_ratio = 15'
			Txt 'vm.min_free_kbytes = 65536'
			Txt 'vm.swappiness = 1'
			Txt 'vm.vfs_cache_pressure = 50'
		} >>"${sysctl_conf}"
	}

	_net() {
		local sysctl_conf="$1"
		{
			Txt 'net.core.netdev_max_backlog = 65535'
			Txt 'net.core.somaxconn = 65535'
			Txt 'net.ipv4.ip_local_port_range = 1024 65535'
			Txt 'net.ipv4.tcp_fin_timeout = 15'
			Txt 'net.ipv4.tcp_keepalive_intvl = 15'
			Txt 'net.ipv4.tcp_keepalive_probes = 5'
			Txt 'net.ipv4.tcp_keepalive_time = 300'
			Txt 'net.ipv4.tcp_max_syn_backlog = 65535'
			Txt 'net.ipv4.tcp_tw_reuse = 1'
		} >>"${sysctl_conf}"
	}

	_tcp() {
		local sysctl_conf="$1"
		{
			Txt 'net.core.rmem_max = 16777216'
			Txt 'net.core.wmem_max = 16777216'
			Txt 'net.ipv4.tcp_mtu_probing = 1'
			Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216'
			Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216'
		} >>"${sysctl_conf}"
	}

	_fs() {
		local sysctl_conf="$1"
		{
			Txt 'fs.file-max = 2097152'
			Txt 'fs.inotify.max_user_watches = 524288'
			Txt 'fs.nr_open = 2097152'
		} >>"${sysctl_conf}"
	}
	_limits() {
		{
			Txt '* hard nofile 1048576'
			Txt '* hard nproc 65535'
			Txt '* soft nofile 1048576'
			Txt '* soft nproc 65535'
		} >>"/etc/security/limits.conf"
	}
	_io() {
		local disk
		for disk in /sys/block/[sv]d*; do
			if [[ -d "${disk}" ]]; then
				Txt 'none' >"${disk}/queue/scheduler" 2>/dev/null || true
				Txt '256' >"${disk}/queue/nr_requests" 2>/dev/null || true
			fi
		done
	}
	_unused_service() {
		local service
		for service in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now "${service}" 2>/dev/null || true
		done
	}
	_clean_cache() {
		sync
		sysctl -w vm.drop_caches=3 >/dev/null 2>&1 || true
		ip -s -s neigh flush all >/dev/null 2>&1 || true
	}

	Task "- 正在優化記憶體管理" "_mem ${sysctl_conf}" &&
		Task "- 正在優化網路設定" "_net ${sysctl_conf}" &&
		Task "- 正在優化 TCP 緩衝區" "_tcp ${sysctl_conf}" &&
		Task "- 正在優化檔案系統設定" "_fs ${sysctl_conf}" &&
		Task "- 正在優化系統限制" "_limits" &&
		Task "- 正在優化 I/O 排程器" "_io" &&
		Task "- 停用非必要服務" "_unused_service" &&
		Task "- 套用系統參數" "sysctl --system" &&
		Task "- 清除系統快取" "_clean_cache"
	[[ $? == 0 ]] || { Err "系統優化流程中斷或失敗" || return 1; }

	DLine && Finish
}
function SysRboot() {
	.Root
	local active_usrs important_procs cont

	Txt "${CLR[3]}正在準備重新啟動系統...${CLR[0]}" && DLine

	active_usrs=$(who | wc -l) || { Err "取得活動使用者數量失敗" || return 1; }
	if ((active_usrs > 1)); then
		Txt "${CLR[1]}警告：目前系統有 ${active_usrs} 個活動使用者${CLR[0]}"
		Raw "\n"
		Txt "活動使用者：" && who | awk '{print $1 " since " $3 " " $4}'
		Raw "\n"
	fi
	important_procs=$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l) || { Err "檢查執行中的程序失敗" || return 1; }
	[[ ${important_procs} == 0 ]] || {
		Txt "${CLR[1]}警告：有 ${important_procs} 個重要程序正在執行${CLR[0]}"
		Raw "\n"
		Txt "${CLR[8]}CPU 使用率最高的 5 個程序：${CLR[0]}"
		ps aux --sort=-%cpu | head -n 6
		Raw "\n"
	}
	Ask "您確定要立即重新啟動系統嗎？(y/N) " -n 1 cont
	Raw "\n"
	[[ ${cont} =~ ^[Yy]$ ]] || {
		Txt "${CLR[2]}已取消重新啟動${CLR[0]}"
		Raw "\n"
		return 0
	}
	Task "- 執行最終檢查" "sync" || { Err "同步檔案系統失敗" || return 1; }
	Task "- 開始重新啟動" "reboot || sudo reboot" || { Err "啟動重新啟動失敗" || return 1; }
	Txt "${CLR[2]}已成功發出重新啟動命令。系統將立即重新啟動${CLR[0]}"
}
function SysUpd() {
	.Root

	local current_lang update_url

	current_lang="${LANG}"
	update_url="https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh"

	Txt "${CLR[3]}正在更新系統套件...${CLR[0]}" && DLine

	pkg::upgrade
	(set -o pipefail 2>/dev/null) && set -o pipefail
	wget -qO- "${update_url}" | bash -s -- "${current_lang}" && { Err "更新 UtilKit.sh 失敗" || return 1; }

	DLine && Finish
}
function SysUpg() {
	.Root

	Txt "${CLR[3]}正在升級系統至下一個主要版本...${CLR[0]}" && DLine

	os_nm=$(ChkOs --name)
	case "${os_nm,,}" in
		debian)
			Txt "- 偵測到 DEBIAN 系統"
			Txt "- 正在更新套件清單"
			DEBIAN_FRONTEND=noninteractive apt-get update -y || { Err "使用 APT 更新套件清單失敗" || return 1; }
			Txt "- 正在升級目前的套件"
			DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y || { Err "升級目前的套件失敗" || return 1; }
			Txt "- 開始 DEBIAN 發行版升級..."
			curr_codenm=$(lsb_release -cs)
			targ_codenm=$(wget -qO- "https://ftp.debian.org/debian/dists/stable/Release" | GetValue "Codename")
			if [[ "${curr_codenm}" == "${targ_codenm}" ]]; then
				Err "系統已達最新穩定版 (本地/遠端穩定版：${curr_codenm}/${targ_codenm})" || return 1
			fi
			Txt "- 正在從 ${CLR[2]}${curr_codenm}${CLR[0]} 升級到 ${CLR[3]}${targ_codenm}${CLR[0]}"
			Task "- 備份 sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || { Err "備份 sources.list 失敗" || return 1; }
			Task "- 更新 sources.list" "sed -i 's/${curr_codenm}/${targ_codenm}/g' /etc/apt/sources.list" || { Err "更新 sources.list 失敗" || return 1; }
			Task "- 更新套件清單" "DEBIAN_FRONTEND=noninteractive apt-get update -y" || { Err "更新新版本的套件清單失敗" || return 1; }
			DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y || { Err "升級到新的 DEBIAN 版本失敗" || return 1; }
			;;
		ubuntu)
			Txt "- 偵測到 UBUNTU 系統"
			Task "- 正在更新套件清單" "DEBIAN_FRONTEND=noninteractive apt-get update -y" || { Err "使用 APT 更新套件清單失敗" || return 1; }
			Task "- 正在升級目前的套件" "DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y" || { Err "升級目前的套件失敗" || return 1; }
			Task "- 安裝 update-manager-core" "DEBIAN_FRONTEND=noninteractive apt-get install -y update-manager-core" || { Err "安裝 update-manager-core 失敗" || return 1; }
			do-release-upgrade -f DistUpgradeViewNonInteractive || { Err "升級 UBUNTU 版本失敗" || return 1; }
			SysRboot
			;;
		*) Err "您的系統尚不支援主要版本升級" || return 1 ;;
	esac
	DLine && Finish
}
function Task() {
	.Flag
	local -r command_str="$2" ignore_error="${3:-false}"
	local ret tmp_file

	tmp_file=$(mktemp) || { Err "無法建立臨時檔案" || return 1; }

	trap 'rm -f "${tmp_file}"' RETURN

	Raw "$1... "

	if eval "${command_str}" >"${tmp_file}" 2>&1; then
		Finish
		ret=0
	else
		ret=$?
		Txt "${CLR[1]}失敗${CLR[0]} (${ret})"
		[[ -s "${tmp_file}" ]] && Txt "${CLR[1]}$(cat "${tmp_file}")${CLR[0]}"
		[[ ${ignore_error} == true ]] || return "${ret}"
	fi
	return "${ret}"
}
function sys::timezone() {
	.Flag

	Cmdd "curl" || { Err "缺失必要套件" || return 1; }
	local -r tz_regex="^[A-Za-z0-9_-]+/[A-Za-z0-9_-]+$|^[A-Z]{3,4}$|^Etc/GMT[+-]?[0-9]+$"
	local data
	_detect_external() {
		(
			timeout 1.5s curl -sL "https://ipapi.co/json" | GetValue "timezone" ||
				timeout 1.5s wget -qO- "http://ip-api.com" | grep -oP '"timezone":"\K[^"]+'
		) 2>/dev/null | grep -oE "${tz_regex}"
	}
	_detect_internal() {
		(
			readlink /etc/localtime | sed "s|^.*/zoneinfo/||" ||
				{ Cmdd timedatectl && timedatectl status | awk '/Time zone:/ {print $3}'; } ||
				grep -v "^#" /etc/timezone | tr -d " "
		) 2>/dev/null | grep -oE "${tz_regex}"
	}

	case "$1" in
		-e | --external)
			wget -qO- "http://ip-api.com" | Trim '"timezone"     : "' '",'
			data=$(_detect_external)

			data=$(curl -sL "https://ipapi.co/json" | GetValue "timezone")
			Txt "${data}" || { Err "從外部服務偵測時區失敗" || return 1; }
			;;
		-i | --internal)
			data=$(_detect_internal)
			Txt "${data}" || { Err "偵測系統時區失敗" || return 1; }
			;;
	esac
}
function Press() { read -p "$1" -n 1 -r || { Err "讀取使用者輸入失敗" || return 1; }; }

function HelpMsg() {
	local app_name current_section max_len cmds cmd_descs opts opt_descs
	max_len=0
	cmds=() cmd_descs=()
	opts=() opt_descs=()
	local item desc i

	if [[ "${1:-}" == "-n" ]]; then
		app_name="${2:-}"
		shift 2
	fi

	# 內部寬度計算函式：強制使用 UTF-8 環境，精準計算終端機寬度
	get_str_width() {
		printf "%s" "$1" | LANG=C.UTF-8 wc -L
	}

	while (($# > 0)); do
		case "$1" in
			-c | --cmd)
				current_section="CMD"
				shift
				;;
			-o | --opt)
				current_section="OPT"
				shift
				;;
			*)
				item="$1"

				if [[ -n "${2:-}" && "$2" != -* ]]; then
					desc="$2"
					shift 2
				else
					desc=""
					shift 1
				fi

				local -r item_width="$(get_str_width "${item}")"

				if [[ "${current_section}" == "CMD" ]]; then
					cmds+=("${item}")
					cmd_descs+=("${desc}")
					((item_width > max_len)) && max_len=${item_width}
				elif [[ "${current_section}" == "OPT" ]]; then
					opts+=("${item}")
					opt_descs+=("${desc}")
					((item_width > max_len)) && max_len=${item_width}
				fi
				;;
		esac
	done

	Txt "Usage: ${app_name:-\$0} [OPTIONS] COMMAND"
	Raw "\n"

	local -r total_width=$((max_len + 4))

	print_aligned_line() {
		local -r target="$1" description="$2"
		local -r w=$(get_str_width "${target}")
		local -r spaces=$((total_width - w))

		local pad

		if ((spaces > 0)); then
			printf -v pad "%*s" "${spaces}" ""
		fi

		printf "    %s%s%s\n" "${target}" "${pad}" "${description}"
	}

	if ((${#cmds[@]} > 0)); then
		Txt "Commands:"
		for ((i = 0; i < ${#cmds[@]}; i++)); do
			print_aligned_line "${cmds[i]}" "${cmd_descs[i]}"
		done
		Raw "\n"
	fi

	if ((${#opts[@]} > 0)); then
		Txt "Options:"
		for ((i = 0; i < ${#opts[@]}; i++)); do
			print_aligned_line "${opts[i]}" "${opt_descs[i]}"
		done
	fi
}
