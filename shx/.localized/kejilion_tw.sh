#!/bin/bash
sh_v="4.0.2"

gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'

canshu="default"
permission_granted="false"
ENABLE_STATS="true"

[ -f ~/utilkit.sh ] && source ~/utilkit.sh || bash <(curl -sL ${gh_proxy}https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh) && source ~/utilkit.sh

UNIT_PREF="B"

quanju_canshu() {
	if [ "$canshu" = "CN" ]; then
		zhushi=0
		gh_proxy="https://gh.kejilion.pro/"
	elif [ "$canshu" = "V6" ]; then
		zhushi=1
		gh_proxy="https://gh.kejilion.pro/"
	else
		zhushi=1 # 0 表示执行，1 表示不执行
		gh_proxy="https://"
	fi

}
quanju_canshu

# 定义一个函数来执行命令
run_command() {
	if [ "$zhushi" -eq 0 ]; then
		"$@"
	fi
}

canshu_v6() {
	if grep -q '^canshu="V6"' /usr/local/bin/k >/dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/kejilion.sh
	fi
}

CheckFirstRun_true() {
	if grep -q '^permission_granted="true"' /usr/local/bin/k >/dev/null 2>&1; then
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
	fi
}

# 收集功能埋点信息的函数，记录当前脚本版本号，使用时间，系统版本，CPU架构，机器所在国家和用户使用的功能名称，绝对不涉及任何敏感信息，请放心！请相信我！
# 为什么要设计这个功能，目的更好的了解用户喜欢使用的功能，进一步优化功能推出更多符合用户需求的功能。
# 全文可搜搜 send_stats 函数调用位置，透明开源，如有顾虑可拒绝使用。

send_stats() {
	if [ "$ENABLE_STATS" == "false" ]; then
		return
	fi
	(
		curl -s -X POST "https://api.kejilion.pro/api/log" \
			-H "Content-Type: application/json" \
			-d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$(Loc --country)\",\"os_info\":\"$(ChkOs)\",\"cpu_arch\":\"$(uname -m)\",\"version\":\"$sh_v\"}" \
			&>/dev/null
	) &
}

yinsiyuanquan2() {
	if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k >/dev/null 2>&1; then
		sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
	fi
}

canshu_v6
CheckFirstRun_true
yinsiyuanquan2

sed -i '/^alias k=/d' ~/.bashrc >/dev/null 2>&1
sed -i '/^alias k=/d' ~/.profile >/dev/null 2>&1
sed -i '/^alias k=/d' ~/.bash_profile >/dev/null 2>&1
cp -f ./kejilion.sh ~/kejilion.sh >/dev/null 2>&1
cp -f ~/kejilion.sh /usr/local/bin/k >/dev/null 2>&1

CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k >/dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# 提示用户同意条款
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}歡迎使用科技lion腳本工具箱${gl_bai}"
	echo "首次使用腳本，請先閱讀並同意使用者授權合約。"
	echo "使用者授權合約: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	Ask "是否同意以上條款？(y/N): " user_input

	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "许可同意"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "许可拒绝"
		clear
		exit
	fi
}

CheckFirstRun_false

ip_address() {

	get_public_ip() {
		curl -s https://ipinfo.io/ip && echo
	}

	get_local_ip() {
		ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' ||
			hostname -I 2>/dev/null | awk '{print $1}' ||
			ifconfig 2>/dev/null | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1
	}

	public_ip=$(get_public_ip)
	isp_info=$(curl -s --max-time 3 http://ipinfo.io/org)

	if echo "$isp_info" | grep -Eiq 'china|mobile|unicom|telecom'; then
		ipv4_address=$(get_local_ip)
	else
		ipv4_address="$public_ip"
	fi

	# ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
	ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}

install() {
	if [ $# -eq 0 ]; then
		echo "未提供套件參數！"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}正在安裝 $package...${gl_bai}"
			if command -v dnf &>/dev/null; then
				dnf -y update
				dnf install -y epel-release
				dnf install -y "$package"
			elif command -v yum &>/dev/null; then
				yum -y update
				yum install -y epel-release
				yum install -y "$package"
			elif command -v apt &>/dev/null; then
				apt update -y
				apt install -y "$package"
			elif command -v apk &>/dev/null; then
				apk update
				apk add "$package"
			elif command -v pacman &>/dev/null; then
				pacman -Syu --noconfirm
				pacman -S --noconfirm "$package"
			elif command -v zypper &>/dev/null; then
				zypper refresh
				zypper install -y "$package"
			elif command -v opkg &>/dev/null; then
				opkg update
				opkg install "$package"
			elif command -v pkg &>/dev/null; then
				pkg update
				pkg install -y "$package"
			else
				echo "未知的套件管理器！"
				return 1
			fi
		fi
	done
}

check_disk_space() {

	required_gb=$1
	required_space_mb=$((required_gb * 1024))
	available_space_mb=$(df -m / | awk 'NR==2 {print $4}')

	if [ $available_space_mb -lt $required_space_mb ]; then
		echo -e "${gl_huang}提示: ${gl_bai}磁碟空間不足！"
		echo "目前可用空間: $((available_space_mb / 1024))G"
		echo "最小需求空間: ${required_gb}G"
		echo "無法繼續安裝，請清理磁碟空間後重試。"
		send_stats "磁盘空间不足"
		break_end
		kejilion
	fi
}

install_dependency() {
	install wget unzip tar jq grep
}

remove() {
	if [ $# -eq 0 ]; then
		echo "未提供套件參數！"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}正在卸載 $package...${gl_bai}"
		if command -v dnf &>/dev/null; then
			dnf remove -y "$package"
		elif command -v yum &>/dev/null; then
			yum remove -y "$package"
		elif command -v apt &>/dev/null; then
			apt purge -y "$package"
		elif command -v apk &>/dev/null; then
			apk del "$package"
		elif command -v pacman &>/dev/null; then
			pacman -Rns --noconfirm "$package"
		elif command -v zypper &>/dev/null; then
			zypper remove -y "$package"
		elif command -v opkg &>/dev/null; then
			opkg remove "$package"
		elif command -v pkg &>/dev/null; then
			pkg delete -y "$package"
		else
			echo "未知的套件管理器！"
			return 1
		fi
	done
}

# 通用 systemctl 函数，适用于各种发行版
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}

# 重启服务
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服務已重新啟動。"
	else
		echo "錯誤：重新啟動 $1 服務失敗。"
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服務已啟動。"
	else
		echo "錯誤：啟動 $1 服務失敗。"
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服務已停止。"
	else
		echo "錯誤：停止 $1 服務失敗。"
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服務狀態已顯示。"
	else
		echo "錯誤：無法顯示 $1 服務狀態。"
	fi
}

enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
		/bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME 已設定為開機自動啟動。"
}

break_end() {
	echo -e "${gl_lv}操作完成${gl_bai}"
	Press "按任意鍵繼續..."
	echo
	clear
}

kejilion() {
	cd ~
	kejilion_sh
}

check_port() {
	install lsof

	stop_containers_or_kill_process() {
		local port=$1
		local containers=$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null)

		if [ -n "$containers" ]; then
			docker stop $containers
		else
			for pid in $(lsof -t -i:$port); do
				kill -9 $pid
			done
		fi
	}

	stop_containers_or_kill_process 80
	stop_containers_or_kill_process 443
}

install_add_docker_cn() {

	local country=$(curl -s ipinfo.io/country)
	if [ "$country" = "CN" ]; then
		NO_TRAN=$'{\n  "registry-mirrors": [\n    "https://docker-0.unsee.tech",\n    "https://docker.1panel.live",\n    "https://registry.dockermirror.com",\n    "https://docker.imgdb.de",\n    "https://docker.m.daocloud.io",\n    "https://hub.firefly.store",\n    "https://hub.littlediary.cn",\n    "https://hub.rat.dev",\n    "https://dhub.kubesre.xyz",\n    "https://cjie.eu.org",\n    "https://docker.1panelproxy.com",\n    "https://docker.hlmirror.com",\n    "https://hub.fast360.xyz",\n    "https://dockerpull.cn",\n    "https://cr.laoyou.ip-ddns.com",\n    "https://docker.melikeme.cn",\n    "https://docker.kejilion.pro"\n  ]\n}'
		echo -e "$NO_TRAN" | sudo tee /etc/docker/daemon.json >/dev/null
	fi

	enable docker
	start docker
	restart docker

}

install_add_docker_guanfang() {
	local country=$(curl -s ipinfo.io/country)
	if [ "$country" = "CN" ]; then
		cd ~
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/install && chmod +x install
		sh install --mirror Aliyun
		rm -f install
	else
		curl -fsSL https://get.docker.com | sh
	fi
	install_add_docker_cn

}

install_add_docker() {
	echo -e "${gl_huang}正在安裝docker環境...${gl_bai}"
	if [ -f /etc/os-release ] && grep -q "Fedora" /etc/os-release; then
		install_add_docker_guanfang
	elif command -v dnf &>/dev/null; then
		dnf update -y
		dnf install -y yum-utils device-mapper-persistent-data lvm2
		rm -f /etc/yum.repos.d/docker*.repo >/dev/null
		country=$(curl -s ipinfo.io/country)
		arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo | tee /etc/yum.repos.d/docker-ce.repo >/dev/null
		else
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null
		fi
		dnf install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn

	elif [ -f /etc/os-release ] && grep -q "Kali" /etc/os-release; then
		apt update
		apt upgrade -y
		apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
		rm -f /usr/share/keyrings/docker-archive-keyring.gpg
		local country=$(curl -s ipinfo.io/country)
		local arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			fi
		else
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list >/dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg >/dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
			fi
		fi
		apt update
		apt install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn

	elif command -v apt &>/dev/null || command -v yum &>/dev/null; then
		install_add_docker_guanfang
	else
		install docker docker-compose
		install_add_docker_cn

	fi
	sleep 2
}

install_docker() {
	if ! command -v docker &>/dev/null; then
		install_add_docker
	fi
}

docker_ps() {
	while true; do
		clear
		send_stats "Docker容器管理"
		echo "Docker 容器列表"
		docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
		echo
		echo "容器操作"
		echo "------------------------"
		echo "1. 建立新的容器"
		echo "------------------------"
		echo "2. 啟動指定容器             6. 啟動所有容器"
		echo "3. 停止指定容器             7. 停止所有容器"
		echo "4. 刪除指定容器             8. 刪除所有容器"
		echo "5. 重新啟動指定容器             9. 重新啟動所有容器"
		echo "------------------------"
		echo "11. 進入指定容器           12. 查看容器日誌"
		echo "13. 查看容器網路           14. 查看容器佔用"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			send_stats "新建容器"
			Ask "請輸入建立命令: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			Ask "請輸入容器名稱（多個容器名稱請用空格分隔）: " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			Ask "請輸入容器名稱（多個容器名稱請用空格分隔）: " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			Ask "請輸入容器名稱（多個容器名稱請用空格分隔）: " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			Ask "請輸入容器名稱（多個容器名稱請用空格分隔）: " dockername
			docker restart $dockername
			;;
		6)
			send_stats "启动所有容器"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "停止所有容器"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "删除所有容器"
			Ask "${gl_hong}注意: ${gl_bai}確定刪除所有容器嗎？(y/N): " choice
			case "$choice" in
			[Yy])
				docker rm -f $(docker ps -a -q)
				;;
			[Nn]) ;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			Ask "請輸入容器名稱: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			Ask "請輸入容器名稱: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器网络"
			echo
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			echo "容器名稱              網路名稱              IP位址"
			for container_id in $container_ids; do
				local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")
				local container_name=$(echo "$container_info" | awk '{print $1}')
				local network_info=$(echo "$container_info" | cut -d' ' -f2-)
				while IFS= read -r line; do
					local network_name=$(echo "$line" | awk '{print $1}')
					local ip_address=$(echo "$line" | awk '{print $2}')
					printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
				done <<<"$network_info"
			done
			break_end
			;;
		14)
			send_stats "查看容器占用"
			docker stats --no-stream
			break_end
			;;
		*)
			break
			;;
		esac
	done
}

docker_image() {
	while true; do
		clear
		send_stats "Docker镜像管理"
		echo "Docker 映像列表"
		docker image ls
		echo
		echo "映像操作"
		echo "------------------------"
		echo "1. 獲取指定映像             3. 刪除指定映像"
		echo "2. 更新指定映像             4. 刪除所有映像"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			send_stats "拉取镜像"
			Ask "請輸入映像名稱（多個映像名稱請用空格分隔）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在獲取鏡像: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			Ask "請輸入映像名稱（多個映像名稱請用空格分隔）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在更新鏡像: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			Ask "請輸入映像名稱（多個映像名稱請用空格分隔）: " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			Ask "${gl_hong}注意: ${gl_bai}確定刪除所有映像嗎？(y/N): " choice
			case "$choice" in
			[Yy])
				docker rmi -f $(docker images -q)
				;;
			[Nn]) ;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;
		*)
			break
			;;
		esac
	done

}

check_crontab_installed() {
	if ! command -v crontab >/dev/null 2>&1; then
		install_crontab
	fi
}

install_crontab() {

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
		ubuntu | debian | kali)
			apt update
			apt install -y cron
			systemctl enable cron
			systemctl start cron
			;;
		centos | rhel | almalinux | rocky | fedora)
			yum install -y cronie
			systemctl enable crond
			systemctl start crond
			;;
		alpine)
			apk add --no-cache cronie
			rc-update add crond
			rc-service crond start
			;;
		arch | manjaro)
			pacman -S --noconfirm cronie
			systemctl enable cronie
			systemctl start cronie
			;;
		opensuse | suse | opensuse-tumbleweed)
			zypper install -y cron
			systemctl enable cron
			systemctl start cron
			;;
		iStoreOS | openwrt | ImmortalWrt | lede)
			opkg update
			opkg install cron
			/etc/init.d/cron enable
			/etc/init.d/cron start
			;;
		FreeBSD)
			pkg install -y cronie
			sysrc cron_enable="YES"
			service cron start
			;;
		*)
			echo "不支援的發行版: $ID"
			return
			;;
		esac
	else
		echo "無法確定作業系統。"
		return
	fi

	echo -e "${gl_lv}crontab 已安裝且 cron 服務正在運行。${gl_bai}"
}

docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 检查配置文件是否存在，如果不存在则创建文件并写入默认设置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
	else
		# 使用jq处理配置文件的更新
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 检查当前配置是否已经有 ipv6 设置
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 更新配置，开启 IPv6
		if [[ $CURRENT_IPV6 == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 对比原始配置与新配置
		if [[ $ORIGINAL_CONFIG == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}目前已開啟ipv6訪問${gl_bai}"
		else
			echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
			restart docker
		fi
	fi
}

docker_ipv6_off() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"

	# 检查配置文件是否存在
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}設定檔不存在${gl_bai}"
		return
	fi

	# 读取当前配置
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# 使用jq处理配置文件的更新
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 检查当前的 ipv6 状态
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 对比原始配置与新配置
	if [[ $CURRENT_IPV6 == "false" ]]; then
		echo -e "${gl_huang}目前已關閉ipv6訪問${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}已成功關閉ipv6訪問${gl_bai}"
	fi
}

save_iptables_rules() {
	mkdir -p /etc/iptables
	touch /etc/iptables/rules.v4
	iptables-save >/etc/iptables/rules.v4
	check_crontab_installed
	crontab -l | grep -v 'iptables-restore' | crontab - >/dev/null 2>&1
	(
		crontab -l
		echo '@reboot iptables-restore < /etc/iptables/rules.v4'
	) | crontab - >/dev/null 2>&1

}

iptables_open() {
	install iptables
	save_iptables_rules
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F

}

open_port() {
	local ports=($@)
	# 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "請提供至少一個埠號"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的关闭规则
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 添加打开规则
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "已開啟埠 $port"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}

close_port() {
	local ports=($@)
	# 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "請提供至少一個埠號"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 删除已存在的打开规则
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 添加关闭规则
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "已關閉埠 $port"
		fi
	done

	# 删除已存在的规则（如果有）
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 插入新规则到第一条
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "已关闭端口"
}

allow_ip() {
	local ips=($@)
	# 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "請提供至少一個IP位址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "已放行IP $ip"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)
	# 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "請提供至少一個IP位址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "已阻止IP $ip"
		fi
	done

	save_iptables_rules
	send_stats "已阻止IP"
}

enable_ddos_defense() {
	# 开启防御 DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "开启DDoS防御"
}

# 关闭DDoS防御
disable_ddos_defense() {
	# 关闭防御 DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "关闭DDoS防御"
}

# 管理国家IP规则的函数
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
	block)
		# 如果 ipset 不存在则创建
		if ! ipset list "$ipset_name" &>/dev/null; then
			ipset create "$ipset_name" hash:net
		fi

		# 下载 IP 区域文件
		if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
			echo "錯誤：下載 $country_code 的 IP 區域檔案失敗"
			exit 1
		fi

		# 将 IP 添加到 ipset
		while IFS= read -r ip; do
			ipset add "$ipset_name" "$ip"
		done <"${country_code,,}.zone"

		# 使用 iptables 阻止 IP
		iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
		iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

		echo "已成功阻止 $country_code 的 IP 位址"
		rm "${country_code,,}.zone"
		;;

	allow)
		# 为允许的国家创建 ipset（如果不存在）
		if ! ipset list "$ipset_name" &>/dev/null; then
			ipset create "$ipset_name" hash:net
		fi

		# 下载 IP 区域文件
		if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
			echo "錯誤：下載 $country_code 的 IP 區域檔案失敗"
			exit 1
		fi

		# 删除现有的国家规则
		iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
		iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
		ipset flush "$ipset_name"

		# 将 IP 添加到 ipset
		while IFS= read -r ip; do
			ipset add "$ipset_name" "$ip"
		done <"${country_code,,}.zone"

		# 仅允许指定国家的 IP
		iptables -P INPUT DROP
		iptables -P OUTPUT DROP
		iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
		iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

		echo "已成功僅允許 $country_code 的 IP 位址"
		rm "${country_code,,}.zone"
		;;

	unblock)
		# 删除国家的 iptables 规则
		iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
		iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

		# 销毁 ipset
		if ipset list "$ipset_name" &>/dev/null; then
			ipset destroy "$ipset_name"
		fi

		echo "已成功解除 $country_code 的 IP 位址限制"
		;;

	*) ;;
	esac
}

iptables_panel() {
	root_use
	install iptables
	save_iptables_rules
	while true; do
		clear
		echo "進階防火牆管理"
		send_stats "高级防火墙管理"
		echo "------------------------"
		iptables -L INPUT
		echo
		echo "防火牆管理"
		echo "------------------------"
		echo "1.  開放指定埠                 2.  關閉指定埠"
		echo "3.  開放所有埠                 4.  關閉所有埠"
		echo "------------------------"
		echo "5.  IP白名單                  \t 6.  IP黑名單"
		echo "7.  清除指定IP"
		echo "------------------------"
		echo "11. 允許PING                  \t 12. 禁止PING"
		echo "------------------------"
		echo "13. 啟動DDOS防禦                 14. 關閉DDOS防禦"
		echo "------------------------"
		echo "15. 阻止指定國家IP               16. 僅允許指定國家IP"
		echo "17. 解除指定國家IP限制"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			Ask "請輸入開放的埠號: " o_port
			open_port $o_port
			send_stats "开放指定端口"
			;;
		2)
			Ask "請輸入關閉的埠號: " c_port
			close_port $c_port
			send_stats "关闭指定端口"
			;;
		3)
			# 开放所有端口
			current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
			iptables -F
			iptables -X
			iptables -P INPUT ACCEPT
			iptables -P FORWARD ACCEPT
			iptables -P OUTPUT ACCEPT
			iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
			iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
			iptables -A INPUT -i lo -j ACCEPT
			iptables -A FORWARD -i lo -j ACCEPT
			iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
			iptables-save >/etc/iptables/rules.v4
			send_stats "开放所有端口"
			;;
		4)
			# 关闭所有端口
			current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
			iptables -F
			iptables -X
			iptables -P INPUT DROP
			iptables -P FORWARD DROP
			iptables -P OUTPUT ACCEPT
			iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
			iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
			iptables -A INPUT -i lo -j ACCEPT
			iptables -A FORWARD -i lo -j ACCEPT
			iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
			iptables-save >/etc/iptables/rules.v4
			send_stats "关闭所有端口"
			;;

		5)
			# IP 白名单
			Ask "請輸入放行的 IP 或 IP 段: " o_ip
			allow_ip $o_ip
			;;
		6)
			# IP 黑名单
			Ask "請輸入封鎖的 IP 或 IP 段: " c_ip
			block_ip $c_ip
			;;
		7)
			# 清除指定 IP
			Ask "請輸入清除的 IP: " d_ip
			iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
			iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
			iptables-save >/etc/iptables/rules.v4
			send_stats "清除指定IP"
			;;
		11)
			# 允许 PING
			iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
			iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
			iptables-save >/etc/iptables/rules.v4
			send_stats "允许PING"
			;;
		12)
			# 禁用 PING
			iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
			iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
			iptables-save >/etc/iptables/rules.v4
			send_stats "禁用PING"
			;;
		13)
			enable_ddos_defense
			;;
		14)
			disable_ddos_defense
			;;

		15)
			Ask "請輸入阻止的國家代碼（如 CN, US, JP）: " country_code
			manage_country_rules block $country_code
			send_stats "允许国家 $country_code 的IP"
			;;
		16)
			Ask "請輸入允許的國家代碼（如 CN, US, JP）: " country_code
			manage_country_rules allow $country_code
			send_stats "阻止国家 $country_code 的IP"
			;;

		17)
			Ask "請輸入清除的國家代碼（如 CN, US, JP）: " country_code
			manage_country_rules unblock $country_code
			send_stats "清除国家 $country_code 的IP"
			;;

		*)
			break
			;;
		esac
	done

}

add_swap() {
	local new_swap=$1 # 获取传入的参数

	# 获取当前系统中所有的 swap 分区
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍历并删除所有的 swap 分区
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 确保 /swapfile 不再被使用
	swapoff /swapfile

	# 删除旧的 /swapfile
	rm -f /swapfile

	# 创建新的 swap 分区
	fallocate -l ${new_swap}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	sed -i '/\/swapfile/d' /etc/fstab
	echo "/swapfile swap swap defaults 0 0" >>/etc/fstab

	if [ -f /etc/alpine-release ]; then
		echo "nohup swapon /swapfile" >/etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	fi

	echo -e "虛擬記憶體大小已調整為${gl_huang}${new_swap}${gl_bai}M"
}

check_swap() {

	local swap_total=$(free -m | awk 'NR==3{print $2}')

	# 判断是否需要创建虚拟内存
	[ "$swap_total" -gt 0 ] || add_swap 1024

}

ldnmp_v() {

	# 获取nginx版本
	local nginx_version=$(docker exec nginx nginx -v 2>&1)
	local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	# 获取mysql版本
	local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	# 获取php版本
	local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	# 获取redis版本
	local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	echo "------------------------"
	echo

}

install_ldnmp_conf() {

	# 创建必要的目录和文件
	cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
	wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
	wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
	wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf

	default_server_ssl

	# 下载 docker-compose.yml 文件并进行替换
	wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
	dbrootpasswd=$(openssl rand -base64 16)
	dbuse=$(openssl rand -hex 4)
	dbusepasswd=$(openssl rand -base64 8)

	# 在 docker-compose.yml 文件中进行替换
	sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
	sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
	sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}

install_ldnmp() {

	check_swap

	cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

	if ! grep -q "network_mode" /home/web/docker-compose.yml; then
		wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
		dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
		dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')

		sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
		sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
		sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

	fi

	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose1.yml; then
		sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml >/dev/null 2>&1
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml >/dev/null 2>&1
	fi

	cd /home/web && docker compose up -d
	sleep 1
	crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
	(
		crontab -l 2>/dev/null
		echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf'
	) | crontab -

	fix_phpfpm_conf php
	fix_phpfpm_conf php74
	restart_ldnmp

	clear
	echo "LDNMP環境安裝完畢"
	echo "------------------------"
	ldnmp_v

}

install_certbot() {

	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
	chmod +x auto_cert_renewal.sh

	check_crontab_installed
	local cron_job="0 0 * * * ~/auto_cert_renewal.sh"
	crontab -l 2>/dev/null | grep -vF "$cron_job" | crontab -
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "續訂任務已更新"
}

install_ssltls() {
	docker stop nginx >/dev/null 2>&1
	check_port >/dev/null 2>&1
	cd ~

	local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	if [ ! -f "$file_path" ]; then
		local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
		local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
		if [[ $yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern ]]; then
			mkdir -p /etc/letsencrypt/live/$yuming/
			if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
				openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
			else
				openssl genpkey -algorithm Ed25519 -out /etc/letsencrypt/live/$yuming/privkey.pem
				openssl req -x509 -key /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
			fi
		else
			docker run -it --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
		fi
	fi
	mkdir -p /home/web/certs/
	cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1
	cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem >/dev/null 2>&1

	docker start nginx >/dev/null 2>&1
}

install_ssltls_text() {
	echo -e "${gl_huang}$yuming 公鑰資訊${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo
	echo -e "${gl_huang}$yuming 私鑰資訊${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo
	echo -e "${gl_huang}憑證存放路徑${gl_bai}"
	echo "公鑰: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "私鑰: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo
}

add_ssl() {
	echo -e "${gl_huang}快速申請SSL憑證，過期前自動續簽${gl_bai}"
	yuming="${1:-}"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	install_docker
	install_certbot
	docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
	install_ssltls
	certs_status
	install_ssltls_text
	ssl_ps
}

ssl_ps() {
	echo -e "${gl_huang}已申請的憑證到期情況${gl_bai}"
	echo "網站資訊                      憑證到期時間"
	echo "------------------------"
	for cert_dir in /etc/letsencrypt/live/*; do
		local cert_file="$cert_dir/fullchain.pem"
		if [ -f "$cert_file" ]; then
			local domain=$(basename "$cert_dir")
			local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
			local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
			printf "%-30s%s\n" "$domain" "$formatted_date"
		fi
	done
	echo
}

default_server_ssl() {
	install openssl

	if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
		openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
	else
		openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
		openssl req -x509 -key /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
	fi

	openssl rand -out /home/web/certs/ticket12.key 48
	openssl rand -out /home/web/certs/ticket13.key 80

}

certs_status() {

	sleep 1

	local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	if [ -f "$file_path" ]; then
		send_stats "域名证书申请成功"
	else
		send_stats "域名证书申请失败"
		echo -e "${gl_hong}注意: ${gl_bai}憑證申請失敗，請檢查以下可能原因並重試："
		echo -e "1. 域名拼寫錯誤 ➠ 請檢查域名輸入是否正確"
		echo -e "2. DNS解析問題 ➠ 確認域名已正確解析到本伺服器IP"
		echo -e "3. 網路設定問題 ➠ 如使用Cloudflare Warp等虛擬網路請暫時關閉"
		echo -e "4. 防火牆限制 ➠ 檢查80/443埠是否開放，確保驗證可訪問"
		echo -e "5. 申請次數超限 ➠ Let's Encrypt有每週限額(5次/域名/週)"
		echo -e "6. 大陸地區備案限制 ➠ 中國大陸環境請確認域名是否備案"
		break_end
		clear
		echo "請再次嘗試部署 $webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}

repeat_add_yuming() {
	if [ -e /home/web/conf.d/$yuming.conf ]; then
		send_stats "域名重复使用"
		web_del "${yuming}" >/dev/null 2>&1
	fi

}

add_yuming() {
	ip_address
	echo -e "先將域名解析到本机IP: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	Ask "請輸入您的 IP 或解析過的域名: " yuming
}

add_db() {
	dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
	dbname="${dbname}"

	dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}

reverse_proxy() {
	ip_address
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
	sed -i "s|0000|$duankou|g" /home/web/conf.d/$yuming.conf
	nginx_http_on
	docker exec nginx nginx -s reload
}

restart_redis() {
	rm -rf /home/web/redis/*
	docker exec redis redis-cli FLUSHALL >/dev/null 2>&1
	# docker exec -it redis redis-cli CONFIG SET maxmemory 1gb > /dev/null 2>&1
	# docker exec -it redis redis-cli CONFIG SET maxmemory-policy allkeys-lru > /dev/null 2>&1
}

restart_ldnmp() {
	restart_redis
	docker exec nginx chown -R nginx:nginx /var/www/html >/dev/null 2>&1
	docker exec nginx mkdir -p /var/cache/nginx/proxy >/dev/null 2>&1
	docker exec nginx mkdir -p /var/cache/nginx/fastcgi >/dev/null 2>&1
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy >/dev/null 2>&1
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi >/dev/null 2>&1
	docker exec php chown -R www-data:www-data /var/www/html >/dev/null 2>&1
	docker exec php74 chown -R www-data:www-data /var/www/html >/dev/null 2>&1
	cd /home/web && docker compose restart nginx php php74

}

nginx_upgrade() {

	local ldnmp_pods="nginx"
	cd /home/web/
	docker rm -f $ldnmp_pods >/dev/null 2>&1
	docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1
	docker images --filter=reference="${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1
	docker compose up -d --force-recreate $ldnmp_pods
	crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
	(
		crontab -l 2>/dev/null
		echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf'
	) | crontab -
	docker exec nginx chown -R nginx:nginx /var/www/html
	docker exec nginx mkdir -p /var/cache/nginx/proxy
	docker exec nginx mkdir -p /var/cache/nginx/fastcgi
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy
	docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi
	docker restart $ldnmp_pods >/dev/null 2>&1

	send_stats "更新$ldnmp_pods"
	echo "更新${ldnmp_pods}完成"

}

phpmyadmin_upgrade() {
	local ldnmp_pods="phpmyadmin"
	local local docker_port=8877
	local dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	local dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

	cd /home/web/
	docker rm -f $ldnmp_pods >/dev/null 2>&1
	docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
	curl -sS -O https://raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
	docker compose -f docker-compose.phpmyadmin.yml up -d
	clear
	ip_address

	check_docker_app_ip
	echo "登入資訊: "
	echo "使用者名稱: $dbuse"
	echo "密碼: $dbusepasswd"
	echo
	send_stats "启动$ldnmp_pods"
}

cf_purge_cache() {
	local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
	local API_TOKEN
	local EMAIL
	local ZONE_IDS

	# 检查配置文件是否存在
	if [ -f "$CONFIG_FILE" ]; then
		# 从配置文件读取 API_TOKEN 和 zone_id
		read API_TOKEN EMAIL ZONE_IDS <"$CONFIG_FILE"
		# 将 ZONE_IDS 转换为数组
		ZONE_IDS=($ZONE_IDS)
	else
		# 提示用户是否清理缓存
		Ask "需要清理 Cloudflare 的快取嗎？(y/N): " answer
		if [[ $answer == "y" ]]; then
			echo "CF資訊保存在$CONFIG_FILE，可以後期修改CF資訊"
			Ask "請輸入您的 API_TOKEN: " API_TOKEN
			Ask "請輸入您的 CF 使用者名稱: " EMAIL
			Ask "請輸入 zone_id（多個用空格分隔）: " -a ZONE_IDS

			mkdir -p /home/web/config/
			echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" >"$CONFIG_FILE"
		fi
	fi

	# 循环遍历每个 zone_id 并执行清除缓存命令
	for ZONE_ID in "${ZONE_IDS[@]}"; do
		echo "正在清除快取 for zone_id: $ZONE_ID"
		curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
			-H "X-Auth-Email: $EMAIL" \
			-H "X-Auth-Key: $API_TOKEN" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'
	done

	echo "快取清除請求已發送完畢。"
}

web_cache() {
	send_stats "清理站点缓存"
	cf_purge_cache
	cd /home/web && docker compose restart
	restart_redis
}

web_del() {

	send_stats "删除站点数据"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		Ask "刪除網站資料，請輸入您的域名（多個域名用空格隔開）: " yuming_list
		if [[ -z $yuming_list ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "正在刪除域名: $yuming"
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "正在刪除資料庫: $dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" >/dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}

nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 根据 mode 参数来决定开启或关闭 WAF
	if [ "$mode" == "on" ]; then
		# 开启 WAF：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf >/dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 关闭 WAF：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf >/dev/null 2>&1
	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

check_waf_status() {
	if grep -q "^\s*#\s*modsecurity on;" /home/web/nginx.conf; then
		waf_status=""
	elif grep -q "modsecurity on;" /home/web/nginx.conf; then
		waf_status=" WAF已開啟"
	else
		waf_status=""
	fi
}

check_cf_mode() {
	if [ -f "/path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" cf模式已開啟"
	else
		CFmessage=""
	fi
}

nginx_http_on() {

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
	if [[ $yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern ]]; then
		sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
	fi

}

patch_wp_memory_limit() {
	local MEMORY_LIMIT="${1:-256M}"     # 第一个参数，默认256M
	local MAX_MEMORY_LIMIT="${2:-256M}" # 第二个参数，默认256M
	local TARGET_DIR="/home/web/html"   # 路径写死

	find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
		# 删除旧定义
		sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
		sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

		# 插入新定义，放在含 "Happy publishing" 的行前
		awk -v insert="define('WP_MEMORY_LIMIT', '$MEMORY_LIMIT');\ndefine('WP_MAX_MEMORY_LIMIT', '$MAX_MEMORY_LIMIT');" \
			'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" >"$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

		echo "[+] Replaced WP_MEMORY_LIMIT in $FILE"
	done
}

patch_wp_debug() {
	local DEBUG="${1:-false}"         # 第一个参数，默认false
	local DEBUG_DISPLAY="${2:-false}" # 第二个参数，默认false
	local DEBUG_LOG="${3:-false}"     # 第三个参数，默认false
	local TARGET_DIR="/home/web/html" # 路径写死

	find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
		# 删除旧定义
		sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
		sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
		sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

		# 插入新定义，放在含 "Happy publishing" 的行前
		awk -v insert="define('WP_DEBUG_DISPLAY', $DEBUG_DISPLAY);\ndefine('WP_DEBUG_LOG', $DEBUG_LOG);" \
			'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" >"$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

		echo "[+] Replaced WP_DEBUG settings in $FILE"
	done
}

nginx_br() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 开启 Brotli：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)# brotli on;|\1brotli on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_static on;|\1brotli_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_comp_level \(.*\);|\1brotli_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_buffers \(.*\);|\1brotli_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_min_length \(.*\);|\1brotli_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_window \(.*\);|\1brotli_window \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_types \(.*\);|\1brotli_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/brotli_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 关闭 Brotli：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)brotli on;|\1# brotli on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_static on;|\1# brotli_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_comp_level \(.*\);|\1# brotli_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_buffers \(.*\);|\1# brotli_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_min_length \(.*\);|\1# brotli_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_window \(.*\);|\1# brotli_window \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_types \(.*\);|\1# brotli_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/brotli_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

nginx_zstd() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 开启 Zstd：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)# zstd on;|\1zstd on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_static on;|\1zstd_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_comp_level \(.*\);|\1zstd_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_buffers \(.*\);|\1zstd_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_min_length \(.*\);|\1zstd_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_types \(.*\);|\1zstd_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/zstd_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 关闭 Zstd：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf >/dev/null 2>&1

		sed -i 's|^\(\s*\)zstd on;|\1# zstd on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_static on;|\1# zstd_static on;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_comp_level \(.*\);|\1# zstd_comp_level \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_buffers \(.*\);|\1# zstd_buffers \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_min_length \(.*\);|\1# zstd_min_length \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_types \(.*\);|\1# zstd_types \2;|' /home/web/nginx.conf >/dev/null 2>&1
		sed -i '/zstd_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

nginx_gzip() {

	local mode=$1
	if [ "$mode" == "on" ]; then
		sed -i 's|^\(\s*\)# gzip on;|\1gzip on;|' /home/web/nginx.conf >/dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		sed -i 's|^\(\s*\)gzip on;|\1# gzip on;|' /home/web/nginx.conf >/dev/null 2>&1
	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	docker exec nginx nginx -s reload

}

web_security() {
	send_stats "LDNMP环境防御"
	while true; do
		check_waf_status
		check_cf_mode
		if [ -x "$(command -v fail2ban-client)" ]; then
			clear
			remove fail2ban
			rm -rf /etc/fail2ban
		else
			clear
			docker_name="fail2ban"
			check_docker_app
			echo -e "伺服器網站防禦程式${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			echo "------------------------"
			echo "1. 安裝防禦程式"
			echo "------------------------"
			echo "5. 查看SSH攔截記錄                6. 查看網站攔截記錄"
			echo "7. 查看防禦規則列表               8. 查看日誌即時監控"
			echo "------------------------"
			echo "11. 設定攔截參數                  12. 清除所有拉黑的IP"
			echo "------------------------"
			echo "21. cloudflare模式                22. 高負載開啟5秒盾"
			echo "------------------------"
			echo "31. 啟用WAF                       32. 關閉WAF"
			echo "33. 啟用DDOS防禦                  34. 關閉DDOS防禦"
			echo "------------------------"
			echo "9. 卸載防禦程式"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			Ask "請輸入您的選擇: " sub_choice
			case $sub_choice in
			1)
				f2b_install_sshd
				cd /path/to/fail2ban/config/fail2ban/filter.d
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
				cd /path/to/fail2ban/config/fail2ban/jail.d/
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
				sed -i "/cloudflare/d" /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
				f2b_status
				;;
			5)
				echo "------------------------"
				f2b_sshd
				echo "------------------------"
				;;
			6)

				echo "------------------------"
				local xxx="fail2ban-nginx-cc"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-418"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-bad-request"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-badbots"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-botsearch"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-deny"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-http-auth"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-nginx-unauthorized"
				f2b_status_xxx
				echo "------------------------"
				local xxx="docker-php-url-fopen"
				f2b_status_xxx
				echo "------------------------"

				;;

			7)
				docker exec -it fail2ban fail2ban-client status
				;;
			8)
				tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log

				;;
			9)
				docker rm -f fail2ban
				rm -rf /path/to/fail2ban
				crontab -l | grep -v "CF-Under-Attack.sh" | crontab - 2>/dev/null
				echo "Fail2Ban防禦程式已卸載"
				;;

			11)
				install nano
				nano /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
				f2b_status
				break
				;;

			12)
				docker exec -it fail2ban fail2ban-client unban --all
				;;

			21)
				send_stats "cloudflare模式"
				echo "到cf後台右上角我的個人資料，選擇左側API令牌，獲取Global API Key"
				NO_TRAN="https://dash.cloudflare.com/login"
				echo "$NO_TRAN"
				Ask "輸入 CF 的帳號: " cfuser
				Ask "輸入 CF 的 Global API Key: " cftoken

				wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
				docker exec nginx nginx -s reload

				cd /path/to/fail2ban/config/fail2ban/jail.d/
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

				cd /path/to/fail2ban/config/fail2ban/action.d
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

				sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
				sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
				f2b_status

				echo "已設定cloudflare模式，可在cf後台，網站-安全性-事件中查看攔截記錄"
				;;

			22)
				send_stats "高负载开启5秒盾"
				echo -e "${gl_huang}網站每5分鐘自動檢測，當偵測到高負載會自動開啟防護盾，低負載也會自動關閉5秒防護盾。${gl_bai}"
				echo "--------------"
				echo "獲取CF參數: "
				echo -e "到cf後台右上角我的個人資料，選擇左側API令牌，獲取${gl_huang}Global API Key${gl_bai}"
				echo -e "到cf後台域名概要頁面右下方獲取${gl_huang}區域ID${gl_bai}"
				NO_TRAN="https://dash.cloudflare.com/login"
				echo "$NO_TRAN"
				echo "--------------"
				Ask "輸入 CF 的帳號: " cfuser
				Ask "輸入 CF 的 Global API Key: " cftoken
				Ask "輸入 CF 中域名的區域 ID: " cfzonID

				cd ~
				install jq bc
				check_crontab_installed
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh
				chmod +x CF-Under-Attack.sh
				sed -i "s/AAAA/$cfuser/g" ~/CF-Under-Attack.sh
				sed -i "s/BBBB/$cftoken/g" ~/CF-Under-Attack.sh
				sed -i "s/CCCC/$cfzonID/g" ~/CF-Under-Attack.sh

				local cron_job="*/5 * * * * ~/CF-Under-Attack.sh"

				local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

				if [ -z "$existing_cron" ]; then
					(
						crontab -l 2>/dev/null
						echo "$cron_job"
					) | crontab -
					echo "高負載自動開盾腳本已添加"
				else
					echo "自動開盾腳本已存在，無需添加"
				fi

				;;

			31)
				nginx_waf on
				echo "網站WAF已啟用"
				send_stats "站点WAF已开启"
				;;

			32)
				nginx_waf off
				echo "網站WAF已關閉"
				send_stats "站点WAF已关闭"
				;;

			33)
				enable_ddos_defense
				;;

			34)
				disable_ddos_defense
				;;

			*)
				break
				;;
			esac
		fi
		break_end
	done
}

