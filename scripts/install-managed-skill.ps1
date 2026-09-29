[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Skill,
    [switch]$Replace
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'sources.json') | ConvertFrom-Json
$source = Join-Path $repoRoot (Join-Path 'skills' $Skill)
$sourceFile = Join-Path $source 'SKILL.md'
$target = Join-Path $config.managed_install_root $Skill
$targetFile = Join-Path $target 'SKILL.md'

if (-not (Test-Path -LiteralPath $sourceFile)) { throw "Managed skill not found: $Skill" }
$head = Get-Content -LiteralPath $sourceFile -TotalCount 30
$name = (($head | Where-Object { $_ -match '^name:' } | Select-Object -First 1) -replace '^name:\s*["'']?', '' -replace '["'']?\s*$', '').Trim()
if ($name -ne $Skill) { throw "Folder/frontmatter mismatch: $Skill / $name" }

if (Test-Path -LiteralPath $target) {
    if (-not $Replace) { throw "Installed skill exists; rerun with -Replace after reviewing its diff: $target" }
    $backupRoot = Join-Path $config.managed_install_root '.backups'
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backup = Join-Path $backupRoot "$Skill-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Move-Item -LiteralPath $target -Destination $backup
    Write-Output "Backup: $backup"
}

Copy-Item -LiteralPath $source -Destination $target -Recurse
if (-not (Test-Path -LiteralPath $targetFile)) { throw "Install verification failed: $targetFile" }
Write-Output "Installed: $target"
