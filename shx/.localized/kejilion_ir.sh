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
	echo -e "${gl_kjlan}به جعبه ابزار اسکریپت科技lion خوش آمدید${gl_bai}"
	echo "برای اولین بار از اسکریپت استفاده می‌کنید، لطفاً ابتدا توافقنامه مجوز کاربر را بخوانید و بپذیرید."
	echo "توافقنامه مجوز کاربر: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	Ask "آیا با شرایط بالا موافقید؟ (y/N): " user_input

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
		echo "پارامتر بسته نرم‌افزاری ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}در حال نصب $package...${gl_bai}"
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
				echo "مدیریت بسته نرم‌افزاری ناشناخته!"
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
		echo -e "${gl_huang}نکته: ${gl_bai}فضای دیسک کافی نیست!"
		echo "فضای موجود فعلی: $((available_space_mb / 1024))G"
		echo "فضای مورد نیاز حداقل: ${required_gb}G"
		echo "نمی‌توان نصب را ادامه داد، لطفاً فضای دیسک را پاک کرده و دوباره امتحان کنید."
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
		echo "پارامتر بسته نرم‌افزاری ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}در حال حذف $package...${gl_bai}"
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
			echo "مدیریت بسته نرم‌افزاری ناشناخته!"
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
		echo "سرویس $1 با موفقیت مجدداً راه‌اندازی شد."
	else
		echo "خطا: راه‌اندازی مجدد سرویس $1 ناموفق بود."
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "سرویس $1 با موفقیت راه‌اندازی شد."
	else
		echo "خطا: راه‌اندازی سرویس $1 ناموفق بود."
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "سرویس $1 با موفقیت متوقف شد."
	else
		echo "خطا: توقف سرویس $1 ناموفق بود."
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "وضعیت سرویس $1 با موفقیت نمایش داده شد."
	else
		echo "خطا: نمایش وضعیت سرویس $1 ناموفق بود."
	fi
}

enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
		/bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "سرویس $SERVICE_NAME برای راه‌اندازی خودکار هنگام بوت تنظیم شد."
}

break_end() {
	echo -e "${gl_lv}عملیات تکمیل شد${gl_bai}"
	Press "برای ادامه هر کلیدی را فشار دهید..."
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
	echo -e "${gl_huang}در حال نصب محیط docker...${gl_bai}"
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
		echo "لیست کانتینرهای Docker"
		docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
		echo
		echo "عملیات کانتینر"
		echo "------------------------"
		echo "1. ایجاد کانتینر جدید"
		echo "------------------------"
		echo "2. راه‌اندازی کانتینر مشخص شده             6. راه‌اندازی همه کانتینرها"
		echo "3. توقف کانتینر مشخص شده             7. توقف همه کانتینرها"
		echo "4. حذف کانتینر مشخص شده             8. حذف همه کانتینرها"
		echo "5. راه‌اندازی مجدد کانتینر مشخص شده             9. راه‌اندازی مجدد همه کانتینرها"
		echo "------------------------"
		echo "11. ورود به کانتینر مشخص شده           12. مشاهده لاگ‌های کانتینر"
		echo "13. مشاهده شبکه کانتینر           14. مشاهده مصرف منابع کانتینر"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			send_stats "新建容器"
			Ask "دستور ایجاد را وارد کنید: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			Ask "نام کانتینر را وارد کنید (برای نام‌های کانتینر متعدد از فاصله استفاده کنید): " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			Ask "نام کانتینر را وارد کنید (برای نام‌های کانتینر متعدد از فاصله استفاده کنید): " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			Ask "نام کانتینر را وارد کنید (برای نام‌های کانتینر متعدد از فاصله استفاده کنید): " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			Ask "نام کانتینر را وارد کنید (برای نام‌های کانتینر متعدد از فاصله استفاده کنید): " dockername
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
			Ask "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می‌خواهید همه کانتینرها را حذف کنید؟ (y/N): " choice
			case "$choice" in
			[Yy])
				docker rm -f $(docker ps -a -q)
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;
		9)
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			Ask "نام کانتینر را وارد کنید: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			Ask "نام کانتینر را وارد کنید: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器网络"
			echo
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			echo "نام کانتینر              نام شبکه              آدرس IP"
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
		echo "لیست ایمیج‌های Docker"
		docker image ls
		echo
		echo "عملیات ایمیج"
		echo "------------------------"
		echo "1. دریافت ایمیج مشخص شده             3. حذف ایمیج مشخص شده"
		echo "2. به‌روزرسانی ایمیج مشخص شده             4. حذف همه ایمیج‌ها"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			send_stats "拉取镜像"
			Ask "نام ایمیج را وارد کنید (برای نام‌های ایمیج متعدد از فاصله استفاده کنید): " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}در حال دریافت ایمیج: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			Ask "نام ایمیج را وارد کنید (برای نام‌های ایمیج متعدد از فاصله استفاده کنید): " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}در حال به‌روزرسانی ایمیج: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			Ask "نام ایمیج را وارد کنید (برای نام‌های ایمیج متعدد از فاصله استفاده کنید): " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			Ask "${gl_hong}توجه: ${gl_bai}آیا مطمئن هستید که می‌خواهید همه ایمیج‌ها را حذف کنید؟ (y/N): " choice
			case "$choice" in
			[Yy])
				docker rmi -f $(docker images -q)
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			echo "توزیع پشتیبانی نمی‌شود: $ID"
			return
			;;
		esac
	else
		echo "سیستم عامل قابل تشخیص نیست."
		return
	fi

	echo -e "${gl_lv}crontab نصب شده است و سرویس cron در حال اجرا است.${gl_bai}"
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
			echo -e "${gl_huang}دسترسی ipv6 در حال حاضر فعال است${gl_bai}"
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
		echo -e "${gl_hong}فایل پیکربندی وجود ندارد${gl_bai}"
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
		echo -e "${gl_huang}دسترسی ipv6 در حال حاضر غیرفعال است${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . >"$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}دسترسی ipv6 با موفقیت غیرفعال شد${gl_bai}"
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
		echo "لطفاً حداقل یک شماره پورت ارائه دهید"
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
			echo "پورت $port باز شد"
		fi
	done

	save_iptables_rules
	send_stats "已打开端口"
}

close_port() {
	local ports=($@)
	# 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک شماره پورت ارائه دهید"
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
			echo "پورت $port بسته شد"
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
		echo "لطفاً حداقل یک آدرس IP یا محدوده IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的阻止规则
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允许规则
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP $ip مجاز شد"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)
	# 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک آدرس IP یا محدوده IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止规则
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP $ip مسدود شد"
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
			echo "خطا: دانلود فایل منطقه IP برای $country_code ناموفق بود"
			exit 1
		fi

		# 将 IP 添加到 ipset
		while IFS= read -r ip; do
			ipset add "$ipset_name" "$ip"
		done <"${country_code,,}.zone"

		# 使用 iptables 阻止 IP
		iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
		iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

		echo "آدرس‌های IP $country_code با موفقیت مسدود شدند"
		rm "${country_code,,}.zone"
		;;

	allow)
		# 为允许的国家创建 ipset（如果不存在）
		if ! ipset list "$ipset_name" &>/dev/null; then
			ipset create "$ipset_name" hash:net
		fi

		# 下载 IP 区域文件
		if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
			echo "خطا: دانلود فایل منطقه IP برای $country_code ناموفق بود"
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

		echo "فقط آدرس‌های IP $country_code با موفقیت مجاز شدند"
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

		echo "محدودیت آدرس IP $country_code با موفقیت برداشته شد"
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
		echo "مدیریت پیشرفته فایروال"
		send_stats "高级防火墙管理"
		echo "------------------------"
		iptables -L INPUT
		echo
		echo "مدیریت فایروال"
		echo "------------------------"
		echo "1.  باز کردن پورت مشخص شده                 2.  بستن پورت مشخص شده"
		echo "3.  باز کردن همه پورت‌ها                 4.  بستن همه پورت‌ها"
		echo "------------------------"
		echo "5.  لیست سفید IP                  \t 6.  لیست سیاه IP"
		echo "7.  پاک کردن IP مشخص شده"
		echo "------------------------"
		echo "11. اجازه PING                  \t 12. ممنوعیت PING"
		echo "------------------------"
		echo "13. فعال کردن دفاع DDOS                 14. غیرفعال کردن دفاع DDOS"
		echo "------------------------"
		echo "15. مسدود کردن IP کشور مشخص شده               16. فقط مجاز کردن IP کشور مشخص شده"
		echo "17. برداشتن محدودیت IP کشور مشخص شده"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			Ask "شماره پورت باز را وارد کنید: " o_port
			open_port $o_port
			send_stats "开放指定端口"
			;;
		2)
			Ask "شماره پورت بسته را وارد کنید: " c_port
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
			Ask "IP یا محدوده IP را برای عبور وارد کنید: " o_ip
			allow_ip $o_ip
			;;
		6)
			# IP 黑名单
			Ask "IP یا محدوده IP را برای مسدود کردن وارد کنید: " c_ip
			block_ip $c_ip
			;;
		7)
			# 清除指定 IP
			Ask "IP را برای پاکسازی وارد کنید: " d_ip
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
			Ask "کد کشور را برای مسدود کردن وارد کنید (مانند CN, US, JP): " country_code
			manage_country_rules block $country_code
			send_stats "允许国家 $country_code 的IP"
			;;
		16)
			Ask "کد کشور را برای اجازه دادن وارد کنید (مانند CN, US, JP): " country_code
			manage_country_rules allow $country_code
			send_stats "阻止国家 $country_code 的IP"
			;;

		17)
			Ask "کد کشور را برای پاکسازی وارد کنید (مانند CN, US, JP): " country_code
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

	echo -e "اندازه حافظه مجازی به ${gl_huang}${new_swap}${gl_bai}M تنظیم شد"
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
	echo "نصب محیط LDNMP به پایان رسید"
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
	echo "وظیفه تمدید به‌روزرسانی شد"
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
	echo -e "${gl_huang}اطلاعات کلید عمومی $yuming${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo
	echo -e "${gl_huang}اطلاعات کلید خصوصی $yuming${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo
	echo -e "${gl_huang}مسیر ذخیره گواهی${gl_bai}"
	echo "کلید عمومی: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "کلید خصوصی: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo
}

add_ssl() {
	echo -e "${gl_huang}درخواست سریع گواهی SSL، تمدید خودکار قبل از انقضا${gl_bai}"
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
	echo -e "${gl_huang}وضعیت انقضای گواهی‌های درخواستی${gl_bai}"
	echo "اطلاعات سایت                      زمان انقضای گواهینامه"
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
		echo -e "${gl_hong}توجه: ${gl_bai}درخواست گواهی ناموفق بود، لطفاً دلایل احتمالی زیر را بررسی کرده و دوباره امتحان کنید:"
		echo -e "1. غلط املایی دامنه ➠ لطفاً صحت دامنه وارد شده را بررسی کنید"
		echo -e "2. مشکل تجزیه DNS ➠ تأیید کنید که دامنه به درستی به IP سرور فعلی تجزیه شده است"
		echo -e "3. مشکل پیکربندی شبکه ➠ در صورت استفاده از شبکه‌های مجازی مانند Cloudflare Warp، لطفاً آن را موقتاً غیرفعال کنید"
		echo -e "4. محدودیت فایروال ➠ بررسی کنید که پورت‌های 80/443 باز هستند و از دسترسی تأیید اطمینان حاصل کنید"
		echo -e "5. تعداد درخواست‌ها بیش از حد مجاز ➠ Let's Encrypt محدودیت هفتگی دارد (5 بار در هفته برای هر دامنه)"
		echo -e "6. محدودیت ثبت دامنه در چین ➠ در محیط چین، لطفاً تأیید کنید که دامنه ثبت شده است"
		break_end
		clear
		echo "لطفاً دوباره برای استقرار $webname تلاش کنید"
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
	echo -e "ابتدا دامنه را به IP فعلی دستگاه تجزیه کنید: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	Ask "IP یا دامنه تجزیه شده خود را وارد کنید: " yuming
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
	echo "به‌روزرسانی ${ldnmp_pods} کامل شد"

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
	echo "اطلاعات ورود: "
	echo "نام کاربری: $dbuse"
	echo "رمز عبور: $dbusepasswd"
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
		Ask "آیا می‌خواهید کش Cloudflare را پاک کنید؟ (y/N): " answer
		if [[ $answer == "y" ]]; then
			echo "اطلاعات CF در $CONFIG_FILE ذخیره شده است و می‌توان اطلاعات CF را بعداً تغییر داد"
			Ask "API_TOKEN خود را وارد کنید: " API_TOKEN
			Ask "نام کاربری CF خود را وارد کنید: " EMAIL
			Ask "شناسه منطقه (zone_id) را وارد کنید (برای چندین مورد از فاصله استفاده کنید): " -a ZONE_IDS

			mkdir -p /home/web/config/
			echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" >"$CONFIG_FILE"
		fi
	fi

	# 循环遍历每个 zone_id 并执行清除缓存命令
	for ZONE_ID in "${ZONE_IDS[@]}"; do
		echo "در حال پاک کردن کش برای zone_id: $ZONE_ID"
		curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
			-H "X-Auth-Email: $EMAIL" \
			-H "X-Auth-Key: $API_TOKEN" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'
	done

	echo "درخواست پاک کردن کش ارسال شد."
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
		Ask "برای حذف داده‌های سایت، نام دامنه خود را وارد کنید (برای چندین دامنه از فاصله استفاده کنید): " yuming_list
		if [[ -z $yuming_list ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "در حال حذف دامنه: $yuming"
		rm -r /home/web/html/$yuming >/dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "در حال حذف پایگاه داده: $dbname"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		waf_status=" WAF فعال است"
	else
		waf_status=""
	fi
}

check_cf_mode() {
	if [ -f "/path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" حالت cf فعال است"
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

		echo "[+] WP_MEMORY_LIMIT در $FILE جایگزین شد"
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

		echo "[+] تنظیمات WP_DEBUG در $FILE جایگزین شد"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
		echo "پارامتر نامعتبر: از 'on' یا 'off' استفاده کنید"
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
			echo -e "برنامه دفاعی وب سرور${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			echo "------------------------"
			echo "1. نصب برنامه دفاعی"
			echo "------------------------"
			echo "5. مشاهده لاگ‌های مسدودسازی SSH                6. مشاهده لاگ‌های مسدودسازی وب‌سایت"
			echo "7. مشاهده لیست قوانین دفاعی               8. مشاهده نظارت زنده لاگ‌ها"
			echo "------------------------"
			echo "11. پیکربندی پارامترهای مسدودسازی                  12. پاک کردن تمام IPهای مسدود شده"
			echo "------------------------"
			echo "21. حالت cloudflare                22. فعال کردن سپر 5 ثانیه‌ای در بار بالا"
			echo "------------------------"
			echo "31. فعال کردن WAF                       32. غیرفعال کردن WAF"
			echo "33. فعال کردن دفاع DDOS                  34. غیرفعال کردن دفاع DDOS"
			echo "------------------------"
			echo "9. حذف برنامه دفاعی"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			Ask "انتخاب خود را وارد کنید: " sub_choice
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
				echo "برنامه دفاعی Fail2Ban حذف شد"
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
				echo "به پروفایل من در گوشه بالا سمت راست پنل cf بروید، API Tokens را در سمت چپ انتخاب کنید و Global API Key را دریافت کنید."
				NO_TRAN="https://dash.cloudflare.com/login"
				echo "$NO_TRAN"
				Ask "حساب CF را وارد کنید: " cfuser
				Ask "کلید Global API CF را وارد کنید: " cftoken

				wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
				docker exec nginx nginx -s reload

				cd /path/to/fail2ban/config/fail2ban/jail.d/
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

				cd /path/to/fail2ban/config/fail2ban/action.d
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

				sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
				sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
				f2b_status

				echo "حالت cloudflare پیکربندی شد، می‌توانید سوابق مسدودسازی را در پنل cf، سایت-امنیت-رویدادها مشاهده کنید."
				;;

			22)
				send_stats "高负载开启5秒盾"
				echo -e "${gl_huang}وب‌سایت هر 5 دقیقه به طور خودکار بررسی می‌شود، هنگامی که بار بالا تشخیص داده شود، سپر به طور خودکار فعال می‌شود و در صورت بار کم نیز سپر 5 ثانیه‌ای غیرفعال می‌شود.${gl_bai}"
				echo "--------------"
				echo "دریافت پارامترهای CF: "
				echo -e "به پروفایل من در گوشه بالا سمت راست داشبورد cf بروید، سپس از سمت چپ API Tokens را انتخاب کنید و ${gl_huang}Global API Key${gl_bai} را دریافت کنید"
				echo -e "از صفحه خلاصه دامنه در داشبورد cf در پایین سمت راست، ${gl_huang}شناسه منطقه${gl_bai} را دریافت کنید"
				NO_TRAN="https://dash.cloudflare.com/login"
				echo "$NO_TRAN"
				echo "--------------"
				Ask "حساب CF را وارد کنید: " cfuser
				Ask "کلید Global API CF را وارد کنید: " cftoken
				Ask "شناسه منطقه دامنه در CF را وارد کنید: " cfzonID

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
					echo "اسکریپت سپر خودکار در بار بالا اضافه شد"
				else
					echo "اسکریپت سپر خودکار از قبل وجود دارد، نیازی به اضافه کردن نیست"
				fi

				;;

			31)
				nginx_waf on
				echo "WAF سایت فعال شد"
				send_stats "站点WAF已开启"
				;;

			32)
				nginx_waf off
				echo "WAF سایت غیرفعال شد"
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
		mode_info="حالت عملکرد بالا"
	else
		mode_info="حالت استاندارد"
	fi

}

check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# 检查 zstd 是否开启且未被注释（整行以 zstd on; 开头）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status="فشرده سازی zstd فعال است"
	else
		zstd_status=""
	fi

	# 检查 brotli 是否开启且未被注释
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status="فشرده سازی br فعال است"
	else
		br_status=""
	fi

	# 检查 gzip 是否开启且未被注释
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status="فشرده سازی gzip فعال است"
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
		echo -e "بهینه‌سازی محیط LDNMP${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
		echo "------------------------"
		echo "1. حالت استاندارد              2. حالت با عملکرد بالا (توصیه شده برای 2H4G یا بالاتر)"
		echo "------------------------"
		echo "3. فعال کردن فشرده‌سازی gzip          4. غیرفعال کردن فشرده‌سازی gzip"
		echo "5. فعال کردن فشرده سازی br            6. غیرفعال کردن فشرده سازی br"
		echo "7. فعال کردن فشرده سازی zstd          8. غیرفعال کردن فشرده سازی zstd"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
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

			echo "محیط LDNMP روی حالت استاندارد تنظیم شده است"

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

			echo "محیط LDNMP روی حالت عملکرد بالا تنظیم شده است"

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
		check_docker="${gl_lv} نصب شده است${gl_bai}"
	else
		check_docker="${gl_hui} نصب نشده است${gl_bai}"
	fi

}

check_docker_app_ip() {
	echo "------------------------"
	echo "آدرس دسترسی:"
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
			update_status="${gl_huang}نسخه جدید پیدا شد!${gl_bai}"
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
		echo "خطا: قادر به دریافت آدرس IP کانتینر $container_name_or_id نیست. لطفاً نام یا شناسه کانتینر را بررسی کنید."
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

	echo "دسترسی IP+پورت به این سرویس مسدود شد"
	save_iptables_rules
}

clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 获取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "خطا: قادر به دریافت آدرس IP کانتینر $container_name_or_id نیست. لطفاً نام یا شناسه کانتینر را بررسی کنید."
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

	echo "دسترسی IP+پورت به این سرویس مجاز شد"
	save_iptables_rules
}

block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z $port || -z $allowed_ip ]]; then
		echo "خطا: لطفاً شماره پورت و IP مجاز را ارائه دهید."
		echo "نحوه استفاده: block_host_port <شماره پورت> <IP مجاز>"
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

	echo "دسترسی IP+پورت به این سرویس مسدود شد"
	save_iptables_rules
}

clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z $port || -z $allowed_ip ]]; then
		echo "خطا: لطفاً شماره پورت و IP مجاز را ارائه دهید."
		echo "نحوه استفاده: clear_host_port_rules <شماره پورت> <IP مجاز>"
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

	echo "دسترسی IP+پورت به این سرویس مجاز شد"
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
		echo "1. نصب              2. بروزرسانی            3. حذف"
		echo "------------------------"
		echo "5. افزودن دسترسی دامنه      6. حذف دسترسی دامنه"
		echo "7. مجاز کردن دسترسی IP+پورت   8. مسدود کردن دسترسی IP+پورت"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			check_disk_space $app_size
			Ask "پورت سرویس خارجی را وارد کنید، Enter را بزنید تا از پورت ${docker_port} به طور پیش‌فرض استفاده شود: " app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			setup_docker_dir
			echo "$docker_port" >"/home/docker/${docker_name}_port.conf"

			clear
			echo "نصب $docker_name کامل شد"
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
			echo "نصب $docker_name کامل شد"
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
			echo "برنامه حذف شد"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "تنظیمات دسترسی دامنه ${docker_name}"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "قالب دامنه example.com بدون https://"
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
		echo "1. نصب             2. بروزرسانی             3. حذف"
		echo "------------------------"
		echo "5. افزودن دسترسی دامنه     6. حذف دسترسی دامنه"
		echo "7. مجاز کردن دسترسی IP+پورت  8. مسدود کردن دسترسی IP+پورت"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			check_disk_space $app_size
			Ask "پورت سرویس خارجی را وارد کنید، Enter را بزنید تا از پورت ${docker_port} به طور پیش‌فرض استفاده شود: " app_port
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
			echo "تنظیمات دسترسی دامنه ${docker_name}"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;
		6)
			echo "قالب دامنه example.com بدون https://"
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

	Ask "${gl_huang}نکته: ${gl_bai}آیا می‌خواهید سرور را اکنون راه‌اندازی مجدد کنید؟ (y/N): " rboot
	case "$rboot" in
	[Yy])
		echo "راه اندازی مجدد شد"
		reboot
		;;
	*)
		echo "لغو شد"
		;;
	esac

}

ldnmp_install_status_one() {

	if docker inspect "php" &>/dev/null; then
		clear
		send_stats "无法再次安装LDNMP环境"
		echo -e "${gl_huang}نکته: ${gl_bai}محیط ساخت سایت نصب شده است. نیازی به نصب مجدد نیست!"
		break_end
		linux_ldnmp
	fi

}

ldnmp_install_all() {
	cd ~
	send_stats "安装LDNMP环境"
	root_use
	clear
	echo -e "${gl_huang}محیط LDNMP نصب نشده است، شروع نصب محیط LDNMP...${gl_bai}"
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
	echo -e "${gl_huang}nginx نصب نشده است، شروع نصب محیط nginx...${gl_bai}"
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
	echo "نصب nginx کامل شد"
	echo -e "نسخه فعلی: ${gl_huang}v$nginx_version${gl_bai}"
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
	echo "وبسایت $webname شما آماده است!"
	echo "https://$yuming"
	echo "------------------------"
	echo "اطلاعات نصب $webname: "

}

