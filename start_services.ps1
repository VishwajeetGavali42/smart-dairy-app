# Smart Dairy Backend & AI Microservice Launcher
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "       Starting Smart Dairy Full-Stack Ecosystem          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Start Python AI Microservice (FastAPI on Port 8000)
Write-Host "[1/3] Starting Python AI Microservice (Port 8000)..." -ForegroundColor Yellow
Start-Process -FilePath "python" -ArgumentList "-m uvicorn main:app --host 0.0.0.0 --port 8000" -WorkingDirectory "$baseDir\ai_service"

# 2. Start Spring Boot Backend Server (Port 8080)
Write-Host "[2/3] Starting Spring Boot Backend Server (Port 8080)..." -ForegroundColor Yellow
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "gradlew.bat bootRun" -WorkingDirectory "$baseDir\backend"

# 3. Setup ADB Reverse Proxy for Android Emulator
Write-Host "[3/3] Setting up ADB port forwarding..." -ForegroundColor Yellow
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (Test-Path $adbPath) {
    & $adbPath reverse tcp:8080 tcp:8080
    & $adbPath reverse tcp:8000 tcp:8000
    Write-Host "ADB reverse proxy enabled for ports 8080 & 8000." -ForegroundColor Green
} else {
    Write-Host "ADB not found in default path; skipping adb reverse." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Services Started Successfully!                          " -ForegroundColor Green
Write-Host "  - Spring Boot Backend: http://localhost:8080            " -ForegroundColor White
Write-Host "  - H2 Database Console: http://localhost:8080/h2-console " -ForegroundColor White
Write-Host "  - Python AI Service:   http://localhost:8000/docs       " -ForegroundColor White
Write-Host "  - Demo Users:          owner / employee / admin         " -ForegroundColor White
Write-Host "  - Default Password:    password                         " -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
