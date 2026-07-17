#!/usr/bin/env bash
# VERSION="1.0.0a1"

# shellcheck source=/dev/null
# set -Eeuo pipefail
# set +u
set -o pipefail
shopt -s expand_aliases

[[ -f ~/utilkit.sh ]] || bash <(wget -qO- utilkit.ogtt.tk/sh &>/dev/null)
source ~/utilkit.sh

declare UNIT_PREF="IB"

function DLine() { io::txt "${1:-${CLR[8]}}========================${CLR[0]}"; }
function SLine() { io::txt "${1:-${CLR[8]}}--------------------------------${CLR[0]}"; }
function Finish() { io::txt "${CLR[2]}完成${CLR[0]}"; }

function AddFile() {
	(($# == 0)) && return 2
	local item parent_dir

	for item in "$@"; do
		io::txt "${CLR[3]}新增檔案 '${item}'${CLR[0]}"
		fs::path_exist "${item}" && io::err "檔案或目錄 '${item}' 已存在" && return 1
		parent_dir="${item%/*}"

		if [[ ${parent_dir} != "${item}" ]] && ! fs::dir_exist "${parent_dir}"; then
			mkdir -p "${parent_dir}" || io::err_die "無法建立父目錄 '${parent_dir}'。請檢查權限" || return 1
		fi

		if : >"${item}"; then
			io::txt "- 檔案 '${item}' 建立成功"
		else
			io::err "建立檔案 '${item}' 失敗。請檢查權限和磁碟空間" && return 1
		fi
	done
	Finish
}
function AddDir() {
	(($# == 0)) && return 2
	local item

	for item in "$@"; do
		io::txt "${CLR[3]}新增目錄 '${item}'${CLR[0]}"

		fs::path_exist "${item}" && io::err "檔案或目錄 '${item}' 已存在" && return 1

		if mkdir -p "${item}"; then
			io::txt "- 目錄 '${item}' 建立成功"
		else
			io::err "建立目錄 '${item}' 失敗。請檢查權限和路徑有效性" && return 1
		fi
	done
	Finish
}
function AddPkg() {
	((EUID != 0 || $(id -u) != 0)) && return 1
	(($# == 0)) && return 2
	local pkg

	for pkg in "$@"; do
		io::txt "${CLR[3]}安裝套件 '${pkg}'${CLR[0]}"

		if pkg::is_installed "${pkg}"; then
			io::txt "- 套件 ${pkg} 已經安裝"
		else
			if pkg::install "${item}"; then
				io::txt "- 套件 ${pkg} 安裝成功"
			else
				io::err "使用 ${PKG_MGR} 安裝 ${pkg} 失敗" && return 1
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
			-*) io::err "無效的選項：$1" && return 1 ;;
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
		io::txt "${msg}\t${dep}"
	done

	((${#missg_deps[@]} == 0)) && return 0

	case "${mode}" in
		1)
			io::raw "\n"
			AddPkg "${missg_deps[@]}"
			;;
		2)
			io::txt "\n${CLR[3]}缺少的套件：${CLR[0]} ${missg_deps[*]}"
			read -p "是否要安裝缺少的套件？(y/N) " -nr 1 cont_inst
			io::raw "\n"
			[[ ${cont_inst} =~ ^[Yy]$ ]] && AddPkg "${missg_deps[@]}"
			;;
	esac
}
function Clear() {
	cd "${1:-${HOME}}" || io::err_die "切換目錄失敗" || return 1
	clear
}
function Download() {
	local targ_dir="." rnm_file url oup_file oup_path
	while (($# > 0)); do
		case "$1" in
			-r | --rename)
				[[ -z $1 || $1 == -* ]] && io::err "-r 選項後未指定檔案名稱" && return 1
				rnm_file="$1"
				shift 2
				;;
			-*) io::err "無效的選項：$1" && return 1 ;;
			*)
				if var::empty "${url}"; then
					url="$1" || targ_dir="$1"
				fi
				shift
				;;
		esac
	done

	var::empty "${url}" && io::err "未指定 URL。請提供要下載的 URL" && return 1
	[[ ${url} =~ ^(http|https|ftp):// ]] || url="https://${url}"
	oup_file="${url##*/}"
	var::empty "${oup_file}" && oup_file="index.html"
	if [[ ${targ_dir} != "." ]]; then
		mkdir -p "${targ_dir}"
	else
		io::err "建立目錄 ${targ_dir} 失敗" && return 1
	fi
	var::valid "${rnm_file}" && oup_file="${rnm_file}"
	oup_path="${targ_dir}/${oup_file}"
	url=$(io::txt "${url}" | sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
	io::txt "${CLR[3]}下載 '${url}'${CLR[0]}"

	net::url_get -c "${url}" -O "${oup_path}" || return 1
}
function ConvSz() {
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
function DelFile() {
	(($# == 0)) && return 2

	local item
	for item in "$@"; do
		io::txt "${CLR[3]}刪除檔案 '${item}'${CLR[0]}"
		if fs::file_exist "${item}"; then
			if rm -f "${item}"; then
				io::txt "- 檔案 '${item}' 刪除成功"
			else
				io::err "刪除檔案 ${item} 失敗。請檢查權限" && return 1
			fi
		else
			io::err "- 檔案 '${item}' 不存在\n" && return 1
		fi
	done
	Finish
}
function DelDir() {
	(($# == 0)) && return 2

	local item
	for item in "$@"; do
		io::txt "${CLR[3]}刪除目錄 '${item}'${CLR[0]}"
		if fs::dir_exist "${item}"; then
			if rm -rf "${item}"; then
				io::txt "- 目錄 '${item}' 刪除成功"
			else
				io::err "刪除目錄 '${item}' 失敗。請檢查權限\n" && return 1
			fi
		else
			io::err "目錄 '${item}' 不存在\n" && return 1
		fi
		Finish
	done
}
function DelPkg() {
	((EUID != 0 || $(id -u) != 0)) && return 1
	(($# == 0)) && return 2
	local pkg

	for pkg in "$@"; do
		io::txt "${CLR[3]}移除套件 '${pkg}'${CLR[0]}"

		if pkg::is_installed "${pkg}"; then
			if pkg::remove "${pkg}"; then
				io::txt "- 套件 ${pkg} 移除成功"
			else
				io::err "使用 ${PKG_MGR} 移除 ${pkg} 失敗" && return 1
			fi
		else
			io::txt "- 套件 ${pkg} 不存在"
		fi
	done
	Finish
}
function SysClean() {
	# TODO: refactor this
	((EUID != 0 || $(id -u) != 0)) && return 1
	io::txt "${CLR[3]}正在執行系統清理...${CLR[0]}"
	DLine

	case "${PKG_MGR^^}" in
		APK)
			Task "- 清理 ${PKG_MGR} 快取" "apk cache clean" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 移除暫存檔案" "rm -rf /tmp/* /var/cache/apk/*" || io::err_die "移除暫存檔案失敗" || return 1
			Task "- 修復 ${PKG_MGR} 套件" "apk fix" || io::err_die "修復 ${PKG_MGR} 套件失敗" || return 1
			;;
		APT)
			Task "- 設定待處理的套件" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a" || io::err_die "設定待處理套件失敗" || return 1
			Task "- 自動移除套件" "pkg::apt autoremove --purge" || io::err_die "自動移除套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "pkg::apt clean" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 自動清理 ${PKG_MGR} 快取" "pkg::apt autoclean" || io::err_die "自動清理 ${PKG_MGR} 快取失敗" || return 1
			;;
		OPKG)
			Task "- 移除暫存檔案" "rm -rf /tmp/*" || io::err_die "移除暫存檔案失敗" || return 1
			Task "- 更新 ${PKG_MGR}" "opkg update" || io::err_die "更新 ${PKG_MGR} 失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "opkg clean" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			;;
		PACMAN)
			Task "- 更新和升級套件" "pacman -Syu --noconfirm" || io::err_die "使用 ${PKG_MGR} 更新和升級套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "pacman -Sc --noconfirm" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 清理所有 ${PKG_MGR} 快取" "pacman -Scc --noconfirm" || io::err_die "清理所有 ${PKG_MGR} 快取失敗" || return 1
			;;
		DNF)
			Task "- 自動移除套件" "dnf autoremove -y" || io::err_die "自動移除套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "dnf clean all" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 建立 ${PKG_MGR} 快取" "dnf makecache" || io::err_die "建立 ${PKG_MGR} 快取失敗" || return 1
			;;
		YUM)
			Task "- 自動移除套件" "yum autoremove -y" || io::err_die "自動移除套件失敗" || return 1
			Task "- 清理 ${PKG_MGR} 快取" "yum clean all" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 建立 ${PKG_MGR} 快取" "yum makecache" || io::err_die "建立 ${PKG_MGR} 快取失敗" || return 1
			;;
		ZYPPER)
			Task "- 清理 ${PKG_MGR} 快取" "zypper clean --all" || io::err_die "清理 ${PKG_MGR} 快取失敗" || return 1
			Task "- 重新整理 ${PKG_MGR} 套件庫" "zypper refresh" || io::err_die "重新整理 ${PKG_MGR} 套件庫失敗" || return 1
			;;
	esac

	if command -v journalctl &>/dev/null; then
		Task "- 輪替和清理 journalctl 日誌" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M" || io::err_die "輪替和清理 journalctl 日誌失敗（系統找不到 journalctl 指令）" || return 1
	fi

	local cmd
	for cmd in docker npm pip; do
		command -v "${cmd}" &>/dev/null && case "${cmd^^}" in
			DOCKER) Task "- 清理 DOCKER 系統" "docker system prune -af" || io::err_die "清理 DOCKER 系統失敗" || return 1 ;;
			NPM) Task "- 清理 NPM 快取" "npm cache clean --force" || io::err_die "清理 NPM 快取失敗" || return 1 ;;
			PIP) Task "- 清除 PIP 快取" "pip cache purge" || io::err_die "清除 PIP 快取失敗" || return 1 ;;
		esac
	done

	Task "- 移除使用者快取檔案" "rm -rf ~/.cache/*" || io::err_die "移除使用者快取檔案失敗" || return 1
	Task "- 移除暫存檔案" "rm -rf /tmp/*" || io::err_die "移除暫存檔案失敗" || return 1
	Task "- 移除縮圖檔案" "rm -rf ~/.thumbnails/*" || io::err_die "移除縮圖檔案失敗" || return 1

	Dline
	Finish
}
function SysInfo() {
	io::txt "${CLR[3]}系統資訊${CLR[0]}"
	DLine

	io::txt "- 主機名稱：            ${CLR[2]}$(uname -n || hostname)${CLR[0]}"
	io::txt "- 作業系統：            ${CLR[2]}$(sys::distro)${CLR[0]}"
	io::txt "- 核心版本：            ${CLR[2]}$(uname -r)${CLR[0]}"
	io::txt "- 系統語言：            ${CLR[2]}${LANG}${CLR[0]}"
	io::txt "- Shell 版本：          ${CLR[2]}$(sys::shell_ver)${CLR[0]}"
	io::txt "- 最後系統更新：        ${CLR[2]}$(pkg::last_update)${CLR[0]}"

	SLine

	io::txt "- 架構：                ${CLR[2]}$(uname -m)${CLR[0]}"
	io::txt "- CPU 型號：            ${CLR[2]}$(sys::cpu_model)${CLR[0]}"
	io::txt "- CPU 核心數：          ${CLR[2]}$(nproc)${CLR[0]}"
	io::txt "- CPU 頻率：            ${CLR[2]}$(sys::cpu_freq)${CLR[0]}"
	io::txt "- CPU 使用率：          ${CLR[2]}$(sys::cpu_usage)%${CLR[0]}"
	io::txt "- CPU 快取：            ${CLR[2]}$(sys::cpu_cache)${CLR[0]}"

	SLine

	io::txt "- RAM 使用率：          ${CLR[2]}$(sys::mem_info)${CLR[0]}"
	io::txt "- SWAP 使用率：         ${CLR[2]}$(sys::swap_info)${CLR[0]}"
	io::txt "- DISK 使用率：         ${CLR[2]}$(sys::disk_info)${CLR[0]}"
	io::txt "- 檔案系統類型：        ${CLR[2]}$(str::grid 2 2 < <(df -T /))${CLR[0]}"

	SLine

	io::txt "- IPv4 地址：           ${CLR[2]}$(net::ip --ipv4)${CLR[0]}"
	io::txt "- IPv6 地址：           ${CLR[2]}$(net::ip --ipv6)${CLR[0]}"
	io::txt "- MAC 位址：            ${CLR[2]}$(net::mac)${CLR[0]}"
	io::txt "- 網路供應商：          ${CLR[2]}$(net::provider)${CLR[0]}"
	io::txt "- DNS 伺服器：          ${CLR[2]}$(net::dns)${CLR[0]}"
	io::txt "- 公開 IP：             ${CLR[2]}$(net::ip --public)${CLR[0]}"
	io::txt "- 網路介面：            ${CLR[2]}$(net::iface -i)${CLR[0]}"
	io::txt "- 內部時區：            ${CLR[2]}$(sys::timezone --internal)${CLR[0]}"
	io::txt "- 外部時區：            ${CLR[2]}$(sys::timezone --external)${CLR[0]}"

	SLine

	io::txt "- 負載平均：            ${CLR[2]}$(sys::load)${CLR[0]}"
	io::txt "- 程序數量：            ${CLR[2]}$(wc -l < <(ps aux --no-headers))${CLR[0]}"
	io::txt "- 已安裝套件：          ${CLR[2]}$(pkg::count)${CLR[0]}"

	SLine

	io::txt "- 啟動時刻：            ${CLR[2]}$(who -b | str::trim "boot  ")${CLR[0]}"
	io::txt "- 運行時間：            ${CLR[2]}$(uptime -p | str::trim "up ")${CLR[0]}"

	SLine

	io::txt "- 虛擬化：              ${CLR[2]}$(sys::virt)${CLR[0]}"

	DLine
}
function SysOptz() {
	((EUID != 0 || $(id -u) != 0)) && return 1

	io::txt "${CLR[3]}正在優化長期運行伺服器的系統設定...${CLR[0]}" && DLine

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
			dev_type=$(cat "${disk}/queue/rotational" 2>/dev/null || io::txt "1")
			if io::txt "${dev_type}" | str::grep -q "0"; then
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
		fs::file_grep -q "${swapfile}" /etc/fstab || cat <<<"${swapfile} none swap sw 0 0" >>/etc/fstab
	}

	Task "- 正在產生核心參數與網路優化設定... " "_ApplySysctlConf" || return 1
	Task "- 正在產生系統資源限制設定... " "_ApplySystemLimits" || return 1
	Task "- 正在優化儲存裝置 I/O 排程器... " "_OptimizeDisk" || return 1
	Task "- 正在停用背景非必要服務... " "_DisableService" || return 1
	Task "- 正在優化 SSH 連線與安全性設定... " "_OptimizeSSH" || return 1
	Task "- 正在配置日誌上限以保護磁碟空間... " "_OptimizeJournal" || return 1
	Task "- 正在建置系統應急 Swap 緩衝空間... " "_EnsureSwap" || return 1
	Task "- 正在將核心參數載入系統運作... " "sysctl --system" || return 1
	Task "- 正在清理網路鄰居快取快門... " "ip -s -s neigh flush all" || return 1

	Dline
	Finish
}
function SysRboot() {
	((EUID != 0 || $(id -u) != 0)) && return 1
	local -r active_usrs="$(who | wc -l)" important_procs="$(ps aux --no-headers | awk '$3 > 1.0 || $4 > 1.0' | wc -l)"
	local cont

	io::txt "${CLR[3]}正在準備重新啟動系統...${CLR[0]}" && DLine

	if ((active_usrs != 0)); then
		io::txt "${CLR[3]}警告：目前系統有 ${active_usrs} 個活動使用者${CLR[0]}"
		io::raw "\n"
		io::txt "活動使用者："
		str::grid 1 {1,3,4} < <(who)
		io::raw "\n"
	fi

	if ((important_procs != 0)); then
		io::txt "${CLR[3]}警告：有 ${important_procs} 個重要程序正在執行${CLR[0]}"
		io::raw "\n"
		io::txt "${CLR[8]}CPU 使用率最高的 5 個程序：${CLR[0]}"
		ps aux --sort=-%cpu | head -n 6
		io::raw "\n"
	fi

	read -p "您確定要立即重新啟動系統嗎？(y/N) " -nr 1 cont
	io::raw "\n"

	if ! [[ ${cont} =~ ^[Yy]$ ]]; then
		io::txt "${CLR[2]}已取消重新啟動${CLR[0]}"
		io::raw "\n"
		return 0
	fi

	Task "- 執行最終檢查" "sync" || io::err_die "同步檔案系統失敗" || return 1
	Task "- 開始重新啟動" "reboot || sudo reboot" || io::err_die "啟動重新啟動失敗" || return 1
	io::txt "${CLR[2]}已成功發出重新啟動命令。系統將立即重新啟動${CLR[0]}"
}
function SysUpd() {
	((EUID != 0 || $(id -u) != 0)) && return 1

	local -r current_lang="${LANG}" update_url="https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh"

	io::txt "${CLR[3]}正在更新系統套件...${CLR[0]}"
	DLine

	pkg::upgrade
	net::url_get -qO- "${update_url}" | bash -s -- "${current_lang}" || io::err_die "更新 UtilKit.sh 失敗" || return 1

	Dline
	Finish
}
function SysUpg() {
	((EUID != 0 || $(id -u) != 0)) && return 1

	io::txt "${CLR[3]}正在升級系統至下一個主要版本...${CLR[0]}" && DLine

	os_nm=$(sys::distro --name)
	case "${os_nm^^}" in
		DEBIAN)
			io::txt "- 偵測到 DEBIAN 系統"
			io::txt "- 正在更新套件清單"
			pkg::updatee || io::err_die "使用 APT 更新套件清單失敗" || return 1
			io::txt "- 正在升級目前的套件"
			pkg::upgrade || io::err_die "升級目前的套件失敗" || return 1
			io::txt "- 開始 DEBIAN 發行版升級..."
			curr_codenm=$(lsb_release -cs)
			targ_codenm=$(str::query "Codename" < <(net::url_get -qO- "https://ftp.debian.org/debian/dists/stable/Release"))
			[[ ${curr_codenm} == "${targ_codenm}" ]] && io::err "系統已達最新穩定版 (本地/遠端穩定版：${curr_codenm}/${targ_codenm}" && return 1
			io::txt "- 正在從 ${CLR[2]}${curr_codenm}${CLR[0]} 升級到 ${CLR[3]}${targ_codenm}${CLR[0]}"
			Task "- 備份 sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup" || io::err_die "備份 sources.list 失敗" || return 1
			Task "- 更新 sources.list" "sed -i 's/${curr_codenm}/${targ_codenm}/g' /etc/apt/sources.list" || io::err_die "更新 sources.list 失敗" || return 1
			Task "- 更新套件清單" "pkg::update" || io::err_die "更新新版本的套件清單失敗" || return 1
			pkg::upgrade || io::err_die "升級到新的 DEBIAN 版本失敗" || return 1
			;;
		UBUNTU)
			io::txt "- 偵測到 UBUNTU 系統"
			Task "- 正在更新套件清單" "pkg::update" || io::err_die "使用 APT 更新套件清單失敗" || return 1
			Task "- 正在升級目前的套件" "pkg::upgrade" || io::err_die "升級目前的套件失敗" || return 1
			Task "- 安裝 update-manager-core" "pkg::install update-manager-core" || io::err_die "安裝 update-manager-core 失敗" || return 1
			do-release-upgrade -f DistUpgradeViewNonInteractive || io::err_die "升級 UBUNTU 版本失敗" || return 1
			SysRboot
			;;
		*) io::err "您的系統尚不支援主要版本升級" && return 1 ;;
	esac
	Dline
	Finish
}
function Task() {
	(($# == 0)) && return 2
	local -r msg="$1" ignore_error="${2:-false}"
	shift 2 # 移出前兩個參數，剩下的 "$@" 就是完整的命令與其參數

	local ret tmp_file

	if ! tmp_file=$(mktemp); then
		io::err "無法建立臨時檔案" && return 1
	fi

	# 注意：在 Bash 中，函式內的 trap '...' RETURN
	# 需要在 Bash 4.4+ 或有設定 set -T / trap_return 的情況下才完全可靠。
	# 建議保留或確保環境支援。
	trap 'rm -f "${tmp_file}"' RETURN

	io::raw "${msg}... "

	# 關鍵改動：直接執行 "$@"，完全不透過 eval，絕對安全且支援帶有空白的參數
	if "$@" >"${tmp_file}" 2>&1; then
		Finish
		ret=0
	else
		ret=$?
		io::txt "${CLR[1]}失敗${CLR[0]} (${ret})"
		[[ -s "${tmp_file}" ]] && io::txt "${CLR[1]}$(cat "${tmp_file}")${CLR[0]}"
		[[ ${ignore_error} == "true" ]] || return "${ret}"
	fi
	return "${ret}"
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
			[[ ${arg} == "-h" || ${arg} == "--help" ]] && help_requested=1 && break
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
			printf "io::error: %s\n\n" "${error_msg}" >&2
			local -r should_exit_1=1
		else
			return 0
		fi
	fi

	io::txt "Usage: ${app_name:-\$0} [OPTIONS] COMMAND"
	io::raw "\n"

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
		io::txt "Commands:"
		for ((i = 0; i < ${#cmds[@]}; i++)); do
			_PrintAlignedLine "${cmds[i]}" "${cmd_descs[i]}"
		done
		io::raw "\n"
	fi

	if ((${#opts[@]} > 0)); then
		io::txt "Options:"
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
function Press() {
	if ! read -p "$1" -n 1 -r; then
		io::err "讀取使用者輸入失敗" && return 1
	fi
}
