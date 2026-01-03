param (
    [Parameter(Mandatory=$true)] [string]$OldDir,
    [Parameter(Mandatory=$true)] [string]$NewDir,
    [string]$ParentPath,
    [string]$CombinedFolderName = "CombinedDir"
)

# 1. Setup Paths properly
# If no ParentPath was provided, default to where the script is located
if ([string]::IsNullOrWhiteSpace($ParentPath)) {
    $ParentPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    if ([string]::IsNullOrWhiteSpace($ParentPath)) { $ParentPath = Get-Location }
}

# Combine the chosen parent directory with the chosen name
$CombinedDir = "$ParentPath\$CombinedFolderName"

# 2. Create Combined Directory if it doesn't exist
if (!(Test-Path -Path "$CombinedDir")) { 
    New-Item -ItemType Directory -Path "$CombinedDir" -Force | Out-Null 
}

$LogFile = "$CombinedDir\MergeLog.txt"
"--- Merge Started at $(Get-Date) ---" | Out-File -FilePath $LogFile

function Write-Log {
    param ([string]$Message, [ConsoleColor]$Color = "White")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $LogEntry = "$Timestamp : $Message"
    $LogEntry | Out-File -FilePath $LogFile -Append
    Write-Host $LogEntry -ForegroundColor $Color
}

function Sync-Directories {
    param ($SourceDir, $TargetDir, $RelativePath)
    
    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        $CurrentDest = $CombinedDir
    } else {
        $CurrentDest = "$CombinedDir\$RelativePath"
    }
    
    if (!(Test-Path -Path "$CurrentDest")) { 
        New-Item -ItemType Directory -Path "$CurrentDest" -Force | Out-Null
        Write-Log "Created Folder: $RelativePath" -Color Yellow
    }

    $OldItems = if (Test-Path -Path "$SourceDir") { Get-ChildItem -Path "$SourceDir" } else { @() }
    $NewItems = if (Test-Path -Path "$TargetDir") { Get-ChildItem -Path "$TargetDir" } else { @() }

    $OldFiles = $OldItems | Where-Object { !$_.PSIsContainer }
    $NewFiles = $NewItems | Where-Object { !$_.PSIsContainer }
    $AllFileNames = ($OldFiles.Name + $NewFiles.Name) | Select-Object -Unique

    foreach ($FileName in $AllFileNames) {
        $FileInOld = $OldFiles | Where-Object { $_.Name -eq $FileName }
        $FileInNew = $NewFiles | Where-Object { $_.Name -eq $FileName }
        $DestFilePath = "$CurrentDest\$FileName"

        if ($FileInOld -and $FileInNew) {
            if ($FileInOld.LastWriteTime -gt $FileInNew.LastWriteTime) {
                Copy-Item -Path "$($FileInOld.FullName)" -Destination "$DestFilePath" -Force
                Write-Log "CONFLICT: Kept OLD version of $FileName" -Color Cyan
            } else {
                Copy-Item -Path "$($FileInNew.FullName)" -Destination "$DestFilePath" -Force
                Write-Log "CONFLICT: Kept NEW version of $FileName" -Color Cyan
            }
        } elseif ($FileInOld) {
            Copy-Item -Path "$($FileInOld.FullName)" -Destination "$DestFilePath" -Force
            Write-Log "UNIQUE (Old): $FileName" -Color Green
        } else {
            Copy-Item -Path "$($FileInNew.FullName)" -Destination "$DestFilePath" -Force
            Write-Log "UNIQUE (New): $FileName" -Color Green
        }
    }

    $OldSubDirs = $OldItems | Where-Object { $_.PSIsContainer }
    $NewSubDirs = $NewItems | Where-Object { $_.PSIsContainer }
    $AllSubDirNames = ($OldSubDirs.Name + $NewSubDirs.Name) | Select-Object -Unique
    foreach ($SubDirName in $AllSubDirNames) {
        $NextRelative = if ([string]::IsNullOrWhiteSpace($RelativePath)) { $SubDirName } else { "$RelativePath\$SubDirName" }
        Sync-Directories -SourceDir "$SourceDir\$SubDirName" -TargetDir "$TargetDir\$SubDirName" -RelativePath $NextRelative
    }
}

try {
    Write-Log "Starting Merge..." -Color White
    Sync-Directories -SourceDir "$OldDir" -TargetDir "$NewDir" -RelativePath ""
    Write-Host "`n--- FINISHED ---" -ForegroundColor Magenta
    explorer.exe "$CombinedDir"
} catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)" -Color Red
}