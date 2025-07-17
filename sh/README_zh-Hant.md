# UtilKit.sh

一個全面的 Shell 函數庫，提供系統管理、監控和網路配置等功能。

---

## 目錄

- [簡介](#簡介)
- [特性](#特性)
- [安裝](#安裝)
- [使用方法](#使用方法)
- [示例](#示例)
- [配置](#配置)
- [常見問題](#常見問題)
- [Contributing](#contributing)
- [License](#license)

---

## 簡介

UtilKit.sh 是一個全面的 Shell 函數庫，專為系統管理員和開發者設計。它提供了豐富的函式可用，包括套件管理、系統監控、網路配置等，大大簡化了日常系統維護工作。

| 可用函式                      |                               |                               |                           |
|-------------------------------|-------------------------------|-------------------------------|---------------------------|
| [ADD](#add)                   | [CHECK_DEPS](#check_deps)     | [CHECK_OS](#check_os)         | [CHECK_ROOT](#check_root) |
| [CHECK_VIRT](#check_virt)     | [CLEAN](#clean)               | [CONVERT_SIZE](#convert_size) | [COPYRIGHT](#copyright)   |
| [CPU_CACHE](#cpu_cache)       | [CPU_FREQ](#cpu_freq)         | [CPU_MODEL](#cpu_model)       | [CPU_USAGE](#cpu_usage)   |
| [DEL](#del)                   | [DISK_USAGE](#disk_usage)     | [DNS_ADDR](#dns_addr)         | [FIND](#find)             |
| [FONT](#font)                 | [FORMAT](#format)             | [GET](#get)                   | [INPUT](#input)           |
| [INTERFACE](#interface)       | [IP_ADDR](#ip_addr)           | [LAST_UPDATE](#last_update)   | [LINE](#line)             |
| [LOAD_AVERAGE](#load_average) | [LOCATION](#location)         | [MAC_ADDR](#mac_addr)         | [MEM_USAGE](#mem_usage)   |
| [NET_PROVIDER](#net_provider) | [PKG_COUNT](#pkg_count)       | [PROGRESS](#progress)         | [PUBLIC_IP](#public_ip)   |
| [RUN](#run)                   | [SHELL_VER](#shell_ver)       | [SWAP_USAGE](#swap_usage)     | [SYS_CLEAN](#sys_clean)   |
| [SYS_INFO](#sys_info)         | [SYS_OPTIMIZE](#sys_optimize) | [SYS_REBOOT](#sys_reboot)     | [SYS_UPDATE](#sys_update) |
| [SYS_UPGRADE](#sys_upgrade)   | [TASK](#task)                 | [TIMEZONE](#timezone)         |                           |

## 特性

- 完整的系統管理功能集
- 即時系統效能監控
- 網路配置與診斷工具
- 自動化系統優化
- 完整的錯誤處理機制
- 支援多種 Linux 發行版
- 豐富的文字處理功能
- 自動更新機制

## 安裝

### 環境要求

- Unix-like 作業系統（Linux、macOS）
- Bash Shell 4.0 或更高版本
- 基本系統工具（tr、bc、curl）
- root 權限（部分功能需要）

```bash
#使用安裝腳本
[ -f ~/utilkit.sh ] && source ~/utilkit.sh || bash <(curl -sL utilkit.ogtt.tk/sh) && source ~/utilkit.sh
```

## 使用方法

### 基本命令格式

```bash
source utilkit.sh
函數名稱 [參數]
```

### 函式說明

#### ADD

- 功能：新增檔案或安裝套件
- 用法：`ADD [-f/-d] <項目>`
- 參數：
  - `-f`：建立檔案
  - `-d`：建立目錄
  - 無參數時預設為安裝套件
- 示例：

```bash
ADD nginx              # 安裝 nginx 套件
ADD -f /path/file.txt  # 建立檔案
ADD -d /path/dir       # 建立目錄
```

#### CHECK_DEPS

- 功能：檢查依賴項是否已安裝
- 用法：

```bash
deps=("curl" "wget" "git")  # 設定要檢查的依賴項
CHECK_DEPS                  # 執行檢查
```

- 說明：需要先設定 deps 陣列變數，再執行檢查

#### CHECK_OS

- 功能：檢查並顯示作業系統資訊
- 用法：`CHECK_OS [選項]`
- 參數：
  - `-v`：只顯示版本號
  - `-n`：只顯示發行版名稱
  - 無參數：顯示完整作業系統資訊
- 示例：

```bash
CHECK_OS        # 輸出：Ubuntu 22.04 LTS
CHECK_OS -v     # 輸出：22.04
CHECK_OS -n     # 輸出：Ubuntu
```

#### CHECK_ROOT

- 功能：檢查是否具有 root 權限
- 用法：`CHECK_ROOT`
- 說明：如果不是 root 用戶執行會報錯並退出

#### CHECK_VIRT

- 功能：檢查虛擬化環境
- 用法：`CHECK_VIRT`
- 輸出：顯示虛擬化類型（KVM/Docker/實體機等）

#### CLEAN

- 功能：清理終端機螢幕
- 用法：`CLEAN`
- 說明：相當於 clear 命令，但會切換到使用者主目錄

#### CONVERT_SIZE

- 功能：轉換檔案大小單位
- 用法：`CONVERT_SIZE <大小> [單位]`
- 參數：
  - 大小：數值
  - 單位：
    - 二進制：B/KiB/MiB/GiB/TiB/PiB
    - 十進制：B/KB/MB/GB/TB/PB
- 示例：

```bash
CONVERT_SIZE 1024        # 預設使用二進制（1.000 KiB）
CONVERT_SIZE 1000 KB     # 使用十進制（1000 KB =  1.000 MB）
```

#### COPYRIGHT

- 功能：顯示版權資訊
- 用法：`COPYRIGHT`
- 輸出：顯示腳本版本和版權聲明

#### CPU_CACHE

- 功能：顯示 CPU 快取大小
- 用法：`CPU_CACHE`
- 輸出：以 KB 為單位顯示快取大小

#### CPU_FREQ

- 功能：顯示 CPU 頻率
- 用法：`CPU_FREQ`
- 輸出：以 GHz 為單位顯示頻率

#### CPU_MODEL

- 功能：顯示 CPU 型號
- 用法：`CPU_MODEL`
- 輸出：顯示處理器完整型號名稱

#### CPU_USAGE

- 功能：顯示 CPU 使用率
- 用法：`CPU_USAGE`
- 輸出：以百分比值顯示當前 CPU 使用率

#### DEL

- 功能：刪除檔案或移除套件
- 用法：`DEL [-f/-d] <項目>`
- 參數：
  - `-f`：刪除檔案
  - `-d`：刪除目錄
  - 無參數時預設為移除套件
- 示例：

```bash
DEL nginx              # 移除 nginx 套件
DEL -f /path/file.txt  # 刪除檔案
DEL -d /path/dir       # 刪除目錄
```

#### DISK_USAGE

- 功能：顯示硬碟使用情況
- 用法：`DISK_USAGE [-u/-t/-p]`
- 參數：
  - `-u`：只顯示已用空間
  - `-t`：只顯示總空間
  - `-p`：只顯示使用率百分比值
- 輸出：顯示已用空間/總空間和使用率百分比

#### DNS_ADDR

- 功能：顯示 DNS 伺服器地址
- 用法：`DNS_ADDR [-4/-6]`
- 參數：
  - `-4`：只顯示 IPv4 DNS
  - `-6`：只顯示 IPv6 DNS
  - 無參數顯示全部

#### FIND

- 功能：搜尋套件
- 用法：`FIND <關鍵字>`
- 說明：在套件庫中搜尋符合關鍵字的套件

#### FONT

- 功能：設定文字樣式和顏色
- 用法：`FONT [樣式] [顏色] [背景色] <文字>`
- 參數：
  - 樣式：B（粗體）、U（底線）
  - 顏色：
    - 基本色：BLACK、RED、GREEN、YELLOW、BLUE、PURPLE、CYAN、WHITE
    - 亮色：L.BLACK、L.RED、L.GREEN、L.YELLOW、L.BLUE、L.PURPLE、L.CYAN、L.WHITE
  - 背景色：
    - 基本背景：BG.BLACK、BG.RED、BG.GREEN、BG.YELLOW、BG.BLUE、BG.PURPLE、BG.CYAN、BG.WHITE
    - 亮背景：L.BG.BLACK、L.BG.RED、L.BG.GREEN、L.BG.YELLOW、L.BG.BLUE、L.BG.PURPLE、L.BG.CYAN、L.BG.WHITE
  - RGB：可使用 RGB 值（前景色和背景色）
- 示例：

```bash
FONT B RED "錯誤"                    # 粗體紅色
FONT B RED BG.WHITE "警告"           # 粗體紅色白底
FONT RGB 255,0,0 "紅色"              # RGB 前景色
FONT B RGB 255,0,0 BG.RGB 0,0,255 "紅字藍底"  # RGB 前景色和背景色
```

#### FORMAT

- 功能：格式化文字
- 用法：`FORMAT <選項> <文字>`
- 參數：
  - `-AA`：轉換為全大寫
  - `-aa`：轉換為全小寫
  - `-Aa`：首字母大寫
- 示例：

```bash
FORMAT -AA "hello"    # 輸出：HELLO
FORMAT -aa "WORLD"    # 輸出：world
FORMAT -Aa "hELLo"    # 輸出：Hello
```

#### GET

- 功能：下載檔案
- 用法：`GET <URL> [-r 新檔名] [-x] [目標目錄]`
- 參數：
  - `-r`：指定新檔名（可選）
  - `-x`：下載後自動解壓縮（可選）
  - 目標目錄：指定下載位置（可選，預設為當前目錄）
- 支援的壓縮格式：
  - tar.gz, tgz
  - tar
  - tar.bz2, tbz2
  - tar.xz, txz
  - zip
  - 7z
  - rar
  - zst
- 示例：

```bash
GET https://example.com/file.txt                      # 下載到當前目錄
GET https://example.com/file.txt downloads            # 下載到指定目錄
GET https://example.com/file.txt -r new.txt downloads # 下載並重命名
GET https://example.com/archive.tar.gz -x             # 下載並自動解壓縮
```

#### INPUT

- 功能：讀取使用者輸入
- 用法：`INPUT <提示文字> <變數名>`
- 示例：`INPUT "請輸入名稱：" name`

#### INTERFACE

- 功能：顯示網路介面資訊
- 用法：`INTERFACE [選項]`
- 參數：
  - `-i`：顯示詳細資訊
  - 流量統計：
    - `RX_BYTES`：接收的位元組數
    - `RX_PACKETS`：接收的封包數
    - `RX_DROP`：丟棄的接收封包數
    - `TX_BYTES`：傳送的位元組數
    - `TX_PACKETS`：傳送的封包數
    - `TX_DROP`：丟棄的傳送封包數
  - 無參數：顯示真實網卡名稱（自動過濾虛擬網卡）
- 示例：

```bash
INTERFACE              # 顯示真實網卡名稱
INTERFACE -i           # 顯示詳細資訊
INTERFACE RX_BYTES     # 顯示接收位元組數
INTERFACE TX_PACKETS   # 顯示傳送封包數
```

- 說明：
  - 自動過濾以下虛擬網卡：
    - lo、sit、stf、gif、dummy
    - vmnet、vir、gre、ipip
    - ppp、bond、tun、tap
    - ip6gre、ip6tnl、teql
    - ocserv、vpn、warp、wgcf
    - wg、docker

#### IP_ADDR

- 功能：顯示 IP 地址
- 用法：`IP_ADDR [-4/-6]`
- 參數：
  - `-4`：顯示 IPv4 地址
  - `-6`：顯示 IPv6 地址
  - 無參數顯示全部

#### LAST_UPDATE

- 功能：顯示最後系統更新時間
- 用法：`LAST_UPDATE`
- 輸出：顯示上次更新的日期和時間

#### LINE

- 功能：繪製分隔線
- 用法：`LINE [字元] [長度]`
- 參數：
  - 字元：分隔線使用的字元（預設為 -）
  - 長度：分隔線長度（預設為 80）

#### LOAD_AVERAGE

- 功能：顯示系統負載
- 用法：`LOAD_AVERAGE`
- 輸出：顯示 1、5、15 分鐘的平均負載

#### LOCATION

- 功能：顯示地理位置
- 用法：`LOCATION`
- 輸出：顯示當前位置的縮寫

#### MAC_ADDR

- 功能：顯示 MAC 地址
- 用法：`MAC_ADDR`
- 輸出：顯示主要網路介面的 MAC 地址

#### MEM_USAGE

- 功能：顯示記憶體使用情況
- 用法：`MEM_USAGE [-u/-t/-p]`
- 參數：
  - `-u`：只顯示已用空間
  - `-t`：只顯示總空間
  - `-p`：只顯示使用率百分比值
- 輸出：顯示已用/總量和使用率百分比

#### NET_PROVIDER

- 功能：顯示網路服務商
- 用法：`NET_PROVIDER`
- 輸出：顯示當前網路的 ISP 名稱

#### PKG_COUNT

- 功能：統計已安裝套件數量
- 用法：`PKG_COUNT`
- 輸出：顯示系統中已安裝的套件總數

#### PROGRESS

- 功能：顯示進度條
- 用法：

```bash
cmds=(
 "command1"
 "command2"
 "command3"
)
PROGRESS
```

- 說明：
  - 需要先設定 cmds 陣列變數
  - 每個命令會依序執行
  - 進度條會顯示執行進度百分比

#### PUBLIC_IP

- 功能：顯示公網 IP
- 用法：`PUBLIC_IP`
- 輸出：顯示當前網路的公網 IP 地址

#### RUN

- 功能：執行命令或腳本
- 用法：`RUN <命令/腳本> [-r] [-b 分支] [--] [參數]`
- 參數：
  - `-r`：額外對 GitHub 進行倉庫下載並執行腳本
  - `-b`：指定 GitHub 倉庫分支（可選，預設為 main）
  - `--`：分隔符，用於傳遞參數給腳本
- 支援：
  - 本地命令執行
  - 本地腳本執行
  - GitHub 倉庫腳本執行
- 示例：

```bash
RUN "ls -la"                           # 執行本地命令
RUN local_script.sh                    # 執行本地腳本
RUN local_script.sh arg1 arg2          # 執行本地腳本並傳遞參數
RUN username/repo/script.sh            # 執行 GitHub 腳本（main 分支）
RUN username/repo/script.sh -b dev     # 執行 GitHub 腳本（指定分支）
RUN username/repo/script.sh -- arg1    # 執行 GitHub 腳本並傳遞參數
```

#### SHELL_VER

- 功能：顯示 Shell 版本
- 用法：`SHELL_VER`
- 輸出：顯示當前使用的 Shell 及其版本

#### SWAP_USAGE

- 功能：顯示交換分區使用情況
- 用法：`SWAP_USAGE [-u/-t/-p]`
- 參數：
  - `-u`：只顯示已用空間
  - `-t`：只顯示總空間
  - `-p`：只顯示使用率百分比值
- 輸出：顯示已用/總量和使用率百分比

#### SYS_CLEAN

- 功能：系統清理
- 用法：`SYS_CLEAN`
- 說明：清理系統快取、暫存檔案等

#### SYS_INFO

- 功能：顯示系統資訊
- 用法：`SYS_INFO`
- 輸出：顯示完整的系統資訊報告

#### SYS_OPTIMIZE

- 功能：系統優化
- 用法：`SYS_OPTIMIZE`
- 說明：優化系統設定以提升效能

#### SYS_REBOOT

- 功能：系統重啟
- 用法：`SYS_REBOOT`
- 說明：安全地重新啟動系統

#### SYS_UPDATE

- 功能：系統更新
- 用法：`SYS_UPDATE`
- 說明：更新系統和已安裝的套件

#### SYS_UPGRADE

- 功能：升級系統到下一個主要版本
- 用法：`SYS_UPGRADE`
- 說明：
  - 自動備份重要系統檔案
  - 更新套件來源
  - 執行完整系統升級
  - 完成後可能需要重新啟動

#### TASK

- 功能：顯示任務執行狀態並處理命令輸出的輔助函數
- 說明：
  - 顯示任務描述和執行狀態
  - 支持單行和多行命令執行
  - 錯誤時自動中止並顯示詳細信息
- 語法：

```bash
TASK "消息" "命令" [是否忽略錯誤]
```

- 參數：
  - `消息`: 顯示的任務描述
  - `命令`: 要執行的 Shell 命令
  - `是否忽略錯誤`: 可選參數，設置為 true 時會忽略命令執行失敗（默認為 false）
- 返回值：
  - 0: 命令成功執行
  - 1: 命令執行失敗
- 示例：

```bash
# 命令示例
TASK "更新套件列表" "apt-get update"
TASK "創建目錄" "ADD -d /path/to/dir"
```

- 輸出格式：

```bash
* 任務描述... Done     # 成功時
* 任務描述... Failed   # 失敗時
  [錯誤詳情]           # 失敗時顯示具體錯誤
```

#### TIMEZONE

- 功能：顯示時區資訊
- 用法：`TIMEZONE [-i/-e]`
- 參數：
  - `-i`：顯示內部時區設定
  - `-e`：顯示外部偵測到的時區

## 示例

### 系統資訊查詢

```bash
source utilkit.sh
SYS_INFO
```

### 系統優化

```bash
source utilkit.sh
SYS_OPTIMIZE
```

### 文字樣式設定

```bash
source utilkit.sh
# 使用基本顏色
FONT B RED "錯誤訊息"
FONT B GREEN BG.WHITE "成功訊息"

# 使用 RGB 顏色
FONT RGB 255,0,0 "自定義紅色"
FONT B RGB 255,0,0 BG.RGB 0,0,255 "紅字藍底"
```

## 配置

### 環境變數

```bash
# 顏色定義
CLR1="\033[0;31m"    # 紅色
CLR2="\033[0;32m"    # 綠色
CLR3="\033[0;33m"    # 黃色
CLR4="\033[0;34m"    # 藍色
CLR5="\033[0;35m"    # 紫色
CLR6="\033[0;36m"    # 青色
CLR7="\033[0;37m"    # 白色
CLR8="\033[0;96m"    # 亮青色
CLR9="\033[0;97m"    # 亮白色
CLR0="\033[0m"       # 重置
```

## 常見問題

**Q：為什麼某些命令需要 root 權限？**  
A：系統層級的操作（如更新、安裝套件等）需要 root 權限以確保安全性。

**Q：如何處理網路連接問題？**  
A：

- 確認網路連接狀態
- 檢查代理設置

**Q：自動更新無法運作？**  
A：請檢查：

- crontab 設定
- 系統時間是否正確
- 網路連接狀態

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

## License

This repository is licensed under the [MIT License](https://opensource.org/licenses/mit-license.php).

---

© 2025 [OG-Open-Source](https://github.com/OG-Open-Source). All rights reserved.
