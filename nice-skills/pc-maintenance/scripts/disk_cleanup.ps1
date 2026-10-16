<#
.SYNOPSIS
    Safe disk cleanup for Windows — clears temp files, caches, and logs.
.DESCRIPTION
    Targets: %TEMP%, Windows\Temp, browser caches (Chrome/Edge), Windows Update
    cache, Prefetch, and Recycle Bin. Every section prints its savings.
.PARAMETER WhatIf
    Preview mode — shows what WOULD be deleted without actually removing anything.
.PARAMETER SkipRecycleBin
    Skip emptying the Recycle Bin (safer for first-time runs).
.PARAMETER SkipBrowserCache
    Skip clearing Chrome and Edge caches.
.EXAMPLE
    .\disk_cleanup.ps1 -WhatIf
.EXAMPLE
    .\disk_cleanup.ps1 -SkipRecycleBin
#>

param(
    [switch]$WhatIf,
    [switch]$SkipRecycleBin,
    [switch]$SkipBrowserCache
)

$ErrorActionPreference = "Stop"
$totalFreed = 0
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Disk Cleanup — $timestamp" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "  *** WHATIF MODE — nothing will be deleted ***`n" -ForegroundColor Yellow
}

# ---- Helper: measure and clean a directory ----
function Clear-Directory {
    param(
        [string]$Path,
        [string]$Label,
        [switch]$Recurse = $true
    )

    if (-not (Test-Path $Path)) {
        Write-Host "  SKIP: $Label — path not found: $Path" -ForegroundColor DarkGray
        return
    }

    $items = if ($Recurse) {
        Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
    } else {
        Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
    }

    if (-not $items) {
        Write-Host "  OK:   $Label — already empty" -ForegroundColor Green
        return
    }

    $sizeBytes = ($items | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($sizeBytes / 1MB, 1)
    $count = $items.Count

    if ($WhatIf) {
        Write-Host "  WHATIF: $Label — would delete $count files ($sizeMB MB)" -ForegroundColor Yellow
        return
    }

    try {
        $items | Remove-Item -Force -ErrorAction Stop
        $script:totalFreed += $sizeBytes
        Write-Host "  DONE:  $Label — deleted $count files ($sizeMB MB)" -ForegroundColor Green
    } catch {
        Write-Host "  WARN:  $Label — some files locked, skipped" -ForegroundColor DarkYellow
    }
}

# ---- 1. User Temp ----
Clear-Directory -Path $env:TEMP -Label "User Temp (%TEMP%)"

# ---- 2. System Temp ----
Clear-Directory -Path "C:\Windows\Temp" -Label "System Temp (C:\Windows\Temp)"

# ---- 3. Prefetch ----
Clear-Directory -Path "C:\Windows\Prefetch" -Label "Prefetch"

# ---- 4. Windows Update cache ----
Clear-Directory -Path "C:\Windows\SoftwareDistribution\Download" -Label "Windows Update cache"

# ---- 5. Delivery Optimization cache ----
Clear-Directory -Path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache" -Label "Delivery Optimization cache"

# ---- 6. Browser caches ----
if (-not $SkipBrowserCache) {
    $browserCaches = @(
        @{Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\Cache_Data"; Name="Chrome cache"},
        @{Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\Cache_Data"; Name="Edge cache"}
    )
    foreach ($bc in $browserCaches) {
        Clear-Directory -Path $bc.Path -Label $bc.Name
    }
}

# ---- 7. Recycle Bin ----
if (-not $SkipRecycleBin) {
    if ($WhatIf) {
        $shell = New-Object -ComObject Shell.Application
        $bin = $shell.Namespace(0xA)
        Write-Host "  WHATIF: Recycle Bin — $($bin.Items().Count) items would be emptied" -ForegroundColor Yellow
    } else {
        try {
            $shell = New-Object -ComObject Shell.Application
            $count = $shell.Namespace(0xA).Items().Count
            Clear-RecycleBin -Force -ErrorAction Stop
            Write-Host "  DONE:  Recycle Bin — $count items emptied" -ForegroundColor Green
        } catch {
            Write-Host "  WARN:  Recycle Bin — could not empty" -ForegroundColor DarkYellow
        }
    }
}

# ---- Summary ----
$totalMB = [math]::Round($totalFreed / 1MB, 1)
Write-Host "`n========================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "  WhatIf complete — run without -WhatIf to clean" -ForegroundColor Yellow
} else {
    Write-Host "  Total freed: $totalMB MB" -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan
