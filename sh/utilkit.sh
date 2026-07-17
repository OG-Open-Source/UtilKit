#!/usr/bin/env bash
# VERSION="8.0.0a10"

# shellcheck source=/dev/null
# set -Eeuo pipefail
# set +u
set -o pipefail
shopt -s expand_aliases

declare -A UT_CODE=() UT_INFO=()
declare BASH=0 PKG_MGR="unknown" LANG="${LANG:-C.UTF-8}"
declare UT_ERR_CODE=0
declare _
export UT_CODE
export UT_ERR_CODE
export UT_INFO

((BASH == 0)) && printf "%b\n" "\x1b[38;2;204;51;51mUnsupported Bash version!\x1b[0m" && return 126
[[ ${PKG_MGR} == "unknown" ]] && printf "%b\n" "\x1b[38;2;204;51;51mUnknown package manager!\x1b[0m" && return 127

source /dev/stdin <<< "$(wget -qO- utilkit.ogtt.tk/sh/core.sh 2>/dev/null)"

# ----------------------------------------------------------------------
#  Namespace: ut (Utility & Custom Error Handling)
# ----------------------------------------------------------------------
function ut::set_code() {
	local -r type_name="${1:-}"
	local -r code_val="${2:-}"
	[[ -n "${type_name}" ]] || return 1
	UT_CODE["${type_name^^}"]="${code_val}"
}
function ut::get_code() {
	local -r type_name="${1:-}"
	[[ -n "${type_name}" ]] || return 1
	io::txt "${UT_CODE["${type_name^^}"]:-}"
}
function ut::clear_codes() {
	UT_CODE=()
}

# @description 抽象化生成高精度 UTC 時間與格式化紀錄至 UT_INFO 以及寫入永續檔案
# @params $1: 函數名稱 (e.g. net::url_get)
# @params $2: 類型 (ERROR 或 WARN)
# @params $3: 精確故障代碼 [A-Z]{4}[0-9]{4} (e.g. NEUG2000)
# @params $4: 詳情訊息 (details)
function ut::log_info() {
	local -r func_name="${1:-}"
	local -r type_name="${2:-}"
	local -r code_val="${3:-}"
	local -r details_msg="${4:-}"
	
	[[ -n "${func_name}" && -n "${type_name}" && -n "${code_val}" ]] || return 1

	# 1. 獲取高精度微秒級 UTC 時間，格式 YYYY-MM-DDTHH:mm:ssssss+00:00
	local raw_nanos nanos current_utc_time
	raw_nanos=$(date -u +'%N' 2>/dev/null)
	if [[ -z "${raw_nanos}" || "${raw_nanos}" == "N" ]]; then
		nanos="000000"
	else
		nanos="${raw_nanos:0:6}"
	fi
	current_utc_time="$(date -u +'%Y-%m-%dT%H:%M:%S').${nanos}+00:00"

	# 2. 更新 UT_CODE 狀態碼 (與 ut::set_code 對稱同步)
	ut::set_code "${type_name}" "${code_val}"

	# 3. 生成符合規範的 UT_INFO 項目與 DELIMITER
	local info_entry
	read -r -d '' info_entry <<-EOF
		function_name: ${func_name}
		datatime: ${current_utc_time}
		code: ${code_val}
		details: ${details_msg}
		---
	EOF

	# 追加至對應函數的 UT_INFO 全局暫存器
	UT_INFO["${func_name}"]+="${info_entry}"$'\n'

	# 4. 將錯誤儲存到文件中 (日誌防禦性校驗)
	local log_file="/var/log/utilkit.sh.log"
	local log_msg="[${current_utc_time}] [${type_name^^}] ${func_name}: ${details_msg} (code: ${code_val})"
	
	# 如果在當前工作目錄下建立日誌，或具有 root 寫入權限，執行永久性文件記錄
	if [[ -w "/var/log" ]]; then
		printf "%s\n" "${log_msg}" >> "${log_file}" 2>/dev/null
	elif [[ -w "." ]]; then
		# 如果無系統 /var/log 寫入權限，fallback 到工作目錄下的日誌文件
		printf "%s\n" "${log_msg}" >> "./utilkit.sh.log" 2>/dev/null
	fi
}

