@echo off
setlocal enabledelayedexpansion

REM === Language Detection ===
set "lang=%~1"
if not defined lang (
    echo Detecting language...
    for /f "tokens=2 delims==" %%a in ('curl -s "https://developers.cloudflare.com/cdn-cgi/trace" ^| findstr "^loc="') do (
        set "loc=%%a"
    )

    if "!loc!"=="CN" (
        set "lang=zh-Hans"
    ) else if "!loc!"=="TW" (
        set "lang=zh-Hant"
    ) else (
        set "lang=en"
    )
)
echo Language set to: %lang%

REM === File Path ===
set "UTILKIT_FILE=%USERPROFILE%\utilkit.sh"

REM === Main Logic ===
if exist "%UTILKIT_FILE%" (
    echo Updating UtilKit.sh...
    curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/localized/utilkit_%lang%.sh" -o "%UTILKIT_FILE%" --fail
    if !errorlevel! neq 0 (
        echo Pre-localized version not available, downloading default version...
        curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/utilkit.sh" -o "%UTILKIT_FILE%" --fail
        if !errorlevel! neq 0 (
            echo Failed to download UtilKit.sh
            exit /b 1
        )
    ) else (
        echo Downloaded pre-localized version for %lang%
    )
    echo UtilKit.sh has been updated successfully
) else (
    REM === Scheduled Task for Auto-Update ===
    schtasks /query /tn "UtilKit Auto-Update" >nul 2>&1
    if !errorlevel! neq 0 (
        echo Adding daily auto-update to Task Scheduler...
        REM Create a task that runs this script daily at midnight
        schtasks /create /tn "UtilKit Auto-Update" /tr "'%~f0' %lang%" /sc daily /st 00:00
        if !errorlevel! equ 0 (
            echo Added daily auto-update to Task Scheduler.
        ) else (
            echo Failed to create scheduled task.
        )
    )

    echo Downloading UtilKit.sh...
    curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/localized/utilkit_%lang%.sh" -o "%UTILKIT_FILE%" --fail
    if !errorlevel! neq 0 (
        echo Pre-localized version not available, downloading default version...
        curl -sSL "https://raw.githubusercontent.com/OG-Open-Source/utilkit/refs/heads/main/sh/utilkit.sh" -o "%UTILKIT_FILE%" --fail
        if !errorlevel! neq 0 (
            echo Failed to download UtilKit.sh
            exit /b 1
        )
    ) else (
        echo Downloaded pre-localized version for %lang%
    )
    
    echo UtilKit.sh has been installed successfully
    echo Please check the content of '%UTILKIT_FILE%'
)

endlocal
exit /b 0