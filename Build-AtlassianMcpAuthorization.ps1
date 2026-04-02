<#
.SYNOPSIS
    Builds the HTTP Basic Authorization value for Atlassian MCP (Cursor mcp.json + ATLASSIAN_MCP_AUTHORIZATION).

.DESCRIPTION
    Prompts for your Atlassian account email and API token (token input is masked).
    Outputs a single line: "Basic <base64(email:token)>" suitable for the Windows
    user environment variable ATLASSIAN_MCP_AUTHORIZATION when using:
      "headers": { "Authorization": "${env:ATLASSIAN_MCP_AUTHORIZATION}" }

    Do not commit secrets. Revoke and recreate the API token if it was exposed.

.PARAMETER Copy
    Copies the Basic ... line to the clipboard after computing it.

.EXAMPLE
    .\Build-AtlassianMcpAuthorization.ps1

.EXAMPLE
    .\Build-AtlassianMcpAuthorization.ps1 -Copy
#>
[CmdletBinding()]
param(
    [switch]$Copy
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

Write-Host ""
Write-Host "Atlassian MCP Authorization builder" -ForegroundColor Cyan
Write-Host "Use the printed 'Basic ...' value for user env var ATLASSIAN_MCP_AUTHORIZATION." -ForegroundColor DarkGray
Write-Host ""

$email = (Read-Host "Atlassian account email").Trim()
if ([string]::IsNullOrWhiteSpace($email)) {
    Write-Error "Email is required."
    exit 1
}

$secureToken = Read-Host "Atlassian API token" -AsSecureString
if ($null -eq $secureToken -or $secureToken.Length -eq 0) {
    Write-Error "API token is required."
    exit 1
}

$tokenPlain = ConvertFrom-SecureStringPlain -SecureString $secureToken
try {
    if ([string]::IsNullOrWhiteSpace($tokenPlain)) {
        Write-Error "API token is required."
        exit 1
    }

    $pair = "${email}:${tokenPlain}"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
    $encoded = [Convert]::ToBase64String($bytes)
    $authorization = "Basic $encoded"

    Write-Host ""
    Write-Host "Set this as your user environment variable ATLASSIAN_MCP_AUTHORIZATION:" -ForegroundColor Green
    Write-Host $authorization
    Write-Host ""

    if ($Copy) {
        Set-Clipboard -Value $authorization
        Write-Host "Copied to clipboard." -ForegroundColor Green
    }
}
finally {
    if ($null -ne $tokenPlain) {
        $tokenPlain = $null
    }
}
