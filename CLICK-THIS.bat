@echo off
setlocal

:: 1. Get Old and New folder paths
set /p OLD_IN="1. Drag and drop the OLD folder path: "
set /p NEW_IN="2. Drag and drop the NEW folder path: "

:: 2. Get the Parent Directory for the output
set /p TARGET_PATH="3. Drag and drop the DIRECTORY where the result should be created: "

:: 3. Get the custom name (Default if empty)
set "TARGET_NAME=CombinedDir"
set /p USER_NAME="4. Type the name for the new folder (or press Enter for 'CombinedDir'): "
if not "%USER_NAME%"=="" set "TARGET_NAME=%USER_NAME%"

:: 4. Strip quotes from all paths
set "OLD_IN=%OLD_IN:"=%"
set "NEW_IN=%NEW_IN:"=%"
set "TARGET_PATH=%TARGET_PATH:"=%"

echo.
echo Starting Merge Process...
echo Target: %TARGET_PATH%\%TARGET_NAME%
echo ------------------------------------------------------------

:: 5. Launch with the new parameters
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0Merge-Folders.ps1' -OldDir '%OLD_IN%' -NewDir '%NEW_IN%' -ParentPath '%TARGET_PATH%' -CombinedFolderName '%TARGET_NAME%'}"

echo.
pause