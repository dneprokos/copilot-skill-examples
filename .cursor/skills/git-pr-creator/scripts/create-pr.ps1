param(
    [string]$BaseBranch = 'main',
    [switch]$AllowDuplicatePrefix,
    [switch]$ApproveInstall,
    [switch]$ApproveAuth,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$global:LASTEXITCODE = 0

function Exit-WithMessage {
    param(
        [string]$Message,
        [int]$Code = 1
    )

    Write-Output $Message
    exit $Code
}

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

function Resolve-GitHubToken {
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

    $rootConfig = Join-Path $RepoRoot 'github-pr.local.json'
    $fromRoot = Read-GitHubTokenFromJsonFile -Path $rootConfig
    if (-not [string]::IsNullOrWhiteSpace($fromRoot)) {
        return $fromRoot
    }

    $legacyConfig = Join-Path $RepoRoot '.github/skills/git-pr-creator/config/github-pr.local.json'
    return Read-GitHubTokenFromJsonFile -Path $legacyConfig
}

function Invoke-Git {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = & git @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $text = ($output | Out-String).Trim()
        throw "git $($Arguments -join ' ') failed. $text"
    }

    return ($output | Out-String).TrimEnd()
}

function Invoke-GitHub {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = & gh @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $text = ($output | Out-String).Trim()
        throw "gh $($Arguments -join ' ') failed. $text"
    }

    return ($output | Out-String).TrimEnd()
}

function Install-GitHubCli {
    $installErrors = @()

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Output 'GitHub CLI (`gh`) was not found. Attempting installation via winget...'
        & $winget.Source install --id GitHub.cli --exact --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Get-Command gh -ErrorAction SilentlyContinue)) {
            return $true
        }

        $installErrors += 'winget install failed'
    }

    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if ($choco) {
        Write-Output 'Attempting GitHub CLI installation via choco...'
        & $choco.Source install gh -y 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Get-Command gh -ErrorAction SilentlyContinue)) {
            return $true
        }

        $installErrors += 'choco install failed'
    }

    $scoop = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoop) {
        Write-Output 'Attempting GitHub CLI installation via scoop...'
        & $scoop.Source install gh 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Get-Command gh -ErrorAction SilentlyContinue)) {
            return $true
        }

        $installErrors += 'scoop install failed'
    }

    if ($installErrors.Count -gt 0) {
        Write-Output ("Automatic gh installation attempts failed: {0}." -f ($installErrors -join '; '))
    }

    return $false
}

function Test-GitHubCliAuthenticated {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        return $false
    }

    & gh auth status 1>$null 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Confirm-Consent {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        [switch]$PreApproved,
        [string]$DeclineMessage
    )

    if ($PreApproved) {
        return $true
    }

    try {
        $answer = Read-Host "$Prompt [y/N]"
    }
    catch {
        if (-not [string]::IsNullOrWhiteSpace($DeclineMessage)) {
            Write-Output $DeclineMessage
        }
        return $false
    }

    if ($answer -match '^(y|yes)$') {
        return $true
    }

    if (-not [string]::IsNullOrWhiteSpace($DeclineMessage)) {
        Write-Output $DeclineMessage
    }

    return $false
}

