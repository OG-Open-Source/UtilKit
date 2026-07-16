#!/usr/bin/env bash
# VERSION="8.0.0a9"

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
	for v in "$@"; do [[ -z "${v}" ]] || return 1; done
}
function var::set() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do [[ -v "${v}" ]] || return 1; done
}
function var::valid() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do [[ -n "${v}" ]] || return 1; done
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
	var::valid "${1:-}" && stdin_buffer="${stdin_buffer#*"$1"}"
	var::valid "${2:-}" && stdin_buffer="${stdin_buffer%%"$2"*}"

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

	if var::valid "${part2}"; then
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

		local remaining_args=("${@:2}")
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
function str::query() (
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
	elif fs::file_exist "${data_source}"; then
		_parse "${pattern}" <"${data_source}"
	else
		_parse "${pattern}" <<<"${data_source}"
	fi
)

function util::conv_size() {
	(($# == 0)) && return 2
	# TODO: change these variables
	local size="$1" default_pref="${UNIT_PREF:-b}" && local unit="${2:-${default_pref}}"

	((size < 0)) && io::err "大小值不能為負數：${size}" && return 1

	local -r LC_ALL=C
	awk -v size="${size}" -v unit="${unit,,}" '
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
    ' || io::err_die "不支持的單位或格式錯誤：size=${size} unit=${unit,,}" || return 1
}
function util::parse_opts() {
	local -n _utilkit_io_parse_opts_ref="$1" || return 1
	shift
	local -r _spec="$1"
	shift

	# 初始化關聯陣列 (修復 SC2154)
	_utilkit_io_parse_opts_ref=()
	_utilkit_io_parse_opts_ref["_args"]="" # 用來收集非旗標的定位參數

	# 預先將 Spec 中所有定義的旗標初始化為預設狀態
	local _spec_item
	for _spec_item in ${_spec}; do
		local _opt_def="${_spec_item%:}"
		local _has_arg=0
		[[ ${_spec_item} == *":" ]] && _has_arg=1

		local _short_opt="${_opt_def%|*}"
		local _long_opt="${_opt_def#*|}"

		if ((_has_arg == 1)); then
			_utilkit_io_parse_opts_ref["${_short_opt}"]=""
			_utilkit_io_parse_opts_ref["${_long_opt}"]=""
		else
			_utilkit_io_parse_opts_ref["${_short_opt}"]="0"
			_utilkit_io_parse_opts_ref["${_long_opt}"]="0"
		fi
	done

	while (($# > 0)); do
		local token="$1"

		# 1. 處理旗標終止符 (Standard -- terminator)
		if [[ ${token} == "--" ]]; then
			shift
			_utilkit_io_parse_opts_ref["_args"]+=" $*"
			break
		fi

		# 2. 處理單一 "-" 或 "+" (視為普通定位參數，而非旗標)
		if [[ ${token} == "-" || ${token} == "+" ]]; then
			_utilkit_io_parse_opts_ref["_args"]+=" ${token}"
			shift
			continue
		fi

		# 3. 識別前綴與行為數值 (-/-- 為 1，+/++ 為 0)
		local prefix="" action_val=1 is_long=0
		if [[ ${token} =~ ^\+\+[a-zA-Z0-9] ]]; then
			prefix="++"
			action_val=0
			is_long=1
		elif [[ ${token} =~ ^--[a-zA-Z0-9] ]]; then
			prefix="--"
			action_val=1
			is_long=1
		elif [[ ${token} =~ ^\+[a-zA-Z0-9] ]]; then
			prefix="+"
			action_val=0
			is_long=0
		elif [[ ${token} =~ ^-[a-zA-Z0-9] ]]; then
			prefix="-"
			action_val=1
			is_long=0
		else
			# 非旗標，歸入定位參數 (修復 SC2154)
			_utilkit_io_parse_opts_ref["_args"]+=" ${token}"
			shift
			continue
		fi

		# 4. 解析是否有等號賦值 "=" (如 -a=1 或 --space=2,format)
		local opt_part="" val_part="" has_equal=0
		if [[ ${token} == *"="* ]]; then
			opt_part="${token%%=*}"
			val_part="${token#*=}"
			has_equal=1
		else
			opt_part="${token}"
		fi

		# 去除前綴字元 (修復 SC2295)
		opt_part="${opt_part#"${prefix}"}"

		# 5. 執行分流解析 (長旗標 vs 短旗標組合) (修復 SC2004)
		if ((is_long == 1)); then
			# -- 長旗標處理 (單一長旗標，不支援組合)
			local opt_name="${opt_part}"
			local matched=0
			local spec_item
			for spec_item in ${_spec}; do
				local opt_def="${spec_item%:}"
				local has_arg=0
				[[ ${spec_item} == *":" ]] && has_arg=1

				local short_opt="${opt_def%|*}"
				local long_opt="${opt_def#*|}"

				if [[ ${opt_name} == "${long_opt}" ]]; then
					matched=1
					if ((has_arg == 1)); then
						# 如果帶有等號，則進行賦值，否則退化為布林開關
						if ((has_equal == 1)); then
							_utilkit_io_parse_opts_ref["${short_opt}"]="${val_part}"
							_utilkit_io_parse_opts_ref["${long_opt}"]="${val_part}"
						else
							_utilkit_io_parse_opts_ref["${short_opt}"]="${action_val}"
							_utilkit_io_parse_opts_ref["${long_opt}"]="${action_val}"
						fi
					else
						# 標準布林開關
						_utilkit_io_parse_opts_ref["${short_opt}"]="${action_val}"
						_utilkit_io_parse_opts_ref["${long_opt}"]="${action_val}"
					fi
					break
				fi
			done

			if ((matched == 0)); then
				io::err "未知的長旗標: ${prefix}${opt_name}"
				return 1
			fi

		else
			# -- 短旗標處理 (依舊支援連續組合，如 -abc 或 +bc)
			local len=${#opt_part}
			local i
			for ((i = 0; i < len; i++)); do
				local char="${opt_part:i:1}"
				local matched=0
				local spec_item
				for spec_item in ${_spec}; do
					local opt_def="${spec_item%:}"
					local has_arg=0
					[[ ${spec_item} == *":" ]] && has_arg=1

					local short_opt="${opt_def%|*}"
					local long_opt="${opt_def#*|}"

					if [[ ${char} == "${short_opt}" ]]; then
						matched=1
						if ((has_arg == 1)); then
							if ((has_equal == 1)); then
								_utilkit_io_parse_opts_ref["${short_opt}"]="${val_part}"
								_utilkit_io_parse_opts_ref["${long_opt}"]="${val_part}"
							else
								# 沒有等號的情況：
								if ((i == len - 1)); then
									# 如果是最後一個字元且後面「已斷開」，退化為布林開關
									_utilkit_io_parse_opts_ref["${short_opt}"]="${action_val}"
									_utilkit_io_parse_opts_ref["${long_opt}"]="${action_val}"
								else
									# 如果後面緊跟著其他字元「未斷開」(e.g., -s123)，視後續字元為參數值
									local remaining="${opt_part:i+1}"
									_utilkit_io_parse_opts_ref["${short_opt}"]="${remaining}"
									_utilkit_io_parse_opts_ref["${long_opt}"]="${remaining}"
									i=len # 強制結束字元迴圈
								fi
							fi
						else
							# 布林開關 (設為 1 或 0)
							_utilkit_io_parse_opts_ref["${short_opt}"]="${action_val}"
							_utilkit_io_parse_opts_ref["${long_opt}"]="${action_val}"
						fi
						break
					fi
				done

				if ((matched == 0)); then
					io::err "未知的短旗標: ${prefix}${char}"
					return 1
				fi
			done
		fi

		# 由於移除了吞噬邏輯，每次處理完一個 token 後固定 shift 1
		shift 1
	done

	# 清理定位參數前後多餘空格
	_utilkit_io_parse_opts_ref["_args"]="${_utilkit_io_parse_opts_ref["_args"]# }"
	_utilkit_io_parse_opts_ref["_args"]="${_utilkit_io_parse_opts_ref["_args"]% }"
}
function util::validate() {
	local -r _format_or_regex="$1"
	local -r _val="$2"
	local -r _out_var="$3"
	local -r _pcre_flag="${4:-0}"

	# 若格式或正規表示式為空，安全清除輸出變數並回傳 2
	if var::empty "${_format_or_regex}"; then
		if var::valid "${_out_var}"; then
			if [[ ${_out_var} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
				local -n _utilkit_util_validate_err_ref="${_out_var}"
				_utilkit_util_validate_err_ref=""
			fi
		fi
		return 2
	fi

	local _pattern

	# 1. 取得基礎 Pattern
	case "${_format_or_regex,,}" in
		"ipv6") _pattern='(([[:xdigit:]]{1,4}:){7}[[:xdigit:]]{1,4}|([[:xdigit:]]{1,4}:){1,7}:|([[:xdigit:]]{1,4}:){1,6}:[[:xdigit:]]{1,4}|([[:xdigit:]]{1,4}:){1,5}(:[[:xdigit:]]{1,4}){1,2}|([[:xdigit:]]{1,4}:){1,4}(:[[:xdigit:]]{1,4}){1,3}|([[:xdigit:]]{1,4}:){1,3}(:[[:xdigit:]]{1,4}){1,4}|([[:xdigit:]]{1,4}:){1,2}(:[[:xdigit:]]{1,4}){1,5}|[[:xdigit:]]{1,4}:((:[[:xdigit:]]{1,4}){1,6})|:((:[[:xdigit:]]{1,4}){1,7}|:)|fe80:(:[[:xdigit:]]{0,4}){0,4}%[[:alnum:]]+|::(ffff(:0{1,4})?:)?((25[0-5]|(2[0-4]|1?[[:digit:]])?[[:digit:]])\.){3}(25[0-5]|(2[0-4]|1?[[:digit:]])?[[:digit:]])|([[:xdigit:]]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1?[[:digit:]])?[[:digit:]])\.){3}(25[0-5]|(2[0-4]|1?[[:digit:]])?[[:digit:]]))' ;;
		"ipv4") _pattern='(25[0-5]|2[0-4][[:digit:]]|[01]?[[:digit:]][[:digit:]]?)(\.(25[0-5]|2[0-4][[:digit:]]|[01]?[[:digit:]][[:digit:]]?)){3}' ;;
		"email") _pattern='[^@[[:space:]]]+@[^@[[:space:]]]+\.[^@[[:space:]]]+' ;;
		"int") _pattern='-?[[:digit:]]+' ;;
		*) _pattern="${_format_or_regex}" ;;
	esac

	# 2. 自動安全加註 ^ 與 $
	if [[ ${_pattern} != "^"* ]] || [[ ${_pattern} != *'$' ]]; then
		local _inner="${_pattern#^}"
		_inner="${_inner%$}"
		_pattern="^(${_inner})$"
	fi

	# 3. 執行匹配（根據 flag 進行分流）
	local _is_match=1
	if ((_pcre_flag == 1)) || [[ ${_pcre_flag} == "true" ]]; then
		str::grep -qP -- "${_pattern}" <<<"${_val}" && _is_match=0
	else
		[[ ${_val} =~ ${_pattern} ]] && _is_match=0
	fi

	# 4. 處理輸出與回傳狀態
	if ((_is_match == 0)); then
		# -- 成功 (Match) --
		if var::valid "${_out_var}"; then
			# 安全檢查變數名稱，避免惡意注入
			if [[ ${_out_var} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
				local -n _utilkit_util_validate_ok_ref="${_out_var}"
				_utilkit_util_validate_ok_ref="${_val}"
			fi
		else
			# 未指定變數時，直接輸出至 stdout
			io::txt "${_val}"
		fi
		return 0
	else
		# -- 失敗 (No Match) --
		if var::valid "${_out_var}"; then
			if [[ ${_out_var} =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
				local -n _utilkit_util_validate_fail_ref="${_out_var}"
				_utilkit_util_validate_fail_ref=""
			fi
		fi
		return 1
	fi
}
function util::harden_session() {
	function curl() { false; }
	function eval() { false; }
	function grep() { false; }
	function wget() { false; }
}
function net::url_get() { command wget --timeout=15 --tries=3 --waitretry=5 --retry-on-http-error=429,500,502,503,504 --max-redirect=5 "$@"; }

function sys::cpu_cache() {
	fs::file_exist /proc/cpuinfo || io::err_die "無法存取 CPU 資訊。" || return 1
	local -r cpu_cache="$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)"
	[[ ${cpu_cache} == "N/A" ]] && io::err "無法確定 CPU 快取大小" && return 1
	io::txt "${cpu_cache} KB"
}
function sys::cpu_freq() {
	fs::file_exist /proc/cpuinfo || io::err_die "無法存取 CPU 資訊。" || return 1
	local -r cpu_freq="$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)"
	[[ ${cpu_freq} == "N/A" ]] && io::err "無法確定 CPU 頻率" && return 1
	io::txt "${cpu_freq} GHz"
}
function sys::cpu_model() {
	str::query "Model name" < <(lscpu) && return 0
	str::query "model name" </proc/cpuinfo && return 0

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
		*) io::txt "$(util::conv_size "${usd}") / $(util::conv_size "${tot}") (${pct}%)" ;;
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
		*) io::txt "$(util::conv_size "${usd}") / $(util::conv_size "${tot}") (${pct}%)" ;;
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
		*) io::txt "$(util::conv_size "${usd}") / $(util::conv_size "${tot}") (${pct}%)" ;;
	esac
}
function sys::distro() {
	case "$1" in
		-v | --version)
			if fs::file_exist /etc/os-release; then
				local -r os_id="$(str::query "ID" </etc/os-release)"
				case "${os_id^^}" in
					DEBIAN) cat /etc/debian_version ;;
					FEDORA) fs::file_grep -oE '[0-9]+' /etc/fedora-release ;;
					CENTOS) fs::file_grep -oE '[0-9]+\.[0-9]+' /etc/centos-release ;;
					ALPINE) cat /etc/alpine-release ;;
					*) io::txt "${VERSION_ID}" ;;
				esac
			elif fs::file_exist /etc/debian_version; then
				cat /etc/debian_version
			elif fs::file_exist /etc/fedora-release; then
				fs::file_grep -oE '[0-9]+' /etc/fedora-release
			elif fs::file_exist /etc/centos-release; then
				fs::file_grep -oE '[0-9]+\.[0-9]+' /etc/centos-release
			elif fs::file_exist /etc/alpine-release; then
				cat /etc/alpine-release
			else
				io::err "Unknown" && return 1
			fi
			;;
		-n | --name)
			if fs::file_exist /etc/os-release; then
				str::query "NAME" </etc/os-release
			elif fs::file_exist /etc/DISTRO_SPECS; then
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
function sys::timezone() (
	(($# == 0)) && return 2

	_DetectExternal() {
		net::url_get -qO- "https://ipapi.co/json" | str::query "timezone" && return 0
		net::url_get -qO- "http://ip-api.com/json" | str::trim '"timezone":"' '",' && return 0
		return 1
	}
	_DetectInternal() {
		readlink /etc/localtime | str::trim "zoneinfo/" && return 0
		timedatectl status | str::grid "Time zone" 2 ":" && return 0
		fs::file_grep -v "^#" /etc/timezone | tr -d " " && return 0
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
)
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
				if fs::file_grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
					io::txt "LXC 容器"
				elif fs::file_grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
					io::txt "虛擬機器（未知類型）"
				else
					io::txt "未偵測到（可能為實體機器）"
				fi
				;;
			*) io::txt "${virt_typ}" ;;
		esac
	elif fs::file_exist /proc/cpuinfo; then
		if fs::file_grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null; then
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
	for d in "$@"; do [[ -d "${d}" ]] || return 1; done
}
function fs::file_exist() {
	(($# == 0)) && return 2
	local f
	for f in "$@"; do [[ -f "${f}" ]] || return 1; done
}
function fs::file_valid() {
	(($# == 0)) && return 2
	local f
	for f in "$@"; do [[ -s "${f}" ]] || return 1; done
}
function fs::file_grep() {
	(($# < 2)) && return 2
	command -v grep &>/dev/null || return 126
	local -r file="${!#}"
	[[ ! (-f "${file}" && -r "${file}" && -s "${file}") ]] && return 2
	command grep "$@"
}
function fs::path_exist() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -e "${p}" || -L "${p}" ]] || return 1; done
}
function fs::perm_read() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -r "${p}" ]] || return 1; done
}
function fs::perm_write() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -w "${p}" ]] || return 1; done
}
function fs::perm_exec() {
	(($# == 0)) && return 2
	local p
	for p in "$@"; do [[ -x "${p}" ]] || return 1; done
}

# ----------------------------------------------------------------------
#  Namespace: net (Networking & Downloads)
# ----------------------------------------------------------------------
function net::dns() {
	fs::file_exist /etc/resolv.conf || io::err_die "找不到 DNS 設定檔" || return 1

	local -A opts
	local dns4=() dns6=()
	util::parse_opts opts "4|ipv4 6|ipv6" "$@" || return 1

	local first second _
	while read -r first second _; do
		# 忽略以 # 或 ; 開頭的註解行，以及空白行
		[[ ${first} =~ ^[#\;] ]] && continue
		var::empty "${first}" && continue

		if [[ ${first} == "nameserver" ]]; then
			if util::validate "ipv4" "${second}"; then
				dns4+=("${second}")
			elif util::validate "ipv6" "${second}"; then
				dns6+=("${second}")
			fi
		fi
	done </etc/resolv.conf

	((${#dns4[@]} == 0 && ${#dns6[@]} == 0)) && io::err "/etc/resolv.conf 中未設定 DNS 伺服器" && return 1

	if ((opts[ipv4] != 0)); then
		((${#dns4[@]} == 0)) && io::err "找不到 IPv4 DNS 伺服器" && return 1
		io::txt "${dns4[*]}"
	elif ((opts[ipv6] != 0)); then
		((${#dns6[@]} == 0)) && io::err "找不到 IPv6 DNS 伺服器" && return 1
		io::txt "${dns6[*]}"
	else
		# 若其中一個為空，避免輸出多餘的空格
		if ((${#dns4[@]} > 0 && ${#dns6[@]} > 0)); then
			io::txt "${dns4[*]}   ${dns6[*]}"
		else
			io::txt "${dns4[*]}${dns6[*]}"
		fi
	fi
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
					io::txt "${iface}: RX: $(util::conv_size "${rx_bytes}"), TX: $(util::conv_size "${tx_bytes}")"
				fi
			done
			;;
		*) io::txt "${interface}" ;;
	esac
}
function net::ip() {
	local -r apis=("api64.ipify.org" "ifconfig.me/ip" "api.ipinfo.io/ip")
	local ip4_addr ip6_addr api raw_ip

	local -A opts
	util::parse_opts opts "4|ipv4 6|ipv6 p|public" "$@" || return 1

	if ((opts[ipv4] != 0)); then
		for api in "${apis[@]}"; do
			raw_ip=$(net::url_get -qO- -4 "${api}" 2>/dev/null)
			util::validate "ipv4" "${raw_ip}" ip4_addr && break
		done

		io::txt "${ip4_addr:-N/A}"
	elif ((opts[ipv6] != 0)); then
		for api in "${apis[@]}"; do
			raw_ip=$(net::url_get -qO- -6 "${api}" 2>/dev/null)
			util::validate "ipv6" "${raw_ip}" ip6_addr && break
		done

		io::txt "${ip6_addr:-N/A}"
	elif ((opts[public] != 0)); then
		str::query "ip" < <(net::url_get -qO- "https://developers.cloudflare.com/cdn-cgi/trace")
	else
		for api in "${apis[@]}"; do
			raw_ip=$(net::url_get -qO- -4 "${api}" 2>/dev/null)
			util::validate "ipv4" "${raw_ip}" ip4_addr && break
		done

		for api in "${apis[@]}"; do
			raw_ip=$(net::url_get -qO- -6 "${api}" 2>/dev/null)
			util::validate "ipv6" "${raw_ip}" ip6_addr && break
		done

		var::empty "${ip4_addr}${ip6_addr}" && io::err "取得 IP 位址失敗" && return 1
		io::raw "IPv4: " && io::txt "${ip4_addr:-N/A}"
		io::raw "IPv6: " && io::txt "${ip6_addr:-N/A}"
	fi
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

# ----------------------------------------------------------------------
#  Namespace: app (Package Manager Wrappers)
# ----------------------------------------------------------------------
function app::install_docker() {
	true
}

function app::docker() {
	true
}
