param(
    [Parameter(Mandatory = $true)][string]$Summary,
    [Parameter(Mandatory = $true)][string]$Details,
    [Parameter(Mandatory = $true)][string[]]$Paths
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $today = Get-Date -Format 'yyyy-MM-dd'
    $old = Get-Content -LiteralPath 'CHANGELOG.md' -Raw
    $entry = "## $today — $Summary`r`n`r`n- $Details`r`n`r`n"
    $new = $old -replace '^# 更新记录\r?\n\r?\n', "# 更新记录`r`n`r`n$entry"
    Set-Content -LiteralPath 'CHANGELOG.md' -Value $new -Encoding utf8
    git add -- 'CHANGELOG.md'
    foreach ($path in $Paths) { git add -- $path }
    git commit -m $Summary
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed; changes were not published' }
    git fetch origin main
    if ($LASTEXITCODE -ne 0) { throw 'Could not verify GitHub push' }
    $localHead = git rev-parse HEAD
    $remoteHead = git rev-parse origin/main
    if ($localHead -ne $remoteHead) { throw 'Commit exists locally but push did not reach GitHub' }
    Write-Output "Published: $localHead"
} finally { Pop-Location }
