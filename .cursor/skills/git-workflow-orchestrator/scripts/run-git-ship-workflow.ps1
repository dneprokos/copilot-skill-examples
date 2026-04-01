param(
    [string]$BranchName,
    [switch]$SkipBranch,
    [Parameter(Mandatory)]
    [string]$CommitMessage,
    [string]$BaseBranch = 'main',
    [string]$PrBase = 'main',
    [switch]$ApproveInstall,
    [switch]$ApproveAuth,
    [switch]$AllowDuplicatePrefix,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-PhaseHeader {
    param(
        [int]$PhaseNum,
        [string]$Title
    )

    Write-Host ''
    Write-Host ("=== Phase {0}: {1} ===" -f $PhaseNum, $Title)
}

function Invoke-PhaseScript {
    param(
        [int]$PhaseNumber,
        [string]$Title,
        [string[]]$PwshArguments
    )

    Write-PhaseHeader -PhaseNum $PhaseNumber -Title $Title

    $output = & pwsh @PwshArguments 2>&1
    $exitCode = $LASTEXITCODE

    $text = ($output | ForEach-Object { "$_" }) -join "`n"
    if (-not [string]::IsNullOrWhiteSpace($text)) {
        Write-Host $text
    }

    if ($exitCode -ne 0) {
        Write-Host "Phase ${PhaseNumber}: FAILED (exit $exitCode)"
        exit $exitCode
    }

    Write-Host "Phase ${PhaseNumber}: SUCCESS"
    return $text
}

function Get-PrUrlFromOutput {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    $matches = [regex]::Matches($Text, 'https://github\.com/[^\s\)\"'']+')
    if ($matches.Count -eq 0) {
        return $null
    }

    return $matches[$matches.Count - 1].Value
}

if (-not $SkipBranch -and [string]::IsNullOrWhiteSpace($BranchName)) {
    Write-Host 'BranchName is required unless -SkipBranch is set.'
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Git is not available in this environment.'
    exit 1
}

if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Host 'pwsh is required to invoke skill scripts.'
    exit 1
}

$repoRootOutput = & git rev-parse --show-toplevel 2>$null
if (-not $? -or [string]::IsNullOrWhiteSpace($repoRootOutput)) {
    Write-Host 'This script must be run inside a Git repository.'
    exit 1
}

$repoRoot = (($repoRootOutput | Select-Object -First 1) | Out-String).Trim()
$skillsRoot = Join-Path $repoRoot '.github/skills'

$branchScript = Join-Path $skillsRoot 'git-branch-creator/scripts/create-branch.ps1'
$commitScript = Join-Path $skillsRoot 'git-commit-creator/scripts/create-commit.ps1'
$pushScript = Join-Path $skillsRoot 'git-push-creator/scripts/push-branch.ps1'
$prScript = Join-Path $skillsRoot 'git-pr-creator/scripts/create-pr.ps1'

foreach ($path in @($branchScript, $commitScript, $pushScript, $prScript)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Host "Missing script: $path"
        exit 1
    }
}

$accumulatedOutput = New-Object System.Collections.Generic.List[string]

if (-not $SkipBranch) {
    $branchArgs = @(
        '-NoProfile',
        '-File', $branchScript,
        '-BranchName', $BranchName,
        '-BaseBranch', $BaseBranch
    )
    if ($DryRun) {
        $branchArgs += '-DryRun'
    }

    $phaseOut = Invoke-PhaseScript -PhaseNumber 1 -Title 'Branch' -PwshArguments $branchArgs
    if ($null -ne $phaseOut) {
        [void]$accumulatedOutput.Add($phaseOut)
    }
}
else {
    Write-PhaseHeader -PhaseNum 1 -Title 'Branch'
    Write-Host 'SKIPPED (-SkipBranch)'
    Write-Host 'Phase 1: SUCCESS'
}

$commitArgs = @(
    '-NoProfile',
    '-File', $commitScript,
    '-StageAll',
    '-CommitMessage', $CommitMessage
)
if ($DryRun) {
    $commitArgs += '-DryRun'
}

$commitOut = Invoke-PhaseScript -PhaseNumber 2 -Title 'Commit' -PwshArguments $commitArgs
if ($null -ne $commitOut) {
    [void]$accumulatedOutput.Add($commitOut)
}

$pushArgs = @('-NoProfile', '-File', $pushScript)
if ($DryRun) {
    $pushArgs += '-DryRun'
}

$pushOut = Invoke-PhaseScript -PhaseNumber 3 -Title 'Push' -PwshArguments $pushArgs
if ($null -ne $pushOut) {
    [void]$accumulatedOutput.Add($pushOut)
}

$prArgs = @(
    '-NoProfile',
    '-File', $prScript,
    '-BaseBranch', $PrBase
)
if ($DryRun) {
    $prArgs += '-DryRun'
}
if ($AllowDuplicatePrefix) {
    $prArgs += '-AllowDuplicatePrefix'
}
if ($ApproveInstall) {
    $prArgs += '-ApproveInstall'
}
if ($ApproveAuth) {
    $prArgs += '-ApproveAuth'
}

$prOut = Invoke-PhaseScript -PhaseNumber 4 -Title 'Pull request' -PwshArguments $prArgs
if ($null -ne $prOut) {
    [void]$accumulatedOutput.Add($prOut)
}

$combined = ($accumulatedOutput | Where-Object { $_ } | ForEach-Object { "$_" }) -join "`n"
$prUrl = Get-PrUrlFromOutput -Text $combined

Write-Host ''
Write-Host '=== Workflow summary ==='
if ($DryRun) {
    Write-Host 'Dry run completed; no PR was created if phases only previewed.'
}

if (-not [string]::IsNullOrWhiteSpace($prUrl)) {
    Write-Host "PR_URL: $prUrl"
    Write-Output "PR_URL: $prUrl"
}
else {
    Write-Host 'PR_URL: (not detected in output; check Phase 4 log above)'
}