declare -gA CLR=(
	[0]="\x1b[0m"
	[1]="\x1b[38;2;204;51;51m"
	[2]="\x1b[38;2;51;204;85m"
	[3]="\x1b[38;2;255;204;51m"
	[4]="\x1b[0;34m"
	[5]="\x1b[0;3\x1b[38;2;136;68;221"
	[6]="\x1b[0;36m"
	[7]="\x1b[0;37m"
	[8]="\x1b[38;2;0;102;204m"
	[9]="\x1b[0;97m"

	[reset]="\x1b[0m" [rst]="\x1b[0m"
	[bold]="\x1b[1m"
	[dim]="\x1b[2m"
	[italic]="\x1b[3m"
	[underline]="\x1b[4m"
	[blink]="\x1b[5m"
	[reverse]="\x1b[7m"
	[hidden]="\x1b[8m"

	[new]="\x1b[38;2;136;68;221"
	[disb]="\x1b[38;2;102;119;153m" [disable]="\x1b[38;2;102;119;153m" [dis]="\x1b[38;2;102;119;153m"
	[eror]="\x1b[38;2;204;51;51m" [error]="\x1b[38;2;204;51;51m" [err]="\x1b[38;2;204;51;51m"
	[info]="\x1b[38;2;0;102;204m" [information]="\x1b[38;2;0;102;204m" [inf]="\x1b[38;2;0;102;204m"
	[sucs]="\x1b[38;2;51;204;85m" [success]="\x1b[38;2;51;204;85m" [scs]="\x1b[38;2;51;204;85m"
	[warn]="\x1b[38;2;255;204;51m" [warning]="\x1b[38;2;255;204;51m" [wrn]="\x1b[38;2;255;204;51m"

	[black]="\x1b[30m" [bg_black]="\x1b[40m"
	[red]="\x1b[31m" [bg_red]="\x1b[41m"
	[green]="\x1b[32m" [bg_green]="\x1b[42m"
	[yellow]="\x1b[33m" [bg_yellow]="\x1b[43m"
	[blue]="\x1b[34m" [bg_blue]="\x1b[44m"
	[magenta]="\x1b[35m" [bg_magenta]="\x1b[45m"
	[cyan]="\x1b[36m" [bg_cyan]="\x1b[46m"
	[white]="\x1b[37m" [bg_white]="\x1b[47m"

	[bright_black]="\x1b[90m" [bg_bright_black]="\x1b[100m"
	[bright_red]="\x1b[91m" [bg_bright_red]="\x1b[101m"
	[bright_green]="\x1b[92m" [bg_bright_green]="\x1b[102m"
	[bright_yellow]="\x1b[93m" [bg_bright_yellow]="\x1b[103m"
	[bright_blue]="\x1b[94m" [bg_bright_blue]="\x1b[104m"
	[bright_magenta]="\x1b[95m" [bg_bright_magenta]="\x1b[105m"
	[bright_cyan]="\x1b[96m" [bg_bright_cyan]="\x1b[106m"
	[bright_white]="\x1b[97m" [bg_bright_white]="\x1b[107m"
)

