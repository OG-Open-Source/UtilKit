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
	echo -e "${gl_kjlan}欢迎使用科技lion脚本工具箱${gl_bai}"
	echo "スクリプトを初めて使用する場合は、まずユーザーライセンス契約をお読みになり、同意してください。"
	echo "ユーザーライセンス契約: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	Ask "Do you agree to the above terms? (y/N): " user_input

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
		echo "パッケージパラメータが提供されていません！"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}正在安装 $package...${gl_bai}"
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
				echo "不明なパッケージマネージャー！"
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
		echo -e "${gl_huang}提示: ${gl_bai}磁盘空间不足！"
		echo "現在利用可能なスペース: $((available_space_mb / 1024))G"
		echo "最小必要スペース: ${required_gb}G"
		echo "インストールを続行できません。ディスクスペースをクリーンアップしてから再試行してください。"
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
		echo "パッケージパラメータが提供されていません！"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}正在卸载 $package...${gl_bai}"
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
			echo "不明なパッケージマネージャー！"
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
		echo "$1 サービスを再起動しました。"
	else
		echo "エラー: $1 サービスの再起動に失敗しました。"
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスを開始しました。"
	else
		echo "エラー: $1 サービスの開始に失敗しました。"
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスを停止しました。"
	else
		echo "エラー: $1 サービスの停止に失敗しました。"
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 サービスのステータスを表示しました。"
	else
		echo "エラー: $1 サービスのステータスを表示できません。"
	fi
}

enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
		/bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME が起動時に自動実行されるように設定されました。"
}

break_end() {
	echo -e "${gl_lv}操作完成${gl_bai}"
	Press "Press any key to continue..."
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
	echo -e "${gl_huang}正在安装docker环境...${gl_bai}"
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
		echo "Dockerコンテナ一覧"
		docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
		echo
		echo "コンテナ操作"
		echo "------------------------"
		echo "1. 新規コンテナの作成"
		echo "------------------------"
		echo "2. 指定コンテナの起動             6. 全コンテナの起動"
		echo "3. 指定コンテナの停止             7. 全コンテナの停止"
		echo "4. 指定コンテナの削除             8. 全コンテナの削除"
		echo "5. 指定コンテナの再起動           9. 全コンテナの再起動"
		echo "------------------------"
		echo "11. 指定コンテナに入る           12. コンテナログの表示"
		echo "13. コンテナネットワークの表示     14. コンテナ使用量の表示"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " sub_choice
		case $sub_choice in
		1)
			send_stats "新建容器"
			Ask "Please enter the creation command: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			Ask "Please enter container names (separate multiple container names with spaces): " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			Ask "Please enter container names (separate multiple container names with spaces): " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			Ask "Please enter container names (separate multiple container names with spaces): " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			Ask "Please enter container names (separate multiple container names with spaces): " dockername
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
			Ask "${gl_hong}Note: ${gl_bai}Are you sure you want to delete all containers? (y/N): " choice
			case "$choice" in
			[Yy])
				docker rm -f $(docker ps -a -q)
				;;
			[Nn]) ;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			Ask "Please enter container name: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			Ask "Please enter container name: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器网络"
			echo
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			echo "コンテナ名              ネットワーク名              IPアドレス"
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
		echo "Dockerイメージ一覧"
		docker image ls
		echo
		echo "イメージ操作"
		echo "------------------------"
		echo "1. 指定イメージの取得             3. 指定イメージの削除"
		echo "2. 指定イメージの更新             4. 全イメージの削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " sub_choice
		case $sub_choice in
		1)
			send_stats "拉取镜像"
			Ask "Please enter image names (separate multiple image names with spaces): " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在获取镜像: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			Ask "Please enter image names (separate multiple image names with spaces): " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在更新镜像: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			Ask "Please enter image names (separate multiple image names with spaces): " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			Ask "${gl_hong}Note: ${gl_bai}Are you sure you want to delete all images? (y/N): " choice
			case "$choice" in
			[Yy])
				docker rmi -f $(docker images -q)
				;;
			[Nn]) ;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
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
			echo "サポートされていないディストリビューション: $ID"
			return
			;;
		esac
	else
		echo "オペレーティングシステムを特定できません。"
		return
	fi

	echo -e "${gl_lv}crontab 已安装且 cron 服务正在运行。${gl_bai}"
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
			echo -e "${gl_huang}当前已开启ipv6访问${gl_bai}"
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
		echo -e "${gl_hong}配置文件不存在${gl_bai}"
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
		echo -e "${gl_huang}当前已关闭ipv6访问${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}已成功关闭ipv6访问${gl_bai}"
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
		echo "少なくとも1つのポート番号を提供してください"
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
			echo "ポート $port を開きました"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}

close_port() {
	local ports=($@)
	# 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "少なくとも1つのポート番号を提供してください"
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
			echo "ポート $port を閉じました"
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
		echo "少なくとも1つのIPアドレスまたはIP範囲を提供してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP $ip を許可しました"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)
	# 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも1つのIPアドレスまたはIP範囲を提供してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP $ip をブロックしました"
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
			echo "エラー: $country_code のIP地域ファイルをダウンロードできませんでした"
			exit 1
		fi

		# 将 IP 添加到 ipset
		while IFS= read -r ip; do
			ipset add "$ipset_name" "$ip"
		done <"${country_code,,}.zone"

		# 使用 iptables 阻止 IP
		iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
		iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

		echo "$country_code のIPアドレスを正常にブロックしました"
		rm "${country_code,,}.zone"
		;;

	allow)
		# 为允许的国家创建 ipset（如果不存在）
		if ! ipset list "$ipset_name" &>/dev/null; then
			ipset create "$ipset_name" hash:net
		fi

		# 下载 IP 区域文件
		if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
			echo "エラー: $country_code のIP地域ファイルをダウンロードできませんでした"
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

		echo "$country_code のIPアドレスのみを正常に許可しました"
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

		echo "$country_code のIPアドレス制限を正常に解除しました"
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
		echo "高度なファイアウォール管理"
		send_stats "高级防火墙管理"
		echo "------------------------"
		iptables -L INPUT
		echo
		echo "ファイアウォール管理"
		echo "------------------------"
		echo "1. 指定ポートを開く                 2. 指定ポートを閉じる"
		echo "3. 全ポートを開く                 4. 全ポートを閉じる"
		echo "------------------------"
		echo "5. IPホワイトリスト                  \t 6. IPブラックリスト"
		echo "7. 指定IPのクリア"
		echo "------------------------"
		echo "11. PINGを許可                  \t 12. PINGを禁止"
		echo "------------------------"
		echo "13. DDOS防御を開始                 14. DDOS防御を閉じる"
		echo "------------------------"
		echo "15. 指定国のIPをブロック               16. 指定国のIPのみを許可"
		echo "17. 指定国のIP制限を解除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " sub_choice
		case $sub_choice in
		1)
			Ask "Please enter the port number to open: " o_port
			open_port $o_port
			send_stats "开放指定端口"
			;;
		2)
			Ask "Please enter the port number to close: " c_port
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
			Ask "Please enter the IP address or IP range to allow: " o_ip
			allow_ip $o_ip
			;;
		6)
			# IP 黑名单
			Ask "Please enter the IP address or IP range to block: " c_ip
			block_ip $c_ip
			;;
		7)
			# 清除指定 IP
			Ask "Please enter the IP address to clear: " d_ip
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
			Ask "Please enter the country codes to block (e.g., CN, US, JP): " country_code
			manage_country_rules block $country_code
			send_stats "允许国家 $country_code 的IP"
			;;
		16)
			Ask "Please enter the country codes to allow (e.g., CN, US, JP): " country_code
			manage_country_rules allow $country_code
			send_stats "阻止国家 $country_code 的IP"
			;;

		17)
			Ask "Please enter the country codes to clear (e.g., CN, US, JP): " country_code
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

	echo -e "虚拟内存大小已调整为${gl_huang}${new_swap}${gl_bai}M"
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
	echo "LDNMP環境のインストールが完了しました"
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
	echo "更新タスクが更新されました"
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
	echo -e "${gl_huang}$yuming 公钥信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo
	echo -e "${gl_huang}$yuming 私钥信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo
	echo -e "${gl_huang}证书存放路径${gl_bai}"
	echo "公開鍵: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "秘密鍵: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo
}

add_ssl() {
	echo -e "${gl_huang}快速申请SSL证书，过期前自动续签${gl_bai}"
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
	echo -e "${gl_huang}已申请的证书到期情况${gl_bai}"
	echo "サイト情報                      証明書の有効期限"
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
		echo -e "${gl_hong}注意: ${gl_bai}证书申请失败，请检查以下可能原因并重试："
		echo -e "1. 域名拼写错误 ➠ 请检查域名输入是否正确"
		echo -e "2. DNS解析问题 ➠ 确认域名已正确解析到本服务器IP"
		echo -e "3. 网络配置问题 ➠ 如使用Cloudflare Warp等虚拟网络请暂时关闭"
		echo -e "4. 防火墙限制 ➠ 检查80/443端口是否开放，确保验证可访问"
		echo -e "5. 申请次数超限 ➠ Let's Encrypt有每周限额(5次/域名/周)"
		echo -e "6. 国内备案限制 ➠ 中国大陆环境请确认域名是否备案"
		break_end
		clear
		echo "$webname のデプロイを再度試してください"
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
	echo -e "先将域名解析到本机IP: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	Ask "Please enter your IP address or resolved domain name: " yuming
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
	echo "更新${ldnmp_pods}が完了しました"

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
	echo "ログイン情報: "
	echo "ユーザー名: $dbuse"
	echo "パスワード: $dbusepasswd"
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
		Ask "Do you need to clear Cloudflare cache? (y/N): " answer
		if [[ $answer == "y" ]]; then
			echo "CF情報は$CONFIG_FILEに保存されており、後でCF情報を変更できます"
			Ask "Please enter your API_TOKEN: " API_TOKEN
			Ask "Please enter your CF username: " EMAIL
			Ask "Please enter your zone_id (separate multiple with spaces): " -a ZONE_IDS

			mkdir -p /home/web/config/
			echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" >"$CONFIG_FILE"
		fi
	fi

	# 循环遍历每个 zone_id 并执行清除缓存命令
	for ZONE_ID in "${ZONE_IDS[@]}"; do
		echo "キャッシュをクリア中 zone_id: $ZONE_ID"
		curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
			-H "X-Auth-Email: $EMAIL" \
			-H "X-Auth-Key: $API_TOKEN" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'
	done

	echo "キャッシュクリアリクエストが送信されました。"
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
		Ask "Delete site data, please enter your domain name(s) (separate multiple domain names with spaces): " yuming_list
		if [[ -z $yuming_list ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "ドメインを削除中: $yuming"
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "データベースを削除中: $dbname"
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
		echo "無効なパラメータ：'on' または 'off' を使用してください"
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
		waf_status=" WAFが有効です"
	else
		waf_status=""
	fi
}

check_cf_mode() {
	if [ -f "/path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" cfモードが有効です"
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

		echo "[+] WP_MEMORY_LIMIT を $FILE に置き換えました"
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

		echo "[+] WP_DEBUG 設定を $FILE に置き換えました"
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
		echo "無効なパラメータ：'on' または 'off' を使用してください"
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
		echo "無効なパラメータ：'on' または 'off' を使用してください"
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
		echo "無効なパラメータ：'on' または 'off' を使用してください"
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
			echo -e "服务器网站防御程序${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			echo "------------------------"
			echo "1. 防御プログラムのインストール"
			echo "------------------------"
			echo "5. SSHブロック記録の表示                6. ウェブサイトブロック記録の表示"
			echo "7. 防御ルールリストの表示               8. ログリアルタイム監視の表示"
			echo "------------------------"
			echo "11. ブロックパラメータの設定                  12. すべてのブラックIPのクリア"
			echo "------------------------"
			echo "21. cloudflareモード                22. 高負荷時に5秒シールドを有効にする"
			echo "------------------------"
			echo "31. WAFを有効にする                       32. WAFを無効にする"
			echo "33. DDOS防御を開始                 34. DDOS防御を閉じる"
			echo "------------------------"
			echo "9. 防御プログラムのアンインストール"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			Ask "Please enter your choice: " sub_choice
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
				echo "Fail2Ban防御プログラムがアンインストールされました"
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
				echo "cfバックエンドの右上にあるマイプロフィールに移動し、左側のAPIトークンを選択して、Global API Keyを取得してください"
				NO_TRAN="https://dash.cloudflare.com/login"
				echo "$NO_TRAN"
				Ask "Enter CF account: " cfuser
				Ask "Enter CF Global API Key: " cftoken

				wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
				docker exec nginx nginx -s reload

				cd /path/to/fail2ban/config/fail2ban/jail.d/
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

				cd /path/to/fail2ban/config/fail2ban/action.d
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

				sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
				sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
				f2b_status

				echo "cloudflareモードが設定されました。cfバックエンドのサイト-セキュリティ-イベントでブロック記録を確認できます"
				;;

			22)
				send_stats "高负载开启5秒盾"
				echo -e "${gl_huang}网站每5分钟自动检测，当达检测到高负载会自动开盾，低负载也会自动关闭5秒盾。${gl_bai}"
				echo "--------------"
				echo "CFパラメータの取得: "
				echo -e "到cf后台右上角我的个人资料，选择左侧API令牌，获取${gl_huang}Global API Key${gl_bai}"
				echo -e "到cf后台域名概要页面右下方获取${gl_huang}区域ID${gl_bai}"
				NO_TRAN="https://dash.cloudflare.com/login"
				echo "$NO_TRAN"
				echo "--------------"
				Ask "Enter CF account: " cfuser
				Ask "Enter CF Global API Key: " cftoken
				Ask "Enter the zone ID of the domain in CF: " cfzonID

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
					echo "高負荷自動シールドスクリプトが追加されました"
				else
					echo "自動シールドスクリプトは既に存在するため、追加する必要はありません"
				fi

				;;

			31)
				nginx_waf on
				echo "サイトWAFが有効になりました"
				send_stats "站点WAF已开启"
				;;

			32)
				nginx_waf off
				echo "サイトWAFが無効になりました"
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
		mode_info="高性能モード"
	else
		mode_info="標準モード"
	fi

}

check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# 检查 zstd 是否开启且未被注释（整行以 zstd on; 开头）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status="zstd圧縮が有効です"
	else
		zstd_status=""
	fi

	# 检查 brotli 是否开启且未被注释
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status="br圧縮が有効です"
	else
		br_status=""
	fi

	# 检查 gzip 是否开启且未被注释
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status="gzip圧縮が有効です"
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
		echo -e "优化LDNMP环境${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
		echo "------------------------"
		echo "1. 標準モード              2. 高性能モード (2H4G以上を推奨)"
		echo "------------------------"
		echo "3. gzip圧縮を有効にする          4. gzip圧縮を無効にする"
		echo "5. br圧縮を有効にする            6. br圧縮を無効にする"
		echo "7. zstd圧縮を有効にする          8. zstd圧縮を無効にする"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " sub_choice
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

			echo "LDNMP環境は標準モードに設定されました"

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

			echo "LDNMP環境は高性能モードに設定されました"

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
		check_docker="${gl_lv}がインストールされています${gl_bai}"
	else
		check_docker="${gl_hui}がインストールされていません${gl_bai}"
	fi

}

check_docker_app_ip() {
	echo "------------------------"
	echo "アクセスアドレス:"
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
			update_status="${gl_huang}新バージョンが見つかりました！${gl_bai}"
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
		echo "エラー：コンテナ $container_name_or_id のIPアドレスを取得できません。コンテナ名またはIDが正しいか確認してください。"
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

	echo "このサービスへのIP+ポートアクセスがブロックされました"
	save_iptables_rules
}

clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "エラー：コンテナ $container_name_or_id のIPアドレスを取得できません。コンテナ名またはIDが正しいか確認してください。"
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

	echo "このサービスへのIP+ポートアクセスが許可されました"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z $port || -z $allowed_ip ]]; then
		echo "エラー：ポート番号と許可するIPを指定してください。"
		echo "使用法: block_host_port <ポート番号> <許可するIP>"
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

	echo "このサービスへのIP+ポートアクセスがブロックされました"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z $port || -z $allowed_ip ]]; then
		echo "エラー：ポート番号と許可するIPを指定してください。"
		echo "使用法: clear_host_port_rules <ポート番号> <許可するIP>"
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

	echo "このサービスへのIP+ポートアクセスが許可されました"
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
		echo "1. インストール              2. 更新            3. アンインストール"
		echo "------------------------"
		echo "5. ドメインアクセスを追加      6. ドメインアクセスを削除"
		echo "7. IP+ポートアクセスを許可   8. IP+ポートアクセスをブロック"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1)
			check_disk_space $app_size
			Ask "Enter the external service port for the application, press Enter to use the default ${docker_port} port: " app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			setup_docker_dir
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

			clear
			echo "$docker_name のインストールが完了しました"
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
			echo "$docker_name のインストールが完了しました"
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
			echo "アプリケーションはアンインストールされました"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name}のドメインアクセス設定"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "ドメイン形式 example.com は https:// を含みません"
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
		echo "1. インストール             2. 更新             3. アンインストール"
		echo "------------------------"
		echo "5. ドメインアクセスを追加     6. ドメインアクセスを削除"
		echo "7. IP+ポートアクセスを許可  8. IP+ポートアクセスをブロック"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1)
			check_disk_space $app_size
			Ask "Enter the external service port for the application, press Enter to use the default ${docker_port} port: " app_port
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
			echo "${docker_name}のドメインアクセス設定"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;
		6)
			echo "ドメイン形式 example.com は https:// を含みません"
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

	Ask "${gl_huang}Tip: ${gl_bai}Do you want to restart the server now? (y/N): " rboot
	case "$rboot" in
	[Yy])
		echo "再起動しました"
		reboot
		;;
	*)
		echo "キャンセルしました"
		;;
	esac

}

ldnmp_install_status_one() {

	if docker inspect "php" &>/dev/null; then
		clear
		send_stats "无法再次安装LDNMP环境"
		echo -e "${gl_huang}提示: ${gl_bai}建站环境已安装。无需再次安装！"
		break_end
		linux_ldnmp
	fi

}

ldnmp_install_all() {
	cd ~
	send_stats "安装LDNMP环境"
	root_use
	clear
	echo -e "${gl_huang}LDNMP环境未安装，开始安装LDNMP环境...${gl_bai}"
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
	echo -e "${gl_huang}nginx未安装，开始安装nginx环境...${gl_bai}"
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
	echo "nginxのインストールが完了しました"
	echo -e "当前版本: ${gl_huang}v$nginx_version${gl_bai}"
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
	echo "あなたの $webname が構築されました！"
	echo "https://$yuming"
	echo "------------------------"
	echo "$webname のインストール情報は以下の通りです: "

}

nginx_web_on() {
	clear
	echo "あなたの $webname が構築されました！"
	echo "https://$yuming"

}

