@echo off
TITLE PCRM Enterprise - Desktop Launcher
COLOR 0A

echo ==============================================================================
echo              PCRM Enterprise - Desktop Work Management System
echo ==============================================================================
echo.

cd /d "%~dp0"

:: 1. Check Python Virtual Environment
if not exist "backend\venv\Scripts\python.exe" (
    echo [*] Setting up virtual environment...
    python -m venv backend\venv
    backend\venv\Scripts\pip.exe install -r backend\requirements.txt
)

:: 2. Database Migrations & Seed Data
echo [*] Checking database migrations...
set DB_ENGINE=sqlite
backend\venv\Scripts\python.exe backend\manage.py migrate --noinput >nul 2>&1
backend\venv\Scripts\python.exe backend\manage.py seed_phase1_data >nul 2>&1
backend\venv\Scripts\python.exe backend\manage.py seed_phase2_templates >nul 2>&1

:: 3. Check if Backend is already responding
echo [*] Verifying backend server status on http://127.0.0.1:8000 ...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/' -UseBasicParsing -TimeoutSec 2; exit 0 } catch { exit 1 }" >nul 2>&1

if %errorlevel% neq 0 (
    echo [*] Starting backend server in background...
    start "PCRM Backend Server" /min cmd /c "cd /d %~dp0 && set DB_ENGINE=sqlite && backend\venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000"
    timeout /t 3 /nobreak >nul
) else (
    echo [*] Backend server is already running!
)

:: 4. Launch Desktop App Window
echo.
echo ==============================================================================
echo [*] Launching PCRM Desktop App on http://127.0.0.1:8000/app/
echo ==============================================================================
echo.

:: Try opening as standalone Chrome app window, otherwise default browser
where chrome >nul 2>nul
if %errorlevel% equ 0 (
    start chrome --app=http://127.0.0.1:8000/app/
) else (
    start http://127.0.0.1:8000/app/
)

echo [SUCCESS] PCRM Desktop App is running!
ping 127.0.0.1 -n 3 >nul
