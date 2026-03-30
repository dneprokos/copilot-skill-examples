param(
    [string]$ProjectPath = "."
)

$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $ProjectPath).Path

function Test-RepoPath {
    param([string]$RelativePath)
    return Test-Path -LiteralPath (Join-Path $root $RelativePath)
}

function Read-JsonFile {
    param([string]$RelativePath)

    if (-not (Test-RepoPath $RelativePath)) {
        return $null
    }

    try {
        return (Get-Content -LiteralPath (Join-Path $root $RelativePath) -Raw | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

function Read-TextFile {
    param([string]$RelativePath)

    if (-not (Test-RepoPath $RelativePath)) {
        return ''
    }

    return Get-Content -LiteralPath (Join-Path $root $RelativePath) -Raw
}

function Get-TomlValue {
    param(
        [string]$Text,
        [string]$Key
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $pattern = '(?m)^\s*' + [regex]::Escape($Key) + '\s*=\s*["'']([^"'']+)["'']'
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return ''
}

function Get-LicenseHint {
    $candidates = @('LICENSE', 'LICENSE.md', 'LICENSE.txt')

    foreach ($file in $candidates) {
        if (Test-RepoPath $file) {
            $sample = ((Get-Content -LiteralPath (Join-Path $root $file) | Select-Object -First 12) -join "`n")
            switch -Regex ($sample) {
                'MIT License' { return 'MIT' }
                'Apache License' { return 'Apache-2.0' }
                'GNU GENERAL PUBLIC LICENSE' { return 'GPL' }
                'BSD' { return 'BSD' }
                default { return 'See LICENSE file' }
            }
        }
    }

    return ''
}

$packageJson = Read-JsonFile 'package.json'
$pyprojectText = Read-TextFile 'pyproject.toml'
$cargoText = Read-TextFile 'Cargo.toml'

$projectName = if ($packageJson -and $packageJson.name) {
    [string]$packageJson.name
}
elseif ($pyprojectText) {
    $value = Get-TomlValue -Text $pyprojectText -Key 'name'
    if ($value) { $value } else { Split-Path $root -Leaf }
}
elseif ($cargoText) {
    $value = Get-TomlValue -Text $cargoText -Key 'name'
    if ($value) { $value } else { Split-Path $root -Leaf }
}
else {
    Split-Path $root -Leaf
}

$description = if ($packageJson -and $packageJson.description) {
    [string]$packageJson.description
}
elseif ($pyprojectText) {
    Get-TomlValue -Text $pyprojectText -Key 'description'
}
elseif ($cargoText) {
    Get-TomlValue -Text $cargoText -Key 'description'
}
else {
    ''
}

$license = if ($packageJson -and $packageJson.license) {
    [string]$packageJson.license
}
elseif ($pyprojectText) {
    $value = Get-TomlValue -Text $pyprojectText -Key 'license'
    if ($value) { $value } else { Get-LicenseHint }
}
elseif ($cargoText) {
    $value = Get-TomlValue -Text $cargoText -Key 'license'
    if ($value) { $value } else { Get-LicenseHint }
}
else {
    Get-LicenseHint
}

$packageManagers = New-Object System.Collections.Generic.List[string]
if (Test-RepoPath 'package-lock.json') { $packageManagers.Add('npm') }
if (Test-RepoPath 'pnpm-lock.yaml') { $packageManagers.Add('pnpm') }
if (Test-RepoPath 'yarn.lock') { $packageManagers.Add('yarn') }
if (Test-RepoPath 'pyproject.toml') { $packageManagers.Add('python') }
if (Test-RepoPath 'Cargo.toml') { $packageManagers.Add('cargo') }
if (Test-RepoPath 'go.mod') { $packageManagers.Add('go') }

$scriptMap = [ordered]@{}
if ($packageJson -and $packageJson.scripts) {
    foreach ($prop in $packageJson.scripts.PSObject.Properties) {
        $scriptMap[$prop.Name] = [string]$prop.Value
    }
}

$ciFiles = @()
if (Test-RepoPath '.github\workflows') {
    $ciFiles = Get-ChildItem -LiteralPath (Join-Path $root '.github\workflows') -File |
    Select-Object -ExpandProperty Name
}

$docs = Get-ChildItem -LiteralPath $root -File |
Where-Object { $_.Name -match '^(README|CONTRIBUTING|CHANGELOG|LICENSE)' } |
Select-Object -ExpandProperty Name

$topLevelItems = Get-ChildItem -LiteralPath $root -Force |
Where-Object { $_.Name -notin @('.git', 'node_modules', '.venv', '__pycache__') } |
Sort-Object -Property @{ Expression = { $_.PSIsContainer }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $false } |
Select-Object -First 20 |
ForEach-Object {
    if ($_.PSIsContainer) { "{0}/" -f $_.Name } else { $_.Name }
}

$result = [ordered]@{
    root            = $root
    projectName     = $projectName
    description     = $description
    license         = $license
    packageManagers = @($packageManagers)
    ciFiles         = @($ciFiles)
    docs            = @($docs)
    scripts         = $scriptMap
    topLevelItems   = @($topLevelItems)
}

$result | ConvertTo-Json -Depth 6
