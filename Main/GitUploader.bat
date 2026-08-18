@echo off
setlocal enabledelayedexpansion

title GitHub File Uploader

:menu
cls
echo.
echo ========== GitHub File Uploader ==========
echo.

set /p repo="Enter GitHub Repository URL (e.g., https://github.com/username/repo.git): "
set repo=!repo:"=!

if "!repo!"=="" (
    echo Error: Repository URL cannot be empty.
    timeout /t 2 >nul
    goto menu
)

echo.
echo What do you want to upload?
echo   [1] A single file
echo   [2] An entire folder
echo.
set /p choice="Choice (1 or 2): "

set isdir=0
if "!choice!"=="2" set isdir=1

echo.
echo Opening the picker... (if you don't see it, check behind this window)
if !isdir!==1 (
    call :pickfolder
) else (
    call :pickfile
)

if "!srcpath!"=="" (
    echo No selection made - cancelled.
    timeout /t 2 >nul
    goto menu
)

if "!srcpath:~-1!"=="\" set srcpath=!srcpath:~0,-1!

echo Selected: !srcpath!
echo.
set /p message="Enter commit message (optional, press Enter for default): "
if "!message!"=="" set message=Upload via GitUploader

echo.
echo Starting upload process...
echo.

set tempdir=%TEMP%\git_upload_%RANDOM%%RANDOM%
mkdir "!tempdir!"
pushd "!tempdir!"

echo [1/4] Cloning repository...
git clone "!repo!" .
if errorlevel 1 (
    echo Error: Failed to clone repository
    goto fail
)

echo [2/4] Copying content...
if !isdir!==1 (
    robocopy "!srcpath!" "!tempdir!" /E /XD .git >nul
    if errorlevel 8 (
        echo Error: Failed to copy folder
        goto fail
    )
) else (
    for %%F in ("!srcpath!") do set filename=%%~nxF
    copy /y "!srcpath!" "!filename!" >nul
    if errorlevel 1 (
        echo Error: Failed to copy file
        goto fail
    )
)

echo [3/4] Committing changes...
git add -A
git diff --cached --quiet
if not errorlevel 1 (
    echo Nothing to commit - the repo already matches your local content.
    goto done
)
git commit -m "!message!"
if errorlevel 1 (
    echo Error: Failed to commit
    goto fail
)

echo [4/4] Pushing to GitHub...
git push
if errorlevel 1 (
    echo Error: Failed to push
    goto fail
)

:done
echo.
echo ========== SUCCESS ==========
echo.
popd
rmdir /s /q "!tempdir!"
pause
exit /b 0

:fail
echo.
popd
rmdir /s /q "!tempdir!" 2>nul
pause
exit /b 1


REM ---------- Explorer picker helpers ----------

:pickfile
set "srcpath="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $owner = New-Object System.Windows.Forms.Form -Property @{TopMost=$true}; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select the file to upload'; $d.InitialDirectory = [Environment]::GetFolderPath('Desktop'); if ($d.ShowDialog($owner) -eq 'OK') { $d.FileName }"`) do set "srcpath=%%I"
goto :eof

:pickfolder
set "srcpath="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $owner = New-Object System.Windows.Forms.Form -Property @{TopMost=$true}; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Select the folder to upload'; $d.SelectedPath = [Environment]::GetFolderPath('Desktop'); if ($d.ShowDialog($owner) -eq 'OK') { $d.SelectedPath }"`) do set "srcpath=%%I"
goto :eof
