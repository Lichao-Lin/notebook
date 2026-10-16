<#
.SYNOPSIS
    Real-time performance snapshot with actionable recommendations.
.DESCRIPTION
    Checks CPU/RAM/Disk pressure, running processes, and suggests optimizations.
    Read-only — no changes made.
.EXAMPLE
    .\performance_check.ps1
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PERFORMANCE SNAPSHOT" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$issues = @()

# ---- CPU Pressure ----
$cpuAvg = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
Write-Host "[ CPU Load: $cpuAvg% ]" -ForegroundColor Yellow
if ($cpuAvg -gt 85) {
    Write-Host "  *** HIGH CPU PRESSURE ***" -ForegroundColor Red
    $issues += "CPU load at $cpuAvg% — check for runaway processes"
} elseif ($cpuAvg -gt 60) {
    Write-Host "  Moderate load — keep an eye on it" -ForegroundColor DarkYellow
} else {
    Write-Host "  Normal" -ForegroundColor Green
}

# Top CPU processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 | ForEach-Object {
    $cpuSec = [math]::Round($_.CPU, 1)
    if ($cpuSec -gt 0) {
        Write-Host "    Top: $($_.ProcessName) — $cpuSec s CPU time"
    }
}
Write-Host ""

# ---- RAM Pressure ----
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$ramPctFree = [math]::Round(($freeRAM / $totalRAM) * 100, 1)
Write-Host "[ RAM: $freeRAM GB free / $totalRAM GB total ($ramPctFree%) ]" -ForegroundColor Yellow
if ($ramPctFree -lt 15) {
    Write-Host "  *** CRITICAL: RAM nearly exhausted ***" -ForegroundColor Red
    $issues += "Free RAM below 15% — close heavy apps or consider RAM upgrade"
} elseif ($ramPctFree -lt 25) {
    Write-Host "  Low memory — close unused apps" -ForegroundColor DarkYellow
    $issues += "Free RAM below 25%"
} else {
    Write-Host "  Normal" -ForegroundColor Green
}
Write-Host ""

# ---- Disk I/O ----
Write-Host "[ DISK ]" -ForegroundColor Yellow
$disks = Get-PhysicalDisk
foreach ($disk in $disks) {
    $healthIcon = if ($disk.HealthStatus -eq "Healthy") { "[OK]" } else { "[!!]" }
    Write-Host "  $healthIcon $($disk.FriendlyName) — $($disk.MediaType) — $($disk.HealthStatus)"
}
# Check page file usage
$pageFile = Get-CimInstance Win32_PageFileUsage
if ($pageFile) {
    $pfMB = [math]::Round($pageFile.CurrentUsage / 1MB, 0)
    if ($pfMB -gt 4096) {
        Write-Host "  Pagefile usage: $pfMB MB (high — indicates RAM pressure)" -ForegroundColor DarkYellow
    }
}
Write-Host ""

# ---- Process Count ----
$procCount = (Get-Process).Count
Write-Host "[ PROCESSES ]" -ForegroundColor Yellow
Write-Host "  Total: $procCount"
if ($procCount -gt 300) {
    Write-Host "  High process count — some may be background bloat" -ForegroundColor DarkYellow
    $issues += "High process count ($procCount)"
} else {
    Write-Host "  Normal" -ForegroundColor Green
}
Write-Host ""

# ---- Uptime ----
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeDays = [math]::Round($uptime.TotalDays, 1)
Write-Host "[ UPTIME: $uptimeDays days ]" -ForegroundColor Yellow
if ($uptimeDays -gt 10) {
    Write-Host "  Consider a reboot to clear memory leaks and pending updates" -ForegroundColor DarkYellow
    $issues += "Uptime exceeds 10 days"
} else {
    Write-Host "  Normal" -ForegroundColor Green
}
Write-Host ""

# ---- Pending Reboot ----
$pending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
if ($pending) {
    Write-Host "[ PENDING REBOOT ]" -ForegroundColor Yellow
    Write-Host "  Windows has pending updates — reboot recommended" -ForegroundColor DarkYellow
    $issues += "Pending reboot required"
    Write-Host ""
}

# ---- Summary ----
Write-Host "========================================" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "  All clear — system looks healthy!" -ForegroundColor Green
} else {
    Write-Host "  RECOMMENDATIONS ($($issues.Count)):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "    * $issue" -ForegroundColor Yellow
    }
}
Write-Host "========================================" -ForegroundColor Cyan
