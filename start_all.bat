@echo off
title Smart Dairy Backend ^& AI Microservice Launcher
echo ==========================================================
echo        Starting Smart Dairy Full-Stack Ecosystem          
echo ==========================================================

echo [1/3] Starting Python AI Microservice (Port 8000)...
start "Smart Dairy AI Service" /D "%~dp0ai_service" cmd /k python -m uvicorn main:app --host 0.0.0.0 --port 8000

echo [2/3] Starting Spring Boot Backend Server (Port 8080)...
start "Smart Dairy Backend Server" /D "%~dp0backend" cmd /k gradlew.bat bootRun

echo [3/3] Setting up ADB port forwarding...
if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
    "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" reverse tcp:8000 tcp:8000
    echo ADB reverse proxy enabled for ports 8080 and 8000.
)

echo.
echo ==========================================================
echo   Services Launched!
echo   - Spring Boot Backend: http://localhost:8080
echo   - H2 Database Console: http://localhost:8080/h2-console
echo   - Python AI Swagger:   http://localhost:8000/docs
echo   - Demo Users:          owner / employee / accountant / admin
echo   - Password:            password
echo ==========================================================
pause
