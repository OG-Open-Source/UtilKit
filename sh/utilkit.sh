#!/usr/bin/env bash
# VERSION="8.0.0a8"

# set -Eeuo pipefail
# set +u
set -o pipefail
shopt -s expand_aliases

declare _
declare BASH=0 PKG_MGR="unknown"
readonly LANG="${LANG:-C.UTF-8}"

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

((BASH == 0)) && printf "%b\n" "${CLR[1]}Unsupported Bash version!${CLR[0]}" && return 126
[[ ${PKG_MGR} == "unknown" ]] && printf "%b\n" "${CLR[1]}Unknown package manager!${CLR[0]}" && return 127

# ----------------------------------------------------------------------
#  Namespace: var/io/str
# ----------------------------------------------------------------------
function var::empty() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do [[ -z "$v" ]] || return 1; done
}
function var::set() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do [[ -v "$v" ]] || return 1; done
}
function var::valid() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do [[ -n "$v" ]] || return 1; done
}

function io::err() { var::valid "$@" && printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2; }
function io::err_die() { var::valid "$@" && printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2 && return 1; }
function io::raw() { printf "%b" "$*"; }
function io::txt() { var::valid "$@" && printf "%b\n" "$*"; }

function str::grep() { command grep "$@"; }
function str::trim() {
	(($# == 0)) && return 2

	local stdin_buffer
	stdin_buffer=$(cat)
	[[ -n ${1:-} ]] && stdin_buffer="${stdin_buffer#*"$1"}"
	[[ -n ${2:-} ]] && stdin_buffer="${stdin_buffer%%"$2"*}"

	printf "%b\n" "${stdin_buffer}"
}
function str::grid() {
	local has_modifiers=0

	(($# > 0)) && [[ $1 =~ ^([_<>^][0-9]*)([_<>^][0-9]*)?$ ]] && has_modifiers=1 && shift

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

	io::txt "${output_cols[*]}"
}
function str::query() {
	local -r key="$1" data_source="${2:-}"
	local -r pattern="(^|[[:space:],'{ \"])(\"${key}\"|'${key}'|\<${key}\>)[[:space:]]*[:=][[:space:]]*(\"([^\"]*)\"|'([^']*)'|([^,#]*[^[:space:],#]))"

	function _parse() {
		local -r target_pattern="$1"
		local line

		while read -r line; do
			[[ ${line} =~ ${target_pattern} ]] && printf "%s\n" "${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}" && return 0
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

function sys::harden_env() {
	function curl() { false; }
	function eval() { false; }
	function grep() { false; }
	function wget() { false; }
}
function sys::cpu_cache() {
	file::exist /proc/cpuinfo || io::err_die "無法存取 CPU 資訊。" || return 1
	local -r cpu_cache="$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)"
	[[ ${cpu_cache} == "N/A" ]] && io::err "無法確定 CPU 快取大小" && return 1
	io::txt "${cpu_cache} KB"
}
function sys::cpu_freq() {
	file::exist /proc/cpuinfo || io::err_die "無法存取 CPU 資訊。" || return 1
	local -r cpu_freq="$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)"
	[[ ${cpu_freq} == "N/A" ]] && io::err "無法確定 CPU 頻率" && return 1
	io::txt "${cpu_freq} GHz"
}
function sys::cpu_model() {
	str::query "Model name" < <(lscpu) && return 0
	str::query "model name" </proc/cpuinfo && return 0
	sysctl -n machdep.cpu.brand_string 2>/dev/null && return 0

	io::err "${CLR[1]}未知${CLR[0]}" && return 1
}
function sys::cpu_usage() {
	local -i usr nice sys idle iowait irq softirq steal guest guest_nice

	if read -r _ usr nice sys idle iowait irq softirq steal guest guest_nice <<<"$(str::grid cpu {1..11} </proc/stat)"; then
		var::empty "${idle}" && io::err "從 /proc/stat 讀取第一階段 CPU 統計失敗" && return 1
	fi
	local -ir prev_total=$((usr + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice)) prev_idle=idle

	sleep 0.3

	if read -r _ usr nice sys idle iowait irq softirq steal guest guest_nice <<<"$(str::grid cpu {1..11} </proc/stat)"; then
		var::empty "${idle}" && io::err "從 /proc/stat 讀取第二階段 CPU 統計失敗" && return 1
	fi
	local -ir curr_total=$((usr + nice + sys + idle + iowait + irq + softirq + steal + guest + guest_nice)) curr_idle=idle
	local -ir tot_delta=$((curr_total - prev_total)) idle_delta=$((curr_idle - prev_idle))

	((tot_delta == 0)) && io::txt "0"
	io::txt $((100 * (tot_delta - idle_delta) / tot_delta))
}
function sys::disk_info() {
	local -r pct=$(df -B1 / | awk '/^\/dev/ {printf("%.2f"), $3/($3+$4)*100}')
	local -r tot=$(str::grid 2 2 < <(df -B1 /))
	local -r usd=$(str::grid 2 3 < <(df -B1 /))
	case "${1:-}" in
		-p | --percentage) io::txt "${pct}" ;;
		-t | --total) io::txt "${tot}" ;;
		-u | --used) io::txt "${usd}" ;;
		*) io::txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function sys::mem_info() {
	local -r pct=$(free --bytes | awk '/^Mem:/ {printf("%.2f"), $3/$2*100}')
	local -r tot=$(str::grid Mem 2 < <(free --bytes))
	local -r usd=$(str::grid Mem 3 < <(free --bytes))
	case "${1:-}" in
		-p | --percentage) io::txt "${pct}" ;;
		-t | --total) io::txt "${tot}" ;;
		-u | --used) io::txt "${usd}" ;;
		*) io::txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function sys::swap_info() {
	local -r pct=$(free --bytes | awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2*100; else print "0.00"}')
	local -r tot=$(str::grid Swap 2 < <(free --bytes))
	local -r usd=$(str::grid Swap 3 < <(free --bytes))
	case "${1:-}" in
		-p | --percentage) io::txt "${pct}" ;;
		-t | --total) io::txt "${tot}" ;;
		-u | --used) io::txt "${usd}" ;;
		*) io::txt "$(ConvSz "${usd}") / $(ConvSz "${tot}") (${pct}%)" ;;
	esac
}
function sys::distro() {
	case "$1" in
		-v | --version)
			if file::exist /etc/os-release; then
				local -r os_id="$(str::query "ID" </etc/os-release)"
				case "${os_id^^}" in
					DEBIAN) cat /etc/debian_version ;;
					FEDORA) file::grep -oE '[0-9]+' /etc/fedora-release ;;
					CENTOS) file::grep -oE '[0-9]+\.[0-9]+' /etc/centos-release ;;
					ALPINE) cat /etc/alpine-release ;;
					*) io::txt "${VERSION_ID}" ;;
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
				io::err "Unknown" && return 1
			fi
			;;
		-n | --name)
			if file::exist /etc/os-release; then
				str::query "NAME" </etc/os-release
			elif file::exist /etc/DISTRO_SPECS; then
				str::query "DISTRO_NAME" </etc/DISTRO_SPECS
			else
				io::err "Unknown" && return 1
			fi
			;;
		*) str::trim "" "\n" </etc/issue ;;
	esac
}
function sys::load() {
	local -r LC_ALL=C
	local zo_mi zv_mi ov_mi

	read -r zo_mi zv_mi ov_mi _ _ </proc/loadavg 2>/dev/null && io::txt "${zo_mi}, ${zv_mi}, ${ov_mi}" && return 0
	io::txt "$(str::grid 1 5 ":" < <(uptime)) ($(nproc) Cores)" && return 0

	io::err "缺失取得方法" && return 1
}
function sys::location() {
	case "$1" in
		-c | --city) data=$(net::url_get -qO- "https://ipinfo.io/city") ;;
		-C | --country | *) data=$(net::url_get -qO- "https://ipinfo.io/country") ;;
	esac

	io::txt "${data:-N/A}"
}
function sys::shell_ver() {
	# TODO: refactor this
	local -r LC_ALL=C

	var::valid "${BASH_VERSION:-}" && io::txt "Bash ${BASH_VERSION}" && return 0
	var::valid "${ZSH_VERSION:-}" && io::txt "Zsh ${ZSH_VERSION}" && return 0

	io::err "不支援的 Shell" && return 1
}
function sys::timezone() {
	(($# == 0)) && return 2

	function _DetectExternal() {
		net::url_get -qO- "https://ipapi.co/json" | str::query "timezone" && return 0
		net::url_get -qO- "http://ip-api.com/json" | str::trim '"timezone":"' '",' && return 0
		return 1
	}
	function _DetectInternal() {
		readlink /etc/localtime | str::trim "zoneinfo/" && return 0
		timedatectl status | str::grid "Time zone" 2 ":" && return 0
		file::grep -v "^#" /etc/timezone | tr -d " " && return 0
		return 1
	}

	case "$1" in
		-e | --external)
			if ! io::txt "$(_DetectExternal)"; then
				io::err "從外部服務偵測時區失敗" && return 1
			fi
			;;
		-i | --internal)
			if ! io::txt "$(_DetectInternal)"; then
				io::err "偵測系統時區失敗" && return 1
			fi
			;;
	esac
}
function sys::virt() {
	if command -v systemd-detect-virt &>/dev/null; then
		local -r virt_typ="$(systemd-detect-virt 2>/dev/null)"

		var::empty "${virt_typ}" && io::err "無法偵測虛擬化環境" && return 1

		case "${virt_typ^^}" in
			KVM)
				if [[ $(cat /sys/class/dmi/id/product_name 2>/dev/null) == *[Pp]roxmox* ]]; then
					io::txt "Proxmox VE (KVM)"
				else
					io::txt "KVM"
				fi
				;;
			MICROSOFT) io::txt "Microsoft Hyper-V" ;;
			WSL) io::txt "適用於 Linux 的 Windows 子系統" ;;
			NONE)
				if file::grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
					io::txt "LXC 容器"
				elif file::grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
					io::txt "虛擬機器（未知類型）"
				else
					io::txt "未偵測到（可能為實體機器）"
				fi
				;;
			*) io::txt "${virt_typ}" ;;
		esac
	elif file::exist /proc/cpuinfo; then
		if file::grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
			io::txt "虛擬機器（未知類型）"
		else
			io::txt "未偵測到（可能為實體機器）"
		fi
	else
		io::txt "未知環境"
	fi
}
# ----------------------------------------------------------------------
#  Namespace: fs (Filesystem & Permissions)
# ----------------------------------------------------------------------
function fs::dir_exist() {
	(($# == 0)) && return 2
	local d
	for d in "$@"; do [[ -d $d ]] || return 1; done
}
function fs::file_exist() {
	(($# == 0)) && return 2
	local f
	for f in "$@"; do [[ -f $f ]] || return 1; done
}
function fs::file_valid() {
	(($# == 0)) && return 2
	local f
	for f in "$@"; do [[ -s $f ]] || return 1; done
}
function fs::file_grep() {
	(($# < 2)) && return 2
	command -v grep &>/dev/null || return 126
	local -r file="${!#}"
	[[ ! (-f ${file} && -r ${file} && -s ${file}) ]] && return 2
	command grep "$@"
}
function fs::path_exist() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -e $p || -L $p ]] || return 1; done
}
function fs::perm_read() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -r $p ]] || return 1; done
}
function fs::perm_write() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -w $p ]] || return 1; done
}
function fs::perm_exec() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -x $p ]] || return 1; done
}

