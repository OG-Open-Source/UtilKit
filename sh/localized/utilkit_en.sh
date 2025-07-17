#!/bin/bash
AUTHORS="OG-Open-Source"
SCRIPTS="UtilKit.sh"
VERSION="6.044.001.263"
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
Txt(){ echo -e "$1" "$2";}
Err(){
[ -z "$1" ]&&{
Txt "${CLR1}Unknown error${CLR0}"
return 1
}
Txt "$CLR1$1$CLR0"
if [ -w "/var/log" ];then
logFile="/var/log/utilkit.sh.log"
timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
logEntry="$timestamp | $SCRIPTS - $VERSION - $(Txt "$1"|tr -d '\n')"
Txt "$logEntry" >>"$logFile" 2>/dev/null
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
mode="package"
failed=0
while [ $# -gt 0 ];do
case "$1" in
-f)mode="file"
shift
continue
;;
-d)mode="directory"
shift
continue
;;
*.deb)?Root
debFile=$(basename "$1")
Txt "${CLR3}INSERT DEB PACKAGE [$debFile]${CLR0}\n"
Get "$1"
if [ -f "$debFile" ];then
dpkg -i "$debFile"||{
Err "Failed to install $debFile. Check package compatibility and dependencies\n"
Del -f "$debFile"
failed=1
shift
continue
}
apt --fix-broken install -y||{
Err "Failed to fix dependencies"
Del -f "$debFile"
failed=1
shift
continue
}
Txt "* DEB package $debFile installed successfully"
Del -f "$debFile"
Txt "${CLR2}FINISHED${CLR0}\n"
else
Err "DEB package $debFile not found or download failed\n"
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
"directory")Txt "${CLR3}INSERT DIRECTORY [$1]${CLR0}"
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
"package")Txt "${CLR3}INSERT PACKAGE [$1]${CLR0}"
?Root
packageManager=$(command -v apk apt opkg pacman yum zypper dnf|head -n1)
packageManager=${packageManager##*/}
case $packageManager in
apk|apt|opkg|pacman|yum|zypper|dnf)?Installed(){
case $packageManager in
apk)apk info -e "$1" &>/dev/null;;
apt)dpkg-query -W -f='${Status}' "$1" 2>/dev/null|grep -q "ok installed";;
opkg)opkg list-installed|grep -q "^$1 ";;
pacman)pacman -Qi "$1" &>/dev/null;;
yum|dnf)$packageManager list installed "$1" &>/dev/null;;
zypper)zypper se -i -x "$1" &>/dev/null
esac
}
InstallPkg(){
case $packageManager in
apk)apk update&&apk add "$1";;
apt)apt install -y "$1";;
opkg)opkg update&&opkg install "$1";;
pacman)pacman -Sy&&pacman -S --noconfirm "$1";;
yum|dnf)$packageManager install -y "$1";;
zypper)zypper refresh&&zypper install -y "$1"
esac
}
if ! ?Installed "$1";then
Txt "* Package $1 is not installed"
if InstallPkg "$1";then
if ?Installed "$1";then
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
function Ask(){
read -e -p "$1" -r $2||{
Err "Failed to read user input"
return 1
}
}
function Check.Deps(){
mode="display"
missingDependencies=()
while [[ $1 == -* ]];do
case "$1" in
-i)mode="interactive";;
-a)mode="auto";;
*)Err "Invalid option: $1"
return 1
esac
shift
done
for dependency in "${deps[@]}";do
if command -v "$dependency" &>/dev/null;then
status="${CLR2}[Available]${CLR0}"
else
status="${CLR1}[Not Found]${CLR0}"
missingDependencies+=("$dependency")
fi
Txt "$status\t$dependency"
done
[[ ${#missingDependencies[@]} -eq 0 ]]&&return 0
case "$mode" in
"interactive")Txt "\n${CLR3}Missing packages:${CLR0} ${missingDependencies[*]}"
Press "Do you want to install the missing packages? (y/N) "
Txt "\n"
[[ $REPLY =~ ^[Yy] ]]&&Add "${missingDependencies[@]}"
;;
"auto")Txt
Add "${missingDependencies[@]}"
esac
}
function Check.Os(){
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
function ?Root(){
if [ "$EUID" -ne 0 ]||[ "$(id -u)" -ne 0 ];then
Err "Please run this script as root user"
exit 1
fi
}
function Check.Virt(){
if command -v systemd-detect-virt >/dev/null 2>&1;then
virtualizationType=$(systemd-detect-virt 2>/dev/null)
[ -z "$virtualizationType" ]&&{
Err "Unable to detect virtualization environment"
return 1
}
case "$virtualizationType" in
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
*)Txt "${virtualizationType:-Not detected (possibly bare metal)}"
esac
elif [ -f /proc/cpuinfo ];then
virtualizationType=$(grep -i "hypervisor" /proc/cpuinfo >/dev/null&&Txt "VM"||Txt "None")
else
virtualizationType="Unknown"
fi
}
function Clean(){
targetDirectory="${1:-$HOME}"
cd "$targetDirectory"||{
Err "Failed to change directory"
return 1
}
clear
}
function Cpu.Cache(){
[ ! -f /proc/cpuinfo ]&&{
Err "Cannot access CPU information. /proc/cpuinfo not available"
return 1
}
centralProcessingUnitCache=$(awk '/^cache size/ {sum+=$4; count++} END {print (count>0) ? sum/count : "N/A"}' /proc/cpuinfo)
[ "$centralProcessingUnitCache" = "N/A" ]&&{
Err "Unable to determine CPU cache size"
return 1
}
Txt "$centralProcessingUnitCache KB"
}
function Cpu.Freq(){
[ ! -f /proc/cpuinfo ]&&{
Err "Cannot access CPU information. /proc/cpuinfo not available"
return 1
}
centralProcessingUnitFreq=$(awk '/^cpu MHz/ {sum+=$4; count++} END {print (count>0) ? sprintf("%.2f", sum/count/1000) : "N/A"}' /proc/cpuinfo)
[ "$centralProcessingUnitFreq" = "N/A" ]&&{
Err "Unable to determine CPU frequency"
return 1
}
Txt "$centralProcessingUnitFreq GHz"
}
function Cpu.Model(){
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
function Cpu.Usage(){
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
totalDifference=$((total2-total1))
idleDifference=$((idle2-idle1))
usage=$((100*(totalDifference-idleDifference)/totalDifference))
Txt "$usage"
}
function ConvSize(){
[ -z "$1" ]&&{
Err "No size value provided for conversion"
return 2
}
size=$1
unit=${2:-iB}
unitLower=$(Format -aa "$unit")
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
case "$unitLower" in
b)bytes=$size;;
kb|kib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unitLower" 'BEGIN {printf "%.0f", size * (unit == "kb" ? 1000 : 1024)}');;
mb|mib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unitLower" 'BEGIN {printf "%.0f", size * (unit == "mb" ? 1000000 : 1048576)}');;
gb|gib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unitLower" 'BEGIN {printf "%.0f", size * (unit == "gb" ? 1000000000 : 1073741824)}');;
tb|tib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unitLower" 'BEGIN {printf "%.0f", size * (unit == "tb" ? 1000000000000 : 1099511627776)}');;
pb|pib)bytes=$(LC_NUMERIC=C awk -v size="$size" -v unit="$unitLower" 'BEGIN {printf "%.0f", size * (unit == "pb" ? 1000000000000000 : 1125899906842624)}');;
*)bytes=$size
esac
[[ ! $bytes =~ ^[0-9]+\.?[0-9]*$ ]]&&{
Err "Failed to convert size value"
return 1
}
LC_NUMERIC=C awk -v bytes="$bytes" -v is_binary="$([[ $unitLower =~ ^.*ib$ ]]&&Txt 1||Txt 0)" '
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
function Copyright(){
Txt "$SCRIPTS $VERSION"
Txt "Copyright (c) $(date +%Y) $AUTHORS."
}
function Del(){
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
mode="package"
failed=0
while [ $# -gt 0 ];do
case "$1" in
-f)mode="file"
shift
continue
;;
-d)mode="directory"
shift
continue
;;
*)Txt "${CLR3}REMOVE $(Format -AA "$mode") [$1]$CLR0"
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
"directory")[ ! -d "$1" ]&&{
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
"package")?Root
packageManager=$(command -v apk apt opkg pacman yum zypper dnf|head -n1)
packageManager=${packageManager##*/}
case $packageManager in
apk|apt|opkg|pacman|yum|zypper|dnf)?Installed(){
case $packageManager in
apk)apk info -e "$1" &>/dev/null;;
apt)dpkg-query -W -f='${Status}' "$1" 2>/dev/null|grep -q "ok installed";;
opkg)opkg list-installed|grep -q "^$1 ";;
pacman)pacman -Qi "$1" &>/dev/null;;
yum|dnf)$packageManager list installed "$1" &>/dev/null;;
zypper)zypper se -i -x "$1" &>/dev/null
esac
}
RmPkg(){
case $packageManager in
apk)apk del "$1";;
apt)apt purge -y "$1"&&apt autoremove -y;;
opkg)opkg remove "$1";;
pacman)pacman -Rns --noconfirm "$1";;
yum|dnf)$packageManager remove -y "$1";;
zypper)zypper remove -y "$1"
esac
}
if ! ?Installed "$1";then
Err "* Package $1 is not installed\n"
failed=1
shift
continue
fi
Txt "* Package $1 is installed"
if ! RmPkg "$1";then
Err "Failed to remove $1 using $pkg_manager\n"
failed=1
shift
continue
fi
if ?Installed "$1";then
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
function Disk.Usage(){
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
*)Txt "$(ConvSize "$used") / $(ConvSize "$total") ($percentage%)"
esac
}
function Net.Dns.Addr(){
[ ! -f /etc/resolv.conf ]&&{
Err "DNS configuration file /etc/resolv.conf not found"
return 1
}
internetProtocolVserion4Servers=()
internetProtocolVserion6Servers=()
while read -r server;do
if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]];then
internetProtocolVserion4Servers+=("$server")
elif [[ $server =~ ^[0-9a-fA-F:]+$ ]];then
internetProtocolVserion6Servers+=("$server")
fi
done < <(grep -E '^nameserver' /etc/resolv.conf|awk '{print $2}')
[[ ${#internetProtocolVserion4Servers[@]} -eq 0 && ${#internetProtocolVserion6Servers[@]} -eq 0 ]]&&{
Err "No DNS servers configured in /etc/resolv.conf"
return 1
}
case "$1" in
-4)[ ${#internetProtocolVserion4Servers[@]} -eq 0 ]&&{
Err "No IPv4 DNS servers found"
return 1
}
Txt "${internetProtocolVserion4Servers[*]}"
;;
-6)[ ${#internetProtocolVserion6Servers[@]} -eq 0 ]&&{
Err "No IPv6 DNS servers found"
return 1
}
Txt "${internetProtocolVserion6Servers[*]}"
;;
*)[ ${#internetProtocolVserion4Servers[@]} -eq 0 -a ${#internetProtocolVserion6Servers[@]} -eq 0 ]&&{
Err "No DNS servers found"
return 1
}
Txt "${internetProtocolVserion4Servers[*]}   ${internetProtocolVserion6Servers[*]}"
esac
}
function Find(){
[ $# -eq 0 ]&&{
Err "No search terms provided. Please specify what to search for"
return 2
}
packageManager=$(command -v apk apt opkg pacman yum zypper dnf|head -n1)
case ${packageManager##*/} in
apk)searchCommand="apk search";;
apt)searchCommand="apt-cache search";;
opkg)searchCommand="opkg search";;
pacman)searchCommand="pacman -Ss";;
yum)searchCommand="yum search";;
zypper)searchCommand="zypper search";;
dnf)searchCommand="dnf search";;
*){
Err "Package manager not found or unsupported"
return 1
}
esac
for target in "$@";do
Txt "${CLR3}SEARCH [$target]${CLR0}"
$searchCommand "$target"||{
Err "No results found for $target\n"
return 1
}
Txt "${CLR2}FINISHED${CLR0}\n"
done
}
function Font(){
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
function Format(){
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
targetDirectory="."
renameFile=""
uniformResourceLocator=""
while [ $# -gt 0 ];do
case "$1" in
-x)extract=true
shift
;;
-r)[ -z "$2" ]||[[ $2 == -* ]]&&{
Err "No filename specified after -r option"
return 2
}
renameFile="$2"
shift 2
;;
-*){
Err "Invalid option: $1"
return 2
};;
*)[ -z "$uniformResourceLocator" ]&&uniformResourceLocator="$1"||targetDirectory="$1"
shift
esac
done
[ -z "$uniformResourceLocator" ]&&{
Err "No URL specified. Please provide a URL to download"
return 2
}
[[ $uniformResourceLocator =~ ^(http|https|ftp):// ]]||uniformResourceLocator="https://$uniformResourceLocator"
outputFile="${uniformResourceLocator##*/}"
[ -z "$outputFile" ]&&outputFile="index.html"
[ "$targetDirectory" != "." ]&&{ mkdir -p "$targetDirectory"||{
Err "Failed to create directory $targetDirectory"
return 1
};}
[ -n "$renameFile" ]&&outputFile="$renameFile"
outputPath="$targetDirectory/$outputFile"
uniformResourceLocator=$(echo "$uniformResourceLocator"|sed -E 's#([^:])/+#\1/#g; s#^(https?|ftp):/+#\1://#')
Txt "${CLR3}DOWNLOAD [$uniformResourceLocator]${CLR0}"
fileSize=$(curl -sI "$uniformResourceLocator"|grep -i content-length|awk '{print $2}'|tr -d '\r')
sizeLimit="26214400"
if [ -n "$fileSize" ]&&[ "$fileSize" -gt "$sizeLimit" ];then
wget --no-check-certificate --timeout=5 --tries=2 "$uniformResourceLocator" -O "$outputPath"||{
Err "Failed to download file using Wget"
return 1
}
else
curl --location --insecure --connect-timeout 5 --retry 2 "$uniformResourceLocator" -o "$outputPath"||{
Err "Failed to download file using cUrl"
return 1
}
fi
if [ -f "$outputPath" ];then
Txt "* File downloaded successfully to $outputPath"
if [ "$extract" = true ];then
case "$outputFile" in
*.tar.gz|*.tgz)tar -xzf "$outputPath" -C "$targetDirectory"||{
Err "Failed to extract tar.gz file"
return 1
};;
*.tar)tar -xf "$outputPath" -C "$targetDirectory"||{
Err "Failed to extract tar file"
return 1
};;
*.tar.bz2|*.tbz2)tar -xjf "$outputPath" -C "$targetDirectory"||{
Err "Failed to extract tar.bz2 file"
return 1
};;
*.tar.xz|*.txz)tar -xJf "$outputPath" -C "$targetDirectory"||{
Err "Failed to extract tar.xz file"
return 1
};;
*.zip)unzip "$outputPath" -d "$targetDirectory"||{
Err "Failed to extract zip file"
return 1
};;
*.7z)7z x "$outputPath" -o"$targetDirectory"||{
Err "Failed to extract 7z file"
return 1
};;
*.rar)unrar x "$outputPath" "$targetDirectory"||{
Err "Failed to extract rar file"
return 1
};;
*.zst)zstd -d "$outputPath" -o "$targetDirectory"||{
Err "Failed to extract zst file"
return 1
};;
*)Txt "* File format not recognized for auto-extraction"
esac
[ $? -eq 0 ]&&Txt "* File extracted successfully to $targetDirectory"
fi
Txt "${CLR2}FINISHED${CLR0}\n"
else
{
Err "Download failed. Check your internet connection and URL validity"
return 1
}
fi
}
function Net.Interface(){
interface=""
declare -a interfaces=()
allInterfaces=$(cat /proc/net/dev|grep ':'|cut -d':' -f1|sed 's/\s//g'|grep -iv '^lo\|^sit\|^stf\|^gif\|^dummy\|^vmnet\|^vir\|^gre\|^ipip\|^ppp\|^bond\|^tun\|^tap\|^ip6gre\|^ip6tnl\|^teql\|^ocserv\|^vpn\|^warp\|^wgcf\|^wg\|^docker\|^br-\|^veth'|sort -n)||{
Err "Failed to get network interfaces from /proc/net/dev"
return 1
}
i=1
while read -r interfaceItem;do
[ -n "$interfaceItem" ]&&interfaces[$i]="$interfaceItem"
((i++))
done <<<"$allInterfaces"
interfacesNumber="${#interfaces[*]}"
default4Route=$(ip -4 route show default 2>/dev/null|grep -A 3 "^default"||Txt)
default6Route=$(ip -6 route show default 2>/dev/null|grep -A 3 "^default"||Txt)
interface4=""
interface6=""
for ((i=1; i<=${#interfaces[@]}; i++));do
item="${interfaces[$i]}"
[ -z "$item" ]&&continue
if [[ -n $default4Route && $default4Route == *"$item"* ]]&&[ -z "$interface4" ];then
interface4="$item"
fi
if [[ -n $default6Route && $default6Route == *"$item"* ]]&&[ -z "$interface6" ];then
interface6="$item"
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
if [ -z "$interface4" ]&&[ -z "$interface6" ]&&[ "$interfacesNumber" -gt 0 ];then
interface4="${interfaces[1]}"
interface6="${interfaces[1]}"
fi
fi
if [ -n "$interface4" ]||[ -n "$interface6" ];then
interface="$interface4 $interface6"
[[ $interface4 == "$interface6" ]]&&interface="$interface4"
interface=$(Txt "$interface"|tr -s ' '|xargs)
else
physicalInterface=$(ip -o link show|grep -v 'lo\|docker\|br-\|veth\|bond\|tun\|tap'|grep 'state UP'|head -n 1|awk -F': ' '{print $2}')
if [ -n "$physicalInterface" ];then
interface="$physicalInterface"
else
interface=$(ip -o link show|grep -v 'lo:'|head -n 1|awk -F': ' '{print $2}')
fi
fi
case "$1" in
rx_bytes|rx_packets|rx_drop|tx_bytes|tx_packets|tx_drop)for iface in $interface
do
if stats=$(awk -v iface="$iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null);then
read receivedBytes receivedPackets receivedDrop transmittedBytes transmittedPackets transmittedDrop <<<"$stats"
case "$1" in
rx_bytes)Txt "$receivedBytes"
break
;;
rx_packets)Txt "$receivedPackets"
break
;;
rx_drop)Txt "$receivedDrop"
break
;;
tx_bytes)Txt "$transmittedBytes"
break
;;
tx_packets)Txt "$transmittedPackets"
break
;;
tx_drop)Txt "$transmittedDrop"
break
esac
fi
done
;;
-i)for iface in $interface
do
if stats=$(awk -v iface="$iface" '$1 ~ iface":" {print $2, $3, $5, $10, $11, $13}' /proc/net/dev 2>/dev/null);then
read receivedBytes receivedPackets receivedDrop transmittedBytes transmittedPackets transmittedDrop <<<"$stats"
Txt "$iface: RX: $(ConvSize $receivedBytes), TX: $(ConvSize $transmittedBytes)"
fi
done
;;
"")Txt "$interface";;
*)Err "Invalid parameter: $1. Valid parameters are: rx_bytes, rx_packets, rx_drop, tx_bytes, tx_packets, tx_drop, -i"
return 2
esac
}
function Net.Ip.Addr(){
version="$1"
case "$version" in
-4)internetProtocolVserion4Address=$(timeout 1s dig +short -4 myip.opendns.com @resolver1.opendns.com 2>/dev/null)||internetProtocolVserion4Address=$(timeout 1s curl -sL ipv4.ip.sb 2>/dev/null)||internetProtocolVserion4Address=$(timeout 1s wget -qO- -4 ifconfig.me 2>/dev/null)||[ -n "$internetProtocolVserion4Address" ]&&Txt "$internetProtocolVserion4Address"||{
Err "Failed to retrieve IPv4 address. Check your internet connection"
return 1
}
;;
-6)internetProtocolVserion6Address=$(timeout 1s curl -sL ipv6.ip.sb 2>/dev/null)||internetProtocolVserion6Address=$(timeout 1s wget -qO- -6 ifconfig.me 2>/dev/null)||[ -n "$internetProtocolVserion6Address" ]&&Txt "$internetProtocolVserion6Address"||{
Err "Failed to retrieve IPv6 address. Check your internet connection"
return 1
}
;;
*)internetProtocolVserion4Address=$(Net.Ip.Addr -4)
internetProtocolVserion6Address=$(Net.Ip.Addr -6)
[ -z "$internetProtocolVserion4Address$internetProtocolVserion6Address" ]&&{
Err "Failed to retrieve IP addresses"
return 1
}
[ -n "$internetProtocolVserion4Address" ]&&Txt "IPv4: $internetProtocolVserion4Address"
[ -n "$internetProtocolVserion6Address" ]&&Txt "IPv6: $internetProtocolVserion6Address"
return
esac
}
function LastUpdate(){
if [ -f /var/log/apt/history.log ];then
lastUpdate=$(awk '/End-Date:/ {print $2, $3, $4; exit}' /var/log/apt/history.log 2>/dev/null)
elif [ -f /var/log/dpkg.log ];then
lastUpdate=$(tail -n 1 /var/log/dpkg.log|awk '{print $1, $2}')
elif command -v rpm &>/dev/null;then
lastUpdate=$(rpm -qa --last|head -n 1|awk '{print $3, $4, $5, $6, $7}')
fi
[ -z "$lastUpdate" ]&&{
Err "Unable to determine last system update time. Update logs not found"
return 1
}||Txt "$lastUpdate"
}
function Linet(){
character="${1:--}"
length="${2:-80}"
printf '%*s\n' "$length"|tr ' ' "$character"||{
Err "Failed to print line"
return 1
}
}
function LoadAverage(){
if [ ! -f /proc/loadavg ];then
loadData=$(uptime|sed 's/.*load average: //'|sed 's/,//g')||{
Err "Failed to get load average from uptime command"
return 1
}
read -r ZoMin ZfMin OfMin <<<"$loadData"
else
read -r ZoMin ZfMin OfMin _ _ </proc/loadavg||{
Err "Failed to read load average from /proc/loadavg"
return 1
}
fi
[[ $ZoMin =~ ^[0-9.]+$ ]]||ZoMin=0
[[ $ZfMin =~ ^[0-9.]+$ ]]||ZfMin=0
[[ $OfMin =~ ^[0-9.]+$ ]]||OfMin=0
LC_ALL=C printf "%.2f, %.2f, %.2f (%d cores)" "$ZoMin" "$ZfMin" "$OfMin" "$(nproc)"
}
function Net.Location(){
location=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace"|grep "^loc="|cut -d= -f2)
[ -n "$location" ]&&Txt "$location"||{
Err "Unable to detect location. Check your internet connection"
return 1
}
}
function Net.Mac.Addr(){
macAddress=$(ip link show|awk '/ether/ {print $2; exit}')
[[ -n $macAddress ]]&&Txt "$macAddress"||{
Err "Unable to retrieve MAC address. Network interface not found"
return 1
}
}
function Mem.Usage(){
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
*)Txt "$(ConvSize "$used") / $(ConvSize "$total") ($percentage%)"
esac
}
function Net.Provider(){
result=$(timeout 1s curl -sL ipinfo.io|grep -oP '"org"\s*:\s*"\K[^"]+')||result=$(timeout 1s curl -sL ipwhois.app/json|grep -oP '"org"\s*:\s*"\K[^"]+')||result=$(timeout 1s curl -sL ip-api.com/json|grep -oP '"org"\s*:\s*"\K[^"]+')||[ -n "$result" ]&&Txt "$result"||{
Err "Unable to detect network provider. Check your internet connection"
return 1
}
}
function Pkg.Count(){
packageManager=$(command -v apk apt opkg pacman yum zypper dnf 2>/dev/null|head -n1)
case ${packageManager##*/} in
apk)countCommand="apk info";;
apt)countCommand="dpkg --get-selections";;
opkg)countCommand="opkg list-installed";;
pacman)countCommand="pacman -Q";;
yum|dnf)countCommand="rpm -qa";;
zypper)countCommand="zypper se --installed-only";;
*){
Err "Unable to count installed packages. Package manager not supported"
return 1
}
esac
if ! packageCount=$($countCommand 2>/dev/null|wc -l)||[[ -z $packageCount || $packageCount -eq 0 ]];then
{
Err "Failed to count packages for ${packageManager##*/}"
return 1
}
fi
Txt "$packageCount"
}
function Progress(){
numberCommands=${#commands[@]}
terminalWidth=$(tput cols)||{
Err "Failed to get terminal width"
return 1
}
barWidth=$((terminalWidth-23))
stty -echo
trap '' SIGINT SIGQUIT SIGTSTP
for ((i=0; i<numberCommands; i++));do
progress=$((i*100/numberCommands))
filledWidth=$((progress*barWidth/100))
printf "\r\033[30;42mProgress: [%3d%%]\033[0m [%s%s]" "$progress" "$(printf "%${filledWidth}s"|tr ' ' '#')" "$(printf "%$((barWidth-filledWidth))s"|tr ' ' '.')"
if ! output=$(eval "${commands[$i]}" 2>&1);then
Txt "\n$output"
stty echo
trap - SIGINT SIGQUIT SIGTSTP
{
Err "Command execution failed: ${commands[$i]}"
return 1
}
fi
done
printf "\r\033[30;42mProgress: [100%%]\033[0m [%s]" "$(printf "%${barWidth}s"|tr ' ' '#')"
printf "\r%${terminalWidth}s\r"
stty echo
trap - SIGINT SIGQUIT SIGTSTP
}
function Net.PublicIp(){
internetProtocol=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace"|grep "^ip="|cut -d= -f2)
[ -n "$internetProtocol" ]&&Txt "$internetProtocol"||{
Err "Unable to detect public IP address. Check your internet connection"
return 1
}
}
function Run(){
commands=()
runCompletions(){
currentWord="${COMP_WORDS[COMP_CWORD]}"
previousWord="${COMP_WORDS[COMP_CWORD-1]}"
completionOptions="${commands[*]}"
COMPREPLY=($(compgen -W "$completionOptions" -- "$currentWord"))
[[ ${#COMPREPLY[@]} -eq 0 ]]&&COMPREPLY=($(compgen -c -- "$currentWord"))
}
complete -F runCompletions RUN
[ $# -eq 0 ]&&{
Err "No command specified"
return 2
}
if [[ $1 == *"/"* ]];then
if [[ $1 =~ ^https?:// ]];then
uniformResourceLocator="$1"
scriptName=$(basename "$1")
deleteAfter=false
shift
while [[ $# -gt 0 && $1 == -* ]];do
case "$1" in
-d)deleteAfter=true
shift
;;
*)break
esac
done
Txt "${CLR3}Downloading and executing script [${scriptName}] from URL${CLR0}"
Task "* Downloading script" "
				curl -sSLf "$uniformResourceLocator" -o "$scriptName" || { Err "Failed to download script $scriptName"; return 1; }
				chmod +x "$scriptName" || { Err "Failed to set execute permission for $scriptName"; return 1; }
			"
Txt "$CLR8$(Linet = "24")$CLR0"
if [[ $1 == "--" ]];then
shift
./"$scriptName" "$@"||{
Err "Failed to execute script $scriptName"
return 1
}
else
./"$scriptName"||{
Err "Failed to execute script $scriptName"
return 1
}
fi
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
[[ $deleteAfter == true ]]&&rm -rf "$scriptName"
elif [[ $1 =~ ^[^/]+/[^/]+/.+ ]];then
repositoryOwner=$(Txt "$1"|cut -d'/' -f1)
repositoryName=$(Txt "$1"|cut -d'/' -f2)
scriptPath=$(Txt "$1"|cut -d'/' -f3-)
scriptName=$(basename "$scriptPath")
downloadRepository=false
repositoryBranch="main"
deleteAfter=false
shift
while [[ $# -gt 0 && $1 == -* ]];do
case "$1" in
-b)[[ -z $2 || $2 == -* ]]&&{
Err "Branch name required after -b"
return 2
}
repositoryBranch="$2"
shift 2
;;
-r)downloadRepository=true
shift
;;
-d)deleteAfter=true
shift
;;
*)break
esac
done
if [[ $downloadRepository == true ]];then
Txt "${CLR3}Cloning repository ${repositoryOwner}/${repositoryName}${CLR0}"
[[ -d $repositoryName ]]&&{
Err "Directory $repositoryName already exists"
return 1
}
temporaryDirectory=$(mktemp -d)
if [[ $repositoryBranch != "main" ]];then
Task "* Cloning from repositoryBranch $repositoryBranch" "git clone --branch $repositoryBranch https://github.com/$repositoryOwner/$repositoryName.git "$temporaryDirectory""
if [ $? -ne 0 ];then
rm -rf "$temporaryDirectory"
{
Err "Failed to clone repository from $repositoryBranch repositoryBranch"
return 1
}
fi
else
Task "* Checking main repositoryBranch" "git clone --branch main https://github.com/$repositoryOwner/$repositoryName.git "$temporaryDirectory"" true
if [ $? -ne 0 ];then
Task "* Trying master repositoryBranch" "git clone --branch master https://github.com/$repositoryOwner/$repositoryName.git "$temporaryDirectory""
if [ $? -ne 0 ];then
rm -rf "$temporaryDirectory"
{
Err "Failed to clone repository from either main or master repositoryBranch"
return 1
}
fi
fi
fi
Task "* Creating target directory" "Add -d "$repositoryName" && cp -r "$temporaryDirectory"/* "$repositoryName"/"
Task "* Cleaning up temporary files" "rm -rf "$temporaryDirectory""
Txt "Repository cloned to directory: ${CLR2}$repositoryName${CLR0}"
if [[ -f "$repositoryName/$scriptPath" ]];then
Task "* Setting execute permissions" "chmod +x "$repositoryName/$scriptPath""
Txt "$CLR8$(Linet = "24")$CLR0"
if [[ $1 == "--" ]];then
shift
./"$repositoryName/$scriptPath" "$@"||{
Err "Failed to execute script $scriptName"
return 1
}
else
./"$repositoryName/$scriptPath"||{
Err "Failed to execute script $scriptName"
return 1
}
fi
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
[[ $deleteAfter == true ]]&&rm -rf "$repositoryName"
fi
else
Txt "${CLR3}Downloading and executing script [${scriptName}] from ${repositoryOwner}/${repositoryName}${CLR0}"
githubUniformResourceLocator="https://raw.githubusercontent.com/$repositoryOwner/$repositoryName/refs/heads/$repositoryBranch/$scriptPath"
if [[ $repositoryBranch != "main" ]];then
Task "* Checking $repositoryBranch repositoryBranch" "curl -sLf "$githubUniformResourceLocator" >/dev/null"
[ $? -ne 0 ]&&{
Err "Script not found in $repositoryBranch repositoryBranch"
return 1
}
else
Task "* Checking main repositoryBranch" "curl -sLf "$githubUniformResourceLocator" >/dev/null" true
if [ $? -ne 0 ];then
Task "* Checking master repositoryBranch" "
							repositoryBranch="master"
							githubUniformResourceLocator="https://raw.githubusercontent.com/$repositoryOwner/$repositoryName/refs/heads/master/$scriptPath"
							curl -sLf "$githubUniformResourceLocator" >/dev/null
						"
[ $? -ne 0 ]&&{
Err "Script not found in either main or master repositoryBranch"
return 1
}
fi
fi
Task "* Downloading script" "
					curl -sSLf \"$githubUniformResourceLocator\" -o \"$scriptName\" || { 
						Err \"Failed to download script $scriptName\"
						Err \"Failed to download from: $github_uniformResourceLocator\"
						return 1
					}

					if [[ ! -f \"$scriptName\" ]]; then
						Err \"Download failed: File not created\"
						return 1
					fi

					if [[ ! -s \"$scriptName\" ]]; then
						Err \"Downloaded file is empty\"
						cat \"$scriptName\" 2>/dev/null || echo \"(cannot display file content)\"
						return 1
					fi

					if ! grep -q '[^[:space:]]' \"$scriptName\"; then
						Err \"Downloaded file contains only whitespace\"
						return 1
					fi

					chmod +x \"$scriptName\" || { 
						Err \"Failed to set execute permission for $scriptName\"
						Err \"Failed to set execute permission on $scriptName\"
						ls -la \"$scriptName\"
						return 1
					}
				"
Txt "$CLR8$(Linet = "24")$CLR0"
if [[ -f $scriptName ]];then
if [[ $1 == "--" ]];then
shift
./"$scriptName" "$@"||{
Err "Failed to execute script $scriptName"
return 1
}
else
./"$scriptName"||{
Err "Failed to execute script $scriptName"
return 1
}
fi
else
Err "Script file '$scriptName' was not downloaded successfully"
return 1
fi
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
[[ $deleteAfter == true ]]&&rm -rf "$scriptName"
fi
else
[ -x "$1" ]||chmod +x "$1"
scriptPath="$1"
if [[ $2 == "--" ]];then
shift 2
"$scriptPath" "$@"||{
Err "Failed to execute script $scriptName"
return 1
}
else
shift
"$scriptPath" "$@"||{
Err "Failed to execute script $scriptName"
return 1
}
fi
fi
else
eval "$*"
fi
rm -rf /tmp/* &>/dev/null
}
function ShellVer(){
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
function Swap.Usage(){
used=$(free -b|awk '/^Swap:/ {printf "%.0f", $3}')
total=$(free -b|awk '/^Swap:/ {printf "%.0f", $2}')
percentage=$(free|awk '/^Swap:/ {if($2>0) printf("%.2f"), $3/$2 * 100.0; else print "0.00"}')
case "$1" in
-u)Txt "$used";;
-t)Txt "$total";;
-p)Txt "$percentage";;
*)Txt "$(ConvSize "$used") / $(ConvSize "$total") ($percentage%)"
esac
}
function Sys.Clean(){
?Root
Txt "${CLR3}Performing system cleanup...${CLR0}"
Txt "$CLR8$(Linet = "24")$CLR0"
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
((waitTime++))
[ "$waitTime" -gt 300 ]&&{
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
for command in docker npm pip;do
if command -v "$command" &>/dev/null;then
case "$command" in
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
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
}
function Sys.Info(){
Txt "${CLR3}System Information${CLR0}"
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "- Hostname:		$CLR2$(uname -n||{
Err "Failed to get hostname"
return 1
})$CLR0"
Txt "- Operating System:	$CLR2$(Check.Os)$CLR0"
Txt "- Kernel Version:	$CLR2$(uname -r)$CLR0"
Txt "- System Language:	$CLR2$LANG$CLR0"
Txt "- Shell Version:	$CLR2$(ShellVer)$CLR0"
Txt "- Last System Update:	$CLR2$(LastUpdate)$CLR0"
Txt "$CLR8$(Linet - "32")$CLR0"
Txt "- Architecture:		$CLR2$(uname -m)$CLR0"
Txt "- CPU Model:		$CLR2$(Cpu.Model)$CLR0"
Txt "- CPU Cores:		$CLR2$(nproc)$CLR0"
Txt "- CPU Frequency:	$CLR2$(Cpu.Freq)$CLR0"
Txt "- CPU Usage:		$CLR2$(Cpu.Usage)%$CLR0"
Txt "- CPU Cache:		$CLR2$(Cpu.Cache)$CLR0"
Txt "$CLR8$(Linet - "32")$CLR0"
Txt "- Memory Usage:		$CLR2$(Mem.Usage)$CLR0"
Txt "- Swap Usage:		$CLR2$(Swap.Usage)$CLR0"
Txt "- Disk Usage:		$CLR2$(Disk.Usage)$CLR0"
Txt "- File System Type:	$CLR2$(df -T /|awk 'NR==2 {print $2}')$CLR0"
Txt "$CLR8$(Linet - "32")$CLR0"
Txt "- IPv4 Address:		$CLR2$(Net.Ip.Addr -4)$CLR0"
Txt "- IPv6 Address:		$CLR2$(Net.Ip.Addr -6)$CLR0"
Txt "- MAC Address:		$CLR2$(Net.Mac.Addr)$CLR0"
Txt "- Network Provider:	$CLR2$(Net.Provider)$CLR0"
Txt "- DNS Servers:		$CLR2$(Net.Dns.Addr)$CLR0"
Txt "- Public IP:		$CLR2$(Net.PublicIp)$CLR0"
Txt "- Network Interface:	$CLR2$(Net.Interface -i)$CLR0"
Txt "- Internal Timezone:	$CLR2$(Net.TimeZone -i)$CLR0"
Txt "- External Timezone:	$CLR2$(Net.TimeZone -e)$CLR0"
Txt "$CLR8$(Linet - "32")$CLR0"
Txt "- Load Average:		$CLR2$(LoadAverage)$CLR0"
Txt "- Process Count:	$CLR2$(ps aux|wc -l)$CLR0"
Txt "- Packages Installed:	$CLR2$(Pkg.Count)$CLR0"
Txt "$CLR8$(Linet - "32")$CLR0"
Txt "- Uptime:		$CLR2$(uptime -p|sed 's/up //')$CLR0"
Txt "- Boot Time:		$CLR2$(who -b|awk '{print $3, $4}')$CLR0"
Txt "$CLR8$(Linet - "32")$CLR0"
Txt "- Virtualization:	$CLR2$(Check.Virt)$CLR0"
Txt "$CLR8$(Linet = "24")$CLR0"
}
function Sys.Optimize(){
?Root
Txt "${CLR3}Optimizing system configuration for long-running servers...${CLR0}"
Txt "$CLR8$(Linet = "24")$CLR0"
sysctlConfig="/etc/sysctl.d/99-server-optimizations.conf"
Txt "# Server optimizations for long-running systems" >"$sysctlConfig"
Task "* Optimizing memory management" "
		Txt 'vm.swappiness = 1' >> $sysctlConfig
		Txt 'vm.vfs_cache_pressure = 50' >> $sysctlConfig
		Txt 'vm.dirty_ratio = 15' >> $sysctlConfig
		Txt 'vm.dirty_background_ratio = 5' >> $sysctlConfig
		Txt 'vm.min_free_kbytes = 65536' >> $sysctlConfig
	"||{
Err "Failed to optimize memory management"
return 1
}
Task "* Optimizing network settings" "
		Txt 'net.core.somaxconn = 65535' >> $sysctlConfig
		Txt 'net.core.netdev_max_backlog = 65535' >> $sysctlConfig
		Txt 'net.ipv4.tcp_max_syn_backlog = 65535' >> $sysctlConfig
		Txt 'net.ipv4.tcp_fin_timeout = 15' >> $sysctlConfig
		Txt 'net.ipv4.tcp_keepalive_time = 300' >> $sysctlConfig
		Txt 'net.ipv4.tcp_keepalive_probes = 5' >> $sysctlConfig
		Txt 'net.ipv4.tcp_keepalive_intvl = 15' >> $sysctlConfig
		Txt 'net.ipv4.tcp_tw_reuse = 1' >> $sysctlConfig
		Txt 'net.ipv4.ip_local_port_range = 1024 65535' >> $sysctlConfig
	"||{
Err "Failed to optimize network settings"
return 1
}
Task "* Optimizing TCP buffers" "
		Txt 'net.core.rmem_max = 16777216' >> $sysctlConfig
		Txt 'net.core.wmem_max = 16777216' >> $sysctlConfig
		Txt 'net.ipv4.tcp_rmem = 4096 87380 16777216' >> $sysctlConfig
		Txt 'net.ipv4.tcp_wmem = 4096 65536 16777216' >> $sysctlConfig
		Txt 'net.ipv4.tcp_mtu_probing = 1' >> $sysctlConfig
	"||{
Err "Failed to optimize TCP buffers"
return 1
}
Task "* Optimizing filesystem settings" "
		Txt 'fs.file-max = 2097152' >> $sysctlConfig
		Txt 'fs.nr_open = 2097152' >> $sysctlConfig
		Txt 'fs.inotify.max_user_watches = 524288' >> $sysctlConfig
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
Task "* Applying system parameters" "sysctl -p $sysctlConfig"||{
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
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
}
function Sys.Reboot(){
?Root
Txt "${CLR3}Preparing to reboot system...${CLR0}"
Txt "$CLR8$(Linet = "24")$CLR0"
activeUsers=$(who|wc -l)||{
Err "Failed to get active user count"
return 1
}
if [ "$activeUsers" -gt 1 ];then
Txt "${CLR1}Warning: There are currently $activeUsers active users on the system${CLR0}\n"
Txt "Active users:"
who|awk '{print $1 " since " $3 " " $4}'
Txt
fi
importantProcesses=$(ps aux --no-headers|awk '$3 > 1.0 || $4 > 1.0'|wc -l)||{
Err "Failed to check running processes"
return 1
}
if [ "$importantProcesses" -gt 0 ];then
Txt "${CLR1}Warning: There are $importantProcesses important processes running${CLR0}\n"
Txt "${CLR8}Top 5 processes by CPU usage:${CLR0}"
ps aux --sort=-%cpu|head -n 6
Txt
fi
Press "Are you sure you want to reboot the system now? (y/N) "
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
function Sys.Update(){
?Root
Txt "${CLR3}Updating system software...${CLR0}"
Txt "$CLR8$(Linet = "24")$CLR0"
UpdatePkgs(){
command="$1"
updateCommand="$2"
upgradeCommand="$3"
Txt "* Updating package lists"
$updateCommand||{
Err "Failed to update package lists using $cmd"
return 1
}
Txt "* Upgrading packages"
$upgradeCommand||{
Err "Failed to upgrade packages using $cmd"
return 1
}
}
case $(command -v apk apt opkg pacman yum zypper dnf|head -n1) in
*apk)UpdatePkgs "apk" "apk update" "apk upgrade";;
*apt)while
fuser /var/lib/dpkg/lock-frontend &>/dev/null
do
Task "* Waiting for dpkg lock" "sleep 1"||return 1
((waitTime++))
[ "$waitTime" -gt 10 ]&&{
Err "Timeout waiting for dpkg lock to be released"
return 1
}
done
Task "* Configuring pending packages" "DEBIAN_FRONTEND=noninteractive dpkg --configure -a"||{
Err "Failed to configure pending packages"
return 1
}
UpdatePkgs "apt" "apt update -y" "apt full-upgrade -y"
;;
*opkg)UpdatePkgs "opkg" "opkg update" "opkg upgrade";;
*pacman)Task "* Updating and upgrading packages" "pacman -Syu --noconfirm"||{
Err "Failed to update and upgrade packages using pacman"
return 1
};;
*yum)UpdatePkgs "yum" "yum check-update" "yum -y update";;
*zypper)UpdatePkgs "zypper" "zypper refresh" "zypper update -y";;
*dnf)UpdatePkgs "dnf" "dnf check-update" "dnf -y update";;
*){
Err "Unsupported package manager"
return 1
}
esac
Txt "* Updating $SCRIPTS"
bash <(curl -L https://raw.githubusercontent.com/OG-Open-Source/UtilKit/refs/heads/main/sh/get_utilkit.sh)||{
Err "Failed to update $SCRIPTS"
return 1
}
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}FINISHED${CLR0}\n"
}
function Sys.Upgrade(){
?Root
Txt "${CLR3}Upgrading system to next major version...${CLR0}"
Txt "$CLR8$(Linet = "24")$CLR0"
operatingSystemName=$(Check.Os -n)
case "$operatingSystemName" in
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
currentCodename=$(lsb_release -cs)
targetCodename=$(curl -s http://ftp.debian.org/debian/dists/stable/Release|grep "^Codename:"|awk '{print $2}')
[ "$currentCodename" = "$targetCodename" ]&&{
Err "System is already running the latest stable version ($targetCodename)"
return 1
}
Txt "* Upgrading from ${CLR2}${currentCodename}${CLR0} to ${CLR3}${targetCodename}${CLR0}"
Task "* Backing up sources.list" "cp /etc/apt/sources.list /etc/apt/sources.list.backup"||{
Err "Failed to backup sources.list"
return 1
}
Task "* Updating sources.list" "sed -i 's/$currentCodename/$targetCodename/g' /etc/apt/sources.list"||{
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
Sys.Reboot
;;
*){
Err "Your system is not yet supported for major version upgrades"
return 1
}
esac
Txt "$CLR8$(Linet = "24")$CLR0"
Txt "${CLR2}System upgrade completed${CLR0}\n"
}
function Task(){
message="$1"
command="$2"
ignoreError=${3:-false}
temporaryFile=$(mktemp)
Txt -n "$message..."
if eval "$command" >"$temporaryFile" 2>&1;then
Txt "${CLR2}Done${CLR0}"
ret=0
else
ret=$?
Txt "${CLR1}Failed${CLR0} ($ret)"
[[ -s $temporaryFile ]]&&Txt "$CLR1$(cat "$temporaryFile")$CLR0"
[[ $ignoreError != "true" ]]&&return $ret
fi
Del -f "$temporaryFile"
return $ret
}
function Net.TimeZone(){
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
function Press(){
read -p "$1" -n 1 -r||{
Err "Failed to read user input"
return 1
}
}
function TEST(){
Txt "$CLR8--- Starting UtilKit Test Suite ---$CLR0"
Linet "=" 40
Txt "Testing Basic I/O Functions"
Linet "-" 40
Txt "Testing Txt:"
Txt "  Hello World"
Txt "Testing Err:"
Err "  This is a test error message."
Txt "Testing Font:"
Font BOLD "  Bold Text"
Font GREEN "  Green Text"
Font BG.RED WHITE "  White text on Red background"
Font RGB "100,150,200" "  Custom RGB color text"
Txt "Testing Linet:"
Linet "*" 20
Linet "=" 40
Txt "Testing File and Directory Operations"
Linet "-" 40
Txt "Testing Add -f (file):"
Add -f test_file.tmp
Txt "Testing Add -d (directory):"
Add -d test_dir.tmp
Txt "Listing created items:"
ls -ld test_file.tmp test_dir.tmp
Txt "Testing Del -f (file):"
Del -f test_file.tmp
Txt "Testing Del -d (directory):"
Del -d test_dir.tmp
Txt "Listing items after deletion:"
ls -ld test_file.tmp test_dir.tmp 2>/dev/null||Txt "  Items successfully deleted."
Linet "=" 40
Txt "Testing System Information Functions"
Linet "-" 40
Txt "Authors: $AUTHORS"
Txt "Script: $SCRIPTS"
Txt "Version: $VERSION"
Copyright
Txt "OS Info: $(Check.Os)"
Txt "OS Name: $(Check.Os -n)"
Txt "OS Version: $(Check.Os -v)"
Txt "Virt-Type: $(Check.Virt)"
Txt "CPU Model: $(Cpu.Model)"
Txt "CPU Freq: $(Cpu.Freq)"
Txt "CPU Cache: $(Cpu.Cache)"
Txt "CPU Usage: $(Cpu.Usage)%"
Txt "Shell: $(ShellVer)"
Txt "Uptime: $(uptime -p)"
Txt "Last Update: $(LastUpdate)"
Txt "Load Average: $(LoadAverage)"
Txt "Package Count: $(Pkg.Count)"
Linet "=" 40
Txt "Testing Resource Usage Functions"
Linet "-" 40
Txt "Memory Usage: $(Mem.Usage)"
Txt "Swap Usage: $(Swap.Usage)"
Txt "Disk Usage: $(Disk.Usage)"
Linet "=" 40
Txt "Testing Network Functions"
Linet "-" 40
Txt "Interface: $(Net.Interface)"
Txt "Interface Stats: $(Net.Interface -i)"
Txt "Public IP: $(Net.PublicIp)"
Txt "IP Address (v4): $(Net.Ip.Addr -4)"
Txt "IP Address (v6): $(Net.Ip.Addr -6)"
Txt "MAC Address: $(Net.Mac.Addr)"
Txt "DNS Servers: $(Net.Dns.Addr)"
Txt "Location: $(Net.Location)"
Txt "Provider: $(Net.Provider)"
Txt "Internal Timezone: $(Net.TimeZone -i)"
Txt "External Timezone: $(Net.TimeZone -e)"
Linet "=" 40
Txt "Testing Utility Functions"
Linet "-" 40
Txt "Testing ConvSize:"
Txt "  1024 B -> $(ConvSize 1024 B)"
Txt "  2048000 KB -> $(ConvSize 2048000 KB)"
Txt "  5.5 GiB -> $(ConvSize 5.5 GiB)"
Txt "Testing Format:"
Txt "  Format -AA 'hello world' -> $(Format -AA 'hello world')"
Txt "  Format -aa 'HELLO WORLD' -> $(Format -aa 'HELLO WORLD')"
Txt "  Format -Aa 'hello world' -> $(Format -Aa 'hello world')"
Txt "Testing Get (small file):"
Get https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/LICENSE -r test_license.tmp
cat test_license.tmp
Del -f test_license.tmp
Txt "Testing Find (package 'curl'):"
Find curl
Txt "Testing Check.Deps (dependency 'bash'):"
deps=("bash" "non_existent_command")
Check.Deps
Linet "=" 40
Txt "Testing Interactive and Task Functions"
Linet "-" 40
Txt "Testing Task:"
Task "  Running 'echo test' command" "echo test"
Txt "Testing Progress:"
commands=("sleep 0.1" "sleep 0.2" "sleep 0.1")
Progress
Txt "\nTesting Run:"
Run echo "  'Run' command executed successfully."
Linet "=" 40
Txt "Testing Potentially Destructive Functions (COMMENTED OUT)"
Linet "-" 40
Txt "  The following functions are not executed automatically to prevent unwanted system changes."
Txt "  Uncomment them in the TEST function to test them manually."
Linet "=" 40
Txt "$CLR8--- UtilKit Test Suite Finished ---$CLR0"
}
