@echo off
echo ========================================
echo  Dream City RP - Authentication Server
echo ========================================
echo.

REM Check if node_modules exists
if not exist "node_modules\" (
    echo [INFO] Installing dependencies...
    call npm install
    echo.
)

REM Check if .env exists
if not exist ".env" (
    echo [WARNING] .env file not found!
    echo [INFO] Creating .env from .env.example...
    copy .env.example .env
    echo.
    echo [ACTION REQUIRED] Please edit .env file and add your:
    echo   - STEAM_API_KEY
    echo   - DB_PASSWORD
    echo.
    echo Press any key to open .env file...
    pause >nul
    notepad .env
    echo.
)

echo [INFO] Starting Dream City RP Authentication Server...
echo [INFO] Server will run on http://localhost:3000
echo [INFO] Press Ctrl+C to stop the server
echo.
echo ========================================
echo.

node server.js

pause
