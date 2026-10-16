# PC Maintenance — Claude Code Skill

A Claude Code skill for automated Windows PC health checks, disk cleanup, and performance monitoring. Combines PowerShell scripts with an interactive AI assistant that explains every action before executing.

## What It Does

- **System inventory** — disk usage, RAM, CPU, uptime, startup programs
- **Waste detection** — temp files, browser caches, Windows Update cache, Recycle Bin
- **Performance analysis** — CPU/RAM pressure, process bloat, disk health (SMART)
- **Safe cleanup** — clears known-safe temp locations with `-WhatIf` preview mode
- **Scheduled maintenance** — optional weekly automated cleanup task

## Quick Start

### 1. Install the Skill

Copy the `pc-maintenance/` folder into `~/.claude/skills/`.

### 2. Trigger It

Just say any of these to Claude Code:

> "帮我清理一下电脑"
> "检查一下系统状态"
> "电脑有点卡，诊断一下"
> "run pc maintenance"
> "free up disk space"

Claude will run the system inventory, present a dashboard, and ask for confirmation before making changes.

## Standalone Scripts

Each script works independently — no Claude required:

| Script | What It Does | Safe? |
|--------|-------------|-------|
| `scripts/system_health.ps1` | Full health report: disk, RAM, CPU, SMART, startup, network | ✅ Read-only |
| `scripts/performance_check.ps1` | Real-time pressure check + recommendations | ✅ Read-only |
| `scripts/disk_cleanup.ps1` | Clears temp/cache/logs with preview mode | ✅ `-WhatIf` safe |

```powershell
# Preview what will be cleaned (no changes)
.\scripts\disk_cleanup.ps1 -WhatIf

# Run cleanup (skip Recycle Bin)
.\scripts\disk_cleanup.ps1 -SkipRecycleBin

# Health report
.\scripts\system_health.ps1

# Performance snapshot
.\scripts\performance_check.ps1
```

## File Structure

```
pc-maintenance/
├── SKILL.md                          # Skill definition (Claude Code)
├── README.md
└── scripts/
    ├── disk_cleanup.ps1              # Safe temp/cache cleaner
    ├── system_health.ps1             # Full system inventory
    └── performance_check.ps1         # Real-time pressure check
```

## Safety Rules

The skill always follows these principles:

1. **Explain first** — never run a command without telling you what it does
2. **Preview mode** — all cleanup scripts support `-WhatIf` to see what would happen
3. **No registry** — never touches the Windows registry
4. **No user files** — only clears known temporary/cache locations
5. **Confirm destructive actions** — asks before emptying Recycle Bin or browser caches
6. **SSD-aware** — never suggests defrag for solid-state drives

## Requirements

- Windows 10 or 11
- PowerShell 5.1+
- Claude Code (for the skill; scripts work standalone)

## License

MIT
