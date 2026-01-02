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

# Helper function to log to file AND display in console
function Write-Log {
    param (
        [string]$Message,
        [ConsoleColor]$Color = "White"
    )
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $LogEntry = "$Timestamp : $Message"
    
    # Save to file
    $LogEntry | Out-File -FilePath $FullLogPath -Append
    
    # Write to console
    Write-Host $LogEntry -ForegroundColor $Color
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
        Write-Log "Created Folder: $RelativePath" -Color Yellow
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
            # CONFLICT: Compare dates
            if ($FileInOld.LastWriteTime -gt $FileInNew.LastWriteTime) {
                Copy-Item $FileInOld.FullName -Destination (Join-Path $CurrentDest $FileName) -Force
                Write-Log "CONFLICT: Kept OLD version of $FileName (Newer date)" -Color Cyan
            }
            else {
                Copy-Item $FileInNew.FullName -Destination (Join-Path $CurrentDest $FileName) -Force
                Write-Log "CONFLICT: Kept NEW version of $FileName (Newer date)" -Color Cyan
            }
        }
        elseif ($FileInOld) {
            Copy-Item $FileInOld.FullName -Destination (Join-Path $CurrentDest $FileName)
            Write-Log "UNIQUE (Old): $RelativeFilePath" -Color Green
        }
        else {
            Copy-Item $FileInNew.FullName -Destination (Join-Path $CurrentDest $FileName)
            Write-Log "UNIQUE (New): $RelativeFilePath" -Color Green
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

# START EXECUTION
Write-Host "Starting merge... Results will be in: $CombinedDir" -ForegroundColor Gray
Write-Host "------------------------------------------------------------"

try {
    Sync-Directories -SourceDir $OldDir -TargetDir $NewDir
    Write-Log "--- Merge Completed Successfully ---" -Color White
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)" -Color Red
}