# ----------------------------------------------------------------------
#  Namespace: var/io/str
# ----------------------------------------------------------------------
function str::grep() {
	var::valid "$@"

	command grep "$@"
}
function str::trim() {
	var::valid "$@"

	local stdin_buffer
	stdin_buffer=$(cat)
	var::valid "${1:-}" && stdin_buffer="${stdin_buffer#*"$1"}"
	var::valid "${2:-}" && stdin_buffer="${stdin_buffer%%"$2"*}"

	io::txt "${stdin_buffer}"
}
function str::grid() {
	local has_modifiers=0

	(($# > 0)) && [[ $1 =~ ^([_<>^][0-9]*)([_<>^][0-9]*)?$ ]] && has_modifiers=1 && shift 1

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

	_parse() {
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

# ----------------------------------------------------------------------
#  Namespace: util ()
# ----------------------------------------------------------------------
function util::conv_size() {
	var::valid "$@"
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
	shift 1
	local -r _spec="$1"
	shift 1

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
			shift 1
			_utilkit_io_parse_opts_ref["_args"]+=" $*"
			break
		fi

		# 2. 處理單一 "-" 或 "+" (視為普通定位參數，而非旗標)
		if [[ ${token} == "-" || ${token} == "+" ]]; then
			_utilkit_io_parse_opts_ref["_args"]+=" ${token}"
			shift 1
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
			shift 1
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

			((matched == 0)) && io::err "未知的長旗標: ${prefix}${opt_name}" && return 1
		else
			# -- 短旗標處理 (依舊支援連續組合，如 -abc 或 +bc)
			local len=${#opt_part}
			local i
			for ((i = 0; i < len; i++)); do
				local -i matched=0
				local char="${opt_part:i:1}" spec_item
				for spec_item in ${_spec}; do
					local -i has_arg=0
					local opt_def="${spec_item%:}"
					[[ ${spec_item} == *":" ]] && has_arg=1

					local short_opt="${opt_def%|*}" long_opt="${opt_def#*|}"

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

				((matched == 0)) && io::err "未知的短旗標: ${prefix}${char}" && return 1
			done
		fi

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

function net::url_get() {
	# 1. 宣告局部變數，並遵循顯式型別優先之順序： -i > none
	local -i arg_idx=0 status_code=0 url_found=0
	local args=("$@")
	local last_arg url_to_check proto

	# 2. 衛語句：輸入範圍安全檢查 (若參數為空，直接回傳錯誤狀態碼 20)
	if (($# == 0)); then
		UT_ERR_CODE=20
		# 使用全域且高度抽象化的 ut::log_info 處理時間、代碼更新、UT_INFO 儲存、以及永續文件寫入
		ut::log_info "net::url_get" "ERROR" "NEUG2000" "net::url_get 失敗：參數列表為空"
		io::err "net::url_get 失敗：參數列表為空"
		return 20
	fi

	# 3. 輸入長度與極值防禦：長度限制 2048 字元，避免緩衝區溢位
	last_arg="${args[$(($# - 1))]}"
	if ((${#last_arg} > 2048)); then
		UT_ERR_CODE=21
		ut::log_info "net::url_get" "ERROR" "NEUG2100" "net::url_get 失敗：參數長度超過限制"
		io::err "net::url_get 失敗：參數長度超過限制"
		return 21
	fi

	# 4. 輸入範圍安全性檢驗：識別並驗證 URL
	# 遍歷參數以找到最後一個非選項參數作為目標 URL
	for ((arg_idx = $# - 1; arg_idx >= 0; arg_idx--)); do
		if [[ ${args[arg_idx]} != -* ]]; then
			url_to_check="${args[arg_idx]}"
			url_found=1
			break
		fi
	done

	if ((url_found == 0)) || [[ -z "${url_to_check}" ]]; then
		UT_ERR_CODE=22
		ut::log_info "net::url_get" "ERROR" "NEUG2200" "net::url_get 失敗：未在參數中找到目標 URL"
		io::err "net::url_get 失敗：未在參數中找到目標 URL"
		return 22
	fi

	# 5. 通訊協定與字元範圍檢驗：僅允許 HTTP 與 HTTPS 協定，避免 file://, gopher:// 等 SSRF 漏洞
	if [[ ${url_to_check} =~ ^([a-zA-Z0-9+.-]+):// ]]; then
		proto="${BASH_REMATCH[1]}"
		proto="${proto,,}" # 轉小寫
		if [[ ${proto} != "http" && ${proto} != "https" ]]; then
			UT_ERR_CODE=23
			ut::log_info "net::url_get" "ERROR" "NEUG2300" "net::url_get 失敗：不支援的通訊協定 '${proto}'"
			io::err "net::url_get 失敗：不支援的通訊協定 '${proto}'"
			return 23
		fi
	else
		# 預設若沒有寫 scheme，直接視為不安全或無效 URL
		UT_ERR_CODE=24
		ut::log_info "net::url_get" "ERROR" "NEUG2400" "net::url_get 失敗：URL 缺少通訊協定開頭"
		io::err "net::url_get 失敗：URL 缺少通訊協定開頭"
		return 24
	fi

	# URL 安全字元集範圍驗證（防止 command injection 和非法字元）
	# 用最通用安全且相容的字元檢驗，若含有 $、`、\、'、"、<、> 或分號等危險命令注入字元，直接拒絕
	if [[ ${url_to_check} == *['$`"'\\]* || ${url_to_check} == *";"* || ${url_to_check} == *"<"* || ${url_to_check} == *">"* ]]; then
		UT_ERR_CODE=25
		ut::log_info "net::url_get" "ERROR" "NEUG2500" "net::url_get 失敗：URL 中偵測到不安全/非法的字元"
		io::err "net::url_get 失敗：URL 中偵測到不安全/非法的字元"
		return 25
	fi

	# 6. try ... catch ... 實作區段
	# 在 Bash 中利用子 Shell 環境執行 wget，並補捉其結束狀態
	# 子 Shell 隔離了執行環境，即使發生異常中斷或 SIGPIPE，也能被父 Shell 順利 catch
	if command wget --timeout=15 --tries=3 --waitretry=5 --retry-on-http-error=429,500,502,503,504 --max-redirect=5 "${args[@]}"; then
		UT_ERR_CODE=0
		return 0
	else
		# Catch Block
		# 捕獲 wget 的 exit status
		status_code=$?
		UT_ERR_CODE="${status_code}"

		# 透過高度抽象的公用處理器，為當次呼叫追加入 ERROR 與獨占性的 WARN 代碼，並安全地將其記錄至 /var/log/utilkit.sh.log 永久檔案
		ut::log_info "net::url_get" "ERROR" "NEUG3000" "net::url_get 失敗：wget 結束狀態碼為 ${status_code}，請求之 URL 為 '${url_to_check}'"
		ut::log_info "net::url_get" "WARN" "NEUG3001" "net::url_get 警告：下載任務異常中斷，請確認遠端伺服器可用性"

		# 回傳 wget 的原始狀態碼
		return "${status_code}"
	fi
}

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
	var::valid "$@"

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
#  Namespace: net (Networking & Downloads)
# ----------------------------------------------------------------------
function net::dns() {
	local -A opts && util::parse_opts opts "4|ipv4 6|ipv6" "$@"

	fs::file_exist /etc/resolv.conf || io::err_die "找不到 DNS 設定檔" || return 1

	local dns4=() dns6=()
	local first second _

	while read -r first second _; do
		# 忽略以 # 或 ; 開頭的註解行，以及空白行
		[[ ${first} =~ ^[#\;] ]] && continue
		var::empty "${first}" && continue

		if [[ ${first} == "nameserver" ]]; then
			if util::validate "ipv4" "${second}" &>/dev/null; then
				dns4+=("${second}")
			elif util::validate "ipv6" "${second}" &>/dev/null; then
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
	local interfaces=()
	local default4_route default6_route i iface iface_name interface interface4 interface6 interfaces_num item line physical_iface stats
	local rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop

	while read -r line; do
		if [[ ${line} =~ ^[[:space:]]*([^:]+): ]]; then
			iface_name="${BASH_REMATCH[1]}"
			iface_name="${iface_name//[[:space:]]/}"
			[[ ${iface_name} =~ ^(lo|sit|stf|gif|dummy|vmnet|vir|gre|ipip|ppp|bond|tun|tap|ip6gre|ip6tnl|teql|ocserv|vpn|warp|wgcf|wg|docker|br-|veth) ]] && continue
			interfaces+=("${iface_name}")
		fi
	done </proc/net/dev

	interfaces_num=${#interfaces[@]}

	default4_route=$(ip -4 route show default 2>/dev/null || io::raw "")
	default6_route=$(ip -6 route show default 2>/dev/null || io::raw "")

	for item in "${interfaces[@]}"; do
		var::empty "${item}" && continue

		if var::valid "${default4_route}" && var::empty "${interface4}"; then
			# 使用具有空白/邊界安全性的 regex 匹配 "dev <iface>"
			[[ ${default4_route} =~ [[:space:]]dev[[:space:]]${item}([[:space:]]|$) ]] && interface4="${item}"
		fi
		if var::valid "${default6_route}" && var::empty "${interface6}"; then
			[[ ${default6_route} =~ [[:space:]]dev[[:space:]]${item}([[:space:]]|$) ]] && interface6="${item}"
		fi

		var::valid "${interface4}" "${interface6}" && break
	done

	if var::empty "${interface4}${interface6}"; then
		for item in "${interfaces[@]}"; do
			if [[ ${item} =~ ^en ]]; then
				interface4="${item}"
				interface6="${item}"
				break
			fi
		done
		# 若依然沒找到 en 開頭的介面，且介面清單不為空，則預設採用第一個介面
		if var::empty "${interface4}" && ((interfaces_num > 0)); then
			interface4="${interfaces[0]}"
			interface6="${interfaces[0]}"
		fi
	fi

	if var::valid "${interface4}" || var::valid "${interface6}"; then
		if [[ ${interface4} == "${interface6}" ]]; then
			interface="${interface4}"
		else
			interface="${interface4} ${interface6}"
			# 原生去除可能的多餘首尾空格
			interface="${interface#"${interface%%[![:space:]]*}"}"
			interface="${interface%"${interface##*[![:space:]]}"}"
		fi
	else
		# 5. 實體介面 fallback 備援：以原生讀取與 regex 擷取，取代 ip | grep | grep | head | grid 管道
		local line_link iface_link state_link first_iface_link
		while read -r line_link; do
			if [[ ${line_link} =~ lo|docker|br-|veth|bond|tun|tap ]]; then
				continue
			fi
			if [[ ${line_link} =~ ^[0-9]+:[[:space:]]*([^:]+):.*state[[:space:]]([A-Z]+) ]]; then
				iface_link="${BASH_REMATCH[1]}"
				iface_link="${iface_link//[[:space:]]/}"
				state_link="${BASH_REMATCH[2]}"

				[[ ${state_link} == "UP" ]] && var::empty "${physical_iface}" && physical_iface="${iface_link}"
				var::empty "${first_iface_link}" && first_iface_link="${iface_link}"
			fi
		done < <(ip -o link show 2>/dev/null)

		if var::valid "${physical_iface}"; then
			interface="${physical_iface}"
		else
			interface="${first_iface_link}"
		fi
	fi

	case "$1" in
		--rx_bytes | --rx_packets | --rx_drop | --tx_bytes | --tx_packets | --tx_drop)
			for iface in ${interface}; do
				local stats=""
				while read -r line; do
					# 去除首部空格以防陣列分割時產生的偏移
					local trimmed="${line#"${line%%[![:space:]]*}"}"
					if [[ ${trimmed} == "${iface}":* ]]; then
						read -r -a arr <<<"${trimmed}"
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
				local stats=""
				while read -r line; do
					local trimmed="${line#"${line%%[![:space:]]*}"}"
					if [[ ${trimmed} == "${iface}":* ]]; then
						read -r -a arr <<<"${trimmed}"
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
	local -A opts && util::parse_opts opts "4|ipv4 6|ipv6 p|public" "$@"

	local -r apis=("https://api64.ipify.org" "https://ifconfig.me/ip" "https://api.ipinfo.io/ip")
	local ip4_addr ip6_addr api raw_ip

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
	var::valid "$@"
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
	var::valid "$@"

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
	var::valid "$@"

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
	var::valid "$@"

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
