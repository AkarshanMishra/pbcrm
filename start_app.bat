@echo off
TITLE PCRM Enterprise - Master Launcher
COLOR 0B

echo ==============================================================================
echo                PCRM - Advanced Secure Employee Management System
echo ==============================================================================
echo.

cd /d "%~dp0"

:: 1. Backend Virtual Environment Check
if not exist "backend\venv\Scripts\python.exe" (
    echo [*] Virtual environment not found. Setting up backend\venv...
    python -m venv backend\venv
    if errorlevel 1 (
        echo [ERROR] Python is not installed or not added to PATH.
        pause
        exit /b 1
    )
    echo [*] Installing backend dependencies...
    backend\venv\Scripts\pip.exe install -r backend\requirements.txt
)

:: 2. Environment Configuration
if not exist ".env" (
    echo [*] Creating .env from .env.example...
    copy .env.example .env >nul
)

:: 3. Database Migrations & Seed Data
echo [*] Applying database migrations...
set DB_ENGINE=sqlite
backend\venv\Scripts\python.exe backend\manage.py migrate --noinput
backend\venv\Scripts\python.exe backend\manage.py seed_phase1_data
backend\venv\Scripts\python.exe backend\manage.py seed_phase2_templates

:: 4. Start Backend Server
echo.
echo ==============================================================================
echo [*] Launching Django REST API on http://127.0.0.1:8000
echo [*] PCRM Desktop App: http://127.0.0.1:8000/app/
echo [*] Interactive API Docs: http://127.0.0.1:8000/api/docs/
echo ==============================================================================
echo.

start "PCRM Backend Server" cmd /k "cd /d %~dp0 && set DB_ENGINE=sqlite && backend\venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000"

:: Wait 3 seconds for server startup
timeout /t 3 /nobreak >nul

:: Open Desktop App and API documentation
start http://127.0.0.1:8000/app/

echo.
echo [SUCCESS] PCRM system is running!
echo Press any key to exit this launcher window (server will stay running).
pause >nul