check_nginx_mode() {

	CONFIG_FILE="/home/web/nginx.conf"

	# 获取当前的 worker_processes 设置值
	current_value=$(grep -E '^\s*worker_processes\s+[0-9]+;' "$CONFIG_FILE" | awk '{print $2}' | tr -d ';')

	# 根据值设置模式信息
	if [ "$current_value" = "8" ]; then
		mode_info="高效能模式"
	else
		mode_info="標準模式"
	fi

}

check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# 检查 zstd 是否开启且未被注释（整行以 zstd on; 开头）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status="zstd壓縮已開啟"
	else
		zstd_status=""
	fi

	# 检查 brotli 是否开启且未被注释
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status="br壓縮已開啟"
	else
		br_status=""
	fi

	# 检查 gzip 是否开启且未被注释
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status="gzip壓縮已開啟"
	else
		gzip_status=""
	fi
}

web_optimization() {
	while true; do
		check_nginx_mode
		check_nginx_compression
		clear
		send_stats "优化LDNMP环境"
		echo -e "優化LDNMP環境${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
		echo "------------------------"
		echo "1. 標準模式              2. 高性能模式 (推薦2H4G以上)"
		echo "------------------------"
		echo "3. 啟用gzip壓縮          4. 關閉gzip壓縮"
		echo "5. 啟用br壓縮            6. 關閉br壓縮"
		echo "7. 啟用zstd壓縮          8. 關閉zstd壓縮"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			send_stats "站点标准模式"

			# nginx调优
			sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
			sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

			# php调优
			wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
			docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
			docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
			rm -rf /home/optimized_php.ini

			# php调优
			wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
			docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
			docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
			rm -rf /home/www.conf

			patch_wp_memory_limit
			patch_wp_debug

			fix_phpfpm_conf php
			fix_phpfpm_conf php74

			# mysql调优
			wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
			docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
			rm -rf /home/custom_mysql_config.cnf

			cd /home/web && docker compose restart

			restart_redis
			optimize_balanced

			echo "LDNMP環境已設定成 標準模式"

			;;
		2)
			send_stats "站点高性能模式"

			# nginx调优
			sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
			sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

			# php调优
			wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
			docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
			docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
			rm -rf /home/optimized_php.ini

			# php调优
			wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
			docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
			docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
			rm -rf /home/www.conf

			patch_wp_memory_limit 512M 512M
			patch_wp_debug

			fix_phpfpm_conf php
			fix_phpfpm_conf php74

			# mysql调优
			wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
			docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
			rm -rf /home/custom_mysql_config.cnf

			cd /home/web && docker compose restart

			restart_redis
			optimize_web_server

			echo "LDNMP環境已設定成 高性能模式"

			;;
		3)
			send_stats "nginx_gzip on"
			nginx_gzip on
			;;
		4)
			send_stats "nginx_gzip off"
			nginx_gzip off
			;;
		5)
			send_stats "nginx_br on"
			nginx_br on
			;;
		6)
			send_stats "nginx_br off"
			nginx_br off
			;;
		7)
			send_stats "nginx_zstd on"
			nginx_zstd on
			;;
		8)
			send_stats "nginx_zstd off"
			nginx_zstd off
			;;
		*)
			break
			;;
		esac
		break_end

	done

}

check_docker_app() {

	if docker inspect "$docker_name" &>/dev/null; then
		check_docker="${gl_lv}已安裝${gl_bai}"
	else
		check_docker="${gl_hui}未安裝${gl_bai}"
	fi

}

check_docker_app_ip() {
	echo "------------------------"
	echo "訪問位址:"
	ip_address

	if [ -n "$ipv4_address" ]; then
		echo "http://$ipv4_address:${docker_port}"
	fi

	if [ -n "$ipv6_address" ]; then
		echo "http://[$ipv6_address]:${docker_port}"
	fi

	local search_pattern1="$ipv4_address:${docker_port}"
	local search_pattern2="127.0.0.1:${docker_port}"

	for file in /home/web/conf.d/*; do
		if [ -f "$file" ]; then
			if grep -q "$search_pattern1" "$file" 2>/dev/null || grep -q "$search_pattern2" "$file" 2>/dev/null; then
				echo "https://$(basename "$file" | sed 's/\.conf$//')"
			fi
		fi
	done

}

check_docker_image_update() {

	local container_name=$1

	local country=$(curl -s ipinfo.io/country)
	if [[ $country == "CN" ]]; then
		update_status=""
		return
	fi

	# 获取容器的创建时间和镜像名称
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# 提取镜像仓库和标签
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# 默认标签为 latest
	[[ $image_repo == "$image_tag" ]] && image_tag="latest"

	# 添加对官方镜像的支持
	[[ $image_repo != */* ]] && image_repo="library/$image_repo"

	# 从 Docker Hub API 获取镜像发布时间
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 验证获取的时间
	if [[ -n $last_updated && $last_updated != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# 比较时间戳
		if [[ $container_created_ts -lt $last_updated_ts ]]; then
			update_status="${gl_huang}發現新版本!${gl_bai}"
		else
			update_status=""
		fi
	else
		update_status=""
	fi

}

block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "錯誤：無法取得容器 $container_name_or_id 的 IP 位址。請檢查容器名稱或ID是否正確。"
		return 1
	fi

	install iptables

	# 检查并封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 检查并放行指定 IP
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 检查并放行本地网络 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	# 检查并封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 检查并放行指定 IP
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 检查并放行本地网络 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi

	echo "已阻止IP+埠口訪問該服務"
	save_iptables_rules
}

clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "錯誤：無法取得容器 $container_name_or_id 的 IP 位址。請檢查容器名稱或ID是否正確。"
		return 1
	fi

	install iptables

	# 清除封禁其他所有 IP 的规则
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的规则
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地网络 127.0.0.0/8 的规则
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	# 清除封禁其他所有 IP 的规则
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的规则
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地网络 127.0.0.0/8 的规则
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi

	echo "已允許IP+埠口訪問該服務"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z $port || -z $allowed_ip ]]; then
		echo "錯誤：請提供埠口號和允許訪問的 IP。"
		echo "用法: block_host_port <埠口號> <允許的IP>"
		return 1
	fi

	install iptables

	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 拒绝其他所有 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 允许指定 IP 访问
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允许本机访问
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 允许已建立和相关连接的流量
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "已阻止IP+埠口訪問該服務"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z $port || -z $allowed_ip ]]; then
		echo "錯誤：請提供埠口號和允許訪問的 IP。"
		echo "用法: clear_host_port_rules <埠口號> <允許的IP>"
		return 1
	fi

	install iptables

	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 清除封禁所有其他 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 清除允许本机访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允许指定 IP 访问的规则
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	echo "已允許IP+埠口訪問該服務"
	save_iptables_rules

}

setup_docker_dir() {

	mkdir -p /home/docker/ 2>/dev/null
	if [ -d "/vol1/1000/" ] && [ ! -d "/vol1/1000/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /vol1/1000/docker 2>/dev/null
		ln -s /vol1/1000/docker /home/docker 2>/dev/null
	fi
}

docker_app() {
	send_stats "${docker_name}管理"

	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "$docker_name $check_docker $update_status"
		echo "$docker_describe"
		echo "$docker_url"
		if docker inspect "$docker_name" &>/dev/null; then
			if [ ! -f "/home/docker/${docker_name}_port.conf" ]; then
				local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
				docker_port=${docker_port:-0000}
				echo "$docker_port" >"/home/docker/${docker_name}_port.conf"
			fi
			local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
			check_docker_app_ip
		fi
		echo
		echo "------------------------"
		echo "1. 安裝              2. 更新            3. 移除"
		echo "------------------------"
		echo "5. 添加域名訪問      6. 刪除域名訪問"
		echo "7. 允許IP+埠口訪問   8. 阻止IP+埠口訪問"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1)
			check_disk_space $app_size
			Ask "輸入應用對外服務埠號，回車預設使用${docker_port}埠號: " app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			setup_docker_dir
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

			clear
			echo "$docker_name 已經安裝完成"
			check_docker_app_ip
			echo
			$docker_use
			$docker_passwd
			send_stats "安装$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum
			clear
			echo "$docker_name 已經安裝完成"
			check_docker_app_ip
			echo
			$docker_use
			$docker_passwd
			send_stats "更新$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			rm -f /home/docker/${docker_name}_port.conf
			echo "應用已移除"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name}域名訪問設定"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "域名格式 example.com 不帶https://"
			web_del
			;;

		7)
			send_stats "允许IP访问 ${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问 ${docker_name}"
			block_container_port "$docker_name" "$ipv4_address"
			;;

		*)
			break
			;;
		esac
		break_end
	done

}

docker_app_plus() {
	send_stats "$app_name"
	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		NO_TRAN="$app_name $check_docker $update_status"
		echo -e "$NO_TRAN"
		echo "$app_text"
		echo "$app_url"
		if docker inspect "$docker_name" &>/dev/null; then
			if [ ! -f "/home/docker/${docker_name}_port.conf" ]; then
				local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
				docker_port=${docker_port:-0000}
				echo "$docker_port" >"/home/docker/${docker_name}_port.conf"
			fi
			local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
			check_docker_app_ip
		fi
		echo
		echo "------------------------"
		echo "1. 安裝             2. 更新             3. 移除"
		echo "------------------------"
		echo "5. 添加域名訪問     6. 刪除域名訪問"
		echo "7. 允許IP+埠口訪問  8. 阻止IP+埠口訪問"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1)
			check_disk_space $app_size
			Ask "輸入應用對外服務埠號，回車預設使用${docker_port}埠號: " app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port
			install jq
			install_docker
			docker_app_install
			setup_docker_dir
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"
			;;
		2)
			docker_app_update
			;;
		3)
			docker_app_uninstall
			rm -f /home/docker/${docker_name}_port.conf
			;;
		5)
			echo "${docker_name}域名訪問設定"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;
		6)
			echo "域名格式 example.com 不帶https://"
			web_del
			;;
		7)
			send_stats "允许IP访问 ${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;
		8)
			send_stats "阻止IP访问 ${docker_name}"
			block_container_port "$docker_name" "$ipv4_address"
			;;
		*)
			break
			;;
		esac
		break_end
	done
}

prometheus_install() {

	local PROMETHEUS_DIR="/home/docker/monitoring/prometheus"
	local GRAFANA_DIR="/home/docker/monitoring/grafana"
	local NETWORK_NAME="monitoring"

	# Create necessary directories
	mkdir -p $PROMETHEUS_DIR
	mkdir -p $GRAFANA_DIR

	# Set correct ownership for Grafana directory
	chown -R 472:472 $GRAFANA_DIR

	if [ ! -f "$PROMETHEUS_DIR/prometheus.yml" ]; then
		curl -o "$PROMETHEUS_DIR/prometheus.yml" ${gh_proxy}raw.githubusercontent.com/kejilion/config/refs/heads/main/prometheus/prometheus.yml
	fi

	# Create Docker network for monitoring
	docker network create $NETWORK_NAME

	# Run Node Exporter container
	docker run -d \
		--name=node-exporter \
		--network $NETWORK_NAME \
		--restart unless-stopped \
		prom/node-exporter

	# Run Prometheus container
	docker run -d \
		--name prometheus \
		-v $PROMETHEUS_DIR/prometheus.yml:/etc/prometheus/prometheus.yml \
		-v $PROMETHEUS_DIR/data:/prometheus \
		--network $NETWORK_NAME \
		--restart unless-stopped \
		--user 0:0 \
		prom/prometheus:latest

	# Run Grafana container
	docker run -d \
		--name grafana \
		-p ${docker_port}:3000 \
		-v $GRAFANA_DIR:/var/lib/grafana \
		--network $NETWORK_NAME \
		--restart unless-stopped \
		grafana/grafana:latest

}

tmux_run() {
	# Check if the session already exists
	tmux has-session -t $SESSION_NAME 2>/dev/null
	# $? is a special variable that holds the exit status of the last executed command
	if [ $? != 0 ]; then
		# Session doesn't exist, create a new one
		tmux new -s $SESSION_NAME
	else
		# Session exists, attach to it
		tmux attach-session -t $SESSION_NAME
	fi
}

tmux_run_d() {

	local base_name="tmuxd"
	local tmuxd_ID=1

	# 检查会话是否存在的函数
	session_exists() {
		tmux has-session -t $1 2>/dev/null
	}

	# 循环直到找到一个不存在的会话名称
	while session_exists "$base_name-$tmuxd_ID"; do
		local tmuxd_ID=$((tmuxd_ID + 1))
	done

	# 创建新的 tmux 会话
	tmux new -d -s "$base_name-$tmuxd_ID" "$tmuxd"

}

f2b_status() {
	docker exec -it fail2ban fail2ban-client reload
	sleep 3
	docker exec -it fail2ban fail2ban-client status
}

f2b_status_xxx() {
	docker exec -it fail2ban fail2ban-client status $xxx
}

f2b_install_sshd() {

	docker run -d \
		--name=fail2ban \
		--net=host \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=Etc/UTC \
		-e VERBOSITY=-vv \
		-v /path/to/fail2ban/config:/config \
		-v /var/log:/var/log:ro \
		-v /home/web/log/nginx/:/remotelogs/nginx:ro \
		--restart unless-stopped \
		lscr.io/linuxserver/fail2ban:latest

	sleep 3
	if grep -q 'Alpine' /etc/issue; then
		cd /path/to/fail2ban/config/fail2ban/filter.d
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd.conf
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd-ddos.conf
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-ssh.conf
	elif command -v dnf &>/dev/null; then
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	else
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/linux-ssh.conf
		systemctl restart rsyslog
	fi

	rm -f /path/to/fail2ban/config/fail2ban/jail.d/sshd.conf
}

f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	else
		xxx=sshd
		f2b_status_xxx
	fi
}

server_reboot() {

	Ask "${gl_huang}提示: ${gl_bai}現在重新啟動伺服器嗎？(y/N): " rboot
	case "$rboot" in
	[Yy])
		echo "已重啟"
		reboot
		;;
	*)
		echo "已取消"
		;;
	esac

}

ldnmp_install_status_one() {

	if docker inspect "php" &>/dev/null; then
		clear
		send_stats "无法再次安装LDNMP环境"
		echo -e "${gl_huang}提示: ${gl_bai}建站環境已安裝。無需再次安裝！"
		break_end
		linux_ldnmp
	fi

}

ldnmp_install_all() {
	cd ~
	send_stats "安装LDNMP环境"
	root_use
	clear
	echo -e "${gl_huang}LDNMP環境未安裝，開始安裝LDNMP環境...${gl_bai}"
	check_disk_space 3
	check_port
	install_dependency
	install_docker
	install_certbot
	install_ldnmp_conf
	install_ldnmp

}

nginx_install_all() {
	cd ~
	send_stats "安装nginx环境"
	root_use
	clear
	echo -e "${gl_huang}nginx未安裝，開始安裝nginx環境...${gl_bai}"
	check_disk_space 1
	check_port
	install_dependency
	install_docker
	install_certbot
	install_ldnmp_conf
	nginx_upgrade
	clear
	local nginx_version=$(docker exec nginx nginx -v 2>&1)
	local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	echo "nginx已安裝完成"
	echo -e "目前版本: ${gl_huang}v$nginx_version${gl_bai}"
	echo

}

ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "请先安装LDNMP环境"
		ldnmp_install_all
	fi

}

nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "请先安装nginx环境"
		nginx_install_all
	fi

}

ldnmp_web_on() {
	clear
	echo "您的 $webname 搭建好了！"
	echo "https://$yuming"
	echo "------------------------"
	echo "$webname 安裝資訊如下: "

}

nginx_web_on() {
	clear
	echo "您的 $webname 搭建好了！"
	echo "https://$yuming"

}

ldnmp_wp() {
	clear
	# wordpress
	webname="WordPress"
	yuming="${1:-}"
	send_stats "安装$webname"
	echo "開始部署 $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	repeat_add_yuming
	ldnmp_install_status
	install_ssltls
	certs_status
	add_db
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	nginx_http_on

	cd /home/web/html
	mkdir $yuming
	cd $yuming
	wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
	# wget -O latest.zip https://cn.wordpress.org/latest-zh_CN.zip
	# wget -O latest.zip https://wordpress.org/latest.zip
	unzip latest.zip
	rm latest.zip
	echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >>/home/web/html/$yuming/wordpress/wp-config-sample.php
	sed -i "s|database_name_here|$dbname|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
	sed -i "s|username_here|$dbuse|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
	sed -i "s|password_here|$dbusepasswd|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
	sed -i "s|localhost|mysql|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
	cp /home/web/html/$yuming/wordpress/wp-config-sample.php /home/web/html/$yuming/wordpress/wp-config.php

	restart_ldnmp
	nginx_web_on
	#   echo "資料庫名: $dbname"
	#   echo "使用者名稱: $dbuse"
	#   echo "密碼: $dbusepasswd"
	#   echo "資料庫位址: mysql"
	#   echo "表前綴: wp_"

}

ldnmp_Proxy() {
	clear
	webname="反向代理-IP+埠"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "開始部署 $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		Ask "請輸入您的反向代理 IP: " reverseproxy
	fi

	if [ -z "$port" ]; then
		Ask "請輸入您的反向代理埠號: " port
	fi
	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	sed -i "s|0000|$port|g" /home/web/conf.d/$yuming.conf
	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}

ldnmp_Proxy_backend() {
	clear
	webname="反向代理-負載均衡"
	yuming="${1:-}"
	reverseproxy_port="${2:-}"

	send_stats "安装$webname"
	echo "開始部署 $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# 获取用户输入的多个IP:端口（用空格分隔）
	if [ -z "$reverseproxy_port" ]; then
		Ask "請輸入您的多個反向代理 IP+埠號用空格隔開（例如 127.0.0.1:3000 127.0.0.1:3002）： " reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' </dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf

	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	# 动态生成 upstream 配置
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	# 替换模板中的占位符
	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}

