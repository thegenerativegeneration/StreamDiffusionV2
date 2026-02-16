@echo off
setlocal
title StreamDiffusionV2 - Model Downloader

:: Determine install directory (script is in %INSTALL_DIR%\scripts\)
for %%i in ("%~dp0..") do set "INSTALL_DIR=%%~fi"
set "PYTHON=%INSTALL_DIR%\python\python.exe"

if not exist "%PYTHON%" (
    echo ERROR: Python not found at %PYTHON%
    echo Please run "Setup Environment" first.
    pause
    exit /b 1
)

"%PYTHON%" "%~dp0download_models.py"
