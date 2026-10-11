[CmdletBinding()]
param(
    [switch]$Fetch,
    [string]$Proxy
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$config = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'sources.json') | ConvertFrom-Json
$installRoots = @($config.managed_install_root) + @($config.additional_install_roots)

function Resolve-Checkout([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return Join-Path $repoRoot $Path
}

function Test-SourceFiles([string]$InstalledDir, [string]$SourceDir) {
    foreach ($sourceFile in Get-ChildItem -LiteralPath $SourceDir -Recurse -File) {
        $relative = [System.IO.Path]::GetRelativePath($SourceDir, $sourceFile.FullName)
        $installedFile = Join-Path $InstalledDir $relative
        if (-not (Test-Path -LiteralPath $installedFile)) { return $false }

        if ($sourceFile.Extension -in @('.md', '.txt', '.json', '.yaml', '.yml', '.ps1', '.js', '.ts', '.tsx', '.css')) {
            $sourceText = (Get-Content -Raw -LiteralPath $sourceFile.FullName) -replace "`r`n", "`n"
            $installedText = (Get-Content -Raw -LiteralPath $installedFile) -replace "`r`n", "`n"
            if ($sourceText -ne $installedText) { return $false }
        } elseif ((Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash -ne
                  (Get-FileHash -LiteralPath $installedFile -Algorithm SHA256).Hash) {
            return $false
        }
    }
    return $true
}

foreach ($installRoot in $installRoots) {
    if (-not (Test-Path -LiteralPath $installRoot)) {
        throw "Codex skills directory does not exist: $installRoot"
    }
}

if ($Fetch) {
    if ($Proxy) {
        $env:https_proxy = $Proxy
        $env:http_proxy = $Proxy
    }
    foreach ($source in $config.sources) {
        $checkout = Resolve-Checkout $source.checkout
        if (-not (Test-Path -LiteralPath $checkout)) {
            Write-Warning "[$($source.id)] checkout unavailable: $($source.checkout)"
            continue
        }
        & git -C $checkout fetch --prune
        if ($LASTEXITCODE -ne 0) { throw "Fetch failed: $($source.id)" }
    }
}

$installed = @(
    foreach ($installRoot in $installRoots) {
        Get-ChildItem -LiteralPath $installRoot -Directory -Force |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') }
    }
)

$invalid = foreach ($skill in $installed) {
    $path = Join-Path $skill.FullName 'SKILL.md'
    $head = Get-Content -LiteralPath $path -TotalCount 40
    $name = ($head | Where-Object { $_ -match '^name:' } | Select-Object -First 1) -replace '^name:\s*["'']?', '' -replace '["'']?\s*$', ''
    if ($head.Count -lt 3 -or $head[0].Trim() -ne '---' -or -not $name -or $name.Trim() -ne $skill.Name) { $skill.Name }
}

Write-Output "Installed user skills: $($installed.Count)"
if ($invalid) { Write-Warning ('Invalid folder/frontmatter pairs: ' + ($invalid -join ', ')) } else { Write-Output 'Frontmatter: verified' }

$coverage = foreach ($skill in $installed) {
    $matches = foreach ($source in $config.sources) {
        if ($source.PSObject.Properties.Name -contains 'skills' -and $skill.Name -notin @($source.skills)) { continue }
        $sourceDir = Join-Path (Join-Path (Resolve-Checkout $source.checkout) $source.skill_path) $skill.Name
        if (Test-Path -LiteralPath (Join-Path $sourceDir 'SKILL.md')) {
            [PSCustomObject]@{
                Source = $source.id
                Exact = Test-SourceFiles $skill.FullName $sourceDir
            }
        }
    }

    $localOnly = $skill.Name -in @($config.local_only)
    $override = $skill.Name -in @($config.local_overrides | ForEach-Object skill)
    $status = if ($matches.Exact -contains $true) { 'source-matched' }
              elseif ($override -or $localOnly) { 'local-reviewed' }
              elseif ($matches) { 'source-diverged' }
              else { 'unregistered' }
    [PSCustomObject]@{ Skill = $skill.Name; Status = $status; Sources = ($matches.Source -join ',') }
}

Write-Output 'Source coverage:'
$coverage | Group-Object Status | Sort-Object Name | Select-Object Name, Count | Format-Table -AutoSize
$coverageProblems = $coverage | Where-Object Status -in @('source-diverged', 'unregistered')
if ($coverageProblems) {
    Write-Warning 'Skills requiring source review:'
    $coverageProblems | Format-Table -AutoSize
}

$projectCoverage = foreach ($binding in @($config.project_bindings)) {
    if ($binding.PSObject.Properties.Name -contains 'skill_root') {
        $projectSkillRoot = Join-Path $binding.project $binding.skill_root
        foreach ($name in @($binding.skills)) {
            $installedDir = Join-Path $projectSkillRoot $name
            if (-not (Test-Path -LiteralPath (Join-Path $installedDir 'SKILL.md'))) {
                [PSCustomObject]@{ Skill = $name; Project = $binding.project; Status = 'missing' }
                continue
            }
            $matched = $false
            foreach ($source in $config.sources) {
                if ($source.PSObject.Properties.Name -contains 'skills' -and $name -notin @($source.skills)) { continue }
                $sourceDir = Join-Path (Join-Path (Resolve-Checkout $source.checkout) $source.skill_path) $name
                if (Test-Path -LiteralPath (Join-Path $sourceDir 'SKILL.md')) {
                    if (Test-SourceFiles $installedDir $sourceDir) { $matched = $true; break }
                }
            }
            [PSCustomObject]@{ Skill = $name; Project = $binding.project; Status = if ($matched) { 'source-matched' } else { 'source-diverged' } }
        }
    } else {
        $entrypoint = Join-Path $binding.project $binding.entrypoint
        [PSCustomObject]@{
            Skill = $binding.skill
            Project = $binding.project
            Status = if (Test-Path -LiteralPath $entrypoint) { 'local-reviewed' } else { 'missing' }
        }
    }
}

Write-Output 'Project skill coverage:'
$projectCoverage | Group-Object Status | Sort-Object Name | Select-Object Name, Count | Format-Table -AutoSize
$projectProblems = $projectCoverage | Where-Object Status -in @('missing', 'source-diverged', 'unregistered')
if ($projectProblems) {
    Write-Warning 'Project skills requiring source review:'
    $projectProblems | Format-Table -AutoSize
}

foreach ($source in $config.sources) {
    $checkout = Resolve-Checkout $source.checkout
    if (-not (Test-Path -LiteralPath $checkout)) {
        Write-Warning "[$($source.id)] checkout unavailable"
        continue
    }
    $head = (& git -C $checkout rev-parse HEAD).Trim()
    $upstream = (& git -C $checkout rev-parse '@{u}').Trim()
    $counts = (& git -C $checkout rev-list --left-right --count 'HEAD...@{u}').Trim()
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

if ($invalid -or $coverageProblems -or $projectProblems) { exit 1 }
