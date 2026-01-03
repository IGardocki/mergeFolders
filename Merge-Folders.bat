@echo off
setlocal

:: 1. Get input
set /p OLD_IN="Enter (or drag and drop) the OLD folder path: "
set /p NEW_IN="Enter (or drag and drop) the NEW folder path: "

:: 2. Strip quotes if the user dragged them in
set "OLD_IN=%OLD_IN:"=%"
set "NEW_IN=%NEW_IN:"=%"

echo.
echo Starting Merge Process...
echo ------------------------------------------------------------

:: 3. The "Double-Quote" handoff
:: We wrap the entire command in an extra set of quotes to protect the inner ones
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0Merge-Folders.ps1' -OldDir '%OLD_IN%' -NewDir '%NEW_IN%'}"

echo.
echo If the merge finished, you can close this window.
pause