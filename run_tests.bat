@echo off
TITLE PCRM Test Runner
COLOR 0E

cd /d "%~dp0"
set DB_ENGINE=sqlite

echo [*] Running PCRM Automated Pytest Suite...
echo.

backend\venv\Scripts\pytest.exe backend\tests -v

echo.
pause
