#!/usr/bin/env bash
# VERSION="8.0.0a7"

# set -Eeuo pipefail
# set +u
set -o pipefail
shopt -s expand_aliases

declare _
declare BASH=0 PKG_MGR="unknown" LANG="" UNIT_PREF="IB"

declare CLR=(
	"\x1b[0m"    # [0] 重置
	"\x1b[0;31m" # [1] 紅
	"\x1b[0;32m" # [2] 綠
	"\x1b[0;33m" # [3] 黃
	"\x1b[0;34m" # [4] 藍
	"\x1b[0;35m" # [5] 紫
	"\x1b[0;36m" # [6] 青
	"\x1b[0;37m" # [7] 白
	"\x1b[0;96m" # [8] 高亮青
	"\x1b[0;97m" # [9] 高亮白
)

((BASH == 0)) && printf "%b\n" "${CLR[1]}Unsupported Bash version!${CLR[0]}" && return 1
[[ ${PKG_MGR} == "unknown" ]] && printf "%b\n" "${CLR[1]}Unknown package manager!${CLR[0]}" && return 1

alias .Flag='(($# == 0)) && return 2'
alias .Root='((EUID != 0 || $(id -u) != 0)) && return 1'
alias .Root.Flag='(($# == 0)) && return 2; ((EUID != 0 || $(id -u) != 0)) && return 1'

# ----------------------------------------------------------------------
#  Namespace: _
# ----------------------------------------------------------------------
function curl() { false; }
function eval() { false; }
function grep() { false; }
function wget() { false; }

# ----------------------------------------------------------------------
#  Namespace: url
# ----------------------------------------------------------------------
function url::get() {
	command wget \
		--timeout=15 \
		--tries=3 \
		--waitretry=5 \
		--retry-on-http-error=429,500,502,503,504 \
		--max-redirect=5 \
		"$@"
}

# ----------------------------------------------------------------------
#  Namespace: dir
# ----------------------------------------------------------------------
function dir::exist() {
	.Flag
	local d
	for d in "$@"; do [[ -d "$d" ]] || return 1; done
}

# ----------------------------------------------------------------------
#  Namespace: file
# ----------------------------------------------------------------------
function file::exist() {
	.Flag
	local f
	for f in "$@"; do [[ -f "$f" ]] || return 1; done
}
function file::valid() {
	.Flag
	local f
	for f in "$@"; do [[ -s "$f" ]] || return 1; done
}
function file::grep() {
	(($# < 2)) && return 2
	command -v grep &>/dev/null || return 126
	local -r file="${!#}"
	[[ ! (-f ${file} && -r ${file} && -s ${file}) ]] && return 2
	command grep "$@"
}

# ----------------------------------------------------------------------
#  Namespace: path
# ----------------------------------------------------------------------
function path::exist() {
	.Flag
	local p
	for p in "$@"; do [[ -e "$p" || -L "$p" ]] || return 1; done
}

# ----------------------------------------------------------------------
#  Namespace: perm
# ----------------------------------------------------------------------
function perm::read() {
	.Flag
	local p
	for p in "$@"; do [[ -r "$p" ]] || return 1; done
}
function perm::write() {
	.Flag
	local p
	for p in "$@"; do [[ -w "$p" ]] || return 1; done
}
function perm::exec() {
	.Flag
	local p
	for p in "$@"; do [[ -x "$p" ]] || return 1; done
}

# ----------------------------------------------------------------------
#  Namespace: pkg
# ----------------------------------------------------------------------
function pkg::apt() {
	.Flag
	DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=180 -y "$@"
}
function pkg::count() {
	case "${PKG_MGR^^}" in
		APK) apk info | wc -l ;;
		APT) dpkg -l | str::grep -c "^ii" ;;
		DNF) rpm -qa | wc -l ;;
		OPKG) opkg list-installed | wc -l ;;
		PACMAN) pacman -Qq | wc -l ;;
		YUM) rpm -qa | wc -l ;;
		ZYPPER) rpm -qa | wc -l ;;
		*) return 127 ;;
	esac
}
function pkg::is_installed() {
	.Flag

	case "${PKG_MGR^^}" in
		APK) apk info -e "${1,,}" &>/dev/null ;;
		APT) dpkg -s "${1,,}" &>/dev/null ;;
		DNF) rpm -q "${1,,}" &>/dev/null ;;
		OPKG) opkg status "${1,,}" 2>/dev/null | str::grep -q "Status:.*installed" ;;
		PACMAN) pacman -Qq "${1,,}" &>/dev/null ;;
		YUM) rpm -q "${1,,}" &>/dev/null ;;
		ZYPPER) rpm -q "${1,,}" &>/dev/null ;;
		*) return 127 ;;
	esac
}
function pkg::install() {
	.Flag

	case "${PKG_MGR^^}" in
		APK) apk add "${1,,}" ;;
		APT) pkg::apt install "${1,,}" ;;
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
		APT) pkg::apt purge "${1,,}" && pkg::apt autoremove ;;
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
		APT) pkg::apt update ;;
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
			APT) pkg::apt full-upgrade ;;
			DNF) dnf upgrade -y ;;
			OPKG) : ;;
			PACMAN) pacman -Syu --noconfirm ;;
			YUM) yum upgrade -y ;;
			ZYPPER) zypper dup -y --no-allow-vendor-change ;;
			*) return 127 ;;
		esac
	fi
}

# ----------------------------------------------------------------------
#  Namespace: str
# ----------------------------------------------------------------------
function str::grep() { command grep "$@"; }
function str::trim() {
	.Flag

	local stdin_buffer
	stdin_buffer=$(cat)
	[[ -n ${1:-} ]] && stdin_buffer="${stdin_buffer#*"$1"}"
	[[ -n ${2:-} ]] && stdin_buffer="${stdin_buffer%%"$2"*}"

	printf "%b\n" "${stdin_buffer}"
}

# ----------------------------------------------------------------------
#  Namespace: var
# ----------------------------------------------------------------------
function var::empty() {
	.Flag
	local v
	for v in "$@"; do [[ -z "$v" ]] || return 1; done
}
function var::set() {
	.Flag
	local v
	for v in "$@"; do [[ -v "$v" ]] || return 1; done
}
function var::valid() {
	.Flag
	local v
	for v in "$@"; do [[ -n "$v" ]] || return 1; done
}

function Err() { var::valid "$@" && printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2; }
function ErrR() { var::valid "$@" && printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2 && return 1; }
function Raw() { printf "%b" "$*"; }
function Txt() { var::valid "$@" && printf "%b\n" "$*"; }

function DLine() { Txt "${1:-${CLR[8]}}========================${CLR[0]}"; }
function SLine() { Txt "${1:-${CLR[8]}}--------------------------------${CLR[0]}"; }
function Finish() { Txt "${CLR[2]}完成${CLR[0]}"; }

