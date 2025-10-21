@echo off
REM Check if at least one argument is provided
if "%~1"=="" (
    echo Usage: watch command [arguments]
    goto :eof
)

:loop
cls
REM Execute the provided command with all arguments
%*
REM Wait for 5 seconds without displaying the countdown
timeout /t 2 >nul
goto loop
