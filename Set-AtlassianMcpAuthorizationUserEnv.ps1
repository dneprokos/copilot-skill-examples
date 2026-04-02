<#
.SYNOPSIS
    Sets the Windows user environment variable ATLASSIAN_MCP_AUTHORIZATION for Atlassian MCP in Cursor.

.DESCRIPTION
    Prompts for the full Authorization value (the line starting with "Basic ") produced by
    Build-AtlassianMcpAuthorization.ps1. Input is masked. Persists the value for your
    user account only (not Machine-wide). Restart Cursor after running so it picks up
    the new variable.

    Pair with mcp.json:
      "headers": { "Authorization": "${env:ATLASSIAN_MCP_AUTHORIZATION}" }

    Do not commit secrets. Revoke and recreate the API token if it was exposed.

.EXAMPLE
    .\Set-AtlassianMcpAuthorizationUserEnv.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$EnvVarName = 'ATLASSIAN_MCP_AUTHORIZATION'

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

Write-Host ""
Write-Host "Set user env: $EnvVarName" -ForegroundColor Cyan
Write-Host "Paste the full line from Build-AtlassianMcpAuthorization.ps1 (starts with Basic )." -ForegroundColor DarkGray
Write-Host "Input is masked. Restart Cursor after this script succeeds." -ForegroundColor DarkGray
Write-Host ""

$secure = Read-Host "Authorization value (Basic ...)" -AsSecureString
if ($null -eq $secure -or $secure.Length -eq 0) {
    Write-Error "Value is required."
    exit 1
}

$plain = ConvertFrom-SecureStringPlain -SecureString $secure
try {
    $value = $plain.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        Write-Error "Value is required."
        exit 1
    }

    if (-not $value.StartsWith('Basic ', [System.StringComparison]::OrdinalIgnoreCase)) {
        Write-Warning "Value does not start with 'Basic '. If Cursor fails to authenticate, regenerate with Build-AtlassianMcpAuthorization.ps1."
    }

    [Environment]::SetEnvironmentVariable($EnvVarName, $value, 'User')

    Write-Host ""
    Write-Host "User environment variable $EnvVarName is set." -ForegroundColor Green
    Write-Host "Restart Cursor completely (quit from tray) so Agent/MCP reads the new value." -ForegroundColor Green
    Write-Host ""
}
finally {
    if ($null -ne $plain) {
        $plain = $null
    }
}
