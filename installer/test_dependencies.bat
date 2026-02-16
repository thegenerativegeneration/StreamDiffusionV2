@echo off
setlocal enabledelayedexpansion
title StreamDiffusionV2 - Dependency Dry Run Test

echo ============================================================
echo  StreamDiffusionV2 Dependency Dry Run Test
echo ============================================================
echo.
echo This verifies that all pip dependencies can be resolved
echo without actually installing anything.
echo.

:: Use build Python if available, otherwise fall back to system Python
set "PYTHON=%~dp0build\python\python.exe"
if not exist "!PYTHON!" (
    where python >nul 2>&1
    if errorlevel 1 (
        echo ERROR: No Python found. Run build_installer.bat first, or install Python.
        pause
        exit /b 1
    )
    for /f "delims=" %%p in ('where python') do set "PYTHON=%%p"
    echo NOTE: Using system Python: !PYTHON!
) else (
    echo Using build Python: !PYTHON!
)
"!PYTHON!" --version
echo.

:: Upgrade pip first
echo Upgrading pip...
"!PYTHON!" -m pip install --upgrade pip --timeout 60
echo.

set "FAIL=0"
set "PIP_TIMEOUT=120"

echo [1/5] Testing PyTorch + CUDA 12.4 resolution...
echo.
"!PYTHON!" -m pip install --dry-run --timeout !PIP_TIMEOUT! torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple
if errorlevel 1 (
    echo.
    echo FAIL: PyTorch dependency resolution failed.
    set "FAIL=1"
) else (
    echo OK
)
echo.

echo [2/5] Testing flash-attn prebuilt wheel resolution...
echo.
"!PYTHON!" -m pip install --dry-run --timeout !PIP_TIMEOUT! https://github.com/sdbds/flash-attention-for-windows/releases/download/311%%2Btorch260%%2Bcu126/flash_attn-2.7.4.post1%%2Bcu126torch2.6.0cxx11abiFALSEfullbackward-cp311-cp311-win_amd64.whl
if errorlevel 1 (
    echo.
    echo WARN: flash-attn resolution failed (optional, non-fatal^).
) else (
    echo OK
)
echo.

echo [3/5] Testing xformers resolution...
echo.
"!PYTHON!" -m pip install --dry-run --timeout !PIP_TIMEOUT! xformers==0.0.29.post3 --index-url https://download.pytorch.org/whl/cu124 --extra-index-url https://pypi.org/simple
if errorlevel 1 (
    echo.
    echo WARN: xformers resolution failed (optional, non-fatal^).
) else (
    echo OK
)
echo.

echo [4/5] Testing requirements-win.txt resolution...
echo.
"!PYTHON!" -m pip install --dry-run --timeout !PIP_TIMEOUT! -r "%~dp0scripts\requirements-win.txt"
if errorlevel 1 (
    echo.
    echo FAIL: requirements-win.txt dependency resolution failed.
    set "FAIL=1"
) else (
    echo OK
)
echo.

echo [5/5] Testing setup.py resolution...
echo.
"!PYTHON!" -m pip install --dry-run --timeout !PIP_TIMEOUT! -e "%~dp0.."
if errorlevel 1 (
    echo.
    echo FAIL: setup.py dependency resolution failed.
    set "FAIL=1"
) else (
    echo OK
)
echo.

echo ============================================================
if "!FAIL!"=="1" (
    echo  RESULT: Some dependency checks FAILED. Fix before building.
) else (
    echo  RESULT: All dependency checks passed.
)
echo ============================================================
echo.
pause
