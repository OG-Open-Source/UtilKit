#!/bin/bash

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

function Txt() { echo -e "$1" "$2"; }
function Err() {
	[ -z "$1" ] && {
		Txt "${CLR1}Unknown error${CLR0}"
		return 1
	}
	Txt "${CLR1}$1${CLR0}"
	if [ -w "/var/log" ]; then
		log_file_Err="/var/log/utilkit.sh.log"
		timestamp_Err="$(date '+%Y-%m-%d %H:%M:%S')"
		log_entry_Err="${timestamp_Err} | ${SCRIPTS} - ${VERSION} - $(Txt "$1" | tr -d '\n')"
		Txt "${log_entry_Err}" >>"${log_file_Err}" 2>/dev/null
	fi
}
function DetectLang() {
	loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace" | grep "^loc=" | cut -d= -f2)
	case "${loc}" in
	CN) echo "zh-Hans" ;;
	TW) echo "zh-Hant" ;;
	*) echo "en" ;;
	esac
}
lang="${1:-$(DetectLang)}"
pkg_mgr=$(DetectPkgMgr)
if [ -f "${HOME}/utilkit.sh" ]; then
	Txt "${CLR2}Updating UtilKit.sh...${CLR0}"
	if curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/localized/utilkit_${lang}.sh" -o "${HOME}/utilkit.sh" 2>/dev/null; then
		Txt "${CLR2}Downloaded pre-localized version for ${lang}${CLR0}"
	else
		Txt "${CLR3}Pre-localized version not available, downloading default version...${CLR0}"
		if ! curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/utilkit.sh" -o "${HOME}/utilkit.sh"; then
			Err "Failed to download UtilKit.sh"
			exit 1
		fi
	fi
	if [ -n "${pkg_mgr}" ]; then
		sed -i "s/^PKG_MGR=\"\"/PKG_MGR=\"${pkg_mgr}\"/" "${HOME}/utilkit.sh"
	fi
	Txt "${CLR2}UtilKit.sh has been updated successfully${CLR0}"
else
	if ! crontab -l 2>/dev/null | grep -q "get_utilkit.sh"; then
		(crontab -l 2>/dev/null || echo "") | {
			cat
			echo "0 0 * * * curl -sL https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/get_utilkit.sh | bash -s -- ${lang}"
		} | crontab -
		Txt "${CLR2}Added daily auto-update to crontab${CLR0}"
	fi
	Txt "${CLR2}Downloading UtilKit.sh...${CLR0}"
	if curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/localized/utilkit_${lang}.sh" -o "${HOME}/utilkit.sh" 2>/dev/null; then
		Txt "${CLR2}Downloaded pre-localized version for ${lang}${CLR0}"
	else
		Txt "${CLR3}Pre-localized version not available, downloading default version...${CLR0}"
		if ! curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/UtilKit/main/sh/utilkit.sh" -o "${HOME}/utilkit.sh"; then
			Err "Failed to download UtilKit.sh"
			exit 1
		fi
	fi
	if [ -n "${pkg_mgr}" ]; then
		sed -i "s/^PKG_MGR=\"\"/PKG_MGR=\"${pkg_mgr}\"/" "${HOME}/utilkit.sh"
	fi
	if ! grep -q "source ~/utilkit.sh" ~/.bashrc; then
		echo "source ~/utilkit.sh" >>~/.bashrc
		Txt "${CLR2}Added source command to ~/.bashrc${CLR0}"
	fi
	Txt "${CLR2}UtilKit.sh has been installed successfully${CLR0}"
	Txt "${CLR2}Please run 'source ~/utilkit.sh' to use it in the current session${CLR0}"
fi
