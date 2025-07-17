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
Txt(){ echo -e "$1";}
Err(){ Txt "$CLR1$1$CLR0";}
detect_language(){
loc=$(curl -s "https://developers.cloudflare.com/cdn-cgi/trace"|grep "^loc="|cut -d= -f2)
case "$loc" in
CN)echo "zh-Hans";;
TW)echo "zh-Hant";;
*)echo "en"
esac
}
lang="${1:-$(detect_language)}"
if [ -f ~/utilkit.sh ];then
Txt "${CLR2}Updating UtilKit.sh...$CLR0"
if curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/localized/utilkit_$lang.sh" -o "utilkit.sh" 2>/dev/null;then
Txt "${CLR2}Downloaded pre-localized version for $lang$CLR0"
else
Txt "${CLR3}Pre-localized version not available, downloading default version...$CLR0"
if ! curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/utilkit.sh" -o "utilkit.sh";then
Err "Failed to download UtilKit.sh"
exit 1
fi
fi
Txt "${CLR2}UtilKit.sh has been updated successfully$CLR0"
else
if ! crontab -l 2>/dev/null|grep -q "get_utilkit.sh";then
(crontab -l 2>/dev/null||echo "")|{
cat
echo "0 0 * * * curl -sL https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/get_utilkit.sh | bash -s -- $lang"
}|crontab -
Txt "${CLR2}Added daily auto-update to crontab$CLR0"
fi
Txt "${CLR2}Downloading UtilKit.sh...$CLR0"
if curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/localized/utilkit_$lang.sh" -o "utilkit.sh" 2>/dev/null;then
Txt "${CLR2}Downloaded pre-localized version for $lang$CLR0"
else
Txt "${CLR3}Pre-localized version not available, downloading default version...$CLR0"
if ! curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/utilkit.sh" -o "utilkit.sh";then
Err "Failed to download UtilKit.sh"
exit 1
fi
fi
if ! grep -q "source ~/utilkit.sh" ~/.bashrc;then
echo "source ~/utilkit.sh" >>~/.bashrc
Txt "${CLR2}Added source command to ~/.bashrc$CLR0"
fi
Txt "${CLR2}UtilKit.sh has been installed successfully$CLR0"
Txt "${CLR2}Please run 'source ~/utilkit.sh' to use it in the current session$CLR0"
fi