function Ensure-GitHubCliReady {
    param(
        [switch]$RequireAuth,
        [switch]$ApproveInstall,
        [switch]$ApproveAuth
    )

    $ghAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)
    if (-not $ghAvailable) {
        $allowInstall = Confirm-Consent `
            -Prompt 'GitHub CLI (`gh`) is required but not installed. Install it automatically now?' `
            -PreApproved:$ApproveInstall `
            -DeclineMessage 'GitHub CLI installation was not approved. Install `gh` manually and rerun this skill, or rerun with -ApproveInstall.'

        if (-not $allowInstall) {
            Exit-WithMessage -Message 'GitHub CLI (`gh`) is required to continue.'
        }

        $installed = Install-GitHubCli
        if (-not $installed) {
            Exit-WithMessage -Message 'GitHub CLI (`gh`) is required and could not be installed automatically. Install it manually, then rerun this skill.'
        }
    }

    if (-not $RequireAuth) {
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
        if (-not (Test-GitHubCliAuthenticated)) {
            Exit-WithMessage -Message 'GitHub CLI could not authenticate with the configured token. Verify GITHUB_TOKEN or GH_TOKEN, or github-pr.local.json at repo root (see .github/skills/git-pr-creator/README.md).'
        }

        return
    }

    if (-not (Test-GitHubCliAuthenticated)) {
        $allowAuth = Confirm-Consent `
            -Prompt 'GitHub CLI is not authenticated. Start `gh auth login --web` now?' `
            -PreApproved:$ApproveAuth `
            -DeclineMessage 'GitHub CLI authentication was not approved. Run `gh auth login` manually and rerun this skill, or rerun with -ApproveAuth.'

        if (-not $allowAuth) {
            Exit-WithMessage -Message 'GitHub CLI authentication is required to continue.'
        }

        Write-Output 'GitHub CLI is not authenticated. Launching `gh auth login --web`...'
        & gh auth login --web --git-protocol https
        if ($LASTEXITCODE -ne 0) {
            Exit-WithMessage -Message 'GitHub CLI authentication failed. Complete `gh auth login` and rerun this skill.'
        }

        if (-not (Test-GitHubCliAuthenticated)) {
            Exit-WithMessage -Message 'GitHub CLI is still not authenticated after login. Complete `gh auth login` and rerun this skill.'
        }
    }
}

function Get-BranchTicketInfo {
    param(
        [Parameter(Mandatory)]
        [string]$BranchName
    )

    $prefix = ''
    $suffix = $BranchName

    if ($BranchName -match '^(?<prefix>(?:[A-Za-z]+-\d+|\d+))[\-_](?<suffix>.+)$') {
        $prefix = $Matches['prefix']
        $suffix = $Matches['suffix']
    }

    return @{
        Prefix = $prefix
        Suffix = $suffix
    }
}

function Convert-BranchSuffixToSummary {
    param(
        [string]$Suffix
    )

    if ([string]::IsNullOrWhiteSpace($Suffix)) {
        return ''
    }

    $candidate = $Suffix -creplace '([a-z])([A-Z])', '$1 $2'
    $candidate = $candidate -replace '[_\-]+', ' '
    $candidate = ($candidate -replace '\s+', ' ').Trim().ToLowerInvariant()

    $genericValues = @(
        'branch', 'test branch', 'test', 'feature', 'bugfix', 'fix', 'task',
        'work', 'changes', 'change', 'update', 'pr', 'pull request'
    )

    if ($genericValues -contains $candidate) {
        return ''
    }

    $words = $candidate -split ' '
    $meaningfulWords = @($words | Where-Object {
            $_ -and $_ -notin @('branch', 'test', 'feature', 'bugfix', 'fix', 'task', 'work', 'changes', 'change', 'update', 'pr')
        })

    if ($meaningfulWords.Count -eq 0) {
        return ''
    }

    $summary = ($meaningfulWords -join ' ')

    if ($summary -match '^(add|fix|update|remove|refactor|create|improve|rename|document|enable|disable)\b') {
        return $summary
    }

    if ($summary -match '\b(skill|skills|helper|helpers|script|scripts|workflow|workflows|feature|features)\b') {
        return "add $summary"
    }

    return "update $summary"
}

