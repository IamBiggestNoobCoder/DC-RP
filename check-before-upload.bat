@echo off
echo ========================================
echo  GitHub Upload Safety Check
echo ========================================
echo.

echo [1/4] Checking for .env file...
if exist ".env" (
    echo   [WARNING] .env file exists locally - This is OK!
    echo   [INFO] .gitignore will prevent it from being uploaded
) else (
    echo   [OK] No .env file found
)
echo.

echo [2/4] Checking for .env.example...
if exist ".env.example" (
    echo   [OK] .env.example exists - Safe to upload
) else (
    echo   [WARNING] .env.example not found
)
echo.

echo [3/4] Checking for .gitignore...
if exist ".gitignore" (
    echo   [OK] .gitignore exists
    findstr /C:".env" .gitignore >nul
    if %errorlevel% equ 0 (
        echo   [OK] .env is in .gitignore - Protected!
    ) else (
        echo   [ERROR] .env NOT in .gitignore - ADD IT NOW!
    )
) else (
    echo   [ERROR] .gitignore NOT found - CREATE IT!
)
echo.

echo [4/4] Checking for node_modules...
if exist "node_modules\" (
    echo   [INFO] node_modules exists locally
    findstr /C:"node_modules" .gitignore >nul
    if %errorlevel% equ 0 (
        echo   [OK] node_modules is in .gitignore - Protected!
    ) else (
        echo   [WARNING] node_modules NOT in .gitignore
    )
) else (
    echo   [OK] No node_modules folder
)
echo.

echo ========================================
echo  Safety Check Complete!
echo ========================================
echo.
echo IMPORTANT REMINDERS:
echo   1. Never commit .env file
echo   2. Only commit .env.example
echo   3. Remove any hardcoded API keys
echo   4. Check git status before pushing
echo.
echo If all checks passed, you're ready to upload!
echo.

pause
