param(
    [switch]$ApproveInstall,
    [switch]$SetGitHubToken,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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

function Confirm-Consent {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        [switch]$PreApproved
    )

    if ($PreApproved) {
        return $true
    }

    try {
        $answer = Read-Host "$Prompt [y/N]"
    }
    catch {
        return $false
    }

    return ($answer -match '^(y|yes)$')
}

function Ensure-ModuleInstalled {
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [switch]$ApproveInstall,
        [switch]$Force
    )

    $module = Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1
    if ($null -ne $module) {
        Write-Host "Module already installed: $ModuleName"
        return
    }

    $allow = Confirm-Consent -Prompt "Install PowerShell module '$ModuleName' for CurrentUser now?" -PreApproved:$ApproveInstall
    if (-not $allow) {
        throw "Installation declined for module '$ModuleName'."
    }

    Write-Host "Installing module: $ModuleName"
    $installParams = @{
        Name = $ModuleName
        Scope = 'CurrentUser'
        Repository = 'PSGallery'
        AllowClobber = $true
        ErrorAction = 'Stop'
    }

    if ($Force) {
        $installParams['Force'] = $true
    }

    Install-Module @installParams
    Write-Host "Installed module: $ModuleName"
}

function Ensure-SecretStoreVault {
    $vault = Get-SecretVault -Name 'SecretStore' -ErrorAction SilentlyContinue
    if ($null -ne $vault) {
        Write-Host 'SecretStore vault is already registered.'
        return
    }

    Register-SecretVault -Name 'SecretStore' -ModuleName 'Microsoft.PowerShell.SecretStore' -DefaultVault -ErrorAction Stop
    Write-Host 'Registered SecretStore vault as default.'
}

function Set-GitHubTokenSecret {
    $secretName = 'GitHubToken'

    try {
        $secureToken = Read-Host "GitHub token for secret '$secretName'" -AsSecureString
    }
    catch {
        throw 'Unable to read token input.'
    }

    if ($null -eq $secureToken -or $secureToken.Length -eq 0) {
        throw 'Token input was empty.'
    }

    $plainToken = ConvertFrom-SecureStringPlain -SecureString $secureToken
    try {
        if ([string]::IsNullOrWhiteSpace($plainToken)) {
            throw 'Token input was empty.'
        }

        Set-Secret -Name $secretName -Secret $plainToken -ErrorAction Stop
        Write-Host "Saved secret '$secretName'."
    }
    finally {
        if ($null -ne $plainToken) {
            $plainToken = $null
        }
    }
}

Write-Host ''
Write-Host 'Windows SecretManagement setup' -ForegroundColor Cyan
Write-Host ''

Ensure-ModuleInstalled -ModuleName 'Microsoft.PowerShell.SecretManagement' -ApproveInstall:$ApproveInstall -Force:$Force
Ensure-ModuleInstalled -ModuleName 'Microsoft.PowerShell.SecretStore' -ApproveInstall:$ApproveInstall -Force:$Force

Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop
Import-Module Microsoft.PowerShell.SecretStore -ErrorAction Stop

Ensure-SecretStoreVault

if ($SetGitHubToken) {
    Set-GitHubTokenSecret
}

Write-Host ''
Write-Host 'Setup complete.' -ForegroundColor Green
Write-Host "Available commands: Get-Secret, Set-Secret. Default secret name for PR skill: 'GitHubToken'."
Write-Host ''