ldnmp_web_status() {
	root_use
	while true; do
		local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
		local output="站點: ${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="資料庫: ${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "LDNMP環境"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}                      憑證到期時間"
		echo -e "------------------------"
		for cert_file in /home/web/certs/*_cert.pem; do
			local domain=$(basename "$cert_file" | sed 's/_cert.pem//')
			if [ -n "$domain" ]; then
				local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
				local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
				printf "%-30s%s\n" "$domain" "$formatted_date"
			fi
		done

		echo "------------------------"
		echo
		echo -e "${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo
		echo "站點目錄"
		echo "------------------------"
		echo -e "資料 ${gl_hui}/home/web/html${gl_bai}     憑證 ${gl_hui}/home/web/certs${gl_bai}     設定 ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo
		echo "操作"
		echo "------------------------"
		echo "1.  申請/更新域名憑證               2.  更換站點域名"
		echo "3.  清理站點快取                    4.  創建關聯站點"
		echo "5.  查看訪問日誌                    6.  查看錯誤日誌"
		echo "7.  編輯全局設定                    8.  編輯站點設定"
		echo "9.  管理站點資料庫\t\t    10. 查看站點分析報告"
		echo "------------------------"
		echo "20. 刪除指定站點資料"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			send_stats "申请域名证书"
			Ask "請輸入您的域名: " yuming
			install_certbot
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
			install_ssltls
			certs_status

			;;

		2)
			send_stats "更换站点域名"
			echo -e "${gl_hong}強烈建議: ${gl_bai}先備份好全站資料再更換網站域名！"
			Ask "請輸入舊域名: " oddyuming
			Ask "請輸入新域名: " yuming
			install_certbot
			install_ssltls
			certs_status

			# mysql替换
			add_db

			local odd_dbname=$(echo "$oddyuming" | sed -e 's/[^A-Za-z0-9]/_/g')
			local odd_dbname="${odd_dbname}"

			docker exec mysql mysqldump -u root -p"$dbrootpasswd" $odd_dbname | docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname
			docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $odd_dbname;"

			local tables=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW TABLES;" | awk '{ if (NR>1) print $1 }')
			for table in $tables; do
				columns=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW COLUMNS FROM $table;" | awk '{ if (NR>1) print $1 }')
				for column in $columns; do
					docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "UPDATE $table SET $column = REPLACE($column, '$oddyuming', '$yuming') WHERE $column LIKE '%$oddyuming%';"
				done
			done

			# 网站目录替换
			mv /home/web/html/$oddyuming /home/web/html/$yuming

			find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
			find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

			mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
			sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

			rm /home/web/certs/${oddyuming}_key.pem
			rm /home/web/certs/${oddyuming}_cert.pem

			docker exec nginx nginx -s reload

			;;

		3)
			web_cache
			;;
		4)
			send_stats "创建关联站点"
			echo -e "為現有的網站再關聯一個新域名用於訪問"
			Ask "請輸入現有的域名: " oddyuming
			Ask "請輸入新域名: " yuming
			install_certbot
			install_ssltls
			certs_status

			cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
			sed -i "s|server_name $oddyuming|server_name $yuming|g" /home/web/conf.d/$yuming.conf
			sed -i "s|/etc/nginx/certs/${oddyuming}_cert.pem|/etc/nginx/certs/${yuming}_cert.pem|g" /home/web/conf.d/$yuming.conf
			sed -i "s|/etc/nginx/certs/${oddyuming}_key.pem|/etc/nginx/certs/${yuming}_key.pem|g" /home/web/conf.d/$yuming.conf

			docker exec nginx nginx -s reload

			;;
		5)
			send_stats "查看访问日志"
			tail -n 200 /home/web/log/nginx/access.log
			break_end
			;;
		6)
			send_stats "查看错误日志"
			tail -n 200 /home/web/log/nginx/error.log
			break_end
			;;
		7)
			send_stats "编辑全局配置"
			install nano
			nano /home/web/nginx.conf
			docker exec nginx nginx -s reload
			;;

		8)
			send_stats "编辑站点配置"
			Ask "編輯網站配置，請輸入您要編輯的域名: " yuming
			install nano
			nano /home/web/conf.d/$yuming.conf
			docker exec nginx nginx -s reload
			;;
		9)
			phpmyadmin_upgrade
			break_end
			;;
		10)
			send_stats "查看站点数据"
			install goaccess
			goaccess --log-format=COMBINED /home/web/log/nginx/access.log
			;;

		20)
			web_del
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null

			;;
		*)
			break
			;;
		esac
	done

}

check_panel_app() {
	if $lujing >/dev/null 2>&1; then
		check_panel="${gl_lv}已安裝${gl_bai}"
	else
		check_panel=""
	fi
}

install_panel() {
	send_stats "${panelname}管理"
	while true; do
		clear
		check_panel_app
		echo -e "$panelname $check_panel"
		echo "${panelname}是一款時下流行且強大的維運管理面板。"
		echo "官網介紹: $panelurl "

		echo
		echo "------------------------"
		echo "1. 安裝            2. 管理            3. 移除"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}安装"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}控制"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}卸载"
			;;
		*)
			break
			;;
		esac
		break_end
	done

}

check_frp_app() {

	if [ -d "/home/frp/" ]; then
		check_frp="${gl_lv}已安裝${gl_bai}"
	else
		check_frp="${gl_hui}未安裝${gl_bai}"
	fi

}

donlond_frp() {
	role="$1"
	config_file="/home/frp/${role}.toml"

	docker run -d \
		--name "$role" \
		--restart=always \
		--network host \
		-v "$config_file":"/frp/${role}.toml" \
		kjlion/frp:alpine \
		"/frp/${role}" -c "/frp/${role}.toml"

}

generate_frps_config() {

	send_stats "安装frp服务端"
	# 生成随机端口和凭证
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	mkdir -p /home/frp
	touch /home/frp/frps.toml
	NO_TRAN=$'[common]\nbind_port = $bind_port\nauthentication_method = token\ntoken = $token\ndashboard_port = $dashboard_port\ndashboard_user = $dashboard_user\ndashboard_pwd = $dashboard_pwd\n'
	echo -e "$NO_TRAN" >/home/frp/frps.toml

	donlond_frp frps

	# 输出生成的信息
	ip_address
	echo "------------------------"
	echo "客戶端部署時需要用的參數"
	echo "服務IP: $ipv4_address"
	echo "token: $token"
	echo
	echo "FRP面板資訊"
	echo "FRP面板位址: http://$ipv4_address:$dashboard_port"
	echo "FRP面板用戶名: $dashboard_user"
	echo "FRP面板密碼: $dashboard_pwd"
	echo

	open_port 8055 8056

}

configure_frpc() {
	send_stats "安装frp客户端"
	Ask "請輸入外網對接 IP: " server_addr
	Ask "請輸入外網對接 token: " token
	echo

	mkdir -p /home/frp
	touch /home/frp/frpc.toml
	NO_TRAN=$'[common]\nserver_addr = ${server_addr}\nserver_port = 8055\ntoken = ${token}\n'
	echo -e "$NO_TRAN" >/home/frp/frpc.toml

	donlond_frp frpc

	open_port 8055

}

add_forwarding_service() {
	send_stats "添加frp内网服务"
	# 提示用户输入服务名称和转发信息
	Ask "請輸入服務名稱: " service_name
	Ask "請輸入轉發類型 (tcp/udp) [回車預設 tcp]: " service_type
	local service_type=${service_type:-tcp}
	Ask "請輸入內網 IP [回車預設 127.0.0.1]: " local_ip
	local local_ip=${local_ip:-127.0.0.1}
	Ask "請輸入內網埠號: " local_port
	Ask "請輸入外網埠號: " remote_port

	# 将用户输入写入配置文件
	NO_TRAN=$'\n[$service_name]\ntype = ${service_type}\nlocal_ip = ${local_ip}\nlocal_port = ${local_port}\nremote_port = ${remote_port}\n'
	echo -e "$NO_TRAN" >>/home/frp/frpc.toml

	# 输出生成的信息
	echo "服務 $service_name 已成功添加到 frpc.toml"

	docker restart frpc

	open_port $local_port

}

delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	Ask "請輸入需要刪除的服務名稱: " service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "服務 $service_name 已成功從 frpc.toml 刪除"

	docker restart frpc

}

list_forwarding_services() {
	local config_file="$1"

	# 打印表头
	echo "服務名稱         內網位址              外網位址                   協議"

	awk '
	BEGIN {
		server_addr=""
		server_port=""
		current_service=""
	}

	/^server_addr = / {
		gsub(/"|'"'"'/, "", $3)
		server_addr=$3
	}

	/^server_port = / {
		gsub(/"|'"'"'/, "", $3)
		server_port=$3
	}

	/^\[.*\]/ {
		# 如果已有服务信息，在处理新服务之前打印当前服务
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 更新当前服务名称
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 清除之前的值
			local_ip=""
			local_port=""
			remote_port=""
			type=""
		}
	}

	/^local_ip = / {
		gsub(/"|'"'"'/, "", $3)
		local_ip=$3
	}

	/^local_port = / {
		gsub(/"|'"'"'/, "", $3)
		local_port=$3
	}

	/^remote_port = / {
		gsub(/"|'"'"'/, "", $3)
		remote_port=$3
	}

	/^type = / {
		gsub(/"|'"'"'/, "", $3)
		type=$3
	}

	END {
		# 打印最后一个服务的信息
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}

# 获取 FRP 服务端端口
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# 生成访问地址
generate_access_urls() {
	# 首先获取所有端口
	get_frp_ports

	# 检查是否有非 8055/8056 的端口
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 只在有有效端口时显示标题和内容
	if [ "$has_valid_ports" = true ]; then
		echo "FRP服務對外訪問位址:"

		# 处理 IPv4 地址
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# 处理 IPv6 地址（如果存在）
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# 处理 HTTPS 配置
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				local frps_search_pattern="${ipv4_address}:${port}"
				local frps_search_pattern2="127.0.0.1:${port}"
				for file in /home/web/conf.d/*.conf; do
					if [ -f "$file" ]; then
						if grep -q "$frps_search_pattern" "$file" 2>/dev/null || grep -q "$frps_search_pattern2" "$file" 2>/dev/null; then
							echo "https://$(basename "$file" .conf)"
						fi
					fi
				done
			fi
		done
	fi
}

frps_main_ports() {
	ip_address
	generate_access_urls
}

frps_panel() {
	send_stats "FRP服务端"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP伺服器端 $check_frp $update_status"
		echo "建構FRP內網穿透服務環境，將無公網IP的設備暴露到互聯網"
		echo "官網介紹: https://github.com/fatedier/frp/"
		echo "影片教學: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo
		echo "------------------------"
		echo "1. 安裝                  2. 更新                  3. 移除"
		echo "------------------------"
		echo "5. 內網服務域名訪問      6. 刪除域名訪問"
		echo "------------------------"
		echo "7. 允許IP+埠口訪問       8. 阻止IP+埠口訪問"
		echo "------------------------"
		echo "00. 刷新服務狀態         0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			generate_frps_config
			echo "FRP服务端已經安裝完成"
			;;
		2)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
			donlond_frp frps
			echo "FRP服务端已經更新完成"
			;;
		3)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine
			rm -rf /home/frp

			close_port 8055 8056

			echo "應用已移除"
			;;
		5)
			echo "將內網穿透服務反向代理成域名訪問"
			send_stats "FRP对外域名访问"
			add_yuming
			Ask "請輸入你的內網穿透服務端口: " frps_port
			ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
			block_host_port "$frps_port" "$ipv4_address"
			;;
		6)
			echo "域名格式 example.com 不帶https://"
			web_del
			;;

		7)
			send_stats "允许IP访问"
			Ask "請輸入需要放行的端口: " frps_port
			clear_host_port_rules "$frps_port" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问"
			echo "如果你已經反向代理域名訪問了，可用此功能阻止IP+埠口訪問，這樣更安全。"
			Ask "請輸入需要阻止的端口: " frps_port
			block_host_port "$frps_port" "$ipv4_address"
			;;

		00)
			send_stats "刷新FRP服务状态"
			echo "已經刷新FRP服務狀態"
			;;

		*)
			break
			;;
		esac
		break_end
	done
}

frpc_panel() {
	send_stats "FRP客户端"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP客戶端 $check_frp $update_status"
		echo "與服务端對接，對接後可創建內網穿透服務到互聯網訪問"
		echo "官網介紹: https://github.com/fatedier/frp/"
		echo "影片教學: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo
		echo "------------------------"
		echo "1. 安裝               2. 更新               3. 移除"
		echo "------------------------"
		echo "4. 添加對外服務       5. 刪除對外服務       6. 手動配置服務"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			configure_frpc
			echo "FRP客戶端已經安裝完成"
			;;
		2)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			donlond_frp frpc
			echo "FRP客戶端已經更新完成"
			;;

		3)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine
			rm -rf /home/frp
			close_port 8055
			echo "應用已移除"
			;;

		4)
			add_forwarding_service
			;;

		5)
			delete_forwarding_service
			;;

		6)
			install nano
			nano /home/frp/frpc.toml
			docker restart frpc
			;;

		*)
			break
			;;
		esac
		break_end
	done
}

yt_menu_pro() {

	local VIDEO_DIR="/home/yt-dlp"
	local URL_FILE="$VIDEO_DIR/urls.txt"
	local ARCHIVE_FILE="$VIDEO_DIR/archive.txt"

	mkdir -p "$VIDEO_DIR"

	while true; do

		if [ -x "/usr/local/bin/yt-dlp" ]; then
			local YTDLP_STATUS="${gl_lv}已安裝${gl_bai}"
		else
			local YTDLP_STATUS="${gl_hui}未安裝${gl_bai}"
		fi

		clear
		send_stats "yt-dlp 下载工具"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp 是一個功能強大的影片下載工具，支援 YouTube、Bilibili、Twitter 等數千個網站。"
		echo -e "官網地址：https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "已下載影片列表:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "（暫無）"
		echo "-------------------------"
		echo "1.  安裝               2.  更新               3.  移除"
		echo "-------------------------"
		echo "5.  單個影片下載       6.  批量影片下載       7.  自定義參數下載"
		echo "8.  下載為MP3音訊      9.  刪除影片目錄       10. Cookie管理（開發中）"
		echo "-------------------------"
		echo "0. 返回上一級選單"
		echo "-------------------------"
		Ask "請輸入選項編號: " choice

		case $choice in
		1)
			send_stats "正在安装 yt-dlp..."
			echo "正在安裝 yt-dlp..."
			install ffmpeg
			sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
			sudo chmod a+rx /usr/local/bin/yt-dlp
			Press "安裝完成。按任意鍵繼續..."
			;;
		2)
			send_stats "正在更新 yt-dlp..."
			echo "正在更新 yt-dlp..."
			sudo yt-dlp -U
			Press "更新完成。按任意鍵繼續..."
			;;
		3)
			send_stats "正在卸载 yt-dlp..."
			echo "正在移除 yt-dlp..."
			sudo rm -f /usr/local/bin/yt-dlp
			Press "卸載完成。按任意鍵繼續..."
			;;
		5)
			send_stats "单个视频下载"
			Ask "請輸入視頻鏈接: " url
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			Press "下載完成，按任意鍵繼續..."
			;;
		6)
			send_stats "批量视频下载"
			install nano
			if [ ! -f "$URL_FILE" ]; then
				echo -e "# 輸入多個影片連結地址\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" >"$URL_FILE"
			fi
			nano $URL_FILE
			echo "現在開始批量下載..."
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-a "$URL_FILE" \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			Press "批量下載完成，按任意鍵繼續..."
			;;
		7)
			send_stats "自定义视频下载"
			Ask "請輸入完整 yt-dlp 參數（不含 yt-dlp）: " custom
			yt-dlp -P "$VIDEO_DIR" $custom \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			Press "執行完成，按任意鍵繼續..."
			;;
		8)
			send_stats "MP3下载"
			Ask "請輸入視頻鏈接: " url
			yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			Press "音訊下載完成，按任意鍵繼續..."
			;;

		9)
			send_stats "删除视频"
			Ask "請輸入刪除視頻名稱: " rmdir
			rm -rf "$VIDEO_DIR/$rmdir"
			;;
		*)
			break
			;;
		esac
	done
}

set_timedate() {
	local shiqu="$1"
	if grep -q 'Alpine' /etc/issue; then
		install tzdata
		cp /usr/share/zoneinfo/${shiqu} /etc/localtime
		hwclock --systohc
	else
		timedatectl set-timezone ${shiqu}
	fi
}

# 修复dpkg中断问题
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}

linux_update() {
	echo -e "${gl_huang}正在系統更新...${gl_bai}"
	if command -v dnf &>/dev/null; then
		dnf -y update
	elif command -v yum &>/dev/null; then
		yum -y update
	elif command -v apt &>/dev/null; then
		fix_dpkg
		DEBIAN_FRONTEND=noninteractive apt update -y
		DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
	elif command -v apk &>/dev/null; then
		apk update && apk upgrade
	elif command -v pacman &>/dev/null; then
		pacman -Syu --noconfirm
	elif command -v zypper &>/dev/null; then
		zypper refresh
		zypper update
	elif command -v opkg &>/dev/null; then
		opkg update
	else
		echo "未知的套件管理器！"
		return
	fi
}

linux_clean() {
	echo -e "${gl_huang}正在系統清理...${gl_bai}"
	if command -v dnf &>/dev/null; then
		rpm --rebuilddb
		dnf autoremove -y
		dnf clean all
		dnf makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v yum &>/dev/null; then
		rpm --rebuilddb
		yum autoremove -y
		yum clean all
		yum makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apt &>/dev/null; then
		fix_dpkg
		apt autoremove --purge -y
		apt clean -y
		apt autoclean -y
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apk &>/dev/null; then
		echo "清理套件管理器快取..."
		apk cache clean
		echo "刪除系統日誌..."
		rm -rf /var/log/*
		echo "刪除APK快取..."
		rm -rf /var/cache/apk/*
		echo "刪除臨時文件..."
		rm -rf /tmp/*

	elif command -v pacman &>/dev/null; then
		pacman -Rns $(pacman -Qdtq) --noconfirm
		pacman -Scc --noconfirm
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v zypper &>/dev/null; then
		zypper clean --all
		zypper refresh
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v opkg &>/dev/null; then
		echo "刪除系統日誌..."
		rm -rf /var/log/*
		echo "刪除臨時文件..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "清理未使用的依賴..."
		pkg autoremove -y
		echo "清理套件管理器快取..."
		pkg clean -y
		echo "刪除系統日誌..."
		rm -rf /var/log/*
		echo "刪除臨時文件..."
		rm -rf /tmp/*

	else
		echo "未知的套件管理器！"
		return
	fi
	return
}

bbr_on() {

	NO_TRAN=$'net.ipv4.tcp_congestion_control=bbr\n'
	echo -e "$NO_TRAN" | sudo tee /etc/sysctl.conf >/dev/null
	sysctl -p

}

set_dns() {

	ip_address

	rm /etc/resolv.conf
	touch /etc/resolv.conf

	if [ -n "$ipv4_address" ]; then
		echo "nameserver $dns1_ipv4" >>/etc/resolv.conf
		echo "nameserver $dns2_ipv4" >>/etc/resolv.conf
	fi

	if [ -n "$ipv6_address" ]; then
		echo "nameserver $dns1_ipv6" >>/etc/resolv.conf
		echo "nameserver $dns2_ipv6" >>/etc/resolv.conf
	fi

}

set_dns_ui() {
	root_use
	send_stats "优化DNS"
	while true; do
		clear
		echo "優化DNS位址"
		echo "------------------------"
		echo "目前DNS位址"
		cat /etc/resolv.conf
		echo "------------------------"
		echo
		echo "1. 國外DNS優化: "
		echo " v4: 1.1.1.1 8.8.8.8"
		echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
		echo "2. 國內DNS優化: "
		echo " v4: 223.5.5.5 183.60.83.19"
		echo " v6: 2400:3200::1 2400:da00::6666"
		echo "3. 手動編輯DNS配置"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " Limiting
		case "$Limiting" in
		1)
			local dns1_ipv4="1.1.1.1"
			local dns2_ipv4="8.8.8.8"
			local dns1_ipv6="2606:4700:4700::1111"
			local dns2_ipv6="2001:4860:4860::8888"
			set_dns
			send_stats "国外DNS优化"
			;;
		2)
			local dns1_ipv4="223.5.5.5"
			local dns2_ipv4="183.60.83.19"
			local dns1_ipv6="2400:3200::1"
			local dns2_ipv6="2400:da00::6666"
			set_dns
			send_stats "国内DNS优化"
			;;
		3)
			install nano
			nano /etc/resolv.conf
			send_stats "手动编辑DNS配置"
			;;
		*)
			break
			;;
		esac
	done

}

restart_ssh() {
	restart sshd ssh >/dev/null 2>&1

}

correct_ssh_config() {

	local sshd_config="/etc/ssh/sshd_config"

	# 如果找到 PasswordAuthentication 设置为 yes
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 如果找到 PubkeyAuthentication 设置为 yes
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# 如果 PasswordAuthentication 和 PubkeyAuthentication 都没有匹配，则设置默认值
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}

new_ssh_port() {

	# 备份 SSH 配置文件
	cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

	sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
	sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

	correct_ssh_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

	restart_ssh
	open_port $new_port
	remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1

	echo "SSH 端口已修改為: $new_port"

	sleep 1

}

add_sshkey() {
	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""
	cat ~/.ssh/sshkey.pub >>~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	ip_address
	echo -e "私鑰資訊已生成，務必複製保存，可保存成 ${gl_huang}${ipv4_address}_ssh.key${gl_bai} 文件，用於以後的SSH登錄"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT私鑰登錄已開啟，已關閉ROOT密碼登錄，重連將會生效${gl_bai}"

}

import_sshkey() {

	Ask "請輸入您的SSH公鑰內容（通常以 'ssh-rsa' 或 'ssh-ed25519' 開頭）: " public_key

	if [[ -z $public_key ]]; then
		echo -e "${gl_hong}錯誤：未輸入公鑰內容。${gl_bai}"
		return 1
	fi

	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	echo "$public_key" >>~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}公鑰已成功匯入，ROOT私鑰登錄已開啟，已關閉ROOT密碼登錄，重連將會生效${gl_bai}"

}

add_sshpasswd() {

	echo "設定你的ROOT密碼"
	passwd
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT登錄設置完畢！${gl_bai}"

}

root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示: ${gl_bai}該功能需要root用戶才能運行！" && break_end && kejilion
}

dd_xitong() {
	send_stats "重装系统"
	dd_xitong_MollyLau() {
		wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

	}

	dd_xitong_bin456789() {
		curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
	}

	dd_xitong_1() {
		echo -e "重裝後初始用戶名: ${gl_huang}root${gl_bai}  初始密碼: ${gl_huang}LeitboGi0ro${gl_bai}  初始端口: ${gl_huang}22${gl_bai}"
		Press "按任意鍵繼續..."
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_2() {
		echo -e "重裝後初始用戶名: ${gl_huang}Administrator${gl_bai}  初始密碼: ${gl_huang}Teddysun.com${gl_bai}  初始端口: ${gl_huang}3389${gl_bai}"
		Press "按任意鍵繼續..."
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_3() {
		echo -e "重裝後初始用戶名: ${gl_huang}root${gl_bai}  初始密碼: ${gl_huang}123@@@${gl_bai}  初始端口: ${gl_huang}22${gl_bai}"
		Press "按任意鍵繼續..."
		dd_xitong_bin456789
	}

	dd_xitong_4() {
		echo -e "重裝後初始用戶名: ${gl_huang}Administrator${gl_bai}  初始密碼: ${gl_huang}123@@@${gl_bai}  初始端口: ${gl_huang}3389${gl_bai}"
		Press "按任意鍵繼續..."
		dd_xitong_bin456789
	}

	while true; do
		root_use
		echo "重裝系統"
		echo "--------------------------------"
		echo -e "${gl_hong}注意: ${gl_bai}重裝有風險失聯，不放心者慎用。重裝預計花費15分鐘，請提前備份數據。"
		echo -e "${gl_hui}感謝MollyLau大佬和bin456789大佬的腳本支持！${gl_bai} "
		echo "------------------------"
		echo "1. Debian 12                  2. Debian 11"
		echo "3. Debian 10                  4. Debian 9"
		echo "------------------------"
		echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
		echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
		echo "------------------------"
		echo "21. Rocky Linux 10            22. Rocky Linux 9"
		echo "23. Alma Linux 10             24. Alma Linux 9"
		echo "25. oracle Linux 10           26. oracle Linux 9"
		echo "27. Fedora Linux 42           28. Fedora Linux 41"
		echo "29. CentOS 10                 30. CentOS 9"
		echo "------------------------"
		echo "31. Alpine Linux              32. Arch Linux"
		echo "33. Kali Linux                34. openEuler"
		echo "35. openSUSE Tumbleweed       36. fnos飛牛公測版"
		echo "------------------------"
		echo "41. Windows 11                42. Windows 10"
		echo "43. Windows 7                 44. Windows Server 2022"
		echo "45. Windows Server 2019       46. Windows Server 2016"
		echo "47. Windows 11 ARM"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請選擇要重裝的系統: " sys_choice
		case "$sys_choice" in
		1)
			send_stats "重装debian 12"
			dd_xitong_1
			bash InstallNET.sh -debian 12
			reboot
			exit
			;;
		2)
			send_stats "重装debian 11"
			dd_xitong_1
			bash InstallNET.sh -debian 11
			reboot
			exit
			;;
		3)
			send_stats "重装debian 10"
			dd_xitong_1
			bash InstallNET.sh -debian 10
			reboot
			exit
			;;
		4)
			send_stats "重装debian 9"
			dd_xitong_1
			bash InstallNET.sh -debian 9
			reboot
			exit
			;;
		11)
			send_stats "重装ubuntu 24.04"
			dd_xitong_1
			bash InstallNET.sh -ubuntu 24.04
			reboot
			exit
			;;
		12)
			send_stats "重装ubuntu 22.04"
			dd_xitong_1
			bash InstallNET.sh -ubuntu 22.04
			reboot
			exit
			;;
		13)
			send_stats "重装ubuntu 20.04"
			dd_xitong_1
			bash InstallNET.sh -ubuntu 20.04
			reboot
			exit
			;;
		14)
			send_stats "重装ubuntu 18.04"
			dd_xitong_1
			bash InstallNET.sh -ubuntu 18.04
			reboot
			exit
			;;

		21)
			send_stats "重装rockylinux10"
			dd_xitong_3
			bash reinstall.sh rocky
			reboot
			exit
			;;

		22)
			send_stats "重装rockylinux9"
			dd_xitong_3
			bash reinstall.sh rocky 9
			reboot
			exit
			;;

		23)
			send_stats "重装alma10"
			dd_xitong_3
			bash reinstall.sh almalinux
			reboot
			exit
			;;

		24)
			send_stats "重装alma9"
			dd_xitong_3
			bash reinstall.sh almalinux 9
			reboot
			exit
			;;

		25)
			send_stats "重装oracle10"
			dd_xitong_3
			bash reinstall.sh oracle
			reboot
			exit
			;;

		26)
			send_stats "重装oracle9"
			dd_xitong_3
			bash reinstall.sh oracle 9
			reboot
			exit
			;;

		27)
			send_stats "重装fedora42"
			dd_xitong_3
			bash reinstall.sh fedora
			reboot
			exit
			;;

		28)
			send_stats "重装fedora41"
			dd_xitong_3
			bash reinstall.sh fedora 41
			reboot
			exit
			;;

		29)
			send_stats "重装centos10"
			dd_xitong_3
			bash reinstall.sh centos 10
			reboot
			exit
			;;

		30)
			send_stats "重装centos9"
			dd_xitong_3
			bash reinstall.sh centos 9
			reboot
			exit
			;;

		31)
			send_stats "重装alpine"
			dd_xitong_1
			bash InstallNET.sh -alpine
			reboot
			exit
			;;

		32)
			send_stats "重装arch"
			dd_xitong_3
			bash reinstall.sh arch
			reboot
			exit
			;;

		33)
			send_stats "重装kali"
			dd_xitong_3
			bash reinstall.sh kali
			reboot
			exit
			;;

		34)
			send_stats "重装openeuler"
			dd_xitong_3
			bash reinstall.sh openeuler
			reboot
			exit
			;;

		35)
			send_stats "重装opensuse"
			dd_xitong_3
			bash reinstall.sh opensuse
			reboot
			exit
			;;

		36)
			send_stats "重装飞牛"
			dd_xitong_3
			bash reinstall.sh fnos
			reboot
			exit
			;;

		41)
			send_stats "重装windows11"
			dd_xitong_2
			bash InstallNET.sh -windows 11 -lang "cn"
			reboot
			exit
			;;
		42)
			dd_xitong_2
			send_stats "重装windows10"
			bash InstallNET.sh -windows 10 -lang "cn"
			reboot
			exit
			;;
		43)
			send_stats "重装windows7"
			dd_xitong_4
			bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
			reboot
			exit
			;;

		44)
			send_stats "重装windows server 22"
			dd_xitong_2
			bash InstallNET.sh -windows 2022 -lang "cn"
			reboot
			exit
			;;
		45)
			send_stats "重装windows server 19"
			dd_xitong_2
			bash InstallNET.sh -windows 2019 -lang "cn"
			reboot
			exit
			;;
		46)
			send_stats "重装windows server 16"
			dd_xitong_2
			bash InstallNET.sh -windows 2016 -lang "cn"
			reboot
			exit
			;;

		47)
			send_stats "重装windows11 ARM"
			dd_xitong_4
			bash reinstall.sh dd --img https://r2.hotdog.eu.org/win11-arm-with-pagefile-15g.xz
			reboot
			exit
			;;

		*)
			break
			;;
		esac
	done
}

bbrv3() {
	root_use
	send_stats "bbrv3管理"

	local cpu_arch=$(uname -m)
	if [ "$cpu_arch" = "aarch64" ]; then
		bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
		break_end
		linux_Settings
	fi

	if dpkg -l | grep -q 'linux-xanmod'; then
		while true; do
			clear
			local kernel_version=$(uname -r)
			echo "您已安裝xanmod的BBRv3核心"
			echo "目前核心版本: $kernel_version"

			echo
			echo "核心管理"
			echo "------------------------"
			echo "1. 更新BBRv3核心              2. 卸載BBRv3核心"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			Ask "請輸入您的選擇: " sub_choice

			case $sub_choice in
			1)
				apt purge -y 'linux-*xanmod1*'
				update-grub

				# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
				wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

				# 步骤3：添加存储库
				echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

				# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
				local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

				apt update -y
				apt install -y linux-xanmod-x64v$version

				echo "XanMod核心已更新。重啟後生效"
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f check_x86-64_psabi.sh*

				server_reboot

				;;
			2)
				apt purge -y 'linux-*xanmod1*'
				update-grub
				echo "XanMod核心已卸載。重啟後生效"
				server_reboot
				;;

			*)
				break
				;;

			esac
		done
	else

		clear
		echo "設定BBR3加速"
		echo "影片介紹: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		echo "------------------------------------------------"
		echo "僅支援Debian/Ubuntu"
		echo "請備份資料，將為您升級Linux核心開啟BBR3"
		echo "VPS是512M記憶體，請提前添加1G虛擬記憶體，防止因記憶體不足失聯！"
		echo "------------------------------------------------"
		Ask "確定繼續嗎？(y/N): " choice

		case "$choice" in
		[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "目前環境不支援，僅支援Debian和Ubuntu系統"
					break_end
					linux_Settings
				fi
			else
				echo "無法確定作業系統類型"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 步骤3：添加存储库
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanMod核心安裝並BBR3啟用成功。重啟後生效"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			;;
		[Nn])
			echo "已取消"
			;;
		*)
			echo "無效的選擇，請輸入 Y 或 N。"
			;;
		esac
	fi

}

elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "匯入 ELRepo GPG 公鑰..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ $os_name != *"Red Hat"* && $os_name != *"AlmaLinux"* && $os_name != *"Rocky"* && $os_name != *"Oracle"* && $os_name != *"CentOS"* ]]; then
		echo "不支援的作業系統：$os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "偵測到的作業系統: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ $os_version == 8 ]]; then
		echo "安裝 ELRepo 倉庫配置 (版本 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ $os_version == 9 ]]; then
		echo "安裝 ELRepo 倉庫配置 (版本 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ $os_version == 10 ]]; then
		echo "安裝 ELRepo 倉庫配置 (版本 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "不支援的系統版本：$os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "啟用 ELRepo 核心倉庫並安裝最新的主線核心..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "已安裝 ELRepo 倉庫配置並更新到最新主線核心。"
	server_reboot

}

elrepo() {
	root_use
	send_stats "红帽内核管理"
	if uname -r | grep -q 'elrepo'; then
		while true; do
			clear
			kernel_version=$(uname -r)
			echo "您已安裝elrepo核心"
			echo "目前核心版本: $kernel_version"

			echo
			echo "核心管理"
			echo "------------------------"
			echo "1. 更新elrepo核心              2. 卸載elrepo核心"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			Ask "請輸入您的選擇: " sub_choice

			case $sub_choice in
			1)
				dnf remove -y elrepo-release
				rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
				elrepo_install
				send_stats "更新红帽内核"
				server_reboot

				;;
			2)
				dnf remove -y elrepo-release
				rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
				echo "elrepo核心已卸載。重啟後生效"
				send_stats "卸载红帽内核"
				server_reboot

				;;
			*)
				break
				;;

			esac
		done
	else

		clear
		echo "請備份資料，將為您升級Linux核心"
		echo "影片介紹: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		echo "------------------------------------------------"
		echo "僅支援紅帽系列發行版 CentOS/RedHat/Alma/Rocky/oracle "
		echo "升級Linux核心可提升系統效能和安全，建議有條件的嘗試，生產環境謹慎升級！"
		echo "------------------------------------------------"
		Ask "確定繼續嗎？(y/N): " choice

		case "$choice" in
		[Yy])
			check_swap
			elrepo_install
			send_stats "升级红帽内核"
			server_reboot
			;;
		[Nn])
			echo "已取消"
			;;
		*)
			echo "無效的選擇，請輸入 Y 或 N。"
			;;
		esac
	fi

}

clamav_freshclam() {
	echo -e "${gl_huang}正在更新病毒庫...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "請指定要掃描的目錄。"
		return
	fi

	echo -e "${gl_huang}正在掃描目錄$@... ${gl_bai}"

	# 构建 mount 参数
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# 构建 clamscan 命令参数
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ >/dev/null 2>&1
	>/home/docker/clamav/log/scan.log >/dev/null 2>&1

	# 执行 Docker 命令
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ 掃描完成，病毒報告存放在${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}如果有病毒請在${gl_huang}scan.log${gl_lv}文件中搜索FOUND關鍵字確認病毒位置 ${gl_bai}"

}

clamav() {
	root_use
	send_stats "病毒扫描管理"
	while true; do
		clear
		echo "clamav病毒掃描工具"
		echo "影片介紹: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
		echo "------------------------"
		echo "是一個開源的防病毒軟體工具，主要用於偵測和刪除各種類型的惡意軟體。"
		echo "包括病毒、木馬程式、間諜軟體、惡意腳本和其他有害軟體。"
		echo "------------------------"
		echo -e "${gl_lv}1. 全盤掃描 ${gl_bai}             ${gl_huang}2. 重要目錄掃描 ${gl_bai}            ${gl_kjlan} 3. 自定義目錄掃描 ${gl_bai}"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			send_stats "全盘扫描"
			install_docker
			docker volume create clam_db >/dev/null 2>&1
			clamav_freshclam
			clamav_scan /
			break_end

			;;
		2)
			send_stats "重要目录扫描"
			install_docker
			docker volume create clam_db >/dev/null 2>&1
			clamav_freshclam
			clamav_scan /etc /var /usr /home /root
			break_end
			;;
		3)
			send_stats "自定义目录扫描"
			Ask "請輸入要掃描的目錄，用空格分隔（例如：/etc /var /usr /home /root）: " directories
			install_docker
			clamav_freshclam
			clamav_scan $directories
			break_end
			;;
		*)
			break
			;;
		esac
	done

}

# 高性能模式优化函数
optimize_high_performance() {
	echo -e "${gl_lv}切換到${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}優化文件描述符...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}優化虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}優化網絡設置...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=250000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

	echo -e "${gl_lv}優化緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}優化CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}其他優化...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}切換到均衡模式...${gl_bai}"

	echo -e "${gl_lv}優化文件描述符...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}優化虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}優化網絡設置...${gl_bai}"
	sysctl -w net.core.rmem_max=8388608 2>/dev/null
	sysctl -w net.core.wmem_max=8388608 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=125000 2>/dev/null
	sysctl -w net.core.somaxconn=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 32768 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 49151' 2>/dev/null

	echo -e "${gl_lv}優化緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}優化CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}其他優化...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}還原到默認設置...${gl_bai}"

	echo -e "${gl_lv}還原文件描述符...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}還原虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}還原網絡設置...${gl_bai}"
	sysctl -w net.core.rmem_max=212992 2>/dev/null
	sysctl -w net.core.wmem_max=212992 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=1000 2>/dev/null
	sysctl -w net.core.somaxconn=128 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 6291456' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 16384 4194304' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=0 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='32768 60999' 2>/dev/null

	echo -e "${gl_lv}還原緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}還原CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}還原其他優化...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}切換到網站搭建優化模式...${gl_bai}"

	echo -e "${gl_lv}優化文件描述符...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}優化虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}優化網絡設置...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

	echo -e "${gl_lv}優化緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}優化CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}其他優化...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

Kernel_optimize() {
	root_use
	while true; do
		clear
		send_stats "Linux内核调优管理"
		echo "Linux系統核心參數優化"
		echo "影片介紹: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
		echo "------------------------------------------------"
		echo "提供多種系統參數調優模式，用戶可以根據自身使用場景進行選擇切換。"
		echo -e "${gl_huang}提示: ${gl_bai}生產環境請謹慎使用！"
		echo "--------------------"
		echo "1. 高效能優化模式：     最大化系統效能，優化檔案描述符、虛擬記憶體、網路設定、快取管理和CPU設定。"
		echo "2. 平衡優化模式：       在效能與資源消耗之間取得平衡，適合日常使用。"
		echo "3. 網站優化模式：       針對網站伺服器進行優化，提高併發連接處理能力、響應速度和整體效能。"
		echo "4. 直播優化模式：       針對直播推流的特殊需求進行優化，減少延遲，提高傳輸效能。"
		echo "5. 遊戲服優化模式：     針對遊戲伺服器進行優化，提高併發處理能力和響應速度。"
		echo "6. 還原預設設定：       將系統設定還原為預設配置。"
		echo "--------------------"
		echo "0. 返回上一級選單"
		echo "--------------------"
		Ask "請輸入您的選擇: " sub_choice
		case $sub_choice in
		1)
			cd ~
			clear
			local tiaoyou_moshi="高效能優化模式"
			optimize_high_performance
			send_stats "高性能模式优化"
			;;
		2)
			cd ~
			clear
			optimize_balanced
			send_stats "均衡模式优化"
			;;
		3)
			cd ~
			clear
			optimize_web_server
			send_stats "网站优化模式"
			;;
		4)
			cd ~
			clear
			local tiaoyou_moshi="直播優化模式"
			optimize_high_performance
			send_stats "直播推流优化"
			;;
		5)
			cd ~
			clear
			local tiaoyou_moshi="遊戲服優化模式"
			optimize_high_performance
			send_stats "游戏服优化"
			;;
		6)
			cd ~
			clear
			restore_defaults
			send_stats "还原默认设置"
			;;
		*)
			break
			;;
		esac
		break_end
	done
}

update_locale() {
	local lang=$1
	local locale_file=$2

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case $ID in
		debian | ubuntu | kali)
			install locales
			sed -i "s/^\s*#\?\s*${locale_file}/${locale_file}/" /etc/locale.gen
			locale-gen
			echo "LANG=${lang}" >/etc/default/locale
			export LANG=${lang}
			echo -e "${gl_lv}系統語言已經修改為: $lang 重新連接SSH生效。${gl_bai}"
			hash -r
			break_end

			;;
		centos | rhel | almalinux | rocky | fedora)
			install glibc-langpack-zh
			localectl set-locale LANG=${lang}
			echo "LANG=${lang}" | tee /etc/locale.conf
			echo -e "${gl_lv}系統語言已經修改為: $lang 重新連接SSH生效。${gl_bai}"
			hash -r
			break_end
			;;
		*)
			echo "不支援的系統: $ID"
			break_end
			;;
		esac
	else
		echo "不支援的系統，無法識別系統類型。"
		break_end
	fi
}

linux_language() {
	root_use
	send_stats "切换系统语言"
	while true; do
		clear
		echo "目前系統語言: $LANG"
		echo "------------------------"
		echo "1. 英文          2. 簡體中文          3. 繁體中文"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice

		case $choice in
		1)
			update_locale "en_US.UTF-8" "en_US.UTF-8"
			send_stats "切换到英文"
			;;
		2)
			update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
			send_stats "切换到简体中文"
			;;
		3)
			update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
			send_stats "切换到繁体中文"
			;;
		*)
			break
			;;
		esac
	done
}

shell_bianse_profile() {

	if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
		sed -i '/^PS1=/d' ~/.bashrc
		echo "${bianse}" >>~/.bashrc
		# source ~/.bashrc
	else
		sed -i '/^PS1=/d' ~/.profile
		echo "${bianse}" >>~/.profile
		# source ~/.profile
	fi
	echo -e "${gl_lv}變更完成。重新連接SSH後可查看變化！${gl_bai}"

	hash -r
	break_end

}

shell_bianse() {
	root_use
	send_stats "命令行美化工具"
	while true; do
		clear
		echo "命令行美化工具"
		echo "------------------------"
		echo -e "1. \\033[1;32mroot \\033[1;34mlocalhost \\033[1;31m~ \\033[0m${gl_bai}#"
		echo -e "2. \\033[1;35mroot \\033[1;36mlocalhost \\033[1;33m~ \\033[0m${gl_bai}#"
		echo -e "3. \\033[1;31mroot \\033[1;32mlocalhost \\033[1;34m~ \\033[0m${gl_bai}#"
		echo -e "4. \\033[1;36mroot \\033[1;33mlocalhost \\033[1;37m~ \\033[0m${gl_bai}#"
		echo -e "5. \\033[1;37mroot \\033[1;31mlocalhost \\033[1;32m~ \\033[0m${gl_bai}#"
		echo -e "6. \\033[1;33mroot \\033[1;34mlocalhost \\033[1;35m~ \\033[0m${gl_bai}#"
		echo -e "7. root localhost ~ #"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice

		case $choice in
		1)
			local bianse="PS1='\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;31m\]\w\[\033[0m\] # '"
			shell_bianse_profile

			;;
		2)
			local bianse="PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;33m\]\w\[\033[0m\] # '"
			shell_bianse_profile
			;;
		3)
			local bianse="PS1='\[\033[1;31m\]\u\[\033[0m\]@\[\033[1;32m\]\h\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\] # '"
			shell_bianse_profile
			;;
		4)
			local bianse="PS1='\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\] \[\033[1;37m\]\w\[\033[0m\] # '"
			shell_bianse_profile
			;;
		5)
			local bianse="PS1='\[\033[1;37m\]\u\[\033[0m\]@\[\033[1;31m\]\h\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] # '"
			shell_bianse_profile
			;;
		6)
			local bianse="PS1='\[\033[1;33m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;35m\]\w\[\033[0m\] # '"
			shell_bianse_profile
			;;
		7)
			local bianse=""
			shell_bianse_profile
			;;
		*)
			break
			;;
		esac

	done
}

linux_trash() {
	root_use
	send_stats "系统回收站"

	local bashrc_profile="/root/.bashrc"
	local TRASH_DIR="$HOME/.local/share/Trash/files"

	while true; do

		local trash_status
		if ! grep -q "trash-put" "$bashrc_profile"; then
			trash_status="${gl_hui}未啟用${gl_bai}"
		else
			trash_status="${gl_lv}已啟用${gl_bai}"
		fi

		clear
		echo -e "當前回收站 ${trash_status}"
		echo -e "啟用後rm刪除的文件先進入回收站，防止誤刪重要文件！"
		echo "------------------------------------------------"
		ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "資源回收筒為空"
		echo "------------------------"
		echo "1. 啟用資源回收筒          2. 關閉資源回收筒"
		echo "3. 還原內容            4. 清空資源回收筒"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice

		case $choice in
		1)
			install trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='trash-put'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "資源回收筒已啟用，刪除的檔案將移至資源回收筒。"
			sleep 2
			;;
		2)
			remove trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='rm -i'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "資源回收筒已關閉，檔案將直接刪除。"
			sleep 2
			;;
		3)
			Ask "輸入要還原的文件名: " file_to_restore
			if [ -e "$TRASH_DIR/$file_to_restore" ]; then
				mv "$TRASH_DIR/$file_to_restore" "$HOME/"
				echo "$file_to_restore 已還原到主目錄。"
			else
				echo "檔案不存在。"
			fi
			;;
		4)
			Ask "確認清空回收站？(y/N): " confirm
			if [[ $confirm == "y" ]]; then
				trash-empty
				echo "資源回收筒已清空。"
			fi
			;;
		*)
			break
			;;
		esac
	done
}

# 创建备份
create_backup() {
	send_stats "创建备份"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 提示用户输入备份目录
	echo "建立備份範例："
	echo "  - 備份單一目錄: /var/www"
	echo "  - 備份多個目錄: /etc /home /var/log"
	echo "  - 直接按Enter將使用預設目錄 (/etc /usr /home)"
	Ask "請輸入要備份的目錄（多個目錄用空格分隔，直接回車則使用預設目錄）：" input

	# 如果用户没有输入目录，则使用默认目录
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"  # 配置文件和软件包配置
			"/usr"  # 已安装的软件文件
			"/home" # 用户数据
		)
	else
		# 将用户输入的目录按空格分隔成数组
		IFS=' ' read -r -a BACKUP_PATHS <<<"$input"
	fi

	# 生成备份文件前缀
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 提取目录名称并去除斜杠
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 去除最后一个下划线
	local PREFIX=${PREFIX%_}

	# 生成备份文件名
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 打印用户选择的目录
	echo "您選擇的備份目錄為："
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "正在建立備份 $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "備份建立成功: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "備份建立失敗！"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	Ask "請輸入要恢復的備份文件名: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "備份檔案不存在！"
		exit 1
	fi

	echo "正在恢復備份 $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "備份恢復成功！"
	else
		echo "備份恢復失敗！"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "可用的備份："
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	Ask "請輸入要刪除的備份文件名: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "備份檔案不存在！"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "備份刪除成功！"
	else
		echo "備份刪除失敗！"
		exit 1
	fi
}

# 备份主菜单
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "系统备份功能"
		echo "系統備份功能"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. 創建備份        2. 恢復備份        3. 刪除備份"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1) create_backup ;;
		2) restore_backup ;;
		3) delete_backup ;;
		*) break ;;
		esac
		Press "按 Enter 鍵繼續..."
	done
}

# 显示连接列表
list_connections() {
	echo "已儲存的連線:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}

# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "創建新連線範例："
	echo "  - 連線名稱: my_server"
	echo "  - IP位址: 192.168.1.100"
	echo "  - 使用者名稱: root"
	echo "  - 連接埠: 22"
	echo "------------------------"
	Ask "請輸入連接名稱: " name
	Ask "請輸入IP地址: " ip
	Ask "請輸入用戶名 (預設: root): " user
	local user=${user:-root} # 如果用户未输入，则使用默认值 root
	Ask "請輸入端口號 (預設: 22): " port
	local port=${port:-22} # 如果用户未输入，则使用默认值 22

	echo "請選擇身份驗證方式:"
	echo "1. 密碼"
	echo "2. 金鑰"
	Ask "請輸入選擇 (1/2): " auth_choice

	case $auth_choice in
	1)
		Ask "請輸入密碼: " -s password_or_key
		echo # 换行
		;;
	2)
		echo "請貼上金鑰內容 (貼上完成後按兩次回車)："
		local password_or_key=""
		while IFS= read -r line; do
			# 如果输入为空行且密钥内容已经包含了开头，则结束输入
			if [[ -z $line && $password_or_key == *"-----BEGIN"* ]]; then
				break
			fi
			# 如果是第一行或已经开始输入密钥内容，则继续添加
			if [[ -n $line || $password_or_key == *"-----BEGIN"* ]]; then
				local password_or_key+="${line}"$'\n'
			fi
		done

		# 检查是否是密钥内容
		if [[ $password_or_key == *"-----BEGIN"* && $password_or_key == *"PRIVATE KEY-----"* ]]; then
			local key_file="$KEY_DIR/$name.key"
			echo -n "$password_or_key" >"$key_file"
			chmod 600 "$key_file"
			local password_or_key="$key_file"
		fi
		;;
	*)
		echo "無效的選擇！"
		return
		;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >>"$CONFIG_FILE"
	echo "連線已儲存!"
}

# 删除连接
delete_connection() {
	send_stats "删除连接"
	Ask "請輸入要刪除的連接編號: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $connection ]]; then
		echo "錯誤：未找到對應的連線。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ $password_or_key == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "連線已刪除!"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	Ask "請輸入要使用的連接編號: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $connection ]]; then
		echo "錯誤：未找到對應的連線。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	echo "正在連線到 $name ($ip)..."
	if [[ -f $password_or_key ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "連線失敗！請檢查以下內容："
			echo "1. 金鑰檔案路徑是否正確：$password_or_key"
			echo "2. 金鑰檔案權限是否正確（應為 600）。"
			echo "3. 目標伺服器是否允許使用金鑰登入。"
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &>/dev/null; then
			echo "錯誤：未安裝 sshpass，請先安裝 sshpass。"
			echo "安裝方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "連線失敗！請檢查以下內容："
			echo "1. 使用者名稱和密碼是否正確。"
			echo "2. 目標伺服器是否允許密碼登入。"
			echo "3. 目標伺服器的 SSH 服務是否正常運行。"
		fi
	fi
}

ssh_manager() {
	send_stats "ssh远程连接工具"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 检查配置文件和密钥目录是否存在，如果不存在则创建
	if [[ ! -f $CONFIG_FILE ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d $KEY_DIR ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSH 遠端連線工具"
		echo "可以透過SSH連線到其他Linux系統上"
		echo "------------------------"
		list_connections
		echo "1. 創建新連線        2. 使用連線        3. 刪除連線"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1) add_connection ;;
		2) use_connection ;;
		3) delete_connection ;;
		0) break ;;
		*) echo "無效的選擇，請重試。" ;;
		esac
	done
}

# 列出可用的硬盘分区
list_partitions() {
	echo "可用的硬碟分割區："
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	Ask "請輸入要掛載的分區名稱（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "分割區不存在！"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "分割區已經掛載！"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "分割區掛載成功: $MOUNT_POINT"
	else
		echo "分割區掛載失敗！"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	Ask "請輸入要卸載的分區名稱（例如 sda1）: " PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "分割區未掛載！"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "分割區卸載成功: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "分割區卸載失敗！"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "已掛載的分割區："
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	Ask "請輸入要格式化的分區名稱（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "分割區不存在！"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "分割區已經掛載，請先卸載！"
		return
	fi

	# 选择文件系统类型
	echo "請選擇檔案系統類型："
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	Ask "請輸入您的選擇: " FS_CHOICE

	case $FS_CHOICE in
	1) FS_TYPE="ext4" ;;
	2) FS_TYPE="xfs" ;;
	3) FS_TYPE="ntfs" ;;
	4) FS_TYPE="vfat" ;;
	*)
		echo "無效的選擇！"
		return
		;;
	esac

	# 确认格式化
	Ask "確認格式化分區 /dev/$PARTITION 為 $FS_TYPE 嗎？(y/N): " CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作已取消。"
		return
	fi

	# 格式化分区
	echo "正在格式化分割區 /dev/$PARTITION 為 $FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "分割區格式化成功！"
	else
		echo "分割區格式化失敗！"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	Ask "請輸入要檢查的分區名稱（例如 sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "分割區不存在！"
		return
	fi

	# 检查分区状态
	echo "檢查分割區 /dev/$PARTITION 的狀態："
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "硬碟分割區管理"
		echo -e "${gl_huang}該功能內部測試階段，請勿在生產環境使用。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. 掛載分割區        2. 卸載分割區        3. 查看已掛載分割區"
		echo "4. 格式化分割區      5. 檢查分割區狀態"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1) mount_partition ;;
		2) unmount_partition ;;
		3) list_mounted_partitions ;;
		4) format_partition ;;
		5) check_partition ;;
		*) break ;;
		esac
		Press "按 Enter 鍵繼續..."
	done
}

# 显示任务列表
list_tasks() {
	echo "已儲存的同步任務:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "創建新同步任務範例："
	echo "  - 任務名稱: backup_www"
	echo "  - 本機目錄: /var/www"
	echo "  - 遠端位址: user@192.168.1.100"
	echo "  - 遠端目錄: /backup/www"
	echo "  - 連接埠號 (預設 22)"
	echo "---------------------------------"
	Ask "請輸入任務名稱: " name
	Ask "請輸入本地目錄: " local_path
	Ask "請輸入遠端目錄: " remote_path
	Ask "請輸入遠端用戶@IP: " remote
	Ask "請輸入 SSH 端口 (預設 22): " port
	port=${port:-22}

	echo "請選擇身份驗證方式:"
	echo "1. 密碼"
	echo "2. 金鑰"
	Ask "請選擇 (1/2): " auth_choice

	case $auth_choice in
	1)
		Ask "請輸入密碼: " -s password_or_key
		echo # 换行
		auth_method="password"
		;;
	2)
		echo "請貼上金鑰內容 (貼上完成後按兩次回車)："
		local password_or_key=""
		while IFS= read -r line; do
			# 如果输入为空行且密钥内容已经包含了开头，则结束输入
			if [[ -z $line && $password_or_key == *"-----BEGIN"* ]]; then
				break
			fi
			# 如果是第一行或已经开始输入密钥内容，则继续添加
			if [[ -n $line || $password_or_key == *"-----BEGIN"* ]]; then
				password_or_key+="${line}"$'\n'
			fi
		done

		# 检查是否是密钥内容
		if [[ $password_or_key == *"-----BEGIN"* && $password_or_key == *"PRIVATE KEY-----"* ]]; then
			local key_file="$KEY_DIR/${name}_sync.key"
			echo -n "$password_or_key" >"$key_file"
			chmod 600 "$key_file"
			password_or_key="$key_file"
			auth_method="key"
		else
			echo "無效的金鑰內容！"
			return
		fi
		;;
	*)
		echo "無效的選擇！"
		return
		;;
	esac

	echo "請選擇同步模式:"
	echo "1. 標準模式 (-avz)"
	echo "2. 刪除目標檔案 (-avz --delete)"
	Ask "請選擇 (1/2): " mode
	case $mode in
	1) options="-avz" ;;
	2) options="-avz --delete" ;;
	*)
		echo "無效選擇，使用預設 -avz"
		options="-avz"
		;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >>"$CONFIG_FILE"

	install rsync rsync

	echo "任務已儲存!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	Ask "請輸入要刪除的任務編號: " num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $task ]]; then
		echo "錯誤：未找到對應的任務。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ $auth_method == "key" && $password_or_key == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "任務已刪除!"
}

run_task() {
	send_stats "执行同步任务"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 解析参数
	local direction="push" # 默认是推送到远端
	local num

	if [[ $1 == "push" || $1 == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 如果没有传入任务编号，提示用户输入
	if [[ -z $num ]]; then
		Ask "請輸入要執行的任務編號: " num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $task ]]; then
		echo "錯誤: 未找到該任務!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 根据同步方向调整源和目标路径
	if [[ $direction == "pull" ]]; then
		echo "正在拉取同步到本機: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "正在推送同步到遠端: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ $auth_method == "password" ]]; then
		if ! command -v sshpass &>/dev/null; then
			echo "錯誤：未安裝 sshpass，請先安裝 sshpass。"
			echo "安裝方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f $password_or_key ]]; then
			echo "錯誤：金鑰檔案不存在：$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "警告：金鑰檔案權限不正確，正在修復..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "同步完成!"
	else
		echo "同步失敗! 請檢查以下內容："
		echo "1. 網路連線是否正常"
		echo "2. 遠端主機是否可存取"
		echo "3. 認證資訊是否正確"
		echo "4. 本機和遠端目錄是否有正確的存取權限"
	fi
}

# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	Ask "請輸入要定時同步的任務編號: " num
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		echo "錯誤: 請輸入有效的任務編號！"
		return
	fi

	echo "請選擇定時執行間隔："
	echo "1) 每小時執行一次"
	echo "2) 每天執行一次"
	echo "3) 每週執行一次"
	Ask "請輸入選項 (1/2/3): " interval

	local random_minute=$(shuf -i 0-59 -n 1)
	# 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
	1) cron_time="$random_minute * * * *" ;; # 每小时，随机分钟执行
	2) cron_time="$random_minute 0 * * *" ;; # 每天，随机分钟执行
	3) cron_time="$random_minute 0 * * 1" ;; # 每周，随机分钟执行
	*)
		echo "錯誤: 請輸入有效的選項！"
		return
		;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "錯誤: 該任務的定時同步已存在！"
		return
	fi

	# 创建到用户的 crontab
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "定時任務已創建: $cron_job"
}

# 查看定时任务
view_tasks() {
	echo "目前的定時任務:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	Ask "請輸入要刪除的任務編號: " num
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		echo "錯誤: 請輸入有效的任務編號！"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "已刪除任務編號 $num 的定時任務"
}

# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync 遠端同步工具"
		echo "遠端目錄之間同步，支援增量同步，高效穩定。"
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 建立新任務                 2. 刪除任務"
		echo "3. 執行本地同步到遠端         4. 執行遠端同步到本地"
		echo "5. 建立定時任務               6. 刪除定時任務"
		echo "---------------------------------"
		echo "0. 返回上一級選單"
		echo "---------------------------------"
		Ask "請輸入您的選擇: " choice
		case $choice in
		1) add_task ;;
		2) delete_task ;;
		3) run_task push ;;
		4) run_task pull ;;
		5) schedule_task ;;
		6) delete_task_schedule ;;
		0) break ;;
		*) echo "無效的選擇，請重試。" ;;
		esac
		Press "按 Enter 鍵繼續..."
	done
}

linux_ps() {
	clear
	send_stats "系统信息查询"

	ip_address

	echo
	echo -e "系統信息查詢"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}主機名:       ${gl_bai}$(uname -n || hostname)"
	echo -e "${gl_kjlan}系統版本:     ${gl_bai}$(ChkOs)"
	echo -e "${gl_kjlan}Linux版本:    ${gl_bai}$(uname -r)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU架構:      ${gl_bai}$(uname -m)"
	echo -e "${gl_kjlan}CPU型號:      ${gl_bai}$(CpuModel)"
	echo -e "${gl_kjlan}CPU核心數:    ${gl_bai}$(nproc)"
	echo -e "${gl_kjlan}CPU頻率:      ${gl_bai}$(CpuFreq)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU占用:      ${gl_bai}$(CpuUsage)%"
	echo -e "${gl_kjlan}系統負載:     ${gl_bai}$(LoadAvg)"
	echo -e "${gl_kjlan}物理內存:     ${gl_bai}$(MemUsage)"
	echo -e "${gl_kjlan}虛擬內存:     ${gl_bai}$(SwapUsage)"
	echo -e "${gl_kjlan}硬盤占用:     ${gl_bai}$(DiskUsage)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}總接收:       ${gl_bai}$(ConvSz $(Iface --rx_bytes))"
	echo -e "${gl_kjlan}總發送:       ${gl_bai}$(ConvSz $(Iface --tx_bytes))"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}網絡算法:     ${gl_bai}$(sysctl -n net.ipv4.tcp_congestion_control) $(sysctl -n net.core.default_qdisc)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}運營商:       ${gl_bai}$(NetProv)"
	echo -e "${gl_kjlan}IPv4地址:     ${gl_bai}$(IpAddr --ipv4)"
	echo -e "${gl_kjlan}IPv6地址:     ${gl_bai}$(IpAddr --ipv6)"
	echo -e "${gl_kjlan}DNS地址:      ${gl_bai}$(DnsAddr)"
	echo -e "${gl_kjlan}地理位置:     ${gl_bai}$(Loc --country)$(Loc --city)"
	echo -e "${gl_kjlan}系統時間:     ${gl_bai}$(TimeZn --internal)$(date +"%Y-%m-%d %H:%M:%S")"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}運行時長:     ${gl_bai}$(uptime -p | sed 's/up //')"
	echo
}

linux_tools() {

	while true; do
		clear
		# send_stats "基础工具"
		echo -e "基礎工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}curl 下載工具 ${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget 下載工具 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}3.   ${gl_bai}sudo 超級管理權限工具             ${gl_kjlan}4.   ${gl_bai}socat 通信連接工具"
		echo -e "${gl_kjlan}5.   ${gl_bai}htop 系統監控工具                 ${gl_kjlan}6.   ${gl_bai}iftop 網絡流量監控工具"
		echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP壓縮解壓工具             ${gl_kjlan}8.   ${gl_bai}tar GZ壓縮解壓工具"
		echo -e "${gl_kjlan}9.   ${gl_bai}tmux 多路後台運行工具             ${gl_kjlan}10.  ${gl_bai}ffmpeg 視頻編碼直播推流工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}btop 現代化監控工具 ${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ranger 文件管理工具"
		echo -e "${gl_kjlan}13.  ${gl_bai}ncdu 硬盤占用查看工具             ${gl_kjlan}14.  ${gl_bai}fzf 全局搜索工具"
		echo -e "${gl_kjlan}15.  ${gl_bai}vim 文本編輯器                    ${gl_kjlan}16.  ${gl_bai}nano 文本編輯器 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}17.  ${gl_bai}git 版本控制系統"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}駭客帝國螢幕保護程式                      ${gl_kjlan}22.  ${gl_bai}跑火車螢幕保護程式"
		echo -e "${gl_kjlan}26.  ${gl_bai}俄羅斯方塊小遊戲                  ${gl_kjlan}27.  ${gl_bai}貪食蛇小遊戲"
		echo -e "${gl_kjlan}28.  ${gl_bai}太空入侵者小遊戲"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}全部安裝                          ${gl_kjlan}32.  ${gl_bai}全部安裝（不含螢幕保護程式和遊戲）${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}全部卸載"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}安裝指定工具                      ${gl_kjlan}42.  ${gl_bai}卸載指定工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			clear
			install curl
			clear
			echo "工具已安裝，使用方法如下："
			curl --help
			send_stats "安装curl"
			;;
		2)
			clear
			install wget
			clear
			echo "工具已安裝，使用方法如下："
			wget --help
			send_stats "安装wget"
			;;
		3)
			clear
			install sudo
			clear
			echo "工具已安裝，使用方法如下："
			sudo --help
			send_stats "安装sudo"
			;;
		4)
			clear
			install socat
			clear
			echo "工具已安裝，使用方法如下："
			socat -h
			send_stats "安装socat"
			;;
		5)
			clear
			install htop
			clear
			htop
			send_stats "安装htop"
			;;
		6)
			clear
			install iftop
			clear
			iftop
			send_stats "安装iftop"
			;;
		7)
			clear
			install unzip
			clear
			echo "工具已安裝，使用方法如下："
			unzip
			send_stats "安装unzip"
			;;
		8)
			clear
			install tar
			clear
			echo "工具已安裝，使用方法如下："
			tar --help
			send_stats "安装tar"
			;;
		9)
			clear
			install tmux
			clear
			echo "工具已安裝，使用方法如下："
			tmux --help
			send_stats "安装tmux"
			;;
		10)
			clear
			install ffmpeg
			clear
			echo "工具已安裝，使用方法如下："
			ffmpeg --help
			send_stats "安装ffmpeg"
			;;

		11)
			clear
			install btop
			clear
			btop
			send_stats "安装btop"
			;;
		12)
			clear
			install ranger
			cd /
			clear
			ranger
			cd ~
			send_stats "安装ranger"
			;;
		13)
			clear
			install ncdu
			cd /
			clear
			ncdu
			cd ~
			send_stats "安装ncdu"
			;;
		14)
			clear
			install fzf
			cd /
			clear
			fzf
			cd ~
			send_stats "安装fzf"
			;;
		15)
			clear
			install vim
			cd /
			clear
			vim -h
			cd ~
			send_stats "安装vim"
			;;
		16)
			clear
			install nano
			cd /
			clear
			nano -h
			cd ~
			send_stats "安装nano"
			;;

		17)
			clear
			install git
			cd /
			clear
			git --help
			cd ~
			send_stats "安装git"
			;;

		21)
			clear
			install cmatrix
			clear
			cmatrix
			send_stats "安装cmatrix"
			;;
		22)
			clear
			install sl
			clear
			sl
			send_stats "安装sl"
			;;
		26)
			clear
			install bastet
			clear
			bastet
			send_stats "安装bastet"
			;;
		27)
			clear
			install nsnake
			clear
			nsnake
			send_stats "安装nsnake"
			;;
		28)
			clear
			install ninvaders
			clear
			ninvaders
			send_stats "安装ninvaders"
			;;

		31)
			clear
			send_stats "全部安装"
			install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			;;

		32)
			clear
			send_stats "全部安装（不含游戏和屏保）"
			install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			;;

		33)
			clear
			send_stats "全部卸载"
			remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			;;

		41)
			clear
			Ask "請輸入安裝的工具名（wget curl sudo htop）: " installname
			install $installname
			send_stats "安装指定软件"
			;;
		42)
			clear
			Ask "請輸入卸載的工具名（htop ufw tmux cmatrix）: " removename
			remove $removename
			send_stats "卸载指定软件"
			;;

		0)
			kejilion
			;;

		*)
			echo "無效的輸入!"
			;;
		esac
		break_end
	done

}

linux_bbr() {
	clear
	send_stats "bbr管理"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			clear
			local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			echo "目前TCP阻塞演算法: $congestion_algorithm $queue_algorithm"

			echo
			echo "BBR管理"
			echo "------------------------"
			echo "1. 啟用BBRv3              2. 關閉BBRv3（會重啟）"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			Ask "請輸入您的選擇: " sub_choice

			case $sub_choice in
			1)
				bbr_on
				send_stats "alpine开启bbr3"
				;;
			2)
				sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
				sysctl -p
				server_reboot
				;;
			*)
				break
				;;

			esac
		done
	else
		install wget
		wget --no-check-certificate -O tcpx.sh ${gh_proxy}raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
		chmod +x tcpx.sh
		./tcpx.sh
	fi

}

linux_docker() {

	while true; do
		clear
		# send_stats "docker管理"
		echo -e "Docker管理"
		docker_tato
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}安裝更新Docker環境 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}2.   ${gl_bai}查看Docker全局狀態 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}Docker容器管理 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}4.   ${gl_bai}Docker鏡像管理"
		echo -e "${gl_kjlan}5.   ${gl_bai}Docker網絡管理"
		echo -e "${gl_kjlan}6.   ${gl_bai}Docker卷管理"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}7.   ${gl_bai}清理無用的docker容器和鏡像網絡數據卷"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}8.   ${gl_bai}更換Docker源"
		echo -e "${gl_kjlan}9.   ${gl_bai}編輯daemon.json文件"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}開啟Docker-ipv6訪問"
		echo -e "${gl_kjlan}12.  ${gl_bai}關閉Docker-ipv6訪問"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}20.  ${gl_bai}卸載Docker環境"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			clear
			send_stats "安装docker环境"
			install_add_docker

			;;
		2)
			clear
			local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			local image_count=$(docker images -q 2>/dev/null | wc -l)
			local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			send_stats "docker全局状态"
			echo "Docker版本"
			docker -v
			docker compose version

			echo
			echo -e "Docker鏡像: ${gl_lv}$image_count${gl_bai} "
			docker image ls
			echo
			echo -e "Docker容器: ${gl_lv}$container_count${gl_bai}"
			docker ps -a
			echo
			echo -e "Docker 卷: ${gl_lv}$volume_count${gl_bai}"
			docker volume ls
			echo
			echo -e "Docker 網路: ${gl_lv}$network_count${gl_bai}"
			docker network ls
			echo

			;;
		3)
			docker_ps
			;;
		4)
			docker_image
			;;

		5)
			while true; do
				clear
				send_stats "Docker网络管理"
				echo "Docker網路列表"
				echo "------------------------------------------------------------"
				docker network ls
				echo

				echo "------------------------------------------------------------"
				container_ids=$(docker ps -q)
				echo "容器名稱              網路名稱              IP位址"

				for container_id in $container_ids; do
					local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

					local container_name=$(echo "$container_info" | awk '{print $1}')
					local network_info=$(echo "$container_info" | cut -d' ' -f2-)

					while IFS= read -r line; do
						local network_name=$(echo "$line" | awk '{print $1}')
						local ip_address=$(echo "$line" | awk '{print $2}')

						printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
					done <<<"$network_info"
				done

				echo
				echo "網路操作"
				echo "------------------------"
				echo "1. 建立網路"
				echo "2. 加入網路"
				echo "3. 退出網路"
				echo "4. 刪除網路"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " sub_choice

				case $sub_choice in
				1)
					send_stats "创建网络"
					Ask "設定新網絡名: " dockernetwork
					docker network create $dockernetwork
					;;
				2)
					send_stats "加入网络"
					Ask "加入網絡名: " dockernetwork
					Ask "那些容器加入該網絡（多個容器名請用空格分隔）: " dockernames

					for dockername in $dockernames; do
						docker network connect $dockernetwork $dockername
					done
					;;
				3)
					send_stats "加入网络"
					Ask "退出網絡名: " dockernetwork
					Ask "那些容器退出該網絡（多個容器名請用空格分隔）: " dockernames

					for dockername in $dockernames; do
						docker network disconnect $dockernetwork $dockername
					done

					;;

				4)
					send_stats "删除网络"
					Ask "請輸入要刪除的網絡名: " dockernetwork
					docker network rm $dockernetwork
					;;

				*)
					break
					;;
				esac
			done
			;;

		6)
			while true; do
				clear
				send_stats "Docker卷管理"
				echo "Docker磁碟區列表"
				docker volume ls
				echo
				echo "磁碟區操作"
				echo "------------------------"
				echo "1. 建立新磁碟區"
				echo "2. 刪除指定磁碟區"
				echo "3. 刪除所有磁碟區"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " sub_choice

				case $sub_choice in
				1)
					send_stats "新建卷"
					Ask "設定新卷名: " dockerjuan
					docker volume create $dockerjuan

					;;
				2)
					Ask "輸入刪除卷名（多個卷名請用空格分隔）: " dockerjuans

					for dockerjuan in $dockerjuans; do
						docker volume rm $dockerjuan
					done

					;;

				3)
					send_stats "删除所有卷"
					Ask "${gl_hong}注意: ${gl_bai}確定刪除所有未使用的卷嗎？(y/N): " choice
					case "$choice" in
					[Yy])
						docker volume prune -f
						;;
					[Nn]) ;;
					*)
						echo "無效的選擇，請輸入 Y 或 N。"
						;;
					esac
					;;

				*)
					break
					;;
				esac
			done
			;;
		7)
			clear
			send_stats "Docker清理"
			Ask "${gl_huang}提示: ${gl_bai}將清理無用的鏡像容器網絡，包括停止的容器，確定清理嗎？(y/N): " choice
			case "$choice" in
			[Yy])
				docker system prune -af --volumes
				;;
			[Nn]) ;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;
		8)
			clear
			send_stats "Docker源"
			bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
			;;

		9)
			clear
			install nano
			mkdir -p /etc/docker && nano /etc/docker/daemon.json
			restart docker
			;;

		11)
			clear
			send_stats "Docker v6 开"
			docker_ipv6_on
			;;

		12)
			clear
			send_stats "Docker v6 关"
			docker_ipv6_off
			;;

		20)
			clear
			send_stats "Docker卸载"
			Ask "${gl_hong}注意: ${gl_bai}確定卸載docker環境嗎？(y/N): " choice
			case "$choice" in
			[Yy])
				docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				remove docker docker-compose docker-ce docker-ce-cli containerd.io
				rm -f /etc/docker/daemon.json
				hash -r
				;;
			[Nn]) ;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;

		0)
			kejilion
			;;
		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done

}

linux_test() {

	while true; do
		clear
		# send_stats "测试脚本合集"
		echo -e "測試腳本合集"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}IP 及解鎖狀態檢測"
		echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT 解鎖狀態檢測"
		echo -e "${gl_kjlan}2.   ${gl_bai}Region 流媒體解鎖測試"
		echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu 流媒體解鎖檢測"
		echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP 品質體檢腳本 ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}網路線路測速"
		echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 三網回程延遲路由測試"
		echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 三網回程線路測試"
		echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 三網測速"
		echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 快速回程測試腳本"
		echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 指定 IP 回程測試腳本"
		echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 三網線路測試"
		echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多功能測速腳本"
		echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality 網路品質體檢腳本 ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}硬體效能測試"
		echo -e "${gl_kjlan}21.  ${gl_bai}yabs 效能測試"
		echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU 效能測試腳本"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}綜合性測試"
		echo -e "${gl_kjlan}31.  ${gl_bai}bench 效能測試"
		echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 融合怪測評 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			clear
			send_stats "ChatGPT解锁状态检测"
			bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			;;
		2)
			clear
			send_stats "Region流媒体解锁测试"
			bash <(curl -L -s check.unlock.media)
			;;
		3)
			clear
			send_stats "yeahwu流媒体解锁检测"
			install wget
			wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			;;
		4)
			clear
			send_stats "xykt_IP质量体检脚本"
			bash <(curl -Ls IP.Check.Place)
			;;

		11)
			clear
			send_stats "besttrace三网回程延迟路由测试"
			install wget
			wget -qO- git.io/besttrace | bash
			;;
		12)
			clear
			send_stats "mtr_trace三网回程线路测试"
			curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			;;
		13)
			clear
			send_stats "Superspeed三网测速"
			bash <(curl -Lso- https://git.io/superspeed_uxh)
			;;
		14)
			clear
			send_stats "nxtrace快速回程测试脚本"
			curl nxtrace.org/nt | bash
			nexttrace --fast-trace --tcp
			;;
		15)
			clear
			send_stats "nxtrace指定IP回程测试脚本"
			echo "可參考的IP列表"
			echo "------------------------"
			echo "北京電信: 219.141.136.12"
			echo "北京聯通: 202.106.50.1"
			echo "北京移動: 221.179.155.161"
			echo "上海電信: 202.96.209.133"
			echo "上海聯通: 210.22.97.1"
			echo "上海移動: 211.136.112.200"
			echo "廣州電信: 58.60.188.222"
			echo "廣州聯通: 210.21.196.6"
			echo "廣州移動: 120.196.165.24"
			echo "成都電信: 61.139.2.69"
			echo "成都聯通: 119.6.6.6"
			echo "成都移動: 211.137.96.205"
			echo "湖南電信: 36.111.200.100"
			echo "湖南聯通: 42.48.16.100"
			echo "湖南移動: 39.134.254.6"
			echo "------------------------"

			Ask "輸入一個指定IP: " testip
			curl nxtrace.org/nt | bash
			nexttrace $testip
			;;

		16)
			clear
			send_stats "ludashi2020三网线路测试"
			curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			;;

		17)
			clear
			send_stats "i-abc多功能测速脚本"
			bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			;;

		18)
			clear
			send_stats "网络质量测试脚本"
			bash <(curl -sL Net.Check.Place)
			;;

		21)
			clear
			send_stats "yabs性能测试"
			check_swap
			curl -sL yabs.sh | bash -s -- -i -5
			;;
		22)
			clear
			send_stats "icu/gb5 CPU性能测试脚本"
			check_swap
			bash <(curl -sL bash.icu/gb5)
			;;

		31)
			clear
			send_stats "bench性能测试"
			curl -Lso- bench.sh | bash
			;;
		32)
			send_stats "spiritysdx融合怪测评"
			clear
			curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			;;

		0)
			kejilion

			;;
		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done

}

linux_Oracle() {

	while true; do
		clear
		send_stats "甲骨文云脚本合集"
		echo -e "甲骨文雲腳本合集"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}安裝閒置機器活躍腳本"
		echo -e "${gl_kjlan}2.   ${gl_bai}卸載閒置機器活躍腳本"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}DD 重裝系統腳本"
		echo -e "${gl_kjlan}4.   ${gl_bai}R 探長開機腳本"
		echo -e "${gl_kjlan}5.   ${gl_bai}開啟 ROOT 密碼登錄模式"
		echo -e "${gl_kjlan}6.   ${gl_bai}IPV6 恢復工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			clear
			echo "活躍腳本: CPU占用10-20% 記憶體占用20% "
			Ask "確定安裝嗎？(y/N): " choice
			case "$choice" in
			[Yy])

				install_docker

				# 设置默认值
				local DEFAULT_CPU_CORE=1
				local DEFAULT_CPU_UTIL="10-20"
				local DEFAULT_MEM_UTIL=20
				local DEFAULT_SPEEDTEST_INTERVAL=120

				# 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				Ask "請輸入CPU核心數 [預設: $DEFAULT_CPU_CORE]: " cpu_core
				local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				Ask "請輸入CPU佔用百分比範圍（例如10-20） [預設: $DEFAULT_CPU_UTIL]: " cpu_util
				local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				Ask "請輸入記憶體佔用百分比 [預設: $DEFAULT_MEM_UTIL]: " mem_util
				local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				Ask "請輸入Speedtest間隔時間（秒） [預設: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				# 运行Docker容器
				docker run -itd --name=lookbusy --restart=always \
					-e TZ=Asia/Shanghai \
					-e CPU_UTIL="$cpu_util" \
					-e CPU_CORE="$cpu_core" \
					-e MEM_UTIL="$mem_util" \
					-e SPEEDTEST_INTERVAL="$speedtest_interval" \
					fogforest/lookbusy
				send_stats "甲骨文云安装活跃脚本"

				;;
			[Nn]) ;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;
		2)
			clear
			docker rm -f lookbusy
			docker rmi fogforest/lookbusy
			send_stats "甲骨文云卸载活跃脚本"
			;;

		3)
			clear
			echo "重裝系統"
			echo "--------------------------------"
			echo -e "${gl_hong}注意: ${gl_bai}重裝有風險失聯，不放心者慎用。重裝預計花費15分鐘，請提前備份數據。"
			Ask "確定繼續嗎？(y/N): " choice

			case "$choice" in
			[Yy])
				while true; do
					Ask "請選擇要重裝的系統:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

					case "$sys_choice" in
					1)
						local xitong="-d 12"
						break
						;;
					2)
						local xitong="-u 20.04"
						break
						;;
					*)
						echo "無效的選擇，請重新輸入。"
						;;
					esac
				done

				Ask "請輸入你重裝後的密碼: " vpspasswd
				install wget
				bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
				send_stats "甲骨文云重装系统脚本"
				;;
			[Nn])
				echo "已取消"
				;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;

		4)
			clear
			echo "該功能處於開發階段，敬請期待！"
			;;
		5)
			clear
			add_sshpasswd

			;;
		6)
			clear
			bash <(curl -L -s jhb.ovh/jb/v6.sh)
			echo "該功能由jhb大神提供，感謝他！"
			send_stats "ipv6修复"
			;;
		0)
			kejilion

			;;
		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done

}

docker_tato() {

	local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
	local image_count=$(docker images -q 2>/dev/null | wc -l)
	local network_count=$(docker network ls -q 2>/dev/null | wc -l)
	local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

	if command -v docker &>/dev/null; then
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_lv}環境已安裝${gl_bai}  容器: ${gl_lv}$container_count${gl_bai}  鏡像: ${gl_lv}$image_count${gl_bai}  網路: ${gl_lv}$network_count${gl_bai}  卷: ${gl_lv}$volume_count${gl_bai}"
	fi
}

ldnmp_tato() {
	local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
	local output="站點: ${gl_lv}${cert_count}${gl_bai}"

	local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
	if [ -n "$dbrootpasswd" ]; then
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
	fi

	local db_output="資料庫: ${gl_lv}${db_count}${gl_bai}"

	if command -v docker &>/dev/null; then
		if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
			echo -e "${gl_huang}------------------------"
			echo -e "${gl_lv}環境已安裝${gl_bai}  $output  $db_output"
		fi
	fi

}

fix_phpfpm_conf() {
	local container_name=$1
	docker exec "$container_name" sh -c "mkdir -p /run/$container_name && chmod 777 /run/$container_name"
	docker exec "$container_name" sh -c "sed -i '1i [global]\\ndaemonize = no' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "sed -i '/^listen =/d' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "echo -e '\nlisten = /run/$container_name/php-fpm.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0777' >> /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "rm -f /usr/local/etc/php-fpm.d/zz-docker.conf"

	find /home/web/conf.d/ -type f -name "*.conf" -exec sed -i "s#fastcgi_pass ${container_name}:9000;#fastcgi_pass unix:/run/${container_name}/php-fpm.sock;#g" {} \;

}

linux_ldnmp() {
	while true; do

		clear
		# send_stats "LDNMP建站"
		echo -e "${gl_huang}LDNMP 建站"
		ldnmp_tato
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}1.   ${gl_bai}安裝 LDNMP 環境 ${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}安裝 WordPress ${gl_huang}★${gl_bai}"
		echo -e "${gl_huang}3.   ${gl_bai}安裝 Discuz 論壇                    ${gl_huang}4.   ${gl_bai}安裝可道雲桌面"
		echo -e "${gl_huang}5.   ${gl_bai}安裝蘋果 CMS 影視站                 ${gl_huang}6.   ${gl_bai}安裝獨角數發卡網"
		echo -e "${gl_huang}7.   ${gl_bai}安裝 flarum 論壇網站                ${gl_huang}8.   ${gl_bai}安裝 typecho 輕量部落格網站"
		echo -e "${gl_huang}9.   ${gl_bai}安裝 LinkStack 分享連結平台         ${gl_huang}20.  ${gl_bai}自訂動態網站"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}21.  ${gl_bai}僅安裝 nginx ${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}網站重定向"
		echo -e "${gl_huang}23.  ${gl_bai}網站反向代理-IP+連接埠 ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}網站反向代理-域名"
		echo -e "${gl_huang}25.  ${gl_bai}安裝 Bitwarden 密碼管理平台         ${gl_huang}26.  ${gl_bai}安裝 Halo 部落格網站"
		echo -e "${gl_huang}27.  ${gl_bai}安裝 AI 繪圖提示詞產生器            ${gl_huang}28.  ${gl_bai}網站反向代理-負載均衡"
		echo -e "${gl_huang}30.  ${gl_bai}自訂靜態網站"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}31.  ${gl_bai}網站資料管理 ${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}備份全站資料"
		echo -e "${gl_huang}33.  ${gl_bai}定時遠端備份                      ${gl_huang}34.  ${gl_bai}還原全站資料"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}35.  ${gl_bai}防護 LDNMP 環境                     ${gl_huang}36.  ${gl_bai}優化 LDNMP 環境"
		echo -e "${gl_huang}37.  ${gl_bai}更新 LDNMP 環境                     ${gl_huang}38.  ${gl_bai}卸載 LDNMP 環境"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}0.   ${gl_bai}返回主選單"
		echo -e "${gl_huang}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			ldnmp_install_status_one
			ldnmp_install_all
			;;
		2)
			ldnmp_wp
			;;

		3)
			clear
			# Discuz论坛
			webname="Discuz論壇"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming
			wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20240520.zip
			unzip latest.zip
			rm latest.zip

			restart_ldnmp

			ldnmp_web_on
			echo "資料庫位址: mysql"
			echo "資料庫名: $dbname"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo "表前綴: discuz_"

			;;

		4)
			clear
			# 可道云桌面
			webname="可道雲桌面"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming
			wget -O latest.zip ${gh_proxy}github.com/kalcaddle/kodbox/archive/refs/tags/1.50.02.zip
			unzip -o latest.zip
			rm latest.zip
			mv /home/web/html/$yuming/kodbox* /home/web/html/$yuming/kodbox
			restart_ldnmp

			ldnmp_web_on
			echo "資料庫位址: mysql"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo "資料庫名: $dbname"
			echo "redis主機: redis"

			;;

		5)
			clear
			# 苹果CMS
			webname="蘋果CMS"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming
			# wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
			wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
			cd /home/web/html/$yuming/template/ && wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
			cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
			cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
			mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php ${gh_proxy}raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

			restart_ldnmp

			ldnmp_web_on
			echo "資料庫位址: mysql"
			echo "資料庫埠: 3306"
			echo "資料庫名: $dbname"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo "資料庫前綴: mac_"
			echo "------------------------"
			echo "安裝成功後登入後台地址"
			echo "https://$yuming/vip.php"

			;;

		6)
			clear
			# 独脚数卡
			webname="獨腳數卡"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming
			wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

			restart_ldnmp

			ldnmp_web_on
			echo "資料庫位址: mysql"
			echo "資料庫埠: 3306"
			echo "資料庫名: $dbname"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo
			echo "redis地址: redis"
			echo "redis密碼: 預設不填寫"
			echo "redis埠: 6379"
			echo
			echo "網站url: https://$yuming"
			echo "後台登入路徑: /admin"
			echo "------------------------"
			echo "使用者名稱: admin"
			echo "密碼: admin"
			echo "------------------------"
			echo "登入時右上角如果出現紅色error0請使用如下命令: "
			echo "我也很氣憤獨角數卡為啥這麼麻煩，會有這樣的問題！"
			echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

			;;

		7)
			clear
			# flarum论坛
			webname="flarum論壇"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

			cd /home/web/html
			mkdir $yuming
			cd $yuming

			docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
			docker exec php sh -c "php composer-setup.php"
			docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
			docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

			docker exec php composer create-project flarum/flarum /var/www/html/$yuming
			docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
			docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
			docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
			docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
			docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
			docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
			docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"

			restart_ldnmp

			ldnmp_web_on
			echo "資料庫位址: mysql"
			echo "資料庫名: $dbname"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo "表前綴: flarum_"
			echo "管理員資訊自行設定"

			;;

		8)
			clear
			# typecho
			webname="typecho"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming
			wget -O latest.zip ${gh_proxy}github.com/typecho/typecho/releases/latest/download/typecho.zip
			unzip latest.zip
			rm latest.zip

			restart_ldnmp

			clear
			ldnmp_web_on
			echo "資料庫前綴: typecho_"
			echo "資料庫位址: mysql"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo "資料庫名: $dbname"

			;;

		9)
			clear
			# LinkStack
			webname="LinkStack"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
			sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
			sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming
			wget -O latest.zip ${gh_proxy}github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
			unzip latest.zip
			rm latest.zip

			restart_ldnmp

			clear
			ldnmp_web_on
			echo "資料庫位址: mysql"
			echo "資料庫埠: 3306"
			echo "資料庫名: $dbname"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			;;

		20)
			clear
			webname="PHP動態站點"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			ldnmp_install_status
			install_ssltls
			certs_status
			add_db
			wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming

			clear
			echo -e "[${gl_huang}1/6${gl_bai}] 上傳 PHP 原始碼"
			echo "-------------"
			echo "目前只允許上傳zip格式的原始碼包，請將原始碼包放到/home/web/html/${yuming}目錄下"
			Ask "也可以輸入下載鏈接，遠端下載原始碼包，直接回車將跳過遠端下載： " url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/6${gl_bai}] index.php 所在路徑"
			echo "-------------"
			# find "$(realpath .)" -name "index.php" -print
			find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

			Ask "請輸入index.php的路徑，類似（/home/web/html/$yuming/wordpress/）： " index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}3/6${gl_bai}] 請選擇 PHP 版本"
			echo "-------------"
			Ask "1. php最新版 | 2. php7.4 : " pho_v
			case "$pho_v" in
			1)
				sed -i "s#php:9000#php:9000#g" /home/web/conf.d/$yuming.conf
				local PHP_Version="php"
				;;
			2)
				sed -i "s#php:9000#php74:9000#g" /home/web/conf.d/$yuming.conf
				local PHP_Version="php74"
				;;
			*)
				echo "無效的選擇，請重新輸入。"
				;;
			esac

			clear
			echo -e "[${gl_huang}4/6${gl_bai}] 安裝指定擴充"
			echo "-------------"
			echo "已安裝的擴充"
			docker exec php php -m

			Ask "輸入需要安裝的擴展名稱，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回車將跳過安裝 ： " php_extensions
			if [ -n "$php_extensions" ]; then
				docker exec $PHP_Version install-php-extensions $php_extensions
			fi

			clear
			echo -e "[${gl_huang}5/6${gl_bai}] 編輯網站設定"
			echo "-------------"
			Press "按任意鍵繼續，可詳細設定網站配置，如偽靜態等內容"
			install nano
			nano /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}6/6${gl_bai}] 資料庫管理"
			echo "-------------"
			Ask "1. 我搭建新站        2. 我搭建老站有數據庫備份： " use_db
			case $use_db in
			1)
				echo
				;;
			2)
				echo "資料庫備份必須是.gz結尾的壓縮包。請放到/home/目錄下，支援寶塔/1panel備份資料匯入。"
				Ask "也可以輸入下載鏈接，遠端下載備份數據，直接回車將跳過遠端下載： " url_download_db

				cd /home/
				if [ -n "$url_download_db" ]; then
					wget "$url_download_db"
				fi
				gunzip $(ls -t *.gz | head -n 1)
				latest_sql=$(ls -t *.sql | head -n 1)
				dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname <"/home/$latest_sql"
				echo "資料庫匯入的表資料"
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
				rm -f *.sql
				echo "資料庫匯入完成"
				;;
			*)
				echo
				;;
			esac

			docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

			restart_ldnmp
			ldnmp_web_on
			prefix="web$(shuf -i 10-99 -n 1)_"
			echo "資料庫位址: mysql"
			echo "資料庫名: $dbname"
			echo "使用者名稱: $dbuse"
			echo "密碼: $dbusepasswd"
			echo "表前綴: $prefix"
			echo "管理員登入資訊自行設定"

			;;

		21)
			ldnmp_install_status_one
			nginx_install_all
			;;

		22)
			clear
			webname="站點重定向"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			Ask "請輸入跳轉域名: " reverseproxy
			nginx_install_status
			install_ssltls
			certs_status

			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			docker exec nginx nginx -s reload

			nginx_web_on

			;;

		23)
			ldnmp_Proxy
			;;

		24)
			clear
			webname="反向代理-域名"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			echo -e "域名格式: ${gl_huang}google.com${gl_bai}"
			Ask "請輸入你的反代域名: " fandai_yuming
			nginx_install_status
			install_ssltls
			certs_status

			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			docker exec nginx nginx -s reload

			nginx_web_on

			;;

		25)
			clear
			webname="Bitwarden"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			nginx_install_status
			install_ssltls
			certs_status

			docker run -d \
				--name bitwarden \
				--restart always \
				-p 3280:80 \
				-v /home/web/html/$yuming/bitwarden/data:/data \
				vaultwarden/server
			duankou=3280
			reverse_proxy

			nginx_web_on

			;;

		26)
			clear
			webname="halo"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			nginx_install_status
			install_ssltls
			certs_status

			docker run -d --name halo --restart always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2
			duankou=8010
			reverse_proxy

			nginx_web_on

			;;

		27)
			clear
			webname="AI繪圖提示詞生成器"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			nginx_install_status
			install_ssltls
			certs_status

			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming

			wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip
			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			docker exec nginx chmod -R nginx:nginx /var/www/html
			docker exec nginx nginx -s reload

			nginx_web_on

			;;

		28)
			ldnmp_Proxy_backend
			;;

		30)
			clear
			webname="靜態站點"
			send_stats "安装$webname"
			echo "開始部署 $webname"
			add_yuming
			repeat_add_yuming
			nginx_install_status
			install_ssltls
			certs_status

			wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
			sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
			nginx_http_on

			cd /home/web/html
			mkdir $yuming
			cd $yuming

			clear
			echo -e "[${gl_huang}1/2${gl_bai}] 上傳靜態原始碼"
			echo "-------------"
			echo "目前只允許上傳zip格式的原始碼包，請將原始碼包放到/home/web/html/${yuming}目錄下"
			Ask "也可以輸入下載鏈接，遠端下載原始碼包，直接回車將跳過遠端下載： " url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/2${gl_bai}] index.html 所在路徑"
			echo "-------------"
			# find "$(realpath .)" -name "index.html" -print
			find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

			Ask "請輸入index.html的路徑，類似（/home/web/html/$yuming/index/）： " index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			docker exec nginx chmod -R nginx:nginx /var/www/html
			docker exec nginx nginx -s reload

			nginx_web_on

			;;

		31)
			ldnmp_web_status
			;;

		32)
			clear
			send_stats "LDNMP环境备份"

			local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
			echo -e "${gl_huang}正在備份 $backup_filename ...${gl_bai}"
			cd /home/ && tar czvf "$backup_filename" web

			while true; do
				clear
				echo "備份檔案已建立: /home/$backup_filename"
				Ask "要傳送備份數據到遠端伺服器嗎？(y/N): " choice
				case "$choice" in
				[Yy])
					Ask "請輸入遠端伺服器IP:  " remote_ip
					if [ -z "$remote_ip" ]; then
						echo "錯誤: 請輸入遠端伺服器IP。"
						continue
					fi
					local latest_tar=$(ls -t /home/*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
						echo "檔案已傳送至遠端伺服器home目錄。"
					else
						echo "未找到要傳送的檔案。"
					fi
					break
					;;
				[Nn])
					break
					;;
				*)
					echo "無效的選擇，請輸入 Y 或 N。"
					;;
				esac
			done
			;;

		33)
			clear
			send_stats "定时远程备份"
			Ask "輸入遠端伺服器IP: " useip
			Ask "輸入遠端伺服器密碼: " usepasswd

			cd ~
			wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh >/dev/null 2>&1
			chmod +x ${useip}_beifen.sh

			sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
			sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

			echo "------------------------"
			echo "1. 每週備份                 2. 每天備份"
			Ask "請輸入您的選擇: " dingshi

			case $dingshi in
			1)
				check_crontab_installed
				Ask "選擇每週備份的星期幾 (0-6，0代表星期日): " weekday
				(
					crontab -l
					echo "0 0 * * $weekday ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			2)
				check_crontab_installed
				Ask "選擇每天備份的時間（小時，0-23）: " hour
				(
					crontab -l
					echo "0 $hour * * * ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			*)
				break
				;;
			esac

			install sshpass

			;;

		34)
			root_use
			send_stats "LDNMP环境还原"
			echo "可用的站點備份"
			echo "-------------------------"
			ls -lt /home/*.gz | awk '{print $NF}'
			echo
			Ask "回車鍵還原最新的備份，輸入備份文件名還原指定的備份，輸入0退出：" filename

			if [ "$filename" == "0" ]; then
				break_end
				linux_ldnmp
			fi

			# 如果用户没有输入文件名，使用最新的压缩包
			if [ -z "$filename" ]; then
				local filename=$(ls -t /home/*.tar.gz | head -1)
			fi

			if [ -n "$filename" ]; then
				cd /home/web/ >/dev/null 2>&1
				docker compose down >/dev/null 2>&1
				rm -rf /home/web >/dev/null 2>&1

				echo -e "${gl_huang}正在解壓縮 $filename ...${gl_bai}"
				cd /home/ && tar -xzf "$filename"

				check_port
				install_dependency
				install_docker
				install_certbot
				install_ldnmp
			else
				echo "沒有找到壓縮包。"
			fi

			;;

		35)
			web_security
			;;

		36)
			web_optimization
			;;

		37)
			root_use
			while true; do
				clear
				send_stats "更新LDNMP环境"
				echo "更新LDNMP環境"
				echo "------------------------"
				ldnmp_v
				echo "發現新版本的元件"
				echo "------------------------"
				check_docker_image_update nginx
				if [ -n "$update_status" ]; then
					echo -e "${gl_huang}nginx $update_status${gl_bai}"
				fi
				check_docker_image_update php
				if [ -n "$update_status" ]; then
					echo -e "${gl_huang}php $update_status${gl_bai}"
				fi
				check_docker_image_update mysql
				if [ -n "$update_status" ]; then
					echo -e "${gl_huang}mysql $update_status${gl_bai}"
				fi
				check_docker_image_update redis
				if [ -n "$update_status" ]; then
					echo -e "${gl_huang}redis $update_status${gl_bai}"
				fi
				echo "------------------------"
				echo
				echo "1. 更新nginx               2. 更新mysql              3. 更新php              4. 更新redis"
				echo "------------------------"
				echo "5. 更新完整環境"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " sub_choice
				case $sub_choice in
				1)
					nginx_upgrade

					;;

				2)
					local ldnmp_pods="mysql"
					Ask "請輸入${ldnmp_pods}版本號 （如: 8.0 8.3 8.4 9.0）（回車獲取最新版）: " version
					local version=${version:-latest}

					cd /home/web/
					cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
					sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
					docker rm -f $ldnmp_pods
					docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
					docker compose up -d --force-recreate $ldnmp_pods
					docker restart $ldnmp_pods
					cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
					send_stats "更新$ldnmp_pods"
					echo "更新${ldnmp_pods}完成"

					;;
				3)
					local ldnmp_pods="php"
					Ask "請輸入${ldnmp_pods}版本號 （如: 7.4 8.0 8.1 8.2 8.3）（回車獲取最新版）: " version
					local version=${version:-8.3}
					cd /home/web/
					cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
					sed -i "s/kjlion\///g" /home/web/docker-compose.yml >/dev/null 2>&1
					sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
					docker rm -f $ldnmp_pods
					docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
					docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi >/dev/null 2>&1
					docker compose up -d --force-recreate $ldnmp_pods
					docker exec php chown -R www-data:www-data /var/www/html

					run_command docker exec php sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories >/dev/null 2>&1

					docker exec php apk update
					curl -sL ${gh_proxy}github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
					docker exec php mkdir -p /usr/local/bin/
					docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
					docker exec php chmod +x /usr/local/bin/install-php-extensions
					docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis imagick

					docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' >/dev/null 2>&1
					docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' >/dev/null 2>&1

					fix_phpfpm_con $ldnmp_pods

					docker restart $ldnmp_pods >/dev/null 2>&1
					cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
					send_stats "更新$ldnmp_pods"
					echo "更新${ldnmp_pods}完成"

					;;
				4)
					local ldnmp_pods="redis"
					cd /home/web/
					docker rm -f $ldnmp_pods
					docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi >/dev/null 2>&1
					docker compose up -d --force-recreate $ldnmp_pods
					docker restart $ldnmp_pods >/dev/null 2>&1
					restart_redis
					send_stats "更新$ldnmp_pods"
					echo "更新${ldnmp_pods}完成"

					;;
				5)
					Ask "${gl_huang}提示: ${gl_bai}長時間不更新環境的用戶，請慎重更新LDNMP環境，會有數據庫更新失敗的風險。確定更新LDNMP環境嗎？(y/N): " choice
					case "$choice" in
					[Yy])
						send_stats "完整更新LDNMP环境"
						cd /home/web/
						docker compose down --rmi all

						check_port
						install_dependency
						install_docker
						install_certbot
						install_ldnmp
						;;
					*) ;;
					esac
					;;
				*)
					break
					;;
				esac
				break_end
			done

			;;

		38)
			root_use
			send_stats "卸载LDNMP环境"
			Ask "${gl_hong}強烈建議：${gl_bai}先備份全部網站數據，再卸載LDNMP環境。確定刪除所有網站數據嗎？(y/N): " choice
			case "$choice" in
			[Yy])
				cd /home/web/
				docker compose down --rmi all
				docker compose -f docker-compose.phpmyadmin.yml down >/dev/null 2>&1
				docker compose -f docker-compose.phpmyadmin.yml down --rmi all >/dev/null 2>&1
				rm -rf /home/web
				;;
			[Nn]) ;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;

		0)
			kejilion
			;;

		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done

}

linux_panel() {

	while true; do
		clear
		# send_stats "应用市场"
		echo -e "應用市場"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}寶塔面板官方版                      ${gl_kjlan}2.   ${gl_bai}aaPanel 寶塔國際版"
		echo -e "${gl_kjlan}3.   ${gl_bai}1Panel 新一代管理面板                ${gl_kjlan}4.   ${gl_bai}NginxProxyManager 可視化面板"
		echo -e "${gl_kjlan}5.   ${gl_bai}OpenList 多儲存檔案列表程式          ${gl_kjlan}6.   ${gl_bai}Ubuntu 遠端桌面網頁版"
		echo -e "${gl_kjlan}7.   ${gl_bai}哪吒探針 VPS 監控面板                 ${gl_kjlan}8.   ${gl_bai}QB 離線 BT 磁力下載面板"
		echo -e "${gl_kjlan}9.   ${gl_bai}Poste.io 電子郵件伺服器程式              ${gl_kjlan}10.  ${gl_bai}RocketChat 多人線上聊天系統"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}禪道專案管理軟體                    ${gl_kjlan}12.  ${gl_bai}青龍面板定時任務管理平台"
		echo -e "${gl_kjlan}13.  ${gl_bai}Cloudreve 網盤 ${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}簡單圖床圖片管理程式"
		echo -e "${gl_kjlan}15.  ${gl_bai}emby 多媒體管理系統                  ${gl_kjlan}16.  ${gl_bai}Speedtest 測速面板"
		echo -e "${gl_kjlan}17.  ${gl_bai}AdGuardHome 去廣告軟體               ${gl_kjlan}18.  ${gl_bai}onlyoffice 線上辦公 OFFICE"
		echo -e "${gl_kjlan}19.  ${gl_bai}雷池 WAF 防火牆面板                   ${gl_kjlan}20.  ${gl_bai}portainer 容器管理面板"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}VScode 網頁版                        ${gl_kjlan}22.  ${gl_bai}UptimeKuma 監控工具"
		echo -e "${gl_kjlan}23.  ${gl_bai}Memos 網頁備忘錄                     ${gl_kjlan}24.  ${gl_bai}Webtop 遠端桌面網頁版 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}25.  ${gl_bai}Nextcloud 網盤                       ${gl_kjlan}26.  ${gl_bai}QD-Today 定時任務管理框架"
		echo -e "${gl_kjlan}27.  ${gl_bai}Dockge 容器堆疊管理面板              ${gl_kjlan}28.  ${gl_bai}LibreSpeed 測速工具"
		echo -e "${gl_kjlan}29.  ${gl_bai}searxng 聚合搜尋站 ${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}PhotoPrism 私有相簿系統"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}StirlingPDF 工具大全                 ${gl_kjlan}32.  ${gl_bai}drawio 免費的線上圖表軟體 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}Sun-Panel 導航面板                   ${gl_kjlan}34.  ${gl_bai}Pingvin-Share 檔案分享平台"
		echo -e "${gl_kjlan}35.  ${gl_bai}極簡朋友圈                          ${gl_kjlan}36.  ${gl_bai}LobeChat AI 聊天聚合網站"
		echo -e "${gl_kjlan}37.  ${gl_bai}MyIP 工具箱 ${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}小雅 alist 全家桶"
		echo -e "${gl_kjlan}39.  ${gl_bai}Bili live 直播錄製工具                ${gl_kjlan}40.  ${gl_bai}webssh 網頁版 SSH 連接工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}耗子管理面板                \t ${gl_kjlan}42.  ${gl_bai}Nexterm 遠端連接工具"
		echo -e "${gl_kjlan}43.  ${gl_bai}RustDesk 遠端桌面(伺服器端) ${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}RustDesk 遠端桌面(中繼端) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}45.  ${gl_bai}Docker 加速站            \t\t ${gl_kjlan}46.  ${gl_bai}GitHub 加速站 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}47.  ${gl_bai}普羅米修斯監控\t\t\t ${gl_kjlan}48.  ${gl_bai}普羅米修斯(主機監控)"
		echo -e "${gl_kjlan}49.  ${gl_bai}普羅米修斯(容器監控)\t\t ${gl_kjlan}50.  ${gl_bai}補貨監控工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}51.  ${gl_bai}PVE 開小雞面板\t\t\t ${gl_kjlan}52.  ${gl_bai}DPanel 容器管理面板"
		echo -e "${gl_kjlan}53.  ${gl_bai}llama3 聊天 AI 大模型                  ${gl_kjlan}54.  ${gl_bai}AMH 主機建站管理面板"
		echo -e "${gl_kjlan}55.  ${gl_bai}FRP 內網穿透(伺服器端) ${gl_huang}★${gl_bai}\t         ${gl_kjlan}56.  ${gl_bai}FRP 內網穿透(客戶端) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}57.  ${gl_bai}Deepseek 聊天 AI 大模型                ${gl_kjlan}58.  ${gl_bai}Dify 大模型知識庫 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}59.  ${gl_bai}NewAPI 大模型資產管理                ${gl_kjlan}60.  ${gl_bai}JumpServer 開源堡壘機"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}61.  ${gl_bai}線上翻譯伺服器\t\t\t ${gl_kjlan}62.  ${gl_bai}RAGFlow 大模型知識庫"
		echo -e "${gl_kjlan}63.  ${gl_bai}OpenWebUI 自託管 AI 平台 ${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}it-tools 工具箱"
		echo -e "${gl_kjlan}65.  ${gl_bai}n8n 自動化工作流平台 ${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}yt-dlp 影片下載工具"
		echo -e "${gl_kjlan}67.  ${gl_bai}ddns-go 動態 DNS 管理工具 ${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${gl_bai}AllinSSL 憑證管理平台"
		echo -e "${gl_kjlan}69.  ${gl_bai}SFTPGo檔案傳輸工具                  ${gl_kjlan}70.  ${gl_bai}AstrBot聊天機器人框架"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}71.  ${gl_bai}Navidrome私人音樂伺服器             ${gl_kjlan}72.  ${gl_bai}bitwarden密碼管理器 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}73.  ${gl_bai}LibreTV私人影視                     ${gl_kjlan}74.  ${gl_bai}MoonTV私人影視"
		echo -e "${gl_kjlan}75.  ${gl_bai}Melody音樂精靈                      ${gl_kjlan}76.  ${gl_bai}線上DOS老遊戲"
		echo -e "${gl_kjlan}77.  ${gl_bai}迅雷離線下載工具                    ${gl_kjlan}78.  ${gl_bai}PandaWiki智慧文件管理系統"
		echo -e "${gl_kjlan}79.  ${gl_bai}Beszel伺服器監控"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="寶塔面板"
			local panelurl="https://www.bt.cn/new/index.html"

			panel_app_install() {
				if [ -f /usr/bin/curl ]; then curl -sSO https://download.bt.cn/install/install_panel.sh; else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh; fi
				bash install_panel.sh ed8484bec
			}

			panel_app_manage() {
				bt
			}

			panel_app_uninstall() {
				curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh >/dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
				chmod +x bt-uninstall.sh
				./bt-uninstall.sh
			}

			install_panel

			;;
		2)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="aapanel"
			local panelurl="https://www.aapanel.com/new/index.html"

			panel_app_install() {
				URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ]; then curl -ksSO "$URL"; else wget --no-check-certificate -O install_7.0_en.sh "$URL"; fi
				bash install_7.0_en.sh aapanel
			}

			panel_app_manage() {
				bt
			}

			panel_app_uninstall() {
				curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh >/dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
				chmod +x bt-uninstall.sh
				./bt-uninstall.sh
			}

			install_panel

			;;
		3)

			local lujing="command -v 1pctl"
			local panelname="1Panel"
			local panelurl="https://1panel.cn/"

			panel_app_install() {
				install bash
				bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"
			}

			panel_app_manage() {
				1pctl user-info
				1pctl update password
			}

			panel_app_uninstall() {
				1pctl uninstall
			}

			install_panel

			;;
		4)

			local docker_name="npm"
			local docker_img="jc21/nginx-proxy-manager:latest"
			local docker_port=81

			docker_rum() {

				docker run -d \
					--name=$docker_name \
					-p ${docker_port}:81 \
					-p 80:80 \
					-p 443:443 \
					-v /home/docker/npm/data:/data \
					-v /home/docker/npm/letsencrypt:/etc/letsencrypt \
					--restart=always \
					$docker_img

			}

			local docker_describe="一個Nginx反向代理工具面板，不支援添加域名訪問。"
			local docker_url="官網介紹: https://nginxproxymanager.com/"
			local docker_use='echo "初始使用者名稱: admin@example.com"'
			local docker_passwd='echo "初始密碼: changeme"'
			local app_size="1"

			docker_app

			;;

		5)

			local docker_name="openlist"
			local docker_img="openlistteam/openlist:latest-aria2"
			local docker_port=5244

			docker_rum() {

				docker run -d \
					--restart=always \
					-v /home/docker/openlist:/opt/openlist/data \
					-p ${docker_port}:5244 \
					-e PUID=0 \
					-e PGID=0 \
					-e UMASK=022 \
					--name="openlist" \
					openlistteam/openlist:latest-aria2

			}

			local docker_describe="一個支援多種儲存，支援網頁瀏覽和 WebDAV 的檔案列表程式，由 gin 和 Solidjs 驅動"
			local docker_url="官網介紹: https://github.com/OpenListTeam/OpenList"
			local docker_use="docker exec -it openlist ./openlist admin random"
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		6)

			local docker_name="webtop-ubuntu"
			local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
			local docker_port=3006

			docker_rum() {

				docker run -d \
					--name=webtop-ubuntu \
					--security-opt seccomp=unconfined \
					-e PUID=1000 \
					-e PGID=1000 \
					-e TZ=Etc/UTC \
					-e SUBFOLDER=/ \
					-e TITLE=Webtop \
					-e CUSTOM_USER=ubuntu-abc \
					-e PASSWORD=ubuntuABC123 \
					-p ${docker_port}:3000 \
					-v /home/docker/webtop/data:/config \
					-v /var/run/docker.sock:/var/run/docker.sock \
					--shm-size="1gb" \
					--restart unless-stopped \
					lscr.io/linuxserver/webtop:ubuntu-kde

			}

			local docker_describe="webtop基於Ubuntu的容器。若IP無法訪問，請添加域名訪問。"
			local docker_url="官網介紹: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use='echo "使用者名稱: ubuntu-abc"'
			local docker_passwd='echo "密碼: ubuntuABC123"'
			local app_size="2"
			docker_app

			;;
		7)
			clear
			send_stats "搭建哪吒"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "哪吒監控 $check_docker $update_status"
				echo "開源、輕量、易用的伺服器監控與維運工具"
				echo "官網搭建文件: https://nezha.wiki/guide/dashboard.html"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo
				echo "------------------------"
				echo "1. 使用"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " choice

				case $choice in
				1)
					check_disk_space 1
					install unzip jq
					install_docker
					curl -sL ${gh_proxy}raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
					;;

				*)
					break
					;;

				esac
				break_end
			done
			;;

		8)

			local docker_name="qbittorrent"
			local docker_img="lscr.io/linuxserver/qbittorrent:latest"
			local docker_port=8081

			docker_rum() {

				docker run -d \
					--name=qbittorrent \
					-e PUID=1000 \
					-e PGID=1000 \
					-e TZ=Etc/UTC \
					-e WEBUI_PORT=${docker_port} \
					-e TORRENTING_PORT=56881 \
					-p ${docker_port}:${docker_port} \
					-p 56881:56881 \
					-p 56881:56881/udp \
					-v /home/docker/qbittorrent/config:/config \
					-v /home/docker/qbittorrent/downloads:/downloads \
					--restart unless-stopped \
					lscr.io/linuxserver/qbittorrent:latest

			}

			local docker_describe="qbittorrent離線BT磁力下載服務"
			local docker_url="官網介紹: https://hub.docker.com/r/linuxserver/qbittorrent"
			local docker_use="sleep 3"
			local docker_passwd="docker logs qbittorrent"
			local app_size="1"
			docker_app

			;;

		9)
			send_stats "搭建邮局"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "郵局服務 $check_docker $update_status"
				echo "poste.io 是一個開源的郵件伺服器解決方案，"
				echo "影片介紹: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo
				echo "埠檢測"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
					echo -e "${gl_lv}埠 $port 目前可用${gl_bai}"
				else
					echo -e "${gl_hong}埠 $port 目前不可用${gl_bai}"
				fi
				echo

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "訪問地址: "
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. 安裝           2. 更新           3. 卸載"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " choice

				case $choice in
				1)
					check_disk_space 2
					Ask "請設定郵箱域名 例如 mail.yuming.com : " yuming
					mkdir -p /home/docker
					echo "$yuming" >/home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "先解析這些DNS記錄"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo
					echo "------------------------"
					Press "按任意鍵繼續..."

					install jq
					install_docker

					docker run \
						--net=host \
						-e TZ=Europe/Prague \
						-v /home/docker/mail:/data \
						--name "mailserver" \
						-h "$yuming" \
						--restart=always \
						-d analogic/poste.io

					clear
					echo "poste.io 已安裝完成"
					echo "------------------------"
					echo "您可以使用以下位址存取poste.io:"
					echo "https://$yuming"
					echo

					;;

				2)
					docker rm -f mailserver
					docker rmi -f analogic/poste.i
					yuming=$(cat /home/docker/mail.txt)
					docker run \
						--net=host \
						-e TZ=Europe/Prague \
						-v /home/docker/mail:/data \
						--name "mailserver" \
						-h "$yuming" \
						--restart=always \
						-d analogic/poste.i
					clear
					echo "poste.io 已安裝完成"
					echo "------------------------"
					echo "您可以使用以下位址存取poste.io:"
					echo "https://$yuming"
					echo
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail
					echo "應用已移除"
					;;

				*)
					break
					;;

				esac
				break_end
			done

			;;

		10)

			local app_name="Rocket.Chat聊天系統"
			local app_text="Rocket.Chat 是一個開源的團隊通訊平台，支援即時聊天、音視訊通話、檔案共享等多種功能，"
			local app_url="官方介紹: https://www.rocket.chat/"
			local docker_name="rocketchat"
			local docker_port="3897"
			local app_size="2"

			docker_app_install() {
				docker run --name db -d --restart=always \
					-v /home/docker/mongo/dump:/dump \
					mongo:latest --replSet rs5 --oplogSize 256
				sleep 1
				docker exec -it db mongosh --eval "printjson(rs.initiate())"
				sleep 5
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

				clear
				ip_address
				echo "已安裝完成"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "rocket.chat 已安裝完成"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "應用已移除"
			}

			docker_app_plus
			;;

		11)
			local docker_name="zentao-server"
			local docker_img="idoop/zentao:latest"
			local docker_port=82

			docker_rum() {

				docker run -d -p ${docker_port}:80 \
					-e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
					-e BIND_ADDRESS="false" \
					-v /home/docker/zentao-server/:/opt/zbox/ \
					--add-host smtp.exmail.qq.com:163.177.90.125 \
					--name zentao-server \
					--restart=always \
					idoop/zentao:latest

			}

			local docker_describe="禪道是通用的專案管理軟體"
			local docker_url="官網介紹: https://www.zentao.net/"
			local docker_use='echo "初始使用者名稱: admin"'
			local docker_passwd='echo "初始密碼: 123456"'
			local app_size="2"
			docker_app

			;;

		12)
			local docker_name="qinglong"
			local docker_img="whyour/qinglong:latest"
			local docker_port=5700

			docker_rum() {

				docker run -d \
					-v /home/docker/qinglong/data:/ql/data \
					-p ${docker_port}:5700 \
					--name qinglong \
					--hostname qinglong \
					--restart unless-stopped \
					whyour/qinglong:latest

			}

			local docker_describe="青龍面板是一個定時任務管理平台"
			local docker_url="官網介紹: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		13)

			local app_name="cloudreve網盤"
			local app_text="cloudreve是一個支援多家雲儲存的網盤系統"
			local app_url="影片介紹: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
			local docker_name="cloudreve"
			local docker_port="5212"
			local app_size="2"

			docker_app_install() {
				cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
				curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
				sed -i "s/5212:5212/${docker_port}:5212/g" /home/docker/cloud/docker-compose.yml
				cd /home/docker/cloud/
				docker compose up -d
				clear
				echo "已安裝完成"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "應用已移除"
			}

			docker_app_plus
			;;

		14)
			local docker_name="easyimage"
			local docker_img="ddsderek/easyimage:latest"
			local docker_port=85
			docker_rum() {

				docker run -d \
					--name easyimage \
					-p ${docker_port}:80 \
					-e TZ=Asia/Shanghai \
					-e PUID=1000 \
					-e PGID=1000 \
					-v /home/docker/easyimage/config:/app/web/config \
					-v /home/docker/easyimage/i:/app/web/i \
					--restart unless-stopped \
					ddsderek/easyimage:latest

			}

			local docker_describe="簡單圖床是一個簡單的圖床程式"
			local docker_url="官網介紹: ${gh_proxy}github.com/icret/EasyImages2.0"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		15)
			local docker_name="emby"
			local docker_img="linuxserver/emby:latest"
			local docker_port=8096

			docker_rum() {

				docker run -d --name=emby --restart=always \
					-v /home/docker/emby/config:/config \
					-v /home/docker/emby/share1:/mnt/share1 \
					-v /home/docker/emby/share2:/mnt/share2 \
					-v /mnt/notify:/mnt/notify \
					-p ${docker_port}:8096 \
					-e UID=1000 -e GID=100 -e GIDLIST=100 \
					linuxserver/emby:latest

			}

			local docker_describe="emby是一個主從式架構的媒體伺服器軟體，可以用來整理伺服器上的影片和音訊，並將音訊和影片串流傳輸到用戶端設備"
			local docker_url="官網介紹: https://emby.media/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		16)
			local docker_name="looking-glass"
			local docker_img="wikihostinc/looking-glass-server"
			local docker_port=89

			docker_rum() {

				docker run -d --name looking-glass --restart always -p ${docker_port}:80 wikihostinc/looking-glass-server

			}

			local docker_describe="Speedtest測速面板是一個VPS網速測試工具，多項測試功能，還可以即時監控VPS進出站流量"
			local docker_url="官網介紹: ${gh_proxy}github.com/wikihost-opensource/als"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		17)

			local docker_name="adguardhome"
			local docker_img="adguard/adguardhome"
			local docker_port=3000

			docker_rum() {

				docker run -d \
					--name adguardhome \
					-v /home/docker/adguardhome/work:/opt/adguardhome/work \
					-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
					-p 53:53/tcp \
					-p 53:53/udp \
					-p ${docker_port}:3000/tcp \
					--restart always \
					adguard/adguardhome

			}

			local docker_describe="AdGuardHome是一款全網廣告攔截與反追蹤軟體，未來將不止是一個DNS伺服器。"
			local docker_url="官網介紹: https://hub.docker.com/r/adguard/adguardhome"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		18)

			local docker_name="onlyoffice"
			local docker_img="onlyoffice/documentserver"
			local docker_port=8082

			docker_rum() {

				docker run -d -p ${docker_port}:80 \
					--restart=always \
					--name onlyoffice \
					-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice \
					-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
					onlyoffice/documentserver

			}

			local docker_describe="onlyoffice是一款開源的線上office工具，太強大了！"
			local docker_url="官網介紹: https://www.onlyoffice.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			;;

		19)
			send_stats "搭建雷池"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "雷池服務 $check_docker"
				echo "雷池是長亭科技開發的WAF網站防火牆程式面板，可以反代網站進行自動化防禦"
				echo "影片介紹: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo

				echo "------------------------"
				echo "1. 安裝           2. 更新           3. 重設密碼           4. 移除"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " choice

				case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
					clear
					echo "雷池WAF面板已安裝完成"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo
					clear
					echo "雷池WAF面板已更新完成"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all
					echo "如果您是預設安裝目錄，那現在專案已移除。如果您是自訂安裝目錄，您需要到安裝目錄下自行執行:"
					echo "docker compose down && docker compose down --rmi all"
					;;
				*)
					break
					;;

				esac
				break_end
			done

			;;

		20)
			local docker_name="portainer"
			local docker_img="portainer/portainer"
			local docker_port=9050

			docker_rum() {

				docker run -d \
					--name portainer \
					-p ${docker_port}:9000 \
					-v /var/run/docker.sock:/var/run/docker.sock \
					-v /home/docker/portainer:/data \
					--restart always \
					portainer/portainer

			}

			local docker_describe="portainer是一個輕量級的docker容器管理面板"
			local docker_url="官網介紹: https://www.portainer.io/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		21)
			local docker_name="vscode-web"
			local docker_img="codercom/code-server"
			local docker_port=8180

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server

			}

			local docker_describe="VScode是一款強大的線上程式碼編寫工具"
			local docker_url="官網介紹: ${gh_proxy}github.com/coder/code-server"
			local docker_use="sleep 3"
			local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
			local app_size="1"
			docker_app
			;;
		22)
			local docker_name="uptime-kuma"
			local docker_img="louislam/uptime-kuma:latest"
			local docker_port=3003

			docker_rum() {

				docker run -d \
					--name=uptime-kuma \
					-p ${docker_port}:3001 \
					-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
					--restart=always \
					louislam/uptime-kuma:latest

			}

			local docker_describe="Uptime Kuma 易於使用的自託管監控工具"
			local docker_url="官網介紹: ${gh_proxy}github.com/louislam/uptime-kuma"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		23)
			local docker_name="memos"
			local docker_img="ghcr.io/usememos/memos:latest"
			local docker_port=5230

			docker_rum() {

				docker run -d --name memos -p ${docker_port}:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest

			}

			local docker_describe="Memos是一款輕量級、自託管的備忘錄中心"
			local docker_url="官網介紹: ${gh_proxy}github.com/usememos/memos"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		24)
			local docker_name="webtop"
			local docker_img="lscr.io/linuxserver/webtop:latest"
			local docker_port=3083

			docker_rum() {

				docker run -d \
					--name=webtop \
					--security-opt seccomp=unconfined \
					-e PUID=1000 \
					-e PGID=1000 \
					-e TZ=Etc/UTC \
					-e SUBFOLDER=/ \
					-e TITLE=Webtop \
					-e CUSTOM_USER=webtop-abc \
					-e PASSWORD=webtopABC123 \
					-e LC_ALL=zh_CN.UTF-8 \
					-e DOCKER_MODS=linuxserver/mods:universal-package-install \
					-e INSTALL_PACKAGES=font-noto-cjk \
					-p ${docker_port}:3000 \
					-v /home/docker/webtop/data:/config \
					-v /var/run/docker.sock:/var/run/docker.sock \
					--shm-size="1gb" \
					--restart unless-stopped \
					lscr.io/linuxserver/webtop:latest

			}

			local docker_describe="webtop基於Alpine的中文版容器。若IP無法訪問，請添加域名訪問。"
			local docker_url="官網介紹: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use='echo "使用者名稱: webtop-abc"'
			local docker_passwd='echo "密碼: webtopABC123"'
			local app_size="2"
			docker_app
			;;

		25)
			local docker_name="nextcloud"
			local docker_img="nextcloud:latest"
			local docker_port=8989
			local rootpasswd=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

			docker_rum() {

				docker run -d --name nextcloud --restart=always -p ${docker_port}:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud

			}

			local docker_describe="Nextcloud擁有超過 400,000 個部署，是您可以下載的最受歡迎的本地內容協作平台"
			local docker_url="官網介紹: https://nextcloud.com/"
			local docker_use="echo \\\"帳號: nextcloud  密碼: $rootpasswd\\\""
			local docker_passwd=""
			local app_size="3"
			docker_app
			;;

		26)
			local docker_name="qd"
			local docker_img="qdtoday/qd:latest"
			local docker_port=8923

			docker_rum() {

				docker run -d --name qd -p ${docker_port}:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd

			}

			local docker_describe="QD-Today是一個HTTP請求定時任務自動執行框架"
			local docker_url="官網介紹: https://qd-today.github.io/qd/zh_CN/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;
		27)
			local docker_name="dockge"
			local docker_img="louislam/dockge:latest"
			local docker_port=5003

			docker_rum() {

				docker run -d --name dockge --restart unless-stopped -p ${docker_port}:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge

			}

			local docker_describe="dockge是一個可視化的docker-compose容器管理面板"
			local docker_url="官網介紹: ${gh_proxy}github.com/louislam/dockge"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		28)
			local docker_name="speedtest"
			local docker_img="ghcr.io/librespeed/speedtest"
			local docker_port=8028

			docker_rum() {

				docker run -d -p ${docker_port}:8080 --name speedtest --restart always ghcr.io/librespeed/speedtest

			}

			local docker_describe="librespeed是用Javascript實現的輕量級速度測試工具，即開即用"
			local docker_url="官網介紹: ${gh_proxy}github.com/librespeed/speedtest"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		29)
			local docker_name="searxng"
			local docker_img="searxng/searxng"
			local docker_port=8029

			docker_rum() {

				docker run -d \
					--name searxng \
					--restart unless-stopped \
					-p ${docker_port}:8080 \
					-v "/home/docker/searxng:/etc/searxng" \
					searxng/searxng

			}

			local docker_describe="searxng是一個私有且隱私的搜尋引擎站點"
			local docker_url="官網介紹: https://hub.docker.com/r/alandoyle/searxng"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		30)
			local docker_name="photoprism"
			local docker_img="photoprism/photoprism:latest"
			local docker_port=2342
			local rootpasswd=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

			docker_rum() {

				docker run -d \
					--name photoprism \
					--restart always \
					--security-opt seccomp=unconfined \
					--security-opt apparmor=unconfined \
					-p ${docker_port}:2342 \
					-e PHOTOPRISM_UPLOAD_NSFW="true" \
					-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
					-v /home/docker/photoprism/storage:/photoprism/storage \
					-v /home/docker/photoprism/Pictures:/photoprism/originals \
					photoprism/photoprism

			}

			local docker_describe="photoprism非常強大的私有相簿系統"
			local docker_url="官網介紹: https://www.photoprism.app/"
			local docker_use="echo \\\"帳號: admin  密碼: $rootpasswd\\\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		31)
			local docker_name="s-pdf"
			local docker_img="frooodle/s-pdf:latest"
			local docker_port=8020

			docker_rum() {

				docker run -d \
					--name s-pdf \
					--restart=always \
					-p ${docker_port}:8080 \
					-v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
					-v /home/docker/s-pdf/extraConfigs:/configs \
					-v /home/docker/s-pdf/logs:/logs \
					-e DOCKER_ENABLE_SECURITY=false \
					frooodle/s-pdf:latest
			}

			local docker_describe="這是一個強大的本地託管基於 Web 的 PDF 操作工具，使用 docker，允許您對 PDF 檔案執行各種操作，例如拆分合併、轉換、重新組織、添加圖像、旋轉、壓縮等。"
			local docker_url="官網介紹: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		32)
			local docker_name="drawio"
			local docker_img="jgraph/drawio"
			local docker_port=7080

			docker_rum() {

				docker run -d --restart=always --name drawio -p ${docker_port}:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio

			}

			local docker_describe="這是一個強大圖表繪製軟體。思維導圖，拓撲圖，流程圖，都能畫"
			local docker_url="官網介紹: https://www.drawio.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		33)
			local docker_name="sun-panel"
			local docker_img="hslr/sun-panel"
			local docker_port=3009

			docker_rum() {

				docker run -d --restart=always -p ${docker_port}:3002 \
					-v /home/docker/sun-panel/conf:/app/conf \
					-v /home/docker/sun-panel/uploads:/app/uploads \
					-v /home/docker/sun-panel/database:/app/database \
					--name sun-panel \
					hslr/sun-panel

			}

			local docker_describe="Sun-Panel伺服器、NAS導航面板、Homepage、瀏覽器首頁"
			local docker_url="官網介紹: https://doc.sun-panel.top/zh_cn/"
			local docker_use='echo "帳號: admin@sun.cc  密碼: 12345678"'
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		34)
			local docker_name="pingvin-share"
			local docker_img="stonith404/pingvin-share"
			local docker_port=3060

			docker_rum() {

				docker run -d \
					--name pingvin-share \
					--restart always \
					-p ${docker_port}:3000 \
					-v /home/docker/pingvin-share/data:/opt/app/backend/data \
					stonith404/pingvin-share
			}

			local docker_describe="Pingvin Share 是一個可自建的檔案分享平台，是 WeTransfer 的一個替代品"
			local docker_url="官網介紹: ${gh_proxy}github.com/stonith404/pingvin-share"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		35)
			local docker_name="moments"
			local docker_img="kingwrcy/moments:latest"
			local docker_port=8035

			docker_rum() {

				docker run -d --restart unless-stopped \
					-p ${docker_port}:3000 \
					-v /home/docker/moments/data:/app/data \
					-v /etc/localtime:/etc/localtime:ro \
					-v /etc/timezone:/etc/timezone:ro \
					--name moments \
					kingwrcy/moments:latest
			}

			local docker_describe="極簡朋友圈，高仿微信朋友圈，記錄你的美好生活"
			local docker_url="官網介紹: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use='echo "帳號: admin  密碼: a123456"'
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		36)
			local docker_name="lobe-chat"
			local docker_img="lobehub/lobe-chat:latest"
			local docker_port=8036

			docker_rum() {

				docker run -d -p ${docker_port}:3210 \
					--name lobe-chat \
					--restart=always \
					lobehub/lobe-chat
			}

			local docker_describe="LobeChat聚合市面上主流的AI大模型，ChatGPT/Claude/Gemini/Groq/Ollama"
			local docker_url="官網介紹: ${gh_proxy}github.com/lobehub/lobe-chat"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			;;

		37)
			local docker_name="myip"
			local docker_img="jason5ng32/myip:latest"
			local docker_port=8037

			docker_rum() {

				docker run -d -p ${docker_port}:18966 --name myip jason5ng32/myip:latest

			}

			local docker_describe="是一個多功能IP工具箱，可以查看自己IP資訊及連通性，用網頁面板呈現"
			local docker_url="官網介紹: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		38)
			send_stats "小雅全家桶"
			clear
			install_docker
			check_disk_space 1
			bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
			;;

		39)

			if [ ! -d /home/docker/bililive-go/ ]; then
				mkdir -p /home/docker/bililive-go/ >/dev/null 2>&1
				wget -O /home/docker/bililive-go/config.yml ${gh_proxy}raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml >/dev/null 2>&1
			fi

			local docker_name="bililive-go"
			local docker_img="chigusa/bililive-go"
			local docker_port=8039

			docker_rum() {

				docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p ${docker_port}:8080 -d chigusa/bililive-go

			}

			local docker_describe="Bililive-go是一個支援多種直播平台的直播錄製工具"
			local docker_url="官網介紹: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		40)
			local docker_name="webssh"
			local docker_img="jrohy/webssh"
			local docker_port=8040
			docker_rum() {
				docker run -d -p ${docker_port}:5032 --restart always --name webssh -e TZ=Asia/Shanghai jrohy/webssh
			}

			local docker_describe="簡易線上ssh連接工具和sftp工具"
			local docker_url="官網介紹: ${gh_proxy}github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		41)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="耗子面板"
			local panelurl="官方地址: ${gh_proxy}github.com/TheTNB/panel"

			panel_app_install() {
				mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o install.sh https://dl.cdn.haozi.net/panel/install.sh && bash install.sh
				cd ~
			}

			panel_app_manage() {
				panel-cli
			}

			panel_app_uninstall() {
				mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o uninstall.sh https://dl.cdn.haozi.net/panel/uninstall.sh && bash uninstall.sh
				cd ~
			}

			install_panel

			;;

		42)
			local docker_name="nexterm"
			local docker_img="germannewsmaker/nexterm:latest"
			local docker_port=8042

			docker_rum() {

				docker run -d \
					--name nexterm \
					-p ${docker_port}:6989 \
					-v /home/docker/nexterm:/app/data \
					--restart unless-stopped \
					germannewsmaker/nexterm:latest

			}

			local docker_describe="nexterm是一款強大的線上SSH/VNC/RDP連接工具。"
			local docker_url="官網介紹: ${gh_proxy}github.com/gnmyt/Nexterm"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		43)
			local docker_name="hbbs"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=0000

			docker_rum() {

				docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbs

			}

			local docker_describe="rustdesk開源的遠端桌面(伺服端)，類似自己的向日葵私服。"
			local docker_url="官網介紹: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd='echo "請記錄您的IP和key，將會在遠端桌面用戶端中使用。請前往44選項安裝中繼端！"'
			local app_size="1"
			docker_app
			;;

		44)
			local docker_name="hbbr"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=0000

			docker_rum() {

				docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbr

			}

			local docker_describe="rustdesk開源的遠端桌面(中繼端)，類似自己的向日葵私服。"
			local docker_url="官網介紹: https://rustdesk.com/zh-cn/"
			local docker_use='echo "前往官網下載遠端桌面的用戶端: https://rustdesk.com/zh-cn/"'
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		45)
			local docker_name="registry"
			local docker_img="registry:2"
			local docker_port=8045

			docker_rum() {

				docker run -d \
					-p ${docker_port}:5000 \
					--name registry \
					-v /home/docker/registry:/var/lib/registry \
					-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
					--restart always \
					registry:2

			}

			local docker_describe="Docker Registry 是用於儲存和分發 Docker 映像的服務。"
			local docker_url="官網介紹: https://hub.docker.com/_/registry"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			;;

		46)
			local docker_name="ghproxy"
			local docker_img="wjqserver/ghproxy:latest"
			local docker_port=8046

			docker_rum() {

				docker run -d --name ghproxy --restart always -p ${docker_port}:8080 wjqserver/ghproxy:latest

			}

			local docker_describe="使用Go實現的GHProxy，用於加速部分地區Github倉庫的拉取。"
			local docker_url="官網介紹: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		47)

			local app_name="普羅米修斯監控"
			local app_text="Prometheus+Grafana企業級監控系統"
			local app_url="官網介紹: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
				echo "已安裝完成"
				check_docker_app_ip
				echo "初始使用者名稱密碼均為: admin"
			}

			docker_app_update() {
				docker rm -f node-exporter prometheus grafana
				docker rmi -f prom/node-exporter
				docker rmi -f prom/prometheus:latest
				docker rmi -f grafana/grafana:latest
				docker_app_install
			}

			docker_app_uninstall() {
				docker rm -f node-exporter prometheus grafana
				docker rmi -f prom/node-exporter
				docker rmi -f prom/prometheus:latest
				docker rmi -f grafana/grafana:latest

				rm -rf /home/docker/monitoring
				echo "應用已移除"
			}

			docker_app_plus
			;;

		48)
			local docker_name="node-exporter"
			local docker_img="prom/node-exporter"
			local docker_port=8048

			docker_rum() {

				docker run -d \
					--name=node-exporter \
					-p ${docker_port}:9100 \
					--restart unless-stopped \
					prom/node-exporter

			}

			local docker_describe="這是一個普羅米修斯的主機數據採集元件，請部署在被監控主機上。"
			local docker_url="官網介紹: https://github.com/prometheus/node_exporter"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		49)
			local docker_name="cadvisor"
			local docker_img="gcr.io/cadvisor/cadvisor:latest"
			local docker_port=8049

			docker_rum() {

				docker run -d \
					--name=cadvisor \
					--restart unless-stopped \
					-p ${docker_port}:8080 \
					--volume=/:/rootfs:ro \
					--volume=/var/run:/var/run:rw \
					--volume=/sys:/sys:ro \
					--volume=/var/lib/docker/:/var/lib/docker:ro \
					gcr.io/cadvisor/cadvisor:latest \
					-housekeeping_interval=10s \
					-docker_only=true

			}

			local docker_describe="這是一個普羅米修斯的容器數據採集元件，請部署在被監控主機上。"
			local docker_url="官網介紹: https://github.com/google/cadvisor"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		50)
			local docker_name="changedetection"
			local docker_img="dgtlmoon/changedetection.io:latest"
			local docker_port=8050

			docker_rum() {

				docker run -d --restart always -p ${docker_port}:5000 \
					-v /home/docker/datastore:/datastore \
					--name changedetection dgtlmoon/changedetection.io:latest

			}

			local docker_describe="這是一款網站變化檢測、補貨監控和通知的小工具"
			local docker_url="官網介紹: https://github.com/dgtlmoon/changedetection.io"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		51)
			clear
			send_stats "PVE开小鸡"
			check_disk_space 1
			curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
			;;

		52)
			local docker_name="dpanel"
			local docker_img="dpanel/dpanel:lite"
			local docker_port=8052

			docker_rum() {

				docker run -it -d --name dpanel --restart=always \
					-p ${docker_port}:8080 -e APP_NAME=dpanel \
					-v /var/run/docker.sock:/var/run/docker.sock \
					-v /home/docker/dpanel:/dpanel \
					dpanel/dpanel:lite

			}

			local docker_describe="Docker可視化面板系統，提供完善的docker管理功能。"
			local docker_url="官網介紹: https://github.com/donknap/dpanel"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		53)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama

			}

			local docker_describe="OpenWebUI一款大語言模型網頁框架，接入全新的llama3大語言模型"
			local docker_url="官網介紹: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3.2:1b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		54)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="AMH面板"
			local panelurl="官方地址: https://amh.sh/index.htm?amh"

			panel_app_install() {
				cd ~
				wget https://dl.amh.sh/amh.sh && bash amh.sh
			}

			panel_app_manage() {
				panel_app_install
			}

			panel_app_uninstall() {
				panel_app_install
			}

			install_panel
			;;

		55)
			frps_panel
			;;

		56)
			frpc_panel
			;;

		57)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama

			}

			local docker_describe="OpenWebUI一款大語言模型網頁框架，接入全新的DeepSeek R1大語言模型"
			local docker_url="官網介紹: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		58)
			local app_name="Dify知識庫"
			local app_text="是一款開源的大語言模型(LLM) 應用開發平台。自託管訓練資料用於AI生成"
			local app_url="官方網站: https://docs.dify.ai/zh-hans"
			local docker_name="docker-nginx-1"
			local docker_port="8058"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langgenius/dify.git && cd dify/docker && cp .env.example .env
				# sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				sed -i "s/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/" /home/docker/dify/docker/.env

				docker compose up -d
				clear
				echo "已安裝完成"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/dify/docker/ && docker compose down --rmi all
				cd /home/docker/dify/
				git pull origin main
				sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				cd /home/docker/dify/docker/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/dify/docker/ && docker compose down --rmi all
				rm -rf /home/docker/dify
				echo "應用已移除"
			}

			docker_app_plus

			;;

		59)
			local app_name="New API"
			local app_text="新一代大模型網關與AI資產管理系統"
			local app_url="官方網站: https://github.com/Calcium-Ion/new-api"
			local docker_name="new-api"
			local docker_port="8059"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/Calcium-Ion/new-api.git && cd new-api

				sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
					-e 's/container_name: redis/container_name: redis-new-api/g' \
					-e 's/container_name: mysql/container_name: mysql-new-api/g' \
					docker-compose.yml

				docker compose up -d
				clear
				echo "已安裝完成"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				cd /home/docker/new-api/
				git pull origin main
				sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
					-e 's/container_name: redis/container_name: redis-new-api/g' \
					-e 's/container_name: mysql/container_name: mysql-new-api/g' \
					docker-compose.yml

				docker compose up -d
				clear
				echo "已安裝完成"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "應用已移除"
			}

			docker_app_plus

			;;

		60)

			local app_name="JumpServer開源堡壘機"
			local app_text="是一個開源的特權存取管理 (PAM) 工具，該程式佔用80埠不支援添加域名訪問了"
			local app_url="官方介紹: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
				echo "已安裝完成"
				check_docker_app_ip
				echo "初始使用者名稱: admin"
				echo "初始密碼: ChangeMe"
			}

			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "應用程式已更新"
			}

			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "應用已移除"
			}

			docker_app_plus
			;;

		61)
			local docker_name="libretranslate"
			local docker_img="libretranslate/libretranslate:latest"
			local docker_port=8061

			docker_rum() {

				docker run -d \
					-p ${docker_port}:5000 \
					--name libretranslate \
					libretranslate/libretranslate \
					--load-only ko,zt,zh,en,ja,pt,es,fr,de,ru

			}

			local docker_describe="免費開源機器翻譯 API，完全自託管，它的翻譯引擎由開源Argos Translate庫提供支援。"
			local docker_url="官網介紹: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		62)
			local app_name="RAGFlow知識庫"
			local app_text="基於深度文件理解的開源 RAG（檢索增強生成）引擎"
			local app_url="官方網站: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
				clear
				echo "已安裝完成"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/ragflow/docker/ && docker compose down --rmi all
				cd /home/docker/ragflow/
				git pull origin main
				cd /home/docker/ragflow/docker/
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/ragflow/docker/ && docker compose down --rmi all
				rm -rf /home/docker/ragflow
				echo "應用已移除"
			}

			docker_app_plus

			;;

		63)
			local docker_name="open-webui"
			local docker_img="ghcr.io/open-webui/open-webui:main"
			local docker_port=8063

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

			}

			local docker_describe="OpenWebUI一款大語言模型網頁框架，官方精簡版本，支援各大模型API接入"
			local docker_url="官網介紹: https://github.com/open-webui/open-webui"
			local docker_use=""
			local docker_passwd=""
			local app_size="3"
			docker_app
			;;

		64)
			local docker_name="it-tools"
			local docker_img="corentinth/it-tools:latest"
			local docker_port=8064

			docker_rum() {
				docker run -d --name it-tools --restart unless-stopped -p ${docker_port}:80 corentinth/it-tools:latest
			}

			local docker_describe="對開發人員和 IT 工作者來說非常有用的工具"
			local docker_url="官網介紹: https://github.com/CorentinTh/it-tools"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		65)
			local docker_name="n8n"
			local docker_img="docker.n8n.io/n8nio/n8n"
			local docker_port=8065

			docker_rum() {

				add_yuming
				mkdir -p /home/docker/n8n
				chmod -R 777 /home/docker/n8n

				docker run -d --name n8n \
					--restart always \
					-p ${docker_port}:5678 \
					-v /home/docker/n8n:/home/node/.n8n \
					-e N8N_HOST=${yuming} \
					-e N8N_PORT=5678 \
					-e N8N_PROTOCOL=https \
					-e N8N_WEBHOOK_URL=https://${yuming}/ \
					docker.n8n.io/n8nio/n8n

				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"

			}

			local docker_describe="是一款功能強大的自動化工作流程平台"
			local docker_url="官網介紹: https://github.com/n8n-io/n8n"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		66)
			yt_menu_pro
			;;

		67)
			local docker_name="ddns-go"
			local docker_img="jeessy/ddns-go"
			local docker_port=8067

			docker_rum() {
				docker run -d \
					--name ddns-go \
					--restart=always \
					-p ${docker_port}:9876 \
					-v /home/docker/ddns-go:/root \
					jeessy/ddns-go

			}

			local docker_describe="自動將你的公網 IP（IPv4/IPv6）即時更新到各大 DNS 服務商，實現動態域名解析。"
			local docker_url="官網介紹: https://github.com/jeessy2/ddns-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		68)
			local docker_name="allinssl"
			local docker_img="allinssl/allinssl:latest"
			local docker_port=8068

			docker_rum() {
				docker run -itd --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
			}

			local docker_describe="開源免費的 SSL 憑證自動化管理平台"
			local docker_url="官網介紹: https://allinssl.com"
			local docker_use='echo "安全入口: /allinssl"'
			local docker_passwd='echo "使用者名稱: allinssl  密碼: allinssldocker"'
			local app_size="1"
			docker_app
			;;

		69)
			local docker_name="sftpgo"
			local docker_img="drakkan/sftpgo:latest"
			local docker_port=8069

			docker_rum() {

				mkdir -p /home/docker/sftpgo/data
				mkdir -p /home/docker/sftpgo/config
				chown -R 1000:1000 /home/docker/sftpgo

				docker run -d \
					--name sftpgo \
					--restart=always \
					-p ${docker_port}:8080 \
					-p 22022:2022 \
					--mount type=bind,source=/home/docker/sftpgo/data,target=/srv/sftpgo \
					--mount type=bind,source=/home/docker/sftpgo/config,target=/var/lib/sftpgo \
					drakkan/sftpgo:latest

			}

			local docker_describe="開源免費隨時隨地SFTP FTP WebDAV 檔案傳輸工具"
			local docker_url="官網介紹: https://sftpgo.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		70)
			local docker_name="astrbot"
			local docker_img="soulter/astrbot:latest"
			local docker_port=8070

			docker_rum() {

				mkdir -p /home/docker/astrbot/data

				sudo docker run -d \
					-p ${docker_port}:6185 \
					-p 6195:6195 \
					-p 6196:6196 \
					-p 6199:6199 \
					-p 11451:11451 \
					-v /home/docker/astrbot/data:/AstrBot/data \
					--restart unless-stopped \
					--name astrbot \
					soulter/astrbot:latest

			}

			local docker_describe="開源AI聊天機器人框架，支援微信，QQ，TG接入AI大模型"
			local docker_url="官網介紹: https://astrbot.app/"
			local docker_use='echo "使用者名稱: astrbot  密碼: astrbot"'
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		71)
			local docker_name="navidrome"
			local docker_img="deluan/navidrome:latest"
			local docker_port=8071

			docker_rum() {

				docker run -d \
					--name navidrome \
					--restart=unless-stopped \
					--user $(id -u):$(id -g) \
					-v /home/docker/navidrome/music:/music \
					-v /home/docker/navidrome/data:/data \
					-p ${docker_port}:4533 \
					-e ND_LOGLEVEL=info \
					deluan/navidrome:latest

			}

			local docker_describe="是一個輕量、高性能的音樂串流媒體伺服器"
			local docker_url="官網介紹: https://www.navidrome.org/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		72)

			local docker_name="bitwarden"
			local docker_img="vaultwarden/server"
			local docker_port=8072

			docker_rum() {

				docker run -d \
					--name bitwarden \
					--restart always \
					-p ${docker_port}:80 \
					-v /home/docker/bitwarden/data:/data \
					vaultwarden/server

			}

			local docker_describe="一個你可以控制數據的密碼管理器"
			local docker_url="官網介紹: https://bitwarden.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		73)

			local docker_name="libretv"
			local docker_img="bestzwei/libretv:latest"
			local docker_port=8073

			docker_rum() {

				Ask "設定LibreTV的登錄密碼: " app_passwd

				docker run -d \
					--name libretv \
					--restart unless-stopped \
					-p ${docker_port}:8080 \
					-e PASSWORD=${app_passwd} \
					bestzwei/libretv:latest

			}

			local docker_describe="免費線上影片搜尋與觀看平台"
			local docker_url="官網介紹: https://github.com/LibreSpark/LibreTV"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		74)

			local docker_name="moontv"
			local docker_img="ghcr.io/senshinya/moontv:latest"
			local docker_port=8074

			docker_rum() {

				Ask "設定MoonTV的登錄密碼: " app_passwd

				docker run -d \
					--name moontv \
					--restart unless-stopped \
					-p ${docker_port}:3000 \
					-e PASSWORD=${app_passwd} \
					ghcr.io/senshinya/moontv:latest

			}

			local docker_describe="免費線上影片搜尋與觀看平台"
			local docker_url="官網介紹: https://github.com/senshinya/MoonTV"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		75)

			local docker_name="melody"
			local docker_img="foamzou/melody:latest"
			local docker_port=8075

			docker_rum() {

				docker run -d \
					--name melody \
					--restart unless-stopped \
					-p ${docker_port}:5566 \
					-v /home/docker/melody/.profile:/app/backend/.profile \
					foamzou/melody:latest

			}

			local docker_describe="你的音樂精靈，旨在幫助你更好地管理音樂。"
			local docker_url="官網介紹: https://github.com/foamzou/melody"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		76)

			local docker_name="dosgame"
			local docker_img="oldiy/dosgame-web-docker:latest"
			local docker_port=8076

			docker_rum() {
				docker run -d \
					--name dosgame \
					--restart unless-stopped \
					-p ${docker_port}:262 \
					oldiy/dosgame-web-docker:latest

			}

			local docker_describe="是一個中文DOS遊戲合集網站"
			local docker_url="官網介紹: https://github.com/rwv/chinese-dos-games"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			;;

		77)

			local docker_name="xunlei"
			local docker_img="cnk3x/xunlei"
			local docker_port=8077

			docker_rum() {

				Ask "設定${docker_name}的登錄用戶名: " app_use
				Ask "設定${docker_name}的登錄密碼: " app_passwd

				docker run -d \
					--name xunlei \
					--restart unless-stopped \
					--privileged \
					-e XL_DASHBOARD_USERNAME=${app_use} \
					-e XL_DASHBOARD_PASSWORD=${app_passwd} \
					-v /home/docker/xunlei/data:/xunlei/data \
					-v /home/docker/xunlei/downloads:/xunlei/downloads \
					-p ${docker_port}:2345 \
					cnk3x/xunlei

			}

			local docker_describe="迅雷你的離線高速BT磁力下載工具"
			local docker_url="官網介紹: https://github.com/cnk3x/xunlei"
			local docker_use='echo "手機登入迅雷，再輸入邀請碼，邀請碼: 迅雷牛通"'
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		78)

			local app_name="PandaWiki"
			local app_text="PandaWiki是一款AI大模型驅動的開源智能文件管理系統，強烈建議不要自定義埠部署。"
			local app_url="官方介紹: https://github.com/chaitin/PandaWiki"
			local docker_name="panda-wiki-nginx"
			local docker_port="2443"
			local app_size="2"

			docker_app_install() {
				bash -c "$(curl -fsSLk https://release.baizhi.cloud/panda-wiki/manager.sh)"
			}

			docker_app_update() {
				docker_app_install
			}

			docker_app_uninstall() {
				docker_app_install
			}

			docker_app_plus
			;;

		79)

			local docker_name="beszel"
			local docker_img="henrygd/beszel"
			local docker_port=8079

			docker_rum() {

				mkdir -p /home/docker/beszel &&
					docker run -d \
						--name beszel \
						--restart=unless-stopped \
						-v /home/docker/beszel:/beszel_data \
						-p ${docker_port}:8090 \
						henrygd/beszel

			}

			local docker_describe="Beszel輕量易用的伺服器監控"
			local docker_url="官網介紹: https://beszel.dev/zh/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		0)
			kejilion
			;;
		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done
}

linux_work() {

	while true; do
		clear
		send_stats "后台工作区"
		echo -e "後台工作區"
		echo -e "系統將為您提供可以後台常駐運行的工作區，您可以將其用於執行長時間的任務"
		echo -e "即使您斷開SSH，工作區中的任務也不會中斷，後台常駐任務。"
		echo -e "${gl_huang}提示: ${gl_bai}進入工作區後使用Ctrl+b再單獨按d，退出工作區！"
		echo -e "${gl_kjlan}------------------------"
		echo "目前已存在的工作區列表"
		echo -e "${gl_kjlan}------------------------"
		tmux list-sessions
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}1號工作區"
		echo -e "${gl_kjlan}2.   ${gl_bai}2號工作區"
		echo -e "${gl_kjlan}3.   ${gl_bai}3號工作區"
		echo -e "${gl_kjlan}4.   ${gl_bai}4號工作區"
		echo -e "${gl_kjlan}5.   ${gl_bai}5號工作區"
		echo -e "${gl_kjlan}6.   ${gl_bai}6號工作區"
		echo -e "${gl_kjlan}7.   ${gl_bai}7號工作區"
		echo -e "${gl_kjlan}8.   ${gl_bai}8號工作區"
		echo -e "${gl_kjlan}9.   ${gl_bai}9號工作區"
		echo -e "${gl_kjlan}10.  ${gl_bai}10號工作區"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}SSH常駐模式 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}22.  ${gl_bai}創建/進入工作區"
		echo -e "${gl_kjlan}23.  ${gl_bai}注入指令到後台工作區"
		echo -e "${gl_kjlan}24.  ${gl_bai}刪除指定工作區"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in

		1)
			clear
			install tmux
			local SESSION_NAME="work1"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run

			;;
		2)
			clear
			install tmux
			local SESSION_NAME="work2"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		3)
			clear
			install tmux
			local SESSION_NAME="work3"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		4)
			clear
			install tmux
			local SESSION_NAME="work4"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		5)
			clear
			install tmux
			local SESSION_NAME="work5"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		6)
			clear
			install tmux
			local SESSION_NAME="work6"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		7)
			clear
			install tmux
			local SESSION_NAME="work7"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		8)
			clear
			install tmux
			local SESSION_NAME="work8"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		9)
			clear
			install tmux
			local SESSION_NAME="work9"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;
		10)
			clear
			install tmux
			local SESSION_NAME="work10"
			send_stats "启动工作区$SESSION_NAME"
			tmux_run
			;;

		21)
			while true; do
				clear
				if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
					local tmux_sshd_status="${gl_lv}開啟${gl_bai}"
				else
					local tmux_sshd_status="${gl_hui}關閉${gl_bai}"
				fi
				send_stats "SSH常驻模式 "
				echo -e "SSH常駐模式 $tmux_sshd_status"
				echo "啟用後SSH連線後會直接進入常駐模式，直接回到之前的工作狀態。"
				echo "------------------------"
				echo "1. 啟用            2. 停用"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " gongzuoqu_del
				case "$gongzuoqu_del" in
				1)
					install tmux
					local SESSION_NAME="sshd"
					send_stats "启动工作区$SESSION_NAME"
					grep -q "tmux attach-session -t sshd" ~/.bashrc || {
						NO_TRAN="\n# 自动进入 tmux 会话\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi"
						echo -e "$NO_TRAN" >>~/.bashrc
					}
					source ~/.bashrc
					tmux_run
					;;
				2)
					sed -i '/# 自动进入 tmux 会话/,+4d' ~/.bashrc
					tmux kill-window -t sshd
					;;
				*)
					break
					;;
				esac
			done
			;;

		22)
			Ask "請輸入你創建或進入的工作區名稱，如1001 kj001 work1: " SESSION_NAME
			tmux_run
			send_stats "自定义工作区"
			;;

		23)
			Ask "請輸入你要後台執行的命令，如:curl -fsSL https://get.docker.com | sh: " tmuxd
			tmux_run_d
			send_stats "注入命令到后台工作区"
			;;

		24)
			Ask "請輸入要刪除的工作區名稱: " gongzuoqu_name
			tmux kill-window -t $gongzuoqu_name
			send_stats "删除工作区"
			;;

		0)
			kejilion
			;;
		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done

}

linux_Settings() {

	while true; do
		clear
		# send_stats "系统工具"
		echo -e "系統工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}設定腳本啟動快捷鍵                 ${gl_kjlan}2.   ${gl_bai}修改登入密碼"
		echo -e "${gl_kjlan}3.   ${gl_bai}ROOT密碼登入模式                   ${gl_kjlan}4.   ${gl_bai}安裝Python指定版本"
		echo -e "${gl_kjlan}5.   ${gl_bai}開放所有埠                       ${gl_kjlan}6.   ${gl_bai}修改SSH連線埠"
		echo -e "${gl_kjlan}7.   ${gl_bai}優化DNS位址                        ${gl_kjlan}8.   ${gl_bai}一鍵重裝系統 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}9.   ${gl_bai}禁用ROOT帳戶創建新帳戶             ${gl_kjlan}10.  ${gl_bai}切換優先ipv4/ipv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}查看埠佔用狀態                   ${gl_kjlan}12.  ${gl_bai}修改虛擬記憶體大小"
		echo -e "${gl_kjlan}13.  ${gl_bai}使用者管理                           ${gl_kjlan}14.  ${gl_bai}使用者/密碼產生器"
		echo -e "${gl_kjlan}15.  ${gl_bai}系統時區調整                       ${gl_kjlan}16.  ${gl_bai}設定BBR3加速"
		echo -e "${gl_kjlan}17.  ${gl_bai}防火牆進階管理器                   ${gl_kjlan}18.  ${gl_bai}修改主機名稱"
		echo -e "${gl_kjlan}19.  ${gl_bai}切換系統更新來源                     ${gl_kjlan}20.  ${gl_bai}定時任務管理"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}本機host解析                       ${gl_kjlan}22.  ${gl_bai}SSH防護程式"
		echo -e "${gl_kjlan}23.  ${gl_bai}限流自動關機                       ${gl_kjlan}24.  ${gl_bai}ROOT私鑰登入模式"
		echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot系統監控預警                 ${gl_kjlan}26.  ${gl_bai}修復OpenSSH高危漏洞（岫源）"
		echo -e "${gl_kjlan}27.  ${gl_bai}紅帽系Linux核心升級                ${gl_kjlan}28.  ${gl_bai}Linux系統核心參數優化 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}29.  ${gl_bai}病毒掃描工具 ${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}文件管理器"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}切換系統語言                       ${gl_kjlan}32.  ${gl_bai}命令列美化工具 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}設定系統資源回收筒                 ${gl_kjlan}34.  ${gl_bai}系統備份與還原"
		echo -e "${gl_kjlan}35.  ${gl_bai}ssh遠端連線工具                    ${gl_kjlan}36.  ${gl_bai}硬碟分割管理工具"
		echo -e "${gl_kjlan}37.  ${gl_bai}命令列歷史記錄                     ${gl_kjlan}38.  ${gl_bai}rsync遠端同步工具"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}留言板                             ${gl_kjlan}66.  ${gl_bai}一條龍系統調優 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}99.  ${gl_bai}重啟伺服器                         ${gl_kjlan}100. ${gl_bai}隱私與安全"
		echo -e "${gl_kjlan}101. ${gl_bai}k指令進階用法 ${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}解除安裝科技lion腳本"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			while true; do
				clear
				Ask "請輸入你的快捷按鍵（輸入0退出）: " kuaijiejian
				if [ "$kuaijiejian" == "0" ]; then
					break_end
					linux_Settings
				fi
				find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				echo "快捷鍵已設定"
				send_stats "脚本快捷键已设置"
				break_end
				linux_Settings
			done
			;;

		2)
			clear
			send_stats "设置你的登录密码"
			echo "設定您的登入密碼"
			passwd
			;;
		3)
			root_use
			send_stats "root密码模式"
			add_sshpasswd
			;;

		4)
			root_use
			send_stats "py版本管理"
			echo "python版本管理"
			echo "影片介紹: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "此功能可無縫安裝python官方支援的任何版本！"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "目前python版本號: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推薦版本:  3.12    3.11    3.10    3.9    3.8    2.7"
			echo "查詢更多版本: https://www.python.org/downloads/"
			echo "------------"
			Ask "輸入你要安裝的python版本號（輸入0退出）: " py_new_v

			if [[ $py_new_v == "0" ]]; then
				send_stats "脚本PY管理"
				break_end
				linux_Settings
			fi

			if ! grep -q 'export PYENV_ROOT="\$HOME/.pyenv"' ~/.bashrc; then
				if command -v yum &>/dev/null; then
					yum update -y && yum install git -y
					yum groupinstall "Development Tools" -y
					yum install openssl-devel bzip2-devel libffi-devel ncurses-devel zlib-devel readline-devel sqlite-devel xz-devel findutils -y

					curl -O https://www.openssl.org/source/openssl-1.1.1u.tar.gz
					tar -xzf openssl-1.1.1u.tar.gz
					cd openssl-1.1.1u
					./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
					make
					make install
					echo "/usr/local/openssl/lib" >/etc/ld.so.conf.d/openssl-1.1.1u.conf
					ldconfig -v
					cd ..

					export LDFLAGS="-L/usr/local/openssl/lib"
					export CPPFLAGS="-I/usr/local/openssl/include"
					export PKG_CONFIG_PATH="/usr/local/openssl/lib/pkgconfig"

				elif command -v apt &>/dev/null; then
					apt update -y && apt install git -y
					apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev -y
				elif command -v apk &>/dev/null; then
					apk update && apk add git
					apk add --no-cache bash gcc musl-dev libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev libc6-compat linux-headers make xz-dev build-base ncurses-dev
				else
					echo "未知的套件管理器！"
					return
				fi

				curl https://pyenv.run | bash
				NO_TRAN=$'\nexport PYENV_ROOT="$HOME/.pyenv"\nif [[ -d "$PYENV_ROOT/bin" ]]; then\n  export PATH="$PYENV_ROOT/bin:$PATH"\nfi\neval "$(pyenv init --path)"\neval "$(pyenv init -)"\neval "$(pyenv virtualenv-init -)"\n\n'
				echo -e "$NO_TRAN" >>~/.bashrc
			fi

			sleep 1
			source ~/.bashrc
			sleep 1
			pyenv install $py_new_v
			pyenv global $py_new_v

			rm -rf /tmp/python-build.*
			rm -rf $(pyenv root)/cache/*

			local VERSION=$(python -V 2>&1 | awk '{print $2}')
			echo -e "目前python版本號: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			;;

		5)
			root_use
			send_stats "开放端口"
			iptables_open
			remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
			echo "連接埠已全部開放"

			;;
		6)
			root_use
			send_stats "修改SSH端口"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 读取当前的 SSH 端口号
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 打印当前的 SSH 端口号
				echo -e "目前的 SSH 埠號是:  ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "連接埠號範圍1到65535之間的數字。（輸入0退出）"

				# 提示用户输入新的 SSH 端口号
				Ask "請輸入新的 SSH 端口號: " new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "連接埠號無效，請輸入1到65535之間的數字。"
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "輸入無效，請輸入數字。"
					send_stats "输入无效SSH端口"
					break_end
				fi
			done

			;;

		7)
			set_dns_ui
			;;

		8)

			dd_xitong
			;;
		9)
			root_use
			send_stats "新用户禁用root"
			Ask "請輸入新用戶名（輸入0退出）: " new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "操作已完成。"
			;;

		10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "設定v4/v6優先順序"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "目前網路優先級設定: ${gl_huang}IPv4${gl_bai} 優先"
				else
					echo -e "目前網路優先級設定: ${gl_huang}IPv6${gl_bai} 優先"
				fi
				echo
				echo "------------------------"
				echo "1. IPv4 優先          2. IPv6 優先          3. IPv6 修復工具"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "選擇優先的網絡: " choice

				case $choice in
				1)
					sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
					echo "已切換為 IPv4 優先"
					send_stats "已切换为 IPv4 优先"
					;;
				2)
					sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
					echo "已切換為 IPv6 優先"
					send_stats "已切换为 IPv6 优先"
					;;

				3)
					clear
					bash <(curl -L -s jhb.ovh/jb/v6.sh)
					echo "該功能由jhb大神提供，感謝他！"
					send_stats "ipv6修复"
					;;

				*)
					break
					;;

				esac
			done
			;;

		11)
			clear
			ss -tulnape
			;;

		12)
			root_use
			send_stats "设置虚拟内存"
			while true; do
				clear
				echo "設定虛擬記憶體"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "目前虛擬記憶體: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 分配1024M         2. 分配2048M         3. 分配4096M         4. 自訂大小"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " choice

				case "$choice" in
				1)
					send_stats "已设置1G虚拟内存"
					add_swap 1024

					;;
				2)
					send_stats "已设置2G虚拟内存"
					add_swap 2048

					;;
				3)
					send_stats "已设置4G虚拟内存"
					add_swap 4096

					;;

				4)
					Ask "請輸入虛擬記憶體大小（單位M）: " new_swap
					add_swap "$new_swap"
					send_stats "已设置自定义虚拟内存"
					;;

				*)
					break
					;;
				esac
			done
			;;

		13)
			while true; do
				root_use
				send_stats "用户管理"
				echo "使用者列表"
				echo "----------------------------------------------------------------------------"
				echo "使用者名稱                使用者權限                       使用者組            sudo權限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done </etc/passwd

				echo
				echo "帳戶操作"
				echo "------------------------"
				echo "1. 建立一般帳戶             2. 建立進階帳戶"
				echo "------------------------"
				echo "3. 賦予最高權限             4. 取消最高權限"
				echo "------------------------"
				echo "5. 刪除帳號"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " sub_choice

				case $sub_choice in
				1)
					# 提示用户输入新用户名
					Ask "請輸入新用戶名: " new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					echo "操作已完成。"
					;;

				2)
					# 提示用户输入新用户名
					Ask "請輸入新用戶名: " new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					# 赋予新用户sudo权限
					echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					echo "操作已完成。"

					;;
				3)
					Ask "請輸入用戶名: " username
					# 赋予新用户sudo权限
					echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
					;;
				4)
					Ask "請輸入用戶名: " username
					# 从sudoers文件中移除用户的sudo权限
					sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

					;;
				5)
					Ask "請輸入要刪除的用戶名: " username
					# 删除用户及其主目录
					userdel -r "$username"
					;;

				*)
					break
					;;
				esac
			done
			;;

		14)
			clear
			send_stats "用户信息生成器"
			echo "隨機使用者名稱"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(</dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "隨機使用者名稱 $i: $username"
			done

			echo
			echo "隨機姓名"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "隨機使用者姓名 $i: $user_name"
			done

			echo
			echo "隨機UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "隨機UUID $i: $uuid"
			done

			echo
			echo "16位隨機密碼"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "隨機密碼 $i: $password"
			done

			echo
			echo "32位隨機密碼"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "隨機密碼 $i: $password"
			done
			echo

			;;

		15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "系統時間資訊"

				# 显示时区和时间
				echo "目前系統時區：$(TimeZn)"
				echo "目前系統時間：$(date +"%Y-%m-%d %H:%M:%S")"

				echo
				echo "時區切換"
				echo "------------------------"
				echo "亞洲"
				echo "1.  中國上海時間             2.  中國香港時間"
				echo "3.  日本東京時間             4.  韓國首爾時間"
				echo "5.  新加坡時間               6.  印度加爾各答時間"
				echo "7.  阿聯酋杜拜時間           8.  澳洲雪梨時間"
				echo "9.  泰國曼谷時間"
				echo "------------------------"
				echo "歐洲"
				echo "11. 英國倫敦時間             12. 法國巴黎時間"
				echo "13. 德國柏林時間             14. 俄羅斯莫斯科時間"
				echo "15. 荷蘭烏特勒支時間       16. 西班牙馬德里時間"
				echo "------------------------"
				echo "美洲"
				echo "21. 美國西部時間             22. 美國東部時間"
				echo "23. 加拿大時間               24. 墨西哥時間"
				echo "25. 巴西時間                 26. 阿根廷時間"
				echo "------------------------"
				echo "31. UTC全球標準時間"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " sub_choice

				case $sub_choice in
				1) set_timedate Asia/Shanghai ;;
				2) set_timedate Asia/Hong_Kong ;;
				3) set_timedate Asia/Tokyo ;;
				4) set_timedate Asia/Seoul ;;
				5) set_timedate Asia/Singapore ;;
				6) set_timedate Asia/Kolkata ;;
				7) set_timedate Asia/Dubai ;;
				8) set_timedate Australia/Sydney ;;
				9) set_timedate Asia/Bangkok ;;
				11) set_timedate Europe/London ;;
				12) set_timedate Europe/Paris ;;
				13) set_timedate Europe/Berlin ;;
				14) set_timedate Europe/Moscow ;;
				15) set_timedate Europe/Amsterdam ;;
				16) set_timedate Europe/Madrid ;;
				21) set_timedate America/Los_Angeles ;;
				22) set_timedate America/New_York ;;
				23) set_timedate America/Vancouver ;;
				24) set_timedate America/Mexico_City ;;
				25) set_timedate America/Sao_Paulo ;;
				26) set_timedate America/Argentina/Buenos_Aires ;;
				31) set_timedate UTC ;;
				*) break ;;
				esac
			done
			;;

		16)

			bbrv3
			;;

		17)
			iptables_panel

			;;

		18)
			root_use
			send_stats "修改主机名"

			while true; do
				clear
				local current_hostname=$(uname -n)
				echo -e "目前主機名稱: ${gl_huang}$current_hostname${gl_bai}"
				echo "------------------------"
				Ask "請輸入新的主機名（輸入0退出）: " new_hostname
				if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
					if [ -f /etc/alpine-release ]; then
						# Alpine
						echo "$new_hostname" >/etc/hostname
						hostname "$new_hostname"
					else
						# 其他系统，如 Debian, Ubuntu, CentOS 等
						hostnamectl set-hostname "$new_hostname"
						sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
						systemctl restart systemd-hostnamed
					fi

					if grep -q "127.0.0.1" /etc/hosts; then
						sed -i "s/127.0.0.1 .*/127.0.0.1       $new_hostname localhost localhost.localdomain/g" /etc/hosts
					else
						echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >>/etc/hosts
					fi

					if grep -q "^::1" /etc/hosts; then
						sed -i "s/^::1 .*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
					else
						echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >>/etc/hosts
					fi

					echo "主機名稱已變更為: $new_hostname"
					send_stats "主机名已更改"
					sleep 1
				else
					echo "已退出，未變更主機名稱。"
					break
				fi
			done
			;;

		19)
			root_use
			send_stats "换系统更新源"
			clear
			echo "選擇更新來源區域"
			echo "接入LinuxMirrors切換系統更新源"
			echo "------------------------"
			echo "1. 中國大陸【預設】          2. 中國大陸【教育網】          3. 海外地區"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			Ask "請輸入您的選擇: " choice

			case $choice in
			1)
				send_stats "中国大陆默认源"
				bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				;;
			2)
				send_stats "中国大陆教育源"
				bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				;;
			3)
				send_stats "海外源"
				bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				;;
			*)
				echo "已取消"
				;;

			esac

			;;

		20)
			send_stats "定时任务管理"
			while true; do
				clear
				check_crontab_installed
				clear
				echo "定時任務列表"
				crontab -l
				echo
				echo "操作"
				echo "------------------------"
				echo "1. 添加定時任務              2. 刪除定時任務              3. 編輯定時任務"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " sub_choice

				case $sub_choice in
				1)
					Ask "請輸入新任務的執行命令: " newquest
					echo "------------------------"
					echo "1. 每月任務                 2. 每週任務"
					echo "3. 每天任務                 4. 每小時任務"
					echo "------------------------"
					Ask "請輸入您的選擇: " dingshi

					case $dingshi in
					1)
						Ask "選擇每月的幾號執行任務？ (1-30): " day
						(
							crontab -l
							echo "0 0 $day * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					2)
						Ask "選擇週幾執行任務？ (0-6，0代表星期日): " weekday
						(
							crontab -l
							echo "0 0 * * $weekday $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					3)
						Ask "選擇每天幾點執行任務？（小時，0-23）: " hour
						(
							crontab -l
							echo "0 $hour * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					4)
						Ask "輸入每小時的第幾分鐘執行任務？（分鐘，0-60）: " minute
						(
							crontab -l
							echo "$minute * * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					*)
						break
						;;
					esac
					send_stats "添加定时任务"
					;;
				2)
					Ask "請輸入需要刪除任務的關鍵字: " kquest
					crontab -l | grep -v "$kquest" | crontab -
					send_stats "删除定时任务"
					;;
				3)
					crontab -e
					send_stats "编辑定时任务"
					;;
				*)
					break
					;;
				esac
			done

			;;

		21)
			root_use
			send_stats "本地host解析"
			while true; do
				clear
				echo "本机host解析列表"
				echo "如果你在這裡添加解析匹配，將不再使用動態解析了"
				cat /etc/hosts
				echo
				echo "操作"
				echo "------------------------"
				echo "1. 添加新的解析              2. 刪除解析地址"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " host_dns

				case $host_dns in
				1)
					Ask "請輸入新的解析記錄 格式: 110.25.5.33 kejilion.pro : " addhost
					echo "$addhost" >>/etc/hosts
					send_stats "本地host解析新增"

					;;
				2)
					Ask "請輸入需要刪除的解析內容關鍵字: " delhost
					sed -i "/$delhost/d" /etc/hosts
					send_stats "本地host解析删除"
					;;
				*)
					break
					;;
				esac
			done
			;;

		22)
			root_use
			send_stats "ssh防御"
			while true; do
				if [ -x "$(command -v fail2ban-client)" ]; then
					clear
					remove fail2ban
					rm -rf /etc/fail2ban
				else
					clear
					docker_name="fail2ban"
					check_docker_app
					echo -e "SSH防護程式 $check_docker"
					echo "fail2ban是一個SSH防止暴力破解工具"
					echo "官網介紹: ${gh_proxy}github.com/fail2ban/fail2ban"
					echo "------------------------"
					echo "1. 安裝防禦程式"
					echo "------------------------"
					echo "2. 查看SSH攔截記錄"
					echo "3. 日誌即時監控"
					echo "------------------------"
					echo "9. 卸載防禦程式"
					echo "------------------------"
					echo "0. 返回上一級選單"
					echo "------------------------"
					Ask "請輸入您的選擇: " sub_choice
					case $sub_choice in
					1)
						install_docker
						f2b_install_sshd

						cd ~
						f2b_status
						break_end
						;;
					2)
						echo "------------------------"
						f2b_sshd
						echo "------------------------"
						break_end
						;;
					3)
						tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
						break
						;;
					9)
						docker rm -f fail2ban
						rm -rf /path/to/fail2ban
						echo "Fail2Ban防禦程式已卸載"
						;;
					*)
						break
						;;
					esac
				fi
			done
			;;

		23)
			root_use
			send_stats "限流关机功能"
			while true; do
				clear
				echo "限流關機功能"
				echo "影片介紹: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "當前流量使用情況，重啟伺服器流量計算會清零！"
				echo -e "${gl_kjlan}總接收: ${gl_bai}$(ConvSz $(Iface --rx_bytes))"
				echo -e "${gl_kjlan}總發送: ${gl_bai}$(ConvSz $(Iface --tx_bytes))"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}目前設定的進站限流閾值為: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}目前設定的出站限流閾值為: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}目前未啟用限流關機功能${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "系統每分鐘會偵測實際流量是否到達閾值，到達後會自動關閉伺服器！"
				echo "------------------------"
				echo "1. 啟用限流關機功能          2. 停用限流關機功能"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " Limiting

				case "$Limiting" in
				1)
					# 输入新的虚拟内存大小
					echo "如果實際伺服器就100G流量，可設定閾值為95G，提前關機，以免出現流量誤差或溢出。"
					Ask "請輸入進站流量閾值（單位為G，預設100G）: " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					Ask "請輸入出站流量閾值（單位為G，預設100G）: " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					Ask "請輸入流量重置日期（預設每月1日重置）: " cz_day
					cz_day=${cz_day:-1}

					cd ~
					curl -Ss -o ~/Limiting_Shut_down.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(
						crontab -l
						echo "* * * * * ~/Limiting_Shut_down.sh"
					) | crontab - >/dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(
						crontab -l
						echo "0 1 $cz_day * * reboot"
					) | crontab - >/dev/null 2>&1
					echo "限流關機已設定"
					send_stats "限流关机已设置"
					;;
				2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "已關閉限流關機功能"
					;;
				*)
					break
					;;
				esac
			done
			;;

		24)

			root_use
			send_stats "私钥登录"
			while true; do
				clear
				echo "ROOT私鑰登入模式"
				echo "影片介紹: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
				echo "------------------------------------------------"
				echo "將會生成金鑰對，更安全的方式SSH登入"
				echo "------------------------"
				echo "1. 生成新金鑰              2. 匯入已有金鑰              3. 查看本机金鑰"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				Ask "請輸入您的選擇: " host_dns

				case $host_dns in
				1)
					send_stats "生成新密钥"
					add_sshkey
					break_end

					;;
				2)
					send_stats "导入已有公钥"
					import_sshkey
					break_end

					;;
				3)
					send_stats "查看本机密钥"
					echo "------------------------"
					echo "公鑰資訊"
					cat ~/.ssh/authorized_keys
					echo "------------------------"
					echo "私鑰資訊"
					cat ~/.ssh/sshkey
					echo "------------------------"
					break_end

					;;
				*)
					break
					;;
				esac
			done

			;;

		25)
			root_use
			send_stats "电报预警"
			echo "TG-bot監控預警功能"
			echo "影片介紹: https://youtu.be/vLL-eb3Z_TY"
			echo "------------------------------------------------"
			echo "您需要配置tg機器人API和接收預警的使用者ID，即可實現本机CPU，記憶體，硬碟，流量，SSH登入的即時監控預警"
			echo "到達閾值後會向使用者發預警訊息"
			echo -e "${gl_hui}-關於流量，重啟伺服器將重新計算-${gl_bai}"
			Ask "確定繼續嗎？(y/N): " choice

			case "$choice" in
			[Yy])
				send_stats "电报预警启用"
				cd ~
				install nano tmux bc jq
				check_crontab_installed
				if [ -f ~/TG-check-notify.sh ]; then
					chmod +x ~/TG-check-notify.sh
					nano ~/TG-check-notify.sh
				else
					curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh
					chmod +x ~/TG-check-notify.sh
					nano ~/TG-check-notify.sh
				fi
				tmux kill-session -t TG-check-notify >/dev/null 2>&1
				tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				crontab -l | grep -v '~/TG-check-notify.sh' | crontab - >/dev/null 2>&1
				(
					crontab -l
					echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'"
				) | crontab - >/dev/null 2>&1

				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh >/dev/null 2>&1
				sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh >/dev/null 2>&1
				sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
				chmod +x ~/TG-SSH-check-notify.sh

				# 添加到 ~/.profile 文件中
				if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile >/dev/null 2>&1; then
					echo 'bash ~/TG-SSH-check-notify.sh' >>~/.profile
					if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						echo 'source ~/.profile' >>~/.bashrc
					fi
				fi

				source ~/.profile

				clear
				echo "TG-bot預警系統已啟動"
				echo -e "${gl_hui}您還可以將root目錄中的TG-check-notify.sh預警檔案放到其他機器上直接使用！${gl_bai}"
				;;
			[Nn])
				echo "已取消"
				;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;

		26)
			root_use
			send_stats "修复SSH高危漏洞"
			cd ~
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/upgrade_openssh9.8p1.sh
			chmod +x ~/upgrade_openssh9.8p1.sh
			~/upgrade_openssh9.8p1.sh
			rm -f ~/upgrade_openssh9.8p1.sh
			;;

		27)
			elrepo
			;;
		28)
			Kernel_optimize
			;;

		29)
			clamav
			;;

		30)
			linux_file
			;;

		31)
			linux_language
			;;

		32)
			shell_bianse
			;;
		33)
			linux_trash
			;;
		34)
			linux_backup
			;;
		35)
			ssh_manager
			;;
		36)
			disk_manager
			;;
		37)
			clear
			send_stats "命令行历史记录"
			get_history_file() {
				for file in "$HOME"/.bash_history "$HOME"/.ash_history "$HOME"/.zsh_history "$HOME"/.local/share/fish/fish_history; do
					[ -f "$file" ] && {
						echo "$file"
						return
					}
				done
				return 1
			}

			history_file=$(get_history_file) && cat -n "$history_file"
			;;

		38)
			rsync_manager
			;;

		41)
			clear
			send_stats "留言板"
			echo "科技lion留言板已遷移至官方社群！請在官方社群進行留言噢！"
			echo "https://bbs.kejilion.pro/"
			;;

		66)

			root_use
			send_stats "一条龙调优"
			echo "一條龍系統調優"
			echo "------------------------------------------------"
			echo "將對以下內容進行操作與優化"
			echo "1. 更新系統到最新"
			echo "2. 清理系統垃圾檔案"
			echo -e "3. 設定虛擬記憶體${gl_huang}1G${gl_bai}"
			echo -e "4. 設定SSH埠號為${gl_huang}5522${gl_bai}"
			echo -e "5. 開放所有埠"
			echo -e "6. 啟用${gl_huang}BBR${gl_bai}加速"
			echo -e "7. 設定時區到${gl_huang}上海${gl_bai}"
			echo -e "8. 自動優化DNS位址${gl_huang}海外: 1.1.1.1 8.8.8.8  國內: 223.5.5.5 ${gl_bai}"
			echo -e "9. 安裝基礎工具${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			echo -e "10. Linux系統核心參數優化切換到${gl_huang}均衡優化模式${gl_bai}"
			echo "------------------------------------------------"
			Ask "確定一鍵保養嗎？(y/N): " choice

			case "$choice" in
			[Yy])
				clear
				send_stats "一条龙调优启动"
				echo "------------------------------------------------"
				linux_update
				echo -e "[${gl_lv}OK${gl_bai}] 1/10. 更新系統到最新"

				echo "------------------------------------------------"
				linux_clean
				echo -e "[${gl_lv}OK${gl_bai}] 2/10. 清理系統垃圾檔案"

				echo "------------------------------------------------"
				add_swap 1024
				echo -e "[${gl_lv}OK${gl_bai}] 3/10. 設定虛擬記憶體${gl_huang}1G${gl_bai}"

				echo "------------------------------------------------"
				local new_port=5522
				new_ssh_port
				echo -e "[${gl_lv}OK${gl_bai}] 4/10. 設定SSH埠號為${gl_huang}5522${gl_bai}"
				echo "------------------------------------------------"
				echo -e "[${gl_lv}OK${gl_bai}] 5/10. 開放所有埠"

				echo "------------------------------------------------"
				bbr_on
				echo -e "[${gl_lv}OK${gl_bai}] 6/10. 啟用${gl_huang}BBR${gl_bai}加速"

				echo "------------------------------------------------"
				set_timedate Asia/Shanghai
				echo -e "[${gl_lv}OK${gl_bai}] 7/10. 設定時區到${gl_huang}上海${gl_bai}"

				echo "------------------------------------------------"
				local country=$(curl -s ipinfo.io/country)
				if [ "$country" = "CN" ]; then
					local dns1_ipv4="223.5.5.5"
					local dns2_ipv4="183.60.83.19"
					local dns1_ipv6="2400:3200::1"
					local dns2_ipv6="2400:da00::6666"
				else
					local dns1_ipv4="1.1.1.1"
					local dns2_ipv4="8.8.8.8"
					local dns1_ipv6="2606:4700:4700::1111"
					local dns2_ipv6="2001:4860:4860::8888"
				fi

				set_dns
				echo -e "[${gl_lv}OK${gl_bai}] 8/10. 自動優化DNS位址${gl_huang}${gl_bai}"

				echo "------------------------------------------------"
				install_docker
				install wget sudo tar unzip socat btop nano vim
				echo -e "[${gl_lv}OK${gl_bai}] 9/10. 安裝基礎工具${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				echo "------------------------------------------------"

				echo "------------------------------------------------"
				optimize_balanced
				echo -e "[${gl_lv}OK${gl_bai}] 10/10. Linux系統核心參數優化"
				echo -e "${gl_lv}一條龍系統調優已完成${gl_bai}"

				;;
			[Nn])
				echo "已取消"
				;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac

			;;

		99)
			clear
			send_stats "重启系统"
			server_reboot
			;;
		100)

			root_use
			while true; do
				clear
				if grep -q '^ENABLE_STATS="true"' /usr/local/bin/k >/dev/null 2>&1; then
					local status_message="${gl_lv}正在采集数据${gl_bai}"
				elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k >/dev/null 2>&1; then
					local status_message="${gl_hui}采集已关闭${gl_bai}"
				else
					local status_message="无法确定的状态"
				fi

				echo "隱私與安全"
				echo "腳本將收集使用者使用功能數據，優化腳本體驗，製作更多好玩好用的功能"
				echo "將收集腳本版本號，使用時間，系統版本，CPU架構，機器所屬國家和使用的功能名稱，"
				echo "------------------------------------------------"
				echo -e "目前狀態: $status_message"
				echo "--------------------"
				echo "1. 啟用採集"
				echo "2. 關閉採集"
				echo "--------------------"
				echo "0. 返回上一級選單"
				echo "--------------------"
				Ask "請輸入您的選擇: " sub_choice
				case $sub_choice in
				1)
					cd ~
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					echo "已啟用採集"
					send_stats "隐私与安全已开启采集"
					;;
				2)
					cd ~
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					echo "已關閉採集"
					send_stats "隐私与安全已关闭采集"
					;;
				*)
					break
					;;
				esac
			done
			;;

		101)
			clear
			k_info
			;;

		102)
			clear
			send_stats "卸载科技lion脚本"
			echo "卸載科技lion腳本"
			echo "------------------------------------------------"
			echo "將徹底卸載kejilion腳本，不影響你其他功能"
			Ask "確定繼續嗎？(y/N): " choice

			case "$choice" in
			[Yy])
				clear
				(crontab -l | grep -v "kejilion.sh") | crontab -
				rm -f /usr/local/bin/k
				rm ~/kejilion.sh
				echo "腳本已卸載，再見！"
				break_end
				clear
				exit
				;;
			[Nn])
				echo "已取消"
				;;
			*)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;

		0)
			kejilion

			;;
		*)
			echo "無效的輸入!"
			;;
		esac
		break_end

	done

}

