@echo off
setlocal DisableDelayedExpansion
set "DSI_ARGC=0"
:collect_args
if "%~1"=="" goto run
set "DSI_ARG_%DSI_ARGC%=%~1"
set /a DSI_ARGC+=1 >nul
shift
goto collect_args
:run
set "DSI_PS1=%~dp0dsi.ps1"
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& $env:DSI_PS1"
exit /b %errorlevel%
