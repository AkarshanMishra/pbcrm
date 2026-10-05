@echo off
TITLE PCRM Backend API
COLOR 0A

cd /d "%~dp0"
set DB_ENGINE=sqlite

echo [*] Starting PCRM Backend Server...
echo [*] Swagger UI: http://127.0.0.1:8000/api/docs/
echo [*] Redoc UI:   http://127.0.0.1:8000/api/redoc/
echo.

backend\venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000
pause