function Extract() {
	local has_modifiers=0

	if (($# > 0)) && [[ $1 =~ ^([_<>^][0-9]*)([_<>^][0-9]*)?$ ]]; then
		has_modifiers=1
		shift
	fi

	local part1 part2

	if ((has_modifiers == 1)); then
		part1="${BASH_REMATCH[1]}"
		part2="${BASH_REMATCH[2]}"
	else
		part1="_"
		part2=">"
	fi

	local sym1="${part1:0:1}" num1="${part1:1}"
	local sym2 num2

	if [[ -n ${part2} ]]; then
		sym2="${part2:0:1}"
		num2="${part2:1}"
	else
		if [[ ${sym1} == @(^|_) ]]; then
			sym2=">"
			num2=""
		else
			sym2="_"
			num2=""
		fi
	fi

	local -i row_num=1 col_num=1
	local -r mod_num1="${num1:-1}" mod_num2="${num2:-1}"
	local raw_col_args=()
	local col_sym delim row_arg row_sym

	if [[ ${sym1} == @(^|_) ]]; then
		row_sym="${sym1}"
		row_num="${mod_num1}"
		row_arg="${1:-1}"

		col_sym="${sym2}"
		col_num="${mod_num2}"

		local -a remaining_args=("${@:2}")
		local -i rem_count="${#remaining_args[@]}"

		if ((rem_count == 0)); then
			raw_col_args=(1)
		elif ((rem_count == 1)); then
			raw_col_args=("${remaining_args[0]}")
		else
			local last_arg="${remaining_args[rem_count - 1]}"
			if ((${#last_arg} == 1)) && [[ ! ${last_arg} =~ ^[0-9]$ ]]; then
				delim="${last_arg}"
				raw_col_args=("${remaining_args[@]:0:rem_count-1}")
			else
				raw_col_args=("${remaining_args[@]}")
			fi
		fi
	else
		col_sym="${sym1}"
		col_num="${mod_num1}"

		row_sym="${sym2}"
		row_num="${mod_num2}"

		row_arg="${*: -1}"
		row_arg="${row_arg:-1}"

		local -i rem_count=$#
		if ((rem_count <= 1)); then
			raw_col_args=(1)
		else
			local -i rem_cols_count="${#remaining_args[@]}"
			local remaining_args=("${@:1:rem_count-1}")

			local last_arg="${remaining_args[rem_cols_count - 1]}"
			if ((${#last_arg} == 1 && rem_cols_count > 1)) && [[ ! "${last_arg}" =~ ^[0-9]$ ]]; then
				delim="${last_arg}"
				raw_col_args=("${remaining_args[@]:0:rem_cols_count-1}")
			else
				raw_col_args=("${remaining_args[@]}")
			fi
		fi
	fi

	local mapfile_lines=()
	mapfile -t mapfile_lines
	local -i total_lines=${#mapfile_lines[@]}
	((total_lines == 0)) && return 1

	local selected_line

	if [[ ${row_arg} =~ ^[0-9]+$ ]]; then
		local -i target_idx=-1
		if [[ ${row_sym} == "^" ]]; then
			target_idx=$((total_lines - row_arg))
		else
			target_idx=$((row_arg - 1))
		fi

		((target_idx < 0 || target_idx >= total_lines)) && return 1
		selected_line="${mapfile_lines[target_idx]}"
	else
		local -i found_idx=-1 idx=0 match_count=0

		if [[ ${row_sym} == "_" ]]; then
			for ((idx = 0; idx < total_lines; idx++)); do
				if [[ ${mapfile_lines[idx]} == *"${row_arg}"* ]]; then
					((match_count++))
					((match_count == row_num)) && found_idx=idx && break
				fi
			done
		else
			for ((idx = total_lines - 1; idx >= 0; idx--)); do
				if [[ ${mapfile_lines[idx]} == *"${row_arg}"* ]]; then
					((match_count++))
					((match_count == row_num)) && found_idx=idx && break
				fi
			done
		fi

		((found_idx == -1)) && return 1
		selected_line="${mapfile_lines[found_idx]}"
	fi

	local mapfile_cols=()
	if var::empty "${delim}"; then
		read -r -a mapfile_cols <<<"${selected_line}"
	else
		local -r old_ifs="${IFS}"
		IFS="${delim}"
		read -r -a mapfile_cols <<<"${selected_line}"
		IFS="${old_ifs}"

		local -r temp_cols=("${mapfile_cols[@]}")
		mapfile_cols=()

		local item
		for item in "${temp_cols[@]}"; do
			item="$(echo "${item}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
			var::valid "${item}" && mapfile_cols+=("${item}")
		done
	fi

	local -i total_cols="${#mapfile_cols[@]}"
	((total_cols == 0)) && return 1

	local output_cols=()

	local col_arg
	for col_arg in "${raw_col_args[@]}"; do
		if [[ ${col_arg} =~ ^[0-9]+$ ]]; then
			local -i target_idx=-1
			if [[ ${col_sym} == "<" ]]; then
				target_idx=$((total_cols - col_arg))
			else
				target_idx=$((col_arg - 1))
			fi

			((target_idx < 0 || target_idx >= total_cols)) && return 1
			output_cols+=("${mapfile_cols[target_idx]}")
		else
			local -i found_idx=-1 idx=0 match_count=0

			if [[ ${col_sym} == ">" ]]; then
				for ((idx = 0; idx < total_cols; idx++)); do
					if [[ ${mapfile_cols[idx]} == *"${col_arg}"* ]]; then
						((match_count++))
						((match_count == col_num)) && found_idx=idx && break
					fi
				done
			else
				for ((idx = total_cols - 1; idx >= 0; idx--)); do
					if [[ ${mapfile_cols[idx]} == *"${col_arg}"* ]]; then
						((match_count++))
						((match_count == col_num)) && found_idx=idx && break
					fi
				done
			fi

			((found_idx == -1)) && return 1
			output_cols+=("${mapfile_cols[found_idx]}")
		fi
	done

	Txt "${output_cols[*]}"
}
function GetValue() {
	local -r key="$1" data_source="${2:-}"
	local -r pattern="(^|[[:space:],'{ \"])(\"${key}\"|'${key}'|\<${key}\>)[[:space:]]*[:=][[:space:]]*(\"([^\"]*)\"|'([^']*)'|([^,#]*[^[:space:],#]))"

	function _parse() {
		local -r target_pattern="$1"
		local line

		while read -r line; do
			if [[ ${line} =~ ${target_pattern} ]]; then
				printf "%s\n" "${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
				return 0
			fi
		done
		return 1
	}

	if var::empty "${data_source}"; then
		_parse "${pattern}"
	elif file::exist "${data_source}"; then
		_parse "${pattern}" <"${data_source}"
	else
		_parse "${pattern}" <<<"${data_source}"
	fi
}

function AddFile() {
	.Flag
	local item parent_dir

	for item in "$@"; do
		Txt "${CLR[3]}新增檔案 '${item}'${CLR[0]}"
		path::exist "${item}" && Err "檔案或目錄 '${item}' 已存在" && return 1
		parent_dir="${item%/*}"

		if [[ ${parent_dir} != "${item}" ]] && ! dir::exist "${parent_dir}"; then
			if ! mkdir -p "${parent_dir}"; then
				Err "無法建立父目錄 '${parent_dir}'。請檢查權限" && return 1
			fi
		fi

		if : >"${item}"; then
			Txt "- 檔案 '${item}' 建立成功"
		else
			Err "建立檔案 '${item}' 失敗。請檢查權限和磁碟空間" && return 1
		fi
	done
	Finish
}
function AddDir() {
	.Flag
	local item

	for item in "$@"; do
		Txt "${CLR[3]}新增目錄 '${item}'${CLR[0]}"

		path::exist "${item}" && Err "檔案或目錄 '${item}' 已存在" && return 1

		if mkdir -p "${item}"; then
			Txt "- 目錄 '${item}' 建立成功"
		else
			Err "建立目錄 '${item}' 失敗。請檢查權限和路徑有效性" && return 1
		fi
	done
	Finish
}
function AddPkg() {
	.Root.Flag
	local pkg

	for pkg in "$@"; do
		Txt "${CLR[3]}安裝套件 '${pkg}'${CLR[0]}"

		if pkg::is_installed "${pkg}"; then
			Txt "- 套件 ${pkg} 已經安裝"
		else
			if pkg::install "${item}"; then
				Txt "- 套件 ${pkg} 安裝成功"
			else
				Err "使用 ${PKG_MGR} 安裝 ${pkg} 失敗" && return 1
			fi
		fi
	done
	Finish
}
function ChkDeps() {
	local -i mode=0
	local missg_deps=() target_deps=()
	local cont_inst dep msg

	while (($# > 0)); do
		case "$1" in
			-a | --automatic) mode=1 ;;
			-i | --interactive) mode=2 ;;
			-*) Err "無效的選項：$1" && return 1 ;;
			*) target_deps+=("$1") ;;
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
			read -p "是否要安裝缺少的套件？(y/N) " -nr 1 cont_inst
			Raw "\n"
			[[ ${cont_inst} =~ ^[Yy]$ ]] && AddPkg "${missg_deps[@]}"
			;;
	esac
}
function sys::distro() {
	case "$1" in
		-v | --version)
			if file::exist /etc/os-release; then
				local -r os_id="$(GetValue "ID" </etc/os-release)"
				case "${os_id^^}" in
					DEBIAN) cat /etc/debian_version ;;
					FEDORA) file::grep -oE '[0-9]+' /etc/fedora-release ;;
					CENTOS) file::grep -oE '[0-9]+\.[0-9]+' /etc/centos-release ;;
					ALPINE) cat /etc/alpine-release ;;
					*) Txt "${VERSION_ID}" ;;
				esac
			elif file::exist /etc/debian_version; then
				cat /etc/debian_version
			elif file::exist /etc/fedora-release; then
				file::grep -oE '[0-9]+' /etc/fedora-release
			elif file::exist /etc/centos-release; then
				file::grep -oE '[0-9]+\.[0-9]+' /etc/centos-release
			elif file::exist /etc/alpine-release; then
				cat /etc/alpine-release
			else
				Err "Unknown" && return 1
			fi
			;;
		-n | --name)
			if file::exist /etc/os-release; then
				GetValue "NAME" </etc/os-release
			elif file::exist /etc/DISTRO_SPECS; then
				GetValue "DISTRO_NAME" </etc/DISTRO_SPECS
			else
				Err "Unknown" && return 1
			fi
			;;
		*) str::trim "" "\n" </etc/issue ;;
	esac
}
function sys::virt() {
	if command -v systemd-detect-virt &>/dev/null; then
		local -r virt_typ="$(systemd-detect-virt 2>/dev/null)"

		var::empty "${virt_typ}" && Err "無法偵測虛擬化環境" && return 1

		case "${virt_typ^^}" in
			KVM)
				if [[ $(cat /sys/class/dmi/id/product_name 2>/dev/null) == *[Pp]roxmox* ]]; then
					Txt "Proxmox VE (KVM)"
				else
					Txt "KVM"
				fi
				;;
			MICROSOFT) Txt "Microsoft Hyper-V" ;;
			WSL) Txt "適用於 Linux 的 Windows 子系統" ;;
			NONE)
				if file::grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
					Txt "LXC 容器"
				elif file::grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
					Txt "虛擬機器（未知類型）"
				else
					Txt "未偵測到（可能為實體機器）"
				fi
				;;
			*) Txt "${virt_typ}" ;;
		esac
	elif file::exist /proc/cpuinfo; then
		if file::grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
			Txt "虛擬機器（未知類型）"
		else
			Txt "未偵測到（可能為實體機器）"
		fi
	else
		Txt "未知環境"
	fi
}
function Clear() {
	cd "${1:-${HOME}}" || ErrR "切換目錄失敗" || return 1
	clear
}
function cpu::cache() {
	file::exist /proc/cpuinfo || ErrR "無法存取 CPU 資訊。" || return 1
	local -r cpu_cache="$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)"
	[[ ${cpu_cache} == "N/A" ]] && Err "無法確定 CPU 快取大小" && return 1
	Txt "${cpu_cache} KB"
}
function cpu::freq() {
	file::exist /proc/cpuinfo || ErrR "無法存取 CPU 資訊。" || return 1
	local -r cpu_freq="$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)"
	[[ ${cpu_freq} == "N/A" ]] && Err "無法確定 CPU 頻率" && return 1
	Txt "${cpu_freq} GHz"
}
function cpu::model() {
	GetValue "Model name" < <(lscpu) && return 0
	GetValue "model name" </proc/cpuinfo && return 0
	sysctl -n machdep.cpu.brand_string 2>/dev/null && return 0

	Err "${CLR[1]}未知${CLR[0]}" && return 1
}
function cpu::usage() {
	local -i usr nice sys idle iowait irq softirq steal guest guest_nice

	if read -r _ usr nice sys idle iowait irq softirq steal guest guest_nice <<<"$(Extract cpu {1..11} </proc/stat)"; then
		var::empty "${idle}" && Err "從 /proc/stat 讀取第一階段 CPU 統計失敗" && return 1
	fi
	local -ir prev_total=$((usr + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice)) prev_idle=idle

	sleep 0.3

	if read -r _ usr nice sys idle iowait irq softirq steal guest guest_nice <<<"$(Extract cpu {1..11} </proc/stat)"; then
		var::empty "${idle}" && Err "從 /proc/stat 讀取第二階段 CPU 統計失敗" && return 1
	fi
	local -ir curr_total=$((usr + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice)) curr_idle=idle
	local -ir tot_delta=$((curr_total - prev_total)) idle_delta=$((curr_idle - prev_idle))

	((tot_delta == 0)) && Txt "0"
	Txt $((100 * (tot_delta - idle_delta) / tot_delta))
}
function ConvSz() {
	.Flag
	# TODO: change these variables
	local size="$1" default_pref="${UNIT_PREF:-b}" && local unit="${2:-${default_pref}}"

	((size < 0)) && Err "大小值不能為負數：${size}" && return 1

	local -r LC_ALL=C
	awk -v size="${size}" -v unit="${unit,,}" '
        function ToBytes(val, u) {
			if (u == "b" || u == "ib")      return val;
			if (u == "kb")			      return val * 1000;
			if (u == "mb")			      return val * 1000^2;
			if (u == "gb")			      return val * 1000^3;
			if (u == "tb")			      return val * 1000^4;
			if (u == "pb")			      return val * 1000^5;
			if (u == "kib")			     return val * 1024;
			if (u == "mib")			     return val * 1024^2;
			if (u == "gib")			     return val * 1024^3;
			if (u == "tib")			     return val * 1024^4;
			if (u == "pib")			     return val * 1024^5;
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
			    else			        printf "%.3f %s", value, units_arr[power + 1];
			}
        }
    ' || ErrR "不支持的單位或格式錯誤：size=${size} unit=${unit,,}" || return 1
}
function DelFile() {
	.Flag

	local item
	for item in "$@"; do
		Txt "${CLR[3]}刪除檔案 '${item}'${CLR[0]}"
		if file::exist "${item}"; then
			if rm -f "${item}"; then
				Txt "- 檔案 '${item}' 刪除成功"
			else
				Err "刪除檔案 ${item} 失敗。請檢查權限" && return 1
			fi
		else
			Err "- 檔案 '${item}' 不存在\n" && return 1
		fi
	done
	Finish
}
function DelDir() {
	.Flag

	local item
	for item in "$@"; do
		Txt "${CLR[3]}刪除目錄 '${item}'${CLR[0]}"
		if dir::exist "${item}"; then
			if rm -rf "${item}"; then
				Txt "- 目錄 '${item}' 刪除成功"
			else
				Err "刪除目錄 '${item}' 失敗。請檢查權限\n" && return 1
			fi
		else
			Err "目錄 '${item}' 不存在\n" && return 1
		fi
		Finish
	done
}
function DelPkg() {
	.Root.Flag
	local pkg

	for pkg in "$@"; do
		Txt "${CLR[3]}移除套件 '${pkg}'${CLR[0]}"

		if pkg::is_installed "${pkg}"; then
			if pkg::remove "${pkg}"; then
				Txt "- 套件 ${pkg} 移除成功"
			else
				Err "使用 ${PKG_MGR} 移除 ${pkg} 失敗" && return 1
			fi
		else
			Txt "- 套件 ${pkg} 不存在"
		fi
	done
	Finish
}
function disk::info() {
	local -r pct=$(df -B1 / | awk '/^\/dev/ {printf("%.2f"), $3/($3+$4)*100}')
	local -r tot=$(Extract 2 2 < <(df -B1 /))
	local -r usd=$(Extract 2 3 < <(df -B1 /))
	case "${1:-}" in
		-p | --percentage) Txt "${pct}" ;;
		-t | --total) Txt "${tot}" ;;
		-u | --used) Txt "${usd}" ;;
		*) Txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function net::dns() {
	file::exist /etc/resolv.conf && Err "找不到 DNS 設定檔" && return 1
	local dns4=() dns6=()

	while read -r servers; do
		[[ ${servers} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && dns4+=("${servers}")
		[[ ${servers} =~ ^[0-9a-fA-F:]+$ ]] && dns6+=("${servers}")
	done < <(file::grep -E '^nameserver' /etc/resolv.conf | Extract 1 2)

	((${#dns4[@]} == 0 && ${#dns6[@]} == 0)) && Err "/etc/resolv.conf 中未設定 DNS 伺服器" && return 1
	case "${1:-}" in
		-4 | --ipv4)
			((${#dns4[@]} == 0)) && Err "找不到 IPv4 DNS 伺服器" && return 1
			Txt "${dns4[*]}"
			;;
		-6 | --ipv6)
			((${#dns6[@]} == 0)) && Err "找不到 IPv6 DNS 伺服器" && return 1
			Txt "${dns6[*]}"
			;;
		*)
			((${#dns4[@]} == 0 && ${#dns6[@]} == 0)) && Err "找不到 DNS 伺服器" && return 1
			Txt "${dns4[*]}   ${dns6[*]}"
			;;
	esac
}
function file::download() {
	local -i unzip=0
	local targ_dir="." rnm_file url oup_file oup_path
	while (($# > 0)); do
		case "$1" in
			-x | --unzip) unzip=1 && shift ;;
			-r | --rename)
				[[ -z $1 || $1 == -* ]] && Err "-r 選項後未指定檔案名稱" && return 1
				rnm_file="$1"
				shift 2
				;;
			-*) Err "無效的選項：$1" && return 1 ;;
			*)
				if var::empty "${url}"; then
					url="$1" || targ_dir="$1"
				fi
				shift
				;;
		esac
	done

	var::empty "${url}" && Err "未指定 URL。請提供要下載的 URL" && return 1
	[[ ${url} =~ ^(http|https|ftp):// ]] || url="https://${url}"
	oup_file="${url##*/}"
	var::empty "${oup_file}" && oup_file="index.html"
	if [[ ${targ_dir} != "." ]]; then
		mkdir -p "${targ_dir}"
	else
		Err "建立目錄 ${targ_dir} 失敗" && return 1
	fi
	var::valid "${rnm_file}" && oup_file="${rnm_file}"
	oup_path="${targ_dir}/${oup_file}"
	url=$(Txt "${url}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	Txt "${CLR[3]}下載 '${url}'${CLR[0]}"

	url::get -c "${url}" -O "${oup_path}" || ErrR "下載檔案失敗" || return 1

	if file::exist "${oup_path}"; then
		Txt "- 檔案成功下載至 ${oup_path}"
		if ((unzip == 1)); then
			if case "${oup_file}" in
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
				Err "解壓縮失敗！" && return 1
			fi
		fi
	else
		Err "下載失敗。請檢查網路連線和 URL 有效性" && return 1
	fi
	Finish
}
function net::iface() {
	local all_interfaces default4_route default6_route interface interfaces=() interfaces_num items=()
	local i item interface4 interface6 physical_iface iface stats
	local rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop

	all_interfaces=$(
		cat /proc/net/dev |
			str::grep ':' |
			cut -d':' -f1 |
			sed 's/\s//g' |
			str::grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker\|^br-\|^veth' |
			sort -n
	) || ErrR "從 /proc/net/dev 取得網路介面失敗" || return 1

	mapfile -t items <<<"${all_interfaces}"
	interfaces=([0]="placeholder")
	for item in "${items[@]}"; do
		var::valid "${item}" && interfaces+=("${item}")
	done
	unset 'interfaces[0]'
	interfaces_num=${#interfaces[@]}

	default4_route=$(ip -4 route show default 2>/dev/null || Raw "")
	default6_route=$(ip -6 route show default 2>/dev/null || Raw "")

	for ((i = 1; i <= ${#interfaces[@]}; i++)); do
		item="${interfaces[i]}"
		var::empty "${item}" && continue

		if var::valid "${default4_route}" && var::empty "${interface4}"; then
			Txt "${default4_route}" | str::grep -qE "\bdev ${item}\b"
			interface4="${item}"
		fi
		if var::valid "${default6_route}" && var::empty "${interface6}"; then
			Txt "${default6_route}" | str::grep -qE "\bdev ${item}\b"
			interface6="${item}"
		fi
		var::valid "${interface4}" "${interface6}" && break
	done

	if var::empty "${interface4}${interface6}"; then
		for ((i = 1; i <= ${#interfaces[@]}; i++)); do
			item="${interfaces[i]}"
			if [[ ${item} =~ ^en ]]; then
				interface4="${item}"
				interface6="${item}"
				break
			fi
		done
		if ((interfaces_num == 0)); then
			interface4="${interfaces[1]}"
			interface6="${interfaces[1]}"
		fi
	fi

	if var::valid "${interface4}" || var::valid "${interface6}"; then
		interface="${interface4} ${interface6}"
		[[ ${interface4} == "${interface6}" ]] && interface="${interface4}"
		interface=$(Txt "${interface}" | tr -s ' ' | xargs)
	else
		physical_iface=$(ip -o link show | str::grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | str::grep 'state UP' | head -n 1 | Extract 1 2 ":")
		if var::valid "${physical_iface}"; then
			interface="${physical_iface}"
		else
			interface=$(ip -o link show | str::grep -v 'lo:' | head -n 1 | Extract 1 2 ":")
		fi
	fi

	case "$1" in
		--rx_bytes | --rx_packets | --rx_drop | --tx_bytes | --tx_packets | --tx_drop)
			for iface in ${interface}; do
				while read -r line; do
					if [[ ${line} =~ ^[[:space:]]*"${iface}": ]]; then
						read -r -a arr <<<"${line}"
						stats="${arr[1]} ${arr[2]} ${arr[4]} ${arr[9]} ${arr[10]} ${arr[12]}"
						break
					fi
				done </proc/net/dev 2>/dev/null
				if var::valid "${stats}"; then
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
					if [[ ${line} =~ ^[[:space:]]*"${iface}": ]]; then
						read -r -a arr <<<"${line}"
						stats="${arr[1]} ${arr[2]} ${arr[4]} ${arr[9]} ${arr[10]} ${arr[12]}"
						break
					fi
				done </proc/net/dev 2>/dev/null
				if var::valid "${stats}"; then
					read -r rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"${stats}"
					Txt "${iface}: RX: $(ConvSz "${rx_bytes}"), TX: $(ConvSz "${tx_bytes}")"
				fi
			done
			;;
		*) Txt "${interface}" ;;
	esac
}
function net::ip() {
	local -r apis=("api64.ipify.org" "ifconfig.me" "ipinfo.io") ip4_regex="(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}"
	local -r ip6_regex="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}{1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}{1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}{1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}{1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}{1,6}|:((:[0-9a-fA-F]{1,4}{1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}{0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}{0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"
	local ip4_addr ip6_addr
	case "$1" in
		-4 | --ipv4)
			for api in "${apis[@]}"; do
				ip4_addr=$(url::get -qO- -4 "${api}" 2>/dev/null)
				break
			done

			ip4_addr=$(str::grep -oE "${ip4_regex}" <<<"${ip4_addr}")
			Txt "${ip4_addr:-N/A}"
			;;
		-6 | --ipv6)
			for api in "${apis[@]}"; do
				ip6_addr=$(url::get -qO- -6 "${api}" 2>/dev/null)
				break
			done
			ip6_addr=$(str::grep -oE "${ip6_regex}" <<<"${ip6_addr}")
			Txt "${ip6_addr:-N/A}"
			;;
		-p | --public) GetValue "ip" < <(url::get -qO- "https://developers.cloudflare.com/cdn-cgi/trace") ;;
		*)
			for api in "${apis[@]}"; do
				ip4_addr=$(url::get -qO- -4 "${api}" 2>/dev/null)
				break
			done
			ip4_addr=$(str::grep -oE "${ip4_regex}" <<<"${ip4_addr}")

			for api in "${apis[@]}"; do
				ip6_addr=$(url::get -qO- -6 "${api}" 2>/dev/null)
				break
			done
			ip6_addr=$(str::grep -oE "${ip6_regex}" <<<"${ip6_addr}")

			var::empty "${ip4_addr}${ip6_addr}" && Err "取得 IP 位址失敗" && return 1
			Raw "IPv4: " && Txt "${ip4_addr:-N/A}"
			Raw "IPv6: " && Txt "${ip6_addr:-N/A}"
			;;
	esac
}
function pkg::last_update() {
	Extract ^ End-Date {2,3} </var/log/apt/history.log && return 0
	Extract ^ 1 {1,2} </var/log/dpkg.log && return 0
	rpm -qa --last | head -n 1 | Extract 1 {3..7} && return 0

	Err "取得最後更新時間失敗" && return 1
}
function sys::load() {
	local -r LC_ALL=C
	local zo_mi zv_mi ov_mi

	read -r zo_mi zv_mi ov_mi _ _ </proc/loadavg 2>/dev/null && Txt "${zo_mi}, ${zv_mi}, ${ov_mi}" && return 0
	Txt "$(Extract 1 5 ":" < <(uptime)) ($(nproc) Cores)" && return 0

	Err "缺失取得方法" && return 1
}
function sys::location() {
	case "$1" in
		-c | --city) data=$(url::get -qO- "https://ipinfo.io/city") ;;
		-C | --country | *) data=$(url::get -qO- "https://ipinfo.io/country") ;;
	esac

	Txt "${data:-N/A}"
}
function net::mac() {
	if ! Extract link/ether 2 < <(ip link show); then
		Err "無法取得 MAC 位址。找不到網路介面" && return 1
	fi
}
function mem::info() {
	local -r pct=$(free --bytes | awk '/^Mem:/ {printf("%.2f"), $3/$2*100}')
	local -r tot=$(Extract Mem 2 < <(free --bytes))
	local -r usd=$(Extract Mem 3 < <(free --bytes))
	case "${1:-}" in
		-p | --percentage) Txt "${pct}" ;;
		-t | --total) Txt "${tot}" ;;
		-u | --used) Txt "${usd}" ;;
		*) Txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function net::provider() {
	url::get -qO- "https://ipinfo.io" | GetValue "org" && return 0
	url::get -qO- "https://ipwhois.app/json" | str::trim '"org":"' '",' && return 0
	url::get -qO- "http://ip-api.com/json" | str::trim '"org":"' '",' && return 0

	Err "無法偵測網路供應商。請檢查網路連線" && return 1
}

function sys::shell_version() {
	# TODO: refactor this
	local -r LC_ALL=C

	var::valid "${BASH_VERSION:-}" && Txt "Bash ${BASH_VERSION}" && return 0
	var::valid "${ZSH_VERSION:-}" && Txt "Zsh ${ZSH_VERSION}" && return 0

	Err "不支援的 Shell" && return 1
}
function swap::info() {
	local -r pct=$(free --bytes | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2*100; else print "0.00"}')
	local -r tot=$(Extract Swap 2 < <(free --bytes))
	local -r usd=$(Extract Swap 3 < <(free --bytes))
	case "${1:-}" in
		-p | --percentage) Txt "${pct}" ;;
		-t | --total) Txt "${tot}" ;;
		-u | --used) Txt "${usd}" ;;
		*) Txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function SysClean() {
	# TODO: refactor this
	.Root
	Txt "${CLR[3]}正在執行系統清理...${CLR[0]}"
	DLine

	case "${PKG_MGR^^}" in
		APK)
			Task "- 清理 ${PKG_MGR} 快取" "apk cache clean" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 移除暫存檔案" "rm -rf /tmp/* /var/cache/apk/*" || ErrR "移除暫存檔案失敗" || return 1
			Task "- 修復 ${PKG_MGR} 套件" "apk fix" || ErrR "修復 ${PKG_MGR} 套件失敗" || return 1
			;;
		APT)
			Task "- 設定待處理的套件" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || ErrR "設定待處理套件失敗" || return 1
			Task "- 自動移除套件" "pkg::apt autoremove --purge" || ErrR "自動移除套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "pkg::apt clean" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 自動清理 ${PKG_MGR} 快取" "pkg::apt autoclean" || ErrR "自動清理 ${PKG_MGR} 快取失敗" || return 1
			;;
		OPKG)
			Task "- 移除暫存檔案" "rm -rf /tmp/*" || ErrR "移除暫存檔案失敗" || return 1
			Task "- 更新 ${PKG_MGR}" "opkg update" || ErrR "更新 ${PKG_MGR} 失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "opkg clean" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			;;
		PACMAN)
			Task "- 更新和升級套件" "pacman -Syu --noconfirm" || ErrR "使用 ${PKG_MGR} 更新和升級套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "pacman -Sc --noconfirm" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 清理所有 ${PKG_MGR} 快取" "pacman -Scc --noconfirm" || ErrR "清理所有 ${PKG_MGR} 快取失敗" || return 1
			;;
		DNF)
			Task "- 自動移除套件" "dnf autoremove -y" || ErrR "自動移除套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "dnf clean all" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 建立 ${PKG_MGR} 快取" "dnf makecache" || ErrR "建立 ${PKG_MGR} 快取失敗" || return 1
			;;
		YUM)
			Task "- 自動移除套件" "yum autoremove -y" || ErrR "自動移除套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "yum clean all" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 建立 ${PKG_MGR} 快取" "yum makecache" || ErrR "建立 ${PKG_MGR} 快取失敗" || return 1
			;;
		ZYPPER)
			Task "- 清理 ${PKG_MGR} 快取" "zypper clean --all" || ErrR "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 重新整理 ${PKG_MGR} 套件庫" "zypper refresh" || ErrR "重新整理 ${PKG_MGR} 套件庫失敗" || return 1
			;;
	esac

	if command -v journalctl &>/dev/null; then
		Task "- 輪替和清理 journalctl 日誌" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || ErrR "輪替和清理 journalctl 日誌失敗（系統找不到 journalctl 指令）" || return 1
	fi

	local cmd
	for cmd in docker npm pip; do
		command -v "${cmd}" &>/dev/null && case "${cmd^^}" in
			DOCKER) Task "- 清理 DOCKER 系統" "docker system prune -af" || ErrR "清理 DOCKER 系統失敗" || return 1 ;;
			NPM) Task "- 清理 NPM 快取" "npm cache clean --force" || ErrR "清理 NPM 快取失敗" || return 1 ;;
			PIP) Task "- 清除 PIP 快取" "pip cache purge" || ErrR "清除 PIP 快取失敗" || return 1 ;;
		esac
	done

	Task "- 移除使用者快取檔案" "rm -rf ~/.cache/*" || ErrR "移除使用者快取檔案失敗" || return 1
	Task "- 移除暫存檔案" "rm -rf /tmp/*" || ErrR "移除暫存檔案失敗" || return 1
	Task "- 移除縮圖檔案" "rm -rf ~/.thumbnails/*" || ErrR "移除縮圖檔案失敗" || return 1

	Dline
	Finish
}
function SysInfo() {
	Txt "${CLR[3]}系統資訊${CLR[0]}"
	DLine

	Txt "- 主機名稱：            ${CLR[2]}$(uname -n || hostname)${CLR[0]}"
	Txt "- 作業系統：            ${CLR[2]}$(sys::distro)${CLR[0]}"
	Txt "- 核心版本：            ${CLR[2]}$(uname -r)${CLR[0]}"
	Txt "- 系統語言：            ${CLR[2]}${LANG}${CLR[0]}"
	Txt "- Shell 版本：          ${CLR[2]}$(sys::shell_version)${CLR[0]}"
	Txt "- 最後系統更新：        ${CLR[2]}$(pkg::last_update)${CLR[0]}"

	SLine

	Txt "- 架構：                ${CLR[2]}$(uname -m)${CLR[0]}"
	Txt "- CPU 型號：            ${CLR[2]}$(cpu::model)${CLR[0]}"
	Txt "- CPU 核心數：          ${CLR[2]}$(nproc)${CLR[0]}"
	Txt "- CPU 頻率：            ${CLR[2]}$(cpu::freq)${CLR[0]}"
	Txt "- CPU 使用率：          ${CLR[2]}$(cpu::usage)%${CLR[0]}"
	Txt "- CPU 快取：            ${CLR[2]}$(cpu::cache)${CLR[0]}"

	SLine

	Txt "- RAM 使用率：          ${CLR[2]}$(mem::info)${CLR[0]}"
	Txt "- SWAP 使用率：         ${CLR[2]}$(swap::info)${CLR[0]}"
	Txt "- DISK 使用率：         ${CLR[2]}$(disk::info)${CLR[0]}"
	Txt "- 檔案系統類型：        ${CLR[2]}$(Extract 2 2 < <(df -T /))${CLR[0]}"

	SLine

	Txt "- IPv4 地址：           ${CLR[2]}$(net::ip --ipv4)${CLR[0]}"
	Txt "- IPv6 地址：           ${CLR[2]}$(net::ip --ipv6)${CLR[0]}"
	Txt "- MAC 位址：            ${CLR[2]}$(net::mac)${CLR[0]}"
	Txt "- 網路供應商：          ${CLR[2]}$(net::provider)${CLR[0]}"
	Txt "- DNS 伺服器：          ${CLR[2]}$(net::dns)${CLR[0]}"
	Txt "- 公開 IP：             ${CLR[2]}$(net::ip --public)${CLR[0]}"
	Txt "- 網路介面：            ${CLR[2]}$(net::iface -i)${CLR[0]}"
	Txt "- 內部時區：            ${CLR[2]}$(sys::timezone --internal)${CLR[0]}"
	Txt "- 外部時區：            ${CLR[2]}$(sys::timezone --external)${CLR[0]}"

	SLine

	Txt "- 負載平均：            ${CLR[2]}$(sys::load)${CLR[0]}"
	Txt "- 程序數量：            ${CLR[2]}$(wc -l < <(ps aux --no-headers))${CLR[0]}"
	Txt "- 已安裝套件：          ${CLR[2]}$(pkg::count)${CLR[0]}"

	SLine

	Txt "- 啟動時刻：            ${CLR[2]}$(who -b | str::trim "boot  ")${CLR[0]}"
	Txt "- 運行時間：            ${CLR[2]}$(uptime -p | str::trim "up ")${CLR[0]}"

	SLine

	Txt "- 虛擬化：              ${CLR[2]}$(sys::virt)${CLR[0]}"

	DLine
}
function SysOptz() {
	.Root

	Txt "${CLR[3]}正在優化長期運行伺服器的系統設定...${CLR[0]}" && DLine

	# ==========================================
	# 1. 系統參數配置 (使用 Heredoc 一次到位，語法極度乾淨)
	# ==========================================
	function _ApplySysctlConf() {
		AddFile /etc/sysctl.d/99-server-optimizations.conf
		cat <<-'EOF' >/etc/sysctl.d/99-server-optimizations.conf
			vm.dirty_background_ratio = 5
			vm.dirty_ratio = 15
			vm.min_free_kbytes = 65536
			vm.swappiness = 1
			vm.vfs_cache_pressure = 50

			net.core.netdev_max_backlog = 65535
			net.core.somaxconn = 65535
			net.ipv4.ip_local_port_range = 1024 65535
			net.ipv4.tcp_fin_timeout = 15
			net.ipv4.tcp_keepalive_intvl = 15
			net.ipv4.tcp_keepalive_probes = 5
			net.ipv4.tcp_keepalive_time = 300
			net.ipv4.tcp_max_syn_backlog = 65535
			net.ipv4.tcp_slow_start_after_idle = 0
			net.ipv4.tcp_tw_reuse = 1
			net.core.default_qdisc = fq
			net.ipv4.conf.all.accept_redirects = 0
			net.ipv4.conf.all.rp_filter = 1
			net.ipv4.conf.default.accept_redirects = 0
			net.ipv4.conf.default.rp_filter = 1
			net.ipv4.tcp_congestion_control = bbr
			net.ipv4.tcp_max_tw_buckets = 262144
			net.ipv4.tcp_syn_retries = 2
			net.ipv4.tcp_synack_retries = 2
			net.ipv4.tcp_syncookies = 1
			net.ipv4.tcp_timestamps = 1

			net.core.rmem_max = 16777216
			net.core.wmem_max = 16777216
			net.ipv4.tcp_mtu_probing = 1
			net.ipv4.tcp_rmem = 4096 87380 16777216
			net.ipv4.tcp_wmem = 4096 65536 16777216

			fs.file-max = 2097152
			fs.inotify.max_user_watches = 524288
			fs.nr_open = 2097152
		EOF
	}

	function _ApplySystemLimits() {
		AddFile /etc/security/limits.d/99-server-limits.conf
		cat <<-'EOF' >/etc/security/limits.d/99-server-limits.conf
			* hard nofile 1048576
			* hard nproc 65535
			* soft nofile 1048576
			* soft nproc 65535
		EOF
	}

	function _OptimizeDisk() {
		local disk dev_type
		for disk in /sys/block/{sd*,vd*,nvme*}; do
			[[ -d "${disk}" ]] || continue
			# 依據是否為旋轉磁碟決定排程器 (0 為 SSD/NVMe)
			dev_type=$(cat "${disk}/queue/rotational" 2>/dev/null || Txt "1")
			if Txt "${dev_type}" | str::grep -q "0"; then
				cat <<<"none" >"${disk}/queue/scheduler" 2>/dev/null
			else
				cat <<<"mq-deadline" >"${disk}/queue/scheduler" 2>/dev/null
			fi
			cat <<<"256" >"${disk}/queue/nr_requests" 2>/dev/null || true
		done
	}

	function _DisableService() {
		local services=(
			autofs
			avahi-daemon
			bluetooth
			cups
			nfs-server
			postfix
			rpcbind
		)
		local s
		for s in "${services[@]}"; do
			if systemctl list-unit-files "${s}.service"; then
				systemctl disable --now "${s}.service" &>/dev/null || true
			fi
		done
	}

	function _OptimizeSSH() {
		local ssh_conf=/etc/ssh/sshd_config
		[[ -f ${ssh_conf} ]] || return 0

		# 備份原始設定
		cp "${ssh_conf}" "${ssh_conf}.bak"

		# 關閉 DNS 反向解析（大幅加快 SSH 登入速度）
		sed -i 's/^#\?UseDNS.*/UseDNS no/g' "${ssh_conf}"

		# 啟用客戶端保活，每 60 秒發送一次，連續 3 次無回應才斷開（防止閒置斷線）
		sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 60/g' "${ssh_conf}"
		sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 3/g' "${ssh_conf}"

		# 提高 SSH 併發連接限制（防止多人或多線程部署時被拒絕）
		sed -i 's/^#\?MaxStartups.*/MaxStartups 10:30:100/g' "${ssh_conf}"

		systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
	}

	function _OptimizeJournal() {
		local journal_conf=/etc/systemd/journald.conf
		[[ -f ${journal_conf} ]] || return 0

		# 限制日誌最大佔用 500MB 空間，預設通常是硬碟的 10%（極易塞爆）
		sed -i 's/^#\?SystemMaxUse.*/SystemMaxUse=500M/g' "${journal_conf}"
		sed -i 's/^#\?RuntimeMaxUse.*/RuntimeMaxUse=200M/g' "${journal_conf}"

		systemctl restart systemd-journald 2>/dev/null
	}

	function _EnsureSwap() {
		# 如果已經有 Swap，就跳過
		(($(swapon -s | wc -l) > 1)) && return 0

		# 建立 2GB 的 Swap 空間
		local swapfile=/swapfile
		fallocate -l 2G "${swapfile}" 2>/dev/null || dd if=/dev/zero of="${swapfile}" bs=1M count=2048

		chmod 600 "${swapfile}"
		mkswap "${swapfile}" >/dev/null
		swapon "${swapfile}"

		# 寫入開機自動掛載
		file::grep -q "${swapfile}" /etc/fstab || cat <<<"${swapfile} none swap sw 0 0" >>/etc/fstab
	}

	if Raw "- 正在產生核心參數與網路優化設定... " && _ApplySysctlConf &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在產生系統資源限制設定... " && _ApplySystemLimits &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在優化儲存裝置 I/O 排程器... " && _OptimizeDisk &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在停用背景非必要服務... " && _DisableService &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在優化 SSH 連線與安全性設定... " && _OptimizeSSH &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在配置日誌上限以保護磁碟空間... " && _OptimizeJournal &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在建置系統應急 Swap 緩衝空間... " && _EnsureSwap &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在將核心參數載入系統運作... " && sysctl --system &>/dev/null; then Finish; else return 1; fi
	if Raw "- 正在清理網路鄰居快取快門... " && ip -s -s neigh flush all &>/dev/null; then Finish; else return 1; fi

	Dline
	Finish
}
function SysRboot() {
	.Root
	local -r active_usrs="$(who | wc -l)" important_procs="$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l)"
	local cont

	Txt "${CLR[3]}正在準備重新啟動系統...${CLR[0]}" && DLine

	if ((active_usrs != 0)); then
		Txt "${CLR[3]}警告：目前系統有 ${active_usrs} 個活動使用者${CLR[0]}"
		Raw "\n"
		Txt "活動使用者："
		Extract 1 {1,3,4} < <(who)
		Raw "\n"
	fi

	if ((important_procs != 0)); then
		Txt "${CLR[3]}警告：有 ${important_procs} 個重要程序正在執行${CLR[0]}"
		Raw "\n"
		Txt "${CLR[8]}CPU 使用率最高的 5 個程序：${CLR[0]}"
		ps aux --sort=-%cpu | head -n 6
		Raw "\n"
	fi

	read -p "您確定要立即重新啟動系統嗎？(y/N) " -nr 1 cont
	Raw "\n"

	if ! [[ ${cont} =~ ^[Yy]$ ]]; then
		Txt "${CLR[2]}已取消重新啟動${CLR[0]}"
		Raw "\n"
		return 0
	fi

	Task "- 執行最終檢查" "sync" || ErrR "同步檔案系統失敗" || return 1
	Task "- 開始重新啟動" "reboot || sudo reboot" || ErrR "啟動重新啟動失敗" || return 1
	Txt "${CLR[2]}已成功發出重新啟動命令。系統將立即重新啟動${CLR[0]}"
}
function SysUpd() {
	.Root

	local -r current_lang="${LANG}" update_url="https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh"

	Txt "${CLR[3]}正在更新系統套件...${CLR[0]}"
	DLine

	pkg::upgrade
	url::get -qO- "${update_url}" | bash -s -- "${current_lang}" || ErrR "更新 UtilKit.sh 失敗" || return 1

	Dline
	Finish
}
function SysUpg() {
	.Root

	Txt "${CLR[3]}正在升級系統至下一個主要版本...${CLR[0]}" && DLine

	os_nm=$(sys::distro --name)
	case "${os_nm^^}" in
		DEBIAN)
			Txt "- 偵測到 DEBIAN 系統"
			Txt "- 正在更新套件清單"
			pkg::updatee || ErrR "使用 APT 更新套件清單失敗" || return 1
			Txt "- 正在升級目前的套件"
			pkg::upgrade || ErrR "升級目前的套件失敗" || return 1
			Txt "- 開始 DEBIAN 發行版升級..."
			curr_codenm=$(lsb_release -cs)
			targ_codenm=$(GetValue "Codename" < <(url::get -qO- "https://ftp.debian.org/debian/dists/stable/Release"))
			[[ ${curr_codenm} == "${targ_codenm}" ]] && Err "系統已達最新穩定版 (本地/遠端穩定版：${curr_codenm}/${targ_codenm}" && return 1
			Txt "- 正在從 ${CLR[2]}${curr_codenm}${CLR[0]} 升級到 ${CLR[3]}${targ_codenm}${CLR[0]}"
			Task "- 備份 sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || ErrR "備份 sources.list 失敗" || return 1
			Task "- 更新 sources.list" "sed -i 's/${curr_codenm}/${targ_codenm}/g' /etc/apt/sources.list" || ErrR "更新 sources.list 失敗" || return 1
			Task "- 更新套件清單" "pkg::update" || ErrR "更新新版本的套件清單失敗" || return 1
			pkg::upgrade || ErrR "升級到新的 DEBIAN 版本失敗" || return 1
			;;
		UBUNTU)
			Txt "- 偵測到 UBUNTU 系統"
			Task "- 正在更新套件清單" "pkg::update" || ErrR "使用 APT 更新套件清單失敗" || return 1
			Task "- 正在升級目前的套件" "pkg::upgrade" || ErrR "升級目前的套件失敗" || return 1
			Task "- 安裝 update-manager-core" "pkg::install update-manager-core" || ErrR "安裝 update-manager-core 失敗" || return 1
			do-release-upgrade -f DistUpgradeViewNonInteractive || ErrR "升級 UBUNTU 版本失敗" || return 1
			SysRboot
			;;
		*) Err "您的系統尚不支援主要版本升級" && return 1 ;;
	esac
	Dline
	Finish
}
function Task() {
	.Flag
	local -r msg="$1" ignore_error="${2:-false}"
	shift 2 # 移出前兩個參數，剩下的 "$@" 就是完整的命令與其參數

	local ret tmp_file

	if ! tmp_file=$(mktemp); then
		Err "無法建立臨時檔案" && return 1
	fi

	# 注意：在 Bash 中，函式內的 trap '...' RETURN
	# 需要在 Bash 4.4+ 或有設定 set -T / trap_return 的情況下才完全可靠。
	# 建議保留或確保環境支援。
	trap 'rm -f "${tmp_file}"' RETURN

	Raw "${msg}... "

	# 關鍵改動：直接執行 "$@"，完全不透過 eval，絕對安全且支援帶有空白的參數
	if "$@" >"${tmp_file}" 2>&1; then
		Finish
		ret=0
	else
		ret=$?
		Txt "${CLR[1]}失敗${CLR[0]} (${ret})"
		[[ -s "${tmp_file}" ]] && Txt "${CLR[1]}$(cat "${tmp_file}")${CLR[0]}"
		[[ ${ignore_error} == "true" ]] || return "${ret}"
	fi
	return "${ret}"
}
function sys::timezone() {
	.Flag

	function _DetectExternal() {
		url::get -qO- "https://ipapi.co/json" | GetValue "timezone" && return 0
		url::get -qO- "http://ip-api.com/json" | str::trim '"timezone":"' '",' && return 0
		return 1
	}
	function _DetectInternal() {
		readlink /etc/localtime | str::trim "zoneinfo/" && return 0
		timedatectl status | Extract "Time zone" 2 ":" && return 0
		file::grep -v "^#" /etc/timezone | tr -d " " && return 0
		return 1
	}

	case "$1" in
		-e | --external)
			if ! Txt "$(_DetectExternal)"; then
				Err "從外部服務偵測時區失敗" && return 1
			fi
			;;
		-i | --internal)
			if ! Txt "$(_DetectInternal)"; then
				Err "偵測系統時區失敗" && return 1
			fi
			;;
	esac
}
function Press() {
	if ! read -p "$1" -n 1 -r; then
		Err "讀取使用者輸入失敗" && return 1
	fi
}

