@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title CuteVoice Studio - EXE Builder

echo ==========================================
echo   CuteVoice Studio - EXE Builder
echo ==========================================
echo.

rem Prefer a normal installed Python launcher; some portable D:\python.exe builds
rem report ensurepip success but do not expose site-packages to `import pip`.
set "PY="
where py >nul 2>&1
if not errorlevel 1 (
  py -3 --version >nul 2>&1
  if not errorlevel 1 (
    py -3 -c "import sys; print(sys.executable)" >nul 2>&1
    if not errorlevel 1 set "PY=py -3"
  )
)
if not defined PY (
  where python >nul 2>&1
  if not errorlevel 1 (
    python --version >nul 2>&1
    if not errorlevel 1 set "PY=python"
  )
)
if not defined PY if exist "D:\python.exe" set "PY=D:\python.exe"
if not defined PY (
  echo ERROR: Python nahi mila. Python 3.10+ install karo.
  goto failed
)

echo [1/4] Python aur pip check...
%PY% --version
if errorlevel 1 goto failed

%PY% -c "import sys; print('Interpreter:',sys.executable); print('Python path:',sys.path)"
%PY% -c "import pip; print('pip',pip.__version__)" >nul 2>&1
if errorlevel 1 (
  echo Pip import nahi ho raha. Built-in ensurepip se repair kar rahe hain...
  %PY% -m ensurepip --upgrade
  %PY% -c "import pip; print('pip',pip.__version__)" >nul 2>&1
  if errorlevel 1 (
    echo ERROR: Is Python installation me pip accessible nahi hai.
    echo Current interpreter: %PY%
    echo Agar py -3 available hai, builder usko prefer karega. Python.org installer use karna best rahega.
    goto failed
  )
)
%PY% -m pip --version
if errorlevel 1 goto failed

echo Pip ready.
echo.
echo [2/4] Build tools aur audio packages install/check...
%PY% -m pip install --upgrade pip setuptools wheel
if errorlevel 1 goto failed
%PY% -m pip install --upgrade pyinstaller numpy sounddevice pedalboard
if errorlevel 1 goto failed

echo.
echo [3/4] Purana build saaf...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist CuteVoiceStudio.spec del /q CuteVoiceStudio.spec

echo.
echo [4/4] GUI EXE build ho raha hai (console window nahi hogi)...
%PY% -m PyInstaller --noconfirm --clean --onefile --windowed --name CuteVoiceStudio --collect-all numpy --collect-all sounddevice --collect-all pedalboard --hidden-import=audio_io --hidden-import=engine --hidden-import=winperf app.py
if errorlevel 1 goto failed

if not exist "dist\CuteVoiceStudio.exe" goto failed

echo.
echo SUCCESS! EXE yahan bana hai:
echo %CD%\dist\CuteVoiceStudio.exe
echo Is EXE par double-click karo. CMD console window nahi khulegi.
echo.
pause
exit /b 0

:failed
echo.
echo BUILD FAILED. Upar ka exact error copy karke bhejo.
echo.
pause
exit /b 1
