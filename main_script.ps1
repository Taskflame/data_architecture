# main_script.ps1
# Log archiving script for Windows PowerShell

param(
    [string]$LogDir = "$env:USERPROFILE\log",
    [string]$BackupDir = "$env:USERPROFILE\backup",
    [double]$Threshold = 0.0000001,   # threshold (%) for archiving
    [int]$M = 3,                      # number of files to archive
    [int]$RestoreCount = 2            # number of files to restore
)

# --- Create directories ---
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }

# --- Calculate folder and disk size ---
$dirSizeMB = [math]::Round((Get-ChildItem -Recurse -Force $LogDir | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
$disk = Get-PSDrive -Name (Get-Item $LogDir).PSDrive.Name
$diskSizeMB = [math]::Round((($disk.Used + $disk.Free) / 1MB), 2)
$percent = [math]::Round(($dirSizeMB / $diskSizeMB) * 100, 6)

Write-Host "Log folder size: $dirSizeMB MB"
Write-Host "Disk size: $diskSizeMB MB"
Write-Host "Folder occupies: $percent% of total disk space"

# --- Force trigger for testing (optional) ---
# $percent = 5   # uncomment to force archiving for demo

# --- Check threshold ---
if ($percent -gt $Threshold) {
    Write-Host "Threshold $Threshold% exceeded. Archiving $M oldest files..."

    $files = Get-ChildItem $LogDir -File | Sort-Object LastWriteTime | Select-Object -First $M
    if (-not $files) {
        Write-Host "No files found for archiving."
        exit
    }

    $archiveName = "log_backup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').zip"
    $archivePath = Join-Path $BackupDir $archiveName

    Compress-Archive -Path ($files.FullName) -DestinationPath $archivePath -Force

    if (Test-Path $archivePath) {
        Write-Host "Archive created: $archivePath"
        foreach ($f in $files) {
            Remove-Item $f.FullName -Force
            Write-Host "Deleted: $($f.Name)"
        }

        $logLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Archive: $archiveName - Deleted: $($files.Count) files - Folder used $percent%"
        $logFile = Join-Path $BackupDir "archive.log"
        $logLine | Out-File -Append $logFile
    }
    else {
        Write-Host "Error: archive was not created."
    }
}
else {
    Write-Host "Folder size ≤ $Threshold%. Archiving is not required."
}

# --- Restoration check ---
$logCount = (Get-ChildItem $LogDir -File -ErrorAction SilentlyContinue).Count
if ($logCount -eq 0) {
    Write-Host "The folder is empty. Attempting to restore from the latest archive..."

    $lastArchive = Get-ChildItem $BackupDir -Filter "*.zip" -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $lastArchive) {
        Write-Host "No archives found for restoration."
        exit
    }

    Expand-Archive -Path $lastArchive.FullName -DestinationPath $LogDir -Force
    Write-Host "Files successfully restored from: $($lastArchive.Name)"
}