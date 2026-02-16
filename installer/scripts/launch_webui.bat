@echo off
setlocal enabledelayedexpansion
title StreamDiffusionV2 - Web UI

:: Determine install directory (script is in %INSTALL_DIR%\scripts\)
for %%i in ("%~dp0..") do set "INSTALL_DIR=%%~fi"
set "PYTHON=%INSTALL_DIR%\python\python.exe"
set "APP_DIR=%INSTALL_DIR%\app"

:: Check Python exists
if not exist "!PYTHON!" (
    echo ERROR: Python not found. Please reinstall StreamDiffusionV2.
    pause
    exit /b 1
)

:: Check environment is set up (torch must be installed)
"!PYTHON!" -c "import torch" 2>nul
if errorlevel 1 (
    echo ERROR: Python environment is not set up.
    echo Please run "Setup Environment" from the Start Menu first.
    pause
    exit /b 1
)

:: Auto-detect which model is available
:: Models are stored under app/ since the code resolves paths relative to app/
set "MODEL_TYPE="
set "CONFIG_PATH="
set "CKPT_FOLDER="

:: Check for 14B model first (prefer larger if both exist)
if exist "!APP_DIR!\wan_models\Wan2.1-T2V-14B\config.json" (
    if exist "!APP_DIR!\ckpts\wan_causal_dmd_v2v_14b\model.pt" (
        set "MODEL_TYPE=T2V-14B"
        set "CONFIG_PATH=!APP_DIR!\configs\wan_causal_dmd_v2v_14b.yaml"
        set "CKPT_FOLDER=!APP_DIR!\ckpts\wan_causal_dmd_v2v_14b"
    )
)

:: Check for 1.3B model
if "!MODEL_TYPE!"=="" (
    if exist "!APP_DIR!\wan_models\Wan2.1-T2V-1.3B\config.json" (
        if exist "!APP_DIR!\ckpts\wan_causal_dmd_v2v\model.pt" (
            set "MODEL_TYPE=T2V-1.3B"
            set "CONFIG_PATH=!APP_DIR!\configs\wan_causal_dmd_v2v.yaml"
            set "CKPT_FOLDER=!APP_DIR!\ckpts\wan_causal_dmd_v2v"
        )
    )
)

if "!MODEL_TYPE!"=="" (
    echo ERROR: No models found.
    echo Please run "Download Models" from the Start Menu first.
    pause
    exit /b 1
)

echo ============================================================
echo  StreamDiffusionV2 Web UI
echo ============================================================
echo.
echo Model: !MODEL_TYPE!
echo Config: !CONFIG_PATH!
echo.
echo Starting server on http://localhost:7860
echo Press Ctrl+C to stop.
echo.

:: Open browser after a delay (before the blocking server call)
start "" cmd /c "ping -n 6 127.0.0.1 >nul && start http://localhost:7860"

:: Embedded Python doesn't add script dir to sys.path; set PYTHONPATH
set "PYTHONPATH=!APP_DIR!\demo"

:: Launch the web UI
cd /d "!APP_DIR!\demo"
"!PYTHON!" main.py --port 7860 --host 127.0.0.1 --num_gpus 1 --step 2 --config_path "!CONFIG_PATH!" --checkpoint_folder "!CKPT_FOLDER!" --model_type !MODEL_TYPE!

pause
