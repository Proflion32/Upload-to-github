@echo off
setlocal enabledelayedexpansion

title GitHub File Uploader

:menu
cls
echo.
echo ========== GitHub File Uploader ==========
echo.

set /p repo="Enter GitHub Repository URL (e.g., https://github.com/username/repo.git): "

if "!repo!"=="" (
    echo Error: Repository URL cannot be empty.
    timeout /t 2 >nul
    goto menu
)

echo.
echo Select file to upload (paste full file path and press Enter):
set /p filepath="File path: "

if not exist "!filepath!" (
    echo Error: File does not exist.
    timeout /t 2 >nul
    goto menu
)

echo.
set /p message="Enter commit message (optional, press Enter for default): "
if "!message!"=="" set message=Upload file via GitUploader

echo.
echo Starting upload process...
echo.

REM Create temporary directory
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c%%a%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set tempdir=%TEMP%\git_upload_%mydate%_%mytime%

mkdir "!tempdir!"
cd /d "!tempdir!"

echo [1/4] Cloning repository...
git clone "!repo!" .
if errorlevel 1 (
    echo Error: Failed to clone repository
    pause
    exit /b 1
)

echo [2/4] Copying file...
for %%F in ("!filepath!") do (
    set filename=%%~nxF
)
copy "!filepath!" "!filename!" >nul
if errorlevel 1 (
    echo Error: Failed to copy file
    pause
    exit /b 1
)

echo [3/4] Committing changes...
git add "!filename!"
git commit -m "!message!"
if errorlevel 1 (
    echo Error: Failed to commit
    pause
    exit /b 1
)

echo [4/4] Pushing to GitHub...
git push
if errorlevel 1 (
    echo Error: Failed to push
    pause
    exit /b 1
)

echo.
echo ========== SUCCESS ==========
echo File uploaded successfully!
echo.
pause

REM Cleanup
cd ..
rmdir /s /q "!tempdir!"