# ----------------------------------------------------------------------
#  Namespace: net (Networking & Downloads)
# ----------------------------------------------------------------------
function net::url_get() { command wget --timeout=15 --tries=3 --waitretry=5 --retry-on-http-error=429,500,502,503,504 --max-redirect=5 "$@"; }
function net::dns() {
	file::exist /etc/resolv.conf && io::err "找不到 DNS 設定檔" && return 1
	local dns4=() dns6=()

	while read -r servers; do
		[[ ${servers} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && dns4+=("${servers}")
		[[ ${servers} =~ ^[0-9a-fA-F:]+$ ]] && dns6+=("${servers}")
	done < <(file::grep -E '^nameserver' /etc/resolv.conf | str::grid 1 2)

	((${#dns4[@]} == 0 && ${#dns6[@]} == 0)) && io::err "/etc/resolv.conf 中未設定 DNS 伺服器" && return 1
	case "${1:-}" in
		-4 | --ipv4)
			((${#dns4[@]} == 0)) && io::err "找不到 IPv4 DNS 伺服器" && return 1
			io::txt "${dns4[*]}"
			;;
		-6 | --ipv6)
			((${#dns6[@]} == 0)) && io::err "找不到 IPv6 DNS 伺服器" && return 1
			io::txt "${dns6[*]}"
			;;
		*)
			((${#dns4[@]} == 0 && ${#dns6[@]} == 0)) && io::err "找不到 DNS 伺服器" && return 1
			io::txt "${dns4[*]}   ${dns6[*]}"
			;;
	esac
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
	) || io::err_die "從 /proc/net/dev 取得網路介面失敗" || return 1

	mapfile -t items <<<"${all_interfaces}"
	interfaces=([0]="placeholder")
	for item in "${items[@]}"; do
		var::valid "${item}" && interfaces+=("${item}")
	done
	unset 'interfaces[0]'
	interfaces_num=${#interfaces[@]}

	default4_route=$(ip -4 route show default 2>/dev/null || io::raw "")
	default6_route=$(ip -6 route show default 2>/dev/null || io::raw "")

	for ((i = 1; i <= ${#interfaces[@]}; i++)); do
		item="${interfaces[i]}"
		var::empty "${item}" && continue

		if var::valid "${default4_route}" && var::empty "${interface4}"; then
			io::txt "${default4_route}" | str::grep -qE "\bdev ${item}\b"
			interface4="${item}"
		fi
		if var::valid "${default6_route}" && var::empty "${interface6}"; then
			io::txt "${default6_route}" | str::grep -qE "\bdev ${item}\b"
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
		interface=$(io::txt "${interface}" | tr -s ' ' | xargs)
	else
		physical_iface=$(ip -o link show | str::grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap' | str::grep 'state UP' | head -n 1 | str::grid 1 2 ":")
		if var::valid "${physical_iface}"; then
			interface="${physical_iface}"
		else
			interface=$(ip -o link show | str::grep -v 'lo:' | head -n 1 | str::grid 1 2 ":")
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
						--rx_bytes) io::txt "${rx_bytes}" && break ;;
						--rx_packets) io::txt "${rx_packets}" && break ;;
						--rx_drop) io::txt "${rx_drop}" && break ;;
						--tx_bytes) io::txt "${tx_bytes}" && break ;;
						--tx_packets) io::txt "${tx_packets}" && break ;;
						--tx_drop) io::txt "${tx_drop}" && break ;;
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
					io::txt "${iface}: RX: $(ConvSz "${rx_bytes}"), TX: $(ConvSz "${tx_bytes}")"
				fi
			done
			;;
		*) io::txt "${interface}" ;;
	esac
}
function net::ip() {
	local -r apis=("api64.ipify.org" "ifconfig.me" "ipinfo.io") ip4_regex="(\b25[0-5]|\b2[0-4][0-9]|\b[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}"
	local -r ip6_regex="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}{1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}{1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}{1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}{1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}{1,6}|:((:[0-9a-fA-F]{1,4}{1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}{0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}{0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))"
	local ip4_addr ip6_addr
	case "$1" in
		-4 | --ipv4)
			for api in "${apis[@]}"; do
				ip4_addr=$(net::url_get -qO- -4 "${api}" 2>/dev/null)
				break
			done

			ip4_addr=$(str::grep -oE "${ip4_regex}" <<<"${ip4_addr}")
			io::txt "${ip4_addr:-N/A}"
			;;
		-6 | --ipv6)
			for api in "${apis[@]}"; do
				ip6_addr=$(net::url_get -qO- -6 "${api}" 2>/dev/null)
				break
			done
			ip6_addr=$(str::grep -oE "${ip6_regex}" <<<"${ip6_addr}")
			io::txt "${ip6_addr:-N/A}"
			;;
		-p | --public) str::query "ip" < <(net::url_get -qO- "https://developers.cloudflare.com/cdn-cgi/trace") ;;
		*)
			for api in "${apis[@]}"; do
				ip4_addr=$(net::url_get -qO- -4 "${api}" 2>/dev/null)
				break
			done
			ip4_addr=$(str::grep -oE "${ip4_regex}" <<<"${ip4_addr}")

			for api in "${apis[@]}"; do
				ip6_addr=$(net::url_get -qO- -6 "${api}" 2>/dev/null)
				break
			done
			ip6_addr=$(str::grep -oE "${ip6_regex}" <<<"${ip6_addr}")

			var::empty "${ip4_addr}${ip6_addr}" && io::err "取得 IP 位址失敗" && return 1
			io::raw "IPv4: " && io::txt "${ip4_addr:-N/A}"
			io::raw "IPv6: " && io::txt "${ip6_addr:-N/A}"
			;;
	esac
}
function net::mac() { str::grid link/ether 2 < <(ip link show) || io::err_die "無法取得 MAC 位址。找不到網路介面" || return 1; }
function net::provider() {
	net::url_get -qO- "https://ipinfo.io" | str::query "org" && return 0
	net::url_get -qO- "https://ipwhois.app/json" | str::trim '"org":"' '",' && return 0
	net::url_get -qO- "http://ip-api.com/json" | str::trim '"org":"' '",' && return 0

	io::err "無法偵測網路供應商。請檢查網路連線" && return 1
}

# ----------------------------------------------------------------------
#  Namespace: pkg (Package Manager Wrappers)
# ----------------------------------------------------------------------
function pkg::apt() {
	(($# == 0)) && return 2
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
	esac
}
function pkg::is_installed() {
	(($# == 0)) && return 2

	case "${PKG_MGR^^}" in
		APK) apk info -e "${1,,}" &>/dev/null ;;
		APT) dpkg -s "${1,,}" &>/dev/null ;;
		DNF) rpm -q "${1,,}" &>/dev/null ;;
		OPKG) opkg status "${1,,}" 2>/dev/null | str::grep -q "Status:.*installed" ;;
		PACMAN) pacman -Qq "${1,,}" &>/dev/null ;;
		YUM) rpm -q "${1,,}" &>/dev/null ;;
		ZYPPER) rpm -q "${1,,}" &>/dev/null ;;
	esac
}
function pkg::install() {
	(($# == 0)) && return 2

	case "${PKG_MGR^^}" in
		APK) apk add "${1,,}" ;;
		APT) pkg::apt install "${1,,}" ;;
		DNF) dnf install -y "${1,,}" ;;
		OPKG) opkg install "${1,,}" ;;
		PACMAN) pacman -S --noconfirm "${1,,}" ;;
		YUM) yum install -y "${1,,}" ;;
		ZYPPER) zypper --non-interactive install -y "${1,,}" ;;
	esac
}
function pkg::last_update() {
	str::grid ^ End-Date {2,3} </var/log/apt/history.log && return 0
	str::grid ^ 1 {1,2} </var/log/dpkg.log && return 0
	rpm -qa --last | head -n 1 | str::grid 1 {3..7} && return 0

	io::err "取得最後更新時間失敗" && return 1
}
function pkg::remove() {
	(($# == 0)) && return 2

	case "${PKG_MGR^^}" in
		APK) apk del "${1,,}" ;;
		APT) pkg::apt purge "${1,,}" && pkg::apt autoremove ;;
		DNF) dnf remove -y "${1,,}" ;;
		OPKG) opkg remove "${1,,}" ;;
		PACMAN) pacman -Rns --noconfirm "${1,,}" ;;
		YUM) yum remove -y "${1,,}" ;;
		ZYPPER) zypper --non-interactive remove -y "${1,,}" ;;
	esac
}
function pkg::update() {
	((EUID != 0 || $(id -u) != 0)) && return 1

	case "${PKG_MGR^^}" in
		APK) apk update ;;
		APT) pkg::apt update ;;
		DNF) dnf check-update -y ;;
		OPKG) opkg update ;;
		PACMAN) : ;;
		YUM) yum check-update -y ;;
		ZYPPER) zypper refresh ;;
	esac
}
function pkg::upgrade() {
	((EUID != 0 || $(id -u) != 0)) && return 1

	if pkg::update; then
		case "${PKG_MGR^^}" in
			APK) apk upgrade ;;
			APT) pkg::apt full-upgrade ;;
			DNF) dnf upgrade -y ;;
			OPKG) : ;;
			PACMAN) pacman -Syu --noconfirm ;;
			YUM) yum upgrade -y ;;
			ZYPPER) zypper dup -y --no-allow-vendor-change ;;
		esac
	fi
}