ldnmp_wp() {
	clear
	# wordpress
	webname="WordPress"
	yuming="${1:-}"
	send_stats "安装$webname"
	echo "$webname のデプロイを開始します"
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
	#   echo "データベース名: $dbname"
	#   echo "ユーザー名: $dbuse"
	#   echo "パスワード: $dbusepasswd"
	#   echo "データベースアドレス: mysql"
	#   echo "テーブルプレフィックス: wp_"

}

ldnmp_Proxy() {
	clear
	webname="リバースプロキシ - IP+ポート"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "$webname のデプロイを開始します"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		Ask "Please enter your reverse proxy IP: " reverseproxy
	fi

	if [ -z "$port" ]; then
		Ask "Please enter your reverse proxy port: " port
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
	webname="リバースプロキシ - ロードバランシング"
	yuming="${1:-}"
	reverseproxy_port="${2:-}"

	send_stats "安装$webname"
	echo "$webname のデプロイを開始します"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# 获取用户输入的多个IP:端口（用空格分隔）
	if [ -z "$reverseproxy_port" ]; then
		Ask "Please enter your multiple reverse proxy IPs + ports separated by spaces (e.g., 127.0.0.1:3000 127.0.0.1:3002): " reverseproxy_port
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
		local output="サイト: ${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="データベース: ${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "LDNMP環境"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}                      证书到期时间"
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
		echo "サイトディレクトリ"
		echo "------------------------"
		echo -e "数据 ${gl_hui}/home/web/html${gl_bai}     证书 ${gl_hui}/home/web/certs${gl_bai}     配置 ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo
		echo "操作"
		echo "------------------------"
		echo "1.  ドメイン証明書を申請/更新               2.  サイトのドメインを変更"
		echo "3.  サイトキャッシュをクリア                    4.  関連サイトを作成"
		echo "5.  アクセスログを表示                    6.  エラーログを表示"
		echo "7.  グローバル設定を編集                    8.  サイト設定を編集"
		echo "9.  サイトデータベースを管理\t\t    10. サイト分析レポートを表示"
		echo "------------------------"
		echo "20. 指定サイトのデータを削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " sub_choice
		case $sub_choice in
		1)
			send_stats "申请域名证书"
			Ask "Please enter your domain name: " yuming
			install_certbot
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
			install_ssltls
			certs_status

			;;

		2)
			send_stats "更换站点域名"
			echo -e "${gl_hong}强烈建议: ${gl_bai}先备份好全站数据再更换站点域名！"
			Ask "Please enter the old domain name: " oddyuming
			Ask "Please enter the new domain name: " yuming
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
			echo -e "为现有的站点再关联一个新域名用于访问"
			Ask "Please enter the existing domain name: " oddyuming
			Ask "Please enter the new domain name: " yuming
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
			Ask "Edit site configuration, please enter the domain name you want to edit: " yuming
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
		check_panel="${gl_lv}がインストールされています${gl_bai}"
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
		echo "${panelname}は、現在人気があり強力な運用管理パネルです。"
		echo "公式サイト紹介: $panelurl "

		echo
		echo "------------------------"
		echo "1. インストール            2. 管理            3. アンインストール"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
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
		check_frp="${gl_lv}がインストールされています${gl_bai}"
	else
		check_frp="${gl_hui}がインストールされていません${gl_bai}"
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
	echo "クライアントデプロイ時に使用するパラメータ"
	echo "サービスIP: $ipv4_address"
	echo "token: $token"
	echo
	echo "FRPパネル情報"
	echo "FRPパネルアドレス: http://$ipv4_address:$dashboard_port"
	echo "FRPパネルユーザー名: $dashboard_user"
	echo "FRPパネルパスワード: $dashboard_pwd"
	echo

	open_port 8055 8056

}

configure_frpc() {
	send_stats "安装frp客户端"
	Ask "Please enter the external access IP: " server_addr
	Ask "Please enter your external access token: " token
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
	Ask "Please enter the service name: " service_name
	Ask "Please enter the forwarding type (tcp/udp) [Press Enter for tcp]: " service_type
	local service_type=${service_type:-tcp}
	Ask "Please enter the internal IP [Press Enter for 127.0.0.1]: " local_ip
	local local_ip=${local_ip:-127.0.0.1}
	Ask "Please enter the internal port: " local_port
	Ask "Please enter the external port: " remote_port

	# 将用户输入写入配置文件
	NO_TRAN=$'\n[$service_name]\ntype = ${service_type}\nlocal_ip = ${local_ip}\nlocal_port = ${local_port}\nremote_port = ${remote_port}\n'
	echo -e "$NO_TRAN" >>/home/frp/frpc.toml

	# 输出生成的信息
	echo "サービス $service_name が frpc.toml に正常に追加されました"

	docker restart frpc

	open_port $local_port

}

delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	Ask "Please enter the service name to delete: " service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "サービス $service_name が frpc.toml から正常に削除されました"

	docker restart frpc

}

list_forwarding_services() {
	local config_file="$1"

	# 打印表头
	echo "サービス名         内部アドレス              外部アドレス                   プロトコル"

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
		echo "FRPサービス外部アクセスアドレス:"

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
		echo -e "FRP服务端 $check_frp $update_status"
		echo "FRP内部ネットワーク貫通サービス環境を構築し、パブリックIPを持たないデバイスをインターネットに公開します"
		echo "公式サイト紹介: https://github.com/fatedier/frp/"
		echo "ビデオチュートリアル: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo
		echo "------------------------"
		echo "1. インストール                  2. 更新                  3. アンインストール"
		echo "------------------------"
		echo "5. 内部サービスドメインアクセス      6. ドメインアクセスを削除"
		echo "------------------------"
		echo "7. IP+ポートアクセスを許可       8. IP+ポートアクセスをブロック"
		echo "------------------------"
		echo "00. サービス状態をリフレッシュ         0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			generate_frps_config
			echo "FRPサーバーのインストールが完了しました"
			;;
		2)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
			donlond_frp frps
			echo "FRPサーバーの更新が完了しました"
			;;
		3)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine
			rm -rf /home/frp

			close_port 8055 8056

			echo "アプリケーションはアンインストールされました"
			;;
		5)
			echo "内部ネットワーク貫通サービスをドメインアクセスにリバースプロキシします"
			send_stats "FRP对外域名访问"
			add_yuming
			Ask "内网穿透サービスのポートを入力してください: " frps_port
			ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
			block_host_port "$frps_port" "$ipv4_address"
			;;
		6)
			echo "ドメイン形式 example.com は https:// を含みません"
			web_del
			;;

		7)
			send_stats "允许IP访问"
			Ask "許可するポートを入力してください: " frps_port
			clear_host_port_rules "$frps_port" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问"
			echo "ドメインアクセスにリバースプロキシ済みの場合、この機能を使用してIP+ポートアクセスをブロックできます。これにより、より安全になります。"
			Ask "ブロックするポートを入力してください: " frps_port
			block_host_port "$frps_port" "$ipv4_address"
			;;

		00)
			send_stats "刷新FRP服务状态"
			echo "FRPサービスの状態をリフレッシュしました"
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
		echo -e "FRP客户端 $check_frp $update_status"
		echo "サーバーと連携し、連携後に内部ネットワーク貫通サービスを作成してインターネットからアクセスできるようにします"
		echo "公式サイト紹介: https://github.com/fatedier/frp/"
		echo "ビデオチュートリアル: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo
		echo "------------------------"
		echo "1. インストール               2. 更新               3. アンインストール"
		echo "------------------------"
		echo "4. 外部サービスを追加       5. 外部サービスを削除       6. サービスを手動設定"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			configure_frpc
			echo "FRPクライアントのインストールが完了しました"
			;;
		2)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			donlond_frp frpc
			echo "FRPクライアントの更新が完了しました"
			;;

		3)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine
			rm -rf /home/frp
			close_port 8055
			echo "アプリケーションはアンインストールされました"
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
			local YTDLP_STATUS="${gl_lv}がインストールされています${gl_bai}"
		else
			local YTDLP_STATUS="${gl_hui}がインストールされていません${gl_bai}"
		fi

		clear
		send_stats "yt-dlp 下载工具"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp 是一个功能强大的视频下载工具，支持 YouTube、Bilibili、Twitter 等数千站点。"
		echo -e "官网地址：https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "ダウンロード済みビデオリスト:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "（なし）"
		echo "-------------------------"
		echo "1.  インストール               2.  更新               3.  アンインストール"
		echo "-------------------------"
		echo "5.  単一ビデオダウンロード       6.  バッチビデオダウンロード       7.  カスタムパラメータダウンロード"
		echo "8.  MP3オーディオとしてダウンロード      9.  ビデオディレクトリを削除       10. Cookie管理（開発中）"
		echo "-------------------------"
		echo "0. 前のメニューに戻る"
		echo "-------------------------"
		Ask "オプション番号を入力してください: " choice

		case $choice in
		1)
			send_stats "正在安装 yt-dlp..."
			echo "yt-dlpをインストール中..."
			install ffmpeg
			sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
			sudo chmod a+rx /usr/local/bin/yt-dlp
			Press "Installation complete. Press any key to continue..."
			;;
		2)
			send_stats "正在更新 yt-dlp..."
			echo "yt-dlpを更新中..."
			sudo yt-dlp -U
			Press "Update complete. Press any key to continue..."
			;;
		3)
			send_stats "正在卸载 yt-dlp..."
			echo "yt-dlpをアンインストール中..."
			sudo rm -f /usr/local/bin/yt-dlp
			Press "Uninstallation complete. Press any key to continue..."
			;;
		5)
			send_stats "单个视频下载"
			Ask "ビデオリンクを入力してください: " url
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			Press "Download complete, press any key to continue..."
			;;
		6)
			send_stats "批量视频下载"
			install nano
			if [ ! -f "$URL_FILE" ]; then
				echo -e "# 输入多个视频链接地址\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" >"$URL_FILE"
			fi
			nano $URL_FILE
			echo "バッチダウンロードを開始します..."
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-a "$URL_FILE" \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			Press "Batch download complete, press any key to continue..."
			;;
		7)
			send_stats "自定义视频下载"
			Ask "完全なyt-dlpパラメータを入力してください（yt-dlpを除く）: " custom
			yt-dlp -P "$VIDEO_DIR" $custom \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			Press "Execution complete, press any key to continue..."
			;;
		8)
			send_stats "MP3下载"
			Ask "ビデオリンクを入力してください: " url
			yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			Press "Audio download complete, press any key to continue..."
			;;

		9)
			send_stats "删除视频"
			Ask "削除するビデオ名を入力してください: " rmdir
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
	echo -e "${gl_huang}正在系统更新...${gl_bai}"
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
		echo "不明なパッケージマネージャー！"
		return
	fi
}