nginx_web_on() {
	clear
	echo "وبسایت $webname شما آماده است!"
	echo "https://$yuming"

}

ldnmp_wp() {
	clear
	# wordpress
	webname="وردپرس"
	yuming="${1:-}"
	send_stats "安装$webname"
	echo "شروع استقرار $webname"
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
	#   echo "نام پایگاه داده: $dbname"
	#   echo "نام کاربری: $dbuse"
	#   echo "رمز عبور: $dbusepasswd"
	#   echo "آدرس پایگاه داده: mysql"
	#   echo "پیشوند جدول: wp_"

}

ldnmp_Proxy() {
	clear
	webname="پروکسی معکوس - IP+پورت"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "شروع استقرار $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		Ask "IP پروکسی معکوس خود را وارد کنید: " reverseproxy
	fi

	if [ -z "$port" ]; then
		Ask "پورت پروکسی معکوس خود را وارد کنید: " port
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
	webname="پروکسی معکوس - تعادل بار"
	yuming="${1:-}"
	reverseproxy_port="${2:-}"

	send_stats "安装$webname"
	echo "شروع استقرار $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# 获取用户输入的多个IP:端口（用空格分隔）
	if [ -z "$reverseproxy_port" ]; then
		Ask "IPها و پورت‌های پروکسی معکوس متعدد خود را با فاصله وارد کنید (مانند 127.0.0.1:3000 127.0.0.1:3002): " reverseproxy_port
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
		local output="سایت: ${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="پایگاه داده: ${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "محیط LDNMP"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}                      زمان انقضای گواهی"
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
		echo "دایرکتوری سایت"
		echo "------------------------"
		echo -e "داده‌ها ${gl_hui}/home/web/html${gl_bai}     گواهی‌ها ${gl_hui}/home/web/certs${gl_bai}     پیکربندی ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo
		echo "عملیات"
		echo "------------------------"
		echo "1.  درخواست/بروزرسانی گواهی دامنه               2.  تغییر دامنه سایت"
		echo "3.  پاکسازی کش سایت                    4.  ایجاد سایت مرتبط"
		echo "5.  مشاهده لاگ دسترسی                    6.  مشاهده لاگ خطا"
		echo "7.  ویرایش پیکربندی سراسری                    8.  ویرایش پیکربندی سایت"
		echo "9.  مدیریت پایگاه داده سایت\t\t    10. مشاهده گزارش تحلیل سایت"
		echo "------------------------"
		echo "20. حذف داده های سایت مشخص"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			send_stats "申请域名证书"
			Ask "دامنه خود را وارد کنید: " yuming
			install_certbot
			docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
			install_ssltls
			certs_status

			;;

		2)
			send_stats "更换站点域名"
			echo -e "${gl_hong}توصیه اکید: ${gl_bai}قبل از تغییر نام دامنه سایت، حتماً از تمام داده‌های سایت پشتیبان تهیه کنید!"
			Ask "دامنه قدیمی را وارد کنید: " oddyuming
			Ask "دامنه جدید را وارد کنید: " yuming
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
			echo -e "برای سایت موجود، یک نام دامنه جدید برای دسترسی مرتبط کنید"
			Ask "دامنه موجود را وارد کنید: " oddyuming
			Ask "دامنه جدید را وارد کنید: " yuming
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
			Ask "برای ویرایش تنظیمات سایت، دامنه مورد نظر را وارد کنید: " yuming
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
		check_panel="${gl_lv} نصب شده است${gl_bai}"
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
		echo "${panelname} یک پنل مدیریت عملیاتی محبوب و قدرتمند است."
		echo "معرفی وبسایت: $panelurl "

		echo
		echo "------------------------"
		echo "1. نصب            2. مدیریت            3. حذف"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
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
		check_frp="${gl_lv} نصب شده است${gl_bai}"
	else
		check_frp="${gl_hui} نصب نشده است${gl_bai}"
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
	echo "پارامترهای مورد نیاز برای استقرار کلاینت"
	echo "IP سرویس: $ipv4_address"
	echo "token: $token"
	echo
	echo "اطلاعات پنل FRP"
	echo "آدرس پنل FRP: http://$ipv4_address:$dashboard_port"
	echo "نام کاربری پنل FRP: $dashboard_user"
	echo "رمز عبور پنل FRP: $dashboard_pwd"
	echo

	open_port 8055 8056

}

configure_frpc() {
	send_stats "安装frp客户端"
	Ask "IP اتصال خارجی را وارد کنید: " server_addr
	Ask "توکن اتصال خارجی را وارد کنید: " token
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
	Ask "نام سرویس را وارد کنید: " service_name
	Ask "نوع فوروارد را وارد کنید (tcp/udp) [Enter پیش‌فرض tcp است]: " service_type
	local service_type=${service_type:-tcp}
	Ask "IP داخلی را وارد کنید [Enter پیش‌فرض 127.0.0.1 است]: " local_ip
	local local_ip=${local_ip:-127.0.0.1}
	Ask "پورت داخلی را وارد کنید: " local_port
	Ask "پورت خارجی را وارد کنید: " remote_port

	# 将用户输入写入配置文件
	NO_TRAN=$'\n[$service_name]\ntype = ${service_type}\nlocal_ip = ${local_ip}\nlocal_port = ${local_port}\nremote_port = ${remote_port}\n'
	echo -e "$NO_TRAN" >>/home/frp/frpc.toml

	# 输出生成的信息
	echo "سرویس $service_name با موفقیت به frpc.toml اضافه شد"

	docker restart frpc

	open_port $local_port

}

delete_forwarding_service() {
	send_stats "删除frp内网服务"
	# 提示用户输入需要删除的服务名称
	Ask "نام سرویس مورد نظر برای حذف را وارد کنید: " service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "سرویس $service_name با موفقیت از frpc.toml حذف شد"

	docker restart frpc

}

list_forwarding_services() {
	local config_file="$1"

	# 打印表头
	echo "نام سرویس         آدرس داخلی              آدرس خارجی                   پروتکل"

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
		echo "آدرس دسترسی خارجی سرویس FRP:"

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
		echo -e "سرور FRP $check_frp $update_status"
		echo "ساخت محیط سرویس تونلینگ داخلی FRP، دستگاه های بدون IP عمومی را در اینترنت قابل دسترس می کند"
		echo "معرفی وبسایت: https://github.com/fatedier/frp/"
		echo "آموزش ویدئویی: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo
		echo "------------------------"
		echo "1. نصب                  2. بروزرسانی                  3. حذف"
		echo "------------------------"
		echo "5. دسترسی دامنه سرویس داخلی      6. حذف دسترسی دامنه"
		echo "------------------------"
		echo "7. مجاز کردن دسترسی IP+پورت       8. مسدود کردن دسترسی IP+پورت"
		echo "------------------------"
		echo "00. بروزرسانی وضعیت سرویس         0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			generate_frps_config
			echo "سرور FRP با موفقیت نصب شد"
			;;
		2)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
			donlond_frp frps
			echo "سرور FRP با موفقیت بروزرسانی شد"
			;;
		3)
			crontab -l | grep -v 'frps' | crontab - >/dev/null 2>&1
			tmux kill-session -t frps >/dev/null 2>&1
			docker rm -f frps && docker rmi kjlion/frp:alpine
			rm -rf /home/frp

			close_port 8055 8056

			echo "برنامه حذف شد"
			;;
		5)
			echo "پروکسی کردن سرویس تونلینگ داخلی به دسترسی دامنه"
			send_stats "FRP对外域名访问"
			add_yuming
			Ask "لطفاً پورت سرویس تونل داخلی خود را وارد کنید:" frps_port
			ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
			block_host_port "$frps_port" "$ipv4_address"
			;;
		6)
			echo "قالب دامنه example.com بدون https://"
			web_del
			;;

		7)
			send_stats "允许IP访问"
			Ask "لطفاً پورت مورد نظر برای باز شدن را وارد کنید:" frps_port
			clear_host_port_rules "$frps_port" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP访问"
			echo "اگر قبلاً دامنه را برای دسترسی پروکسی کرده اید، می توانید از این تابع برای مسدود کردن دسترسی IP+پورت استفاده کنید، که امن تر است."
			Ask "لطفاً پورت مورد نظر برای مسدود شدن را وارد کنید:" frps_port
			block_host_port "$frps_port" "$ipv4_address"
			;;

		00)
			send_stats "刷新FRP服务状态"
			echo "وضعیت سرویس FRP بروزرسانی شد"
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
		echo -e "کلاینت FRP $check_frp $update_status"
		echo "اتصال به سرور، پس از اتصال می توانید سرویس تونلینگ داخلی را برای دسترسی اینترنتی ایجاد کنید"
		echo "معرفی وبسایت: https://github.com/fatedier/frp/"
		echo "آموزش ویدئویی: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo
		echo "------------------------"
		echo "1. نصب               2. بروزرسانی               3. حذف"
		echo "------------------------"
		echo "4. افزودن سرویس خارجی       5. حذف سرویس خارجی       6. پیکربندی دستی سرویس"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1)
			install jq grep ss
			install_docker
			configure_frpc
			echo "کلاینت FRP با موفقیت نصب شد"
			;;
		2)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			donlond_frp frpc
			echo "کلاینت FRP با موفقیت بروزرسانی شد"
			;;

		3)
			crontab -l | grep -v 'frpc' | crontab - >/dev/null 2>&1
			tmux kill-session -t frpc >/dev/null 2>&1
			docker rm -f frpc && docker rmi kjlion/frp:alpine
			rm -rf /home/frp
			close_port 8055
			echo "برنامه حذف شد"
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
			local YTDLP_STATUS="${gl_lv} نصب شده است${gl_bai}"
		else
			local YTDLP_STATUS="${gl_hui} نصب نشده است${gl_bai}"
		fi

		clear
		send_stats "yt-dlp 下载工具"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp یک ابزار قدرتمند دانلود ویدیو است که از هزاران سایت مانند YouTube، Bilibili، Twitter و غیره پشتیبانی می‌کند."
		echo -e "آدرس وب‌سایت رسمی: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "لیست ویدئوهای دانلود شده:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "（موجود نیست）"
		echo "-------------------------"
		echo "1.  نصب               2.  بروزرسانی               3.  حذف"
		echo "-------------------------"
		echo "5.  دانلود تک ویدئو       6.  دانلود گروهی ویدئو       7.  دانلود با پارامتر سفارشی"
		echo "8.  دانلود به صورت فایل صوتی MP3      9.  حذف دایرکتوری ویدئو       10. مدیریت کوکی (در حال توسعه)"
		echo "-------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "-------------------------"
		Ask "لطفاً شماره گزینه را وارد کنید:" choice

		case $choice in
		1)
			send_stats "正在安装 yt-dlp..."
			echo "در حال نصب yt-dlp..."
			install ffmpeg
			sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
			sudo chmod a+rx /usr/local/bin/yt-dlp
			Press "نصب کامل شد. برای ادامه هر کلیدی را فشار دهید..."
			;;
		2)
			send_stats "正在更新 yt-dlp..."
			echo "در حال بروزرسانی yt-dlp..."
			sudo yt-dlp -U
			Press "به‌روزرسانی کامل شد. برای ادامه هر کلیدی را فشار دهید..."
			;;
		3)
			send_stats "正在卸载 yt-dlp..."
			echo "در حال حذف yt-dlp..."
			sudo rm -f /usr/local/bin/yt-dlp
			Press "حذف کامل شد. برای ادامه هر کلیدی را فشار دهید..."
			;;
		5)
			send_stats "单个视频下载"
			Ask "لطفاً لینک ویدیو را وارد کنید:" url
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			Press "دانلود کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		6)
			send_stats "批量视频下载"
			install nano
			if [ ! -f "$URL_FILE" ]; then
				echo -e "# آدرس‌های لینک‌های ویدیوی متعدد را وارد کنید\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" >"$URL_FILE"
			fi
			nano $URL_FILE
			echo "شروع دانلود گروهی..."
			yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-a "$URL_FILE" \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			Press "دانلود دسته‌ای کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		7)
			send_stats "自定义视频下载"
			Ask "لطفاً پارامترهای کامل yt-dlp را وارد کنید (بدون yt-dlp):" custom
			yt-dlp -P "$VIDEO_DIR" $custom \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites
			Press "اجرا کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;
		8)
			send_stats "MP3下载"
			Ask "لطفاً لینک ویدیو را وارد کنید:" url
			yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
				--write-subs --sub-langs all \
				--write-thumbnail --embed-thumbnail \
				--write-info-json \
				-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
				--no-overwrites --no-post-overwrites "$url"
			Press "دانلود صدا کامل شد، برای ادامه هر کلیدی را فشار دهید..."
			;;

		9)
			send_stats "删除视频"
			Ask "لطفاً نام ویدیوی مورد نظر برای حذف را وارد کنید:" rmdir
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
	echo -e "${gl_huang}در حال به‌روزرسانی سیستم...${gl_bai}"
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
		echo "مدیریت بسته نرم‌افزاری ناشناخته!"
		return
	fi
}

