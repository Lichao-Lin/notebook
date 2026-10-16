<#
.SYNOPSIS
    Quick system health check — disk, RAM, CPU, boot time, and SMART status.
.DESCRIPTION
    Prints a one-page health report. Non-destructive, read-only.
.EXAMPLE
    .\system_health.ps1
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SYSTEM HEALTH REPORT" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ---- OS Info ----
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
Write-Host "[ OS ]" -ForegroundColor Yellow
Write-Host "  Name:    $($os.Caption)"
Write-Host "  Build:   $($os.BuildNumber)"
Write-Host "  Uptime:  $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
Write-Host ""

# ---- CPU ----
$cpu = Get-CimInstance Win32_Processor
$cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
Write-Host "[ CPU ]" -ForegroundColor Yellow
Write-Host "  Model:        $($cpu.Name.Trim())"
Write-Host "  Cores:        $($cpu.NumberOfCores) ($($cpu.NumberOfLogicalProcessors) logical)"
Write-Host "  Current Load: $cpuLoad%"
Write-Host ""

# ---- RAM ----
$cs = Get-CimInstance Win32_ComputerSystem
$totalRAM = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$usedRAM = [math]::Round($totalRAM - $freeRAM, 1)
$ramPct = [math]::Round(($freeRAM / $totalRAM) * 100, 1)
Write-Host "[ RAM ]" -ForegroundColor Yellow
Write-Host "  Total: $totalRAM GB  |  Used: $usedRAM GB  |  Free: $freeRAM GB ($ramPct%)"
if ($ramPct -lt 20) {
    Write-Host "  *** WARNING: Low memory — close unused apps or consider RAM upgrade ***" -ForegroundColor Red
}
Write-Host ""

# ---- Disks ----
Write-Host "[ DISKS ]" -ForegroundColor Yellow
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    $used = [math]::Round($_.Used / 1GB, 1)
    $free = [math]::Round(($_.Free) / 1GB, 1)
    $total = $used + $free
    $pctFree = [math]::Round(($free / $total) * 100, 1)
    $color = if ($pctFree -lt 10) { "Red" } elseif ($pctFree -lt 20) { "Yellow" } else { "Green" }
    Write-Host "  $($_.Name):  Used $used GB / $total GB  |  Free $free GB ($pctFree%)" -ForegroundColor $color
}

# ---- SMART status (basic check via PhysicalDisk) ----
Write-Host ""
Write-Host "[ DISK HEALTH ]" -ForegroundColor Yellow
try {
    $disks = Get-PhysicalDisk -ErrorAction Stop
    foreach ($d in $disks) {
        $statusColor = if ($d.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
        Write-Host "  $($d.FriendlyName) — $($d.MediaType) — $($d.HealthStatus)" -ForegroundColor $statusColor
    }
} catch {
    Write-Host "  Could not query SMART data (may need admin rights)" -ForegroundColor DarkGray
}

# ---- Top memory processes ----
Write-Host ""
Write-Host "[ TOP 5 MEMORY CONSUMERS ]" -ForegroundColor Yellow
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | ForEach-Object {
    $mb = [math]::Round($_.WorkingSet64 / 1MB, 1)
    Write-Host "  $($_.ProcessName) — $mb MB"
}

# ---- Startup programs count ----
Write-Host ""
Write-Host "[ STARTUP ]" -ForegroundColor Yellow
$startupItems = Get-CimInstance Win32_StartupCommand | Where-Object { $_.Command -ne $null }
Write-Host "  Startup programs: $($startupItems.Count)"
if ($startupItems.Count -gt 10) {
    Write-Host "  Consider reviewing — each item adds boot time" -ForegroundColor DarkYellow
    $startupItems | Select-Object -First 5 | ForEach-Object {
        Write-Host "    - $($_.Name)"
    }
    if ($startupItems.Count -gt 5) {
        Write-Host "    ... and $($startupItems.Count - 5) more"
    }
}

# ---- Network ----
Write-Host ""
Write-Host "[ NETWORK ]" -ForegroundColor Yellow
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $adapters) {
    Write-Host "  $($adapter.Name): $($adapter.LinkSpeed)"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Report complete." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
