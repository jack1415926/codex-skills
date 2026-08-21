[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Source,
    [Parameter(Mandatory)]
    [string]$Skill
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'sources.json') | ConvertFrom-Json
$definition = $config.sources | Where-Object { $_.id -eq $Source } | Select-Object -First 1
if (-not $definition) { throw "Unknown source: $Source" }

$sourceSkill = Join-Path $definition.checkout (Join-Path $definition.skill_path $Skill)
$skillFile = Join-Path $sourceSkill 'SKILL.md'
if (-not (Test-Path -LiteralPath $skillFile)) {
    throw "No SKILL.md for '$Skill' in '$Source': $sourceSkill"
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stageRoot = Join-Path $repoRoot (Join-Path 'staging' (Join-Path $timestamp (Join-Path $Source $Skill)))
New-Item -ItemType Directory -Path (Split-Path -Parent $stageRoot) -Force | Out-Null
Copy-Item -LiteralPath $sourceSkill -Destination $stageRoot -Recurse

$commit = (& git -C $definition.checkout rev-parse HEAD).Trim()
$note = [ordered]@{
    source = $Source
    remote = $definition.remote
    revision = $commit
    skill = $Skill
    staged_at = (Get-Date).ToString('o')
} | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $stageRoot 'SOURCE.json') -Value $note -Encoding utf8

Write-Output "Staged: $stageRoot"
Write-Output "Review: git diff --no-index -- C:\\Users\\ROG\\.codex\\skills\\$Skill $stageRoot"
