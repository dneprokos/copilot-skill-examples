# Windows SecretManagement Setup

This skill installs and configures PowerShell SecretManagement + SecretStore so local scripts can store GitHub tokens securely instead of plain JSON files.

## What it does

- installs required modules for current user
- ensures `SecretStore` vault is registered and default
- optionally prompts for and stores `GitHubToken`
- validates that `Get-Secret` and `Set-Secret` are available

## Quick start

Install modules and register vault:

```powershell
pwsh -NoProfile -File ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1
```

Install non-interactively (approved):

```powershell
pwsh -NoProfile -File ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1 -ApproveInstall
```

Install and set GitHub token in one run:

```powershell
pwsh -NoProfile -File ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1 -SetGitHubToken
```

## Output

The script reports:

- module install status
- vault registration status
- whether `GitHubToken` was saved

## Notes

- This is designed for local developer machines on Windows.
- Token value is never echoed by the script.
- PR creation scripts read token in this order: env vars, SecretManagement `GitHubToken`, then legacy JSON fallback.
