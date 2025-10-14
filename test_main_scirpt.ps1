# test_main_script.ps1
# Testing the main script

$main = ".\main_script.ps1"
$LogDir = "$env:USERPROFILE\log"
$BackupDir = "$env:USERPROFILE\backup"

# --- Preparation ---
Write-Host "Cleaning up the test environment..."
Remove-Item -Recurse -Force $LogDir, $BackupDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $LogDir, $BackupDir | Out-Null

# --- Creating test files ---
Write-Host "Creating 5 files in $LogDir..."
for ($i = 1; $i -le 5; $i++) {
    $filePath = Join-Path $LogDir "file_$i.log"
    $data = "Test log file $i " * 50000
    Set-Content $filePath $data
}

# --- Running the main script ---
Write-Host "`nRunning the main script..."
powershell -ExecutionPolicy Bypass -File $main -LogDir $LogDir -BackupDir $BackupDir -Threshold 0.00001 -M 3

# --- Checking results ---
Write-Host "`nChecking results..."
$archiveCount = (Get-ChildItem $BackupDir -Filter "*.zip").Count
if ($archiveCount -gt 0) { 
    Write-Host "Test 1: Archive successfully created." 
} else { 
    Write-Host "Test 1: Archive was not created." 
}

$logCount = (Get-ChildItem $LogDir -File).Count
if ($logCount -lt 5) { 
    Write-Host "Test 2: Old files were deleted ($logCount remaining)." 
} else { 
    Write-Host "Test 2: Files were not deleted." 
}

if (Test-Path (Join-Path $BackupDir "archive.log")) {
    Write-Host "Test 3: Archive log file was created."
} else {
    Write-Host "Test 3: Archive log file is missing."
}

# --- Checking restoration ---
Write-Host "`nDeleting all files and testing restoration..."
Remove-Item (Join-Path $LogDir "*") -Force
powershell -ExecutionPolicy Bypass -File $main -LogDir $LogDir -BackupDir $BackupDir -Threshold 0.00001 -M 3
$restoredCount = (Get-ChildItem $LogDir -File).Count
if ($restoredCount -gt 0) {
    Write-Host "Test 4: Files successfully restored ($restoredCount)."
} else {
    Write-Host "Test 4: Files were not restored."
}

Write-Host "`nTesting completed."