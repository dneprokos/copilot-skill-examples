param(
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
    $coreBranch = Resolve-CoreBranch

    $currentBranch = (Invoke-Git -Arguments @('branch', '--show-current')).Trim()
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Exit-WithMessage -Message 'Unable to determine the current branch.'
    }

    if ($currentBranch -eq $coreBranch) {
        Exit-WithMessage -Message "You cannot push to the $coreBranch branch with this skill."
    }

    if ($DryRun) {
        Write-Output "[DryRun] Would push '$currentBranch' to 'origin/$currentBranch'."
        Write-Output "[DryRun] Command: git push --set-upstream origin $currentBranch"
        return
    }

    $pushResult = Invoke-Git -Arguments @('push', '--set-upstream', 'origin', $currentBranch)
    if ([string]::IsNullOrWhiteSpace($pushResult)) {
        Write-Output "Pushed '$currentBranch' to 'origin/$currentBranch'."
    }
    else {
        Write-Output $pushResult
    }
}
finally {
    Pop-Location
}
