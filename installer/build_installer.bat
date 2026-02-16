@echo off
setlocal enabledelayedexpansion
title StreamDiffusionV2 - Build Installer

echo ============================================================
echo  StreamDiffusionV2 Installer Builder
echo ============================================================
echo.

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "BUILD_DIR=%SCRIPT_DIR%build"

:: Check prerequisites - find Inno Setup
where ISCC >nul 2>&1
if errorlevel 1 (
    :: Check common install locations
    if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" (
        set "PATH=%LOCALAPPDATA%\Programs\Inno Setup 6;%PATH%"
    ) else if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
        set "PATH=%ProgramFiles(x86)%\Inno Setup 6;%PATH%"
    ) else if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
        set "PATH=%ProgramFiles%\Inno Setup 6;%PATH%"
    ) else (
        echo ERROR: Inno Setup Compiler ^(ISCC.exe^) not found.
        echo Install Inno Setup 6.x from https://jrsoftware.org/isinfo.php
        pause
        exit /b 1
    )
)

where node >nul 2>&1
if errorlevel 1 (
    echo ERROR: Node.js not found in PATH.
    echo Install Node.js 18+ from https://nodejs.org/
    pause
    exit /b 1
)

set "PY_VERSION=3.11.9"
set "PY_ZIP=python-%PY_VERSION%-embed-amd64.zip"
set "PY_URL=https://www.python.org/ftp/python/%PY_VERSION%/%PY_ZIP%"
set "PIP_VERSION=24.3.1"
set "PIP_WHL=pip-%PIP_VERSION%-py3-none-any.whl"
set "PIP_URL=https://files.pythonhosted.org/packages/py3/p/pip/%PIP_WHL%"
set "PY_DIR=%BUILD_DIR%\python"

:: Clean previous build
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"

echo [1/3] Preparing portable Python 3.11...
echo.

:: Download Python embeddable zip if not cached
if not exist "!SCRIPT_DIR!cache\!PY_ZIP!" (
    mkdir "!SCRIPT_DIR!cache" 2>nul
    echo Downloading !PY_URL!...
    curl -L -o "!SCRIPT_DIR!cache\!PY_ZIP!" "!PY_URL!"
    if errorlevel 1 (
        echo ERROR: Failed to download Python.
        pause
        exit /b 1
    )
)

:: Download pip wheel if not cached
if not exist "!SCRIPT_DIR!cache\!PIP_WHL!" (
    echo Downloading pip wheel...
    curl -L -o "!SCRIPT_DIR!cache\!PIP_WHL!" "!PIP_URL!"
    if errorlevel 1 (
        echo ERROR: Failed to download pip wheel.
        pause
        exit /b 1
    )
)

:: Extract Python embeddable zip (no registry, no conflicts)
echo Extracting Python to !PY_DIR!...
mkdir "!PY_DIR!"
powershell -Command "Expand-Archive -Path '!SCRIPT_DIR!cache\!PY_ZIP!' -DestinationPath '!PY_DIR!' -Force"
if errorlevel 1 (
    echo ERROR: Failed to extract Python.
    pause
    exit /b 1
)

:: Enable import site and add Lib\site-packages to path
:: The ._pth file restricts imports by default; we need to enable site-packages
echo Configuring Python paths...
(
    echo python311.zip
    echo .
    echo Lib\site-packages
    echo import site
) > "!PY_DIR!\python311._pth"

:: Create site-packages directory
mkdir "!PY_DIR!\Lib\site-packages" 2>nul

:: Create sitecustomize.py to re-enable PYTHONPATH support
:: (._pth file ignores PYTHONPATH; sitecustomize is loaded by site.py)
(
    echo import sys, os
    echo for p in os.environ.get^('PYTHONPATH', ''^).split^(os.pathsep^):
    echo     if p and p not in sys.path:
    echo         sys.path.insert^(0, p^)
) > "!PY_DIR!\Lib\site-packages\sitecustomize.py"

:: Install pip by extracting the wheel directly into site-packages
:: (A .whl file is a zip archive; PowerShell requires .zip extension)
echo Installing pip...
copy "!SCRIPT_DIR!cache\!PIP_WHL!" "!PY_DIR!\pip.zip" >nul
powershell -Command "Expand-Archive -Path '!PY_DIR!\pip.zip' -DestinationPath '!PY_DIR!\Lib\site-packages' -Force"
if errorlevel 1 (
    echo ERROR: pip installation failed.
    pause
    exit /b 1
)
del "!PY_DIR!\pip.zip"

:: Verify pip works
"!PY_DIR!\python.exe" -m pip --version
if errorlevel 1 (
    echo ERROR: pip not available in installed Python.
    pause
    exit /b 1
)

echo.
echo [2/3] Building frontend...
echo.

cd /d "%PROJECT_DIR%\demo\frontend"
call npm install
if errorlevel 1 (
    echo ERROR: npm install failed.
    pause
    exit /b 1
)

call npm run build
if errorlevel 1 (
    echo ERROR: Frontend build failed.
    pause
    exit /b 1
)

:: Copy built frontend to build directory
:: SvelteKit with adapter-static outputs to build/ directory
set "FRONTEND_SRC=%PROJECT_DIR%\demo\frontend\build"
if not exist "!FRONTEND_SRC!" (
    :: Fallback: check for public directory
    set "FRONTEND_SRC=%PROJECT_DIR%\demo\frontend\public"
)
if not exist "!FRONTEND_SRC!" (
    echo ERROR: Frontend build output not found.
    echo Checked: %PROJECT_DIR%\demo\frontend\build
    echo Checked: %PROJECT_DIR%\demo\frontend\public
    pause
    exit /b 1
)

mkdir "%BUILD_DIR%\frontend_public"
xcopy /s /e /q "!FRONTEND_SRC!\*" "%BUILD_DIR%\frontend_public\"

echo.
echo [3/3] Compiling installer...
echo.

cd /d "%SCRIPT_DIR%"
ISCC StreamDiffusionV2Setup.iss
if errorlevel 1 (
    echo ERROR: Inno Setup compilation failed.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Build complete!
echo  Installer: %SCRIPT_DIR%output\StreamDiffusionV2Setup.exe
echo ============================================================
echo.
pause
