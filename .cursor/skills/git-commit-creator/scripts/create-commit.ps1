param(
    [string]$CommitMessage,
    [switch]$StageAll,
    [switch]$PreviewOnly,
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

function Test-GitStagedChanges {
    & git diff --cached --quiet --exit-code
    return (-not $?)
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

    if ($StageAll) {
        if ($DryRun) {
            Write-Output '[DryRun] Would stage all unstaged files with: git add -A'
        }
        else {
            Write-Output 'Staging all unstaged files...'
            Invoke-Git -Arguments @('add', '-A') | Out-Null
        }
    }

    $statusOutput = Invoke-Git -Arguments @('status', '--short')
    $stagedFiles = Invoke-Git -Arguments @('diff', '--cached', '--name-only')
    $stagedStat = Invoke-Git -Arguments @('diff', '--cached', '--stat')
    $hasStagedChanges = Test-GitStagedChanges

    if ($DryRun -and $StageAll -and -not $hasStagedChanges -and -not [string]::IsNullOrWhiteSpace($statusOutput)) {
        $hasStagedChanges = $true
    }

    Write-Output "Current branch: $currentBranch"
    Write-Output ''
    Write-Output 'Git status:'
    if ([string]::IsNullOrWhiteSpace($statusOutput)) {
        Write-Output '(working tree clean)'
    }
    else {
        Write-Output $statusOutput
    }

    Write-Output ''
    Write-Output 'Staged files:'
    if ([string]::IsNullOrWhiteSpace($stagedFiles)) {
        Write-Output '(no staged files)'
    }
    else {
        Write-Output $stagedFiles
    }

    Write-Output ''
    Write-Output 'Staged diff summary:'
    if ([string]::IsNullOrWhiteSpace($stagedStat)) {
        Write-Output '(no staged diff summary)'
    }
    else {
        Write-Output $stagedStat
    }

    if ($PreviewOnly) {
        return
    }

    if (-not $hasStagedChanges) {
        Exit-WithMessage -Message 'No staged changes are available to commit.'
    }

    if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
        Exit-WithMessage -Message 'A commit message should be specified for this skill.'
    }

    if ($DryRun) {
        Write-Output ''
        Write-Output "[DryRun] Would create commit on '$currentBranch' with message: $CommitMessage"
        return
    }

    Invoke-Git -Arguments @('commit', '-m', $CommitMessage) | Out-Null
    Write-Output ''
    Write-Output "Created commit on '$currentBranch' with message: $CommitMessage"
}
finally {
    Pop-Location
}