linux_clean() {
	echo -e "${gl_huang}正在系统清理...${gl_bai}"
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
		echo "パッケージマネージャーキャッシュをクリア中..."
		apk cache clean
		echo "システムログを削除中..."
		rm -rf /var/log/*
		echo "APKキャッシュを削除中..."
		rm -rf /var/cache/apk/*
		echo "一時ファイルを削除中..."
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
		echo "システムログを削除中..."
		rm -rf /var/log/*
		echo "一時ファイルを削除中..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "未使用の依存関係をクリア中..."
		pkg autoremove -y
		echo "パッケージマネージャーキャッシュをクリア中..."
		pkg clean -y
		echo "システムログを削除中..."
		rm -rf /var/log/*
		echo "一時ファイルを削除中..."
		rm -rf /tmp/*

	else
		echo "不明なパッケージマネージャー！"
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
		echo "DNSアドレスを最適化"
		echo "------------------------"
		echo "現在のDNSアドレス"
		cat /etc/resolv.conf
		echo "------------------------"
		echo
		echo "1. 海外DNS最適化: "
		echo " v4: 1.1.1.1 8.8.8.8"
		echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
		echo "2. 国内DNS最適化:"
		echo " v4: 223.5.5.5 183.60.83.19"
		echo " v6: 2400:3200::1 2400:da00::6666"
		echo "3. DNS設定を手動編集"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " Limiting
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

	echo "SSHポートは次のものに変更されました: $new_port"

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
	echo -e "私钥信息已生成，务必复制保存，可保存成 ${gl_huang}${ipv4_address}_ssh.key${gl_bai} 文件，用于以后的SSH登录"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${gl_bai}"

}

import_sshkey() {

	Ask "SSH公開鍵の内容を入力してください（通常は 'ssh-rsa' または 'ssh-ed25519' で始まります）: " public_key

	if [[ -z $public_key ]]; then
		echo -e "${gl_hong}错误：未输入公钥内容。${gl_bai}"
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
	echo -e "${gl_lv}公钥已成功导入，ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${gl_bai}"

}

add_sshpasswd() {

	echo "ROOTパスワードを設定してください"
	passwd
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOTログイン設定完了！${gl_bai}"

}

root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${gl_huang}ヒント: ${gl_bai}この機能はrootユーザーのみ実行可能です！" && break_end && kejilion
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
		echo -e "再インストール後の初期ユーザー名: ${gl_huang}root${gl_bai}  初期パスワード: ${gl_huang}LeitboGi0ro${gl_bai}  初期ポート: ${gl_huang}22${gl_bai}"
		Press "Press any key to continue..."
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_2() {
		echo -e "再インストール後の初期ユーザー名: ${gl_huang}Administrator${gl_bai}  初期パスワード: ${gl_huang}Teddysun.com${gl_bai}  初期ポート: ${gl_huang}3389${gl_bai}"
		Press "Press any key to continue..."
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_3() {
		echo -e "再インストール後の初期ユーザー名: ${gl_huang}root${gl_bai}  初期パスワード: ${gl_huang}123@@@${gl_bai}  初期ポート: ${gl_huang}22${gl_bai}"
		Press "Press any key to continue..."
		dd_xitong_bin456789
	}

	dd_xitong_4() {
		echo -e "再インストール後の初期ユーザー名: ${gl_huang}Administrator${gl_bai}  初期パスワード: ${gl_huang}123@@@${gl_bai}  初期ポート: ${gl_huang}3389${gl_bai}"
		Press "Press any key to continue..."
		dd_xitong_bin456789
	}

	while true; do
		root_use
		echo "システム再インストール"
		echo "--------------------------------"
		echo -e "${gl_hong}注意: ${gl_bai}再インストールは接続不能のリスクがあります。ご心配な方は慎重にご利用ください。再インストールには約15分かかりますので、事前にデータのバックアップをお願いします。"
		echo -e "${gl_hui}MollyLau様、bin456789様のスクリプトサポートに感謝いたします！${gl_bai} "
		echo "------------------------"
		echo "1. Debian 12                  2. Debian 11"
		echo "3. Debian 10                  4. Debian 9"
		echo "------------------------"
		echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
		echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
		echo "------------------------"
		echo "21. Rocky Linux 10            22. Rocky Linux 9"
		echo "23. Alma Linux 10             24. Alma Linux 9"
		echo "25. Oracle Linux 10           26. Oracle Linux 9"
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
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "再インストールするシステムを選択してください: " sys_choice
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
			echo "XanmodのBBRv3カーネルがインストールされました"
			echo "現在のカーネルバージョン: $kernel_version"

			echo
			echo "カーネル管理"
			echo "------------------------"
			echo "1. BBRv3カーネルを更新              2. BBRv3カーネルをアンインストール"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			Ask "Please enter your choice: " sub_choice

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

				echo "XanModカーネルが更新されました。再起動後に有効になります"
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f check_x86-64_psabi.sh*

				server_reboot

				;;
			2)
				apt purge -y 'linux-*xanmod1*'
				update-grub
				echo "XanModカーネルがアンインストールされました。再起動後に有効になります"
				server_reboot
				;;

			*)
				break
				;;

			esac
		done
	else

		clear
		echo "BBR3アクセラレーションを設定"
		echo "ビデオ紹介: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		echo "------------------------------------------------"
		echo "Debian/Ubuntuのみサポート"
		echo "データをバックアップしてください。LinuxカーネルをアップグレードしてBBR3を有効にします。"
		echo "VPSは512Mメモリです。メモリ不足による切断を防ぐため、事前に1Gの仮想メモリを追加してください！"
		echo "------------------------------------------------"
		Ask "続行しますか？(y/N): " choice

		case "$choice" in
		[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "現在の環境はサポートされていません。DebianおよびUbuntuシステムのみサポートしています。"
					break_end
					linux_Settings
				fi
			else
				echo "オペレーティングシステムのタイプを特定できません"
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

			echo "XanModカーネルのインストールとBBR3の有効化に成功しました。再起動後に有効になります"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			;;
		[Nn])
			echo "キャンセルしました"
			;;
		*)
			echo "無効な選択です。Y または N を入力してください。"
			;;
		esac
	fi

}

elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "ELRepo GPG公開鍵をインポート中..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ $os_name != *"Red Hat"* && $os_name != *"AlmaLinux"* && $os_name != *"Rocky"* && $os_name != *"Oracle"* && $os_name != *"CentOS"* ]]; then
		echo "サポートされていないオペレーティングシステム: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "検出されたオペレーティングシステム: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ $os_version == 8 ]]; then
		echo "ELRepoリポジトリ設定をインストール (バージョン 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ $os_version == 9 ]]; then
		echo "ELRepoリポジトリ設定をインストール (バージョン 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ $os_version == 10 ]]; then
		echo "ELRepoリポジトリ設定をインストール (バージョン 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "サポートされていないシステムバージョン: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "ELRepoカーネルリポジトリを有効化し、最新のメインラインカーネルをインストール中..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "ELRepoリポジトリ設定がインストールされ、最新のメインラインカーネルに更新されました。"
	server_reboot

}

elrepo() {
	root_use
	send_stats "红帽内核管理"
	if uname -r | grep -q 'elrepo'; then
		while true; do
			clear
			kernel_version=$(uname -r)
			echo "elrepoカーネルがインストールされました"
			echo "現在のカーネルバージョン: $kernel_version"

			echo
			echo "カーネル管理"
			echo "------------------------"
			echo "1. elrepoカーネルを更新              2. elrepoカーネルをアンインストール"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			Ask "Please enter your choice: " sub_choice

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
				echo "elrepoカーネルがアンインストールされました。再起動後に有効になります"
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
		echo "データをバックアップしてください。Linuxカーネルをアップグレードします。"
		echo "ビデオ紹介: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		echo "------------------------------------------------"
		echo "Red Hat系ディストリビューション CentOS/RedHat/Alma/Rocky/Oracle のみサポート"
		echo "Linuxカーネルのアップグレードはシステムパフォーマンスとセキュリティを向上させます。条件が許せば試すことをお勧めしますが、本番環境では慎重にアップグレードしてください！"
		echo "------------------------------------------------"
		Ask "続行しますか？(y/N): " choice

		case "$choice" in
		[Yy])
			check_swap
			elrepo_install
			send_stats "升级红帽内核"
			server_reboot
			;;
		[Nn])
			echo "キャンセルしました"
			;;
		*)
			echo "無効な選択です。Y または N を入力してください。"
			;;
		esac
	fi

}

clamav_freshclam() {
	echo -e "${gl_huang}ウイルス定義ファイルを更新中...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "スキャンするディレクトリを指定してください。"
		return
	fi

	echo -e "${gl_huang}ディレクトリ$@をスキャン中... ${gl_bai}"

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

	echo -e "${gl_lv}$@ スキャン完了、ウイルスレポートは${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}に保存されました"
	echo -e "${gl_lv}ウイルスが見つかった場合は、${gl_huang}scan.log${gl_lv}ファイルでFOUNDキーワードを検索してウイルスの位置を確認してください ${gl_bai}"

}

clamav() {
	root_use
	send_stats "病毒扫描管理"
	while true; do
		clear
		echo "clamavウイルススキャンツール"
		echo "ビデオ紹介: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
		echo "------------------------"
		echo "は、さまざまな種類のマルウェアを検出および削除するために使用されるオープンソースのアンチウイルスソフトウェアツールです。"
		echo "ウイルス、トロイの木馬、スパイウェア、悪意のあるスクリプト、その他の有害なソフトウェアが含まれます。"
		echo "------------------------"
		echo -e "${gl_lv}1. 全ディスクスキャン ${gl_bai}             ${gl_huang}2. 重要ディレクトリのスキャン ${gl_bai}            ${gl_kjlan} 3. カスタムディレクトリのスキャン ${gl_bai}"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " sub_choice
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
			Ask "スキャンするディレクトリを入力してください。スペースで区切ります（例: /etc /var /usr /home /root）: " directories
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
	echo -e "${gl_lv}${tiaoyou_moshi}に切り替え中...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを最適化中...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}仮想メモリを最適化中...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化中...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を最適化中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}その他の最適化中...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}バランスモードに切り替え中...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを最適化中...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}仮想メモリを最適化中...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化中...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を最適化中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}その他の最適化中...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}デフォルト設定に復元中...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを復元中...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}仮想メモリを復元中...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を復元中...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を復元中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}CPU設定を復元中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}その他の最適化を復元中...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}ウェブサイト構築最適化モードに切り替え中...${gl_bai}"

	echo -e "${gl_lv}ファイルディスクリプタを最適化中...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}仮想メモリを最適化中...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化中...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を最適化中...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化中...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}その他の最適化中...${gl_bai}"
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
		echo "Linuxシステムカーネルパラメータの最適化"
		echo "ビデオ紹介: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
		echo "------------------------------------------------"
		echo "複数のシステムパラメータチューニングモードを提供し、ユーザーは自身の使用シナリオに応じて選択および切り替えることができます。"
		echo -e "${gl_huang}ヒント: ${gl_bai}本番環境では慎重にご利用ください！"
		echo "--------------------"
		echo "1. 高性能最適化モード：     システムパフォーマンスを最大化し、ファイルディスクリプタ、仮想メモリ、ネットワーク設定、キャッシュ管理、CPU設定を最適化します。"
		echo "2. バランス最適化モード：       パフォーマンスとリソース消費のバランスを取り、日常の使用に適しています。"
		echo "3. ウェブサイト最適化モード：       ウェブサイトサーバー向けに最適化され、同時接続処理能力、応答速度、全体的なパフォーマンスを向上させます。"
		echo "4. ライブストリーム最適化モード：       ライブストリームプッシュの特別なニーズに合わせて最適化され、遅延を削減し、転送パフォーマンスを向上させます。"
		echo "5. ゲームサーバー最適化モード：     ゲームサーバー向けに最適化され、同時処理能力と応答速度を向上させます。"
		echo "6. デフォルト設定に戻す：       システム設定をデフォルト構成に戻します。"
		echo "--------------------"
		echo "0. 前のメニューに戻る"
		echo "--------------------"
		Ask "Please enter your choice: " sub_choice
		case $sub_choice in
		1)
			cd ~
			clear
			local tiaoyou_moshi="高性能最適化モード"
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
			local tiaoyou_moshi="ライブストリーム最適化モード"
			optimize_high_performance
			send_stats "直播推流优化"
			;;
		5)
			cd ~
			clear
			local tiaoyou_moshi="ゲームサーバー最適化モード"
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
			echo -e "${gl_lv}システム言語を: $lang に変更しました。SSHを再接続すると有効になります。${gl_bai}"
			hash -r
			break_end

			;;
		centos | rhel | almalinux | rocky | fedora)
			install glibc-langpack-zh
			localectl set-locale LANG=${lang}
			echo "LANG=${lang}" | tee /etc/locale.conf
			echo -e "${gl_lv}システム言語を: $lang に変更しました。SSHを再接続すると有効になります。${gl_bai}"
			hash -r
			break_end
			;;
		*)
			echo "サポートされていないシステム: $ID"
			break_end
			;;
		esac
	else
		echo "サポートされていないシステム、システムタイプを認識できません。"
		break_end
	fi
}

linux_language() {
	root_use
	send_stats "切换系统语言"
	while true; do
		clear
		echo "現在のシステム言語: $LANG"
		echo "------------------------"
		echo "1. 英語          2. 簡体字中国語          3. 繁体字中国語"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice

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
	echo -e "${gl_lv}変更が完了しました。SSHを再接続すると変更内容を確認できます！${gl_bai}"

	hash -r
	break_end

}

shell_bianse() {
	root_use
	send_stats "命令行美化工具"
	while true; do
		clear
		echo "コマンドライン美化ツール"
		echo "------------------------"
		echo -e "1. \\033[1;32mroot \\033[1;34mlocalhost \\033[1;31m~ \\033[0m${gl_bai}#"
		echo -e "2. \\033[1;35mroot \\033[1;36mlocalhost \\033[1;33m~ \\033[0m${gl_bai}#"
		echo -e "3. \\033[1;31mroot \\033[1;32mlocalhost \\033[1;34m~ \\033[0m${gl_bai}#"
		echo -e "4. \\033[1;36mroot \\033[1;33mlocalhost \\033[1;37m~ \\033[0m${gl_bai}#"
		echo -e "5. \\033[1;37mroot \\033[1;31mlocalhost \\033[1;32m~ \\033[0m${gl_bai}#"
		echo -e "6. \\033[1;33mroot \\033[1;34mlocalhost \\033[1;35m~ \\033[0m${gl_bai}#"
		echo -e "7. root localhost ~ #"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice

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
			trash_status="${gl_hui}は有効になっていません${gl_bai}"
		else
			trash_status="${gl_lv}が有効になっています${gl_bai}"
		fi

		clear
		echo -e "現在のゴミ箱 ${trash_status}"
		echo -e "有効にすると、rmで削除されたファイルはゴミ箱に入り、誤って重要なファイルを削除するのを防ぎます！"
		echo "------------------------------------------------"
		ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "ゴミ箱は空です"
		echo "------------------------"
		echo "1. ゴミ箱を有効にする          2. ゴミ箱を無効にする"
		echo "3. 内容を復元            4. ゴミ箱を空にする"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice

		case $choice in
		1)
			install trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='trash-put'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "ゴミ箱が有効になりました。削除されたファイルはゴミ箱に移動されます。"
			sleep 2
			;;
		2)
			remove trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='rm -i'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "ゴミ箱が無効になりました。ファイルは直接削除されます。"
			sleep 2
			;;
		3)
			Ask "復元するファイル名を入力してください: " file_to_restore
			if [ -e "$TRASH_DIR/$file_to_restore" ]; then
				mv "$TRASH_DIR/$file_to_restore" "$HOME/"
				echo "$file_to_restore がホームディレクトリに復元されました。"
			else
				echo "ファイルが存在しません。"
			fi
			;;
		4)
			Ask "ゴミ箱を空にしますか？(y/N): " confirm
			if [[ $confirm == "y" ]]; then
				trash-empty
				echo "ゴミ箱が空になりました。"
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
	echo "バックアップの作成例:"
	echo "  - 単一ディレクトリのバックアップ: /var/www"
	echo "  - 複数のディレクトリのバックアップ: /etc /home /var/log"
	echo "  - Enterキーを押すとデフォルトディレクトリ (/etc /usr /home) が使用されます"
	Ask "バックアップするディレクトリを入力してください（複数のディレクトリはスペースで区切ります。直接Enterを押すとデフォルトのディレクトリが使用されます）:" input

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
	echo "選択されたバックアップディレクトリ:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "バックアップを作成中 $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "バックアップが正常に作成されました: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "バックアップの作成に失敗しました！"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	Ask "復元するバックアップファイル名を入力してください: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルが存在しません！"
		exit 1
	fi

	echo "バックアップを復元中 $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "バックアップの復元に成功しました！"
	else
		echo "バックアップの復元に失敗しました！"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "利用可能なバックアップ："
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	Ask "削除するバックアップファイル名を入力してください: " BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルが存在しません！"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "バックアップの削除に成功しました！"
	else
		echo "バックアップの削除に失敗しました！"
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
		echo "システムバックアップ機能"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. バックアップ作成        2. バックアップ復元        3. バックアップ削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1) create_backup ;;
		2) restore_backup ;;
		3) delete_backup ;;
		*) break ;;
		esac
		Press "Press Enter to continue..."
	done
}

# 显示连接列表
list_connections() {
	echo "保存済みの接続："
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}

# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "新しい接続の作成例："
	echo "  - 接続名: my_server"
	echo "  - IPアドレス: 192.168.1.100"
	echo "  - ユーザー名: root"
	echo "  - ポート: 22"
	echo "------------------------"
	Ask "接続名を入力してください: " name
	Ask "IPアドレスを入力してください: " ip
	Ask "ユーザー名を入力してください (デフォルト: root): " user
	local user=${user:-root} # 如果用户未输入，则使用默认值 root
	Ask "ポート番号を入力してください (デフォルト: 22): " port
	local port=${port:-22} # 如果用户未输入，则使用默认值 22

	echo "認証方法を選択してください："
	echo "1. パスワード"
	echo "2. キー"
	Ask "選択を入力してください (1/2): " auth_choice

	case $auth_choice in
	1)
		Ask "パスワードを入力してください: " -s password_or_key
		echo # 换行
		;;
	2)
		echo "キーの内容を貼り付けてください（貼り付け後、Enterキーを2回押してください）："
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
		echo "無効な選択です！"
		return
		;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >>"$CONFIG_FILE"
	echo "接続を保存しました！"
}

# 删除连接
delete_connection() {
	send_stats "删除连接"
	Ask "削除する接続番号を入力してください: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $connection ]]; then
		echo "エラー：対応する接続が見つかりませんでした。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ $password_or_key == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "接続を削除しました！"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	Ask "使用する接続番号を入力してください: " num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $connection ]]; then
		echo "エラー：対応する接続が見つかりませんでした。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	echo "$name ($ip) に接続中..."
	if [[ -f $password_or_key ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました！以下の点を確認してください："
			echo "1. キーファイルのパスが正しいか：$password_or_key"
			echo "2. キーファイルの権限が正しいか（600である必要があります）。"
			echo "3. ターゲットサーバーがキーログインを許可しているか。"
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &>/dev/null; then
			echo "エラー：sshpass がインストールされていません。まず sshpass をインストールしてください。"
			echo "インストール方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました！以下の点を確認してください："
			echo "1. ユーザー名とパスワードが正しいか。"
			echo "2. ターゲットサーバーがパスワードログインを許可しているか。"
			echo "3. ターゲットサーバーのSSHサービスが正常に動作しているか。"
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
		echo "SSHリモート接続ツール"
		echo "SSHを使用して他のLinuxシステムに接続できます"
		echo "------------------------"
		list_connections
		echo "1. 新しい接続を作成        2. 接続を使用        3. 接続を削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1) add_connection ;;
		2) use_connection ;;
		3) delete_connection ;;
		0) break ;;
		*) echo "無効な選択です。再試行してください。" ;;
		esac
	done
}

# 列出可用的硬盘分区
list_partitions() {
	echo "利用可能なディスクパーティション："
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	Ask "マウントするパーティション名を入力してください（例: sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "パーティションが存在しません！"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "パーティションは既にマウントされています！"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "パーティションのマウントに成功しました: $MOUNT_POINT"
	else
		echo "パーティションのマウントに失敗しました！"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	Ask "アンマウントするパーティション名を入力してください（例: sda1）: " PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "パーティションはマウントされていません！"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションのアンマウントに成功しました: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "パーティションのアンマウントに失敗しました！"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "マウントされているパーティション："
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	Ask "フォーマットするパーティション名を入力してください（例: sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "パーティションが存在しません！"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "パーティションは既にマウントされています。まずアンマウントしてください！"
		return
	fi

	# 选择文件系统类型
	echo "ファイルシステムタイプを選択してください："
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	Ask "Please enter your choice: " FS_CHOICE

	case $FS_CHOICE in
	1) FS_TYPE="ext4" ;;
	2) FS_TYPE="xfs" ;;
	3) FS_TYPE="ntfs" ;;
	4) FS_TYPE="vfat" ;;
	*)
		echo "無効な選択です！"
		return
		;;
	esac

	# 确认格式化
	Ask "パーティション /dev/$PARTITION を $FS_TYPE にフォーマットしますか？(y/N): " CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作はキャンセルされました。"
		return
	fi

	# 格式化分区
	echo "パーティション /dev/$PARTITION を $FS_TYPE にフォーマット中..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションのフォーマットに成功しました！"
	else
		echo "パーティションのフォーマットに失敗しました！"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	Ask "チェックするパーティション名を入力してください（例: sda1）: " PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "パーティションが存在しません！"
		return
	fi

	# 检查分区状态
	echo "パーティション /dev/$PARTITION の状態を確認中："
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "ディスクパーティション管理"
		echo -e "${gl_huang}この機能は内部テスト段階です。本番環境では使用しないでください。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. パーティションのマウント        2. パーティションのアンマウント        3. マウントされているパーティションの表示"
		echo "4. パーティションのフォーマット      5. パーティションの状態確認"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1) mount_partition ;;
		2) unmount_partition ;;
		3) list_mounted_partitions ;;
		4) format_partition ;;
		5) check_partition ;;
		*) break ;;
		esac
		Press "Press Enter to continue..."
	done
}

# 显示任务列表
list_tasks() {
	echo "保存済みの同期タスク："
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "新しい同期タスクの作成例："
	echo "  - タスク名: backup_www"
	echo "  - ローカルディレクトリ: /var/www"
	echo "  - リモートアドレス: user@192.168.1.100"
	echo "  - リモートディレクトリ: /backup/www"
	echo "  - ポート番号 (デフォルト 22)"
	echo "---------------------------------"
	Ask "タスク名を入力してください: " name
	Ask "ローカルディレクトリを入力してください: " local_path
	Ask "リモートディレクトリを入力してください: " remote_path
	Ask "リモートユーザー@IPを入力してください: " remote
	Ask "SSHポートを入力してください (デフォルト 22): " port
	port=${port:-22}

	echo "認証方法を選択してください："
	echo "1. パスワード"
	echo "2. キー"
	Ask "選択を入力してください (1/2): " auth_choice

	case $auth_choice in
	1)
		Ask "パスワードを入力してください: " -s password_or_key
		echo # 换行
		auth_method="password"
		;;
	2)
		echo "キーの内容を貼り付けてください（貼り付け後、Enterキーを2回押してください）："
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
			echo "無効なキーコンテンツです！"
			return
		fi
		;;
	*)
		echo "無効な選択です！"
		return
		;;
	esac

	echo "同期モードを選択してください："
	echo "1. 標準モード (-avz)"
	echo "2. ターゲットファイルを削除 (-avz --delete)"
	Ask "選択を入力してください (1/2): " mode
	case $mode in
	1) options="-avz" ;;
	2) options="-avz --delete" ;;
	*)
		echo "無効な選択です。デフォルトの -avz を使用します。"
		options="-avz"
		;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >>"$CONFIG_FILE"

	install rsync rsync

	echo "タスクを保存しました！"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	Ask "削除するタスク番号を入力してください: " num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $task ]]; then
		echo "エラー：対応するタスクが見つかりませんでした。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ $auth_method == "key" && $password_or_key == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "タスクを削除しました！"
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
		Ask "実行するタスク番号を入力してください: " num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $task ]]; then
		echo "エラー: このタスクは見つかりません！"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 根据同步方向调整源和目标路径
	if [[ $direction == "pull" ]]; then
		echo "ローカルへの同期を取得中: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "リモートへの同期をプッシュ中: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ $auth_method == "password" ]]; then
		if ! command -v sshpass &>/dev/null; then
			echo "エラー：sshpass がインストールされていません。まず sshpass をインストールしてください。"
			echo "インストール方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f $password_or_key ]]; then
			echo "エラー：キーファイルが存在しません：$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "警告：キーファイルの権限が正しくありません。修正中です..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "同期が完了しました！"
	else
		echo "同期に失敗しました！以下の点を確認してください："
		echo "1. ネットワーク接続が正常か"
		echo "2. リモートホストにアクセス可能か"
		echo "3. 認証情報が正しいか"
		echo "4. ローカルおよびリモートディレクトリに正しいアクセス権があるか"
	fi
}

# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	Ask "定期的に同期するタスク番号を入力してください: " num
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		echo "エラー: 有効なタスク番号を入力してください！"
		return
	fi

	echo "実行間隔を選択してください："
	echo "1) 1時間ごとに実行"
	echo "2) 毎日実行"
	echo "3) 毎週実行"
	Ask "オプションを入力してください (1/2/3): " interval

	local random_minute=$(shuf -i 0-59 -n 1)
	# 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
	1) cron_time="$random_minute * * * *" ;; # 每小时，随机分钟执行
	2) cron_time="$random_minute 0 * * *" ;; # 每天，随机分钟执行
	3) cron_time="$random_minute 0 * * 1" ;; # 每周，随机分钟执行
	*)
		echo "エラー: 有効なオプションを入力してください！"
		return
		;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "エラー: このタスクの定期同期は既に存在します！"
		return
	fi

	# 创建到用户的 crontab
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "定期タスクを作成しました: $cron_job"
}

# 查看定时任务
view_tasks() {
	echo "現在の定期タスク："
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	Ask "削除するタスク番号を入力してください: " num
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		echo "エラー: 有効なタスク番号を入力してください！"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "タスク番号 $num の定期タスクを削除しました"
}

# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync リモート同期ツール"
		echo "リモートディレクトリ間の同期、増分同期をサポートし、効率的で安定しています。"
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 新しいタスクを作成します                 2. タスクを削除します"
		echo "3. ローカルからリモートへの同期を実行します         4. リモートからローカルへの同期を実行します"
		echo "5. 定期タスクを作成します               6. 定期タスクを削除します"
		echo "---------------------------------"
		echo "0. 前のメニューに戻る"
		echo "---------------------------------"
		Ask "Please enter your choice: " choice
		case $choice in
		1) add_task ;;
		2) delete_task ;;
		3) run_task push ;;
		4) run_task pull ;;
		5) schedule_task ;;
		6) delete_task_schedule ;;
		0) break ;;
		*) echo "無効な選択です。再試行してください。" ;;
		esac
		Press "Press Enter to continue..."
	done
}

linux_ps() {
	clear
	send_stats "系统信息查询"

	ip_address

	echo
	echo -e "システム情報クエリ"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ホスト名:       ${gl_bai}$(uname -n || hostname)"
	echo -e "${gl_kjlan}システムバージョン:     ${gl_bai}$(ChkOs)"
	echo -e "${gl_kjlan}Linuxバージョン:    ${gl_bai}$(uname -r)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPUアーキテクチャ:      ${gl_bai}$(uname -m)"
	echo -e "${gl_kjlan}CPUモデル:      ${gl_bai}$(CpuModel)"
	echo -e "${gl_kjlan}CPUコア数:    ${gl_bai}$(nproc)"
	echo -e "${gl_kjlan}CPU周波数:      ${gl_bai}$(CpuFreq)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU使用率:      ${gl_bai}$(CpuUsage)%"
	echo -e "${gl_kjlan}システム負荷:     ${gl_bai}$(LoadAvg)"
	echo -e "${gl_kjlan}物理メモリ:     ${gl_bai}$(MemUsage)"
	echo -e "${gl_kjlan}仮想メモリ:     ${gl_bai}$(SwapUsage)"
	echo -e "${gl_kjlan}ディスク使用率:     ${gl_bai}$(DiskUsage)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}総受信:       ${gl_bai}$(ConvSz $(Iface --rx_bytes))"
	echo -e "${gl_kjlan}総送信:       ${gl_bai}$(ConvSz $(Iface --tx_bytes))"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ネットワークアルゴリズム:     ${gl_bai}$(sysctl -n net.ipv4.tcp_congestion_control) $(sysctl -n net.core.default_qdisc)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}プロバイダー:       ${gl_bai}$(NetProv)"
	echo -e "${gl_kjlan}IPv4アドレス:     ${gl_bai}$(IpAddr --ipv4)"
	echo -e "${gl_kjlan}IPv6アドレス:     ${gl_bai}$(IpAddr --ipv6)"
	echo -e "${gl_kjlan}DNSアドレス:      ${gl_bai}$(DnsAddr)"
	echo -e "${gl_kjlan}地理的位置:     ${gl_bai}$(Loc --country)$(Loc --city)"
	echo -e "${gl_kjlan}システム時間:     ${gl_bai}$(TimeZn --internal)$(date +"%Y-%m-%d %H:%M:%S")"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}稼働時間:     ${gl_bai}$(uptime -p | sed 's/up //')"
	echo
}

linux_tools() {

	while true; do
		clear
		# send_stats "基础工具"
		echo -e "基本ツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}curl ダウンロードツール ${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget ダウンロードツール ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}3.   ${gl_bai}sudo スーパー管理権限ツール             ${gl_kjlan}4.   ${gl_bai}socat 通信接続ツール"
		echo -e "${gl_kjlan}5.   ${gl_bai}htop システム監視ツール                 ${gl_kjlan}6.   ${gl_bai}iftop ネットワークトラフィック監視ツール"
		echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP圧縮解凍ツール             ${gl_kjlan}8.   ${gl_bai}tar GZ圧縮解凍ツール"
		echo -e "${gl_kjlan}9.   ${gl_bai}tmux マルチバックグラウンド実行ツール             ${gl_kjlan}10.  ${gl_bai}ffmpeg 動画エンコードライブストリーミングプッシュツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}btop 近代的な監視ツール ${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ranger ファイル管理ツール"
		echo -e "${gl_kjlan}13.  ${gl_bai}ncdu ディスク使用量確認ツール             ${gl_kjlan}14.  ${gl_bai}fzf グローバル検索ツール"
		echo -e "${gl_kjlan}15.  ${gl_bai}vim テキストエディタ                    ${gl_kjlan}16.  ${gl_bai}nano テキストエディタ ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}17.  ${gl_bai}git バージョン管理システム"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}ハッカーズ・マトリックス風スクリーンセーバー                      ${gl_kjlan}22.  ${gl_bai}トレイン風スクリーンセーバー"
		echo -e "${gl_kjlan}26.  ${gl_bai}テトリス風ミニゲーム                  ${gl_kjlan}27.  ${gl_bai}スネーク風ミニゲーム"
		echo -e "${gl_kjlan}28.  ${gl_bai}スペースインベーダー風ミニゲーム"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}すべてインストール                          ${gl_kjlan}32.  ${gl_bai}すべてインストール（スクリーンセーバーとゲームを除く）${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}すべてアンインストール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}指定ツールをインストール                      ${gl_kjlan}42.  ${gl_bai}指定ツールをアンインストール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

		case $sub_choice in
		1)
			clear
			install curl
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
			curl --help
			send_stats "安装curl"
			;;
		2)
			clear
			install wget
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
			wget --help
			send_stats "安装wget"
			;;
		3)
			clear
			install sudo
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
			sudo --help
			send_stats "安装sudo"
			;;
		4)
			clear
			install socat
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
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
			echo "ツールがインストールされました。使用方法は以下の通りです。"
			unzip
			send_stats "安装unzip"
			;;
		8)
			clear
			install tar
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
			tar --help
			send_stats "安装tar"
			;;
		9)
			clear
			install tmux
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
			tmux --help
			send_stats "安装tmux"
			;;
		10)
			clear
			install ffmpeg
			clear
			echo "ツールがインストールされました。使用方法は以下の通りです。"
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
			Ask "インストールするツール名を入力してください（wget curl sudo htop）: " installname
			install $installname
			send_stats "安装指定软件"
			;;
		42)
			clear
			Ask "アンインストールするツール名を入力してください（htop ufw tmux cmatrix）: " removename
			remove $removename
			send_stats "卸载指定软件"
			;;

		0)
			kejilion
			;;

		*)
			echo "無効な入力!"
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
			echo "現在のTCP輻輳制御アルゴリズム: $congestion_algorithm $queue_algorithm"

			echo
			echo "BBR管理"
			echo "------------------------"
			echo "1. BBRv3を有効にする              2. BBRv3を無効にする（再起動します）"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			Ask "Please enter your choice: " sub_choice

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
		echo -e "${gl_kjlan}1.   ${gl_bai}Docker環境のインストール・更新 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}2.   ${gl_bai}Dockerグローバル状態の表示 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}Dockerコンテナ管理 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}4.   ${gl_bai}Dockerイメージ管理"
		echo -e "${gl_kjlan}5.   ${gl_bai}Dockerネットワーク管理"
		echo -e "${gl_kjlan}6.   ${gl_bai}Dockerボリューム管理"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}7.   ${gl_bai}未使用のDockerコンテナ、イメージ、ネットワーク、ボリュームをクリーンアップ"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}8.   ${gl_bai}Dockerソースの変更"
		echo -e "${gl_kjlan}9.   ${gl_bai}daemon.jsonファイルを編集"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}Docker-ipv6アクセスを有効にする"
		echo -e "${gl_kjlan}12.  ${gl_bai}Docker-ipv6アクセスを無効にする"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}20.  ${gl_bai}Docker環境のアンインストール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

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
			echo "Dockerバージョン"
			docker -v
			docker compose version

			echo
			echo -e "Dockerイメージ: ${gl_lv}$image_count${gl_bai} "
			docker image ls
			echo
			echo -e "Dockerコンテナ: ${gl_lv}$container_count${gl_bai}"
			docker ps -a
			echo
			echo -e "Dockerボリューム: ${gl_lv}$volume_count${gl_bai}"
			docker volume ls
			echo
			echo -e "Dockerネットワーク: ${gl_lv}$network_count${gl_bai}"
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
				echo "Dockerネットワークリスト"
				echo "------------------------------------------------------------"
				docker network ls
				echo

				echo "------------------------------------------------------------"
				container_ids=$(docker ps -q)
				echo "コンテナ名              ネットワーク名              IPアドレス"

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
				echo "ネットワーク操作"
				echo "------------------------"
				echo "1. ネットワークを作成します"
				echo "2. ネットワークに参加します"
				echo "3. ネットワークから退出します"
				echo "4. ネットワークを削除します"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " sub_choice

				case $sub_choice in
				1)
					send_stats "创建网络"
					Ask "新しいネットワーク名を設定します: " dockernetwork
					docker network create $dockernetwork
					;;
				2)
					send_stats "加入网络"
					Ask "ネットワーク名に参加します: " dockernetwork
					Ask "このネットワークに参加するコンテナを入力してください（複数のコンテナ名はスペースで区切ります）: " dockernames

					for dockername in $dockernames; do
						docker network connect $dockernetwork $dockername
					done
					;;
				3)
					send_stats "加入网络"
					Ask "ネットワークから退出します: " dockernetwork
					Ask "このネットワークから退出するコンテナを入力してください（複数のコンテナ名はスペースで区切ります）: " dockernames

					for dockername in $dockernames; do
						docker network disconnect $dockernetwork $dockername
					done

					;;

				4)
					send_stats "删除网络"
					Ask "削除するネットワーク名を入力してください: " dockernetwork
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
				echo "Dockerボリュームリスト"
				docker volume ls
				echo
				echo "ボリューム操作"
				echo "------------------------"
				echo "1. 新しいボリュームを作成します"
				echo "2. 指定したボリュームを削除します"
				echo "3. すべてのボリュームを削除します"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " sub_choice

				case $sub_choice in
				1)
					send_stats "新建卷"
					Ask "新しいボリューム名を設定します: " dockerjuan
					docker volume create $dockerjuan

					;;
				2)
					Ask "削除するボリューム名を入力してください（複数のボリューム名はスペースで区切ります）: " dockerjuans

					for dockerjuan in $dockerjuans; do
						docker volume rm $dockerjuan
					done

					;;

				3)
					send_stats "删除所有卷"
					Ask "${gl_hong}注意: ${gl_bai}未使用のボリュームをすべて削除しますか？(y/N): " choice
					case "$choice" in
					[Yy])
						docker volume prune -f
						;;
					[Nn]) ;;
					*)
						echo "無効な選択です。Y または N を入力してください。"
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
			Ask "${gl_huang}ヒント: ${gl_bai}停止中のコンテナを含む、不要なイメージコンテナネットワークをクリーンアップします。クリーンアップしますか？(y/N): " choice
			case "$choice" in
			[Yy])
				docker system prune -af --volumes
				;;
			[Nn]) ;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
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
			Ask "${gl_hong}注意: ${gl_bai}docker環境をアンマウントしますか？(y/N): " choice
			case "$choice" in
			[Yy])
				docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				remove docker docker-compose docker-ce docker-ce-cli containerd.io
				rm -f /etc/docker/daemon.json
				hash -r
				;;
			[Nn]) ;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;

		0)
			kejilion
			;;
		*)
			echo "無効な入力!"
			;;
		esac
		break_end

	done

}

linux_test() {

	while true; do
		clear
		# send_stats "测试脚本合集"
		echo -e "テストスクリプトコレクション"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}IPおよびアンロック状態の検出"
		echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT アンロック状態の検出"
		echo -e "${gl_kjlan}2.   ${gl_bai}Region ストリーミングアンロックテスト"
		echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu ストリーミングアンロック検出"
		echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP品質体检スクリプト ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}ネットワーク回線速度テスト"
		echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 3社バックエンド遅延ルーティングテスト"
		echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 3社バックエンド回線テスト"
		echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 3社速度テスト"
		echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 高速バックエンドテストスクリプト"
		echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 指定IPバックエンドテストスクリプト"
		echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 3社回線テスト"
		echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多機能速度テストスクリプト"
		echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality ネットワーク品質体检スクリプト ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}ハードウェアパフォーマンステスト"
		echo -e "${gl_kjlan}21.  ${gl_bai}yabs パフォーマンステスト"
		echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPUパフォーマンステストスクリプト"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}総合テスト"
		echo -e "${gl_kjlan}31.  ${gl_bai}bench パフォーマンステスト"
		echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 融合怪测评 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

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
			echo "参照可能なIPリスト"
			echo "------------------------"
			echo "北京テレコム: 219.141.136.12"
			echo "北京ユニコム: 202.106.50.1"
			echo "北京モバイル: 221.179.155.161"
			echo "上海テレコム: 202.96.209.133"
			echo "上海ユニコム: 210.22.97.1"
			echo "上海モバイル: 211.136.112.200"
			echo "広州テレコム: 58.60.188.222"
			echo "広州ユニコム: 210.21.196.6"
			echo "広州モバイル: 120.196.165.24"
			echo "成都テレコム: 61.139.2.69"
			echo "成都ユニコム: 119.6.6.6"
			echo "成都モバイル: 211.137.96.205"
			echo "湖南テレコム: 36.111.200.100"
			echo "湖南ユニコム: 42.48.16.100"
			echo "湖南モバイル: 39.134.254.6"
			echo "------------------------"

			Ask "指定したIPアドレスを入力してください: " testip
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
			echo "無効な入力!"
			;;
		esac
		break_end

	done

}

linux_Oracle() {

	while true; do
		clear
		send_stats "甲骨文云脚本合集"
		echo -e "Oracle Cloudスクリプトコレクション"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}アイドルマシンのアクティブスクリプトのインストール"
		echo -e "${gl_kjlan}2.   ${gl_bai}アイドルマシンのアクティブスクリプトのアンインストール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}DDシステム再インストールスクリプト"
		echo -e "${gl_kjlan}4.   ${gl_bai}R探長起動スクリプト"
		echo -e "${gl_kjlan}5.   ${gl_bai}ROOTパスワードログインモードの有効化"
		echo -e "${gl_kjlan}6.   ${gl_bai}IPV6復旧ツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

		case $sub_choice in
		1)
			clear
			echo "アクティブなスクリプト: CPU使用率10-20% メモリ使用率20% "
			Ask "インストールしますか？(y/N): " choice
			case "$choice" in
			[Yy])

				install_docker

				# 设置默认值
				local DEFAULT_CPU_CORE=1
				local DEFAULT_CPU_UTIL="10-20"
				local DEFAULT_MEM_UTIL=20
				local DEFAULT_SPEEDTEST_INTERVAL=120

				# 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				Ask "CPUコア数を入力してください [デフォルト: $DEFAULT_CPU_CORE]: " cpu_core
				local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				Ask "CPU使用率の範囲を入力してください（例: 10-20） [デフォルト: $DEFAULT_CPU_UTIL]: " cpu_util
				local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				Ask "メモリ使用率を入力してください [デフォルト: $DEFAULT_MEM_UTIL]: " mem_util
				local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				Ask "Speedtestの間隔（秒）を入力してください [デフォルト: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
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
				echo "無効な選択です。Y または N を入力してください。"
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
			echo "システム再インストール"
			echo "--------------------------------"
			echo -e "${gl_hong}注意: ${gl_bai}再インストールは接続不能のリスクがあります。ご心配な方は慎重にご利用ください。再インストールには約15分かかりますので、事前にデータのバックアップをお願いします。"
			Ask "続行しますか？(y/N): " choice

			case "$choice" in
			[Yy])
				while true; do
					Ask "再インストールするシステムを選択してください:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

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
						echo "無効な選択です。再入力してください。"
						;;
					esac
				done

				Ask "再インストール後のパスワードを入力してください: " vpspasswd
				install wget
				bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
				send_stats "甲骨文云重装系统脚本"
				;;
			[Nn])
				echo "キャンセルしました"
				;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;

		4)
			clear
			echo "この機能は開発中です。しばらくお待ちください！"
			;;
		5)
			clear
			add_sshpasswd

			;;
		6)
			clear
			bash <(curl -L -s jhb.ovh/jb/v6.sh)
			echo "この機能はjhb氏によって提供されました。感謝します！"
			send_stats "ipv6修复"
			;;
		0)
			kejilion

			;;
		*)
			echo "無効な入力!"
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
		echo -e "${gl_lv}環境はインストール済みです${gl_bai}  コンテナ: ${gl_lv}$container_count${gl_bai}  イメージ: ${gl_lv}$image_count${gl_bai}  ネットワーク: ${gl_lv}$network_count${gl_bai}  ボリューム: ${gl_lv}$volume_count${gl_bai}"
	fi
}

ldnmp_tato() {
	local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
	local output="サイト: ${gl_lv}${cert_count}${gl_bai}"

	local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
	if [ -n "$dbrootpasswd" ]; then
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
	fi

	local db_output="データベース: ${gl_lv}${db_count}${gl_bai}"

	if command -v docker &>/dev/null; then
		if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
			echo -e "${gl_huang}------------------------"
			echo -e "${gl_lv}環境はインストール済みです${gl_bai}  $output  $db_output"
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
		echo -e "${gl_huang}LDNMPサイト構築"
		ldnmp_tato
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}1.   ${gl_bai}LDNMP環境のインストール ${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}WordPressのインストール ${gl_huang}★${gl_bai}"
		echo -e "${gl_huang}3.   ${gl_bai}Discuzフォーラムのインストール                    ${gl_huang}4.   ${gl_bai}可道云デスクトップのインストール"
		echo -e "${gl_huang}5.   ${gl_bai}可道云CMS映画サイトのインストール                 ${gl_huang}6.   ${gl_bai}単角数カード発行サイトのインストール"
		echo -e "${gl_huang}7.   ${gl_bai}flarumフォーラムサイトのインストール                ${gl_huang}8.   ${gl_bai}typecho軽量ブログサイトのインストール"
		echo -e "${gl_huang}9.   ${gl_bai}LinkStack共有リンクプラットフォームのインストール         ${gl_huang}20.  ${gl_bai}カスタム動的サイト"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}21.  ${gl_bai}nginxのみインストール ${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}サイトリダイレクト"
		echo -e "${gl_huang}23.  ${gl_bai}サイトリバースプロキシ-IP+ポート ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}サイトリバースプロキシ-ドメイン名"
		echo -e "${gl_huang}25.  ${gl_bai}Bitwardenパスワード管理プラットフォームのインストール         ${gl_huang}26.  ${gl_bai}Haloブログサイトのインストール"
		echo -e "${gl_huang}27.  ${gl_bai}AIペイントプロンプトジェネレーターのインストール            ${gl_huang}28.  ${gl_bai}サイトリバースプロキシ-ロードバランシング"
		echo -e "${gl_huang}30.  ${gl_bai}カスタム静的サイト"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}31.  ${gl_bai}サイトデータ管理 ${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}全サイトデータのバックアップ"
		echo -e "${gl_huang}33.  ${gl_bai}定期リモートバックアップ                      ${gl_huang}34.  ${gl_bai}全サイトデータの復元"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}35.  ${gl_bai}LDNMP環境の保護                     ${gl_huang}36.  ${gl_bai}LDNMP環境の最適化"
		echo -e "${gl_huang}37.  ${gl_bai}LDNMP環境の更新                     ${gl_huang}38.  ${gl_bai}LDNMP環境のアンインストール"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_huang}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

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
			webname="Discuzフォーラム"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースアドレス: mysql"
			echo "データベース名: $dbname"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo "テーブルプレフィックス: discuz_"

			;;

		4)
			clear
			# 可道云桌面
			webname="Koodo Desktop"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースアドレス: mysql"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo "データベース名: $dbname"
			echo "redisホスト: redis"

			;;

		5)
			clear
			# 苹果CMS
			webname="AppleCMS"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースアドレス: mysql"
			echo "データベースポート: 3306"
			echo "データベース名: $dbname"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo "データベースプレフィックス: mac_"
			echo "------------------------"
			echo "インストール後にバックエンドにログインするアドレス"
			echo "https://$yuming/vip.php"

			;;

		6)
			clear
			# 独脚数卡
			webname="D-Jiao ShuKa"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースアドレス: mysql"
			echo "データベースポート: 3306"
			echo "データベース名: $dbname"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo
			echo "redisアドレス: redis"
			echo "redisパスワード: デフォルトでは何も入力しません"
			echo "redisポート: 6379"
			echo
			echo "ウェブサイトURL: https://$yuming"
			echo "バックエンドログインパス: /admin"
			echo "------------------------"
			echo "ユーザー名: admin"
			echo "パスワード: admin"
			echo "------------------------"
			echo "ログイン時に右上隅に赤いerror0が表示された場合は、次のコマンドを使用してください:"
			echo "なぜ独角数卡はこんなに面倒で、このような問題があるのか、私もとても腹が立ちます！"
			echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

			;;

		7)
			clear
			# flarum论坛
			webname="Flarumフォーラム"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースアドレス: mysql"
			echo "データベース名: $dbname"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo "テーブルプレフィックス: flarum_"
			echo "管理者情報はご自身で設定してください"

			;;

		8)
			clear
			# typecho
			webname="Typecho"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースプレフィックス: typecho_"
			echo "データベースアドレス: mysql"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo "データベース名: $dbname"

			;;

		9)
			clear
			# LinkStack
			webname="LinkStack"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo "データベースアドレス: mysql"
			echo "データベースポート: 3306"
			echo "データベース名: $dbname"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			;;

		20)
			clear
			webname="PHP動的サイト"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo -e "[${gl_huang}1/6${gl_bai}] PHPソースコードのアップロード"
			echo "-------------"
			echo "現在、zip形式のソースコードパッケージのみアップロードできます。ソースコードパッケージを/home/web/html/${yuming}ディレクトリに配置してください。"
			Ask "ダウンロードリンクを入力することもできます。ソースコードパッケージをリモートでダウンロードします。直接Enterを押すとリモートダウンロードはスキップされます： " url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/6${gl_bai}] index.phpのパス"
			echo "-------------"
			# find "$(realpath .)" -name "index.php" -print
			find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

			Ask "index.phpのパスを入力してください（例: /home/web/html/$yuming/wordpress/）： " index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}3/6${gl_bai}] PHPバージョンの選択"
			echo "-------------"
			Ask "1. 最新版PHP | 2. php7.4 : " pho_v
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
				echo "無効な選択です。再入力してください。"
				;;
			esac

			clear
			echo -e "[${gl_huang}4/6${gl_bai}] 指定された拡張機能のインストール"
			echo "-------------"
			echo "インストール済みの拡張機能"
			docker exec php php -m

			Ask "インストールする拡張機能名を入力してください。例: ${gl_huang}SourceGuardian imap ftp${gl_bai} など。直接Enterを押すとインストールはスキップされます： " php_extensions
			if [ -n "$php_extensions" ]; then
				docker exec $PHP_Version install-php-extensions $php_extensions
			fi

			clear
			echo -e "[${gl_huang}5/6${gl_bai}] サイト設定の編集"
			echo "-------------"
			Press "Press any key to continue to set site configuration in detail, such as pretty permalinks"
			install nano
			nano /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}6/6${gl_bai}] データベース管理"
			echo "-------------"
			Ask "1. 新しいサイトを構築する        2. データベースバックアップのある古いサイトを構築する： " use_db
			case $use_db in
			1)
				echo
				;;
			2)
				echo "データベースのバックアップは.gzで終わる圧縮ファイルである必要があります。/home/ディレクトリに配置してください。宝塔/1panelのバックアップデータインポートをサポートしています。"
				Ask "バックアップデータをリモートでダウンロードすることもできます。直接Enterを押すとリモートダウンロードはスキップされます： " url_download_db

				cd /home/
				if [ -n "$url_download_db" ]; then
					wget "$url_download_db"
				fi
				gunzip $(ls -t *.gz | head -n 1)
				latest_sql=$(ls -t *.sql | head -n 1)
				dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname <"/home/$latest_sql"
				echo "データベースインポートテーブルデータ"
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
				rm -f *.sql
				echo "データベースのインポートが完了しました"
				;;
			*)
				echo
				;;
			esac

			docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

			restart_ldnmp
			ldnmp_web_on
			prefix="web$(shuf -i 10-99 -n 1)_"
			echo "データベースアドレス: mysql"
			echo "データベース名: $dbname"
			echo "ユーザー名: $dbuse"
			echo "パスワード: $dbusepasswd"
			echo "テーブルプレフィックス: $prefix"
			echo "管理者ログイン情報はご自身で設定してください"

			;;

		21)
			ldnmp_install_status_one
			nginx_install_all
			;;

		22)
			clear
			webname="サイトリダイレクト"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
			add_yuming
			Ask "リダイレクトドメイン名を入力してください: " reverseproxy
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
			webname="リバースプロキシ - ドメイン名"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
			add_yuming
			echo -e "ドメイン名形式: ${gl_huang}google.com${gl_bai}"
			Ask "プロキシドメイン名を入力してください: " fandai_yuming
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
			echo "$webname のデプロイを開始します"
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
			echo "$webname のデプロイを開始します"
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
			webname="AIプロンプトジェネレーター"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			webname="静的サイト"
			send_stats "安装$webname"
			echo "$webname のデプロイを開始します"
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
			echo -e "[${gl_huang}1/2${gl_bai}] 静的ソースコードのアップロード"
			echo "-------------"
			echo "現在、zip形式のソースコードパッケージのみアップロードできます。ソースコードパッケージを/home/web/html/${yuming}ディレクトリに配置してください。"
			Ask "ダウンロードリンクを入力することもできます。ソースコードパッケージをリモートでダウンロードします。直接Enterを押すとリモートダウンロードはスキップされます： " url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/2${gl_bai}] index.htmlのパス"
			echo "-------------"
			# find "$(realpath .)" -name "index.html" -print
			find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

			Ask "index.htmlのパスを入力してください（例: /home/web/html/$yuming/index/）： " index_lujing

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
			echo -e "${gl_huang}バックアップ中 $backup_filename ...${gl_bai}"
			cd /home/ && tar czvf "$backup_filename" web

			while true; do
				clear
				echo "バックアップファイルが作成されました: /home/$backup_filename"
				Ask "バックアップデータをリモートサーバーに転送しますか？(y/N): " choice
				case "$choice" in
				[Yy])
					Ask "リモートサーバーのIPアドレスを入力してください:  " remote_ip
					if [ -z "$remote_ip" ]; then
						echo "エラー: リモートサーバーのIPを入力してください。"
						continue
					fi
					local latest_tar=$(ls -t /home/*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
						echo "ファイルはリモートサーバーのhomeディレクトリに転送されました。"
					else
						echo "転送するファイルが見つかりませんでした。"
					fi
					break
					;;
				[Nn])
					break
					;;
				*)
					echo "無効な選択です。Y または N を入力してください。"
					;;
				esac
			done
			;;

		33)
			clear
			send_stats "定时远程备份"
			Ask "リモートサーバーのIPアドレスを入力してください: " useip
			Ask "リモートサーバーのパスワードを入力してください: " usepasswd

			cd ~
			wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh >/dev/null 2>&1
			chmod +x ${useip}_beifen.sh

			sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
			sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

			echo "------------------------"
			echo "1. 週次バックアップ                 2. 日次バックアップ"
			Ask "Please enter your choice: " dingshi

			case $dingshi in
			1)
				check_crontab_installed
				Ask "毎週バックアップする曜日を選択してください (0-6、0は日曜日): " weekday
				(
					crontab -l
					echo "0 0 * * $weekday ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			2)
				check_crontab_installed
				Ask "毎日バックアップする時間を選択してください（時、0-23）: " hour
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
			echo "利用可能なサイトバックアップ"
			echo "-------------------------"
			ls -lt /home/*.gz | awk '{print $NF}'
			echo
			Ask "Enterキーで最新のバックアップを復元します。バックアップファイル名を入力して指定したバックアップを復元します。0を入力すると終了します：" filename

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

				echo -e "${gl_huang}解凍中 $filename ...${gl_bai}"
				cd /home/ && tar -xzf "$filename"

				check_port
				install_dependency
				install_docker
				install_certbot
				install_ldnmp
			else
				echo "圧縮ファイルが見つかりませんでした。"
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
				echo "LDNMP環境の更新"
				echo "------------------------"
				ldnmp_v
				echo "新しいバージョンのコンポーネントが見つかりました"
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
				echo "1. nginxの更新               2. mysqlの更新              3. phpの更新              4. redisの更新"
				echo "------------------------"
				echo "5. 環境全体の更新"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " sub_choice
				case $sub_choice in
				1)
					nginx_upgrade

					;;

				2)
					local ldnmp_pods="mysql"
					Ask "${ldnmp_pods}のバージョン番号を入力してください（例: 8.0 8.3 8.4 9.0）（Enterで最新版を取得）: " version
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
					echo "更新${ldnmp_pods}が完了しました"

					;;
				3)
					local ldnmp_pods="php"
					Ask "${ldnmp_pods}のバージョン番号を入力してください（例: 7.4 8.0 8.1 8.2 8.3）（Enterで最新版を取得）: " version
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
					echo "更新${ldnmp_pods}が完了しました"

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
					echo "更新${ldnmp_pods}が完了しました"

					;;
				5)
					Ask "${gl_huang}ヒント: ${gl_bai}長期間環境を更新していないユーザーは、LDNMP環境の更新に慎重になってください。データベース更新失敗のリスクがあります。LDNMP環境を更新しますか？(y/N): " choice
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
			Ask "${gl_hong}強く推奨: ${gl_bai}すべてのウェブサイトデータをバックアップしてから、LDNMP環境をアンインストールしてください。すべてのウェブサイトデータを削除しますか？(y/N): " choice
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
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;

		0)
			kejilion
			;;

		*)
			echo "無効な入力!"
			;;
		esac
		break_end

	done

}

linux_panel() {

	while true; do
		clear
		# send_stats "应用市场"
		echo -e "アプリマーケット"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}宝塔パネル公式版                      ${gl_kjlan}2.   ${gl_bai}aaPanel宝塔国際版"
		echo -e "${gl_kjlan}3.   ${gl_bai}1Panel次世代管理パネル                ${gl_kjlan}4.   ${gl_bai}NginxProxyManagerビジュアルパネル"
		echo -e "${gl_kjlan}5.   ${gl_bai}OpenListマルチストレージファイルリストプログラム          ${gl_kjlan}6.   ${gl_bai}UbuntuリモートデスクトップWeb版"
		echo -e "${gl_kjlan}7.   ${gl_bai}哪吒探针VPS監視パネル                 ${gl_kjlan}8.   ${gl_bai}QBオフラインBTマグネットダウンロードパネル"
		echo -e "${gl_kjlan}9.   ${gl_bai}Poste.ioメールサーバープログラム              ${gl_kjlan}10.  ${gl_bai}RocketChatマルチユーザーオンラインチャットシステム"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}禅道プロジェクト管理ソフトウェア                    ${gl_kjlan}12.  ${gl_bai}青龙パネル定期タスク管理プラットフォーム"
		echo -e "${gl_kjlan}13.  ${gl_bai}Cloudreveストレージ ${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}シンプルな画像アップローダー画像管理プログラム"
		echo -e "${gl_kjlan}15.  ${gl_bai}embyマルチメディア管理システム                  ${gl_kjlan}16.  ${gl_bai}Speedtest速度テストパネル"
		echo -e "${gl_kjlan}17.  ${gl_bai}AdGuardHome広告除去ソフトウェア               ${gl_kjlan}18.  ${gl_bai}onlyofficeオンラインオフィスOFFICE"
		echo -e "${gl_kjlan}19.  ${gl_bai}雷池WAFファイアウォールパネル                   ${gl_kjlan}20.  ${gl_bai}portainerコンテナ管理パネル"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}VScode Web版                        ${gl_kjlan}22.  ${gl_bai}UptimeKuma監視ツール"
		echo -e "${gl_kjlan}23.  ${gl_bai}Memos Webメモ                     ${gl_kjlan}24.  ${gl_bai}WebtopリモートデスクトップWeb版 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}25.  ${gl_bai}Nextcloudストレージ                       ${gl_kjlan}26.  ${gl_bai}QD-Today定期タスク管理フレームワーク"
		echo -e "${gl_kjlan}27.  ${gl_bai}Dockgeコンテナスタック管理パネル              ${gl_kjlan}28.  ${gl_bai}LibreSpeed速度テストツール"
		echo -e "${gl_kjlan}29.  ${gl_bai}searxng集約検索サイト ${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}PhotoPrismプライベートアルバムシステム"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}StirlingPDFツール大全                 ${gl_kjlan}32.  ${gl_bai}drawio無料オンライン図表ソフトウェア ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}Sun-Panelナビゲーションパネル                   ${gl_kjlan}34.  ${gl_bai}Pingvin-Shareファイル共有プラットフォーム"
		echo -e "${gl_kjlan}35.  ${gl_bai}ミニマルな朋友圈                          ${gl_kjlan}36.  ${gl_bai}LobeChat AIチャット集約サイト"
		echo -e "${gl_kjlan}37.  ${gl_bai}MyIPツールボックス ${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}小雅alistフルセット"
		echo -e "${gl_kjlan}39.  ${gl_bai}Bililiveライブストリーム録画ツール                ${gl_kjlan}40.  ${gl_bai}webssh Web版SSH接続ツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}耗子管理パネル                \t ${gl_kjlan}42.  ${gl_bai}Nextermリモート接続ツール"
		echo -e "${gl_kjlan}43.  ${gl_bai}RustDeskリモートデスクトップ(サーバー側) ${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}RustDeskリモートデスクトップ(中継側) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}45.  ${gl_bai}Docker加速站            \t\t ${gl_kjlan}46.  ${gl_bai}GitHub加速站 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}47.  ${gl_bai}Prometheus監視\t\t\t ${gl_kjlan}48.  ${gl_bai}Prometheus(ホスト監視)"
		echo -e "${gl_kjlan}49.  ${gl_bai}Prometheus(コンテナ監視)\t\t ${gl_kjlan}50.  ${gl_bai}補充監視ツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}51.  ${gl_bai}PVE小鸡面板\t\t\t ${gl_kjlan}52.  ${gl_bai}DPanelコンテナ管理パネル"
		echo -e "${gl_kjlan}53.  ${gl_bai}llama3チャットAI大規模モデル                  ${gl_kjlan}54.  ${gl_bai}AMHホストサイト構築管理パネル"
		echo -e "${gl_kjlan}55.  ${gl_bai}FRP内部ネットワーク貫通(サーバー側) ${gl_huang}★${gl_bai}\t         ${gl_kjlan}56.  ${gl_bai}FRP内部ネットワーク貫通(クライアント側) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}57.  ${gl_bai}DeepseekチャットAI大規模モデル                ${gl_kjlan}58.  ${gl_bai}Dify大規模モデル知識ベース ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}59.  ${gl_bai}NewAPI大規模モデル資産管理                ${gl_kjlan}60.  ${gl_bai}JumpServerオープンソース堡塁機"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}61.  ${gl_bai}オンライン翻訳サーバー\t\t\t ${gl_kjlan}62.  ${gl_bai}RAGFlow大規模モデル知識ベース"
		echo -e "${gl_kjlan}63.  ${gl_bai}OpenWebUIセルフホストAIプラットフォーム ${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}it-toolsツールボックス"
		echo -e "${gl_kjlan}65.  ${gl_bai}n8n自動ワークフロープラットフォーム ${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}yt-dlp動画ダウンロードツール"
		echo -e "${gl_kjlan}67.  ${gl_bai}ddns-go動的DNS管理ツール ${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${gl_bai}AllinSSL証明書管理プラットフォーム"
		echo -e "${gl_kjlan}69.  ${gl_bai}SFTPGoファイル転送ツール                  ${gl_kjlan}70.  ${gl_bai}AstrBotチャットボットフレームワーク"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}71.  ${gl_bai}Navidromeプライベート音楽サーバー             ${gl_kjlan}72.  ${gl_bai}bitwardenパスワードマネージャー ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}73.  ${gl_bai}LibreTVプライベートビデオ                     ${gl_kjlan}74.  ${gl_bai}MoonTVプライベートビデオ"
		echo -e "${gl_kjlan}75.  ${gl_bai}Melodyミュージックエルフ                      ${gl_kjlan}76.  ${gl_bai}オンラインDOSレトロゲーム"
		echo -e "${gl_kjlan}77.  ${gl_bai}迅雷オフラインダウンロードツール                    ${gl_kjlan}78.  ${gl_bai}PandaWikiインテリジェントドキュメント管理システム"
		echo -e "${gl_kjlan}79.  ${gl_bai}Beszelサーバー監視"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

		case $sub_choice in
		1)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="宝塔面板"
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

			local docker_describe="Nginxリバースプロキシツールパネル、ドメイン名でのアクセスはサポートされていません。"
			local docker_url="公式サイト紹介: https://nginxproxymanager.com/"
			local docker_use='echo "初期ユーザー名: admin@example.com"'
			local docker_passwd='echo "初期パスワード: changeme"'
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

			local docker_describe="GinとSolidjsで駆動される、複数のストレージをサポートし、ウェブブラウジングとWebDAVをサポートするファイルリストプログラム"
			local docker_url="公式サイト紹介: https://github.com/OpenListTeam/OpenList"
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

			local docker_describe="webtopはUbuntuベースのコンテナです。IPでアクセスできない場合は、ドメイン名を追加してアクセスしてください。"
			local docker_url="公式サイト紹介: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use='echo "ユーザー名: ubuntu-abc"'
			local docker_passwd='echo "パスワード: ubuntuABC123"'
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
				echo -e "Nezha監視 $check_docker $update_status"
				echo "オープンソースで軽量、使いやすいサーバー監視・運用管理ツール"
				echo "公式ドキュメント: https://nezha.wiki/guide/dashboard.html"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo
				echo "------------------------"
				echo "1. 使用方法"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " choice

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

			local docker_describe="qbittorrentオフラインBTマグネットダウンロードサービス"
			local docker_url="公式サイト紹介: https://hub.docker.com/r/linuxserver/qbittorrent"
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
				echo -e "郵便局サービス $check_docker $update_status"
				echo "poste.io はオープンソースのメールサーバーソリューションです。"
				echo "ビデオ紹介: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo
				echo "ポートチェック"
				port=25
				timeout=3
				if echo "終了" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
					echo -e "${gl_lv}ポート $port 現在利用可能${gl_bai}"
				else
					echo -e "${gl_hong}ポート $port 現在利用不可${gl_bai}"
				fi
				echo

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "アクセスアドレス: "
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. インストール           2. 更新           3. アンインストール"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " choice

				case $choice in
				1)
					check_disk_space 2
					Ask "メールドメイン名を設定してください。例: mail.yuming.com : " yuming
					mkdir -p /home/docker
					echo "$yuming" >/home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "これらのDNSレコードを先に解析してください"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo
					echo "------------------------"
					Press "Press any key to continue..."

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
					echo "poste.ioのインストールが完了しました"
					echo "------------------------"
					echo "poste.ioには以下のURLでアクセスできます:"
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
					echo "poste.ioのインストールが完了しました"
					echo "------------------------"
					echo "poste.ioには以下のURLでアクセスできます:"
					echo "https://$yuming"
					echo
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail
					echo "アプリケーションはアンインストールされました"
					;;

				*)
					break
					;;

				esac
				break_end
			done

			;;

		10)

			local app_name="Rocket.Chatチャットシステム"
			local app_text="Rocket.Chatは、リアルタイムチャット、オーディオ/ビデオ通話、ファイル共有などの複数の機能に対応したオープンソースのチームコミュニケーションプラットフォームです。"
			local app_url="公式紹介: https://www.rocket.chat/"
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
				echo "インストールが完了しました"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "rocket.chatのインストールが完了しました"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "アプリケーションはアンインストールされました"
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

			local docker_describe="禅道は汎用的なプロジェクト管理ソフトウェアです"
			local docker_url="公式サイト紹介: https://www.zentao.net/"
			local docker_use='echo "初期ユーザー名: admin"'
			local docker_passwd='echo "初期パスワード: 123456"'
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

			local docker_describe="青龙パネルは定期的なタスク管理プラットフォームです"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		13)

			local app_name="cloudreveクラウドストレージ"
			local app_text="cloudreveは、複数のクラウドストレージに対応したクラウドストレージシステムです。"
			local app_url="ビデオ紹介: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
				echo "インストールが完了しました"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "アプリケーションはアンインストールされました"
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

			local docker_describe="Simple Image Bedはシンプルな画像アップロードプログラムです"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/icret/EasyImages2.0"
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

			local docker_describe="Embyはクライアントデバイスにオーディオとビデオをストリーミングするために使用できる、サーバー上のビデオとオーディオを整理するためのクライアント・サーバー型メディアサーバーソフトウェアです"
			local docker_url="公式サイト紹介: https://emby.media/"
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

			local docker_describe="Speedtestスピードテストパネルは、VPSのネットワーク速度テストツールであり、複数のテスト機能があり、VPSの送受信トラフィックをリアルタイムで監視することもできます"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/wikihost-opensource/als"
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

			local docker_describe="AdGuardHomeは、ネットワーク全体の広告ブロックおよびアンチトラッキングソフトウェアであり、将来的には単なるDNSサーバー以上のものになります。"
			local docker_url="公式サイト紹介: https://hub.docker.com/r/adguard/adguardhome"
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

			local docker_describe="OnlyOfficeはオープンソースのオンラインオフィスツールで、非常に強力です！"
			local docker_url="公式サイト紹介: https://www.onlyoffice.com/"
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
				echo -e "Nezhaサービス $check_docker"
				echo "雷池は長亭科技が開発したWAFサイトファイアウォールプログラムパネルで、サイトをプロキシして自動防御を行うことができます。"
				echo "ビデオ紹介: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo

				echo "------------------------"
				echo "1. インストール           2. 更新           3. パスワードリセット           4. アンインストール"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " choice

				case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
					clear
					echo "雷池WAFパネルのインストールが完了しました"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo
					clear
					echo "雷池WAFパネルの更新が完了しました"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all
					echo "デフォルトのインストールディレクトリを使用していた場合、プロジェクトはアンインストールされました。カスタムインストールディレクトリを使用していた場合は、インストールディレクトリに移動して実行してください:"
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

			local docker_describe="Portainerは軽量なDockerコンテナ管理パネルです"
			local docker_url="公式サイト紹介: https://www.portainer.io/"
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

			local docker_describe="VScodeは強力なオンラインコード編集ツールです"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/coder/code-server"
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

			local docker_describe="Uptime Kuma使いやすいセルフホスト型監視ツール"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/louislam/uptime-kuma"
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

			local docker_describe="Memosは軽量でセルフホスト型のメモ中心ツールです"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/usememos/memos"
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

			local docker_describe="webtopはAlpineベースの中国語版コンテナです。IPでアクセスできない場合は、ドメイン名を追加してアクセスしてください。"
			local docker_url="公式サイト紹介: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use='echo "ユーザー名: webtop-abc"'
			local docker_passwd='echo "パスワード: webtopABC123"'
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

			local docker_describe="Nextcloudは400,000以上のデプロイメントを持ち、ダウンロードできる最も人気のあるローカルコンテンツコラボレーションプラットフォームです"
			local docker_url="公式サイト紹介: https://nextcloud.com/"
			local docker_use="echo \\\"アカウント: nextcloud  パスワード: $rootpasswd\\\""
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

			local docker_describe="QD-TodayはHTTPリクエストの定期的なタスク自動実行フレームワークです"
			local docker_url="公式サイト紹介: https://qd-today.github.io/qd/zh_CN/"
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

			local docker_describe="DockgeはビジュアルなDocker Composeコンテナ管理パネルです"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/louislam/dockge"
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

			local docker_describe="LibrespeedはJavaScriptで実装された軽量スピードテストツールで、すぐに使用できます"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/librespeed/speedtest"
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

			local docker_describe="SearxNGはプライベートでプライバシー重視の検索エンジンサイトです"
			local docker_url="公式サイト紹介: https://hub.docker.com/r/alandoyle/searxng"
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

			local docker_describe="PhotoPrismは非常に強力なプライベートフォトアルバムシステムです"
			local docker_url="公式サイト紹介: https://www.photoprism.app/"
			local docker_use="echo \\\"アカウント: admin  パスワード: $rootpasswd\\\""
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

			local docker_describe="これは強力なローカルホスト型WebベースPDF操作ツールで、Dockerを使用しており、PDFファイルの分割・結合、変換、再編成、画像追加、回転、圧縮などのさまざまな操作を実行できます。"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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

			local docker_describe="これは強力なチャート描画ソフトウェアです。マインドマップ、トポロジー図、フローチャートを描画できます"
			local docker_url="公式サイト紹介: https://www.drawio.com/"
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

			local docker_describe="Sun-Panelサーバー、NASナビゲーションパネル、Homepage、ブラウザホームページ"
			local docker_url="公式サイト紹介: https://doc.sun-panel.top/zh_cn/"
			local docker_use='echo "アカウント: admin@sun.cc  パスワード: 12345678"'
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

			local docker_describe="Pingvin Shareはセルフホスト可能なファイル共有プラットフォームで、WeTransferの代替品です"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/stonith404/pingvin-share"
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

			local docker_describe="ミニマルな朋友圈、WeChat朋友圈にそっくりで、あなたの素晴らしい生活を記録します"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use='echo "アカウント: admin  パスワード: a123456"'
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

			local docker_describe="LobeChatは、ChatGPT/Claude/Gemini/Groq/Ollamaなどの主要なAI大規模モデルを統合しています"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/lobehub/lobe-chat"
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

			local docker_describe="これは多機能IPツールボックスで、自分のIP情報や接続性を確認でき、Webページパネルで表示します"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
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

			local docker_describe="Bililive-goは、複数のライブストリーミングプラットフォームをサポートするライブストリーミング録画ツールです"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

			local docker_describe="シンプルなオンラインSSH接続ツールとSFTPツール"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		41)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="耗子面板"
			local panelurl="公式アドレス: ${gh_proxy}github.com/TheTNB/panel"

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

			local docker_describe="Nextermは強力なオンラインSSH/VNC/RDP接続ツールです。"
			local docker_url="公式サイト紹介: ${gh_proxy}github.com/gnmyt/Nexterm"
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

			local docker_describe="RustDeskはオープンソースのリモートデスクトップ（サーバー側）で、独自の向日葵プライベートサーバーに似ています。"
			local docker_url="公式サイト紹介: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd='echo "IPとキーを記録してください。リモートデスクトップクライアントで使用します。44番オプションでリレーノードをインストールしてください！"'
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

			local docker_describe="RustDeskはオープンソースのリモートデスクトップ（中継側）で、独自の向日葵プライベートサーバーに似ています。"
			local docker_url="公式サイト紹介: https://rustdesk.com/zh-cn/"
			local docker_use='echo "リモートデスクトップクライアントを公式サイトからダウンロード: https://rustdesk.com/zh-cn/"'
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

			local docker_describe="Docker Registryは、Dockerイメージを保存および配布するためのサービスです。"
			local docker_url="公式サイト紹介: https://hub.docker.com/_/registry"
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

			local docker_describe="Goで実装されたGHProxyで、一部の地域のGitHubリポジトリのプルを高速化するために使用されます。"
			local docker_url="公式サイト紹介: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		47)

			local app_name="Prometheus監視"
			local app_text="Prometheus+Grafanaエンタープライズ級監視システム"
			local app_url="公式サイト紹介: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
				echo "インストールが完了しました"
				check_docker_app_ip
				echo "初期ユーザー名とパスワードは両方とも: admin"
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
				echo "アプリケーションはアンインストールされました"
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

			local docker_describe="これはPrometheusのホストデータ収集コンポーネントで、監視対象のホストにデプロイする必要があります。"
			local docker_url="公式サイト紹介: https://github.com/prometheus/node_exporter"
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

			local docker_describe="これはPrometheusのコンテナデータ収集コンポーネントで、監視対象のホストにデプロイする必要があります。"
			local docker_url="公式サイト紹介: https://github.com/google/cadvisor"
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

			local docker_describe="これはウェブサイトの変更検出、在庫監視、通知を行う小さなツールです"
			local docker_url="公式サイト紹介: https://github.com/dgtlmoon/changedetection.io"
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

			local docker_describe="Docker可視化パネルシステムで、完全なDocker管理機能を提供します。"
			local docker_url="公式サイト紹介: https://github.com/donknap/dpanel"
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

			local docker_describe="OpenWebUIは、新しいllama3大規模言語モデルに接続する大規模言語モデルWebフレームワークです"
			local docker_url="公式サイト紹介: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3.2:1b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		54)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="AMHパネル"
			local panelurl="公式アドレス: https://amh.sh/index.htm?amh"

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

			local docker_describe="OpenWebUIは、新しいDeepSeek R1大規模言語モデルに接続する大規模言語モデルWebフレームワークです"
			local docker_url="公式サイト紹介: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		58)
			local app_name="Difyナレッジベース"
			local app_text="オープンソースの大規模言語モデル(LLM)アプリケーション開発プラットフォームです。セルフホストされたトレーニングデータを使用してAI生成を行います。"
			local app_url="公式サイト: https://docs.dify.ai/zh-hans"
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
				echo "インストールが完了しました"
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
				echo "アプリケーションはアンインストールされました"
			}

			docker_app_plus

			;;

		59)
			local app_name="New API"
			local app_text="次世代大規模モデルゲートウェイおよびAI資産管理システム"
			local app_url="公式サイト: https://github.com/Calcium-Ion/new-api"
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
				echo "インストールが完了しました"
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
				echo "インストールが完了しました"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "アプリケーションはアンインストールされました"
			}

			docker_app_plus

			;;

		60)

			local app_name="JumpServerオープンソース堡垒機"
			local app_text="特権アクセス管理 (PAM) のオープンソースツールです。このプログラムはポート80を占有しており、ドメイン名でのアクセスはサポートされていません。"
			local app_url="公式紹介: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
				echo "インストールが完了しました"
				check_docker_app_ip
				echo "初期ユーザー名: admin"
				echo "初期パスワード: ChangeMe"
			}

			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "アプリケーションが更新されました"
			}

			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "アプリケーションはアンインストールされました"
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

			local docker_describe="無料オープンソース機械翻訳API、完全にセルフホスト可能、その翻訳エンジンはオープンソースArgos Translateライブラリによってサポートされています。"
			local docker_url="公式サイト紹介: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		62)
			local app_name="RAGFlowナレッジベース"
			local app_text="深層文書理解に基づくオープンソースRAG（Retrieval Augmented Generation）エンジン"
			local app_url="公式サイト: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
				clear
				echo "インストールが完了しました"
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
				echo "アプリケーションはアンインストールされました"
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

			local docker_describe="OpenWebUIは、主要なモデルAPI接続をサポートする、公式に簡略化された大規模言語モデルWebフレームワークです"
			local docker_url="公式サイト紹介: https://github.com/open-webui/open-webui"
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

			local docker_describe="開発者やIT担当者にとって非常に便利なツール"
			local docker_url="公式サイト紹介: https://github.com/CorentinTh/it-tools"
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

			local docker_describe="強力な自動ワークフロープラットフォームです"
			local docker_url="公式サイト紹介: https://github.com/n8n-io/n8n"
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

			local docker_describe="あなたのパブリックIP（IPv4/IPv6）を主要なDNSプロバイダーにリアルタイムで自動更新し、動的DNS解決を実現します。"
			local docker_url="公式サイト紹介: https://github.com/jeessy2/ddns-go"
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

			local docker_describe="オープンソース無料SSL証明書自動管理プラットフォーム"
			local docker_url="公式サイト紹介: https://allinssl.com"
			local docker_use='echo "セキュアな入り口: /allinssl"'
			local docker_passwd='echo "ユーザー名: allinssl  パスワード: allinssldocker"'
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

			local docker_describe="オープンソース無料いつでもどこでもSFTP FTP WebDAVファイル転送ツール"
			local docker_url="公式サイト紹介: https://sftpgo.com/"
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

			local docker_describe="オープンソースAIチャットボットフレームワーク、WeChat、QQ、TGのAI大規模モデル接続をサポート"
			local docker_url="公式サイト紹介: https://astrbot.app/"
			local docker_use='echo "ユーザー名: astrbot  パスワード: astrbot"'
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

			local docker_describe="軽量で高性能な音楽ストリーミングサーバーです"
			local docker_url="公式サイト紹介: https://www.navidrome.org/"
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

			local docker_describe="あなたがデータを制御できるパスワードマネージャー"
			local docker_url="公式サイト紹介: https://bitwarden.com/"
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

				Ask "LibreTVのログインパスワードを設定します: " app_passwd

				docker run -d \
					--name libretv \
					--restart unless-stopped \
					-p ${docker_port}:8080 \
					-e PASSWORD=${app_passwd} \
					bestzwei/libretv:latest

			}

			local docker_describe="無料オンラインビデオ検索および視聴プラットフォーム"
			local docker_url="公式サイト紹介: https://github.com/LibreSpark/LibreTV"
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

				Ask "MoonTVのログインパスワードを設定します: " app_passwd

				docker run -d \
					--name moontv \
					--restart unless-stopped \
					-p ${docker_port}:3000 \
					-e PASSWORD=${app_passwd} \
					ghcr.io/senshinya/moontv:latest

			}

			local docker_describe="無料オンラインビデオ検索および視聴プラットフォーム"
			local docker_url="公式サイト紹介: https://github.com/senshinya/MoonTV"
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

			local docker_describe="あなたの音楽の精霊、音楽をより良く管理するのに役立つことを目指しています。"
			local docker_url="公式サイト紹介: https://github.com/foamzou/melody"
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

			local docker_describe="中国語DOSゲームコレクションサイトです"
			local docker_url="公式サイト紹介: https://github.com/rwv/chinese-dos-games"
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

				Ask "${docker_name}のログインユーザー名を設定します: " app_use
				Ask "${docker_name}のログインパスワードを設定します: " app_passwd

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

			local docker_describe="迅雷あなたのオフライン高速BTマグネットダウンロードツール"
			local docker_url="公式サイト紹介: https://github.com/cnk3x/xunlei"
			local docker_use='echo "迅雷に携帯でログインし、招待コードを入力してください。招待コード: 迅雷牛通"'
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		78)

			local app_name="PandaWiki"
			local app_text="PandaWikiは、AI大規模モデル駆動型のオープンソースインテリジェントドキュメント管理システムです。カスタムポートでのデプロイは強く推奨されません。"
			local app_url="公式紹介: https://github.com/chaitin/PandaWiki"
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

			local docker_describe="Beszel軽量で使いやすいサーバー監視"
			local docker_url="公式サイト紹介: https://beszel.dev/zh/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		0)
			kejilion
			;;
		*)
			echo "無効な入力!"
			;;
		esac
		break_end

	done
}

linux_work() {

	while true; do
		clear
		send_stats "后台工作区"
		echo -e "バックグラウンドワークスペース"
		echo -e "システムはバックグラウンドで常駐実行できるワークスペースを提供します。長時間タスクの実行に使用できます。"
		echo -e "SSHを切断しても、ワークスペース内のタスクは中断されません。バックグラウンド常駐タスク。"
		echo -e "${gl_huang}ヒント: ${gl_bai}ワークスペースに入ったらCtrl+bを押し、次にdを単独で押して終了してください！"
		echo -e "${gl_kjlan}------------------------"
		echo "現在存在するワークスペースのリスト"
		echo -e "${gl_kjlan}------------------------"
		tmux list-sessions
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}ワークスペース1"
		echo -e "${gl_kjlan}2.   ${gl_bai}ワークスペース2"
		echo -e "${gl_kjlan}3.   ${gl_bai}ワークスペース3"
		echo -e "${gl_kjlan}4.   ${gl_bai}ワークスペース4"
		echo -e "${gl_kjlan}5.   ${gl_bai}ワークスペース5"
		echo -e "${gl_kjlan}6.   ${gl_bai}ワークスペース6"
		echo -e "${gl_kjlan}7.   ${gl_bai}ワークスペース7"
		echo -e "${gl_kjlan}8.   ${gl_bai}ワークスペース8"
		echo -e "${gl_kjlan}9.   ${gl_bai}ワークスペース9"
		echo -e "${gl_kjlan}10.  ${gl_bai}ワークスペース10"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}SSH常駐モード ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}22.  ${gl_bai}ワークスペースの作成/入室"
		echo -e "${gl_kjlan}23.  ${gl_bai}バックグラウンドワークスペースにコマンドを注入"
		echo -e "${gl_kjlan}24.  ${gl_bai}指定したワークスペースを削除"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

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
					local tmux_sshd_status="${gl_lv}有効${gl_bai}"
				else
					local tmux_sshd_status="${gl_hui}無効${gl_bai}"
				fi
				send_stats "SSH常驻模式 "
				echo -e "SSH常駐モード $tmux_sshd_status"
				echo "有効にすると、SSH接続後に常駐モードに入り、以前の作業状態に戻ることができます。"
				echo "------------------------"
				echo "1. 有効にする            2. 無効にする"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " gongzuoqu_del
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
			Ask "作成または参加するワークスペース名を入力してください。例: 1001 kj001 work1: " SESSION_NAME
			tmux_run
			send_stats "自定义工作区"
			;;

		23)
			Ask "バックグラウンドで実行するコマンドを入力してください。例: curl -fsSL https://get.docker.com | sh: " tmuxd
			tmux_run_d
			send_stats "注入命令到后台工作区"
			;;

		24)
			Ask "削除するワークスペース名を入力してください: " gongzuoqu_name
			tmux kill-window -t $gongzuoqu_name
			send_stats "删除工作区"
			;;

		0)
			kejilion
			;;
		*)
			echo "無効な入力!"
			;;
		esac
		break_end

	done

}

linux_Settings() {

	while true; do
		clear
		# send_stats "系统工具"
		echo -e "システムツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}スクリプト起動ショートカットキーの設定                 ${gl_kjlan}2.   ${gl_bai}ログインパスワードの変更"
		echo -e "${gl_kjlan}3.   ${gl_bai}ROOTパスワードログインモード                   ${gl_kjlan}4.   ${gl_bai}Pythonの特定バージョンのインストール"
		echo -e "${gl_kjlan}5.   ${gl_bai}全ポートを開放                       ${gl_kjlan}6.   ${gl_bai}SSH接続ポートの変更"
		echo -e "${gl_kjlan}7.   ${gl_bai}DNSアドレスの最適化                        ${gl_kjlan}8.   ${gl_bai}ワンクリックシステム再インストール ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}9.   ${gl_bai}ROOTアカウントによる新規アカウント作成を無効化             ${gl_kjlan}10.  ${gl_bai}IPv4/IPv6の優先切り替え"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}ポート使用状況の確認                   ${gl_kjlan}12.  ${gl_bai}仮想メモリサイズの変更"
		echo -e "${gl_kjlan}13.  ${gl_bai}ユーザー管理                           ${gl_kjlan}14.  ${gl_bai}ユーザー/パスワードジェネレーター"
		echo -e "${gl_kjlan}15.  ${gl_bai}システムタイムゾーン調整                       ${gl_kjlan}16.  ${gl_bai}BBR3アクセラレーションの設定"
		echo -e "${gl_kjlan}17.  ${gl_bai}ファイアウォール高度マネージャー                   ${gl_kjlan}18.  ${gl_bai}ホスト名の変更"
		echo -e "${gl_kjlan}19.  ${gl_bai}システムアップデートソースの切り替え                     ${gl_kjlan}20.  ${gl_bai}定期タスク管理"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}ローカルホスト解析                       ${gl_kjlan}22.  ${gl_bai}SSH防御プログラム"
		echo -e "${gl_kjlan}23.  ${gl_bai}レート制限自動シャットダウン                       ${gl_kjlan}24.  ${gl_bai}ROOTプライベートキーログインモード"
		echo -e "${gl_kjlan}25.  ${gl_bai}TG-botシステム監視アラート                 ${gl_kjlan}26.  ${gl_bai}OpenSSHの重大な脆弱性（岫源）の修正"
		echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat系Linuxカーネルアップグレード                ${gl_kjlan}28.  ${gl_bai}Linuxシステムカーネルパラメータ最適化 ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}29.  ${gl_bai}ウイルススキャンツール ${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}ファイルマネージャー"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}システム言語の切り替え                       ${gl_kjlan}32.  ${gl_bai}コマンドライン美化ツール ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}システムゴミ箱の設定                     ${gl_kjlan}34.  ${gl_bai}システムバックアップと復元"
		echo -e "${gl_kjlan}35.  ${gl_bai}sshリモート接続ツール                    ${gl_kjlan}36.  ${gl_bai}ディスクパーティション管理ツール"
		echo -e "${gl_kjlan}37.  ${gl_bai}コマンド履歴                     ${gl_kjlan}38.  ${gl_bai}rsyncリモート同期ツール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}掲示板                             ${gl_kjlan}66.  ${gl_bai}ワンストップシステムチューニング ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}99.  ${gl_bai}サーバーの再起動                         ${gl_kjlan}100. ${gl_bai}プライバシーとセキュリティ"
		echo -e "${gl_kjlan}101. ${gl_bai}kコマンドの上級使い方 ${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}科技lionスクリプトのアンインストール"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

		case $sub_choice in
		1)
			while true; do
				clear
				Ask "ショートカットキーを入力してください（0を入力すると終了）: " kuaijiejian
				if [ "$kuaijiejian" == "0" ]; then
					break_end
					linux_Settings
				fi
				find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				echo "ショートカットキーが設定されました"
				send_stats "脚本快捷键已设置"
				break_end
				linux_Settings
			done
			;;

		2)
			clear
			send_stats "设置你的登录密码"
			echo "ログインパスワードを設定してください"
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
			echo "Pythonバージョン管理"
			echo "ビデオ紹介: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "この機能により、Python公式がサポートするあらゆるバージョンをシームレスにインストールできます！"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "現在のPythonバージョン: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推奨バージョン:  3.12    3.11    3.10    3.9    3.8    2.7"
			echo "その他のバージョンを確認: https://www.python.org/downloads/"
			echo "------------"
			Ask "インストールするpythonのバージョン番号を入力してください（0を入力すると終了）: " py_new_v

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
					echo "不明なパッケージマネージャー！"
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
			echo -e "現在のPythonバージョン: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			;;

		5)
			root_use
			send_stats "开放端口"
			iptables_open
			remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
			echo "ポートはすべて開かれています"

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
				echo -e "現在のSSHポート番号は:  ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "ポート番号の範囲は1から65535の数字です。（0を入力すると終了）"

				# 提示用户输入新的 SSH 端口号
				Ask "新しいSSHポート番号を入力してください: " new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "ポート番号が無効です。1から65535の間の数字を入力してください。"
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "無効な入力です。数字を入力してください。"
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
			Ask "新しいユーザー名を入力してください（0を入力すると終了）: " new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "操作が完了しました。"
			;;

		10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "v4/v6優先度を設定"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "現在のネットワーク優先度設定: ${gl_huang}IPv4${gl_bai} 優先"
				else
					echo -e "現在のネットワーク優先度設定: ${gl_huang}IPv6${gl_bai} 優先"
				fi
				echo
				echo "------------------------"
				echo "1. IPv4優先          2. IPv6優先          3. IPv6修復ツール"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "優先するネットワークを選択してください: " choice

				case $choice in
				1)
					sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
					echo "IPv4優先に切り替えました"
					send_stats "已切换为 IPv4 优先"
					;;
				2)
					sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
					echo "IPv6優先に切り替えました"
					send_stats "已切换为 IPv6 优先"
					;;

				3)
					clear
					bash <(curl -L -s jhb.ovh/jb/v6.sh)
					echo "この機能はjhb氏によって提供されました。感謝します！"
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
				echo "仮想メモリを設定"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "現在の仮想メモリ: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 1024Mを割り当てる         2. 2048Mを割り当てる         3. 4096Mを割り当てる         4. カスタムサイズ"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " choice

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
					Ask "仮想メモリサイズを入力してください（単位M）: " new_swap
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
				echo "ユーザーリスト"
				echo "----------------------------------------------------------------------------"
				echo "ユーザー名                ユーザー権限                       ユーザーグループ            sudo権限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done </etc/passwd

				echo
				echo "アカウント操作"
				echo "------------------------"
				echo "1. 一般アカウントを作成             2. 上級アカウントを作成"
				echo "------------------------"
				echo "3. 最高権限を付与             4. 最高権限を剥奪"
				echo "------------------------"
				echo "5. アカウントを削除"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " sub_choice

				case $sub_choice in
				1)
					# 提示用户输入新用户名
					Ask "新しいユーザー名を入力してください: " new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					echo "操作が完了しました。"
					;;

				2)
					# 提示用户输入新用户名
					Ask "新しいユーザー名を入力してください: " new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					# 赋予新用户sudo权限
					echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					echo "操作が完了しました。"

					;;
				3)
					Ask "ユーザー名を入力してください: " username
					# 赋予新用户sudo权限
					echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
					;;
				4)
					Ask "ユーザー名を入力してください: " username
					# 从sudoers文件中移除用户的sudo权限
					sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

					;;
				5)
					Ask "削除するユーザー名を入力してください: " username
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
			echo "ランダムなユーザー名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(</dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "ランダムなユーザー名 $i: $username"
			done

			echo
			echo "ランダムな名前"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "ランダムなユーザー名 $i: $user_name"
			done

			echo
			echo "ランダムなUUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "ランダムなUUID $i: $uuid"
			done

			echo
			echo "16桁のランダムパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "ランダムパスワード $i: $password"
			done

			echo
			echo "32桁のランダムパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "ランダムパスワード $i: $password"
			done
			echo

			;;

		15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "システム時刻情報"

				# 显示时区和时间
				echo "現在のシステムタイムゾーン：$(TimeZn)"
				echo "現在のシステム時刻：$(date +"%Y-%m-%d %H:%M:%S")"

				echo
				echo "タイムゾーン切り替え"
				echo "------------------------"
				echo "アジア"
				echo "1.  中国上海時間             2.  中国香港時間"
				echo "3.  日本東京時間             4.  韓国ソウル時間"
				echo "5.  シンガポール時間               6.  インドコルカタ時間"
				echo "7.  UAEドバイ時間           8.  オーストラリアシドニー時間"
				echo "9.  タイバンコク時間"
				echo "------------------------"
				echo "ヨーロッパ"
				echo "11. イギリスロンドン時間             12. フランスパリ時間"
				echo "13. ドイツベルリン時間             14. ロシアモスクワ時間"
				echo "15. オランダユトレヒト時間       16. スペインマドリード時間"
				echo "------------------------"
				echo "アメリカ"
				echo "21. アメリカ西部時間             22. アメリカ東部時間"
				echo "23. カナダ時間               24. メキシコ時間"
				echo "25. ブラジル時間                 26. アルゼンチン時間"
				echo "------------------------"
				echo "31. UTC世界標準時間"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " sub_choice

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
				echo -e "現在のホスト名: ${gl_huang}$current_hostname${gl_bai}"
				echo "------------------------"
				Ask "新しいホスト名を入力してください（0を入力すると終了）: " new_hostname
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

					echo "ホスト名が変更されました: $new_hostname"
					send_stats "主机名已更改"
					sleep 1
				else
					echo "終了しました。ホスト名は変更されていません。"
					break
				fi
			done
			;;

		19)
			root_use
			send_stats "换系统更新源"
			clear
			echo "更新ソース領域の選択"
			echo "LinuxMirrors切り替えシステム更新ソースへのアクセス"
			echo "------------------------"
			echo "1. 中国大陸【デフォルト】          2. 中国大陸【教育ネットワーク】          3. 海外地域"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			Ask "Please enter your choice: " choice

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
				echo "キャンセルしました"
				;;

			esac

			;;

		20)
			send_stats "定时任务管理"
			while true; do
				clear
				check_crontab_installed
				clear
				echo "定期タスクリスト"
				crontab -l
				echo
				echo "操作"
				echo "------------------------"
				echo "1. 定期タスクの追加              2. 定期タスクの削除              3. 定期タスクの編集"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " sub_choice

				case $sub_choice in
				1)
					Ask "新しいタスクの実行コマンドを入力してください: " newquest
					echo "------------------------"
					echo "1. 月次タスク                 2. 週次タスク"
					echo "3. 日次タスク                 4. 時間タスク"
					echo "------------------------"
					Ask "Please enter your choice: " dingshi

					case $dingshi in
					1)
						Ask "タスクを実行する月の日を選択してください？ (1-30): " day
						(
							crontab -l
							echo "0 0 $day * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					2)
						Ask "タスクを実行する曜日を選択してください (0-6、0は日曜日): " weekday
						(
							crontab -l
							echo "0 0 * * $weekday $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					3)
						Ask "タスクを実行する時間を選択してください（時、0-23）: " hour
						(
							crontab -l
							echo "0 $hour * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					4)
						Ask "タスクを実行する毎時の何分かを入力してください（分、0-60）: " minute
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
					Ask "削除するタスクのキーワードを入力してください: " kquest
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
				echo "ローカルホスト解析リスト"
				echo "ここに解析マッチを追加すると、動的解析は使用されなくなります"
				cat /etc/hosts
				echo
				echo "操作"
				echo "------------------------"
				echo "1. 新しい解析の追加              2. 解析アドレスの削除"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " host_dns

				case $host_dns in
				1)
					Ask "新しい解析レコードを入力してください フォーマット: 110.25.5.33 kejilion.pro : " addhost
					echo "$addhost" >>/etc/hosts
					send_stats "本地host解析新增"

					;;
				2)
					Ask "削除する解析内容のキーワードを入力してください: " delhost
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
					echo -e "SSH防御プログラム $check_docker"
					echo "fail2banはSSHのブルートフォース攻撃防止ツールです"
					echo "公式サイト紹介: ${gh_proxy}github.com/fail2ban/fail2ban"
					echo "------------------------"
					echo "1. 防御プログラムのインストール"
					echo "------------------------"
					echo "2. SSHブロック記録の表示"
					echo "3. ログのリアルタイム監視"
					echo "------------------------"
					echo "9. 防御プログラムのアンインストール"
					echo "------------------------"
					echo "0. 前のメニューに戻る"
					echo "------------------------"
					Ask "Please enter your choice: " sub_choice
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
						echo "Fail2Ban防御プログラムがアンインストールされました"
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
				echo "トラフィック制限シャットダウン機能"
				echo "ビデオ紹介: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "現在のトラフィック使用状況、サーバー再起動でトラフィック計算はリセットされます！"
				echo -e "${gl_kjlan}総受信: ${gl_bai}$(ConvSz $(Iface --rx_bytes))"
				echo -e "${gl_kjlan}総送信: ${gl_bai}$(ConvSz $(Iface --tx_bytes))"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}現在設定されている受信トラフィック制限しきい値は: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}現在設定されている送信トラフィック制限しきい値は: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}現在、トラフィック制限シャットダウン機能は有効になっていません${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "システムは毎分実際のトラフィックが閾値に達したかどうかを検出します。達した場合、サーバーは自動的にシャットダウンされます！"
				echo "------------------------"
				echo "1. トラフィック制限シャットダウン機能の有効化          2. トラフィック制限シャットダウン機能の無効化"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " Limiting

				case "$Limiting" in
				1)
					# 输入新的虚拟内存大小
					echo "実際のサーバーが100Gのトラフィックしかない場合、閾値を95Gに設定すると、トラフィック誤差やオーバーフローを避けるために早期にシャットダウンできます。"
					Ask "受信トラフィックのしきい値を入力してください（単位はG、デフォルト100G）: " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					Ask "送信トラフィックのしきい値を入力してください（単位はG、デフォルト100G）: " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					Ask "トラフィックリセット日を入力してください（デフォルトは毎月1日）: " cz_day
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
					echo "トラフィック制限シャットダウンが設定されました"
					send_stats "限流关机已设置"
					;;
				2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "トラフィック制限シャットダウン機能は無効化されました"
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
				echo "ROOT秘密鍵ログインモード"
				echo "ビデオ紹介: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
				echo "------------------------------------------------"
				echo "鍵ペアが生成され、より安全な方法でSSHログインできます"
				echo "------------------------"
				echo "1. 新しい鍵の生成              2. 既存の鍵のインポート              3. ローカル鍵の表示"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				Ask "Please enter your choice: " host_dns

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
					echo "公開鍵情報"
					cat ~/.ssh/authorized_keys
					echo "------------------------"
					echo "秘密鍵情報"
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
			echo "TG-bot監視アラート機能"
			echo "ビデオ紹介: https://youtu.be/vLL-eb3Z_TY"
			echo "------------------------------------------------"
			echo "tgボットAPIとアラート受信ユーザーIDを設定することで、ローカルCPU、メモリ、ディスク、トラフィック、SSHログインのリアルタイム監視アラートを実現できます"
			echo "閾値に達するとユーザーにアラートメッセージが送信されます"
			echo -e "${gl_hui}トラフィックについて、サーバーを再起動すると再計算されます-${gl_bai}"
			Ask "続行しますか？(y/N): " choice

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
				echo "TG-botアラートシステムが起動しました"
				echo -e "${gl_hui}rootディレクトリのTG-check-notify.shアラートファイルを他のマシンに配置して直接使用することもできます！${gl_bai}"
				;;
			[Nn])
				echo "キャンセルしました"
				;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
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
			echo "科技lion掲示板は公式コミュニティに移行しました！公式コミュニティでメッセージを残してください！"
			echo "https://bbs.kejilion.pro/"
			;;

		66)

			root_use
			send_stats "一条龙调优"
			echo "ワンストップシステムチューニング"
			echo "------------------------------------------------"
			echo "以下の内容を操作・最適化します"
			echo "1. システムを最新版に更新"
			echo "2. システムの不要ファイルをクリーンアップ"
			echo -e "3. 仮想メモリを${gl_huang}1G${gl_bai}に設定"
			echo -e "4. SSHポート番号を${gl_huang}5522${gl_bai}に設定"
			echo -e "5. 全ポートを開放"
			echo -e "6. ${gl_huang}BBR${gl_bai}アクセラレーションを有効化"
			echo -e "7. タイムゾーンを${gl_huang}上海${gl_bai}に設定"
			echo -e "8. DNSアドレスの自動最適化${gl_huang}海外: 1.1.1.1 8.8.8.8  国内: 223.5.5.5 ${gl_bai}"
			echo -e "9. 基本ツールをインストール${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			echo -e "10. Linuxシステムカーネルパラメータ最適化を${gl_huang}バランス最適化モード${gl_bai}に切り替え"
			echo "------------------------------------------------"
			Ask "ワンクリックメンテナンスを実行しますか？(y/N): " choice

			case "$choice" in
			[Yy])
				clear
				send_stats "一条龙调优启动"
				echo "------------------------------------------------"
				linux_update
				echo -e "[${gl_lv}OK${gl_bai}] 1/10. システムを最新に更新"

				echo "------------------------------------------------"
				linux_clean
				echo -e "[${gl_lv}OK${gl_bai}] 2/10. システムのジャンクファイルをクリーンアップ"

				echo "------------------------------------------------"
				add_swap 1024
				echo -e "[${gl_lv}OK${gl_bai}] 3/10. 仮想メモリを${gl_huang}1G${gl_bai}に設定"

				echo "------------------------------------------------"
				local new_port=5522
				new_ssh_port
				echo -e "[${gl_lv}OK${gl_bai}] 4/10. SSHポート番号を${gl_huang}5522${gl_bai}に設定"
				echo "------------------------------------------------"
				echo -e "[${gl_lv}OK${gl_bai}] 5/10. 全ポートを開放"

				echo "------------------------------------------------"
				bbr_on
				echo -e "[${gl_lv}OK${gl_bai}] 6/10. ${gl_huang}BBR${gl_bai}アクセラレーションを有効化"

				echo "------------------------------------------------"
				set_timedate Asia/Shanghai
				echo -e "[${gl_lv}OK${gl_bai}] 7/10. タイムゾーンを${gl_huang}上海${gl_bai}に設定"

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
				echo -e "[${gl_lv}OK${gl_bai}] 8/10. DNSアドレスの自動最適化${gl_huang}${gl_bai}"

				echo "------------------------------------------------"
				install_docker
				install wget sudo tar unzip socat btop nano vim
				echo -e "[${gl_lv}OK${gl_bai}] 9/10. 基本ツールをインストール${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				echo "------------------------------------------------"

				echo "------------------------------------------------"
				optimize_balanced
				echo -e "[${gl_lv}OK${gl_bai}] 10/10. Linuxシステムカーネルパラメータ最適化"
				echo -e "${gl_lv}ワンストップシステムチューニングが完了しました${gl_bai}"

				;;
			[Nn])
				echo "キャンセルしました"
				;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
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

				echo "プライバシーとセキュリティ"
				echo "スクリプトはユーザーの使用機能データを収集し、スクリプト体験を最適化し、より楽しく便利な機能を作成します"
				echo "スクリプトバージョン番号、使用時間、システムバージョン、CPUアーキテクチャ、マシンが属する国、および使用機能の名前を収集します。"
				echo "------------------------------------------------"
				echo -e "現在の状態: $status_message"
				echo "--------------------"
				echo "1. 収集を有効にする"
				echo "2. 収集を無効にする"
				echo "--------------------"
				echo "0. 前のメニューに戻る"
				echo "--------------------"
				Ask "Please enter your choice: " sub_choice
				case $sub_choice in
				1)
					cd ~
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					echo "収集が有効になりました"
					send_stats "隐私与安全已开启采集"
					;;
				2)
					cd ~
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					echo "収集が無効になりました"
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
			echo "科技lionスクリプトのアンインストール"
			echo "------------------------------------------------"
			echo "kejilionスクリプトを完全にアンインストールします。他の機能には影響しません。"
			Ask "続行しますか？(y/N): " choice

			case "$choice" in
			[Yy])
				clear
				(crontab -l | grep -v "kejilion.sh") | crontab -
				rm -f /usr/local/bin/k
				rm ~/kejilion.sh
				echo "スクリプトはアンインストールされました。さようなら！"
				break_end
				clear
				exit
				;;
			[Nn])
				echo "キャンセルしました"
				;;
			*)
				echo "無効な選択です。Y または N を入力してください。"
				;;
			esac
			;;

		0)
			kejilion

			;;
		*)
			echo "無効な入力!"
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
		echo "ファイルマネージャー"
		echo "------------------------"
		echo "現在のパス"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1.  ディレクトリに入る           2.  ディレクトリを作成             3.  ディレクトリ権限の変更         4.  ディレクトリ名の変更"
		echo "5.  ディレクトリの削除           6.  一つ上のメニューディレクトリに戻る"
		echo "------------------------"
		echo "11. ファイルを作成           12. ファイルを編集             13. ファイル権限の変更         14. ファイル名の変更"
		echo "15. ファイルの削除"
		echo "------------------------"
		echo "21. ファイル/ディレクトリの圧縮       22. ファイル/ディレクトリの解凍         23. ファイル/ディレクトリの移動         24. ファイル/ディレクトリのコピー"
		echo "25. ファイルを他のサーバーに転送"
		echo "------------------------"
		echo "0.  一つ上のメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " Limiting

		case "$Limiting" in
		1)
			# 进入目录
			Ask "ディレクトリ名を入力してください: " dirname
			cd "$dirname" 2>/dev/null || echo "ディレクトリに入れません"
			send_stats "进入目录"
			;;
		2)
			# 创建目录
			Ask "作成するディレクトリ名を入力してください: " dirname
			mkdir -p "$dirname" && echo "ディレクトリが作成されました" || echo "作成に失敗しました"
			send_stats "创建目录"
			;;
		3)
			# 修改目录权限
			Ask "ディレクトリ名を入力してください: " dirname
			Ask "権限を入力してください (例: 755): " perm
			chmod "$perm" "$dirname" && echo "権限が変更されました" || echo "変更に失敗しました"
			send_stats "修改目录权限"
			;;
		4)
			# 重命名目录
			Ask "現在のディレクトリ名を入力してください: " current_name
			Ask "新しいディレクトリ名を入力してください: " new_name
			mv "$current_name" "$new_name" && echo "ディレクトリ名が変更されました" || echo "名前の変更に失敗しました"
			send_stats "重命名目录"
			;;
		5)
			# 删除目录
			Ask "削除するディレクトリ名を入力してください: " dirname
			rm -rf "$dirname" && echo "ディレクトリが削除されました" || echo "削除に失敗しました"
			send_stats "删除目录"
			;;
		6)
			# 返回上一级选单目录
			cd ..
			send_stats "返回上一级选单目录"
			;;
		11)
			# 创建文件
			Ask "作成するファイル名を入力してください: " filename
			touch "$filename" && echo "ファイルが作成されました" || echo "作成に失敗しました"
			send_stats "创建文件"
			;;
		12)
			# 编辑文件
			Ask "編集するファイル名を入力してください: " filename
			install nano
			nano "$filename"
			send_stats "编辑文件"
			;;
		13)
			# 修改文件权限
			Ask "ファイル名を入力してください: " filename
			Ask "権限を入力してください (例: 755): " perm
			chmod "$perm" "$filename" && echo "権限が変更されました" || echo "変更に失敗しました"
			send_stats "修改文件权限"
			;;
		14)
			# 重命名文件
			Ask "現在のファイル名を入力してください: " current_name
			Ask "新しいファイル名を入力してください: " new_name
			mv "$current_name" "$new_name" && echo "ファイル名が変更されました" || echo "名前の変更に失敗しました"
			send_stats "重命名文件"
			;;
		15)
			# 删除文件
			Ask "削除するファイル名を入力してください: " filename
			rm -f "$filename" && echo "ファイルが削除されました" || echo "削除に失敗しました"
			send_stats "删除文件"
			;;
		21)
			# 压缩文件/目录
			Ask "圧縮するファイル/ディレクトリ名を入力してください: " name
			install tar
			tar -czvf "$name.tar.gz" "$name" && echo "$name.tar.gzに圧縮されました" || echo "圧縮に失敗しました"
			send_stats "压缩文件/目录"
			;;
		22)
			# 解压文件/目录
			Ask "解凍するファイル名を入力してください (.tar.gz): " filename
			install tar
			tar -xzvf "$filename" && echo "$filenameが解凍されました" || echo "解凍に失敗しました"
			send_stats "解压文件/目录"
			;;

		23)
			# 移动文件或目录
			Ask "移動するファイルまたはディレクトリのパスを入力してください: " src_path
			if [ ! -e "$src_path" ]; then
				echo "エラー: ファイルまたはディレクトリが存在しません。"
				send_stats "移动文件或目录失败: 文件或目录不存在"
				continue
			fi

			Ask "宛先パスを入力してください（新しいファイル名またはディレクトリ名を含む）: " dest_path
			if [ -z "$dest_path" ]; then
				echo "エラー: 宛先パスを入力してください。"
				send_stats "移动文件或目录失败: 目标路径未指定"
				continue
			fi

			mv "$src_path" "$dest_path" && echo "ファイルまたはディレクトリが $dest_path に移動されました" || echo "ファイルまたはディレクトリの移動に失敗しました"
			send_stats "移动文件或目录"
			;;

		24)
			# 复制文件目录
			Ask "コピーするファイルまたはディレクトリのパスを入力してください: " src_path
			if [ ! -e "$src_path" ]; then
				echo "エラー: ファイルまたはディレクトリが存在しません。"
				send_stats "复制文件或目录失败: 文件或目录不存在"
				continue
			fi

			Ask "宛先パスを入力してください（新しいファイル名またはディレクトリ名を含む）: " dest_path
			if [ -z "$dest_path" ]; then
				echo "エラー: 宛先パスを入力してください。"
				send_stats "复制文件或目录失败: 目标路径未指定"
				continue
			fi

			# 使用 -r 选项以递归方式复制目录
			cp -r "$src_path" "$dest_path" && echo "ファイルまたはディレクトリが $dest_path にコピーされました" || echo "ファイルまたはディレクトリのコピーに失敗しました"
			send_stats "复制文件或目录"
			;;

		25)
			# 传送文件至远端服务器
			Ask "転送するファイルパスを入力してください: " file_to_transfer
			if [ ! -f "$file_to_transfer" ]; then
				echo "エラー: ファイルが存在しません。"
				send_stats "传送文件失败: 文件不存在"
				continue
			fi

			Ask "リモートサーバーのIPを入力してください: " remote_ip
			if [ -z "$remote_ip" ]; then
				echo "エラー: リモートサーバーのIPを入力してください。"
				send_stats "传送文件失败: 未输入远端服务器IP"
				continue
			fi

			Ask "リモートサーバーのユーザー名を入力してください (デフォルト: root): " remote_user
			remote_user=${remote_user:-root}

			Ask "リモートサーバーのパスワードを入力してください: " -s remote_password
			echo
			if [ -z "$remote_password" ]; then
				echo "エラー: リモートサーバーのパスワードを入力してください。"
				send_stats "传送文件失败: 未输入远端服务器密码"
				continue
			fi

			Ask "ログインポートを入力してください (デフォルト: 22): " remote_port
			remote_port=${remote_port:-22}

			# 清除已知主机的旧条目
			ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			sleep 2 # 等待时间

			# 使用scp传输文件
			NO_TRAN=$'echo "$remote_password" | scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/"'
			eval "$NO_TRAN"

			if [ $? -eq 0 ]; then
				echo "ファイルはリモートサーバーのhomeディレクトリに転送されました。"
				send_stats "文件传送成功"
			else
				echo "ファイルの転送に失敗しました。"
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
			echo "無効な選択です。再入力してください。"
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
		echo -e "${gl_huang}$name ($hostname) に接続中...${gl_bai}"
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
		echo "サーバークラスター制御"
		cat ~/cluster/servers.py
		echo
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}サーバーリスト管理${gl_bai}"
		echo -e "${gl_kjlan}1.  ${gl_bai}サーバーを追加               ${gl_kjlan}2.  ${gl_bai}サーバーを削除            ${gl_kjlan}3.  ${gl_bai}サーバーを編集"
		echo -e "${gl_kjlan}4.  ${gl_bai}クラスターをバックアップ                 ${gl_kjlan}5.  ${gl_bai}クラスターを復元"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}バッチタスク実行${gl_bai}"
		echo -e "${gl_kjlan}11. ${gl_bai}科技lionスクリプトをインストール         ${gl_kjlan}12. ${gl_bai}システムを更新              ${gl_kjlan}13. ${gl_bai}システムをクリーンアップ"
		echo -e "${gl_kjlan}14. ${gl_bai}dockerをインストール               ${gl_kjlan}15. ${gl_bai}BBR3をインストール              ${gl_kjlan}16. ${gl_bai}1G仮想メモリを設定"
		echo -e "${gl_kjlan}17. ${gl_bai}タイムゾーンを上海に設定           ${gl_kjlan}18. ${gl_bai}全ポートを開放\t       ${gl_kjlan}51. ${gl_bai}カスタムコマンド"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.  ${gl_bai}メインメニューに戻る"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " sub_choice

		case $sub_choice in
		1)
			send_stats "添加集群服务器"
			Ask "サーバー名: " server_name
			Ask "サーバーIP: " server_ip
			Ask "サーバーポート（22）: " server_port
			local server_port=${server_port:-22}
			Ask "サーバーユーザー名（root）: " server_username
			local server_username=${server_username:-root}
			Ask "サーバーユーザーパスワード: " server_password

			sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			;;
		2)
			send_stats "删除集群服务器"
			Ask "削除するキーワードを入力してください: " rmserver
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
			echo -e " ${gl_huang}/root/cluster/servers.py${gl_bai} ファイルをダウンロードしてバックアップを完了してください！"
			break_end
			;;

		5)
			clear
			send_stats "还原集群"
			echo "servers.pyをアップロードしてください。任意のキーを押すとアップロードを開始します！"
			echo -e " ${gl_huang}servers.py${gl_bai} ファイルを ${gl_huang}/root/cluster/${gl_bai} にアップロードして復元を完了してください！"
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
			Ask "バッチ実行するコマンドを入力してください: " mingling
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
	echo "広告セクション"
	echo "------------------------"
	echo "ユーザーによりシンプルでエレガントなプロモーションと購入体験を提供します！"
	echo
	echo -e "サーバー特別オファー"
	echo "------------------------"
	echo -e "${gl_lan}ライカクラウド 香港CN2 GIA 韓国デュアルISP 米国CN2 GIA 特別オファー${gl_bai}"
	echo -e "${gl_bai}URL: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}RackNerd $10.99/year USA 1 Core 1GB RAM 20GB SSD 1TB Traffic/month${gl_bai}"
	echo -e "${gl_bai}URL: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}Hostinger $52.7/year USA 1 Core 4GB RAM 50GB SSD 4TB Traffic/month${gl_bai}"
	echo -e "${gl_bai}URL: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
	echo "------------------------"
	echo -e "${gl_huang}Bawagong $49/quarter USA CN2GIA Japan SoftBank 2 Core 1GB RAM 20GB SSD 1TB Traffic/month${gl_bai}"
	echo -e "${gl_bai}URL: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}DMIT $28/quarter USA CN2GIA 1 Core 2GB RAM 20GB SSD 800GB Traffic/month${gl_bai}"
	echo -e "${gl_bai}URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}V.PS $6.9/month Tokyo SoftBank 2 Core 1GB RAM 20GB SSD 1TB Traffic/month${gl_bai}"
	echo -e "${gl_bai}URL: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}More popular VPS discounts${gl_bai}"
	echo -e "${gl_bai}URL: https://kejilion.pro/topvps/${gl_bai}"
	echo "------------------------"
	echo
	echo -e "Domain Discounts"
	echo "------------------------"
	echo -e "${gl_lan}GNAME $8.8 first year for COM domain, $6.68 first year for CC domain${gl_bai}"
	echo -e "${gl_bai}URL: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
	echo "------------------------"
	echo
	echo -e "Kejilion Peripherals"
	echo "------------------------"
	echo -e "${gl_kjlan}Bilibili: ${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}YouTube: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
	echo -e "${gl_kjlan}Official Website: ${gl_bai}https://kejilion.pro/              ${gl_kjlan}Navigation: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
	echo -e "${gl_kjlan}Blog: ${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}Software Center: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}Script Official Website: ${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub Address: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
	echo "------------------------"
	echo
}

kejilion_update() {

	send_stats "脚本更新"
	cd ~
	while true; do
		clear
		echo "更新ログ"
		echo "------------------------"
		echo "全ログ: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
		echo "------------------------"

		curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
		local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

		if [ "$sh_v" = "$sh_v_new" ]; then
			echo -e "${gl_lv}You are already on the latest version!${gl_huang}v$sh_v${gl_bai}"
			send_stats "脚本已经最新了，无需更新"
		else
			echo "新バージョンが見つかりました！"
			echo -e "Current version v$sh_v        Latest version ${gl_huang}v$sh_v_new${gl_bai}"
		fi

		local cron_job="kejilion.sh"
		local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

		if [ -n "$existing_cron" ]; then
			echo "------------------------"
			echo -e "${gl_lv}Automatic updates are enabled, and the script will automatically update every day at 2 AM!${gl_bai}"
		fi

		echo "------------------------"
		echo "1. 今すぐ更新            2. 自動更新を有効にする            3. 自動更新を無効にする"
		echo "------------------------"
		echo "0. メインメニューに戻る"
		echo "------------------------"
		Ask "Please enter your choice: " choice
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
			echo -e "${gl_lv}The script has been updated to the latest version!${gl_huang}v$sh_v_new${gl_bai}"
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
			echo -e "${gl_lv}Automatic updates are enabled, and the script will automatically update every day at 2 AM!${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}Automatic updates are disabled${gl_bai}"
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
		echo -e "Kejilion Script Toolbox v$sh_v"
		echo -e "Enter ${gl_huang}k${gl_kjlan} in the command line to quickly start the script${gl_bai}"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}1.   ${gl_bai}System Information Query"
		echo -e "${gl_kjlan}2.   ${gl_bai}System Update"
		echo -e "${gl_kjlan}3.   ${gl_bai}System Cleanup"
		echo -e "${gl_kjlan}4.   ${gl_bai}Basic Tools"
		echo -e "${gl_kjlan}5.   ${gl_bai}BBR Management"
		echo -e "${gl_kjlan}6.   ${gl_bai}Docker Management"
		echo -e "${gl_kjlan}7.   ${gl_bai}WARP Management"
		echo -e "${gl_kjlan}8.   ${gl_bai}Test Script Collection"
		echo -e "${gl_kjlan}9.   ${gl_bai}Oracle Cloud Script Collection"
		echo -e "${gl_huang}10.  ${gl_bai}LDNMP Website Building"
		echo -e "${gl_kjlan}11.  ${gl_bai}App Market"
		echo -e "${gl_kjlan}12.  ${gl_bai}Backend Workspace"
		echo -e "${gl_kjlan}13.  ${gl_bai}System Tools"
		echo -e "${gl_kjlan}14.  ${gl_bai}Server Cluster Control"
		echo -e "${gl_kjlan}15.  ${gl_bai}Advertising Column"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}p.   ${gl_bai}Palworld Server Creation Script"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}00.  ${gl_bai}Script Update"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.   ${gl_bai}Exit Script"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "Please enter your choice: " choice

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
		*) echo "無効な入力!" ;;
		esac
		break_end
	done
}

k_info() {
	send_stats "k命令参考用例"
	echo "-------------------"
	echo "视频介绍: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
	echo "以下是k命令参考用例："
	echo "启动脚本            k"
	echo "安装软件包          k install nano wget | k add nano wget | k 安装 nano wget"
	echo "卸载软件包          k remove nano wget | k del nano wget | k uninstall nano wget | k 卸载 nano wget"
	echo "更新系统            k update | k 更新"
	echo "清理系统垃圾        k clean | k 清理"
	echo "重装系统面板        k dd | k 重装"
	echo "bbr3控制面板        k bbr3 | k bbrv3"
	echo "内核调优面板        k nhyh | k 内核优化"
	echo "设置虚拟内存        k swap 2048"
	echo "设置虚拟时区        k time Asia/Shanghai | k 时区 Asia/Shanghai"
	echo "系统回收站          k trash | k hsz | k 回收站"
	echo "系统备份功能        k backup | k bf | k 备份"
	echo "ssh远程连接工具     k ssh | k 远程连接"
	echo "rsync远程同步工具   k rsync | k 远程同步"
	echo "硬盘管理工具        k disk | k 硬盘管理"
	echo "内网穿透（服务端）  k frps"
	echo "内网穿透（客户端）  k frpc"
	echo "软件启动            k start sshd | k 启动 sshd "
	echo "软件停止            k stop sshd | k 停止 sshd "
	echo "软件重启            k restart sshd | k 重启 sshd "
	echo "软件状态查看        k status sshd | k 状态 sshd "
	echo "软件开机启动        k enable docker | k autostart docke | k 开机启动 docker "
	echo "域名证书申请        k ssl"
	echo "域名证书到期查询    k ssl ps"
	echo "docker环境安装      k docker install |k docker 安装"
	echo "docker容器管理      k docker ps |k docker 容器"
	echo "docker镜像管理      k docker img |k docker 镜像"
	echo "LDNMP站点管理       k web"
	echo "LDNMP缓存清理       k web cache"
	echo "安装WordPress       k wp |k wordpress |k wp xxx.com"
	echo "安装反向代理        k fd |k rp |k 反代 |k fd xxx.com"
	echo "安装负载均衡        k loadbalance |k 负载均衡"
	echo "防火墙面板          k fhq |k 防火墙"
	echo "开放端口            k dkdk 8080 |k 打开端口 8080"
	echo "关闭端口            k gbdk 7800 |k 关闭端口 7800"
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
