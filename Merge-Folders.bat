@echo off
set /p OLD="Enter (or drag and drop) the OLD folder path, then press enter: "
set /p NEW="Enter (or drag and drop) the NEW folder path, then press enter: "

echo.
echo Starting Merge...
powershell.exe -ExecutionPolicy Bypass -File ".\Merge-Folders.ps1" -OldDir "%OLD%" -NewDir "%NEW%"

echo.
echo Process Finished.
pause