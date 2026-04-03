param(
    [string]$BranchName,
    [string]$BaseBranch = '',
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

    return ($output | Out-String).Trim()
}

function Switch-Branch {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [switch]$Create
    )

    try {
        if ($Create) {
            Invoke-Git -Arguments @('switch', '-c', $Name) | Out-Null
        }
        else {
            Invoke-Git -Arguments @('switch', $Name) | Out-Null
        }
    }
    catch {
        if ($Create) {
            Invoke-Git -Arguments @('checkout', '-b', $Name) | Out-Null
        }
        else {
            Invoke-Git -Arguments @('checkout', $Name) | Out-Null
        }
    }
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

if ([string]::IsNullOrWhiteSpace($BranchName)) {
    Exit-WithMessage -Message 'A new branch name should be specified for this skill.'
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
    if ([string]::IsNullOrWhiteSpace($BaseBranch)) {
        $BaseBranch = Resolve-CoreBranch
    }

    Write-Output 'Fetching latest changes from origin...'
    Invoke-Git -Arguments @('fetch', '--prune', 'origin') | Out-Null

    $currentBranch = (Invoke-Git -Arguments @('branch', '--show-current')).Trim()
    if ($currentBranch -ne $BaseBranch) {
        Write-Output "Switching to '$BaseBranch'..."
        Switch-Branch -Name $BaseBranch
    }

    & git show-ref --verify --quiet "refs/remotes/origin/$BaseBranch"
    if (-not $?) {
        Exit-WithMessage -Message "Remote branch 'origin/$BaseBranch' was not found."
    }

    $countText = Invoke-Git -Arguments @('rev-list', '--left-right', '--count', "$BaseBranch...origin/$BaseBranch")
    $counts = $countText -split '\s+'
    $aheadCount = [int]$counts[0]
    $behindCount = [int]$counts[1]

    if ($behindCount -gt 0) {
        Write-Output "'$BaseBranch' is behind origin by $behindCount commit(s). Pulling latest changes..."
        if ($DryRun) {
            Write-Output "[DryRun] Would run: git pull --ff-only origin $BaseBranch"
        }
        else {
            Invoke-Git -Arguments @('pull', '--ff-only', 'origin', $BaseBranch) | Out-Null
        }
    }
    elseif ($aheadCount -gt 0) {
        Write-Output "'$BaseBranch' is ahead of origin by $aheadCount commit(s). Using the local branch as the base."
    }
    else {
        Write-Output "'$BaseBranch' is already up to date."
    }

    & git show-ref --verify --quiet "refs/heads/$BranchName"
    if ($?) {
        Exit-WithMessage -Message "Branch '$BranchName' already exists. Choose a different name."
    }

    if ($DryRun) {
        Write-Output "[DryRun] Would create and switch to '$BranchName' from '$BaseBranch'."
        return
    }

    Switch-Branch -Name $BranchName -Create
    Write-Output "Created and switched to new branch '$BranchName' from '$BaseBranch'."
}
finally {
    Pop-Location
}