linux_file() {
	root_use
	send_stats "文件管理器"
	while true; do
		clear
		echo "檔案管理器"
		echo "------------------------"
		echo "當前路徑"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1.  進入目錄           2.  建立目錄             3.  修改目錄權限         4.  重新命名目錄"
		echo "5.  刪除目錄           6.  返回上一級選單目錄"
		echo "------------------------"
		echo "11. 建立檔案           12. 編輯檔案             13. 修改檔案權限         14. 重新命名檔案"
		echo "15. 刪除檔案"
		echo "------------------------"
		echo "21. 壓縮檔案目錄       22. 解壓縮檔案目錄         23. 移動檔案目錄         24. 複製檔案目錄"
		echo "25. 傳送檔案至其他伺服器"
		echo "------------------------"
		echo "0.  返回上一級選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " Limiting

		case "$Limiting" in
		1)
			# 进入目录
			Ask "請輸入目錄名: " dirname
			cd "$dirname" 2>/dev/null || echo "無法進入目錄"
			send_stats "进入目录"
			;;
		2)
			# 创建目录
			Ask "請輸入要創建的目錄名: " dirname
			mkdir -p "$dirname" && echo "目錄已建立" || echo "建立失敗"
			send_stats "创建目录"
			;;
		3)
			# 修改目录权限
			Ask "請輸入目錄名: " dirname
			Ask "請輸入權限 (如 755): " perm
			chmod "$perm" "$dirname" && echo "權限已修改" || echo "修改失敗"
			send_stats "修改目录权限"
			;;
		4)
			# 重命名目录
			Ask "請輸入目前目錄名: " current_name
			Ask "請輸入新目錄名: " new_name
			mv "$current_name" "$new_name" && echo "目錄已重新命名" || echo "重新命名失敗"
			send_stats "重命名目录"
			;;
		5)
			# 删除目录
			Ask "請輸入要刪除的目錄名: " dirname
			rm -rf "$dirname" && echo "目錄已刪除" || echo "刪除失敗"
			send_stats "删除目录"
			;;
		6)
			# 返回上一级选单目录
			cd ..
			send_stats "返回上一级选单目录"
			;;
		11)
			# 创建文件
			Ask "請輸入要創建的檔名: " filename
			touch "$filename" && echo "檔案已建立" || echo "建立失敗"
			send_stats "创建文件"
			;;
		12)
			# 编辑文件
			Ask "請輸入要編輯的檔名: " filename
			install nano
			nano "$filename"
			send_stats "编辑文件"
			;;
		13)
			# 修改文件权限
			Ask "請輸入檔名: " filename
			Ask "請輸入權限 (如 755): " perm
			chmod "$perm" "$filename" && echo "權限已修改" || echo "修改失敗"
			send_stats "修改文件权限"
			;;
		14)
			# 重命名文件
			Ask "請輸入目前檔名: " current_name
			Ask "請輸入新檔名: " new_name
			mv "$current_name" "$new_name" && echo "檔案已重新命名" || echo "重新命名失敗"
			send_stats "重命名文件"
			;;
		15)
			# 删除文件
			Ask "請輸入要刪除的檔名: " filename
			rm -f "$filename" && echo "檔案已刪除" || echo "刪除失敗"
			send_stats "删除文件"
			;;
		21)
			# 压缩文件/目录
			Ask "請輸入要壓縮的檔案/目錄名: " name
			install tar
			tar -czvf "$name.tar.gz" "$name" && echo "已壓縮為 $name.tar.gz" || echo "壓縮失敗"
			send_stats "压缩文件/目录"
			;;
		22)
			# 解压文件/目录
			Ask "請輸入要解壓縮的檔名 (.tar.gz): " filename
			install tar
			tar -xzvf "$filename" && echo "已解壓縮 $filename" || echo "解壓縮失敗"
			send_stats "解压文件/目录"
			;;

		23)
			# 移动文件或目录
			Ask "請輸入要移動的檔案或目錄路徑: " src_path
			if [ ! -e "$src_path" ]; then
				echo "錯誤: 檔案或目錄不存在。"
				send_stats "移动文件或目录失败: 文件或目录不存在"
				continue
			fi

			Ask "請輸入目標路徑 (包括新檔名或目錄名): " dest_path
			if [ -z "$dest_path" ]; then
				echo "錯誤: 請輸入目標路徑。"
				send_stats "移动文件或目录失败: 目标路径未指定"
				continue
			fi

			mv "$src_path" "$dest_path" && echo "檔案或目錄已移動到 $dest_path" || echo "移動檔案或目錄失敗"
			send_stats "移动文件或目录"
			;;

		24)
			# 复制文件目录
			Ask "請輸入要複製的檔案或目錄路徑: " src_path
			if [ ! -e "$src_path" ]; then
				echo "錯誤: 檔案或目錄不存在。"
				send_stats "复制文件或目录失败: 文件或目录不存在"
				continue
			fi

			Ask "請輸入目標路徑 (包括新檔名或目錄名): " dest_path
			if [ -z "$dest_path" ]; then
				echo "錯誤: 請輸入目標路徑。"
				send_stats "复制文件或目录失败: 目标路径未指定"
				continue
			fi

			# 使用 -r 选项以递归方式复制目录
			cp -r "$src_path" "$dest_path" && echo "檔案或目錄已複製到 $dest_path" || echo "複製檔案或目錄失敗"
			send_stats "复制文件或目录"
			;;

		25)
			# 传送文件至远端服务器
			Ask "請輸入要傳送的檔案路徑: " file_to_transfer
			if [ ! -f "$file_to_transfer" ]; then
				echo "錯誤: 檔案不存在。"
				send_stats "传送文件失败: 文件不存在"
				continue
			fi

			Ask "請輸入遠端伺服器IP: " remote_ip
			if [ -z "$remote_ip" ]; then
				echo "錯誤: 請輸入遠端伺服器IP。"
				send_stats "传送文件失败: 未输入远端服务器IP"
				continue
			fi

			Ask "請輸入遠端伺服器使用者名稱 (預設root): " remote_user
			remote_user=${remote_user:-root}

			Ask "請輸入遠端伺服器密碼: " -s remote_password
			echo
			if [ -z "$remote_password" ]; then
				echo "錯誤: 請輸入遠端伺服器密碼。"
				send_stats "传送文件失败: 未输入远端服务器密码"
				continue
			fi

			Ask "請輸入登入埠 (預設22): " remote_port
			remote_port=${remote_port:-22}

			# 清除已知主机的旧条目
			ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			sleep 2 # 等待时间

			# 使用scp传输文件
			NO_TRAN=$'echo "$remote_password" | scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/"'
			eval "$NO_TRAN"

			if [ $? -eq 0 ]; then
				echo "檔案已傳送至遠端伺服器home目錄。"
				send_stats "文件传送成功"
			else
				echo "檔案傳送失敗。"
				send_stats "文件传送失败"
			fi

			break_end
			;;

		0)
			# 返回上一级选单
			send_stats "返回上一级选单菜单"
			break
			;;
		*)
			# 处理无效输入
			echo "無效的選擇，請重新輸入"
			send_stats "无效选择"
			;;
		esac
	done
}