linux_clean() {
	echo -e "${gl_huang}در حال پاکسازی سیستم...${gl_bai}"
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
		echo "پاکسازی کش مدیر بسته..."
		apk cache clean
		echo "حذف لاگ های سیستم..."
		rm -rf /var/log/*
		echo "حذف کش APK..."
		rm -rf /var/cache/apk/*
		echo "حذف فایل های موقت..."
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
		echo "حذف لاگ های سیستم..."
		rm -rf /var/log/*
		echo "حذف فایل های موقت..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "پاکسازی وابستگی های استفاده نشده..."
		pkg autoremove -y
		echo "پاکسازی کش مدیر بسته..."
		pkg clean -y
		echo "حذف لاگ های سیستم..."
		rm -rf /var/log/*
		echo "حذف فایل های موقت..."
		rm -rf /tmp/*

	else
		echo "مدیریت بسته نرم‌افزاری ناشناخته!"
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
		echo "بهینه سازی آدرس DNS"
		echo "------------------------"
		echo "آدرس DNS فعلی"
		cat /etc/resolv.conf
		echo "------------------------"
		echo
		echo "1. بهینه سازی DNS خارجی: "
		echo " v4: 1.1.1.1 8.8.8.8"
		echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
		echo "2. بهینه‌سازی DNS داخلی: "
		echo " v4: 223.5.5.5 183.60.83.19"
		echo " v6: 2400:3200::1 2400:da00::6666"
		echo "3. ویرایش دستی پیکربندی DNS"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " Limiting
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

	echo "پورت SSH به: $new_port تغییر یافت"

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
	echo -e "اطلاعات کلید خصوصی تولید شده است، حتماً آن را کپی و ذخیره کنید، می‌توانید آن را به عنوان فایل ${gl_huang}${ipv4_address}_ssh.key${gl_bai} ذخیره کنید، که برای ورود SSH بعدی استفاده می‌شود"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		-e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		-e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		-e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ورود با کلید خصوصی ROOT فعال شد، ورود با رمز عبور ROOT غیرفعال شد، اتصال مجدد اعمال خواهد شد${gl_bai}"

}

import_sshkey() {

	Ask "لطفاً محتوای کلید عمومی SSH خود را وارد کنید (معمولاً با 'ssh-rsa' یا 'ssh-ed25519' شروع می‌شود):" public_key

	if [[ -z $public_key ]]; then
		echo -e "${gl_hong}خطا: محتوای کلید عمومی وارد نشده است.${gl_bai}"
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
	echo -e "${gl_lv}کلید عمومی با موفقیت وارد شد، ورود با کلید خصوصی ROOT فعال شد، ورود با رمز عبور ROOT غیرفعال شد، اتصال مجدد اعمال خواهد شد${gl_bai}"

}

add_sshpasswd() {

	echo "رمز عبور ROOT خود را تنظیم کنید"
	passwd
	sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "تنظیمات ورود ${gl_lv}ROOT${gl_bai} کامل شد!"

}

root_use() {
	clear
	[ "$EUID" -ne 0 ] && echo -e "${gl_huang}نکته: ${gl_bai}این قابلیت نیاز به کاربر root دارد تا اجرا شود!" && break_end && kejilion
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
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}root${gl_bai} رمز عبور اولیه: ${gl_huang}LeitboGi0ro${gl_bai} پورت اولیه: ${gl_huang}22${gl_bai}"
		Press "برای ادامه هر کلیدی را فشار دهید..."
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_2() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}Administrator${gl_bai} رمز عبور اولیه: ${gl_huang}Teddysun.com${gl_bai} پورت اولیه: ${gl_huang}3389${gl_bai}"
		Press "برای ادامه هر کلیدی را فشار دهید..."
		install wget
		dd_xitong_MollyLau
	}

	dd_xitong_3() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}root${gl_bai} رمز عبور اولیه: ${gl_huang}123@@@${gl_bai} پورت اولیه: ${gl_huang}22${gl_bai}"
		Press "برای ادامه هر کلیدی را فشار دهید..."
		dd_xitong_bin456789
	}

	dd_xitong_4() {
		echo -e "نام کاربری اولیه پس از نصب مجدد: ${gl_huang}Administrator${gl_bai} رمز عبور اولیه: ${gl_huang}123@@@${gl_bai} پورت اولیه: ${gl_huang}3389${gl_bai}"
		Press "برای ادامه هر کلیدی را فشار دهید..."
		dd_xitong_bin456789
	}

	while true; do
		root_use
		echo "نصب مجدد سیستم عامل"
		echo "--------------------------------"
		echo -e "${gl_hong}توجه: ${gl_bai}نصب مجدد خطر قطع ارتباط را دارد، با احتیاط استفاده کنید. نصب مجدد حدود 15 دقیقه طول می کشد، لطفاً قبل از آن از داده های خود پشتیبان تهیه کنید."
		echo -e "با تشکر از پشتیبانی اسکریپت از سوی MollyLau و bin456789! ${gl_bai} "
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
		echo "35. openSUSE Tumbleweed       36. fnos飞牛公测版"
		echo "------------------------"
		echo "41. Windows 11                42. Windows 10"
		echo "43. Windows 7                 44. Windows Server 2022"
		echo "45. Windows Server 2019       46. Windows Server 2016"
		echo "47. Windows 11 ARM"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "لطفاً سیستم مورد نظر برای نصب مجدد را انتخاب کنید:" sys_choice
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
			echo "شما هسته BBRv3 xanmod را نصب کرده‌اید"
			echo "نسخه فعلی هسته: $kernel_version"

			echo
			echo "مدیریت هسته"
			echo "------------------------"
			echo "1. به‌روزرسانی هسته BBRv3              2. حذف هسته BBRv3"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			Ask "انتخاب خود را وارد کنید: " sub_choice

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

				echo "هسته XanMod به‌روزرسانی شد. پس از راه‌اندازی مجدد اعمال می‌شود"
				rm -f /etc/apt/sources.list.d/xanmod-release.list
				rm -f check_x86-64_psabi.sh*

				server_reboot

				;;
			2)
				apt purge -y 'linux-*xanmod1*'
				update-grub
				echo "هسته XanMod حذف شد. پس از راه‌اندازی مجدد اعمال می‌شود"
				server_reboot
				;;

			*)
				break
				;;

			esac
		done
	else

		clear
		echo "فعال‌سازی شتاب‌دهنده BBR3"
		echo "معرفی ویدئو: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		echo "------------------------------------------------"
		echo "فقط Debian/Ubuntu پشتیبانی می‌شود"
		echo "لطفاً از داده‌های خود پشتیبان تهیه کنید، هسته لینوکس شما برای فعال‌سازی BBR3 ارتقا خواهد یافت"
		echo "VPS دارای 512 مگابایت حافظه است، لطفاً قبل از آن 1 گیگابایت حافظه مجازی اضافه کنید تا از قطع شدن به دلیل کمبود حافظه جلوگیری شود!"
		echo "------------------------------------------------"
		Ask "آیا از ادامه مطمئن هستید؟ (y/N):" choice

		case "$choice" in
		[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "محیط فعلی پشتیبانی نمی‌شود، فقط سیستم‌های Debian و Ubuntu پشتیبانی می‌شوند"
					break_end
					linux_Settings
				fi
			else
				echo "نوع سیستم عامل قابل تعیین نیست"
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

			echo "نصب هسته XanMod و فعال‌سازی BBR3 با موفقیت انجام شد. پس از راه‌اندازی مجدد اعمال می‌شود"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			;;
		[Nn])
			echo "لغو شد"
			;;
		*)
			echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
			;;
		esac
	fi

}

elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "وارد کردن کلید عمومی GPG ELRepo..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ $os_name != *"Red Hat"* && $os_name != *"AlmaLinux"* && $os_name != *"Rocky"* && $os_name != *"Oracle"* && $os_name != *"CentOS"* ]]; then
		echo "سیستم عامل پشتیبانی نشده: $os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "سیستم عامل شناسایی شده: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ $os_version == 8 ]]; then
		echo "نصب پیکربندی مخزن ELRepo (نسخه 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ $os_version == 9 ]]; then
		echo "نصب پیکربندی مخزن ELRepo (نسخه 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ $os_version == 10 ]]; then
		echo "نصب پیکربندی مخزن ELRepo (نسخه 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "نسخه سیستم عامل پشتیبانی نشده: $os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "فعال‌سازی مخزن هسته ELRepo و نصب آخرین هسته mainline..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "پیکربندی مخزن ELRepo نصب و به آخرین هسته mainline به‌روزرسانی شد."
	server_reboot

}

elrepo() {
	root_use
	send_stats "红帽内核管理"
	if uname -r | grep -q 'elrepo'; then
		while true; do
			clear
			kernel_version=$(uname -r)
			echo "شما هسته elrepo را نصب کرده‌اید"
			echo "نسخه فعلی هسته: $kernel_version"

			echo
			echo "مدیریت هسته"
			echo "------------------------"
			echo "1. به‌روزرسانی هسته elrepo              2. حذف هسته elrepo"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			Ask "انتخاب خود را وارد کنید: " sub_choice

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
				echo "هسته elrepo حذف شد. پس از راه‌اندازی مجدد اعمال می‌شود"
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
		echo "لطفاً از داده‌های خود پشتیبان تهیه کنید، هسته لینوکس شما ارتقا خواهد یافت"
		echo "معرفی ویدئو: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		echo "------------------------------------------------"
		echo "فقط توزیع‌های خانواده Red Hat CentOS/RedHat/Alma/Rocky/oracle پشتیبانی می‌شوند "
		echo "ارتقاء هسته لینوکس می‌تواند عملکرد و امنیت سیستم را بهبود بخشد، توصیه می‌شود در صورت امکان امتحان کنید، در محیط تولید با احتیاط ارتقا دهید!"
		echo "------------------------------------------------"
		Ask "آیا از ادامه مطمئن هستید؟ (y/N):" choice

		case "$choice" in
		[Yy])
			check_swap
			elrepo_install
			send_stats "升级红帽内核"
			server_reboot
			;;
		[Nn])
			echo "لغو شد"
			;;
		*)
			echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
			;;
		esac
	fi

}

clamav_freshclam() {
	echo -e "${gl_huang}در حال به روز رسانی پایگاه داده ویروس...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "لطفاً دایرکتوری مورد نظر برای اسکن را مشخص کنید."
		return
	fi

	echo -e "${gl_huang}در حال اسکن دایرکتوری $@... ${gl_bai}"

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

	echo -e "${gl_lv}$@ اسکن کامل شد، گزارش ویروس در ${gl_huang}/home/docker/clamav/log/scan.log${gl_bai} ذخیره شده است."
	echo -e "${gl_lv}اگر ویروس وجود دارد، کلمه FOUND را در فایل ${gl_huang}scan.log${gl_lv} جستجو کنید تا موقعیت ویروس را تأیید کنید. ${gl_bai}"

}

clamav() {
	root_use
	send_stats "病毒扫描管理"
	while true; do
		clear
		echo "ابزار اسکن ویروس clamav"
		echo "معرفی ویدئو: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
		echo "------------------------"
		echo "یک ابزار نرم‌افزار ضد ویروس منبع باز است که عمدتاً برای تشخیص و حذف انواع مختلف بدافزار استفاده می‌شود."
		echo "شامل ویروس‌ها، تروجان‌ها، جاسوس‌افزارها، اسکریپت‌های مخرب و سایر نرم‌افزارهای مضر."
		echo "------------------------"
		echo -e "${gl_lv}1. اسکن کل دیسک ${gl_bai}             ${gl_huang}2. اسکن دایرکتوری های مهم ${gl_bai}            ${gl_kjlan} 3. اسکن دایرکتوری سفارشی ${gl_bai}"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
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
			Ask "لطفاً دایرکتوری‌های مورد نظر برای اسکن را با فاصله وارد کنید (مثال: /etc /var /usr /home /root):" directories
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
	echo -e "${gl_lv}تغییر به حالت ${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}بهینه سازی توصیف فایل...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}بهینه سازی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}سایر بهینه سازی ها...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never >/sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null

}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}تغییر به حالت متعادل...${gl_bai}"

	echo -e "${gl_lv}بهینه سازی توصیف فایل...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}بهینه سازی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}سایر بهینه سازی ها...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}بازگرداندن به تنظیمات پیش فرض...${gl_bai}"

	echo -e "${gl_lv}بازگرداندن توصیف فایل...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}بازگرداندن حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}بازگرداندن تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv}بازگرداندن مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}بازگرداندن تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بازگرداندن سایر بهینه سازی ها...${gl_bai}"
	# 还原透明大页面
	echo always >/sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}

# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}تغییر به حالت بهینه سازی راه اندازی وب سایت...${gl_bai}"

	echo -e "${gl_lv}بهینه سازی توصیف فایل...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}بهینه سازی حافظه مجازی...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات شبکه...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت کش...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}بهینه سازی تنظیمات CPU...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}سایر بهینه سازی ها...${gl_bai}"
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
		echo "بهینه‌سازی پارامترهای هسته سیستم لینوکس"
		echo "معرفی ویدئو: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
		echo "------------------------------------------------"
		echo "حالت‌های مختلف تنظیم پارامترهای سیستم را ارائه می‌دهد، کاربران می‌توانند بر اساس سناریوی استفاده خود انتخاب و جابجا شوند."
		echo -e "${gl_huang}نکته: ${gl_bai}لطفاً در محیط تولید با احتیاط استفاده کنید!"
		echo "--------------------"
		echo "1. حالت بهینه‌سازی عملکرد بالا: حداکثر کردن عملکرد سیستم، بهینه‌سازی توصیف‌گرهای فایل، حافظه مجازی، تنظیمات شبکه، مدیریت حافظه پنهان و تنظیمات CPU."
		echo "2. حالت بهینه‌سازی متعادل: تعادل بین عملکرد و مصرف منابع را برقرار می‌کند، مناسب برای استفاده روزمره."
		echo "3. حالت بهینه‌سازی وب‌سایت: برای سرورهای وب‌سایت بهینه‌سازی شده است، قابلیت پردازش اتصالات همزمان، سرعت پاسخگویی و عملکرد کلی را بهبود می‌بخشد."
		echo "4. حالت بهینه‌سازی پخش زنده: برای نیازهای خاص پخش زنده بهینه شده است، تأخیر را کاهش می‌دهد و عملکرد انتقال را بهبود می‌بخشد."
		echo "5. حالت بهینه‌سازی سرور بازی: برای سرورهای بازی بهینه شده است، قابلیت پردازش همزمان و سرعت پاسخگویی را بهبود می‌بخشد."
		echo "6. بازگرداندن تنظیمات پیش‌فرض: تنظیمات سیستم را به پیکربندی پیش‌فرض بازمی‌گرداند."
		echo "--------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "--------------------"
		Ask "انتخاب خود را وارد کنید: " sub_choice
		case $sub_choice in
		1)
			cd ~
			clear
			local tiaoyou_moshi="حالت بهینه سازی عملکرد بالا"
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
			local tiaoyou_moshi="حالت بهینه سازی پخش زنده"
			optimize_high_performance
			send_stats "直播推流优化"
			;;
		5)
			cd ~
			clear
			local tiaoyou_moshi="حالت بهینه سازی سرور بازی"
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
			echo -e "${gl_lv}زبان سیستم به: $lang تغییر یافت. برای اعمال مجدد به SSH متصل شوید.${gl_bai}"
			hash -r
			break_end

			;;
		centos | rhel | almalinux | rocky | fedora)
			install glibc-langpack-zh
			localectl set-locale LANG=${lang}
			echo "LANG=${lang}" | tee /etc/locale.conf
			echo -e "${gl_lv}زبان سیستم به: $lang تغییر یافت. برای اعمال مجدد به SSH متصل شوید.${gl_bai}"
			hash -r
			break_end
			;;
		*)
			echo "سیستم پشتیبانی نشده: $ID"
			break_end
			;;
		esac
	else
		echo "سیستم پشتیبانی نشده، نوع سیستم قابل تشخیص نیست."
		break_end
	fi
}

linux_language() {
	root_use
	send_stats "切换系统语言"
	while true; do
		clear
		echo "زبان فعلی سیستم: $LANG"
		echo "------------------------"
		echo "1. انگلیسی          2. چینی ساده شده          3. چینی سنتی"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice

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
	echo -e "${gl_lv}تغییرات کامل شد. پس از اتصال مجدد به SSH می توانید تغییرات را مشاهده کنید!${gl_bai}"

	hash -r
	break_end

}

shell_bianse() {
	root_use
	send_stats "命令行美化工具"
	while true; do
		clear
		echo "ابزار زیباسازی خط فرمان"
		echo "------------------------"
		echo -e "1. \\033[1;32mroot \\033[1;34mlocalhost \\033[1;31m~ \\033[0m${gl_bai}#"
		echo -e "2. \\033[1;35mroot \\033[1;36mlocalhost \\033[1;33m~ \\033[0m${gl_bai}#"
		echo -e "3. \\033[1;31mroot \\033[1;32mlocalhost \\033[1;34m~ \\033[0m${gl_bai}#"
		echo -e "4. \\033[1;36mroot \\033[1;33mlocalhost \\033[1;37m~ \\033[0m${gl_bai}#"
		echo -e "5. \\033[1;37mroot \\033[1;31mlocalhost \\033[1;32m~ \\033[0m${gl_bai}#"
		echo -e "6. \\033[1;33mroot \\033[1;34mlocalhost \\033[1;35m~ \\033[0m${gl_bai}#"
		echo -e "7. root localhost ~ #"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice

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
			trash_status="${gl_hui} فعال نیست${gl_bai}"
		else
			trash_status="${gl_lv} فعال است${gl_bai}"
		fi

		clear
		echo -e "سطل بازیافت فعلی ${trash_status}"
		echo -e "پس از فعال شدن، فایل های حذف شده با rm ابتدا وارد سطل بازیافت می شوند تا از حذف تصادفی فایل های مهم جلوگیری شود!"
		echo "------------------------------------------------"
		ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "سطل بازیافت خالی است"
		echo "------------------------"
		echo "1. فعال کردن سطل بازیافت          2. غیرفعال کردن سطل بازیافت"
		echo "3. بازیابی محتویات            4. خالی کردن سطل بازیافت"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice

		case $choice in
		1)
			install trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='trash-put'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "سطل بازیافت فعال شد، فایل‌های حذف شده به سطل بازیافت منتقل می‌شوند."
			sleep 2
			;;
		2)
			remove trash-cli
			sed -i '/alias rm/d' "$bashrc_profile"
			echo "alias rm='rm -i'" >>"$bashrc_profile"
			source "$bashrc_profile"
			echo "سطل بازیافت غیرفعال شد، فایل‌ها مستقیماً حذف می‌شوند."
			sleep 2
			;;
		3)
			Ask "نام فایل مورد نظر برای بازیابی را وارد کنید:" file_to_restore
			if [ -e "$TRASH_DIR/$file_to_restore" ]; then
				mv "$TRASH_DIR/$file_to_restore" "$HOME/"
				echo "$file_to_restore در دایرکتوری اصلی بازیابی شد."
			else
				echo "فایل وجود ندارد."
			fi
			;;
		4)
			Ask "آیا از خالی کردن سطل بازیافت مطمئن هستید؟ (y/N):" confirm
			if [[ $confirm == "y" ]]; then
				trash-empty
				echo "سطل بازیافت خالی شد."
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
	echo "ایجاد نمونه پشتیبان:"
	echo "  - پشتیبان‌گیری از یک دایرکتوری: /var/www"
	echo "  - پشتیبان‌گیری از چندین دایرکتوری: /etc /home /var/log"
	echo "  - فشار دادن Enter بدون ورودی از دایرکتوری‌های پیش‌فرض (/etc /usr /home) استفاده خواهد کرد"
	Ask "لطفاً دایرکتوری‌های مورد نظر برای پشتیبان‌گیری را وارد کنید (چندین دایرکتوری را با فاصله جدا کنید، زدن Enter پیش‌فرض را انتخاب می‌کند):" input

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
	echo "دایرکتوری پشتیبان انتخاب شده شما:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 创建备份
	echo "در حال ایجاد پشتیبان $BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 检查命令是否成功
	if [ $? -eq 0 ]; then
		echo "پشتیبان با موفقیت ایجاد شد: $BACKUP_DIR/$BACKUP_NAME"
	else
		echo "ایجاد پشتیبان ناموفق بود!"
		exit 1
	fi
}

# 恢复备份
restore_backup() {
	send_stats "恢复备份"
	# 选择要恢复的备份
	Ask "لطفاً نام فایل پشتیبان مورد نظر برای بازیابی را وارد کنید:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "فایل پشتیبان وجود ندارد!"
		exit 1
	fi

	echo "در حال بازیابی پشتیبان $BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "بازیابی پشتیبان با موفقیت انجام شد!"
	else
		echo "بازیابی پشتیبان با شکست مواجه شد!"
		exit 1
	fi
}

# 列出备份
list_backups() {
	echo "پشتیبان‌های موجود:"
	ls -1 "$BACKUP_DIR"
}

# 删除备份
delete_backup() {
	send_stats "删除备份"

	Ask "لطفاً نام فایل پشتیبان مورد نظر برای حذف را وارد کنید:" BACKUP_NAME

	# 检查备份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "فایل پشتیبان وجود ندارد!"
		exit 1
	fi

	# 删除备份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "حذف پشتیبان با موفقیت انجام شد!"
	else
		echo "حذف پشتیبان با شکست مواجه شد!"
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
		echo "عملکرد پشتیبان‌گیری سیستم"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. ایجاد پشتیبان        2. بازیابی پشتیبان        3. حذف پشتیبان"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1) create_backup ;;
		2) restore_backup ;;
		3) delete_backup ;;
		*) break ;;
		esac
		Press "برای ادامه کلید Enter را فشار دهید..."
	done
}

# 显示连接列表
list_connections() {
	echo "اتصالات ذخیره شده:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}

# 添加新连接
add_connection() {
	send_stats "添加新连接"
	echo "نمونه ایجاد اتصال جدید:"
	echo "  - نام اتصال: my_server"
	echo "  - آدرس IP: 192.168.1.100"
	echo "  - نام کاربری: root"
	echo "  - پورت: 22"
	echo "------------------------"
	Ask "لطفاً نام اتصال را وارد کنید:" name
	Ask "لطفاً آدرس IP را وارد کنید:" ip
	Ask "لطفاً نام کاربری را وارد کنید (پیش‌فرض: root):" user
	local user=${user:-root} # 如果用户未输入，则使用默认值 root
	Ask "لطفاً شماره پورت را وارد کنید (پیش‌فرض: 22):" port
	local port=${port:-22} # 如果用户未输入，则使用默认值 22

	echo "لطفاً روش احراز هویت را انتخاب کنید:"
	echo "1. رمز عبور"
	echo "2. کلید"
	Ask "لطفاً گزینه را انتخاب کنید (1/2):" auth_choice

	case $auth_choice in
	1)
		Ask "لطفاً رمز عبور را وارد کنید:" -s password_or_key
		echo # 换行
		;;
	2)
		echo "لطفاً محتوای کلید را بچسبانید (پس از چسباندن دو بار Enter را فشار دهید):"
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
		echo "انتخاب نامعتبر!"
		return
		;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >>"$CONFIG_FILE"
	echo "اتصال ذخیره شد!"
}

# 删除连接
delete_connection() {
	send_stats "删除连接"
	Ask "لطفاً شماره اتصال مورد نظر برای حذف را وارد کنید:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $connection ]]; then
		echo "خطا: اتصال مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	# 如果连接使用的是密钥文件，则删除该密钥文件
	if [[ $password_or_key == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "اتصال حذف شد!"
}

# 使用连接
use_connection() {
	send_stats "使用连接"
	Ask "لطفاً شماره اتصال مورد نظر برای استفاده را وارد کنید:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $connection ]]; then
		echo "خطا: اتصال مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<<"$connection"

	echo "در حال اتصال به $name ($ip)..."
	if [[ -f $password_or_key ]]; then
		# 使用密钥连接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال با شکست مواجه شد! لطفاً موارد زیر را بررسی کنید:"
			echo "1. آیا مسیر فایل کلید صحیح است: $password_or_key"
			echo "2. آیا مجوزهای فایل کلید صحیح است (باید 600 باشد)."
			echo "3. آیا سرور مقصد اجازه ورود با کلید را می‌دهد."
		fi
	else
		# 使用密码连接
		if ! command -v sshpass &>/dev/null; then
			echo "خطا: sshpass نصب نشده است، لطفاً ابتدا sshpass را نصب کنید."
			echo "روش نصب:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال با شکست مواجه شد! لطفاً موارد زیر را بررسی کنید:"
			echo "1. آیا نام کاربری و رمز عبور صحیح هستند."
			echo "2. آیا سرور مقصد اجازه ورود با رمز عبور را می‌دهد."
			echo "3. آیا سرویس SSH سرور مقصد به درستی کار می‌کند."
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
		echo "ابزار اتصال از راه دور SSH"
		echo "می‌توانید از طریق SSH به سایر سیستم‌های لینوکس متصل شوید"
		echo "------------------------"
		list_connections
		echo "1. ایجاد اتصال جدید        2. استفاده از اتصال        3. حذف اتصال"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1) add_connection ;;
		2) use_connection ;;
		3) delete_connection ;;
		0) break ;;
		*) echo "انتخاب نامعتبر، لطفاً دوباره امتحان کنید." ;;
		esac
	done
}

# 列出可用的硬盘分区
list_partitions() {
	echo "پارتیشن‌های دیسک موجود:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 挂载分区
mount_partition() {
	send_stats "挂载分区"
	Ask "لطفاً نام پارتیشن مورد نظر برای مانت کردن را وارد کنید (مثال sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن از قبل مانت شده است!"
		return
	fi

	# 创建挂载点
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 挂载分区
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "مانت پارتیشن با موفقیت انجام شد: $MOUNT_POINT"
	else
		echo "مانت پارتیشن با شکست مواجه شد!"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸载分区
unmount_partition() {
	send_stats "卸载分区"
	Ask "لطفاً نام پارتیشن مورد نظر برای آنمانت کردن را وارد کنید (مثال sda1):" PARTITION

	# 检查分区是否已经挂载
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "پارتیشن مانت نشده است!"
		return
	fi

	# 卸载分区
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "باز کردن پارتیشن با موفقیت انجام شد: $MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "باز کردن پارتیشن با شکست مواجه شد!"
	fi
}

# 列出已挂载的分区
list_mounted_partitions() {
	echo "پارتیشن‌های مانت شده:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分区
format_partition() {
	send_stats "格式化分区"
	Ask "لطفاً نام پارتیشن مورد نظر برای فرمت کردن را وارد کنید (مثال sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# 检查分区是否已经挂载
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن از قبل مانت شده است، لطفاً ابتدا آن را باز کنید!"
		return
	fi

	# 选择文件系统类型
	echo "لطفاً نوع سیستم فایل را انتخاب کنید:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	Ask "انتخاب خود را وارد کنید: " FS_CHOICE

	case $FS_CHOICE in
	1) FS_TYPE="ext4" ;;
	2) FS_TYPE="xfs" ;;
	3) FS_TYPE="ntfs" ;;
	4) FS_TYPE="vfat" ;;
	*)
		echo "انتخاب نامعتبر!"
		return
		;;
	esac

	# 确认格式化
	Ask "آیا از فرمت کردن پارتیشن /dev/$PARTITION با فرمت $FS_TYPE مطمئن هستید؟ (y/N):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "عملیات لغو شد."
		return
	fi

	# 格式化分区
	echo "در حال فرمت کردن پارتیشن /dev/$PARTITION به $FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "فرمت پارتیشن با موفقیت انجام شد!"
	else
		echo "فرمت پارتیشن با شکست مواجه شد!"
	fi
}

# 检查分区状态
check_partition() {
	send_stats "检查分区状态"
	Ask "لطفاً نام پارتیشن مورد نظر برای بررسی را وارد کنید (مثال sda1):" PARTITION

	# 检查分区是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" >/dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# 检查分区状态
	echo "بررسی وضعیت پارتیشن /dev/$PARTITION:"
	fsck "/dev/$PARTITION"
}

# 主菜单
disk_manager() {
	send_stats "硬盘管理功能"
	while true; do
		clear
		echo "مدیریت پارتیشن دیسک"
		echo -e "${gl_huang}این قابلیت در مرحله تست داخلی است، لطفاً در محیط تولید استفاده نکنید.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. مانت پارتیشن        2. باز کردن پارتیشن        3. مشاهده پارتیشن‌های مانت شده"
		echo "4. فرمت پارتیشن      5. بررسی وضعیت پارتیشن"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1) mount_partition ;;
		2) unmount_partition ;;
		3) list_mounted_partitions ;;
		4) format_partition ;;
		5) check_partition ;;
		*) break ;;
		esac
		Press "برای ادامه کلید Enter را فشار دهید..."
	done
}

# 显示任务列表
list_tasks() {
	echo "وظایف همگام‌سازی ذخیره شده:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任务
add_task() {
	send_stats "添加新同步任务"
	echo "نمونه ایجاد وظیفه همگام‌سازی جدید:"
	echo "  - نام وظیفه: backup_www"
	echo "  - دایرکتوری محلی: /var/www"
	echo "  - آدرس راه دور: user@192.168.1.100"
	echo "  - دایرکتوری راه دور: /backup/www"
	echo "  - شماره پورت (پیش‌فرض 22)"
	echo "---------------------------------"
	Ask "لطفاً نام وظیفه را وارد کنید:" name
	Ask "لطفاً دایرکتوری محلی را وارد کنید:" local_path
	Ask "لطفاً دایرکتوری راه دور را وارد کنید:" remote_path
	Ask "لطفاً کاربر@IP راه دور را وارد کنید:" remote
	Ask "لطفاً پورت SSH را وارد کنید (پیش‌فرض 22):" port
	port=${port:-22}

	echo "لطفاً روش احراز هویت را انتخاب کنید:"
	echo "1. رمز عبور"
	echo "2. کلید"
	Ask "لطفاً گزینه را انتخاب کنید (1/2):" auth_choice

	case $auth_choice in
	1)
		Ask "لطفاً رمز عبور را وارد کنید:" -s password_or_key
		echo # 换行
		auth_method="password"
		;;
	2)
		echo "لطفاً محتوای کلید را بچسبانید (پس از چسباندن دو بار Enter را فشار دهید):"
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
			echo "محتوای کلید نامعتبر!"
			return
		fi
		;;
	*)
		echo "انتخاب نامعتبر!"
		return
		;;
	esac

	echo "لطفاً حالت همگام‌سازی را انتخاب کنید:"
	echo "1. حالت استاندارد (-avz)"
	echo "2. حذف فایل‌های مقصد (-avz --delete)"
	Ask "لطفاً گزینه را انتخاب کنید (1/2):" mode
	case $mode in
	1) options="-avz" ;;
	2) options="-avz --delete" ;;
	*)
		echo "انتخاب نامعتبر، از پیش‌فرض -avz استفاده می‌شود"
		options="-avz"
		;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >>"$CONFIG_FILE"

	install rsync rsync

	echo "وظیفه ذخیره شد!"
}

# 删除任务
delete_task() {
	send_stats "删除同步任务"
	Ask "لطفاً شماره وظیفه مورد نظر برای حذف را وارد کنید:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $task ]]; then
		echo "خطا: وظیفه مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 如果任务使用的是密钥文件，则删除该密钥文件
	if [[ $auth_method == "key" && $password_or_key == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "وظیفه حذف شد!"
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
		Ask "لطفاً شماره وظیفه مورد نظر برای اجرا را وارد کنید:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z $task ]]; then
		echo "خطا: این وظیفه یافت نشد!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<<"$task"

	# 根据同步方向调整源和目标路径
	if [[ $direction == "pull" ]]; then
		echo "در حال کشیدن همگام‌سازی به محلی: $remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "در حال ارسال همگام‌سازی به راه دور: $local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 连接通用参数
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ $auth_method == "password" ]]; then
		if ! command -v sshpass &>/dev/null; then
			echo "خطا: sshpass نصب نشده است، لطفاً ابتدا sshpass را نصب کنید."
			echo "روش نصب:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 检查密钥文件是否存在和权限是否正确
		if [[ ! -f $password_or_key ]]; then
			echo "خطا: فایل کلید یافت نشد: $password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "هشدار: مجوزهای فایل کلید نادرست است، در حال اصلاح..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "همگام‌سازی کامل شد!"
	else
		echo "همگام‌سازی با شکست مواجه شد! لطفاً موارد زیر را بررسی کنید:"
		echo "1. آیا اتصال شبکه عادی است"
		echo "2. آیا میزبان راه دور قابل دسترسی است"
		echo "3. آیا اطلاعات احراز هویت صحیح است"
		echo "4. آیا دایرکتوری‌های محلی و راه دور دارای مجوزهای دسترسی صحیح هستند"
	fi
}

# 创建定时任务
schedule_task() {
	send_stats "添加同步定时任务"

	Ask "لطفاً شماره وظیفه زمان‌بندی شده برای همگام‌سازی را وارد کنید:" num
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً شماره وظیفه معتبری وارد کنید!"
		return
	fi

	echo "لطفاً فاصله زمانی اجرای زمان‌بندی شده را انتخاب کنید:"
	echo "1) هر ساعت یک بار اجرا شود"
	echo "2) هر روز یک بار اجرا شود"
	echo "3) هر هفته یک بار اجرا شود"
	Ask "لطفاً گزینه را انتخاب کنید (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)
	# 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
	1) cron_time="$random_minute * * * *" ;; # 每小时，随机分钟执行
	2) cron_time="$random_minute 0 * * *" ;; # 每天，随机分钟执行
	3) cron_time="$random_minute 0 * * 1" ;; # 每周，随机分钟执行
	*)
		echo "خطا: لطفاً یک گزینه معتبر وارد کنید!"
		return
		;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 检查是否已存在相同任务
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "خطا: همگام‌سازی زمان‌بندی شده برای این وظیفه از قبل وجود دارد!"
		return
	fi

	# 创建到用户的 crontab
	(
		crontab -l 2>/dev/null
		echo "$cron_job"
	) | crontab -
	echo "وظیفه زمان‌بندی شده ایجاد شد: $cron_job"
}

# 查看定时任务
view_tasks() {
	echo "وظایف زمان‌بندی شده فعلی:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 删除定时任务
delete_task_schedule() {
	send_stats "删除同步定时任务"
	Ask "لطفاً شماره وظیفه مورد نظر برای حذف را وارد کنید:" num
	if ! [[ $num =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً شماره وظیفه معتبری وارد کنید!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "وظیفه زمان‌بندی شده با شماره $num حذف شد"
}

# 任务管理主菜单
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "ابزار همگام‌سازی راه دور Rsync"
		echo "همگام‌سازی بین دایرکتوری‌های راه دور، پشتیبانی از همگام‌سازی افزایشی، کارآمد و پایدار."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. ایجاد وظیفه جدید                 2. حذف وظیفه"
		echo "3. اجرای همگام سازی محلی به راه دور         4. اجرای همگام سازی راه دور به محلی"
		echo "5. ایجاد وظیفه زمانبندی شده               6. حذف وظیفه زمانبندی شده"
		echo "---------------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "---------------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
		case $choice in
		1) add_task ;;
		2) delete_task ;;
		3) run_task push ;;
		4) run_task pull ;;
		5) schedule_task ;;
		6) delete_task_schedule ;;
		0) break ;;
		*) echo "انتخاب نامعتبر، لطفاً دوباره امتحان کنید." ;;
		esac
		Press "برای ادامه کلید Enter را فشار دهید..."
	done
}

linux_ps() {
	clear
	send_stats "系统信息查询"

	ip_address

	echo
	echo -e "پرس و جوی اطلاعات سیستم"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}نام میزبان:       ${gl_bai}$(uname -n || hostname)"
	echo -e "${gl_kjlan}نسخه سیستم:     ${gl_bai}$(ChkOs)"
	echo -e "${gl_kjlan}نسخه لینوکس:    ${gl_bai}$(uname -r)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}معماری CPU:      ${gl_bai}$(uname -m)"
	echo -e "${gl_kjlan}مدل CPU:      ${gl_bai}$(CpuModel)"
	echo -e "${gl_kjlan}تعداد هسته CPU:    ${gl_bai}$(nproc)"
	echo -e "${gl_kjlan}فرکانس CPU:      ${gl_bai}$(CpuFreq)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}مصرف CPU:      ${gl_bai}$(CpuUsage)%"
	echo -e "${gl_kjlan}بار سیستم:     ${gl_bai}$(LoadAvg)"
	echo -e "${gl_kjlan}حافظه فیزیکی:     ${gl_bai}$(MemUsage)"
	echo -e "${gl_kjlan}حافظه مجازی:     ${gl_bai}$(SwapUsage)"
	echo -e "${gl_kjlan}مصرف دیسک:     ${gl_bai}$(DiskUsage)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}کل دریافت:       ${gl_bai}$(ConvSz $(Iface --rx_bytes))"
	echo -e "${gl_kjlan}کل ارسال:       ${gl_bai}$(ConvSz $(Iface --tx_bytes))"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}الگوریتم شبکه:     ${gl_bai}$(sysctl -n net.ipv4.tcp_congestion_control) $(sysctl -n net.core.default_qdisc)"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}اپراتور:       ${gl_bai}$(NetProv)"
	echo -e "${gl_kjlan}آدرس IPv4:     ${gl_bai}$(IpAddr --ipv4)"
	echo -e "${gl_kjlan}آدرس IPv6:     ${gl_bai}$(IpAddr --ipv6)"
	echo -e "${gl_kjlan}آدرس DNS:      ${gl_bai}$(DnsAddr)"
	echo -e "${gl_kjlan}موقعیت جغرافیایی:     ${gl_bai}$(Loc --country)$(Loc --city)"
	echo -e "${gl_kjlan}زمان سیستم:     ${gl_bai}$(TimeZn --internal)$(date +"%Y-%m-%d %H:%M:%S")"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}زمان اجرا:     ${gl_bai}$(uptime -p | sed 's/up //')"
	echo
}

linux_tools() {

	while true; do
		clear
		# send_stats "基础工具"
		echo -e "ابزارهای پایه"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}ابزار دانلود curl ${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}ابزار دانلود wget ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}3.   ${gl_bai}ابزار مدیریت فوق العاده sudo             ${gl_kjlan}4.   ${gl_bai}ابزار اتصال ارتباطی socat"
		echo -e "${gl_kjlan}5.   ${gl_bai}ابزار نظارت سیستم htop                 ${gl_kjlan}6.   ${gl_bai}ابزار نظارت ترافیک شبکه iftop"
		echo -e "${gl_kjlan}7.   ${gl_bai}ابزار فشرده سازی و استخراج ZIP unzip             ${gl_kjlan}8.   ${gl_bai}ابزار فشرده سازی و استخراج GZ tar"
		echo -e "${gl_kjlan}9.   ${gl_bai}ابزار اجرای چندگانه در پس زمینه tmux             ${gl_kjlan}10.  ${gl_bai}ابزار کدگذاری ویدئو و پخش زنده ffmpeg"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}ابزار نظارت مدرن btop ${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ابزار مدیریت فایل ranger"
		echo -e "${gl_kjlan}13.  ${gl_bai}ابزار مشاهده مصرف دیسک ncdu             ${gl_kjlan}14.  ${gl_bai}ابزار جستجوی سراسری fzf"
		echo -e "${gl_kjlan}15.  ${gl_bai}ویرایشگر متن vim                    ${gl_kjlan}16.  ${gl_bai}ویرایشگر متن nano ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}17.  ${gl_bai}سیستم کنترل نسخه git"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}محافظ صفحه نمایش ماتریکس                      ${gl_kjlan}22.  ${gl_bai}محافظ صفحه نمایش قطار در حال حرکت"
		echo -e "${gl_kjlan}26.  ${gl_bai}بازی کوچک تتریس                  ${gl_kjlan}27.  ${gl_bai}بازی کوچک مار خوراک"
		echo -e "${gl_kjlan}28.  ${gl_bai}بازی کوچک مهاجمان فضا"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}نصب همه                          ${gl_kjlan}32.  ${gl_bai}نصب همه (بدون محافظ صفحه نمایش و بازی) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}حذف همه"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}نصب ابزار مشخص                      ${gl_kjlan}42.  ${gl_bai}حذف ابزار مشخص"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			clear
			install curl
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
			curl --help
			send_stats "安装curl"
			;;
		2)
			clear
			install wget
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
			wget --help
			send_stats "安装wget"
			;;
		3)
			clear
			install sudo
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
			sudo --help
			send_stats "安装sudo"
			;;
		4)
			clear
			install socat
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
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
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
			unzip
			send_stats "安装unzip"
			;;
		8)
			clear
			install tar
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
			tar --help
			send_stats "安装tar"
			;;
		9)
			clear
			install tmux
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
			tmux --help
			send_stats "安装tmux"
			;;
		10)
			clear
			install ffmpeg
			clear
			echo "ابزار نصب شده است، نحوه استفاده به شرح زیر است:"
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
			Ask "لطفاً نام ابزار مورد نظر برای نصب را وارد کنید (wget curl sudo htop):" installname
			install $installname
			send_stats "安装指定软件"
			;;
		42)
			clear
			Ask "لطفاً نام ابزار مورد نظر برای حذف را وارد کنید (htop ufw tmux cmatrix):" removename
			remove $removename
			send_stats "卸载指定软件"
			;;

		0)
			kejilion
			;;

		*)
			echo "ورودی نامعتبر!"
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
			echo "الگوریتم انسداد TCP فعلی: $congestion_algorithm $queue_algorithm"

			echo
			echo "مدیریت BBR"
			echo "------------------------"
			echo "1. فعال کردن BBRv3              2. غیرفعال کردن BBRv3 (راه اندازی مجدد خواهد شد)"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			Ask "انتخاب خود را وارد کنید: " sub_choice

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
		echo -e "مدیریت Docker"
		docker_tato
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}نصب و به روز رسانی محیط Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}2.   ${gl_bai}مشاهده وضعیت کلی Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}مدیریت کانتینرهای Docker ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}4.   ${gl_bai}مدیریت ایمیج های Docker"
		echo -e "${gl_kjlan}5.   ${gl_bai}مدیریت شبکه های Docker"
		echo -e "${gl_kjlan}6.   ${gl_bai}مدیریت Volume های Docker"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}7.   ${gl_bai}پاکسازی کانتینرها، ایمیج ها و Volume های شبکه Docker استفاده نشده"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}8.   ${gl_bai}تغییر منبع Docker"
		echo -e "${gl_kjlan}9.   ${gl_bai}ویرایش فایل daemon.json"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}فعال کردن دسترسی IPv6 Docker"
		echo -e "${gl_kjlan}12.  ${gl_bai}غیرفعال کردن دسترسی IPv6 Docker"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}20.  ${gl_bai}حذف محیط Docker"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

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
			echo "نسخه Docker"
			docker -v
			docker compose version

			echo
			echo -e "ایمیج های Docker: ${gl_lv}$image_count${gl_bai} "
			docker image ls
			echo
			echo -e "کانتینرهای Docker: ${gl_lv}$container_count${gl_bai}"
			docker ps -a
			echo
			echo -e "Docker Volume: ${gl_lv}$volume_count${gl_bai}"
			docker volume ls
			echo
			echo -e "Docker Network: ${gl_lv}$network_count${gl_bai}"
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
				echo "لیست شبکه های Docker"
				echo "------------------------------------------------------------"
				docker network ls
				echo

				echo "------------------------------------------------------------"
				container_ids=$(docker ps -q)
				echo "نام کانتینر              نام شبکه              آدرس IP"

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
				echo "عملیات شبکه"
				echo "------------------------"
				echo "1. ایجاد شبکه"
				echo "2. پیوستن به شبکه"
				echo "3. خروج از شبکه"
				echo "4. حذف شبکه"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					send_stats "创建网络"
					Ask "نام شبکه جدید را تنظیم کنید:" dockernetwork
					docker network create $dockernetwork
					;;
				2)
					send_stats "加入网络"
					Ask "نام شبکه را وارد کنید:" dockernetwork
					Ask "کدام کانتینرها به این شبکه اضافه شوند (برای نام‌های چندگانه از فاصله استفاده کنید):" dockernames

					for dockername in $dockernames; do
						docker network connect $dockernetwork $dockername
					done
					;;
				3)
					send_stats "加入网络"
					Ask "نام شبکه را خروج کنید:" dockernetwork
					Ask "کدام کانتینرها از این شبکه خارج شوند (برای نام‌های چندگانه از فاصله استفاده کنید):" dockernames

					for dockername in $dockernames; do
						docker network disconnect $dockernetwork $dockername
					done

					;;

				4)
					send_stats "删除网络"
					Ask "لطفاً نام شبکه مورد نظر برای حذف را وارد کنید:" dockernetwork
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
				echo "لیست Volume های Docker"
				docker volume ls
				echo
				echo "عملیات Volume"
				echo "------------------------"
				echo "1. ایجاد Volume جدید"
				echo "2. حذف Volume مشخص شده"
				echo "3. حذف همه Volume ها"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					send_stats "新建卷"
					Ask "نام والیوم جدید را تنظیم کنید:" dockerjuan
					docker volume create $dockerjuan

					;;
				2)
					Ask "نام والیوم‌های مورد نظر برای حذف را وارد کنید (برای نام‌های چندگانه از فاصله استفاده کنید):" dockerjuans

					for dockerjuan in $dockerjuans; do
						docker volume rm $dockerjuan
					done

					;;

				3)
					send_stats "删除所有卷"
					Ask "${gl_hong}توجه:${gl_bai} آیا از حذف تمام والیوم‌های استفاده نشده مطمئن هستید؟ (y/N):" choice
					case "$choice" in
					[Yy])
						docker volume prune -f
						;;
					[Nn]) ;;
					*)
						echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			Ask "${gl_huang}نکته:${gl_bai} ایمیج‌ها، کانتینرها و شبکه‌های بدون استفاده، شامل کانتینرهای متوقف شده، پاکسازی خواهند شد. آیا از پاکسازی مطمئن هستید؟ (y/N):" choice
			case "$choice" in
			[Yy])
				docker system prune -af --volumes
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			Ask "${gl_hong}توجه:${gl_bai} آیا از آنمانت کردن محیط داکر مطمئن هستید؟ (y/N):" choice
			case "$choice" in
			[Yy])
				docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				remove docker docker-compose docker-ce docker-ce-cli containerd.io
				rm -f /etc/docker/daemon.json
				hash -r
				;;
			[Nn]) ;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion
			;;
		*)
			echo "ورودی نامعتبر!"
			;;
		esac
		break_end

	done

}

linux_test() {

	while true; do
		clear
		# send_stats "测试脚本合集"
		echo -e "مجموعه اسکریپت های تست"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}بررسی وضعیت IP و رفع انسداد"
		echo -e "${gl_kjlan}1.   ${gl_bai}بررسی وضعیت رفع انسداد ChatGPT"
		echo -e "${gl_kjlan}2.   ${gl_bai}تست رفع انسداد استریمینگ Region"
		echo -e "${gl_kjlan}3.   ${gl_bai}بررسی رفع انسداد استریمینگ yeahwu"
		echo -e "${gl_kjlan}4.   ${gl_bai}اسکریپت تست کیفیت IP xykt ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست سرعت خطوط شبکه"
		echo -e "${gl_kjlan}11.  ${gl_bai}تست تاخیر و مسیریابی بازگشتی سه شبکه besttrace"
		echo -e "${gl_kjlan}12.  ${gl_bai}تست خطوط بازگشتی سه شبکه mtr_trace"
		echo -e "${gl_kjlan}13.  ${gl_bai}تست سرعت سه شبکه Superspeed"
		echo -e "${gl_kjlan}14.  ${gl_bai}اسکریپت تست بازگشتی سریع nxtrace"
		echo -e "${gl_kjlan}15.  ${gl_bai}اسکریپت تست بازگشتی IP مشخص nxtrace"
		echo -e "${gl_kjlan}16.  ${gl_bai}تست خطوط سه شبکه ludashi2020"
		echo -e "${gl_kjlan}17.  ${gl_bai}اسکریپت تست سرعت چند منظوره i-abc"
		echo -e "${gl_kjlan}18.  ${gl_bai}اسکریپت تست کیفیت شبکه NetQuality ${gl_huang}★${gl_bai}"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست عملکرد سخت افزار"
		echo -e "${gl_kjlan}21.  ${gl_bai}تست عملکرد yabs"
		echo -e "${gl_kjlan}22.  ${gl_bai}اسکریپت تست عملکرد CPU icu/gb5"

		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}تست جامع"
		echo -e "${gl_kjlan}31.  ${gl_bai}تست عملکرد bench"
		echo -e "${gl_kjlan}32.  ${gl_bai}تست ترکیبی spiritysdx ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

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
			echo "لیست IP های قابل ارجاع"
			echo "------------------------"
			echo "پکن تلکام: 219.141.136.12"
			echo "پکن یونیکام: 202.106.50.1"
			echo "پکن موبایل: 221.179.155.161"
			echo "شانگهای تلکام: 202.96.209.133"
			echo "شانگهای یونیکام: 210.22.97.1"
			echo "شانگهای موبایل: 211.136.112.200"
			echo "گوانگژو تلکام: 58.60.188.222"
			echo "گوانگژو یونیکام: 210.21.196.6"
			echo "گوانگژو موبایل: 120.196.165.24"
			echo "چنگدو تلکام: 61.139.2.69"
			echo "چنگدو یونیکام: 119.6.6.6"
			echo "چنگدو موبایل: 211.137.96.205"
			echo "هونان تلکام: 36.111.200.100"
			echo "هونان یونیکام: 42.48.16.100"
			echo "هونان موبایل: 39.134.254.6"
			echo "------------------------"

			Ask "یک IP مشخص را وارد کنید:" testip
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
			echo "ورودی نامعتبر!"
			;;
		esac
		break_end

	done

}

linux_Oracle() {

	while true; do
		clear
		send_stats "甲骨文云脚本合集"
		echo -e "مجموعه اسکریپت های Oracle Cloud"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}اسکریپت فعال سازی ماشین های بیکار"
		echo -e "${gl_kjlan}2.   ${gl_bai}اسکریپت غیرفعال سازی ماشین های بیکار"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}3.   ${gl_bai}اسکریپت نصب مجدد سیستم DD"
		echo -e "${gl_kjlan}4.   ${gl_bai}اسکریپت راه اندازی R探长"
		echo -e "${gl_kjlan}5.   ${gl_bai}فعال سازی حالت ورود با رمز عبور ROOT"
		echo -e "${gl_kjlan}6.   ${gl_bai}ابزار بازیابی IPV6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			clear
			echo "اسکریپت فعال: مصرف CPU 10-20% مصرف حافظه 20% "
			Ask "آیا از نصب مطمئن هستید؟ (y/N):" choice
			case "$choice" in
			[Yy])

				install_docker

				# 设置默认值
				local DEFAULT_CPU_CORE=1
				local DEFAULT_CPU_UTIL="10-20"
				local DEFAULT_MEM_UTIL=20
				local DEFAULT_SPEEDTEST_INTERVAL=120

				# 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				Ask "لطفاً تعداد هسته‌های CPU را وارد کنید [پیش‌فرض: $DEFAULT_CPU_CORE]:" cpu_core
				local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				Ask "لطفاً محدوده درصد استفاده از CPU را وارد کنید (مثال 10-20) [پیش‌فرض: $DEFAULT_CPU_UTIL]:" cpu_util
				local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				Ask "لطفاً درصد استفاده از حافظه را وارد کنید [پیش‌فرض: $DEFAULT_MEM_UTIL]:" mem_util
				local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				Ask "لطفاً فاصله زمانی Speedtest را وارد کنید (ثانیه) [پیش‌فرض: $DEFAULT_SPEEDTEST_INTERVAL]:" speedtest_interval
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
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			echo "نصب مجدد سیستم عامل"
			echo "--------------------------------"
			echo -e "${gl_hong}توجه: ${gl_bai}نصب مجدد خطر قطع ارتباط را دارد، با احتیاط استفاده کنید. نصب مجدد حدود 15 دقیقه طول می کشد، لطفاً قبل از آن از داده های خود پشتیبان تهیه کنید."
			Ask "آیا از ادامه مطمئن هستید؟ (y/N):" choice

			case "$choice" in
			[Yy])
				while true; do
					Ask "لطفاً سیستم مورد نظر برای نصب مجدد را انتخاب کنید: 1. Debian12 | 2. Ubuntu20.04 :" sys_choice

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
						echo "انتخاب نامعتبر، لطفا دوباره وارد کنید."
						;;
					esac
				done

				Ask "لطفاً رمز عبور خود را پس از نصب مجدد وارد کنید:" vpspasswd
				install wget
				bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
				send_stats "甲骨文云重装系统脚本"
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		4)
			clear
			echo "این ویژگی در مرحله توسعه است، لطفا منتظر بمانید!"
			;;
		5)
			clear
			add_sshpasswd

			;;
		6)
			clear
			bash <(curl -L -s jhb.ovh/jb/v6.sh)
			echo "این ویژگی توسط استاد jhb ارائه شده است، از او سپاسگزاریم!"
			send_stats "ipv6修复"
			;;
		0)
			kejilion

			;;
		*)
			echo "ورودی نامعتبر!"
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
		echo -e "${gl_lv}محیط نصب شده است${gl_bai}  کانتینر: ${gl_lv}$container_count${gl_bai}  ایمیج: ${gl_lv}$image_count${gl_bai}  شبکه: ${gl_lv}$network_count${gl_bai}  Volume: ${gl_lv}$volume_count${gl_bai}"
	fi
}

ldnmp_tato() {
	local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
	local output="سایت: ${gl_lv}${cert_count}${gl_bai}"

	local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
	if [ -n "$dbrootpasswd" ]; then
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
	fi

	local db_output="پایگاه داده: ${gl_lv}${db_count}${gl_bai}"

	if command -v docker &>/dev/null; then
		if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
			echo -e "${gl_huang}------------------------"
			echo -e "${gl_lv}محیط نصب شده است${gl_bai}  $output  $db_output"
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
		echo -e "${gl_huang}راه اندازی سایت LDNMP"
		ldnmp_tato
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}1.   ${gl_bai}نصب محیط LDNMP ${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}نصب WordPress ${gl_huang}★${gl_bai}"
		echo -e "${gl_huang}3.   ${gl_bai}نصب انجمن Discuz                    ${gl_huang}4.   ${gl_bai}نصب دسکتاپ ابری Keduoyun"
		echo -e "${gl_huang}5.   ${gl_bai}نصب سایت فیلم و سریال Apple CMS                 ${gl_huang}6.   ${gl_bai}نصب سایت فروش کارت دیجیتال Unicorn"
		echo -e "${gl_huang}7.   ${gl_bai}نصب سایت انجمن Flarum                ${gl_huang}8.   ${gl_bai}نصب وبلاگ سبک Typecho"
		echo -e "${gl_huang}9.   ${gl_bai}نصب پلتفرم لینک اشتراک گذاری LinkStack         ${gl_huang}20.  ${gl_bai}سایت پویا سفارشی"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}21.  ${gl_bai}فقط نصب nginx ${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}تغییر مسیر سایت"
		echo -e "${gl_huang}23.  ${gl_bai}پراکسی معکوس سایت - IP+پورت ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}پراکسی معکوس سایت - دامنه"
		echo -e "${gl_huang}25.  ${gl_bai}نصب پلتفرم مدیریت رمز عبور Bitwarden         ${gl_huang}26.  ${gl_bai}نصب وبلاگ Halo"
		echo -e "${gl_huang}27.  ${gl_bai}نصب مولد پرامپت نقاشی هوش مصنوعی            ${gl_huang}28.  ${gl_bai}پراکسی معکوس سایت - تعادل بار"
		echo -e "${gl_huang}30.  ${gl_bai}سایت استاتیک سفارشی"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}31.  ${gl_bai}مدیریت داده های سایت ${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}پشتیبان گیری از تمام داده های سایت"
		echo -e "${gl_huang}33.  ${gl_bai}پشتیبان گیری از راه دور زمانبندی شده                      ${gl_huang}34.  ${gl_bai}بازیابی تمام داده های سایت"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}35.  ${gl_bai}محافظت از محیط LDNMP                     ${gl_huang}36.  ${gl_bai}بهینه سازی محیط LDNMP"
		echo -e "${gl_huang}37.  ${gl_bai}به روز رسانی محیط LDNMP                     ${gl_huang}38.  ${gl_bai}حذف نصب محیط LDNMP"
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_huang}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_huang}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

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
			webname="انجمن دیسکوز"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "آدرس پایگاه داده: mysql"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند جدول: discuz_"

			;;

		4)
			clear
			# 可道云桌面
			webname="دسکتاپ کلاود دیسک"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "آدرس پایگاه داده: mysql"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo "نام پایگاه داده: $dbname"
			echo "میزبان redis: redis"

			;;

		5)
			clear
			# 苹果CMS
			webname="اپل CMS"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "آدرس پایگاه داده: mysql"
			echo "پورت پایگاه داده: 3306"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند پایگاه داده: mac_"
			echo "------------------------"
			echo "آدرس ورود به پنل مدیریت پس از نصب"
			echo "https://$yuming/vip.php"

			;;

		6)
			clear
			# 独脚数卡
			webname="کارت های دیجیتال تک پا"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "آدرس پایگاه داده: mysql"
			echo "پورت پایگاه داده: 3306"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo
			echo "آدرس redis: redis"
			echo "رمز عبور redis: به طور پیش فرض خالی بگذارید"
			echo "پورت redis: 6379"
			echo
			echo "آدرس وب سایت: https://$yuming"
			echo "مسیر ورود به پنل مدیریت: /admin"
			echo "------------------------"
			echo "نام کاربری: admin"
			echo "رمز عبور: admin"
			echo "------------------------"
			echo "اگر در گوشه بالا سمت راست هنگام ورود خطای قرمز error0 ظاهر شد، از دستور زیر استفاده کنید:"
			echo "من هم از اینکه چرا کارت های دیجیتال独角数卡 اینقدر دردسر دارند و چنین مشکلاتی دارند، عصبانی هستم!"
			echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

			;;

		7)
			clear
			# flarum论坛
			webname="انجمن فلارم"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "آدرس پایگاه داده: mysql"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند جدول: flarum_"
			echo "اطلاعات مدیر را خودتان تنظیم کنید"

			;;

		8)
			clear
			# typecho
			webname="تایپچو"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "پیشوند پایگاه داده: typecho_"
			echo "آدرس پایگاه داده: mysql"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo "نام پایگاه داده: $dbname"

			;;

		9)
			clear
			# LinkStack
			webname="لینک استک"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo "آدرس پایگاه داده: mysql"
			echo "پورت پایگاه داده: 3306"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			;;

		20)
			clear
			webname="سایت پویا PHP"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo -e "[${gl_huang}1/6${gl_bai}] آپلود کد منبع PHP"
			echo "-------------"
			echo "در حال حاضر فقط بسته های کد منبع با فرمت zip مجاز هستند، لطفا بسته کد منبع را در دایرکتوری /home/web/html/${yuming} قرار دهید."
			Ask "همچنین می‌توانید لینک دانلود را وارد کنید تا بسته منبع را از راه دور دانلود کنید، زدن Enter از دانلود راه دور صرف نظر می‌کند:" url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/6${gl_bai}] مسیر دایرکتوری index.php"
			echo "-------------"
			# find "$(realpath .)" -name "index.php" -print
			find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

			Ask "لطفاً مسیر فایل index.php را وارد کنید، مانند ( /home/web/html/$yuming/wordpress/ ):" index_lujing

			sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
			sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}3/6${gl_bai}] انتخاب نسخه PHP"
			echo "-------------"
			Ask "1. آخرین نسخه PHP | 2. php7.4 :" pho_v
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
				echo "انتخاب نامعتبر، لطفا دوباره وارد کنید."
				;;
			esac

			clear
			echo -e "[${gl_huang}4/6${gl_bai}] نصب افزونه های مشخص شده"
			echo "-------------"
			echo "افزونه های نصب شده"
			docker exec php php -m

			Ask "لطفاً نام افزونه‌های مورد نیاز برای نصب را وارد کنید، مانند ${gl_huang}SourceGuardian imap ftp${gl_bai}. زدن Enter از نصب صرف نظر می‌کند:" php_extensions
			if [ -n "$php_extensions" ]; then
				docker exec $PHP_Version install-php-extensions $php_extensions
			fi

			clear
			echo -e "[${gl_huang}5/6${gl_bai}] ویرایش پیکربندی سایت"
			echo "-------------"
			Press "برای ادامه فشار دهید، می‌توانید تنظیمات دقیق سایت مانند شبه استاتیک و غیره را پیکربندی کنید"
			install nano
			nano /home/web/conf.d/$yuming.conf

			clear
			echo -e "[${gl_huang}6/6${gl_bai}] مدیریت پایگاه داده"
			echo "-------------"
			Ask "1. من یک سایت جدید راه‌اندازی می‌کنم 2. من یک سایت قدیمی با پشتیبان پایگاه داده دارم:" use_db
			case $use_db in
			1)
				echo
				;;
			2)
				echo "پشتیبان گیری از پایگاه داده باید یک بسته فشرده با پسوند .gz باشد. لطفا آن را در /home/ قرار دهید، از پشتیبان گیری宝塔/1panel پشتیبانی می کند."
				Ask "همچنین می‌توانید لینک دانلود را وارد کنید تا داده‌های پشتیبان را از راه دور دانلود کنید، زدن Enter از دانلود راه دور صرف نظر می‌کند:" url_download_db

				cd /home/
				if [ -n "$url_download_db" ]; then
					wget "$url_download_db"
				fi
				gunzip $(ls -t *.gz | head -n 1)
				latest_sql=$(ls -t *.sql | head -n 1)
				dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname <"/home/$latest_sql"
				echo "داده های جدول وارد شده از پایگاه داده"
				docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
				rm -f *.sql
				echo "وارد کردن پایگاه داده کامل شد"
				;;
			*)
				echo
				;;
			esac

			docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

			restart_ldnmp
			ldnmp_web_on
			prefix="web$(shuf -i 10-99 -n 1)_"
			echo "آدرس پایگاه داده: mysql"
			echo "نام پایگاه داده: $dbname"
			echo "نام کاربری: $dbuse"
			echo "رمز عبور: $dbusepasswd"
			echo "پیشوند جدول: $prefix"
			echo "اطلاعات ورود مدیر را خودتان تنظیم کنید"

			;;

		21)
			ldnmp_install_status_one
			nginx_install_all
			;;

		22)
			clear
			webname="تغییر مسیر سایت"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
			add_yuming
			Ask "لطفاً دامنه هدایت را وارد کنید:" reverseproxy
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
			webname="پروکسی معکوس - دامنه"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
			add_yuming
			echo -e "قالب دامنه: ${gl_huang}google.com${gl_bai}"
			Ask "لطفاً دامنه پروکسی معکوس خود را وارد کنید:" fandai_yuming
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
			webname="بیت واردن"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			webname="هالو"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			webname="مولد پرامپت نقاشی هوش مصنوعی"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			webname="سایت استاتیک"
			send_stats "安装$webname"
			echo "شروع استقرار $webname"
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
			echo -e "[${gl_huang}1/2${gl_bai}] آپلود کد منبع استاتیک"
			echo "-------------"
			echo "در حال حاضر فقط بسته های کد منبع با فرمت zip مجاز هستند، لطفا بسته کد منبع را در دایرکتوری /home/web/html/${yuming} قرار دهید."
			Ask "همچنین می‌توانید لینک دانلود را وارد کنید تا بسته منبع را از راه دور دانلود کنید، زدن Enter از دانلود راه دور صرف نظر می‌کند:" url_download

			if [ -n "$url_download" ]; then
				wget "$url_download"
			fi

			unzip $(ls -t *.zip | head -n 1)
			rm -f $(ls -t *.zip | head -n 1)

			clear
			echo -e "[${gl_huang}2/2${gl_bai}] مسیر دایرکتوری index.html"
			echo "-------------"
			# find "$(realpath .)" -name "index.html" -print
			find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

			Ask "لطفاً مسیر فایل index.html را وارد کنید، مانند ( /home/web/html/$yuming/index/ ):" index_lujing

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
			echo -e "${gl_huang}در حال پشتیبان گیری از $backup_filename ...${gl_bai}"
			cd /home/ && tar czvf "$backup_filename" web

			while true; do
				clear
				echo "فایل پشتیبان ایجاد شد: /home/$backup_filename"
				Ask "آیا می‌خواهید داده‌های پشتیبان را به سرور راه دور منتقل کنید؟ (y/N):" choice
				case "$choice" in
				[Yy])
					Ask "لطفاً IP سرور راه دور را وارد کنید:" remote_ip
					if [ -z "$remote_ip" ]; then
						echo "خطا: لطفا IP سرور راه دور را وارد کنید."
						continue
					fi
					local latest_tar=$(ls -t /home/*.tar.gz | head -1)
					if [ -n "$latest_tar" ]; then
						ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
						sleep 2 # 添加等待时间
						scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
						echo "فایل به دایرکتوری home سرور راه دور منتقل شد."
					else
						echo "فایل مورد نظر برای انتقال یافت نشد."
					fi
					break
					;;
				[Nn])
					break
					;;
				*)
					echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
					;;
				esac
			done
			;;

		33)
			clear
			send_stats "定时远程备份"
			Ask "IP سرور راه دور را وارد کنید:" useip
			Ask "رمز عبور سرور راه دور را وارد کنید:" usepasswd

			cd ~
			wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh >/dev/null 2>&1
			chmod +x ${useip}_beifen.sh

			sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
			sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

			echo "------------------------"
			echo "1. پشتیبان گیری هفتگی                 2. پشتیبان گیری روزانه"
			Ask "انتخاب خود را وارد کنید: " dingshi

			case $dingshi in
			1)
				check_crontab_installed
				Ask "روز هفته را برای پشتیبان‌گیری هفتگی انتخاب کنید (0-6، 0 نشان‌دهنده یکشنبه است):" weekday
				(
					crontab -l
					echo "0 0 * * $weekday ./${useip}_beifen.sh"
				) | crontab - >/dev/null 2>&1
				;;
			2)
				check_crontab_installed
				Ask "زمان پشتیبان‌گیری روزانه را انتخاب کنید (ساعت، 0-23):" hour
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
			echo "پشتیبان گیری های سایت موجود"
			echo "-------------------------"
			ls -lt /home/*.gz | awk '{print $NF}'
			echo
			Ask "با زدن Enter آخرین پشتیبان بازیابی می‌شود، با وارد کردن نام فایل، فایل پشتیبان مشخصی بازیابی می‌شود، با وارد کردن 0 خارج شوید:" filename

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

				echo -e "${gl_huang}در حال استخراج $filename ...${gl_bai}"
				cd /home/ && tar -xzf "$filename"

				check_port
				install_dependency
				install_docker
				install_certbot
				install_ldnmp
			else
				echo "بسته فشرده یافت نشد."
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
				echo "به روز رسانی محیط LDNMP"
				echo "------------------------"
				ldnmp_v
				echo "نسخه جدیدی از کامپوننت ها کشف شد"
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
				echo "1. به روز رسانی nginx               2. به روز رسانی mysql              3. به روز رسانی php              4. به روز رسانی redis"
				echo "------------------------"
				echo "5. به روز رسانی کامل محیط"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice
				case $sub_choice in
				1)
					nginx_upgrade

					;;

				2)
					local ldnmp_pods="mysql"
					Ask "لطفاً نسخه ${ldnmp_pods} را وارد کنید (مانند: 8.0 8.3 8.4 9.0) (زدن Enter آخرین نسخه را دریافت می‌کند):" version
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
					echo "به‌روزرسانی ${ldnmp_pods} کامل شد"

					;;
				3)
					local ldnmp_pods="php"
					Ask "لطفاً نسخه ${ldnmp_pods} را وارد کنید (مانند: 7.4 8.0 8.1 8.2 8.3) (زدن Enter آخرین نسخه را دریافت می‌کند):" version
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
					echo "به‌روزرسانی ${ldnmp_pods} کامل شد"

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
					echo "به‌روزرسانی ${ldnmp_pods} کامل شد"

					;;
				5)
					Ask "${gl_huang}نکته:${gl_bai} کاربرانی که مدت طولانی است محیط خود را به‌روز نکرده‌اند، لطفاً در به‌روزرسانی محیط LDNMP با احتیاط عمل کنند، خطر به‌روزرسانی ناموفق پایگاه داده وجود دارد. آیا از به‌روزرسانی محیط LDNMP مطمئن هستید؟ (y/N):" choice
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
			Ask "${gl_hong}اکیداً توصیه می‌شود:${gl_bai} ابتدا تمام داده‌های وب‌سایت را پشتیبان‌گیری کنید، سپس محیط LDNMP را حذف کنید. آیا از حذف تمام داده‌های وب‌سایت مطمئن هستید؟ (y/N):" choice
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
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion
			;;

		*)
			echo "ورودی نامعتبر!"
			;;
		esac
		break_end

	done

}

linux_panel() {

	while true; do
		clear
		# send_stats "应用市场"
		echo -e "بازار برنامه"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}پنل مدیریت رسمی宝塔                      ${gl_kjlan}2.   ${gl_bai}پنل مدیریت بین المللی宝塔 aaPanel"
		echo -e "${gl_kjlan}3.   ${gl_bai}پنل مدیریت نسل جدید 1Panel                ${gl_kjlan}4.   ${gl_bai}پنل مدیریت بصری NginxProxyManager"
		echo -e "${gl_kjlan}5.   ${gl_bai}برنامه لیست فایل چند ذخیره سازی OpenList          ${gl_kjlan}6.   ${gl_bai}نسخه دسکتاپ از راه دور Ubuntu مبتنی بر وب"
		echo -e "${gl_kjlan}7.   ${gl_bai}پنل نظارت VPS哪吒探针                 ${gl_kjlan}8.   ${gl_bai}پنل دانلود BT مگنت آفلاین QB"
		echo -e "${gl_kjlan}9.   ${gl_bai}برنامه سرور ایمیل Poste.io              ${gl_kjlan}10.  ${gl_bai}سیستم چت آنلاین چند نفره RocketChat"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}نرم افزار مدیریت پروژه ZenTao                    ${gl_kjlan}12.  ${gl_bai}پلتفرم مدیریت وظایف زمانبندی شده پنل Qinglong"
		echo -e "${gl_kjlan}13.  ${gl_bai}Cloudreve ${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}برنامه مدیریت ساده تصاویر آپلود کننده"
		echo -e "${gl_kjlan}15.  ${gl_bai}سیستم مدیریت چندرسانه ای Emby                  ${gl_kjlan}16.  ${gl_bai}پنل تست سرعت Speedtest"
		echo -e "${gl_kjlan}17.  ${gl_bai}نرم افزار مسدود کننده تبلیغات AdGuardHome               ${gl_kjlan}18.  ${gl_bai}ONLYOFFICE مجموعه اداری آنلاین"
		echo -e "${gl_kjlan}19.  ${gl_bai}پنل فایروال WAF雷池                   ${gl_kjlan}20.  ${gl_bai}پنل مدیریت کانتینر Portainer"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}نسخه وب VScode                        ${gl_kjlan}22.  ${gl_bai}ابزار نظارت UptimeKuma"
		echo -e "${gl_kjlan}23.  ${gl_bai}یادداشت برداری وب Memos                     ${gl_kjlan}24.  ${gl_bai}نسخه دسکتاپ از راه دور Webtop ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}25.  ${gl_bai}Nextcloud                       ${gl_kjlan}26.  ${gl_bai}چارچوب مدیریت وظایف زمانبندی شده QD-Today"
		echo -e "${gl_kjlan}27.  ${gl_bai}پنل مدیریت پشته کانتینر Dockge              ${gl_kjlan}28.  ${gl_bai}ابزار تست سرعت LibreSpeed"
		echo -e "${gl_kjlan}29.  ${gl_bai}موتور جستجوی تجمیعی Searxng ${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}سیستم مدیریت آلبوم خصوصی PhotoPrism"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}مجموعه ابزار PDF Stirling                 ${gl_kjlan}32.  ${gl_bai}نرم افزار رایگان نمودار آنلاین drawio ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}پنل ناوبری Sun-Panel                   ${gl_kjlan}34.  ${gl_bai}پلتفرم اشتراک گذاری فایل Pingvin-Share"
		echo -e "${gl_kjlan}35.  ${gl_bai}حساب کاربری ساده                          ${gl_kjlan}36.  ${gl_bai}وب سایت تجمیع چت هوش مصنوعی LobeChat"
		echo -e "${gl_kjlan}37.  ${gl_bai}جعبه ابزار MyIP ${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}بسته کامل alist شیائویی"
		echo -e "${gl_kjlan}39.  ${gl_bai}ابزار ضبط استریم زنده Bililive                ${gl_kjlan}40.  ${gl_bai}ابزار اتصال SSH مبتنی بر وب webssh"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}پنل مدیریت Haizi                \t ${gl_kjlan}42.  ${gl_bai}ابزار اتصال از راه دور Nexterm"
		echo -e "${gl_kjlan}43.  ${gl_bai}RustDesk دسکتاپ از راه دور (سرور) ${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}RustDesk دسکتاپ از راه دور (رله) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}45.  ${gl_bai}ایستگاه شتاب دهنده Docker            \t\t ${gl_kjlan}46.  ${gl_bai}ایستگاه شتاب دهنده GitHub ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}47.  ${gl_bai}نظارت Prometheus\t\t\t ${gl_kjlan}48.  ${gl_bai}Prometheus (نظارت میزبان)"
		echo -e "${gl_kjlan}49.  ${gl_bai}Prometheus (نظارت کانتینر)\t\t ${gl_kjlan}50.  ${gl_bai}ابزار نظارت بر موجودی"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}51.  ${gl_bai}پنل ایجاد ماشین PVE\t\t\t ${gl_kjlan}52.  ${gl_bai}پنل مدیریت کانتینر DPanel"
		echo -e "${gl_kjlan}53.  ${gl_bai}مدل زبان بزرگ چت هوش مصنوعی llama3                  ${gl_kjlan}54.  ${gl_bai}پنل مدیریت میزبان AMH"
		echo -e "${gl_kjlan}55.  ${gl_bai}FRP تونلینگ شبکه خصوصی (سرور) ${gl_huang}★${gl_bai}\t         ${gl_kjlan}56.  ${gl_bai}FRP تونلینگ شبکه خصوصی (کلاینت) ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}57.  ${gl_bai}مدل زبان بزرگ چت هوش مصنوعی Deepseek                ${gl_kjlan}58.  ${gl_bai}پایگاه دانش مدل بزرگ Dify ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}59.  ${gl_bai}مدیریت دارایی مدل بزرگ NewAPI                ${gl_kjlan}60.  ${gl_bai}Fortress JumpServer منبع باز"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}61.  ${gl_bai}سرور ترجمه آنلاین\t\t\t ${gl_kjlan}62.  ${gl_bai}پایگاه دانش مدل بزرگ RAGFlow"
		echo -e "${gl_kjlan}63.  ${gl_bai}پلتفرم هوش مصنوعی خودمیزبان OpenWebUI ${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}جعبه ابزار it-tools"
		echo -e "${gl_kjlan}65.  ${gl_bai}پلتفرم گردش کار اتوماسیون n8n ${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}ابزار دانلود ویدئو yt-dlp"
		echo -e "${gl_kjlan}67.  ${gl_bai}ابزار مدیریت DNS پویا ddns-go ${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${gl_bai}پلتفرم مدیریت گواهی AllinSSL"
		echo -e "${gl_kjlan}69.  ${gl_bai}ابزار انتقال فایل SFTPGo                  ${gl_kjlan}70.  ${gl_bai}چارچوب ربات چت AstrBot"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}71.  ${gl_bai}سرور موسیقی خصوصی Navidrome             ${gl_kjlan}72.  ${gl_bai}مدیریت کننده رمز عبور Bitwarden ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}73.  ${gl_bai}فیلم و سریال خصوصی LibreTV                     ${gl_kjlan}74.  ${gl_bai}فیلم و سریال خصوصی MoonTV"
		echo -e "${gl_kjlan}75.  ${gl_bai}جواهر موسیقی Melody                      ${gl_kjlan}76.  ${gl_bai}بازی های قدیمی DOS آنلاین"
		echo -e "${gl_kjlan}77.  ${gl_bai}ابزار دانلود آفلاین Xunlei                    ${gl_kjlan}78.  ${gl_bai}سیستم مدیریت اسناد هوشمند PandaWiki"
		echo -e "${gl_kjlan}79.  ${gl_bai}نظارت بر سرور Beszel"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="پنل بائوتا"
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

			local docker_describe="یک پنل ابزار پروکسی معکوس Nginx، از دسترسی با دامنه پشتیبانی نمی‌کند."
			local docker_url="معرفی وب‌سایت رسمی: https://nginxproxymanager.com/"
			local docker_use='echo "نام کاربری اولیه: admin@example.com"'
			local docker_passwd='echo "رمز عبور اولیه: changeme"'
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

			local docker_describe="یک برنامه لیست فایل که از چندین ذخیره‌سازی پشتیبانی می‌کند و از مرور وب و WebDAV پشتیبانی می‌کند، که توسط gin و Solidjs هدایت می‌شود."
			local docker_url="معرفی وب‌سایت رسمی: https://github.com/OpenListTeam/OpenList"
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

			local docker_describe="webtop مبتنی بر کانتینر اوبونتو است. اگر IP قابل دسترسی نیست، لطفاً دامنه را برای دسترسی اضافه کنید."
			local docker_url="معرفی وب‌سایت رسمی: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use='echo "نام کاربری: ubuntu-abc"'
			local docker_passwd='echo "رمز عبور: ubuntuABC123"'
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
				echo -e "نظارت Nezha $check_docker $update_status"
				echo "ابزار نظارت و نگهداری سرور متن باز، سبک و آسان برای استفاده"
				echo "سند راه اندازی وب سایت رسمی: https://nezha.wiki/guide/dashboard.html"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo
				echo "------------------------"
				echo "1. استفاده"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " choice

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

			local docker_describe="سرویس دانلود آفلاین BT و مگنت qbittorrent"
			local docker_url="معرفی وب‌سایت رسمی: https://hub.docker.com/r/linuxserver/qbittorrent"
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
				echo -e "سرویس پست $check_docker $update_status"
				echo "poste.io یک راه حل سرور ایمیل متن باز است،"
				echo "معرفی ویدئو: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo
				echo "بررسی پورت"
				port=25
				timeout=3
				if echo "خروج" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
					echo -e "${gl_lv}پورت $port در حال حاضر در دسترس است${gl_bai}"
				else
					echo -e "${gl_hong}پورت $port در حال حاضر در دسترس نیست${gl_bai}"
				fi
				echo

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "آدرس دسترسی: "
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. نصب           2. به روز رسانی           3. حذف"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " choice

				case $choice in
				1)
					check_disk_space 2
					Ask "لطفاً دامنه ایمیل را تنظیم کنید، به عنوان مثال mail.yuming.com:" yuming
					mkdir -p /home/docker
					echo "$yuming" >/home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "این رکوردهای DNS را ابتدا تجزیه کنید"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo
					echo "------------------------"
					Press "برای ادامه هر کلیدی را فشار دهید..."

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
					echo "poste.io نصب شد"
					echo "------------------------"
					echo "شما می توانید از آدرس زیر برای دسترسی به poste.io استفاده کنید:"
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
					echo "poste.io نصب شد"
					echo "------------------------"
					echo "شما می توانید از آدرس زیر برای دسترسی به poste.io استفاده کنید:"
					echo "https://$yuming"
					echo
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail
					echo "برنامه حذف شد"
					;;

				*)
					break
					;;

				esac
				break_end
			done

			;;

		10)

			local app_name="سیستم چت راکت"
			local app_text="Rocket.Chat یک پلتفرم ارتباط تیمی منبع باز است که از چت زنده، تماس صوتی/تصویری، اشتراک گذاری فایل و سایر ویژگی ها پشتیبانی می کند."
			local app_url="معرفی رسمی: https://www.rocket.chat/"
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
				echo "نصب کامل شد"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "rocket.chat نصب شد"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "برنامه حذف شد"
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

			local docker_describe="ZenTao یک نرم‌افزار مدیریت پروژه عمومی است."
			local docker_url="معرفی وب‌سایت رسمی: https://www.zentao.net/"
			local docker_use='echo "نام کاربری اولیه: admin"'
			local docker_passwd='echo "رمز عبور اولیه: 123456"'
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

			local docker_describe="Qinglong Panel یک پلتفرم مدیریت وظایف زمان‌بندی شده است."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;
		13)

			local app_name="فضای ذخیره سازی ابری"
			local app_text="cloudreve یک سیستم فضای ذخیره سازی ابری است که از چندین فضای ذخیره سازی ابری پشتیبانی می کند."
			local app_url="معرفی ویدئو: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
				echo "نصب کامل شد"
				check_docker_app_ip
			}

			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "برنامه حذف شد"
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

			local docker_describe="Simple Image Bed یک برنامه ساده برای ذخیره تصاویر است."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/icret/EasyImages2.0"
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

			local docker_describe="Emby یک نرم‌افزار سرور رسانه با معماری اصلی-فرعی است که می‌تواند برای سازماندهی ویدیوها و صداها در سرور و پخش صدا و تصویر به دستگاه‌های کلاینت استفاده شود."
			local docker_url="معرفی وب‌سایت رسمی: https://emby.media/"
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

			local docker_describe="Speedtest Panel یک ابزار تست سرعت اینترنت VPS است، با چندین قابلیت تست و همچنین نظارت بر ترافیک ورودی و خروجی VPS در زمان واقعی."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/wikihost-opensource/als"
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

			local docker_describe="AdGuard Home یک نرم‌افزار مسدود کننده تبلیغات در سراسر شبکه و ضد ردیابی است، و در آینده بیش از یک سرور DNS خواهد بود."
			local docker_url="معرفی وب‌سایت رسمی: https://hub.docker.com/r/adguard/adguardhome"
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

			local docker_describe="OnlyOffice یک ابزار آفیس آنلاین متن‌باز است، بسیار قدرتمند!"
			local docker_url="معرفی وب‌سایت رسمی: https://www.onlyoffice.com/"
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
				echo -e "سرویس لایچی $check_docker"
				echo "Lechi یک پنل برنامه فایروال وب سایت است که توسط Changting Technology توسعه یافته است و می تواند سایت ها را برای دفاع خودکار پروکسی کند."
				echo "معرفی ویدئو: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo

				echo "------------------------"
				echo "1. نصب           2. بروزرسانی           3. بازنشانی رمز عبور           4. حذف"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " choice

				case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
					clear
					echo "پنل فایروال Lechi WAF نصب شد"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo
					clear
					echo "پنل فایروال Lechi WAF بروزرسانی شد"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all
					echo "اگر از دایرکتوری نصب پیش فرض استفاده کرده اید، پروژه اکنون حذف شده است. اگر از دایرکتوری نصب سفارشی استفاده کرده اید، باید به دایرکتوری نصب رفته و به صورت دستی اجرا کنید:"
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

			local docker_describe="Portainer یک پنل مدیریت کانتینر سبک داکر است."
			local docker_url="معرفی وب‌سایت رسمی: https://www.portainer.io/"
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

			local docker_describe="VScode یک ابزار قدرتمند برای نوشتن کد آنلاین است."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/coder/code-server"
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

			local docker_describe="Uptime Kuma ابزار نظارت خود میزبان با استفاده آسان"
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/louislam/uptime-kuma"
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

			local docker_describe="Memos یک مرکز یادداشت‌برداری سبک و خود میزبان است."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/usememos/memos"
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

			local docker_describe="webtop مبتنی بر کانتینر نسخه چینی Alpine است. اگر IP قابل دسترسی نیست، لطفاً دامنه را برای دسترسی اضافه کنید."
			local docker_url="معرفی وب‌سایت رسمی: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use='echo "نام کاربری: webtop-abc"'
			local docker_passwd='echo "رمز عبور: webtopABC123"'
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

			local docker_describe="Nextcloud با بیش از 400,000 استقرار، محبوب‌ترین پلتفرم همکاری محلی است که می‌توانید دانلود کنید."
			local docker_url="معرفی وب‌سایت رسمی: https://nextcloud.com/"
			local docker_use="echo \\\"حساب کاربری: nextcloud  رمز عبور: $rootpasswd\\\""
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

			local docker_describe="QD-Today یک چارچوب اجرای خودکار وظایف زمان‌بندی شده درخواست HTTP است."
			local docker_url="معرفی وب‌سایت رسمی: https://qd-today.github.io/qd/zh_CN/"
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

			local docker_describe="Dockge یک پنل مدیریت کانتینر docker-compose بصری است."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/louislam/dockge"
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

			local docker_describe="Librespeed یک ابزار تست سرعت سبک است که با جاوا اسکریپت پیاده‌سازی شده است، آماده استفاده."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/librespeed/speedtest"
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

			local docker_describe="SearxNG یک سایت موتور جستجوی خصوصی و حفظ حریم خصوصی است."
			local docker_url="معرفی وب‌سایت رسمی: https://hub.docker.com/r/alandoyle/searxng"
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

			local docker_describe="PhotoPrism یک سیستم آلبوم عکس خصوصی بسیار قدرتمند است."
			local docker_url="معرفی وب‌سایت رسمی: https://www.photoprism.app/"
			local docker_use="echo \\\"حساب کاربری: admin  رمز عبور: $rootpasswd\\\""
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

			local docker_describe="این یک ابزار قدرتمند مدیریت PDF مبتنی بر وب و میزبانی محلی است که از داکر استفاده می‌کند و به شما امکان می‌دهد عملیات مختلفی را بر روی فایل‌های PDF انجام دهید، مانند تقسیم و ادغام، تبدیل، سازماندهی مجدد، افزودن تصاویر، چرخش، فشرده‌سازی و غیره."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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

			local docker_describe="این یک نرم‌افزار قدرتمند رسم نمودار است. نقشه‌های ذهنی، نمودارهای توپولوژیکی، نمودارهای جریان، همه را می‌توان رسم کرد."
			local docker_url="معرفی وب‌سایت رسمی: https://www.drawio.com/"
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

			local docker_describe="Sun-Panel پنل ناوبری سرور، NAS، Homepage، صفحه اصلی مرورگر."
			local docker_url="معرفی وب‌سایت رسمی: https://doc.sun-panel.top/zh_cn/"
			local docker_use='echo "حساب کاربری: admin@sun.cc  رمز عبور: 12345678"'
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

			local docker_describe="Pingvin Share یک پلتفرم اشتراک‌گذاری فایل خود میزبان است، جایگزینی برای WeTransfer."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/stonith404/pingvin-share"
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

			local docker_describe="فید خبری مینیمالیستی، شبیه به فید خبری وی‌چت، زندگی زیبای شما را ثبت می‌کند."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use='echo "حساب کاربری: admin  رمز عبور: a123456"'
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

			local docker_describe="LobeChat مدل‌های بزرگ هوش مصنوعی اصلی بازار را جمع‌آوری می‌کند، ChatGPT/Claude/Gemini/Groq/Ollama."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/lobehub/lobe-chat"
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

			local docker_describe="یک جعبه ابزار IP چند منظوره است که می‌تواند اطلاعات IP و اتصال خود را مشاهده کند و آن را در یک پنل وب نمایش دهد."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
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

			local docker_describe="Bililive-go یک ابزار ضبط پخش زنده است که از چندین پلتفرم پخش زنده پشتیبانی می‌کند."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

			local docker_describe="ابزار اتصال SSH و ابزار SFTP آنلاین ساده."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		41)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="پنل هاوزی"
			local panelurl="آدرس رسمی: ${gh_proxy}github.com/TheTNB/panel"

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

			local docker_describe="Nexterm یک ابزار قدرتمند اتصال آنلاین SSH/VNC/RDP است."
			local docker_url="معرفی وب‌سایت رسمی: ${gh_proxy}github.com/gnmyt/Nexterm"
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

			local docker_describe="RustDesk یک دسکتاپ از راه دور منبع باز (سمت سرور) است، شبیه به سرور اختصاصی خودتان."
			local docker_url="معرفی وب‌سایت رسمی: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd='echo "IP و کلید خود را یادداشت کنید، در کلاینت دسکتاپ از راه دور استفاده خواهد شد. به گزینه 44 برای نصب ترمینال رله بروید!"'
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

			local docker_describe="RustDesk یک دسکتاپ از راه دور منبع باز (سمت رله) است، شبیه به سرور اختصاصی خودتان."
			local docker_url="معرفی وب‌سایت رسمی: https://rustdesk.com/zh-cn/"
			local docker_use='echo "کلاینت دسکتاپ از راه دور را از وب سایت رسمی دانلود کنید: https://rustdesk.com/zh-cn/"'
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

			local docker_describe="Docker Registry سرویسی برای ذخیره و توزیع ایمیج‌های داکر است."
			local docker_url="معرفی وب‌سایت رسمی: https://hub.docker.com/_/registry"
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

			local docker_describe="GHProxy پیاده‌سازی شده با Go، برای تسریع دریافت مخازن Github در برخی مناطق استفاده می‌شود."
			local docker_url="معرفی وب‌سایت رسمی: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			;;

		47)

			local app_name="نظارت پرومتئوس"
			local app_text="سیستم نظارت در سطح سازمانی Prometheus+Grafana"
			local app_url="معرفی وب سایت: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
				echo "نصب کامل شد"
				check_docker_app_ip
				echo "نام کاربری و رمز عبور اولیه هر دو: admin"
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
				echo "برنامه حذف شد"
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

			local docker_describe="این یک کامپوننت جمع‌آوری داده‌های میزبان برای Prometheus است، لطفاً آن را روی میزبان تحت نظارت مستقر کنید."
			local docker_url="معرفی وب‌سایت رسمی: https://github.com/prometheus/node_exporter"
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

			local docker_describe="این یک کامپوننت جمع‌آوری داده‌های کانتینر برای Prometheus است، لطفاً آن را روی میزبان تحت نظارت مستقر کنید."
			local docker_url="معرفی وب سایت رسمی: https://github.com/google/cadvisor"
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

			local docker_describe="این یک ابزار کوچک برای تشخیص تغییرات وب‌سایت، نظارت بر موجودی و اطلاع‌رسانی است."
			local docker_url="معرفی وب سایت رسمی: https://github.com/dgtlmoon/changedetection.io"
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

			local docker_describe="سیستم پنل بصری داکر، قابلیت‌های مدیریت کامل داکر را ارائه می‌دهد."
			local docker_url="معرفی وب سایت رسمی: https://github.com/donknap/dpanel"
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

			local docker_describe="OpenWebUI یک چارچوب وب برای مدل‌های زبان بزرگ است که مدل زبان بزرگ جدید llama3 را ادغام می‌کند."
			local docker_url="معرفی وب سایت رسمی: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3.2:1b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		54)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="پنل AMH"
			local panelurl="آدرس رسمی: https://amh.sh/index.htm?amh"

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

			local docker_describe="OpenWebUI یک چارچوب وب برای مدل‌های زبان بزرگ است که مدل زبان بزرگ جدید DeepSeek R1 را ادغام می‌کند."
			local docker_url="معرفی وب سایت رسمی: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		58)
			local app_name="پایگاه دانش دیفای"
			local app_text="یک پلتفرم توسعه برنامه مدل زبان بزرگ (LLM) منبع باز است. داده های آموزشی خود میزبان برای تولید هوش مصنوعی استفاده می شود."
			local app_url="وب سایت رسمی: https://docs.dify.ai/zh-hans"
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
				echo "نصب کامل شد"
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
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		59)
			local app_name="API جدید"
			local app_text="سیستم مدیریت دارایی هوش مصنوعی و دروازه مدل بزرگ نسل جدید"
			local app_url="وب سایت رسمی: https://github.com/Calcium-Ion/new-api"
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
				echo "نصب کامل شد"
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
				echo "نصب کامل شد"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "برنامه حذف شد"
			}

			docker_app_plus

			;;

		60)

			local app_name="JumpServer دروازه امن منبع باز"
			local app_text="یک ابزار مدیریت دسترسی ممتاز (PAM) منبع باز است، این برنامه از پورت ۸۰ استفاده می کند و از افزودن دسترسی دامنه پشتیبانی نمی کند."
			local app_url="معرفی رسمی: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
				echo "نصب کامل شد"
				check_docker_app_ip
				echo "نام کاربری اولیه: admin"
				echo "رمز عبور اولیه: ChangeMe"
			}

			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "برنامه بروزرسانی شد"
			}

			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "برنامه حذف شد"
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

			local docker_describe="API ترجمه ماشینی رایگان و منبع باز، کاملاً خود میزبان، موتور ترجمه آن توسط کتابخانه ترجمه منبع باز Argos پشتیبانی می‌شود."
			local docker_url="معرفی وب سایت رسمی: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			;;

		62)
			local app_name="پایگاه دانش RAGFlow"
			local app_text="موتور RAG (بازیابی افزوده) منبع باز مبتنی بر درک عمیق اسناد"
			local app_url="وب سایت رسمی: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
				clear
				echo "نصب کامل شد"
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
				echo "برنامه حذف شد"
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

			local docker_describe="OpenWebUI یک چارچوب وب برای مدل‌های زبان بزرگ است، نسخه رسمی ساده شده، از دسترسی به API مدل‌های بزرگ پشتیبانی می‌کند."
			local docker_url="معرفی وب سایت رسمی: https://github.com/open-webui/open-webui"
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

			local docker_describe="ابزاری بسیار مفید برای توسعه دهندگان و متخصصان IT"
			local docker_url="معرفی وب سایت رسمی: https://github.com/CorentinTh/it-tools"
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

			local docker_describe="یک پلتفرم گردش کار خودکار قدرتمند است."
			local docker_url="معرفی وب سایت رسمی: https://github.com/n8n-io/n8n"
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

			local docker_describe="IP عمومی (IPv4/IPv6) شما را به طور خودکار و در زمان واقعی به ارائه دهندگان اصلی DNS به روز می‌کند تا تجزیه و تحلیل دامنه پویا را تحقق بخشد."
			local docker_url="معرفی وب سایت رسمی: https://github.com/jeessy2/ddns-go"
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

			local docker_describe="پلتفرم مدیریت خودکار گواهینامه SSL رایگان و منبع باز"
			local docker_url="معرفی وب سایت رسمی: https://allinssl.com"
			local docker_use='echo "ورودی امنیتی: /allinssl"'
			local docker_passwd='echo "نام کاربری: allinssl  رمز عبور: allinssldocker"'
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

			local docker_describe="ابزار انتقال فایل SFTP FTP WebDAV رایگان و منبع باز در هر زمان و هر مکان"
			local docker_url="معرفی وب سایت رسمی: https://sftpgo.com/"
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

			local docker_describe="یک چارچوب ربات چت هوش مصنوعی منبع باز که از اتصال به مدل‌های بزرگ هوش مصنوعی از طریق WeChat، QQ، TG پشتیبانی می‌کند."
			local docker_url="معرفی وب سایت رسمی: https://astrbot.app/"
			local docker_use='echo "نام کاربری: astrbot  رمز عبور: astrbot"'
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

			local docker_describe="یک سرور پخش موسیقی سبک و با کارایی بالا است."
			local docker_url="معرفی وب سایت رسمی: https://www.navidrome.org/"
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

			local docker_describe="یک مدیر رمز عبور که می‌توانید داده‌های آن را کنترل کنید."
			local docker_url="معرفی وب سایت رسمی: https://bitwarden.com/"
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

				Ask "رمز عبور ورود LibreTV را تنظیم کنید:" app_passwd

				docker run -d \
					--name libretv \
					--restart unless-stopped \
					-p ${docker_port}:8080 \
					-e PASSWORD=${app_passwd} \
					bestzwei/libretv:latest

			}

			local docker_describe="پلتفرم جستجو و تماشای ویدیوی آنلاین رایگان."
			local docker_url="معرفی وب سایت رسمی: https://github.com/LibreSpark/LibreTV"
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

				Ask "رمز عبور ورود MoonTV را تنظیم کنید:" app_passwd

				docker run -d \
					--name moontv \
					--restart unless-stopped \
					-p ${docker_port}:3000 \
					-e PASSWORD=${app_passwd} \
					ghcr.io/senshinya/moontv:latest

			}

			local docker_describe="پلتفرم جستجو و تماشای ویدیوی آنلاین رایگان."
			local docker_url="معرفی وب سایت رسمی: https://github.com/senshinya/MoonTV"
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

			local docker_describe="نوازنده موسیقی شما، که برای کمک به مدیریت بهتر موسیقی شما طراحی شده است."
			local docker_url="معرفی وب سایت رسمی: https://github.com/foamzou/melody"
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

			local docker_describe="یک مجموعه وب‌سایت بازی‌های DOS چینی است."
			local docker_url="معرفی وب سایت رسمی: https://github.com/rwv/chinese-dos-games"
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

				Ask "نام کاربری ورود ${docker_name} را تنظیم کنید:" app_use
				Ask "رمز عبور ورود ${docker_name} را تنظیم کنید:" app_passwd

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

			local docker_describe="Thunder ابزار دانلود آفلاین BT و مگنت پرسرعت شما."
			local docker_url="معرفی وب سایت رسمی: https://github.com/cnk3x/xunlei"
			local docker_use='echo "برنامه Xunlei را در تلفن همراه خود وارد کنید، سپس کد دعوت را وارد کنید، کد دعوت: Xunlei Niutong"'
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		78)

			local app_name="پاندا ویکی"
			local app_text="PandaWiki یک سیستم مدیریت اسناد هوشمند منبع باز مبتنی بر مدل زبان بزرگ هوش مصنوعی است، استقرار سفارشی پورت به شدت توصیه نمی شود."
			local app_url="معرفی رسمی: https://github.com/chaitin/PandaWiki"
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

			local docker_describe="Beszel مانیتورینگ سرور سبک و آسان برای استفاده."
			local docker_url="معرفی وب سایت رسمی: https://beszel.dev/zh/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			;;

		0)
			kejilion
			;;
		*)
			echo "ورودی نامعتبر!"
			;;
		esac
		break_end

	done
}

linux_work() {

	while true; do
		clear
		send_stats "后台工作区"
		echo -e "فضای کاری پس‌زمینه"
		echo -e "سیستم یک فضای کاری را برای شما فراهم می‌کند که می‌تواند به طور مداوم در پس‌زمینه اجرا شود و می‌توانید از آن برای انجام وظایف طولانی مدت استفاده کنید."
		echo -e "حتی اگر اتصال SSH خود را قطع کنید، وظایف در فضای کاری قطع نمی‌شوند، وظایف در حال اجرا در پس‌زمینه."
		echo -e "${gl_huang}نکته: ${gl_bai}پس از ورود به فضای کاری، برای خروج از آن، Ctrl+b را فشار داده و سپس d را جداگانه فشار دهید!"
		echo -e "${gl_kjlan}------------------------"
		echo "لیست فضاهای کاری موجود در حال حاضر"
		echo -e "${gl_kjlan}------------------------"
		tmux list-sessions
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}فضای کاری شماره ۱"
		echo -e "${gl_kjlan}2.   ${gl_bai}فضای کاری شماره ۲"
		echo -e "${gl_kjlan}3.   ${gl_bai}فضای کاری شماره ۳"
		echo -e "${gl_kjlan}4.   ${gl_bai}فضای کاری شماره ۴"
		echo -e "${gl_kjlan}5.   ${gl_bai}فضای کاری شماره ۵"
		echo -e "${gl_kjlan}6.   ${gl_bai}فضای کاری شماره ۶"
		echo -e "${gl_kjlan}7.   ${gl_bai}فضای کاری شماره ۷"
		echo -e "${gl_kjlan}8.   ${gl_bai}فضای کاری شماره ۸"
		echo -e "${gl_kjlan}9.   ${gl_bai}فضای کاری شماره ۹"
		echo -e "${gl_kjlan}10.  ${gl_bai}فضای کاری شماره ۱۰"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}حالت دائمی SSH ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}22.  ${gl_bai}ایجاد/ورود به فضای کاری"
		echo -e "${gl_kjlan}23.  ${gl_bai}تزریق دستور به فضای کاری پس‌زمینه"
		echo -e "${gl_kjlan}24.  ${gl_bai}حذف فضای کاری مشخص"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

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
					local tmux_sshd_status="${gl_lv}فعال کردن${gl_bai}"
				else
					local tmux_sshd_status="${gl_hui}غیرفعال کردن${gl_bai}"
				fi
				send_stats "SSH常驻模式 "
				echo -e "حالت دائمی SSH $tmux_sshd_status"
				echo "پس از فعال شدن، اتصال SSH مستقیماً وارد حالت دائمی می شود و مستقیماً به وضعیت کار قبلی باز می گردد."
				echo "------------------------"
				echo "1. فعال کردن            2. غیرفعال کردن"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " gongzuoqu_del
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
			Ask "لطفاً نام فضای کاری که ایجاد یا وارد می‌کنید را وارد کنید، مانند 1001 kj001 work1:" SESSION_NAME
			tmux_run
			send_stats "自定义工作区"
			;;

		23)
			Ask "لطفاً دستوری را که می‌خواهید در پس‌زمینه اجرا شود وارد کنید، مانند: curl -fsSL https://get.docker.com | sh:" tmuxd
			tmux_run_d
			send_stats "注入命令到后台工作区"
			;;

		24)
			Ask "لطفاً نام فضای کاری مورد نظر برای حذف را وارد کنید:" gongzuoqu_name
			tmux kill-window -t $gongzuoqu_name
			send_stats "删除工作区"
			;;

		0)
			kejilion
			;;
		*)
			echo "ورودی نامعتبر!"
			;;
		esac
		break_end

	done

}

linux_Settings() {

	while true; do
		clear
		# send_stats "系统工具"
		echo -e "ابزارهای سیستم"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}1.   ${gl_bai}تنظیم میانبر اسکریپت                 ${gl_kjlan}2.   ${gl_bai}تغییر رمز عبور ورود"
		echo -e "${gl_kjlan}3.   ${gl_bai}حالت ورود با رمز عبور ROOT                   ${gl_kjlan}4.   ${gl_bai}نصب نسخه مشخص پایتون"
		echo -e "${gl_kjlan}5.   ${gl_bai}باز کردن تمام پورت‌ها                       ${gl_kjlan}6.   ${gl_bai}تغییر پورت اتصال SSH"
		echo -e "${gl_kjlan}7.   ${gl_bai}بهینه‌سازی آدرس DNS                        ${gl_kjlan}8.   ${gl_bai}نصب مجدد سیستم با یک کلیک ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}9.   ${gl_bai}غیرفعال کردن حساب ROOT برای ایجاد حساب جدید             ${gl_kjlan}10.  ${gl_bai}تغییر اولویت IPv4/IPv6"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}11.  ${gl_bai}مشاهده وضعیت اشغال پورت                   ${gl_kjlan}12.  ${gl_bai}تغییر اندازه حافظه مجازی"
		echo -e "${gl_kjlan}13.  ${gl_bai}مدیریت کاربر                           ${gl_kjlan}14.  ${gl_bai}مولد کاربر/رمز عبور"
		echo -e "${gl_kjlan}15.  ${gl_bai}تنظیم منطقه زمانی سیستم                       ${gl_kjlan}16.  ${gl_bai}تنظیم شتاب‌دهنده BBR3"
		echo -e "${gl_kjlan}17.  ${gl_bai}مدیر پیشرفته فایروال                   ${gl_kjlan}18.  ${gl_bai}تغییر نام میزبان"
		echo -e "${gl_kjlan}19.  ${gl_bai}تغییر منبع به‌روزرسانی سیستم                     ${gl_kjlan}20.  ${gl_bai}مدیریت وظایف زمان‌بندی شده"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}21.  ${gl_bai}تجزیه و تحلیل هاست محلی                       ${gl_kjlan}22.  ${gl_bai}برنامه دفاعی SSH"
		echo -e "${gl_kjlan}23.  ${gl_bai}خاموش شدن خودکار با محدودیت ترافیک                       ${gl_kjlan}24.  ${gl_bai}حالت ورود با کلید خصوصی ROOT"
		echo -e "${gl_kjlan}25.  ${gl_bai}هشدار سیستم نظارت ربات TG                 ${gl_kjlan}26.  ${gl_bai}رفع آسیب‌پذیری بالای OpenSSH (XiuYuan)"
		echo -e "${gl_kjlan}27.  ${gl_bai}ارتقاء هسته لینوکس خانواده Red Hat                ${gl_kjlan}28.  ${gl_bai}بهینه‌سازی پارامترهای هسته سیستم لینوکس ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}29.  ${gl_bai}ابزار اسکن ویروس ${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}مدیریت فایل"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}31.  ${gl_bai}تغییر زبان سیستم                       ${gl_kjlan}32.  ${gl_bai}ابزار زیباسازی خط فرمان ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}33.  ${gl_bai}تنظیم سطل بازیافت سیستم                     ${gl_kjlan}34.  ${gl_bai}پشتیبان‌گیری و بازیابی سیستم"
		echo -e "${gl_kjlan}35.  ${gl_bai}ابزار اتصال از راه دور SSH                    ${gl_kjlan}36.  ${gl_bai}ابزار مدیریت پارتیشن دیسک"
		echo -e "${gl_kjlan}37.  ${gl_bai}تاریخچه خط فرمان                     ${gl_kjlan}38.  ${gl_bai}ابزار همگام‌سازی از راه دور rsync"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}41.  ${gl_bai}تابلو پیام                             ${gl_kjlan}66.  ${gl_bai}بهینه‌سازی جامع سیستم ${gl_huang}★${gl_bai}"
		echo -e "${gl_kjlan}99.  ${gl_bai}راه اندازی مجدد سرور                         ${gl_kjlan}100. ${gl_bai}حریم خصوصی و امنیت"
		echo -e "${gl_kjlan}101. ${gl_bai}استفاده پیشرفته از دستور k ${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}حذف اسکریپت科技lion"
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			while true; do
				clear
				Ask "لطفاً کلید میانبر خود را وارد کنید (وارد کردن 0 خروج است):" kuaijiejian
				if [ "$kuaijiejian" == "0" ]; then
					break_end
					linux_Settings
				fi
				find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				echo "کلیدهای میانبر تنظیم شدند"
				send_stats "脚本快捷键已设置"
				break_end
				linux_Settings
			done
			;;

		2)
			clear
			send_stats "设置你的登录密码"
			echo "رمز عبور ورود خود را تنظیم کنید"
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
			echo "مدیریت نسخه پایتون"
			echo "معرفی ویدئو: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "این تابع می تواند هر نسخه ای را که پایتون به طور رسمی پشتیبانی می کند، بدون مشکل نصب کند!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "نسخه فعلی پایتون: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "نسخه های پیشنهادی:  3.12    3.11    3.10    3.9    3.8    2.7"
			echo "برای مشاهده نسخه های بیشتر: https://www.python.org/downloads/"
			echo "------------"
			Ask "لطفاً نسخه پایتون مورد نظر برای نصب را وارد کنید (وارد کردن 0 خروج است):" py_new_v

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
					echo "مدیریت بسته نرم‌افزاری ناشناخته!"
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
			echo -e "نسخه فعلی پایتون: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			;;

		5)
			root_use
			send_stats "开放端口"
			iptables_open
			remove iptables-persistent ufw firewalld iptables-services >/dev/null 2>&1
			echo "تمام پورت ها باز هستند"

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
				echo -e "شماره پورت SSH فعلی:  ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "عدد بین 1 تا 65535 برای شماره پورت. (0 برای خروج)"

				# 提示用户输入新的 SSH 端口号
				Ask "لطفاً شماره پورت SSH جدید را وارد کنید:" new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "شماره پورت نامعتبر است، لطفاً یک عدد بین 1 تا 65535 وارد کنید."
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "ورودی نامعتبر است، لطفاً یک عدد وارد کنید."
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
			Ask "لطفاً نام کاربری جدید را وارد کنید (وارد کردن 0 خروج است):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "عملیات تکمیل شد."
			;;

		10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "تنظیم اولویت v4/v6"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "تنظیم اولویت شبکه فعلی: ${gl_huang}IPv4${gl_bai} اولویت دارد"
				else
					echo -e "تنظیم اولویت شبکه فعلی: ${gl_huang}IPv6${gl_bai} اولویت دارد"
				fi
				echo
				echo "------------------------"
				echo "1. اولویت IPv4          2. اولویت IPv6          3. ابزار رفع مشکل IPv6"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "شبکه اولویت‌دار را انتخاب کنید:" choice

				case $choice in
				1)
					sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
					echo "به اولویت IPv4 تغییر یافت"
					send_stats "已切换为 IPv4 优先"
					;;
				2)
					sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null 2>&1
					echo "به اولویت IPv6 تغییر یافت"
					send_stats "已切换为 IPv6 优先"
					;;

				3)
					clear
					bash <(curl -L -s jhb.ovh/jb/v6.sh)
					echo "این ویژگی توسط استاد jhb ارائه شده است، از او سپاسگزاریم!"
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
				echo "تنظیم حافظه مجازی"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "حافظه مجازی فعلی: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. تخصیص 1024M         2. تخصیص 2048M         3. تخصیص 4096M         4. اندازه سفارشی"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " choice

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
					Ask "لطفاً اندازه حافظه مجازی را وارد کنید (واحد M):" new_swap
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
				echo "لیست کاربران"
				echo "----------------------------------------------------------------------------"
				echo "نام کاربری                مجوزهای کاربر                       گروه کاربر            مجوز sudo"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done </etc/passwd

				echo
				echo "عملیات حساب کاربری"
				echo "------------------------"
				echo "1. ایجاد حساب عادی             2. ایجاد حساب پیشرفته"
				echo "------------------------"
				echo "3. اعطای بالاترین مجوز             4. لغو بالاترین مجوز"
				echo "------------------------"
				echo "5. حذف حساب"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					# 提示用户输入新用户名
					Ask "لطفاً نام کاربری جدید را وارد کنید:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					echo "عملیات تکمیل شد."
					;;

				2)
					# 提示用户输入新用户名
					Ask "لطفاً نام کاربری جدید را وارد کنید:" new_username

					# 创建新用户并设置密码
					useradd -m -s /bin/bash "$new_username"
					passwd "$new_username"

					# 赋予新用户sudo权限
					echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					echo "عملیات تکمیل شد."

					;;
				3)
					Ask "لطفاً نام کاربری را وارد کنید:" username
					# 赋予新用户sudo权限
					echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
					;;
				4)
					Ask "لطفاً نام کاربری را وارد کنید:" username
					# 从sudoers文件中移除用户的sudo权限
					sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

					;;
				5)
					Ask "لطفاً نام کاربری مورد نظر برای حذف را وارد کنید:" username
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
			echo "نام کاربری تصادفی"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(</dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "نام کاربری تصادفی $i: $username"
			done

			echo
			echo "نام تصادفی"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "نام کاربری تصادفی $i: $user_name"
			done

			echo
			echo "UUID تصادفی"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "UUID تصادفی $i: $uuid"
			done

			echo
			echo "رمز عبور تصادفی 16 رقمی"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "رمز عبور تصادفی $i: $password"
			done

			echo
			echo "رمز عبور تصادفی 32 رقمی"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(</dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "رمز عبور تصادفی $i: $password"
			done
			echo

			;;

		15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "اطلاعات زمان سیستم"

				# 显示时区和时间
				echo "منطقه زمانی فعلی سیستم: $(TimeZn)"
				echo "زمان فعلی سیستم: $(date +"%Y-%m-%d %H:%M:%S")"

				echo
				echo "تغییر منطقه زمانی"
				echo "------------------------"
				echo "آسیا"
				echo "1.  زمان شانگهای چین             2.  زمان هنگ کنگ چین"
				echo "3.  زمان توکیو ژاپن             4.  زمان سئول کره جنوبی"
				echo "5.  زمان سنگاپور               6.  زمان کلکته هند"
				echo "7.  زمان دبی امارات متحده عربی           8.  زمان سیدنی استرالیا"
				echo "9.  زمان بانکوک تایلند"
				echo "------------------------"
				echo "اروپا"
				echo "11. زمان لندن انگلستان             12. زمان پاریس فرانسه"
				echo "13. زمان برلین آلمان             14. زمان مسکو روسیه"
				echo "15. زمان اوترخت هلند       16. زمان مادرید اسپانیا"
				echo "------------------------"
				echo "آمریکا"
				echo "21. زمان غرب آمریکا             22. زمان شرق آمریکا"
				echo "23. زمان کانادا               24. زمان مکزیک"
				echo "25. زمان برزیل                 26. زمان آرژانتین"
				echo "------------------------"
				echo "31. زمان جهانی استاندارد UTC"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice

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
				echo -e "نام میزبان فعلی: ${gl_huang}$current_hostname${gl_bai}"
				echo "------------------------"
				Ask "لطفاً نام میزبان جدید را وارد کنید (وارد کردن 0 خروج است):" new_hostname
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

					echo "نام میزبان به: $new_hostname تغییر یافت"
					send_stats "主机名已更改"
					sleep 1
				else
					echo "خارج شدید، نام میزبان تغییر نکرد."
					break
				fi
			done
			;;

		19)
			root_use
			send_stats "换系统更新源"
			clear
			echo "انتخاب منطقه منبع به‌روزرسانی"
			echo "سوئیچ منبع به‌روزرسانی سیستم با استفاده از سیستم تغییر آینه لینوکس"
			echo "------------------------"
			echo "1. سرزمین اصلی چین [پیش‌فرض] 2. سرزمین اصلی چین [شبکه آموزشی] 3. مناطق خارج از کشور"
			echo "------------------------"
			echo "0. بازگشت به منوی قبلی"
			echo "------------------------"
			Ask "انتخاب خود را وارد کنید: " choice

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
				echo "لغو شد"
				;;

			esac

			;;

		20)
			send_stats "定时任务管理"
			while true; do
				clear
				check_crontab_installed
				clear
				echo "لیست وظایف زمان‌بندی شده"
				crontab -l
				echo
				echo "عملیات"
				echo "------------------------"
				echo "1. افزودن وظیفه زمان‌بندی شده 2. حذف وظیفه زمان‌بندی شده 3. ویرایش وظیفه زمان‌بندی شده"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice

				case $sub_choice in
				1)
					Ask "لطفاً دستور اجرای وظیفه جدید را وارد کنید:" newquest
					echo "------------------------"
					echo "1. وظیفه ماهانه 2. وظیفه هفتگی"
					echo "3. وظیفه روزانه 4. وظیفه ساعتی"
					echo "------------------------"
					Ask "انتخاب خود را وارد کنید: " dingshi

					case $dingshi in
					1)
						Ask "کدام روز از ماه را برای اجرای وظیفه انتخاب می‌کنید؟ (1-30):" day
						(
							crontab -l
							echo "0 0 $day * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					2)
						Ask "انتخاب روز هفته برای اجرای وظیفه؟ (۰-۶، ۰ نماینده یکشنبه): " weekday
						(
							crontab -l
							echo "0 0 * * $weekday $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					3)
						Ask "انتخاب ساعت اجرای وظیفه در روز؟ (ساعت، ۰-۲۳): " hour
						(
							crontab -l
							echo "0 $hour * * * $newquest"
						) | crontab - >/dev/null 2>&1
						;;
					4)
						Ask "دقیقه اجرای وظیفه در هر ساعت را وارد کنید؟ (دقیقه، ۰-۶۰): " minute
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
					Ask "کلیدواژه وظیفه مورد نظر برای حذف را وارد کنید: " kquest
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
				echo "لیست تجزیه هاست محلی"
				echo "اگر تجزیه تطبیقی را در اینجا اضافه کنید، دیگر از تجزیه پویا استفاده نخواهد شد"
				cat /etc/hosts
				echo
				echo "عملیات"
				echo "------------------------"
				echo "1. افزودن تجزیه جدید 2. حذف آدرس تجزیه"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " host_dns

				case $host_dns in
				1)
					Ask "رکورد تجزیه و تحلیل جدید را وارد کنید فرمت: 110.25.5.33 kejilion.pro : " addhost
					echo "$addhost" >>/etc/hosts
					send_stats "本地host解析新增"

					;;
				2)
					Ask "کلیدواژه محتوای تجزیه و تحلیل مورد نظر برای حذف را وارد کنید: " delhost
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
					echo -e "برنامه دفاعی SSH $check_docker"
					echo "fail2ban یک ابزار جلوگیری از حملات brute-force SSH است"
					echo "معرفی وب‌سایت رسمی: ${gh_proxy}github.com/fail2ban/fail2ban"
					echo "------------------------"
					echo "1. نصب برنامه دفاعی"
					echo "------------------------"
					echo "2. مشاهده سوابق مسدودسازی SSH"
					echo "3. نظارت زنده بر گزارش‌ها"
					echo "------------------------"
					echo "9. حذف برنامه دفاعی"
					echo "------------------------"
					echo "0. بازگشت به منوی قبلی"
					echo "------------------------"
					Ask "انتخاب خود را وارد کنید: " sub_choice
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
						echo "برنامه دفاعی Fail2Ban حذف شد"
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
				echo "عملکرد خاموش کردن محدود کننده جریان"
				echo "معرفی ویدئو: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "وضعیت فعلی استفاده از جریان، محاسبه جریان پس از راه‌اندازی مجدد سرور صفر خواهد شد!"
				echo -e "${gl_kjlan}کل دریافت: ${gl_bai}$(ConvSz $(Iface --rx_bytes))"
				echo -e "${gl_kjlan}کل ارسال: ${gl_bai}$(ConvSz $(Iface --tx_bytes))"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}آستانه فعلی تنظیم شده برای محدودیت ترافیک ورودی: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}آستانه فعلی تنظیم شده برای محدودیت ترافیک خروجی: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}عملکرد خاموش شدن با محدودیت ترافیک در حال حاضر فعال نیست${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "سیستم هر دقیقه جریان واقعی را با آستانه بررسی می‌کند و پس از رسیدن به آن، سرور به طور خودکار خاموش می‌شود!"
				echo "------------------------"
				echo "1. فعال کردن عملکرد خاموش کردن محدود کننده جریان 2. غیرفعال کردن عملکرد خاموش کردن محدود کننده جریان"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " Limiting

				case "$Limiting" in
				1)
					# 输入新的虚拟内存大小
					echo "اگر سرور واقعی فقط 100 گیگابایت ترافیک دارد، می‌توانید آستانه را روی 95 گیگابایت تنظیم کنید تا زودتر خاموش شود تا از خطاهای ترافیکی یا سرریز جلوگیری شود."
					Ask "آستانه ترافیک ورودی را وارد کنید (واحد گیگابایت، پیش فرض ۱۰۰ گیگابایت): " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					Ask "آستانه ترافیک خروجی را وارد کنید (واحد گیگابایت، پیش فرض ۱۰۰ گیگابایت): " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					Ask "تاریخ بازنشانی ترافیک را وارد کنید (پیش فرض اول هر ماه بازنشانی می شود): " cz_day
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
					echo "خاموش کردن محدود کننده جریان تنظیم شده است"
					send_stats "限流关机已设置"
					;;
				2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "عملکرد خاموش کردن محدود کننده جریان غیرفعال شده است"
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
				echo "حالت ورود با کلید خصوصی ROOT"
				echo "معرفی ویدئو: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
				echo "------------------------------------------------"
				echo "یک جفت کلید تولید می‌شود، روش امن‌تر برای ورود به SSH"
				echo "------------------------"
				echo "1. تولید کلید جدید 2. وارد کردن کلید موجود 3. مشاهده کلیدهای محلی"
				echo "------------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "------------------------"
				Ask "انتخاب خود را وارد کنید: " host_dns

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
					echo "اطلاعات کلید عمومی"
					cat ~/.ssh/authorized_keys
					echo "------------------------"
					echo "اطلاعات کلید خصوصی"
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
			echo "عملکرد هشدار مانیتورینگ TG-bot"
			echo "معرفی ویدئو: https://youtu.be/vLL-eb3Z_TY"
			echo "------------------------------------------------"
			echo "شما نیاز به پیکربندی API ربات تلگرام و شناسه کاربر دریافت کننده هشدار دارید تا بتوانید مانیتورینگ و هشدار بلادرنگ CPU، حافظه، دیسک، جریان و ورود SSH را در دستگاه محلی پیاده سازی کنید."
			echo "پس از رسیدن به آستانه، پیام هشدار به کاربر ارسال می‌شود"
			echo -e "${gl_hui}-در مورد ترافیک، پس از راه اندازی مجدد سرور دوباره محاسبه می شود-${gl_bai}"
			Ask "آیا از ادامه مطمئن هستید؟ (y/N):" choice

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
				echo "سیستم هشدار TG-bot راه‌اندازی شده است"
				echo -e "${gl_hui}شما همچنین می توانید فایل هشدار TG-check-notify.sh را در دایرکتوری root در ماشین های دیگر قرار دهید تا مستقیماً از آن استفاده کنید!${gl_bai}"
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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
			echo "تابلو پیام‌رسانی Lion Technology به انجمن رسمی منتقل شده است! لطفاً در انجمن رسمی پیام بگذارید!"
			echo "https://bbs.kejilion.pro/"
			;;

		66)

			root_use
			send_stats "一条龙调优"
			echo "بهینه‌سازی سیستم یکپارچه"
			echo "------------------------------------------------"
			echo "عملیات و بهینه‌سازی برای موارد زیر انجام خواهد شد"
			echo "1. به‌روزرسانی سیستم به آخرین نسخه"
			echo "2. پاکسازی فایل‌های زباله سیستم"
			echo -e "3. تنظیم حافظه مجازی${gl_huang}1G${gl_bai}"
			echo -e "4. تنظیم شماره پورت SSH به${gl_huang}5522${gl_bai}"
			echo -e "5. باز کردن تمام پورت‌ها"
			echo -e "6. فعال کردن شتاب‌دهنده ${gl_huang}BBR${gl_bai}"
			echo -e "7. تنظیم منطقه زمانی به${gl_huang}شانگهای${gl_bai}"
			echo -e "8. بهینه‌سازی خودکار آدرس DNS${gl_huang}خارج از کشور: 1.1.1.1 8.8.8.8  داخل کشور: 223.5.5.5 ${gl_bai}"
			echo -e "9. نصب ابزارهای پایه${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			echo -e "10. بهینه‌سازی پارامترهای هسته سیستم لینوکس به${gl_huang}حالت بهینه‌سازی متعادل${gl_bai}"
			echo "------------------------------------------------"
			Ask "آیا از نگهداری یک کلید اطمینان دارید؟ (y/N): " choice

			case "$choice" in
			[Yy])
				clear
				send_stats "一条龙调优启动"
				echo "------------------------------------------------"
				linux_update
				echo -e "[${gl_lv}OK${gl_bai}] 1/10. به‌روزرسانی سیستم به آخرین نسخه"

				echo "------------------------------------------------"
				linux_clean
				echo -e "[${gl_lv}OK${gl_bai}] 2/10. پاکسازی فایل‌های زباله سیستم"

				echo "------------------------------------------------"
				add_swap 1024
				echo -e "[${gl_lv}OK${gl_bai}] 3/10. تنظیم حافظه مجازی${gl_huang}1G${gl_bai}"

				echo "------------------------------------------------"
				local new_port=5522
				new_ssh_port
				echo -e "[${gl_lv}OK${gl_bai}] 4/10. تنظیم شماره پورت SSH به${gl_huang}5522${gl_bai}"
				echo "------------------------------------------------"
				echo -e "[${gl_lv}OK${gl_bai}] 5/10. باز کردن تمام پورت‌ها"

				echo "------------------------------------------------"
				bbr_on
				echo -e "[${gl_lv}OK${gl_bai}] 6/10. فعال کردن شتاب‌دهنده ${gl_huang}BBR${gl_bai}"

				echo "------------------------------------------------"
				set_timedate Asia/Shanghai
				echo -e "[${gl_lv}OK${gl_bai}] 7/10. تنظیم منطقه زمانی به${gl_huang}شانگهای${gl_bai}"

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
				echo -e "[${gl_lv}OK${gl_bai}] 8/10. بهینه‌سازی خودکار آدرس DNS${gl_huang}${gl_bai}"

				echo "------------------------------------------------"
				install_docker
				install wget sudo tar unzip socat btop nano vim
				echo -e "[${gl_lv}OK${gl_bai}] 9/10. نصب ابزارهای پایه${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				echo "------------------------------------------------"

				echo "------------------------------------------------"
				optimize_balanced
				echo -e "[${gl_lv}OK${gl_bai}] 10/10. بهینه‌سازی پارامترهای هسته سیستم لینوکس"
				echo -e "${gl_lv}بهینه‌سازی جامع سیستم کامل شد${gl_bai}"

				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
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

				echo "حریم خصوصی و امنیت"
				echo "اسکریپت داده‌های استفاده از ویژگی توسط کاربر را جمع‌آوری می‌کند تا تجربه استفاده از اسکریپت را بهینه کند و ویژگی‌های سرگرم‌کننده و کاربردی بیشتری ایجاد کند."
				echo "نسخه اسکریپت، زمان استفاده، نسخه سیستم، معماری CPU، کشور مالک دستگاه و نام ویژگی‌های استفاده شده جمع‌آوری خواهد شد."
				echo "------------------------------------------------"
				echo -e "وضعیت فعلی: $status_message"
				echo "--------------------"
				echo "1. فعال کردن جمع‌آوری"
				echo "2. غیرفعال کردن جمع‌آوری"
				echo "--------------------"
				echo "0. بازگشت به منوی قبلی"
				echo "--------------------"
				Ask "انتخاب خود را وارد کنید: " sub_choice
				case $sub_choice in
				1)
					cd ~
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					echo "جمع‌آوری فعال شده است"
					send_stats "隐私与安全已开启采集"
					;;
				2)
					cd ~
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					echo "جمع‌آوری غیرفعال شده است"
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
			echo "حذف اسکریپت Lion Technology"
			echo "------------------------------------------------"
			echo "اسکریپت kejilion به طور کامل حذف خواهد شد و بر سایر عملکردهای شما تأثیر نمی‌گذارد."
			Ask "آیا از ادامه مطمئن هستید؟ (y/N):" choice

			case "$choice" in
			[Yy])
				clear
				(crontab -l | grep -v "kejilion.sh") | crontab -
				rm -f /usr/local/bin/k
				rm ~/kejilion.sh
				echo "اسکریپت حذف شد، خداحافظ!"
				break_end
				clear
				exit
				;;
			[Nn])
				echo "لغو شد"
				;;
			*)
				echo "انتخاب نامعتبر است، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;

		0)
			kejilion

			;;
		*)
			echo "ورودی نامعتبر!"
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
		echo "مدیریت فایل"
		echo "------------------------"
		echo "مسیر فعلی"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. ورود به دایرکتوری 2. ایجاد دایرکتوری 3. تغییر مجوزهای دایرکتوری 4. تغییر نام دایرکتوری"
		echo "5. حذف دایرکتوری 6. بازگشت به منوی قبلی"
		echo "------------------------"
		echo "11. ایجاد فایل 12. ویرایش فایل 13. تغییر مجوزهای فایل 14. تغییر نام فایل"
		echo "15. حذف فایل"
		echo "------------------------"
		echo "21. فشرده‌سازی دایرکتوری فایل 22. استخراج دایرکتوری فایل 23. انتقال دایرکتوری فایل 24. کپی دایرکتوری فایل"
		echo "25. انتقال فایل به سرور دیگر"
		echo "------------------------"
		echo "0. بازگشت به منوی قبلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " Limiting

		case "$Limiting" in
		1)
			# 进入目录
			Ask "نام دایرکتوری را وارد کنید: " dirname
			cd "$dirname" 2>/dev/null || echo "امکان ورود به دایرکتوری وجود ندارد"
			send_stats "进入目录"
			;;
		2)
			# 创建目录
			Ask "نام دایرکتوری مورد نظر برای ایجاد را وارد کنید: " dirname
			mkdir -p "$dirname" && echo "دایرکتوری ایجاد شد" || echo "ایجاد ناموفق بود"
			send_stats "创建目录"
			;;
		3)
			# 修改目录权限
			Ask "نام دایرکتوری را وارد کنید: " dirname
			Ask "مجوزها را وارد کنید (مانند ۷۵۵): " perm
			chmod "$perm" "$dirname" && echo "مجوزها تغییر کردند" || echo "تغییر ناموفق بود"
			send_stats "修改目录权限"
			;;
		4)
			# 重命名目录
			Ask "نام دایرکتوری فعلی را وارد کنید: " current_name
			Ask "نام دایرکتوری جدید را وارد کنید: " new_name
			mv "$current_name" "$new_name" && echo "دایرکتوری تغییر نام یافت" || echo "تغییر نام ناموفق بود"
			send_stats "重命名目录"
			;;
		5)
			# 删除目录
			Ask "نام دایرکتوری مورد نظر برای حذف را وارد کنید: " dirname
			rm -rf "$dirname" && echo "دایرکتوری حذف شد" || echo "حذف ناموفق بود"
			send_stats "删除目录"
			;;
		6)
			# 返回上一级选单目录
			cd ..
			send_stats "返回上一级选单目录"
			;;
		11)
			# 创建文件
			Ask "نام فایل مورد نظر برای ایجاد را وارد کنید: " filename
			touch "$filename" && echo "فایل ایجاد شد" || echo "ایجاد ناموفق بود"
			send_stats "创建文件"
			;;
		12)
			# 编辑文件
			Ask "نام فایل مورد نظر برای ویرایش را وارد کنید: " filename
			install nano
			nano "$filename"
			send_stats "编辑文件"
			;;
		13)
			# 修改文件权限
			Ask "نام فایل را وارد کنید: " filename
			Ask "مجوزها را وارد کنید (مانند ۷۵۵): " perm
			chmod "$perm" "$filename" && echo "مجوزها تغییر کردند" || echo "تغییر ناموفق بود"
			send_stats "修改文件权限"
			;;
		14)
			# 重命名文件
			Ask "نام فایل فعلی را وارد کنید: " current_name
			Ask "نام فایل جدید را وارد کنید: " new_name
			mv "$current_name" "$new_name" && echo "فایل تغییر نام یافت" || echo "تغییر نام ناموفق بود"
			send_stats "重命名文件"
			;;
		15)
			# 删除文件
			Ask "نام فایل مورد نظر برای حذف را وارد کنید: " filename
			rm -f "$filename" && echo "فایل حذف شد" || echo "حذف ناموفق بود"
			send_stats "删除文件"
			;;
		21)
			# 压缩文件/目录
			Ask "نام فایل/دایرکتوری مورد نظر برای فشرده سازی را وارد کنید: " name
			install tar
			tar -czvf "$name.tar.gz" "$name" && echo "به $name.tar.gz فشرده شد" || echo "فشرده‌سازی ناموفق بود"
			send_stats "压缩文件/目录"
			;;
		22)
			# 解压文件/目录
			Ask "نام فایل مورد نظر برای باز کردن فشرده سازی را وارد کنید (.tar.gz): " filename
			install tar
			tar -xzvf "$filename" && echo "استخراج شد $filename" || echo "استخراج ناموفق بود"
			send_stats "解压文件/目录"
			;;

		23)
			# 移动文件或目录
			Ask "مسیر فایل یا دایرکتوری مورد نظر برای انتقال را وارد کنید: " src_path
			if [ ! -e "$src_path" ]; then
				echo "خطا: فایل یا دایرکتوری وجود ندارد."
				send_stats "移动文件或目录失败: 文件或目录不存在"
				continue
			fi

			Ask "مسیر مقصد را وارد کنید (شامل نام فایل یا دایرکتوری جدید): " dest_path
			if [ -z "$dest_path" ]; then
				echo "خطا: لطفاً مسیر مقصد را وارد کنید."
				send_stats "移动文件或目录失败: 目标路径未指定"
				continue
			fi

			mv "$src_path" "$dest_path" && echo "فایل یا دایرکتوری به $dest_path منتقل شد" || echo "انتقال فایل یا دایرکتوری ناموفق بود"
			send_stats "移动文件或目录"
			;;

		24)
			# 复制文件目录
			Ask "مسیر فایل یا دایرکتوری مورد نظر برای کپی را وارد کنید: " src_path
			if [ ! -e "$src_path" ]; then
				echo "خطا: فایل یا دایرکتوری وجود ندارد."
				send_stats "复制文件或目录失败: 文件或目录不存在"
				continue
			fi

			Ask "مسیر مقصد را وارد کنید (شامل نام فایل یا دایرکتوری جدید): " dest_path
			if [ -z "$dest_path" ]; then
				echo "خطا: لطفاً مسیر مقصد را وارد کنید."
				send_stats "复制文件或目录失败: 目标路径未指定"
				continue
			fi

			# 使用 -r 选项以递归方式复制目录
			cp -r "$src_path" "$dest_path" && echo "فایل یا دایرکتوری به $dest_path کپی شد" || echo "کپی فایل یا دایرکتوری ناموفق بود"
			send_stats "复制文件或目录"
			;;

		25)
			# 传送文件至远端服务器
			Ask "مسیر فایل مورد نظر برای انتقال را وارد کنید: " file_to_transfer
			if [ ! -f "$file_to_transfer" ]; then
				echo "خطا: فایل وجود ندارد."
				send_stats "传送文件失败: 文件不存在"
				continue
			fi

			Ask "IP سرور راه دور را وارد کنید: " remote_ip
			if [ -z "$remote_ip" ]; then
				echo "خطا: لطفا IP سرور راه دور را وارد کنید."
				send_stats "传送文件失败: 未输入远端服务器IP"
				continue
			fi

			Ask "نام کاربری سرور راه دور را وارد کنید (پیش فرض root): " remote_user
			remote_user=${remote_user:-root}

			Ask "رمز عبور سرور راه دور را وارد کنید: " -s remote_password
			echo
			if [ -z "$remote_password" ]; then
				echo "خطا: لطفاً رمز عبور سرور راه دور را وارد کنید."
				send_stats "传送文件失败: 未输入远端服务器密码"
				continue
			fi

			Ask "پورت ورود را وارد کنید (پیش فرض ۲۲): " remote_port
			remote_port=${remote_port:-22}

			# 清除已知主机的旧条目
			ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			sleep 2 # 等待时间

			# 使用scp传输文件
			NO_TRAN=$'echo "$remote_password" | scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/"'
			eval "$NO_TRAN"

			if [ $? -eq 0 ]; then
				echo "فایل به دایرکتوری home سرور راه دور منتقل شد."
				send_stats "文件传送成功"
			else
				echo "انتقال فایل ناموفق بود."
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
			echo "انتخاب نامعتبر است، لطفاً دوباره وارد کنید"
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
		echo -e "${gl_huang}در حال اتصال به $name ($hostname)...${gl_bai}"
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
		echo "کنترل خوشه سرور"
		cat ~/cluster/servers.py
		echo
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}مدیریت لیست سرورها${gl_bai}"
		echo -e "${gl_kjlan}1.  ${gl_bai}افزودن سرور               ${gl_kjlan}2.  ${gl_bai}حذف سرور            ${gl_kjlan}3.  ${gl_bai}ویرایش سرور"
		echo -e "${gl_kjlan}4.  ${gl_bai}پشتیبان‌گیری از کلاستر                 ${gl_kjlan}5.  ${gl_bai}بازیابی کلاستر"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}اجرای دسته‌ای وظایف${gl_bai}"
		echo -e "${gl_kjlan}11. ${gl_bai}نصب اسکریپت科技lion         ${gl_kjlan}12. ${gl_bai}به‌روزرسانی سیستم              ${gl_kjlan}13. ${gl_bai}پاکسازی سیستم"
		echo -e "${gl_kjlan}14. ${gl_bai}نصب docker               ${gl_kjlan}15. ${gl_bai}نصب BBR3              ${gl_kjlan}16. ${gl_bai}تنظیم حافظه مجازی 1 گیگابایت"
		echo -e "${gl_kjlan}17. ${gl_bai}تنظیم منطقه زمانی به شانگهای           ${gl_kjlan}18. ${gl_bai}باز کردن تمام پورت‌ها\t       ${gl_kjlan}51. ${gl_bai}دستور سفارشی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.  ${gl_bai}بازگشت به منوی اصلی"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " sub_choice

		case $sub_choice in
		1)
			send_stats "添加集群服务器"
			Ask "نام سرور: " server_name
			Ask "IP سرور: " server_ip
			Ask "پورت سرور (۲۲): " server_port
			local server_port=${server_port:-22}
			Ask "نام کاربری سرور (root): " server_username
			local server_username=${server_username:-root}
			Ask "رمز عبور کاربر سرور: " server_password

			sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			;;
		2)
			send_stats "删除集群服务器"
			Ask "کلیدواژه مورد نظر برای حذف را وارد کنید: " rmserver
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
			echo -e "لطفاً فایل ${gl_huang}/root/cluster/servers.py${gl_bai} را دانلود کنید تا پشتیبان‌گیری کامل شود!"
			break_end
			;;

		5)
			clear
			send_stats "还原集群"
			echo "لطفاً servers.py خود را آپلود کنید، برای شروع آپلود هر کلیدی را فشار دهید!"
			echo -e "لطفاً فایل ${gl_huang}servers.py${gl_bai} خود را در ${gl_huang}/root/cluster/${gl_bai} آپلود کنید تا بازیابی کامل شود!"
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
			Ask "دستور اجرای دسته ای را وارد کنید: " mingling
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
	echo "بخش تبلیغات"
	echo "------------------------"
	echo "تجربه تبلیغات و خرید ساده‌تر و زیباتر را برای کاربران فراهم می‌کند!"
	echo
	echo -e "تخفیف سرور"
	echo "------------------------"
	echo -e "${gl_lan}LeCloud هنگ کنگ CN2 GIA کره دو ISP آمریکا CN2 GIA فعالیت‌های تخفیف${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}RackNerd 10.99 دلار در سال آمریکا 1 هسته 1 گیگابایت رم 20 گیگابایت هارد 1 ترابایت ترافیک در ماه${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}Hostinger 52.7 دلار در سال آمریکا 1 هسته 4 گیگابایت رم 50 گیگابایت هارد 4 ترابایت ترافیک در ماه${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
	echo "------------------------"
	echo -e "${gl_huang}搬瓦工 49 دلار در هر فصل آمریکا CN2GIA ژاپن سافت‌بنک 2 هسته 1 گیگابایت رم 20 گیگابایت هارد 1 ترابایت ترافیک در ماه${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
	echo "------------------------"
	echo -e "${gl_lan}DMIT 28 دلار در هر فصل آمریکا CN2GIA 1 هسته 2 گیگابایت رم 20 گیگابایت هارد 800 گیگابایت ترافیک در ماه${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
	echo "------------------------"
	echo -e "${gl_zi}V.PS 6.9 دلار در ماه توکیو سافت‌بنک 2 هسته 1 گیگابایت رم 20 گیگابایت هارد 1 ترابایت ترافیک در ماه${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}تخفیف‌های بیشتر برای VPS${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://kejilion.pro/topvps/${gl_bai}"
	echo "------------------------"
	echo
	echo -e "تخفیف دامنه"
	echo "------------------------"
	echo -e "${gl_lan}GNAME 8.8 دلار برای سال اول دامنه COM 6.68 دلار برای سال اول دامنه CC${gl_bai}"
	echo -e "${gl_bai}آدرس وب: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
	echo "------------------------"
	echo
	echo -e "لوازم جانبی科技 lion"
	echo "------------------------"
	echo -e "${gl_kjlan}Bilibili: ${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}یوتیوب: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
	echo -e "${gl_kjlan}وب‌سایت رسمی: ${gl_bai}https://kejilion.pro/              ${gl_kjlan}راهنما: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
	echo -e "${gl_kjlan}بلاگ: ${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}مرکز نرم‌افزار: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
	echo "------------------------"
	echo -e "${gl_kjlan}وب‌سایت رسمی اسکریپت: ${gl_bai}https://kejilion.sh            ${gl_kjlan}آدرس GitHub: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
	echo "------------------------"
	echo
}

kejilion_update() {

	send_stats "脚本更新"
	cd ~
	while true; do
		clear
		echo "گزارش به‌روزرسانی"
		echo "------------------------"
		echo "تمام گزارش‌ها: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
		echo "------------------------"

		curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
		local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

		if [ "$sh_v" = "$sh_v_new" ]; then
			echo -e "${gl_lv}شما آخرین نسخه هستید!${gl_huang}v$sh_v${gl_bai}"
			send_stats "脚本已经最新了，无需更新"
		else
			echo "نسخه جدید پیدا شد!"
			echo -e "نسخه فعلی v$sh_v        آخرین نسخه ${gl_huang}v$sh_v_new${gl_bai}"
		fi

		local cron_job="kejilion.sh"
		local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

		if [ -n "$existing_cron" ]; then
			echo "------------------------"
			echo -e "${gl_lv}به‌روزرسانی خودکار فعال است، اسکریپت هر روز ساعت 2 بامداد به‌طور خودکار به‌روزرسانی می‌شود!${gl_bai}"
		fi

		echo "------------------------"
		echo "1. به‌روزرسانی اکنون 2. فعال کردن به‌روزرسانی خودکار 3. غیرفعال کردن به‌روزرسانی خودکار"
		echo "------------------------"
		echo "0. بازگشت به منوی اصلی"
		echo "------------------------"
		Ask "انتخاب خود را وارد کنید: " choice
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
			echo -e "${gl_lv}اسکریپت به آخرین نسخه به‌روزرسانی شد!${gl_huang}v$sh_v_new${gl_bai}"
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
			echo -e "${gl_lv}به‌روزرسانی خودکار فعال است، اسکریپت هر روز ساعت 2 بامداد به‌طور خودکار به‌روزرسانی می‌شود!${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}به‌روزرسانی خودکار غیرفعال است${gl_bai}"
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
		echo -e "جعبه ابزار اسکریپت科技lion v$sh_v"
		echo -e "در خط فرمان ${gl_huang}k${gl_kjlan} را وارد کنید تا اسکریپت به سرعت راه‌اندازی شود${gl_bai}"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}1.   ${gl_bai}پرس و جوی اطلاعات سیستم"
		echo -e "${gl_kjlan}2.   ${gl_bai}به‌روزرسانی سیستم"
		echo -e "${gl_kjlan}3.   ${gl_bai}پاکسازی سیستم"
		echo -e "${gl_kjlan}4.   ${gl_bai}ابزارهای پایه"
		echo -e "${gl_kjlan}5.   ${gl_bai}مدیریت BBR"
		echo -e "${gl_kjlan}6.   ${gl_bai}مدیریت Docker"
		echo -e "${gl_kjlan}7.   ${gl_bai}مدیریت WARP"
		echo -e "${gl_kjlan}8.   ${gl_bai}مجموعه اسکریپت‌های تست"
		echo -e "${gl_kjlan}9.   ${gl_bai}مجموعه اسکریپت‌های ابری Oracle"
		echo -e "${gl_huang}10.  ${gl_bai}راه‌اندازی سایت LDNMP"
		echo -e "${gl_kjlan}11.  ${gl_bai}بازارچه اپلیکیشن"
		echo -e "${gl_kjlan}12.  ${gl_bai}فضای کاری پس‌زمینه"
		echo -e "${gl_kjlan}13.  ${gl_bai}ابزارهای سیستم"
		echo -e "${gl_kjlan}14.  ${gl_bai}کنترل خوشه سرور"
		echo -e "${gl_kjlan}15.  ${gl_bai}بخش تبلیغات"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}p.   ${gl_bai}اسکریپت راه‌اندازی سرور Palworld"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}00.  ${gl_bai}به‌روزرسانی اسکریپت"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		echo -e "${gl_kjlan}0.   ${gl_bai}خروج از اسکریپت"
		echo -e "${gl_kjlan}------------------------${gl_bai}"
		Ask "انتخاب خود را وارد کنید: " choice

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
		*) echo "ورودی نامعتبر!" ;;
		esac
		break_end
	done
}

k_info() {
	send_stats "k命令参考用例"
	echo "-------------------"
	echo "معرفی ویدیو: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
	echo "در زیر نمونه‌های مرجع دستور k آورده شده است:"
	echo "اسکریپت راه‌اندازی            k"
	echo "نصب بسته نرم‌افزاری          k install nano wget | k add nano wget | k نصب nano wget"
	echo "حذف بسته نرم‌افزاری          k remove nano wget | k del nano wget | k uninstall nano wget | k حذف nano wget"
	echo "به‌روزرسانی سیستم            k update | k به‌روزرسانی"
	echo "پاکسازی زباله‌های سیستم        k clean | k پاکسازی"
	echo "نصب مجدد پنل سیستم        k dd | k نصب مجدد"
	echo "پنل کنترل bbr3        k bbr3 | k bbrv3"
	echo "پنل تنظیم هسته        k nhyh | k تنظیم هسته"
	echo "تنظیم حافظه مجازی        k swap 2048"
	echo "تنظیم منطقه زمانی مجازی        k time Asia/Shanghai | k منطقه زمانی Asia/Shanghai"
	echo "سطل زباله سیستم          k trash | k hsz | k سطل زباله"
	echo "قابلیت پشتیبان‌گیری سیستم        k backup | k bf | k پشتیبان‌گیری"
	echo "ابزار اتصال از راه دور ssh     k ssh | k اتصال از راه دور"
	echo "ابزار همگام‌سازی از راه دور rsync   k rsync | k همگام‌سازی از راه دور"
	echo "ابزار مدیریت دیسک        k disk | k مدیریت دیسک"
	echo "نفوذ به شبکه داخلی (سرور)  k frps"
	echo "نفوذ به شبکه داخلی (کلاینت)  k frpc"
	echo "راه‌اندازی نرم‌افزار            k start sshd | k راه‌اندازی sshd "
	echo "توقف نرم‌افزار            k stop sshd | k توقف sshd "
	echo "راه‌اندازی مجدد نرم‌افزار            k restart sshd | k راه‌اندازی مجدد sshd "
	echo "مشاهده وضعیت نرم‌افزار        k status sshd | k وضعیت sshd "
	echo "راه‌اندازی خودکار نرم‌افزار هنگام روشن شدن سیستم        k enable docker | k autostart docke | k راه‌اندازی خودکار docker "
	echo "درخواست گواهی دامنه        k ssl"
	echo "استعلام تاریخ انقضای گواهی دامنه    k ssl ps"
	echo "نصب محیط docker      k docker install |k docker نصب"
	echo "مدیریت کانتینر docker      k docker ps |k docker کانتینر"
	echo "مدیریت ایمیج docker      k docker img |k docker ایمیج"
	echo "مدیریت سایت LDNMP      k web"
	echo "پاکسازی کش LDNMP       k web cache"
	echo "نصب وردپرس       k wp |k wordpress |k wp xxx.com"
	echo "نصب پروکسی معکوس        k fd |k rp |k پروکسی معکوس |k fd xxx.com"
	echo "نصب تعادل بار        k loadbalance |k تعادل بار"
	echo "پنل فایروال          k fhq |k فایروال"
	echo "باز کردن پورت            k dkdk 8080 |k باز کردن پورت 8080"
	echo "بستن پورت            k gbdk 7800 |k بستن پورت 7800"
	echo "اجازه دسترسی به IP              k fxip 127.0.0.0/8 |k اجازه دسترسی به IP 127.0.0.0/8"
	echo "مسدود کردن IP              k zzip 177.5.25.36 |k مسدود کردن IP 177.5.25.36"
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
