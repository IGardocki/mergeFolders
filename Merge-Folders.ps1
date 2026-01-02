param (
    [Parameter(Mandatory=$true)] [string]$OldDir,
    [Parameter(Mandatory=$true)] [string]$NewDir,
    [string]$CombinedDir = "CombinedDir",
    [string]$LogFile = "MergeLog.txt"
)

# Resolve full path for CombinedDir
$CombinedDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CombinedDir)

if (!(Test-Path $CombinedDir)) { 
    New-Item -ItemType Directory -Path $CombinedDir | Out-Null 
}

$FullLogPath = Join-Path $CombinedDir $LogFile
"--- Merge (Newest File Wins) Started at $(Get-Date) ---" | Out-File -FilePath $FullLogPath
Write-Host "Logging to: $FullLogPath" -ForegroundColor Yellow

function Write-Log {
    param ($Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp : $Message" | Out-File -FilePath $FullLogPath -Append
}

function Sync-Directories {
    param (
        $SourceDir, 
        $TargetDir, 
        $RelativePath = ""
    )

    $CurrentDest = Join-Path $CombinedDir $RelativePath
    if (!(Test-Path $CurrentDest)) { 
        New-Item -ItemType Directory -Path $CurrentDest | Out-Null
        Write-Log "Created Folder: $RelativePath"
    }

    $OldItems = if (Test-Path $SourceDir) { Get-ChildItem -Path $SourceDir } else { @() }
    $NewItems = if (Test-Path $TargetDir) { Get-ChildItem -Path $TargetDir } else { @() }

    # --- 1. PROCESS FILES ---
    $OldFiles = $OldItems | Where-Object { !$_.PSIsContainer }
    $NewFiles = $NewItems | Where-Object { !$_.PSIsContainer }
    $AllFileNames = ($OldFiles.Name + $NewFiles.Name) | Select-Object -Unique

    foreach ($FileName in $AllFileNames) {
        $FileInOld = $OldFiles | Where-Object { $_.Name -eq $FileName }
        $FileInNew = $NewFiles | Where-Object { $_.Name -eq $FileName }
        $RelativeFilePath = Join-Path $RelativePath $FileName

        if ($FileInOld -and $FileInNew) {
            # CONFLICT: Compare Modification Dates
            if ($FileInOld.LastWriteTime -gt $FileInNew.LastWriteTime) {
                Copy-Item $FileInOld.FullName -Destination (Join-Path $CurrentDest $FileName) -Force
                Write-Log "CONFLICT: Kept OLD version of $FileName (Modified: $($FileInOld.LastWriteTime))"
            }
            else {
                Copy-Item $FileInNew.FullName -Destination (Join-Path $CurrentDest $FileName) -Force
                Write-Log "CONFLICT: Kept NEW version of $FileName (Modified: $($FileInNew.LastWriteTime))"
            }
        }
        elseif ($FileInOld) {
            Copy-Item $FileInOld.FullName -Destination (Join-Path $CurrentDest $FileName)
            Write-Log "UNIQUE (Old): Copied $RelativeFilePath"
        }
        else {
            Copy-Item $FileInNew.FullName -Destination (Join-Path $CurrentDest $FileName)
            Write-Log "UNIQUE (New): Copied $RelativeFilePath"
        }
    }

    # --- 2. PROCESS SUBDIRECTORIES (Recursion) ---
    $OldSubDirs = $OldItems | Where-Object { $_.PSIsContainer }
    $NewSubDirs = $NewItems | Where-Object { $_.PSIsContainer }
    $AllSubDirNames = ($OldSubDirs.Name + $NewSubDirs.Name) | Select-Object -Unique

    foreach ($SubDirName in $AllSubDirNames) {
        Sync-Directories `
            -SourceDir (Join-Path $SourceDir $SubDirName) `
            -TargetDir (Join-Path $TargetDir $SubDirName) `
            -RelativePath (Join-Path $RelativePath $SubDirName)
    }
}

try {
    Sync-Directories -SourceDir $OldDir -TargetDir $NewDir
    Write-Log "--- Merge Completed Successfully ---"
    Write-Host "Sync Complete! Result in: $CombinedDir" -ForegroundColor Cyan
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Host "An error occurred. Check the log." -ForegroundColor Red
}