cluster_python3() {
	install python3 python3-paramiko
	cd ~/cluster/
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}

run_commands_on_servers() {

	install sshpass

	local SERVERS_FILE="$HOME/cluster/servers.py"
	local SERVERS=$(grep -oP '{"name": "\K[^"]+|"hostname": "\K[^"]+|"port": \K[^,]+|"username": "\K[^"]+|"password": "\K[^"]+' "$SERVERS_FILE")

	# 将提取的信息转换为数组
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<<"$SERVERS"

	# 遍历服务器并执行命令
	for ((i = 0; i < ${#SERVER_ARRAY[@]}; i += 5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i + 1]}
		local port=${SERVER_ARRAY[i + 2]}
		local username=${SERVER_ARRAY[i + 3]}
		local password=${SERVER_ARRAY[i + 4]}
		echo
		echo -e "${gl_huang}連線到 $name ($hostname)...${gl_bai}"
		# sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
		sshpass -p "$password" ssh -t -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
	done
	echo
	break_end

}

linux_cluster() {
	mkdir cluster
	if [ ! -f ~/cluster/servers.py ]; then
		NO_TRAN=$'servers = [\n\n]\n'
		echo -e "$NO_TRAN" >~/cluster/servers.py
	fi

	while true; do
		clear
		send_stats "集群控制中心"
		echo "伺服器叢集控制"
		cat ~/cluster/servers.py
		echo
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}伺服器列表管理${gl_bai}"
		echo -e "${gl_kjlan}1.  ${gl_bai}添加伺服器               ${gl_kjlan}2.  ${gl_bai}刪除伺服器            ${gl_kjlan}3.  ${gl_bai}編輯伺服器"
		echo -e "${gl_kjlan}4.  ${gl_bai}備份叢集                 ${gl_kjlan}5.  ${gl_bai}還原叢集"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}批次執行任務${gl_bai}"
		echo -e "${gl_kjlan}11. ${gl_bai}安裝科技lion腳本         ${gl_kjlan}12. ${gl_bai}更新系統              ${gl_kjlan}13. ${gl_bai}清理系統"
		echo -e "${gl_kjlan}14. ${gl_bai}安裝docker               ${gl_kjlan}15. ${gl_bai}安裝BBR3              ${gl_kjlan}16. ${gl_bai}設定1G虛擬記憶體"
		echo -e "${gl_kjlan}17. ${gl_bai}設定時區到上海           ${gl_kjlan}18. ${gl_bai}開放所有埠\t       ${gl_kjlan}51. ${gl_bai}自訂指令"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.  ${gl_bai}返回主選單"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " sub_choice

		case $sub_choice in
		1)
			send_stats "添加集群服务器"
			Ask "伺服器名稱: " server_name
			Ask "伺服器IP: " server_ip
			Ask "伺服器埠（22）: " server_port
			local server_port=${server_port:-22}
			Ask "伺服器使用者名稱（root）: " server_username
			local server_username=${server_username:-root}
			Ask "伺服器使用者密碼: " server_password

			sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			;;
		2)
			send_stats "删除集群服务器"
			Ask "請輸入需要刪除的關鍵字: " rmserver
			sed -i "/$rmserver/d" ~/cluster/servers.py
			;;
		3)
			send_stats "编辑集群服务器"
			install nano
			nano ~/cluster/servers.py
			;;

		4)
			clear
			send_stats "备份集群"
			echo -e "請將 ${gl_huang}/root/cluster/servers.py${gl_bai} 檔案下載，完成備份！"
			break_end
			;;

		5)
			clear
			send_stats "还原集群"
			echo "請上傳您的servers.py，按任意鍵開始上傳！"
			echo -e "請上傳您的 ${gl_huang}servers.py${gl_bai} 檔案到 ${gl_huang}/root/cluster/${gl_bai} 完成還原！"
			break_end
			;;

		11)
			local py_task="install_kejilion.py"
			cluster_python3
			;;
		12)
			run_commands_on_servers "k update"
			;;
		13)
			run_commands_on_servers "k clean"
			;;
		14)
			run_commands_on_servers "k docker install"
			;;
		15)
			run_commands_on_servers "k bbr3"
			;;
		16)
			run_commands_on_servers "k swap 1024"
			;;
		17)
			run_commands_on_servers "k time Asia/Shanghai"
			;;
		18)
			run_commands_on_servers "k iptables_open"
			;;

		51)
			send_stats "自定义执行命令"
			Ask "請輸入批次執行的命令: " mingling
			run_commands_on_servers "${mingling}"
			;;

		*)
			kejilion
			;;
		esac
	done

}

