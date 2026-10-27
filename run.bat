@echo off
rem ============================================================
rem  DouK-Downloader - Windows launcher
rem
rem  First run : creates .venv and installs requirements.txt
rem  Next runs : starts the program immediately
rem
rem  Usage:
rem    run.bat                start
rem    run.bat --reinstall    force reinstall dependencies
rem ============================================================

setlocal EnableExtensions
chcp 65001 >nul 2>&1
for /f "tokens=2 delims=:" %%a in ('chcp') do set "OLDCP=%%a"
set "OLDCP=%OLDCP: =%"
title DouK-Downloader

cd /d "%~dp0"
if errorlevel 1 (
    echo [ERROR] Cannot open the script directory.
    goto :fail
)

if not exist "main.py" (
    echo [ERROR] main.py not found. Put this file in the project root.
    goto :fail
)
if not exist "requirements.txt" (
    echo [ERROR] requirements.txt not found.
    goto :fail
)

set "VENV=.venv"
set "PY=%VENV%\Scripts\python.exe"
set "STAMP=%VENV%\.deps-ok"

rem ---------- 1. virtual environment --------------------------
if exist "%PY%" goto :deps

echo [1/2] Creating virtual environment "%VENV%" ...

set "BASE_PY="
py -3.13 --version >nul 2>&1
if not errorlevel 1 set "BASE_PY=py -3.13"

if not defined BASE_PY (
    py -3.12 --version >nul 2>&1
    if not errorlevel 1 set "BASE_PY=py -3.12"
)
if not defined BASE_PY (
    py -3 --version >nul 2>&1
    if not errorlevel 1 set "BASE_PY=py -3"
)
if not defined BASE_PY (
    python --version >nul 2>&1
    if not errorlevel 1 set "BASE_PY=python"
)

if not defined BASE_PY (
    echo [ERROR] Python 3.12 or newer was not found.
    echo         Install it from https://www.python.org/downloads/
    echo         and enable "Add python.exe to PATH".
    goto :fail
)

echo       Interpreter : %BASE_PY%
%BASE_PY% -m venv "%VENV%"
if not exist "%PY%" (
    echo [ERROR] Could not create the virtual environment.
    goto :fail
)

rem ---------- 2. dependencies --------------------------------
:deps
if /i "%~1"=="--reinstall" (
    echo [2/2] Forcing dependency reinstall ...
    del /q "%STAMP%" 2>nul
)

if exist "%STAMP%" goto :run

echo [2/2] Installing dependencies, please wait ...
"%PY%" -m pip install --upgrade pip --quiet --disable-pip-version-check
"%PY%" -m pip install -r requirements.txt --disable-pip-version-check
if errorlevel 1 (
    echo [ERROR] Dependency installation failed.
    echo         Check your network or proxy settings, then run again.
    goto :fail
)
echo ok>"%STAMP%"
echo       Dependencies installed.

rem ---------- 3. start ---------------------------------------
:run
set "PYTHONIOENCODING=utf-8"
set "PYTHONUTF8=1"
echo.
"%PY%" main.py %*
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo [ERROR] Program exited with code %RC%.
    goto :fail
)

echo.
echo Program closed normally.
if not defined NO_PAUSE pause
if defined OLDCP chcp %OLDCP% >nul 2>&1
exit /b 0

:fail
echo.
if not defined NO_PAUSE pause
if defined OLDCP chcp %OLDCP% >nul 2>&1
exit /b 1
