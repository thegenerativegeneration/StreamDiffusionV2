@echo off
setlocal enabledelayedexpansion
title StreamDiffusionV2 - Environment Setup

echo ============================================================
echo  StreamDiffusionV2 Environment Setup
echo ============================================================
echo.

:: Determine install directory (script is in %INSTALL_DIR%\scripts\)
for %%i in ("%~dp0..") do set "INSTALL_DIR=%%~fi"
set "PYTHON=%INSTALL_DIR%\python\python.exe"
set "APP_DIR=%INSTALL_DIR%\app"

:: Pip timeout in seconds (large packages like PyTorch need time)
set "PIP_TIMEOUT=120"

:: Verify Python exists
if not exist "!PYTHON!" (
    echo ERROR: Python not found at !PYTHON!
    echo Please reinstall StreamDiffusionV2.
    pause
    exit /b 1
)

echo [1/8] Upgrading pip and installing build tools...
echo.
"!PYTHON!" -m pip install --upgrade pip setuptools wheel --timeout !PIP_TIMEOUT!
echo.

echo [2/8] Checking GPU and CUDA prerequisites...
echo.
"!PYTHON!" "%~dp0check_gpu.py"
if errorlevel 1 (
    echo.
    echo WARNING: GPU check failed. You may encounter issues.
    echo Press any key to continue anyway, or close this window to abort.
    pause >nul
)
echo.

echo [3/8] Installing PyTorch with CUDA 12.4 support...
echo This may take several minutes depending on your internet speed.
echo.
"!PYTHON!" -m pip install --timeout !PIP_TIMEOUT! torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple
if errorlevel 1 (
    echo.
    echo ERROR: Failed to install PyTorch. Please check your internet connection.
    pause
    exit /b 1
)
echo.

echo [4/8] Installing flash-attn (prebuilt Windows wheel, optional^)...
echo.
"!PYTHON!" -m pip install --timeout !PIP_TIMEOUT! https://github.com/sdbds/flash-attention-for-windows/releases/download/Python311%%2Btorch260%%2Bcu126/flash_attn-2.7.4.post1%%2Bcu126torch2.6.0cxx11abiFALSEfullbackward-cp311-cp311-win_amd64.whl 2>nul
if errorlevel 1 (
    echo NOTE: flash-attn installation failed. This is expected on some Windows systems.
    echo The application will use a built-in fallback attention mechanism.
    echo.
)

echo [5/8] Installing xformers (optional^)...
echo.
"!PYTHON!" -m pip install --timeout !PIP_TIMEOUT! xformers==0.0.29.post3 --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple 2>nul
if errorlevel 1 (
    echo NOTE: xformers installation failed. This is non-critical.
    echo.
)

echo [6/8] Installing remaining dependencies...
echo.
"!PYTHON!" -m pip install --timeout !PIP_TIMEOUT! -r "%~dp0requirements-win.txt"
if errorlevel 1 (
    echo.
    echo ERROR: Failed to install dependencies.
    pause
    exit /b 1
)
echo.

echo [7/8] Installing StreamDiffusionV2 package...
echo.
pushd "!APP_DIR!"
"!PYTHON!" -m pip install --timeout !PIP_TIMEOUT! -e .
popd
if errorlevel 1 (
    echo.
    echo ERROR: Failed to install StreamDiffusionV2 package.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Environment setup complete!
echo ============================================================
echo.
echo Next step: Run "Download Models" from the Start Menu
echo to download the AI models before launching the Web UI.
echo.
pause