kejilion_Affiliates() {

	clear
	send_stats "广告专栏"
	echo "廣告專欄"
	echo "------------------------"
	echo "將為使用者提供更簡單優雅的推廣與購買體驗！"
	echo
	echo -e "伺服器優惠"
	echo "------------------------"
	echo -e "${gl_lan}萊卡雲 香港CN2 GIA 韓國雙ISP 美國CN2 GIA 優惠活動${gl_bai}"
	echo -e "${gl_bai}網址: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}RackNerd 每年 10.99 美元 美國 1 核心 1G 記憶體 20G 硬碟 1T 月流量${gl_bai}"
	echo -e "${gl_bai}網址: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}Hostinger 每年 52.7 美元 美國 1 核心 4G 記憶體 50G 硬碟 4T 月流量${gl_bai}"
	echo -e "${gl_bai}網址: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
	echo "------------------------"
	echo -e "${gl_huang}搬瓦工 每季 49 美元 美國 CN2GIA 日本軟銀 2 核心 1G 記憶體 20G 硬碟 1T 月流量${gl_bai}"
	echo -e "${gl_bai}網址: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}DMIT 每季 28 美元 美國 CN2GIA 1 核心 2G 記憶體 20G 硬碟 800G 月流量${gl_bai}"
	echo -e "${gl_bai}網址: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}V.PS 每月 6.9 美元 東京軟銀 2 核心 1G 記憶體 20G 硬碟 1T 月流量${gl_bai}"
	echo -e "${gl_bai}網址: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}更多熱門 VPS 優惠${gl_bai}"
	echo -e "${gl_bai}網址: https://kejilion.pro/topvps/${gl_bai}"
	echo "------------------------"
	echo
	echo -e "域名優惠"
	echo "------------------------"
	echo -e "${gl_lan}GNAME 首年 COM 域名 8.8 美元 首年 CC 域名 6.68 美元${gl_bai}"
	echo -e "${gl_bai}網址: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
	echo "------------------------"
	echo
	echo -e "科技lion 周邊"
	echo "------------------------"
	echo -e "${gl_kjlan}B 站: ${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}油管: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
	echo -e "${gl_kjlan}官網: ${gl_bai}https://kejilion.pro/              ${gl_kjlan}導航: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
	echo -e "${gl_kjlan}部落格: ${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}軟體中心: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}腳本官網: ${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub 地址: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
	echo "------------------------"
	echo
}

