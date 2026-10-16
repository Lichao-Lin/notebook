---
name: pc-maintenance
description: Automated personal computer maintenance and health monitoring. Use this skill whenever the user asks to clean up their PC, check system health, free up disk space, monitor performance, optimize startup, run maintenance tasks, or diagnose sluggish performance. Also trigger when the user mentions "电脑运维", "系统清理", "磁盘清理", "性能检查", "开机加速", "系统优化", "电脑检查", or wants to do routine PC care.
---

# PC Auto-Maintenance

Automatically diagnose, clean, and optimize a Windows personal computer. Runs inventory checks, identifies waste, and applies safe fixes — explaining every action before taking it.

## Workflow

When invoked, first run a full system inventory, then present findings in a dashboard format. Let the user decide what to clean/fix. Never delete user files or change system settings without confirmation.

### Phase 1: System Inventory (read-only, always safe)

Run these diagnostics in parallel:

**Disk Usage:**
```powershell
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{N='Used(GB)';E={[math]::Round(($_.Used/1GB),1)}}, @{N='Free(GB)';E={[math]::Round(($_.Free/1GB),1)}}, @{N='Total(GB)';E={[math]::Round(($_.Used+$_.Free)/1GB,1)}} | Format-Table -AutoSize
```

**Top 10 Disk-Consuming Folders (User Profile):**
```powershell
Get-ChildItem -Path $env:USERPROFILE -Directory -ErrorAction SilentlyContinue | ForEach-Object { $size = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; [PSCustomObject]@{Folder=$_.Name; SizeGB=[math]::Round($size/1GB,2)} } | Sort-Object SizeGB -Descending | Select-Object -First 10 | Format-Table -AutoSize
```

**System Info:**
```powershell
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$mem = Get-CimInstance Win32_ComputerSystem
Write-Host "=== System Overview ==="
Write-Host "OS: $($os.Caption) (Build $($os.BuildNumber))"
Write-Host "Last Boot: $($os.LastBootUpTime)"
Write-Host "Uptime: $([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)) days"
Write-Host "CPU: $($cpu.Name.Trim())"
Write-Host "RAM: $([math]::Round($mem.TotalPhysicalMemory/1GB,1)) GB total"
Write-Host "Free RAM: $([math]::Round(($os.FreePhysicalMemory/1MB),1)) GB"
Write-Host "Processes: $((Get-Process).Count)"
```

**Startup Programs:**
```powershell
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, User | Format-List
```

### Phase 2: Waste Identification (read-only)

**Temp files:**
```powershell
$paths = @($env:TEMP, "C:\Windows\Temp", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache")
foreach ($p in $paths) {
    if (Test-Path $p) {
        $size = (Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "$p : $([math]::Round($size/1MB,1)) MB"
    }
}
```

**Recycle Bin:**
```powershell
$shell = New-Object -ComObject Shell.Application
$bin = $shell.Namespace(0xA)
$items = $bin.Items()
Write-Host "Recycle Bin: $($items.Count) items"
```

**Browser Cache (Chrome/Edge):**
```powershell
$browserPaths = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
)
foreach ($p in $browserPaths) {
    if (Test-Path $p) {
        $s = (Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Write-Host "$p : $([math]::Round($s/1MB,1)) MB"
    }
}
```

**Windows Update Cache:**
```powershell
$wu = "C:\Windows\SoftwareDistribution\Download"
if (Test-Path $wu) {
    $s = (Get-ChildItem -Path $wu -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Write-Host "Windows Update Cache: $([math]::Round($s/1MB,1)) MB"
}
```

### Phase 3: Present Dashboard

Summarize findings in a concise table:

```
┌─────────────────────────────────────────────┐
│           PC HEALTH DASHBOARD               │
├────────────┬──────────┬──────────┬─────────┤
│ Disk       │ Used     │ Free     │ Health  │
├────────────┼──────────┼──────────┼─────────┤
│ C:         │ XXX GB   │ XXX GB   │ OK/WARN │
├────────────┴──────────┴──────────┴─────────┤
│ Top space consumers:                        │
│  1. AppData     XX GB                       │
│  2. .m2         XX GB                       │
│  3. ...                                      │
├─────────────────────────────────────────────┤
│ Waste Found:                                │
│  Temp files:    XXX MB                      │
│  Browser cache: XXX MB                      │
│  Win Update:    XXX MB                      │
│  Recycle Bin:   XX items                    │
├─────────────────────────────────────────────┤
│ Memory:  XX/YY GB (XX% free)                │
│ Uptime:  X days                             │
│ Startup: XX programs                        │
└─────────────────────────────────────────────┘
```

### Phase 4: Recommended Actions (user confirms each)

Based on severity, propose actions with explanation:

| Action | Command | Risk |
|--------|---------|------|
| Clear temp files | `scripts/disk_cleanup.ps1 -WhatIf` first | Low |
| Empty Recycle Bin | `Clear-RecycleBin -Force` | Low |
| Clear browser cache | Manual via browser | Low |
| Clear Windows Update cache | `scripts/disk_cleanup.ps1` | Low |
| Run Disk Cleanup | `cleanmgr /sagerun:1` | Low |
| Disable startup programs | Task Manager > Startup | Medium |

**Never do these without explicit user request:**
- Registry cleaning
- Driver updates
- Defrag (SSDs don't need it)
- Third-party "cleaner" tools

### Phase 5: Performance Recommendations

After cleanup, analyze and suggest:

- **RAM < 20% free**: Recommend closing memory-heavy apps or upgrading RAM
- **Disk < 10% free**: Urgent — recommend immediate cleanup or larger drive
- **Uptime > 7 days**: Suggest reboot to clear memory leaks
- **Startup > 10 items**: Flag for review; each item adds ~2-5s to boot time
- **CPU temp high**: Suggest cleaning fans/vents (cannot check via script)

### Phase 6: Scheduled Maintenance Setup (optional)

Offer to create a scheduled task for automatic cleanup:
```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File `"$PSScriptRoot\scripts\disk_cleanup.ps1`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
Register-ScheduledTask -TaskName "PCMaintenance-Weekly" -Action $action -Trigger $trigger -Description "Weekly disk cleanup"
```

## Script Usage

Bundled scripts can be run directly:

- **Disk Cleanup**: `powershell -File scripts/disk_cleanup.ps1`
- **System Health**: `powershell -File scripts/system_health.ps1`
- **Performance Check**: `powershell -File scripts/performance_check.ps1`

Each script has a `-WhatIf` mode for safe preview.

## Important Rules

1. **Always explain before executing** — tell the user what you're about to do and why
2. **Never delete user files** — only clear known-safe temp/cache locations
3. **Confirm destructive actions** — ask before clearing Recycle Bin, browser cache, or large temp sets
4. **Don't touch registry** — registries are fragile; avoid unless the user specifically asks
5. **SSD-awareness** — never suggest defrag for SSDs (check with `Get-PhysicalDisk | Select MediaType`)
6. **Respect privacy** — don't read file contents, only enumerate sizes and counts
