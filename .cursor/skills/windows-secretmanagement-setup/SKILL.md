---
name: windows-secretmanagement-setup
description: >-
  Install and configure Windows Credential Manager style secret storage for PowerShell using
  SecretManagement and SecretStore. Use when users ask to install secret manager support,
  set up Credential Manager for GitHub token storage, or bootstrap GitHubToken for PR skills.
argument-hint: "optional setup context"
---

# Windows SecretManagement Setup

Install and initialize PowerShell SecretManagement for secure local token storage.

## When this skill fits

Use it for requests like:

- "install credential manager support for PR token"
- "set up SecretManagement on Windows"
- "configure GitHubToken secret"

Do **not** use it for:

- creating pull requests
- rotating GitHub org secrets
- CI/CD secret injection

## Workflow

### 1. Verify PowerShell environment

Ensure the environment can run PowerShell module install commands and has network access to PSGallery.

### 2. Install required modules

Install these modules for the current user if missing:

- `Microsoft.PowerShell.SecretManagement`
- `Microsoft.PowerShell.SecretStore`

Run helper script:

```powershell
pwsh -NoProfile -File ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1
```

### 3. Register SecretStore vault

If `SecretStore` vault is not registered, register it and set it as default.

### 4. Optionally save GitHub token

Prompt user for token input (masked) and store it as secret name `GitHubToken`.

```powershell
pwsh -NoProfile -File ./.github/skills/windows-secretmanagement-setup/scripts/install-secretmanagement.ps1 -SetGitHubToken
```

### 5. Validate setup

Confirm secret commands and retrieval work:

```powershell
Get-SecretVault
Get-Secret -Name GitHubToken -AsPlainText
```

## Hard rules

- Never print token values to logs.
- Never commit token files when secure storage is available.
- Keep `GitHubToken` as the default secret name for PR workflows.
- Use `-ApproveInstall` for headless/non-interactive runs.
