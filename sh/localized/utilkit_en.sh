#!/bin/bash
Authors="OG-Open-Source"
Scripts="UtilKit.sh"
Version="6.043.009.241"
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
Txt(){ echo -e "$1";}
Err(){
[ -z "$1" ]&&{
Txt "${CLR1}Unknown error${CLR0}"
return 1
}
Txt "$CLR1$1$CLR0"
if [ -w "/var/log" ];then
log_file="/var/log/utilkit.sh.log"
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
log_entry="$timestamp | $Scripts - $Version - $(Txt "$1"|tr -d '\n')"
Txt "$log_entry" >>"$log_file" 2>/dev/null
fi
}
function Add(){
[ $# -eq 0 ]&&{
Err "No items specified for insertion. Please provide at least one item to add"
return 2
}
[ "$1" = "-f" -o "$1" = "-d" ]&&[ $# -eq 1 ]&&{
Err "No file or directory path specified after -f or -d"
return 2
}
[ "$1" = "-f" -o "$1" = "-d" ]&&[ "$2" = "" ]&&{
Err "No file or directory path specified after -f or -d"
return 2
}
mode="pkg"
failed=0
while [ $# -gt 0 ];do
case "$1" in
-f)mode="file"
shift
continue
;;
-d)mode="dir"
shift
continue
;;
*.deb)CHECK_ROOT
deb_file=$(basename "$1")
Txt "${CLR3}INSERT DEB PACKAGE [$deb_file]${CLR0}\n"
Get "$1"
if [ -f "$deb_file" ];then
dpkg -i "$deb_file"||{
Err "Failed to install $deb_file. Check package compatibility and dependencies\n"
Del -f "$deb_file"
failed=1
shift
continue
}
apt --fix-broken install -y||{
Err "Failed to fix dependencies"
Del -f "$deb_file"
failed=1
shift
continue
}
Txt "* DEB package $deb_file installed successfully"
Del -f "$deb_file"
Txt "${CLR2}FINISHED${CLR0}\n"
else
Err "DEB package $deb_file not found or download failed\n"
failed=1
shift
continue
fi
shift
;;
*)case "$mode" in
"file")Txt "${CLR3}INSERT FILE [$1]${CLR0}"
[ -d "$1" ]&&{
Err "Directory $1 already exists. Cannot create file with the same name\n"
failed=1
shift
continue
}
[ -f "$1" ]&&{
Err "File $1 already exists\n"
failed=1
shift
continue
}
touch "$1"||{
Err "Failed to create file $1. Check permissions and disk space\n"
failed=1
shift
continue
}
Txt "* File $1 created successfully"
Txt "${CLR2}FINISHED${CLR0}\n"
;;
"dir")Txt "${CLR3}INSERT DIRECTORY [$1]${CLR0}"
[ -f "$1" ]&&{
Err "File $1 already exists. Cannot create directory with the same name\n"
failed=1
shift
continue
}
[ -d "$1" ]&&{
Err "Directory $1 already exists\n"
failed=1
shift
continue
}
mkdir -p "$1"||{
Err "Failed to create directory $1. Check permissions and path validity\n"
failed=1
shift
continue
}
Txt "* Directory $1 created successfully"
Txt "${CLR2}FINISHED${CLR0}\n"
;;
"pkg")Txt "${CLR3}INSERT PACKAGE [$1]${CLR0}"
CHECK_ROOT
pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf|head -n1)
pkg_manager=${pkg_manager##*/}
case $pkg_manager in
apk|apt|opkg|pacman|yum|zypper|dnf)is_installed(){
case $pkg_manager in
apk)apk info -e "$1" &>/dev/null;;
apt)dpkg-query -W -f='${Status}' "$1" 2>/dev/null|grep -q "ok installed";;
opkg)opkg list-installed|grep -q "^$1 ";;
pacman)pacman -Qi "$1" &>/dev/null;;
yum|dnf)$pkg_manager list installed "$1" &>/dev/null;;
zypper)zypper se -i -x "$1" &>/dev/null
esac
}
install_pkg(){
case $pkg_manager in
apk)apk update&&apk add "$1";;
apt)apt install -y "$1";;
opkg)opkg update&&opkg install "$1";;
pacman)pacman -Sy&&pacman -S --noconfirm "$1";;
yum|dnf)$pkg_manager install -y "$1";;
zypper)zypper refresh&&zypper install -y "$1"
esac
}
if ! is_installed "$1";then
Txt "* Package $1 is not installed"
if install_pkg "$1";then
if is_installed "$1";then
Txt "* Package $1 installed successfully"
Txt "${CLR2}FINISHED${CLR0}\n"
else
Err "Failed to install $1 using $pkg_manager\n"
failed=1
shift
continue
fi
else
Err "Failed to install $1 using $pkg_manager\n"
failed=1
shift
continue
fi
else
Txt "* Package $1 is already installed"
Txt "${CLR2}FINISHED${CLR0}\n"
fi
;;
*)Err "Unsupported package manager\n"
failed=1
shift
continue
esac
esac
shift
esac
done
return $failed
}
function CHECK_DEPS(){
mode="display"
missing_deps=()
while [[ $1 == -* ]];do
case "$1" in
-i)mode="interactive";;
-a)mode="auto";;
*)Err "Invalid option: $1"
return 1
esac
shift
done
for dep in "${deps[@]}";do
if command -v "$dep" &>/dev/null;then
status="${CLR2}[Available]${CLR0}"
else
status="${CLR1}[Not Found]${CLR0}"
missing_deps+=("$dep")
fi
Txt "$status\t$dep"
done
[[ ${#missing_deps[@]} -eq 0 ]]&&return 0
case "$mode" in
"interactive")Txt "\n${CLR3}Missing packages:${CLR0} ${missing_deps[*]}"
read -p "Do you want to install the missing packages? (y/N) " -n 1 -r
Txt "\n"
[[ $REPLY =~ ^[Yy] ]]&&Add "${missing_deps[@]}"
;;
"auto")Txt
Add "${missing_deps[@]}"
esac
}
function CHECK_OS(){
case "$1" in
-v)if
[ -f /etc/os-release ]
then
source /etc/os-release
[ "$ID" = "debian" ]&&cat /etc/debian_version||Txt "$VERSION_ID"
elif [ -f /etc/debian_version ];then
cat /etc/debian_version
elif [ -f /etc/fedora-release ];then
grep -oE '[0-9]+' /etc/fedora-release
elif [ -f /etc/centos-release ];then
grep -oE '[0-9]+\.[0-9]+' /etc/centos-release
elif [ -f /etc/alpine-release ];then
cat /etc/alpine-release
else
{
Err "Unknown distribution version"
return 1
}
fi
;;
-n)if
[ -f /etc/os-release ]
then
source /etc/os-release
Txt "$ID"|sed 's/.*/\u&/'
elif [ -f /etc/DISTRO_SPECS ];then
grep -i "DISTRO_NAME" /etc/DISTRO_SPECS|cut -d'=' -f2|awk '{print $1}'
else
{
Err "Unknown distribution"
return 1
}
fi
;;
*)if
[ -f /etc/os-release ]
then
source /etc/os-release
[ "$ID" = "debian" ]&&Txt "$NAME $(cat /etc/debian_version)"||Txt "$PRETTY_NAME"
elif [ -f /etc/DISTRO_SPECS ];then
grep -i "DISTRO_NAME" /etc/DISTRO_SPECS|cut -d'=' -f2
else
{
Err "Unknown distribution"
return 1
}
fi
esac
}
function CHECK_ROOT(){
if [ "$EUID" -ne 0 ]||[ "$(id -u)" -ne 0 ];then
Err "Please run this script as root user"
exit 1
fi
}
function CHECK_VIRT(){
if command -v systemd-detect-virt >/dev/null 2>&1;then
virt_type=$(systemd-detect-virt 2>/dev/null)
[ -z "$virt_type" ]&&{
Err "Unable to detect virtualization environment"
return 1
}
case "$virt_type" in
kvm)grep -qi "proxmox" /sys/class/dmi/id/product_name 2>/dev/null&&Txt "Proxmox VE (KVM)"||Txt "KVM";;
microsoft)Txt "Microsoft Hyper-V";;
none)if
grep -q "container=lxc" /proc/1/environ 2>/dev/null
then
Txt "LXC container"
elif grep -qi "hypervisor" /proc/cpuinfo 2>/dev/null;then
Txt "Virtual machine (Unknown type)"
else
Txt "Not detected (possibly bare metal)"
fi
;;
*)Txt "${virt_type:-Not detected (possibly bare metal)}"
esac
elif [ -f /proc/cpuinfo ];then
virt_type=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null&&Txt "VM"||Txt "None")
else
virt_type="Unknown"
fi
}
function CLEAN(){
cd "$HOME"||{
Err "Failed to change directory to HOME"
return 1
}
clear
}
function CPU_CACHE(){
[ ! -f /proc/cpuinfo ]&&{
Err "Cannot access CPU information. /proc/cpuinfo not available"
return 1
}
cpu_cache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
[ "$cpu_cache" = "N/A" ]&&{
Err "Unable to determine CPU cache size"
return 1
}
Txt "$cpu_cache KB"
}
function CPU_FREQ(){
[ ! -f /proc/cpuinfo ]&&{
Err "Cannot access CPU information. /proc/cpuinfo not available"
return 1
}
cpu_freq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
[ "$cpu_freq" = "N/A" ]&&{
Err "Unable to determine CPU frequency"
return 1
}
Txt "$cpu_freq GHz"
}
function CPU_MODEL(){
if command -v lscpu &>/dev/null;then
lscpu|awk -F': +' '/Model name/ {print $2; exit}'
elif [ -f /proc/cpuinfo ];then
sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo|head -n1
elif command -v sysctl &>/dev/null&&sysctl -n machdep.cpu.brand_string &>/dev/null;then
sysctl -n machdep.cpu.brand_string
else
{
Txt "$CLR1Unknown$CLR0"
return 1
}
fi
}
function CPU_USAGE(){
read -r cpu user nice system idle iowait irq softirq <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat)||{
Err "Failed to read CPU statistics from /proc/stat"
return 1
}
total1=$((user+nice+system+idle+iowait+irq+softirq))
idle1=$idle
sleep 0.3
read -r cpu user nice system idle iowait irq softirq <<<$(awk '/^cpu / {print $1,$2,$3,$4,$5,$6,$7,$8}' /proc/stat)||{
Err "Failed to read CPU statistics from /proc/stat"
return 1
}
total2=$((user+nice+system+idle+iowait+irq+softirq))
idle2=$idle
total_diff=$((total2-total1))
idle_diff=$((idle2-idle1))
usage=$((100*(total_diff-idle_diff)/total_diff))
Txt "$usage"
}
function CONVERT_SIZE(){
[ -z "$1" ]&&{
Err "No size value provided for conversion"
return 2
}
size=$1
unit=${2:-iB}
unit_lower=$(FORMAT -aa "$unit")
if ! [[ $size =~ ^[+-]?[0-9]*\.?[0-9]+$ ]];then
{
Err "Invalid size value. Must be a numeric value"
return 2
}
elif [[ $size =~ ^[-].*$ ]];then
{
Err "Size value cannot be negative"
return 2
}
elif [[ $size =~ ^[+].*$ ]];then
size=${size#+}
fi
case "$unit_lower" in
b)bytes=$size;;
kb|kib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "kb" ? 1000 : 1024)}');;
mb|mib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "mb" ? 1000000 : 1048576)}');;
gb|gib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "gb" ? 1000000000 : 1073741824)}');;
tb|tib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "tb" ? 1000000000000 : 1099511627776)}');;
pb|pib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unit_lower" 'BEGIN {printf "%.0f", size * (unit == "pb" ? 1000000000000000 : 1125899906842624)}');;
*)bytes=$size
esac
[[ ! $bytes =~ ^[0-9]+\.?[0-9]*$ ]]&&{
Err "Failed to convert size value"
return 1
}
LC_NUMERIC=C awk -v bytes="$bytes" -v is_binary="$([[ $unit_lower =~ ^.*ib$ ]]&&Txt 1||Txt 0)" '
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
function COPYRIGHT(){
Txt "$Scripts $Version"
Txt "Copyright (C) $(date +%Y) $Authors."
}
function DEL(){
[ $# -eq 0 ]&&{
Err "No items specified for deletion. Please provide at least one item to delete"
return 2
}
[ "$1" = "-f" -o "$1" = "-d" ]&&[ $# -eq 1 ]&&{
Err "No file or directory path specified after -f or -d"
return 2
}
[ "$1" = "-f" -o "$1" = "-d" ]&&[ "$2" = "" ]&&{
Err "No file or directory path specified after -f or -d"
return 2
}
mode="pkg"
failed=0
while [ $# -gt 0 ];do
case "$1" in
-f)mode="file"
shift
continue
;;
-d)mode="dir"
shift
continue
;;
*)Txt "${CLR3}REMOVE $(FORMAT -AA "$mode") [$1]$CLR0"
case "$mode" in
"file")[ ! -f "$1" ]&&{
Err "File $1 does not exist\n"
failed=1
shift
continue
}
Txt "*#Qr4sf7#*"
rm -f "$1"||{
Err "Failed to remove file $1\n"
failed=1
shift
continue
}
Txt "* File $1 removed successfully"
Txt "${CLR2}FINISHED${CLR0}\n"
;;
"dir")[ ! -d "$1" ]&&{
Err "Directory $1 does not exist\n"
failed=1
shift
continue
}
Txt "* Directory $1 exists"
rm -rf "$1"||{
Err "Failed to remove directory $1\n"
failed=1
shift
continue
}
Txt "* Directory $1 removed successfully"
Txt "${CLR2}FINISHED${CLR0}\n"
;;
"pkg")CHECK_ROOT
pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf|head -n1)
pkg_manager=${pkg_manager##*/}
case $pkg_manager in
apk|apt|opkg|pacman|yum|zypper|dnf)is_installed(){
case $pkg_manager in
apk)apk info -e "$1" &>/dev/null;;
apt)dpkg-query -W -f='${Status}' "$1" 2>/dev/null|grep -q "ok installed";;
opkg)opkg list-installed|grep -q "^$1 ";;
pacman)pacman -Qi "$1" &>/dev/null;;
yum|dnf)$pkg_manager list installed "$1" &>/dev/null;;
zypper)zypper se -i -x "$1" &>/dev/null
esac
}
remove_pkg(){
case $pkg_manager in
apk)apk del "$1";;
apt)apt purge -y "$1"&&apt autoremove -y;;
opkg)opkg remove "$1";;
pacman)pacman -Rns --noconfirm "$1";;
yum|dnf)$pkg_manager remove -y "$1";;
zypper)zypper remove -y "$1"
esac
}
if ! is_installed "$1";then
Err "* Package $1 is not installed\n"
failed=1
shift
continue
fi
Txt "* Package $1 is installed"
if ! remove_pkg "$1";then
Err "Failed to remove $1 using $pkg_manager\n"
failed=1
shift
continue
fi
if is_installed "$1";then
Err "Failed to remove $1 using $pkg_manager\n"
failed=1
shift
continue
fi
Txt "* Package $1 removed successfully"
Txt "${CLR2}FINISHED${CLR0}\n"
;;
*){
Err "Unsupported package manager"
return 1
}
esac
esac
shift
esac
done
return $failed
}
function DISK_USAGE(){
used=$(df -B1 /|awk '/^\/dev/ {print $3}')||{
Err "Failed to get disk usage statistics"
return 1
}
total=$(df -B1 /|awk '/^\/dev/ {print $2}')||{
Err "Failed to get total disk space"
return 1
}
percentage=$(df /|awk '/^\/dev/ {printf("%.2f"), $3/$2 * 100.0}')
case "$1" in
-u)Txt "$used";;
-t)Txt "$total";;
-p)Txt "$percentage";;
*)Txt "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)"
esac
}
function DNS_ADDR(){
[ ! -f /etc/resolv.conf ]&&{
Err "DNS configuration file /etc/resolv.conf not found"
return 1
}
ipv4_servers=()
ipv6_servers=()
while read -r server;do
if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];then
ipv4_servers+=("$server")
elif [[ $server =~ ^[0-9a-fA-F:]+$ ]];then
ipv6_servers+=("$server")
fi
done < <(grep -E '^nameserver' /etc/resolv.conf|awk '{print $2}')
[[ ${#ipv4_servers[@]} -eq 0 && ${#ipv6_servers[@]} -eq 0 ]]&&{
Err "No DNS servers configured in /etc/resolv.conf"
return 1
}
case "$1" in
-4)[ ${#ipv4_servers[@]} -eq 0 ]&&{
Err "No IPv4 DNS servers found"
return 1
}
Txt "${ipv4_servers[*]}"
;;
-6)[ ${#ipv6_servers[@]} -eq 0 ]&&{
Err "No IPv6 DNS servers found"
return 1
}
Txt "${ipv6_servers[*]}"
;;
*)[ ${#ipv4_servers[@]} -eq 0 -a ${#ipv6_servers[@]} -eq 0 ]&&{
Err "No DNS servers found"
return 1
}
Txt "${ipv4_servers[*]}   ${ipv6_servers[*]}"
esac
}
function FIND(){
[ $# -eq 0 ]&&{
Err "No search terms provided. Please specify what to search for"
return 2
}
pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf|head -n1)
case ${pkg_manager##*/} in
apk)search_command="apk search";;
apt)search_command="apt-cache search";;
opkg)search_command="opkg search";;
pacman)search_command="pacman -Ss";;
yum)search_command="yum search";;
zypper)search_command="zypper search";;
dnf)search_command="dnf search";;
*){
Err "Package manager not found or unsupported"
return 1
}
esac
for target in "$@";do
Txt "${CLR3}SEARCH [$target]${CLR0}"
$search_command "$target"||{
Err "No results found for $target\n"
return 1
}
Txt "${CLR2}FINISHED${CLR0}\n"
done
}
function FONT(){
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
[L.BG.BLUE]="\033[104m" [L.BG.PURPLE]="\033[105m" [L.BG.CYAN]="\033[106m" [L.BG.WHITE]="\033[107m")
while [[ $# -gt 1 ]];do
case "$1" in
RGB)shift
[[ $1 =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]]&&font+="\033[38;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
;;
BG.RGB)shift
[[ $1 =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]]&&font+="\033[48;2;${BASH_REMATCH[1]};${BASH_REMATCH[2]};${BASH_REMATCH[3]}m"
;;
*)font+="${style[$1]:-}"
esac
shift
done
Txt "$font$1$CLR0"
}
function FORMAT(){
option="$1"
value="$2"
result=""
[ -z "$value" ]&&{
Err "No value provided for formatting"
return 2
}
[ -z "$option" ]&&{
Err "No formatting option provided"
return 2
}
case "$option" in
-AA)result=$(Txt "$value"|tr '[:lower:]' '[:upper:]');;
-aa)result=$(Txt "$value"|tr '[:upper:]' '[:lower:]');;
-Aa)result=$(Txt "$value"|tr '[:upper:]' '[:lower:]'|sed 's/\b\(.\)/\u\1/');;
*)result="$value"
esac
Txt "$result"
}
function Get(){
extract="false"
target_dir="."
rename_file=""
url=""
while [ $# -gt 0 ];do
case "$1" in
-x)extract=true
shift
;;
-r)[ -z "$2" ]||[[ $2 == -* ]]&&{
Err "No filename specified after -r option"
return 2
}
rename_file="$2"
shift 2
;;
-*){
Err "Invalid option: $1"
return 2
};;
*)[ -z "$url" ]&&url="$1"||target_dir="$1"
shift
esac
done
[ -z "$url" ]&&{
Err "No URL specified. Please provide a URL to download"
return 2
}
[[ $url =~ ^(http|https|ftp):// ]]||url="https://$url"
output_file="${url##*/}"
[ -z "$output_file" ]&&output_file="index.html"
[ "$target_dir" != "." ]&&{ mkdir -p "$target_dir"||{
Err "Failed to create directory $target_dir"
return 1
};}
[ -n "$rename_file" ]&&output_file="$rename_file"
output_path="$target_dir/$output_file"
url=$(Txt "$url"|sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
Txt "${CLR3}DOWNLOAD [$url]${CLR0}"
file_size=$(curl -sI "$url"|grep -i content-length|awk '{print $2}'|tr -d '\r')
size_limit="26214400"
if [ -n "$file_size" ]&&[ "$file_size" -gt "$size_limit" ];then
wget --no-check-certificate --timeout=5 --tries=2 "$url" -O "$output_path"||{
Err "Failed to download file using wget"
return 1
}
else
curl --location --insecure --connect-timeout 5 --retry 2 "$url" -o "$output_path"||{
Err "Failed to download file using curl"
return 1
}
fi
if [ -f "$output_path" ];then
Txt "* File downloaded successfully to $output_path"
if [ "$extract" = true ];then
case "$output_file" in
*.tar.gz|*.tgz)tar -xzf "$output_path" -C "$target_dir"||{
Err "Failed to extract tar.gz file"
return 1
};;
*.tar)tar -xf "$output_path" -C "$target_dir"||{
Err "Failed to extract tar file"
return 1
};;
*.tar.bz2|*.tbz2)tar -xjf "$output_path" -C "$target_dir"||{
Err "Failed to extract tar.bz2 file"
return 1
};;
*.tar.xz|*.txz)tar -xJf "$output_path" -C "$target_dir"||{
Err "Failed to extract tar.xz file"
return 1
};;
*.zip)unzip "$output_path" -d "$target_dir"||{
Err "Failed to extract zip file"
return 1
};;
*.7z)7z x "$output_path" -o"$target_dir"||{
Err "Failed to extract 7z file"
return 1
};;
*.rar)unrar x "$output_path" "$target_dir"||{
Err "Failed to extract rar file"
return 1
};;
*.zst)zstd -d "$output_path" -o "$target_dir"||{
Err "Failed to extract zst file"
return 1
};;
*)Txt "* File format not recognized for auto-extraction"
esac
[ $? -eq 0 ]&&Txt "* File extracted successfully to $target_dir"
fi
Txt "${CLR2}FINISHED${CLR0}\n"
else
{
Err "Download failed. Check your internet connection and URL validity"
return 1
}
fi
}
function Ask(){
read -e -p "$1" "$2"||{
Err "Failed to read user input"
return 1
}
}
function INTERFACE(){
interface=""
declare -a interfaces=()
all_interfaces=$(cat /proc/net/dev|grep ':'|cut -d':' -f1|sed 's/\s//g'|grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker\|^br-\|^veth'|sort -n)||{
Err "Failed to get network interfaces from /proc/net/dev"
return 1
}
i=1
while read -r interface_item;do
[ -n "$interface_item" ]&&interfaces[$i]="$interface_item"
((i++))
done <<<"$all_interfaces"
interfaces_num="${#interfaces[*]}"
default4_route=$(ip -4 route show default 2>/dev/null|grep -A 3 "^default"||Txt)
default6_route=$(ip -6 route show default 2>/dev/null|grep -A 3 "^default"||Txt)
get_arr_item_idx(){
item="$1"
shift
arr=("$@")
for ((i=1; i<=${#arr[@]}; i++));do
if [ "$item" = "${arr[$i]}" ];then
Txt "$i"
return 0
fi
done
return 255
}
interface4=""
interface6=""
for ((i=1; i<=${#interfaces[@]}; i++));do
item="${interfaces[$i]}"
[ -z "$item" ]&&continue
if [[ -n $default4_route && $default4_route == *"$item"* ]]&&[ -z "$interface4" ];then
interface4="$item"
interface4_device_order=$(get_arr_item_idx "$item" "${interfaces[@]}")
fi
if [[ -n $default6_route && $default6_route == *"$item"* ]]&&[ -z "$interface6" ];then
interface6="$item"
interface6_device_order=$(get_arr_item_idx "$item" "${interfaces[@]}")
fi
[ -n "$interface4" ]&&[ -n "$interface6" ]&&break
done
if [ -z "$interface4" ]&&[ -z "$interface6" ];then
for ((i=1; i<=${#interfaces[@]}; i++));do
item="${interfaces[$i]}"
if [[ $item =~ ^en ]];then
interface4="$item"
interface6="$item"
break
fi
done
if [ -z "$interface4" ]&&[ -z "$interface6" ]&&[ "$interfaces_num" -gt 0 ];then
interface4="${interfaces[1]}"
interface6="${interfaces[1]}"
fi
fi
if [ -n "$interface4" ]||[ -n "$interface6" ];then
interface="$interface4 $interface6"
[[ $interface4 == "$interface6" ]]&&interface="$interface4"
interface=$(Txt "$interface"|tr -s ' '|xargs)
else
physical_iface=$(ip -o link show|grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap'|grep 'state UP'|head -n 1|awk -F': ' '{print $2}')
if [ -n "$physical_iface" ];then
interface="$physical_iface"
else
interface=$(ip -o link show|grep -v 'lo:'|head -n 1|awk -F': ' '{print $2}')
fi
fi
case "$1" in
RX_BYTES|RX_PACKETS|RX_DROP|TX_BYTES|TX_PACKETS|TX_DROP)for iface in $interface
do
if stats=$(awk -v iface="$iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null);then
read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"$stats"
case "$1" in
RX_BYTES)Txt "$rx_bytes"
break
;;
RX_PACKETS)Txt "$rx_packets"
break
;;
RX_DROP)Txt "$rx_drop"
break
;;
TX_BYTES)Txt "$tx_bytes"
break
;;
TX_PACKETS)Txt "$tx_packets"
break
;;
TX_DROP)Txt "$tx_drop"
break
esac
fi
done
;;
-i)for iface in $interface
do
if stats=$(awk -v iface="$iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null);then
read rx_bytes rx_packets rx_drop tx_bytes tx_packets tx_drop <<<"$stats"
Txt "$iface: RX: $(CONVERT_SIZE $rx_bytes), TX: $(CONVERT_SIZE $tx_bytes)"
fi
done
;;
"")Txt "$interface";;
*)Err "Invalid parameter: $1. Valid parameters are: RX_BYTES, RX_PACKETS, RX_DROP, TX_BYTES, TX_PACKETS, TX_DROP, -i"
return 2
esac
}
function IP_ADDR(){
version="$1"
case "$version" in
-4)ipv4_addr=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null)||ipv4_addr=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null)||ipv4_addr=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null)||[ -n "$ipv4_addr" ]&&Txt "$ipv4_addr"||{
Err "Failed to retrieve IPv4 address. Check your internet connection"
return 1
}
;;
-6)ipv6_addr=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null)||ipv6_addr=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null)||[ -n "$ipv6_addr" ]&&Txt "$ipv6_addr"||{
Err "Failed to retrieve IPv6 address. Check your internet connection"
return 1
}
;;
*)ipv4_addr=$(IP_ADDR -4)
ipv6_addr=$(IP_ADDR -6)
[ -z "$ipv4_addr$ipv6_addr" ]&&{
Err "Failed to retrieve IP addresses"
return 1
}
[ -n "$ipv4_addr" ]&&Txt "IPv4: $ipv4_addr"
[ -n "$ipv6_addr" ]&&Txt "IPv6: $ipv6_addr"
return
esac
}
function LAST_UPDATE(){
if [ -f /var/log/apt/history.log ];then
last_update=$(awk '/End-Date:/ {print $2, $3, $4; exit}' /var/log/apt/history.log 2>/dev/null)
elif [ -f /var/log/dpkg.log ];then
last_update=$(tail -n 1 /var/log/dpkg.log|awk '{print $1, $2}')
elif command -v rpm &>/dev/null;then
last_update=$(rpm -qa --last|head -n 1|awk '{print $3, $4, $5, $6, $7}')
fi
[ -z "$last_update" ]&&{
Err "Unable to determine last system update time. Update logs not found"
return 1
}||Txt "$last_update"
}
function LINE(){
char="${1:--}"
length="${2:-80}"
printf '%*s\n' "$length"|tr ' ' "$char"||{
Err "Failed to print line"
return 1
}
}
function LOAD_AVERAGE(){
if [ ! -f /proc/loadavg ];then
load_data=$(uptime|sed 's/.*load average: //'|sed 's/,//g')||{
Err "Failed to get load average from uptime command"
return 1
}
else
read -r one_min five_min fifteen_min _ _ </proc/loadavg||{
Err "Failed to read load average from /proc/loadavg"
return 1
}
fi
[[ $one_min =~ ^[0-9.]+$ ]]||one_min=0
[[ $five_min =~ ^[0-9.]+$ ]]||five_min=0
[[ $fifteen_min =~ ^[0-9.]+$ ]]||fifteen_min=0
LC_ALL=C printf "%.2f, %.2f, %.2f (%d cores)" "$one_min" "$five_min" "$fifteen_min" "$(nproc)"
}
function LOCATION(){
loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace"|grep "^loc="|cut -d= -f2)
[ -n "$loc" ]&&Txt "$loc"||{
Err "Unable to detect location. Check your internet connection"
return 1
}
}
function MAC_ADDR(){
mac_address=$(ip link show|awk '/ether/ {print $2; exit}')
[[ -n $mac_address ]]&&Txt "$mac_address"||{
Err "Unable to retrieve MAC address. Network interface not found"
return 1
}
}
function MEM_USAGE(){
used=$(free -b|awk '/^Mem:/ {print $3}')||used=$(vmstat -s|grep 'used memory'|awk '{print $1*1024}')||{
Err "Failed to get memory usage statistics"
return 1
}
total=$(free -b|awk '/^Mem:/ {print $2}')||total=$(grep MemTotal /proc/meminfo|awk '{print $2*1024}')
percentage=$(free|awk '/^Mem:/ {printf("%.2f"), $3/$2 * 100.0}')||percentage=$(awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {available=$2} END {printf("%.2f", (total-available)/total * 100.0)}' /proc/meminfo)
case "$1" in
-u)Txt "$used";;
-t)Txt "$total";;
-p)Txt "$percentage";;
*)Txt "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)"
esac
}
function NET_PROVIDER(){
result=$(timeout 1s curl -sL ipinfo.io|grep -oP '"org"\s*:\s*"\K[^"]+')||result=$(timeout 1s curl -sL ipwhois.app/json|grep -oP '"org"\s*:\s*"\K[^"]+')||result=$(timeout 1s curl -sL ip-api.com/json|grep -oP '"org"\s*:\s*"\K[^"]+')||[ -n "$result" ]&&Txt "$result"||{
Err "Unable to detect network provider. Check your internet connection"
return 1
}
}
function PKG_COUNT(){
pkg_manager=$(command -v apk apt opkg pacman yum zypper dnf 2>/dev/null|head -n1)
case ${pkg_manager##*/} in
apk)count_cmd="apk info";;
apt)count_cmd="dpkg --get-selections";;
opkg)count_cmd="opkg list-installed";;
pacman)count_cmd="pacman -Q";;
yum|dnf)count_cmd="rpm -qa";;
zypper)count_cmd="zypper se --installed-only";;
*){
Err "Unable to count installed packages. Package manager not supported"
return 1
}
esac
if ! pkg_count=$($count_cmd 2>/dev/null|wc -l)||[[ -z $pkg_count || $pkg_count -eq 0 ]];then
{
Err "Failed to count packages for ${pkg_manager##*/}"
return 1
}
fi
Txt "$pkg_count"
}
function PROGRESS(){
num_cmds=${#cmds[@]}
term_width=$(tput cols)||{
Err "Failed to get terminal width"
return 1
}
bar_width=$((term_width-23))
stty -echo
trap '' SIGINT SIGQUIT SIGTSTP
for ((i=0; i<num_cmds; i++));do
progress=$((i*100/num_cmds))
filled_width=$((progress*bar_width/100))
printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "$progress" "$(printf "%${filled_width}s"|tr ' ' '#')" "$(printf "%$((bar_width-filled_width))s"|tr ' ' '.')"
if ! output=$(eval "${cmds[$i]}" 2>&1);then
Txt "\n$output"
stty echo
trap - SIGINT SIGQUIT SIGTSTP
{
Err "Command execution failed: ${cmds[$i]}"
return 1
}
fi
done
printf "\r\033[30;42mProgress: [100%%]\033[0m [%s]" "$(printf "%${bar_width}s"|tr ' ' '#')"
printf "\r%${term_width}s\r"
stty echo
trap - SIGINT SIGQUIT SIGTSTP
}
function PUBLIC_IP(){
ip=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace"|grep "^ip="|cut -d= -f2)
[ -n "$ip" ]&&Txt "$ip"||{
Err "Unable to detect public IP address. Check your internet connection"
return 1
}
}
function RUN(){
commands=()
_run_completions(){
cur="${COMP_WORDS[COMP_CWORD]}"
prev="${COMP_WORDS[COMP_CWORD-1]}"
opts="${commands[*]}"
COMPREPLY=($(compgen -W "$opts" -- "$cur"))
[[ ${#COMPREPLY[@]} -eq 0 ]]&&COMPREPLY=($(compgen -c -- "$cur"))
}
complete -F _run_completions RUN
[ $# -eq 0 ]&&{
Err "No command specified"
return 2
}
if [[ $1 == *"/"* ]];then
if [[ $1 =~ ^https?:// ]];then
url="$1"
script_name=$(basename "$1")
delete_after=false
shift
while [[ $# -gt 0 && $1 == -* ]];do
case "$1" in
-d)delete_after=true
shift
;;
*)break
esac
done
Txt "${CLR3}Downloading and executing script [${script_name}] from URL${CLR0}"
Task "* Downloading script" "
				curl -sSLf "$url" -o "$script_name" || { Err "Failed to download script $script_name"; return 1; }
				chmod +x "$script_name" || { Err "Failed to set execute permission for $script_name"; return 1; }
			"
Txt "$CLR8$(LINE = "24")$CLR0"
if [[ $1 == "--" ]];then
shift
./"$script_name" "$@"||{
Err "Failed to execute script $script_name"
return 1
}
else
./"$script_name"||{
Err "Failed to execute script $script_name"
return 1
}
fi
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
[[ $delete_after == true ]]&&rm -rf "$script_name"
elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]];then
repo_owner=$(Txt "$1"|cut -d'/' -f1)
repo_name=$(Txt "$1"|cut -d'/' -f2)
script_path=$(Txt "$1"|cut -d'/' -f3-)
script_name=$(basename "$script_path")
branch="main"
download_repo=false
delete_after=false
shift
while [[ $# -gt 0 && $1 == -* ]];do
case "$1" in
-b)[[ -z $2 || $2 == -* ]]&&{
Err "Branch name required after -b"
return 2
}
branch="$2"
shift 2
;;
-r)download_repo=true
shift
;;
-d)delete_after=true
shift
;;
*)break
esac
done
if [[ $download_repo == true ]];then
Txt "${CLR3}Cloning repository ${repo_owner}/${repo_name}${CLR0}"
[[ -d $repo_name ]]&&{
Err "Directory $repo_name already exists"
return 1
}
temp_dir=$(mktemp -d)
if [[ $branch != "main" ]];then
Task "* Cloning from branch $branch" "git clone --branch $branch https://github.com/$repo_owner/$repo_name.git "$temp_dir""
if [ $? -ne 0 ];then
rm -rf "$temp_dir"
{
Err "Failed to clone repository from $branch branch"
return 1
}
fi
else
Task "* Checking main branch" "git clone --branch main https://github.com/$repo_owner/$repo_name.git "$temp_dir"" true
if [ $? -ne 0 ];then
Task "* Trying master branch" "git clone --branch master https://github.com/$repo_owner/$repo_name.git "$temp_dir""
if [ $? -ne 0 ];then
rm -rf "$temp_dir"
{
Err "Failed to clone repository from either main or master branch"
return 1
}
fi
fi
fi
Task "* Creating target directory" "Add -d "$repo_name" && cp -r "$temp_dir"/* "$repo_name"/"
Task "* Cleaning up temporary files" "rm -rf "$temp_dir""
Txt "Repository cloned to directory: ${CLR2}$repo_name${CLR0}"
if [[ -f "$repo_name/$script_path" ]];then
Task "* Setting execute permissions" "chmod +x "$repo_name/$script_path""
Txt "$CLR8$(LINE = "24")$CLR0"
if [[ $1 == "--" ]];then
shift
./"$repo_name/$script_path" "$@"||{
Err "Failed to execute script $script_name"
return 1
}
else
./"$repo_name/$script_path"||{
Err "Failed to execute script $script_name"
return 1
}
fi
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
[[ $delete_after == true ]]&&rm -rf "$repo_name"
fi
else
Txt "${CLR3}Downloading and executing script [${script_name}] from ${repo_owner}/${repo_name}${CLR0}"
github_url="https://raw.githubusercontent.com/$repo_owner/$repo_name/refs/heads/$branch/$script_path"
if [[ $branch != "main" ]];then
Task "* Checking $branch branch" "curl -sLf "$github_url" >/dev/null"
[ $? -ne 0 ]&&{
Err "Script not found in $branch branch"
return 1
}
else
Task "* Checking main branch" "curl -sLf "$github_url" >/dev/null" true
if [ $? -ne 0 ];then
Task "* Checking master branch" "
							branch="master"
							github_url="https://raw.githubusercontent.com/$repo_owner/$repo_name/refs/heads/master/$script_path"
							curl -sLf "$github_url" >/dev/null
						"
[ $? -ne 0 ]&&{
Err "Script not found in either main or master branch"
return 1
}
fi
fi
Task "* Downloading script" "
					curl -sSLf \"$github_url\" -o \"$script_name\" || { 
						Err \"Failed to download script $script_name\"
						Err \"Failed to download from: $github_url\"
						return 1
					}

					if [[ ! -f \"$script_name\" ]]; then
						Err \"Download failed: File not created\"
						return 1
					fi

					if [[ ! -s \"$script_name\" ]]; then
						Err \"Downloaded file is empty\"
						cat \"$script_name\" 2>/dev/null || echo \"(cannot display file content)\"
						return 1
					fi

					if ! grep -q '[^[:space:]]' \"$script_name\"; then
						Err \"Downloaded file contains only whitespace\"
						return 1
					fi

					chmod +x \"$script_name\" || { 
						Err \"Failed to set execute permission for $script_name\"
						Err \"Failed to set execute permission on $script_name\"
						ls -la \"$script_name\"
						return 1
					}
				"
Txt "$CLR8$(LINE = "24")$CLR0"
if [[ -f $script_name ]];then
if [[ $1 == "--" ]];then
shift
./"$script_name" "$@"||{
Err "Failed to execute script $script_name"
return 1
}
else
./"$script_name"||{
Err "Failed to execute script $script_name"
return 1
}
fi
else
Err "Script file '$script_name' was not downloaded successfully"
return 1
fi
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
[[ $delete_after == true ]]&&rm -rf "$script_name"
fi
else
[ -x "$1" ]||chmod +x "$1"
script_path="$1"
if [[ $2 == "--" ]];then
shift 2
"$script_path" "$@"||{
Err "Failed to execute script $script_name"
return 1
}
else
shift
"$script_path" "$@"||{
Err "Failed to execute script $script_name"
return 1
}
fi
fi
else
eval "$*"
fi
rm -rf /tmp/* &>/dev/null
}
function SHELL_VER(){
LC_ALL=C
if [ -n "${BASH_VERSION-}" ];then
Txt "Bash $BASH_VERSION"
elif [ -n "${ZSH_VERSION-}" ];then
Txt "Zsh $ZSH_VERSION"
else
{
Err "Unsupported shell"
return 1
}
fi
}
function SWAP_USAGE(){
used=$(free -b|awk '/^Swap:/ {printf "%.0f", $3}')
total=$(free -b|awk '/^Swap:/ {printf "%.0f", $2}')
percentage=$(free|awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
case "$1" in
-u)Txt "$used";;
-t)Txt "$total";;
-p)Txt "$percentage";;
*)Txt "$(CONVERT_SIZE "$used") / $(CONVERT_SIZE "$total") ($percentage%)"
esac
}
function SYS_CLEAN(){
CHECK_ROOT
Txt "${CLR3}Performing system cleanup...${CLR0}"
Txt "$CLR8$(LINE = "24")$CLR0"
case $(command -v apk apt opkg pacman yum zypper dnf|head -n1) in
*apk)Txt "* Cleaning APK cache"
apk cache clean||{
Err "Failed to clean APK cache"
return 1
}
Txt "* Removing temporary files"
rm -rf /tmp/* /var/cache/apk/*||{
Err "Failed to remove temporary files"
return 1
}
Txt "* Fixing APK packages"
apk fix||{
Err "Failed to fix APK packages"
return 1
}
;;
*apt)while
fuser /var/lib/dpkg/lock-frontend &>/dev/null
do
Txt "* Waiting for dpkg lock"
sleep 1||return 1
((wait_time++))
[ "$wait_time" -gt 300 ]&&{
Err "Timeout waiting for dpkg lock to be released"
return 1
}
done
Txt "* Configuring pending packages"
DEBIAN_FRONTEND=noninteractive dpkg --configure -a||{
Err "Failed to configure pending packages"
return 1
}
Txt "* Autoremoving packages"
apt autoremove --purge -y||{
Err "Failed to autoremove packages"
return 1
}
Txt "* Cleaning APT cache"
apt clean -y||{
Err "Failed to clean APT cache"
return 1
}
Txt "* Autocleaning APT cache"
apt autoclean -y||{
Err "Failed to autoclean APT cache"
return 1
}
;;
*opkg)Txt "* Removing temporary files"
rm -rf /tmp/*||{
Err "Failed to remove temporary files"
return 1
}
Txt "* Updating OPKG"
opkg update||{
Err "Failed to update OPKG"
return 1
}
Txt "* Cleaning OPKG cache"
opkg clean||{
Err "Failed to clean OPKG cache"
return 1
}
;;
*pacman)Txt "* Updating and upgrading packages"
pacman -Syu --noconfirm||{
Err "Failed to update and upgrade packages using pacman"
return 1
}
Txt "* Cleaning pacman cache"
pacman -Sc --noconfirm||{
Err "Failed to clean pacman cache"
return 1
}
Txt "* Cleaning all pacman cache"
pacman -Scc --noconfirm||{
Err "Failed to clean all pacman cache"
return 1
}
;;
*yum)Txt "* Autoremoving packages"
yum autoremove -y||{
Err "Failed to autoremove packages"
return 1
}
Txt "* Cleaning YUM cache"
yum clean all||{
Err "Failed to clean YUM cache"
return 1
}
Txt "* Making YUM cache"
yum makecache||{
Err "Failed to make YUM cache"
return 1
}
;;
*zypper)Txt "* Cleaning Zypper cache"
zypper clean --all||{
Err "Failed to clean Zypper cache"
return 1
}
Txt "* Refreshing Zypper repositories"
zypper refresh||{
Err "Failed to refresh Zypper repositories"
return 1
}
;;
*dnf)Txt "* Autoremoving packages"
dnf autoremove -y||{
Err "Failed to autoremove packages"
return 1
}
Txt "* Cleaning DNF cache"
dnf clean all||{
Err "Failed to clean DNF cache"
return 1
}
Txt "* Making DNF cache"
dnf makecache||{
Err "Failed to make DNF cache"
return 1
}
;;
*){
Err "Unsupported package manager. Skipping system-specific cleanup"
return 1
}
esac
if command -v journalctl &>/dev/null;then
Task "* Rotating and vacuuming journalctl logs" "journalctl --rotate --vacuum-time=1d --vacuum-size=500M"||{
Err "Failed to rotate and vacuum journalctl logs"
return 1
}
fi
Task "* Removing temporary files" "rm -rf /tmp/*"||{
Err "Failed to remove temporary files"
return 1
}
for cmd in docker npm pip;do
if command -v "$cmd" &>/dev/null;then
case "$cmd" in
docker)Task "* Cleaning Docker system" "docker system prune -af"||{
Err "Failed to clean Docker system"
return 1
};;
npm)Task "* Cleaning NPM cache" "npm cache clean --force"||{
Err "Failed to clean NPM cache"
return 1
};;
pip)Task "* Purging PIP cache" "pip cache purge"||{
Err "Failed to purge PIP cache"
return 1
}
esac
fi
done
Task "* Removing user cache files" "rm -rf ~/.cache/*"||{
Err "Failed to remove user cache files"
return 1
}
Task "* Removing thumbnail files" "rm -rf ~/.thumbnails/*"||{
Err "Failed to remove thumbnail files"
return 1
}
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
}
function SYS_INFO(){
Txt "${CLR3}System Information${CLR0}"
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "- Hostname:		$CLR2$(uname -n||{
Err "Failed to get hostname"
return 1
})$CLR0"
Txt "- Operating System:	$CLR2$(CHECK_OS)$CLR0"
Txt "- Kernel Version:	$CLR2$(uname -r)$CLR0"
Txt "- System Language:	$CLR2$LANG$CLR0"
Txt "- Shell Version:	$CLR2$(SHELL_VER)$CLR0"
Txt "- Last System Update:	$CLR2$(LAST_UPDATE)$CLR0"
Txt "$CLR8$(LINE - "32")$CLR0"
Txt "- Architecture:		$CLR2$(uname -m)$CLR0"
Txt "- CPU Model:		$CLR2$(CPU_MODEL)$CLR0"
Txt "- CPU Cores:		$CLR2$(nproc)$CLR0"
Txt "- CPU Frequency:	$CLR2$(CPU_FREQ)$CLR0"
Txt "- CPU Usage:		$CLR2$(CPU_USAGE)%$CLR0"
Txt "- CPU Cache:		$CLR2$(CPU_CACHE)$CLR0"
Txt "$CLR8$(LINE - "32")$CLR0"
Txt "- Memory Usage:		$CLR2$(MEM_USAGE)$CLR0"
Txt "- Swap Usage:		$CLR2$(SWAP_USAGE)$CLR0"
Txt "- Disk Usage:		$CLR2$(DISK_USAGE)$CLR0"
Txt "- File System Type:	$CLR2$(df -T /|awk 'NR==2 {print $2}')$CLR0"
Txt "$CLR8$(LINE - "32")$CLR0"
Txt "- IPv4 Address:		$CLR2$(IP_ADDR -4)$CLR0"
Txt "- IPv6 Address:		$CLR2$(IP_ADDR -6)$CLR0"
Txt "- MAC Address:		$CLR2$(MAC_ADDR)$CLR0"
Txt "- Network Provider:	$CLR2$(NET_PROVIDER)$CLR0"
Txt "- DNS Servers:		$CLR2$(DNS_ADDR)$CLR0"
Txt "- Public IP:		$CLR2$(PUBLIC_IP)$CLR0"
Txt "- Network Interface:	$CLR2$(INTERFACE -i)$CLR0"
Txt "- Internal Timezone:	$CLR2$(TIMEZONE -i)$CLR0"
Txt "- External Timezone:	$CLR2$(TIMEZONE -e)$CLR0"
Txt "$CLR8$(LINE - "32")$CLR0"
Txt "- Load Average:		$CLR2$(LOAD_AVERAGE)$CLR0"
Txt "- Process Count:	$CLR2$(ps aux|wc -l)$CLR0"
Txt "- Packages Installed:	$CLR2$(PKG_COUNT)$CLR0"
Txt "$CLR8$(LINE - "32")$CLR0"
Txt "- Uptime:		$CLR2$(uptime -p|sed 's/up //')$CLR0"
Txt "- Boot Time:		$CLR2$(who -b|awk '{print $3, $4}')$CLR0"
Txt "$CLR8$(LINE - "32")$CLR0"
Txt "- Virtualization:	$CLR2$(CHECK_VIRT)$CLR0"
Txt "$CLR8$(LINE = "24")$CLR0"
}
function SYS_OPTIMIZE(){
CHECK_ROOT
Txt "${CLR3}Optimizing system configuration for long-running servers...${CLR0}"
Txt "$CLR8$(LINE = "24")$CLR0"
SYSCTL_CONF="/etc/sysctl.d/99-server-optimizations.conf"
Txt "# Server optimizations for long-running systems" >"$SYSCTL_CONF"
Task "* Optimizing memory management" "
		Txt 'vm.swappiness = 1' >> $SYSCTL_CONF
		Txt 'vm.vfs_cache_pressure = 50' >> $SYSCTL_CONF
		Txt 'vm.dirty_ratio = 15' >> $SYSCTL_CONF
		Txt 'vm.dirty_background_ratio = 5' >> $SYSCTL_CONF
		Txt 'vm.min_free_kbytes = 65536' >> $SYSCTL_CONF
	"||{
Err "Failed to optimize memory management"
return 1
}
Task "* Optimizing network settings" "
		Txt 'net.core.somaxconn = 65535' >> $SYSCTL_CONF
		Txt 'net.core.netdev_max_backlog = 65535' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_max_syn_backlog = 65535' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_fin_timeout = 15' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_keepalive_time = 300' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_keepalive_probes = 5' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_keepalive_intvl = 15' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_tw_reuse = 1' >> $SYSCTL_CONF
		Txt 'net.ipv4.ip_local_port_range = 1024 65535' >> $SYSCTL_CONF
	"||{
Err "Failed to optimize network settings"
return 1
}
Task "* Optimizing TCP buffers" "
		Txt 'net.core.rmem_max = 16777216' >> $SYSCTL_CONF
		Txt 'net.core.wmem_max = 16777216' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> $SYSCTL_CONF
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> $SYSCTL_CONF
	"||{
Err "Failed to optimize TCP buffers"
return 1
}
Task "* Optimizing filesystem settings" "
		Txt 'fs.file-max = 2097152' >> $SYSCTL_CONF
		Txt 'fs.nr_open = 2097152' >> $SYSCTL_CONF
		Txt 'fs.inotify.max_user_watches = 524288' >> $SYSCTL_CONF
	"||{
Err "Failed to optimize filesystem settings"
return 1
}
Task "* Optimizing system limits" "
		Txt '* soft nofile 1048576' >> /etc/security/limits.conf
		Txt '* hard nofile 1048576' >> /etc/security/limits.conf
		Txt '* soft nproc 65535' >> /etc/security/limits.conf
		Txt '* hard nproc 65535' >> /etc/security/limits.conf
	"||{
Err "Failed to optimize system limits"
return 1
}
Task "* Optimizing I/O scheduler" "
		for disk in /sys/block/[sv]d*; do
			Txt 'none' > \$disk/queue/scheduler 2>/dev/null || true
			Txt '256' > \$disk/queue/nr_requests 2>/dev/null || true
		done
	"||{
Err "Failed to optimize I/O scheduler"
return 1
}
Task "* Disabling non-essential services" '
		for service in bluetooth cups avahi-daemon postfix nfs-server rpcbind autofs; do
			systemctl disable --now $service 2>/dev/null || true
		done
	'||{
Err "Failed to disable services"
return 1
}
Task "* Applying system parameters" "sysctl -p $SYSCTL_CONF"||{
Err "Failed to apply system parameters"
return 1
}
Task "* Clearing system cache" "
		sync
		Txt 3 > /proc/sys/vm/drop_caches
		ip -s -s neigh flush all
	"||{
Err "Failed to clear system cache"
return 1
}
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
}
function SYS_REBOOT(){
CHECK_ROOT
Txt "${CLR3}Preparing to reboot system...${CLR0}"
Txt "$CLR8$(LINE = "24")$CLR0"
active_users=$(who|wc -l)||{
Err "Failed to get active user count"
return 1
}
if [ "$active_users" -gt 1 ];then
Txt "${CLR1}Warning: There are currently $active_users active users on the system${CLR0}\n"
Txt "Active users:"
who|awk '{print $1 " since " $3 " " $4}'
Txt
fi
important_processes=$(ps aux --no-headers|awk '$3 > 1.0 || $4 > 1.0'|wc -l)||{
Err "Failed to check running processes"
return 1
}
if [ "$important_processes" -gt 0 ];then
Txt "${CLR1}Warning: There are $important_processes important processes running${CLR0}\n"
Txt "${CLR8}Top 5 processes by CPU usage:${CLR0}"
ps aux --sort=-%cpu|head -n 6
Txt
fi
read -p "Are you sure you want to reboot the system now? (y/N) " -n 1 -r
Txt
[[ ! $REPLY =~ ^[Yy]$ ]]&&{
Txt "${CLR2}Reboot cancelled${CLR0}\n"
return 0
}
Task "* Performing final checks" "sync"||{
Err "Failed to sync filesystems"
return 1
}
Task "* Initiating reboot" "reboot || sudo reboot"||{
Err "Failed to initiate reboot"
return 1
}
Txt "${CLR2}Reboot command issued successfully. The system will reboot momentarily${CLR0}"
}
function SYS_UPDATE(){
CHECK_ROOT
Txt "${CLR3}Updating system software...${CLR0}"
Txt "$CLR8$(LINE = "24")$CLR0"
update_pkgs(){
cmd="$1"
update_cmd="$2"
upgrade_cmd="$3"
Txt "* Updating package lists"
$update_cmd||{
Err "Failed to update package lists using $cmd"
return 1
}
Txt "* Upgrading packages"
$upgrade_cmd||{
Err "Failed to upgrade packages using $cmd"
return 1
}
}
case $(command -v apk apt opkg pacman yum zypper dnf|head -n1) in
*apk)update_pkgs "apk" "apk update" "apk upgrade";;
*apt)while
fuser /var/lib/dpkg/lock-frontend &>/dev/null
do
Task "* Waiting for dpkg lock" "sleep 1"||return 1
((wait_time++))
[ "$wait_time" -gt 10 ]&&{
Err "Timeout waiting for dpkg lock to be released"
return 1
}
done
Task "* Configuring pending packages" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a"||{
Err "Failed to configure pending packages"
return 1
}
update_pkgs "apt" "apt update -y" "apt full-upgrade -y"
;;
*opkg)update_pkgs "opkg" "opkg update" "opkg upgrade";;
*pacman)Task "* Updating and upgrading packages" "pacman -Syu --noconfirm"||{
Err "Failed to update and upgrade packages using pacman"
return 1
};;
*yum)update_pkgs "yum" "yum check-update" "yum -y update";;
*zypper)update_pkgs "zypper" "zypper refresh" "zypper update -y";;
*dnf)update_pkgs "dnf" "dnf check-update" "dnf -y update";;
*){
Err "Unsupported package manager"
return 1
}
esac
Txt "* Updating $Scripts"
bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/get_utilkit.sh)||{
Err "Failed to update $Scripts"
return 1
}
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
}
function SYS_UPGRADE(){
CHECK_ROOT
Txt "${CLR3}Upgrading system to next major version...${CLR0}"
Txt "$CLR8$(LINE = "24")$CLR0"
os_name=$(CHECK_OS -n)
case "$os_name" in
Debian)Txt "* Detected 'Debian' system"
Txt "* Updating package lists"
apt update -y||{
Err "Failed to update package lists using apt"
return 1
}
Txt "* Upgrading current packages"
apt full-upgrade -y||{
Err "Failed to upgrade current packages"
return 1
}
Txt "* Starting 'Debian' release upgrade..."
current_codename=$(lsb_release -cs)
target_codename=$(curl -s http://ftp.debian.org/debian/dists/stable/Release|grep "^Codename:"|awk '{print $2}')
[ "$current_codename" = "$target_codename" ]&&{
Err "System is already running the latest stable version ($target_codename)"
return 1
}
Txt "* Upgrading from ${CLR2}${current_codename}${CLR0} to ${CLR3}${target_codename}${CLR0}"
Task "* Backing up sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup"||{
Err "Failed to backup sources.list"
return 1
}
Task "* Updating sources.list" "sed -i 's/$current_codename/$target_codename/g' /etc/apt/sources.list"||{
Err "Failed to update sources.list"
return 1
}
Task "* Updating package lists for new release" "apt update -y"||{
Err "Failed to update package lists for new release"
return 1
}
Task "* Upgrading to new Debian release" "apt full-upgrade -y"||{
Err "Failed to upgrade to new Debian release"
return 1
}
;;
Ubuntu)Txt "* Detected 'Ubuntu' system"
Task "* Updating package lists" "apt update -y"||{
Err "Failed to update package lists using apt"
return 1
}
Task "* Upgrading current packages" "apt full-upgrade -y"||{
Err "Failed to upgrade current packages"
return 1
}
Task "* Installing update-manager-core" "apt install -y update-manager-core"||{
Err "Failed to install update-manager-core"
return 1
}
Task "* Upgrading Ubuntu release" "do-release-upgrade -f DistUpgradeViewNonInteractive"||{
Err "Failed to upgrade Ubuntu release"
return 1
}
SYS_REBOOT
;;
*){
Err "Your system is not yet supported for major version upgrades"
return 1
}
esac
Txt "$CLR8$(LINE = "24")$CLR0"
Txt "${CLR2}System upgrade completed${CLR0}\n"
}
function Task(){
message="$1"
command="$2"
ignore_Err=${3:-false}
temp_file=$(mktemp)
echo -ne "$message... "
if eval "$command" >"$temp_file" 2>&1;then
Txt "${CLR2}Done${CLR0}"
ret=0
else
ret=$?
Txt "${CLR1}Failed${CLR0} ($ret)"
[[ -s $temp_file ]]&&Txt "$CLR1$(cat "$temp_file")$CLR0"
[[ $ignore_Err != "true" ]]&&return $ret
fi
Del -f "$temp_file"
return $ret
}
function TIMEZONE(){
case "$1" in
-e)result=$(timeout 1s curl -sL ipapi.co/timezone)||result=$(timeout 1s curl -sL worldtimeapi.org/api/ip|grep -oP '"timezone":"\K[^"]+')||result=$(timeout 1s curl -sL ip-api.com/json|grep -oP '"timezone":"\K[^"]+')||[ -n "$result" ]&&Txt "$result"||{
Err "Failed to detect timezone from external services"
return 1
}
;;
-i|*)result=$(readlink /etc/localtime|sed 's|^.*/zoneinfo/||') 2>/dev/null||result=$(command -v timedatectl &>/dev/null&&timedatectl status|awk '/Time zone:/ {print $3}')||result=$(cat /etc/timezone 2>/dev/null|uniq)||[ -n "$result" ]&&Txt "$result"||{
Err "Failed to detect system timezone"
return 1
}
esac
}
