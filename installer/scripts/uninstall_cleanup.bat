@echo off
setlocal enabledelayedexpansion

:: Determine install directory (script is in %INSTALL_DIR%\scripts\)
for %%i in ("%~dp0..") do set "INSTALL_DIR=%%~fi"
set "PYTHON_DIR=!INSTALL_DIR!\python"

:: Kill any running Python processes from this installation
for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq python.exe" /FO LIST 2^>nul ^| findstr "PID:"') do (
    wmic process where "ProcessId=%%i" get ExecutablePath 2>nul | findstr /i "!PYTHON_DIR!" >nul 2>&1
    if not errorlevel 1 (
        taskkill /PID %%i /F >nul 2>&1
    )
)

for /f "tokens=2" %%i in ('tasklist /FI "IMAGENAME eq pythonw.exe" /FO LIST 2^>nul ^| findstr "PID:"') do (
    wmic process where "ProcessId=%%i" get ExecutablePath 2>nul | findstr /i "!PYTHON_DIR!" >nul 2>&1
    if not errorlevel 1 (
        taskkill /PID %%i /F >nul 2>&1
    )
)

:: Wait a moment for processes to terminate
timeout /t 2 /nobreak >nul

:: Remove site-packages (large, installed by setup_environment.bat)
if exist "!PYTHON_DIR!\Lib\site-packages" (
    rmdir /s /q "!PYTHON_DIR!\Lib\site-packages" 2>nul
)

:: Remove downloaded models (stored under app/ for code path resolution)
if exist "!INSTALL_DIR!\app\wan_models" (
    rmdir /s /q "!INSTALL_DIR!\app\wan_models" 2>nul
)

:: Remove checkpoints
if exist "!INSTALL_DIR!\app\ckpts" (
    rmdir /s /q "!INSTALL_DIR!\app\ckpts" 2>nul
)

:: Remove any output directories
if exist "!INSTALL_DIR!\app\outputs" (
    rmdir /s /q "!INSTALL_DIR!\app\outputs" 2>nul
)

if exist "!INSTALL_DIR!\app\slo_metrics" (
    rmdir /s /q "!INSTALL_DIR!\app\slo_metrics" 2>nul
)

exit /b 0
