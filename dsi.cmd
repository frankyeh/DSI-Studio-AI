@echo off
setlocal DisableDelayedExpansion
rem resolve before the shift loop below: shift moves %0, so a later %~dp0 resolves the first argument instead
set "DSI_PS1=%~dp0dsi.ps1"
set "DSI_ARGC=0"
:collect_args
if "%~1"=="" goto run
set "DSI_ARG_%DSI_ARGC%=%~1"
set /a DSI_ARGC+=1 >nul
shift
goto collect_args
:run
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "& $env:DSI_PS1"
exit /b %errorlevel%