kejilion_update() {

	send_stats "脚本更新"
	cd ~
	while true; do
		clear
		echo "更新日誌"
		echo "------------------------"
		echo "全部日誌: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
		echo "------------------------"

		curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
		local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

		if [ "$sh_v" = "$sh_v_new" ]; then
			echo -e "${gl_lv}您已是最新版本！${gl_huang}v$sh_v${gl_bai}"
			send_stats "脚本已经最新了，无需更新"
		else
			echo "發現新版本！"
			echo -e "目前版本 v$sh_v        最新版本 ${gl_huang}v$sh_v_new${gl_bai}"
		fi

		local cron_job="kejilion.sh"
		local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

		if [ -n "$existing_cron" ]; then
			echo "------------------------"
			echo -e "${gl_lv}自動更新已開啟，每天凌晨 2 點腳本會自動更新！${gl_bai}"
		fi

		echo "------------------------"
		echo "1. 現在更新            2. 啟用自動更新            3. 關閉自動更新"
		echo "------------------------"
		echo "0. 返回主選單"
		echo "------------------------"
		Ask "請輸入您的選擇: " choice
		case "$choice" in
		1)
			clear
			local country=$(curl -s ipinfo.io/country)
			if [ "$country" = "CN" ]; then
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/cn/kejilion.sh && chmod +x kejilion.sh
			else
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh
			fi
			canshu_v6
			CheckFirstRun_true
			yinsiyuanquan2
			cp -f ~/kejilion.sh /usr/local/bin/k >/dev/null 2>&1
			echo -e "${gl_lv}腳本已更新至最新版本！${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "脚本已经最新$sh_v_new"
			break_end
			~/kejilion.sh
			exit
			;;
		2)
			clear
			local country=$(curl -s ipinfo.io/country)
			local ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
			if [ "$country" = "CN" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"CN\"/g' ./kejilion.sh"
			elif [ -n "$ipv6_address" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"V6\"/g' ./kejilion.sh"
			else
				SH_Update_task="curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh"
			fi
			check_crontab_installed
			(crontab -l | grep -v "kejilion.sh") | crontab -
			# (crontab -l 2>/dev/null; echo "0 2 * * * bash -c \\"$SH_Update_task\"") | crontab -
			(
				crontab -l 2>/dev/null
				NO_TRAN="$(shuf -i 0-59 -n 1) 2 * * * bash -c \"\$SH_Update_task\""
				echo "$NO_TRAN"
			) | crontab -
			echo -e "${gl_lv}自動更新已開啟，每天凌晨 2 點腳本會自動更新！${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}自動更新已關閉${gl_bai}"
			send_stats "关闭脚本自动更新"
			break_end
			;;
		*)
			kejilion_sh
			;;
		esac
	done

}

