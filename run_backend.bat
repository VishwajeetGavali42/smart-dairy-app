@echo off
title Smart Dairy Backend & Ollama AI Server
color 0A

echo =====================================================================
echo                SMART DAIRY BACKEND & OLLAMA SERVER
echo =====================================================================

:: Find active Wi-Fi IPv4 address using PowerShell
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "((Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue).IPAddress | Select-Object -First 1)"`) do set WIFI_IP=%%i

if "%WIFI_IP%"=="" (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
        if not defined WIFI_IP set WIFI_IP=%%a
    )
)

echo.
echo [NETWORK STATUS]
echo   Computer Wi-Fi IP  : %WIFI_IP%
echo   Spring Boot Port   : 8080
echo.
echo [MOBILE PHONE INSTRUCTIONS]
echo   1. Connect your mobile phone and this PC to the SAME Wi-Fi
echo      (or turn on your phone's Hotspot and connect PC to it).
echo   2. On your phone app, go to AI Chat -> tap the Cloud Icon (☁).
echo   3. Enter Server Host: %WIFI_IP%:8080
echo   4. Tap 'Connect & Test' (जोडा आणि तपासा).
echo =====================================================================
echo.

:: Check if Ollama is running
curl -s http://127.0.0.1:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Starting Ollama server in background...
    start "" ollama serve
    timeout /t 3 >nul
) else (
    echo [✓] Ollama is running (llama3.1 available)
)

echo [*] Starting Spring Boot Backend...
echo.
cd /d "%~dp0backend"
if exist "build\libs\smartdairy-backend-1.0.0.jar" (
    "C:\Program Files\Java\jdk-23\bin\java.exe" -jar build\libs\smartdairy-backend-1.0.0.jar
) else (
    call gradlew.bat bootRun
)

pause