function HelpMsg() {
	local -i max_len=0 i=0 perform_validation=0
	local cmds=() cmd_descs=() opts=() opt_descs=() valid_cmds=() valid_opts=() args_to_validate=()
	local app_name current_section item desc

	function _IsInArray() {
		local -r target="$1"
		shift
		local element
		for element in "$@"; do
			[[ ${element} == "${target}" ]] && return 0
		done
		return 1
	}

	function _GetStrWidth() { printf "%s" "$1" | LANG=C.UTF-8 wc -L; }

	if [[ $1 == "-n" ]]; then
		app_name="${2:-}"
		shift 2
	fi

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
			--validate | -v)
				perform_validation=1
				shift
				args_to_validate=("$@")
				break
				;;
			*)
				item="$1"

				if var::valid "$2" && [[ $2 != -* ]]; then
					desc="$2"
					shift 2
				else
					desc=""
					shift 1
				fi

				local -i item_width=0
				item_width=$(_GetStrWidth "${item}")

				if [[ ${current_section} == "CMD" ]]; then
					cmds+=("${item}")
					cmd_descs+=("${desc}")
					valid_cmds+=("${item}")
					((item_width > max_len)) && max_len=item_width
				elif [[ ${current_section} == "OPT" ]]; then
					opts+=("${item}")
					opt_descs+=("${desc}")

					# 拆分選項定義（如 "-h, --help" 拆為 "-h" 與 "--help"）並寫入驗證白名單
					local opt_cleaned="${item//[,|]/ }"
					local opt_part
					for opt_part in ${opt_cleaned}; do
						valid_opts+=("${opt_part}")
					done

					((item_width > max_len)) && max_len=item_width
				fi
				;;
		esac
	done

	local -i help_requested=0 has_error=0 command_seen=0
	local error_msg

	if ((perform_validation == 1)); then
		local arg
		for arg in "${args_to_validate[@]}"; do
			if [[ ${arg} == "-h" || ${arg} == "--help" ]]; then
				help_requested=1
				break
			fi
		done

		if ((help_requested == 0)); then
			for arg in "${args_to_validate[@]}"; do
				if [[ ${arg} == --* ]]; then
					local opt_name="${arg%%=*}"
					if ! _IsInArray "${opt_name}" "${valid_opts[@]}"; then
						error_msg="Invalid option: ${arg}"
						has_error=1
						break
					fi
				elif [[ ${arg} == -* && "${arg}" != "-" ]]; then
					local first_opt="-${arg:1:1}"
					if _IsInArray "${first_opt}" "${valid_opts[@]}"; then
						if ! _IsInArray "${arg}" "${valid_opts[@]}"; then
							local -i idx=0 is_cluster_valid=1
							for ((idx = 1; idx < ${#arg}; idx++)); do
								local char_opt="-${arg:idx:1}"
								if ! _IsInArray "${char_opt}" "${valid_opts[@]}"; then
									is_cluster_valid=0
									break
								fi
							done
							if ((is_cluster_valid == 0)); then
								error_msg="Invalid option: ${arg}"
								has_error=1
								break
							fi
						fi
					else
						error_msg="Invalid option: ${arg}"
						has_error=1
						break
					fi
				else
					if ((${#cmds[@]} > 0 && command_seen == 0)); then
						if _IsInArray "${arg}" "${valid_cmds[@]}"; then
							command_seen=1
						else
							error_msg="Invalid command: ${arg}"
							has_error=1
							break
						fi
					fi
				fi
			done
		fi

		if ((help_requested == 1)); then
			local -r should_exit_0=1
		elif ((has_error == 1)); then
			printf "Error: %s\n\n" "${error_msg}" >&2
			local -r should_exit_1=1
		else
			return 0
		fi
	fi

	Txt "Usage: ${app_name:-\$0} [OPTIONS] COMMAND"
	Raw "\n"

	local -r total_width=$((max_len + 4))

	function _PrintAlignedLine() {
		local -r target="$1" description="$2"
		local -i spaces=0 w=0
		spaces=$((total_width - w))
		w=$(_GetStrWidth "${target}")
		local pad

		((spaces > 0)) && printf -v pad "%*s" "${spaces}" ""

		printf "    %s%s%s\n" "${target}" "${pad}" "${description}"
	}

	if ((${#cmds[@]} > 0)); then
		Txt "Commands:"
		for ((i = 0; i < ${#cmds[@]}; i++)); do
			_PrintAlignedLine "${cmds[i]}" "${cmd_descs[i]}"
		done
		Raw "\n"
	fi

	if ((${#opts[@]} > 0)); then
		Txt "Options:"
		for ((i = 0; i < ${#opts[@]}; i++)); do
			_PrintAlignedLine "${opts[i]}" "${opt_descs[i]}"
		done
	fi

	# 根據驗證狀態判定結束與否
	if [[ ${should_exit_0:-} == 1 ]]; then
		exit 0
	elif [[ ${should_exit_1:-} == 1 ]]; then
		exit 1
	fi
}