kejilion_sh() {
	while true; do
		clear
		echo -e "${gl_kjlan}"
		echo "╦╔═╔═╗ ╦╦╦  ╦╔═╗╔╗╔ ╔═╗╦ ╦"
		echo "╠╩╗║╣  ║║║  ║║ ║║║║ ╚═╗╠═╣"
		echo "╩ ╩╚═╝╚╝╩╩═╝╩╚═╝╝╚╝o╚═╝╩ ╩"
		echo -e "科技lion 腳本工具箱 v$sh_v"
		echo -e "命令行輸入${gl_huang}k${gl_kjlan}可快速啟動腳本${gl_bai}"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}1.   ${gl_bai}系統資訊查詢"
		echo -e "${gl_kjlan}2.   ${gl_bai}系統更新"
		echo -e "${gl_kjlan}3.   ${gl_bai}系統清理"
		echo -e "${gl_kjlan}4.   ${gl_bai}基礎工具"
		echo -e "${gl_kjlan}5.   ${gl_bai}BBR 管理"
		echo -e "${gl_kjlan}6.   ${gl_bai}Docker 管理"
		echo -e "${gl_kjlan}7.   ${gl_bai}WARP 管理"
		echo -e "${gl_kjlan}8.   ${gl_bai}測試腳本合集"
		echo -e "${gl_kjlan}9.   ${gl_bai}甲骨文雲腳本合集"
		echo -e "${gl_huang}10.  ${gl_bai}LDNMP 建站"
		echo -e "${gl_kjlan}11.  ${gl_bai}應用市場"
		echo -e "${gl_kjlan}12.  ${gl_bai}後台工作區"
		echo -e "${gl_kjlan}13.  ${gl_bai}系統工具"
		echo -e "${gl_kjlan}14.  ${gl_bai}伺服器叢集控制"
		echo -e "${gl_kjlan}15.  ${gl_bai}廣告專欄"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}p.   ${gl_bai}幻獸帕魯開服腳本"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}00.  ${gl_bai}腳本更新"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.   ${gl_bai}退出腳本"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "請輸入您的選擇: " choice

		case $choice in
		1) linux_ps ;;
		2)
			clear
			send_stats "系统更新"
			linux_update
			;;
		3)
			clear
			send_stats "系统清理"
			linux_clean
			;;
		4) linux_tools ;;
		5) linux_bbr ;;
		6) linux_docker ;;
		7)
			clear
			send_stats "warp管理"
			install wget
			wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh
			bash menu.sh [option] [lisence/url/token]
			;;
		8) linux_test ;;
		9) linux_Oracle ;;
		10) linux_ldnmp ;;
		11) linux_panel ;;
		12) linux_work ;;
		13) linux_Settings ;;
		14) linux_cluster ;;
		15) kejilion_Affiliates ;;
		p)
			send_stats "幻兽帕鲁开服脚本"
			cd ~
			curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh
			chmod +x palworld.sh
			./palworld.sh
			exit
			;;
		00) kejilion_update ;;
		0)
			clear
			exit
			;;
		*) echo "無效的輸入!" ;;
		esac
		break_end
	done
}

k_info() {
	send_stats "k命令参考用例"
	echo "-------------------"
	echo "影片介紹: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
	echo "以下是k命令參考用例："
	echo "啟動腳本            k"
	echo "安裝套件          k install nano wget | k add nano wget | k 安裝 nano wget"
	echo "卸載套件          k remove nano wget | k del nano wget | k uninstall nano wget | k 卸載 nano wget"
	echo "更新系統            k update | k 更新"
	echo "清理系統垃圾        k clean | k 清理"
	echo "重裝系統面板        k dd | k 重裝"
	echo "bbr3控制面板        k bbr3 | k bbrv3"
	echo "核心調優面板        k nhyh | k 核心優化"
	echo "設定虛擬記憶體        k swap 2048"
	echo "設定虛擬時區        k time Asia/Shanghai | k 時區 Asia/Shanghai"
	echo "系統回收站          k trash | k hsz | k 回收站"
	echo "系統備份功能        k backup | k bf | k 備份"
	echo "ssh遠端連接工具     k ssh | k 遠端連接"
	echo "rsync遠端同步工具   k rsync | k 遠端同步"
	echo "硬碟管理工具        k disk | k 硬碟管理"
	echo "內網穿透（伺服器端）  k frps"
	echo "內網穿透（客戶端）  k frpc"
	echo "軟體啟動            k start sshd | k 啟動 sshd "
	echo "軟體停止            k stop sshd | k 停止 sshd "
	echo "軟體重啟            k restart sshd | k 重啟 sshd "
	echo "軟體狀態查看        k status sshd | k 狀態 sshd "
	echo "軟體開機啟動        k enable docker | k autostart docke | k 開機啟動 docker "
	echo "域名憑證申請        k ssl"
	echo "域名憑證到期查詢    k ssl ps"
	echo "docker環境安裝      k docker install |k docker 安裝"
	echo "docker容器管理      k docker ps |k docker 容器"
	echo "docker鏡像管理      k docker img |k docker 鏡像"
	echo "LDNMP網站管理       k web"
	echo "LDNMP快取清理       k web cache"
	echo "安裝WordPress       k wp |k wordpress |k wp xxx.com"
	echo "安裝反向代理        k fd |k rp |k 反代 |k fd xxx.com"
	echo "安裝負載均衡        k loadbalance |k 負載均衡"
	echo "防火牆面板          k fhq |k 防火牆"
	echo "開放端口            k dkdk 8080 |k 打開端口 8080"
	echo "關閉端口            k gbdk 7800 |k 關閉端口 7800"
	echo "放行IP              k fxip 127.0.0.0/8 |k 放行IP 127.0.0.0/8"
	echo "阻止IP              k zzip 177.5.25.36 |k 阻止IP 177.5.25.36"
}

if [ "$#" -eq 0 ]; then
	# 如果没有参数，运行交互式逻辑
	kejilion_sh
else
	# 如果有参数，执行相应函数
	case $1 in
	install | add | 安装)
		shift
		send_stats "安装软件"
		install "$@"
		;;
	remove | del | uninstall | 卸载)
		shift
		send_stats "卸载软件"
		remove "$@"
		;;
	update | 更新)
		linux_update
		;;
	clean | 清理)
		linux_clean
		;;
	dd | 重装)
		dd_xitong
		;;
	bbr3 | bbrv3)
		bbrv3
		;;
	nhyh | 内核优化)
		Kernel_optimize
		;;
	trash | hsz | 回收站)
		linux_trash
		;;
	backup | bf | 备份)
		linux_backup
		;;
	ssh | 远程连接)
		ssh_manager
		;;

	rsync | 远程同步)
		rsync_manager
		;;

	rsync_run)
		shift
		send_stats "定时rsync同步"
		run_task "$@"
		;;

	disk | 硬盘管理)
		disk_manager
		;;

	wp | wordpress)
		shift
		ldnmp_wp "$@"

		;;
	fd | rp | 反代)
		shift
		ldnmp_Proxy "$@"
		;;

	loadbalance | 负载均衡)
		ldnmp_Proxy_backend
		;;

	swap)
		shift
		send_stats "快速设置虚拟内存"
		add_swap "$@"
		;;

	time | 时区)
		shift
		send_stats "快速设置时区"
		set_timedate "$@"
		;;

	iptables_open)
		iptables_open
		;;

	frps)
		frps_panel
		;;

	frpc)
		frpc_panel
		;;

	打开端口 | dkdk)
		shift
		open_port "$@"
		;;

	关闭端口 | gbdk)
		shift
		close_port "$@"
		;;

	放行IP | fxip)
		shift
		allow_ip "$@"
		;;

	阻止IP | zzip)
		shift
		block_ip "$@"
		;;

	防火墙 | fhq)
		iptables_panel
		;;

	status | 状态)
		shift
		send_stats "软件状态查看"
		status "$@"
		;;
	start | 启动)
		shift
		send_stats "软件启动"
		start "$@"
		;;
	stop | 停止)
		shift
		send_stats "软件暂停"
		stop "$@"
		;;
	restart | 重启)
		shift
		send_stats "软件重启"
		restart "$@"
		;;

	enable | autostart | 开机启动)
		shift
		send_stats "软件开机自启"
		enable "$@"
		;;

	ssl)
		shift
		if [ "$1" = "ps" ]; then
			send_stats "查看证书状态"
			ssl_ps
		elif [ -z "$1" ]; then
			add_ssl
			send_stats "快速申请证书"
		elif [ -n "$1" ]; then
			add_ssl "$1"
			send_stats "快速申请证书"
		else
			k_info
		fi
		;;

	docker)
		shift
		case $1 in
		install | 安装)
			send_stats "快捷安装docker"
			install_docker
			;;
		ps | 容器)
			send_stats "快捷容器管理"
			docker_ps
			;;
		img | 镜像)
			send_stats "快捷镜像管理"
			docker_image
			;;
		*)
			k_info
			;;
		esac
		;;

	web)
		shift
		if [ "$1" = "cache" ]; then
			web_cache
		elif [ "$1" = "sec" ]; then
			web_security
		elif [ "$1" = "opt" ]; then
			web_optimization
		elif [ -z "$1" ]; then
			ldnmp_web_status
		else
			k_info
		fi
		;;

	*)
		k_info
		;;
	esac
fi
