param(
    [string]$BaseBranch = 'main',
    [switch]$AllowDuplicatePrefix,
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
$ghAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)

Push-Location $repoRoot
try {
    $currentBranch = (Invoke-Git -Arguments @('branch', '--show-current')).Trim()
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Exit-WithMessage -Message 'Unable to determine the current branch.'
    }

    if ($currentBranch -eq 'main') {
        Exit-WithMessage -Message 'You cannot create a pull request from the main branch with this skill.'
    }

    $prTitle = Get-ProposedPrTitle -CurrentBranch $currentBranch -BaseBranch $BaseBranch
    $ticketInfo = Get-BranchTicketInfo -BranchName $currentBranch
    $prefix = [string]$ticketInfo.Prefix

    $duplicatePullRequests = @()
    $duplicateCheckWarning = ''
    if (-not [string]::IsNullOrWhiteSpace($prefix)) {
        if (-not $ghAvailable -and -not $DryRun) {
            Exit-WithMessage -Message 'GitHub CLI (`gh`) is required to check for existing pull requests and create a new one.'
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

    if (-not $ghAvailable) {
        Exit-WithMessage -Message 'GitHub CLI (`gh`) is required to create a pull request with this skill.'
    }

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