function Get-ChangeSummary {
    param(
        [string]$BaseBranch,
        [string]$CurrentBranch
    )

    $range = "origin/$BaseBranch..HEAD"
    $commitSubjects = ''

    try {
        $commitSubjects = Invoke-Git -Arguments @('log', '--format=%s', $range)
    }
    catch {
        $commitSubjects = Invoke-Git -Arguments @('log', '--format=%s', '-n', '5')
    }

    $cleanedSubjects = @($commitSubjects -split "`r?`n" | Where-Object { $_.Trim() } | ForEach-Object {
            ($_ -replace '^(feat|fix|docs|refactor|test|chore)(\(.+\))?:\s*', '').Trim()
        })

    $changedFiles = ''
    try {
        $changedFiles = Invoke-Git -Arguments @('diff', '--name-only', $range)
    }
    catch {
        try {
            $changedFiles = Invoke-Git -Arguments @('show', '--pretty=', '--name-only', 'HEAD')
        }
        catch {
            $changedFiles = ''
        }
    }

    if ($changedFiles -match '\.github/skills/git-' -and $changedFiles -match 'README\.md') {
        return 'add new git related skills'
    }

    if ($changedFiles -match '\.github/skills/git-') {
        return 'add git workflow skills'
    }

    if ($changedFiles -match 'README\.md') {
        return 'update repository documentation'
    }

    if ($cleanedSubjects.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($cleanedSubjects[0])) {
        return $cleanedSubjects[0].ToLowerInvariant()
    }

    return "update $CurrentBranch changes"
}

function Get-ProposedPrTitle {
    param(
        [string]$CurrentBranch,
        [string]$BaseBranch
    )

    $ticketInfo = Get-BranchTicketInfo -BranchName $CurrentBranch
    $prefix = [string]$ticketInfo.Prefix
    $summary = Convert-BranchSuffixToSummary -Suffix ([string]$ticketInfo.Suffix)

    if ([string]::IsNullOrWhiteSpace($summary)) {
        $summary = Get-ChangeSummary -BaseBranch $BaseBranch -CurrentBranch $CurrentBranch
    }

    if ([string]::IsNullOrWhiteSpace($summary)) {
        $summary = 'update current branch changes'
    }

    if ([string]::IsNullOrWhiteSpace($prefix)) {
        return $summary
    }

    return "[$prefix]: $summary"
}

function Get-OpenPullRequestsByPrefix {
    param(
        [string]$Prefix
    )

    if ([string]::IsNullOrWhiteSpace($Prefix)) {
        return @()
    }

    $json = Invoke-GitHub -Arguments @('pr', 'list', '--state', 'open', '--limit', '100', '--json', 'number,title,url')
    if ([string]::IsNullOrWhiteSpace($json)) {
        return @()
    }

    $pullRequests = @($json | ConvertFrom-Json)
    return @($pullRequests | Where-Object { $_.title -match "^\[$([regex]::Escape($Prefix))\]" })
}

function Test-RemoteBranchExists {
    param(
        [string]$BranchName
    )

    & git ls-remote --exit-code --heads origin $BranchName *> $null
    return $?
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Exit-WithMessage -Message 'Git is not available in this environment.'
}

$repoRootOutput = & git rev-parse --show-toplevel 2>$null
$repoLookupSucceeded = $?
$repoRoot = ($repoRootOutput | Select-Object -First 1)
if (-not $repoLookupSucceeded -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    Exit-WithMessage -Message 'This skill must be run inside a Git repository.'
}

