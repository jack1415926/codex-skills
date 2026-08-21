[CmdletBinding()]
param(
    [switch]$Fetch,
    [string]$Proxy
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'sources.json') | ConvertFrom-Json
$installRoot = $config.managed_install_root

if (-not (Test-Path -LiteralPath $installRoot)) {
    throw "Codex skills directory does not exist: $installRoot"
}

if ($Fetch) {
    if ($Proxy) {
        $env:https_proxy = $Proxy
        $env:http_proxy = $Proxy
    }
    foreach ($source in $config.sources) {
        if (-not (Test-Path -LiteralPath $source.checkout)) {
            Write-Warning "[$($source.id)] checkout unavailable: $($source.checkout)"
            continue
        }
        & git -C $source.checkout fetch --prune
        if ($LASTEXITCODE -ne 0) { throw "Fetch failed: $($source.id)" }
    }
}

$installed = Get-ChildItem -LiteralPath $installRoot -Directory -Force |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }

$invalid = foreach ($skill in $installed) {
    $path = Join-Path $skill.FullName 'SKILL.md'
    $head = Get-Content -LiteralPath $path -TotalCount 40
    $name = ($head | Where-Object { $_ -match '^name:' } | Select-Object -First 1) -replace '^name:\s*["'']?', '' -replace '["'']?\s*$', ''
    if ($head.Count -lt 3 -or $head[0].Trim() -ne '---' -or -not $name -or $name.Trim() -ne $skill.Name) { $skill.Name }
}

Write-Output "Installed direct skills: $($installed.Count)"
if ($invalid) { Write-Warning ('Invalid folder/frontmatter pairs: ' + ($invalid -join ', ')) } else { Write-Output 'Frontmatter: verified' }

foreach ($source in $config.sources) {
    if (-not (Test-Path -LiteralPath $source.checkout)) {
        Write-Warning "[$($source.id)] checkout unavailable"
        continue
    }
    $head = (& git -C $source.checkout rev-parse HEAD).Trim()
    $upstream = (& git -C $source.checkout rev-parse '@{u}').Trim()
    $counts = (& git -C $source.checkout rev-list --left-right --count 'HEAD...@{u}').Trim()
    Write-Output "[$($source.id)] head=$head upstream=$upstream ahead/behind=$counts"
}

$markers = @('claude code', 'claude\\.ai', 'askuserquestion', '\bwebfetch\b', 'subagent_type', '\.claude/')
$hits = foreach ($skill in $installed) {
    $path = Join-Path $skill.FullName 'SKILL.md'
    $text = Get-Content -Raw -LiteralPath $path
    foreach ($marker in $markers) {
        if ($text -match $marker) { [PSCustomObject]@{ Skill = $skill.Name; Marker = $marker } }
    }
}
if ($hits) {
    Write-Output 'Host-specific markers requiring review:'
    $hits | Sort-Object Skill, Marker | Format-Table -AutoSize
} else {
    Write-Output 'Host-specific markers: none found'
}
