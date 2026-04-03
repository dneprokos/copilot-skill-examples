param(
    [string]$BranchName,
    [switch]$SkipBranch,
    [Parameter(Mandatory)]
    [string]$CommitMessage,
    [string]$BaseBranch = '',
    [string]$PrBase = '',
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

# Keep in sync with create-pr.ps1: token helper functions + Resolve-GitHubToken
function Read-GitHubTokenFromJsonFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding utf8
        $obj = $raw | ConvertFrom-Json
        $token = $obj.github_token
        if ($token -is [string] -and -not [string]::IsNullOrWhiteSpace($token)) {
            return $token.Trim()
        }
    }
    catch {
        return $null
    }

    return $null
}

function ConvertFrom-SecureStringPlain {
    param(
        [Parameter(Mandatory)]
        [System.Security.SecureString]$SecureString
    )

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null
    }
}

function Get-GitHubTokenSecretName {
    return 'GitHubToken'
}

function Test-SecretManagementAvailable {
    $getSecret = Get-Command Get-Secret -ErrorAction SilentlyContinue
    $setSecret = Get-Command Set-Secret -ErrorAction SilentlyContinue
    return ($null -ne $getSecret -and $null -ne $setSecret)
}

function Test-IsInteractiveSession {
    try {
        return [Environment]::UserInteractive
    }
    catch {
        return $false
    }
}

function Read-GitHubTokenFromSecretManagement {
    param(
        [Parameter(Mandatory)]
        [string]$SecretName
    )

    if (-not (Test-SecretManagementAvailable)) {
        return $null
    }

    try {
        $secret = Get-Secret -Name $SecretName -AsPlainText -ErrorAction Stop
        if ($secret -is [string] -and -not [string]::IsNullOrWhiteSpace($secret)) {
            return $secret.Trim()
        }
    }
    catch {
        return $null
    }

    return $null
}

function Prompt-AndStoreGitHubToken {
    param(
        [Parameter(Mandatory)]
        [string]$SecretName
    )

    if (-not (Test-SecretManagementAvailable)) {
        return $null
    }

    if (-not (Test-IsInteractiveSession)) {
        return $null
    }

    Write-Host "No GitHub token found in SecretManagement secret '$SecretName'."
    Write-Host 'Enter a token to store it securely in the SecretManagement/SecretStore vault.'

    try {
        $secureToken = Read-Host 'GitHub token' -AsSecureString
    }
    catch {
        return $null
    }

    if ($null -eq $secureToken -or $secureToken.Length -eq 0) {
        return $null
    }

    $plainToken = ConvertFrom-SecureStringPlain -SecureString $secureToken
    try {
        if ([string]::IsNullOrWhiteSpace($plainToken)) {
            return $null
        }

        Set-Secret -Name $SecretName -Secret $plainToken -ErrorAction Stop
        Write-Host "Stored token in SecretManagement as '$SecretName'."
        return $plainToken.Trim()
    }
    catch {
        Write-Host "Failed to save token to SecretManagement secret '$SecretName'."
        return $null
    }
    finally {
        if ($null -ne $plainToken) {
            $plainToken = $null
        }
    }
}

function Resolve-GitHubTokenForWorkflow {
    param(
        [Parameter(Mandatory)]
        [string]$RepoRoot
    )

    $fromEnv = $env:GITHUB_TOKEN
    if ([string]::IsNullOrWhiteSpace($fromEnv)) {
        $fromEnv = $env:GH_TOKEN
    }

    if (-not [string]::IsNullOrWhiteSpace($fromEnv)) {
        return $fromEnv.Trim()
    }

    $secretName = Get-GitHubTokenSecretName
    $fromSecret = Read-GitHubTokenFromSecretManagement -SecretName $secretName
    if (-not [string]::IsNullOrWhiteSpace($fromSecret)) {
        return $fromSecret
    }

    # Use active gh CLI keyring auth before falling back to legacy JSON files.
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        & gh auth status 1>$null 2>$null
        if ($LASTEXITCODE -eq 0) {
            $ghCliToken = & gh auth token 2>$null
            if (-not [string]::IsNullOrWhiteSpace($ghCliToken)) {
                return $ghCliToken.Trim()
            }
        }
    }

    $promptedToken = Prompt-AndStoreGitHubToken -SecretName $secretName
    if (-not [string]::IsNullOrWhiteSpace($promptedToken)) {
        return $promptedToken
    }

    $rootConfig = Join-Path $RepoRoot 'github-pr.local.json'
    $fromRoot = Read-GitHubTokenFromJsonFile -Path $rootConfig
    if (-not [string]::IsNullOrWhiteSpace($fromRoot)) {
        return $fromRoot
    }

    $legacyConfig = Join-Path $RepoRoot '.github/skills/git-pr-creator/config/github-pr.local.json'
    return Read-GitHubTokenFromJsonFile -Path $legacyConfig
}

function Resolve-CoreBranch {
    $candidates = @('main', 'develop')
    foreach ($branch in $candidates) {
        & git ls-remote --exit-code --heads origin $branch *> $null
        if ($?) {
            return $branch
        }
    }

    return 'main'
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

if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
    $BaseBranch = Resolve-CoreBranch
}

if ([string]::IsNullOrWhiteSpace($PrBase)) {
    $PrBase = $BaseBranch
}

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

if (-not $DryRun) {
    $resolvedToken = Resolve-GitHubTokenForWorkflow -RepoRoot $repoRoot
    if ([string]::IsNullOrWhiteSpace($resolvedToken)) {
        Write-Host @'
GitHub token required before ship workflow (non-DryRun).

Set GITHUB_TOKEN or GH_TOKEN, or configure SecretManagement secret GitHubToken.

If SecretManagement is unavailable, install it with:
    ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1

Legacy fallback: create repo-root github-pr.local.json,
or legacy .github/skills/git-pr-creator/config/github-pr.local.json.

See .github/skills/git-pr-creator/README.md
'@
        exit 1
    }

    $env:GH_TOKEN = $resolvedToken
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