$repoRoot = $repoRoot.Trim()
Push-Location $repoRoot
try {
    $currentBranch = (Invoke-Git -Arguments @('branch', '--show-current')).Trim()
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Exit-WithMessage -Message 'Unable to determine the current branch.'
    }

    if ($currentBranch -eq 'main') {
        Exit-WithMessage -Message 'You cannot create a pull request from the main branch with this skill.'
    }

    if (-not $DryRun) {
        $resolvedToken = Resolve-GitHubToken -RepoRoot $repoRoot
        if ([string]::IsNullOrWhiteSpace($resolvedToken)) {
            Exit-WithMessage -Message @'
GitHub token required for PR operations (non-DryRun).

Set environment variable GITHUB_TOKEN or GH_TOKEN, or create (preferred, repo root):
  github-pr.local.json
with a string property "github_token".

Optional legacy path:
  .github/skills/git-pr-creator/config/github-pr.local.json

Copy github-pr.local.example.json from the repo root to github-pr.local.json and paste your token.
Do not commit github-pr.local.json. See .github/skills/git-pr-creator/README.md for how to create a token.
'@
        }

        $env:GH_TOKEN = $resolvedToken
    }

    $prTitle = Get-ProposedPrTitle -CurrentBranch $currentBranch -BaseBranch $BaseBranch
    $ticketInfo = Get-BranchTicketInfo -BranchName $currentBranch
    $prefix = [string]$ticketInfo.Prefix
    $ghAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)

    $duplicatePullRequests = @()
    $duplicateCheckWarning = ''
    if (-not [string]::IsNullOrWhiteSpace($prefix)) {
        if (-not $ghAvailable -and -not $DryRun) {
            Ensure-GitHubCliReady -RequireAuth -ApproveInstall:$ApproveInstall -ApproveAuth:$ApproveAuth
            $ghAvailable = $true
        }

        if ($ghAvailable) {
            try {
                $duplicatePullRequests = @(Get-OpenPullRequestsByPrefix -Prefix $prefix)
            }
            catch {
                if ($DryRun) {
                    $duplicateCheckWarning = "Could not verify existing PRs for [$prefix] during preview."
                }
                else {
                    throw
                }
            }
        }

        if (@($duplicatePullRequests).Count -gt 0 -and -not $AllowDuplicatePrefix) {
            Write-Output "Existing open pull request(s) with prefix [$prefix]:"
            $duplicatePullRequests | ForEach-Object {
                Write-Output "- #$($_.number) $($_.title)"
                Write-Output "  $($_.url)"
            }

            Exit-WithMessage -Message "A pull request with prefix [$prefix] already exists. Ask the user whether to create an additional PR and rerun with approval."
        }
    }

    $remoteBranchExists = Test-RemoteBranchExists -BranchName $currentBranch

    $bodyLines = @(
        '## Summary',
        '',
        '- created from the current branch using the git-pr-creator skill',
        '- title generated from the branch name and recent branch changes'
    )
    $prBody = $bodyLines -join "`n"

    if ($DryRun) {
        $ghAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)
        Write-Output "Current branch: $currentBranch"
        Write-Output "Base branch: $BaseBranch"
        Write-Output "Proposed PR title: $prTitle"

        if ($remoteBranchExists) {
            Write-Output "Remote branch: origin/$currentBranch"
        }
        else {
            Write-Output "[DryRun] Would publish '$currentBranch' to 'origin/$currentBranch' before creating the PR."
        }

        if (-not [string]::IsNullOrWhiteSpace($duplicateCheckWarning)) {
            Write-Output $duplicateCheckWarning
        }
        elseif (-not [string]::IsNullOrWhiteSpace($prefix) -and @($duplicatePullRequests).Count -eq 0) {
            Write-Output "No open pull requests were found with prefix [$prefix]."
        }

        if (-not $ghAvailable) {
            Write-Output '[DryRun] GitHub CLI is not available, so PR creation is being previewed only.'
        }
        else {
            Write-Output "[DryRun] Command: gh pr create --base $BaseBranch --head $currentBranch --title \"$prTitle\""
        }

        return
    }

    Ensure-GitHubCliReady -RequireAuth -ApproveInstall:$ApproveInstall -ApproveAuth:$ApproveAuth

    if (-not $remoteBranchExists) {
        Invoke-Git -Arguments @('push', '--set-upstream', 'origin', $currentBranch) | Out-Null
    }
    else {
        Invoke-Git -Arguments @('push', 'origin', $currentBranch) | Out-Null
    }

    $prResult = Invoke-GitHub -Arguments @('pr', 'create', '--base', $BaseBranch, '--head', $currentBranch, '--title', $prTitle, '--body', $prBody)
    Write-Output $prResult
}
finally {
    Pop-Location
}
