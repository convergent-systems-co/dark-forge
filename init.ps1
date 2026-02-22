#Requires -Version 5.1
<#
.SYNOPSIS
    Initializes the .ai submodule for a consuming project on Windows.

.DESCRIPTION
    PowerShell equivalent of init.sh. Creates symlinks (or copies as fallback)
    for AI tool configuration files and validates dependencies.

    This script is idempotent — safe to run multiple times.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .ai\init.ps1
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# --- Dependency checks ---

function Test-PythonInstalled {
    try {
        $version = & python --version 2>&1
        if ($version -match 'Python (\d+\.\d+)') {
            $major, $minor = $Matches[1] -split '\.'
            if (([int]$major -gt 3) -or (([int]$major -eq 3) -and ([int]$minor -ge 9))) {
                Write-Host "  [OK] Python $($Matches[1]) found" -ForegroundColor Green
                return $true
            }
        }
        Write-Host "  [WARN] Python found but version 3.9+ is required (found: $version)" -ForegroundColor Yellow
        return $false
    }
    catch {
        Write-Host "  [WARN] Python is not installed or not in PATH" -ForegroundColor Yellow
        Write-Host "         The policy engine requires Python 3.9+ with 'jsonschema' and 'pyyaml' packages." -ForegroundColor Yellow
        Write-Host "         Install from: https://www.python.org/downloads/" -ForegroundColor Yellow
        return $false
    }
}

function Test-PipPackages {
    param([string[]]$Packages)

    $missing = @()
    foreach ($pkg in $Packages) {
        $null = & python -c "import $pkg" 2>&1
        if ($LASTEXITCODE -ne 0) {
            $missing += $pkg
        }
    }

    if ($missing.Count -gt 0) {
        # Map import names to pip package names for install instructions
        $installPkgs = @()
        foreach ($m in $missing) {
            switch ($m) {
                'yaml' { $installPkgs += 'pyyaml' }
                default { $installPkgs += $m }
            }
        }

        Write-Host "  [WARN] Missing Python packages (imports): $($missing -join ', ')" -ForegroundColor Yellow
        Write-Host "         Install with: pip install $($installPkgs -join ' ')" -ForegroundColor Yellow
        return $false
    }

    Write-Host "  [OK] Required Python packages installed (jsonschema, pyyaml)" -ForegroundColor Green
    return $true
}

Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Cyan
$pythonOk = Test-PythonInstalled
if ($pythonOk) {
    Test-PipPackages -Packages @('jsonschema', 'yaml') | Out-Null
}
Write-Host ""

# --- Symlink/copy helpers ---

$CanSymlink = $false
try {
    $testLink = Join-Path $env:TEMP "ai_symlink_test_$(Get-Random)"
    $testTarget = Join-Path $env:TEMP "ai_symlink_target_$(Get-Random)"
    Set-Content -Path $testTarget -Value "test"
    New-Item -ItemType SymbolicLink -Path $testLink -Target $testTarget -ErrorAction Stop | Out-Null
    Remove-Item $testLink -Force
    Remove-Item $testTarget -Force
    $CanSymlink = $true
}
catch {
    Write-Host "  [INFO] Symbolic links not available (requires Developer Mode or admin)." -ForegroundColor Yellow
    Write-Host "         Falling back to file copies. Files will not auto-update with submodule changes." -ForegroundColor Yellow
    Write-Host "         To enable symlinks: Settings > Developer settings > Developer Mode > On" -ForegroundColor Yellow
    Write-Host ""
}

function New-LinkOrCopy {
    param(
        [string]$LinkPath,
        [string]$TargetRelative,
        [string]$TargetAbsolute
    )

    $linkName = [System.IO.Path]::GetFileName($LinkPath)
    $parentDir = Split-Path -Parent $LinkPath

    if (Test-Path $LinkPath) {
        $item = Get-Item $LinkPath -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            # Existing symlink — verify it points to the expected target
            $currentTarget = $item | Select-Object -ExpandProperty Target -ErrorAction SilentlyContinue
            if ($null -ne $currentTarget -and $currentTarget -eq $TargetRelative) {
                Write-Host "  $linkName already linked" -ForegroundColor DarkGray
                return
            }
            Write-Host "  Updating $linkName link target (was '$currentTarget', expected '$TargetRelative')" -ForegroundColor Yellow
            Remove-Item $LinkPath -Force
        }
        else {
            # Existing file that's not a symlink — check if it's a copy we made
            if (-not $CanSymlink) {
                Write-Host "  $linkName already exists (copy)" -ForegroundColor DarkGray
                return
            }
            # Remove the file so we can create a symlink
            Remove-Item $LinkPath -Force
        }
    }

    if ($CanSymlink) {
        New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetRelative -Force | Out-Null
        Write-Host "  Linked $linkName -> $TargetRelative" -ForegroundColor Green
    }
    else {
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        Copy-Item -Path $TargetAbsolute -Destination $LinkPath -Force
        Write-Host "  Copied $linkName <- $TargetRelative" -ForegroundColor Green
    }
}

# --- Create symlinks/copies ---

Write-Host "Initializing .ai submodule configuration..." -ForegroundColor Cyan

$InstructionsSource = Join-Path $ScriptDir "instructions.md"

# instructions.md -> CLAUDE.md, .cursorrules
foreach ($target in @("CLAUDE.md", ".cursorrules")) {
    New-LinkOrCopy `
        -LinkPath (Join-Path $ProjectRoot $target) `
        -TargetRelative ".ai\instructions.md" `
        -TargetAbsolute $InstructionsSource
}

# GitHub Copilot instructions
$githubDir = Join-Path $ProjectRoot ".github"
if (-not (Test-Path $githubDir)) {
    New-Item -ItemType Directory -Path $githubDir -Force | Out-Null
}
New-LinkOrCopy `
    -LinkPath (Join-Path $githubDir "copilot-instructions.md") `
    -TargetRelative "..\.ai\instructions.md" `
    -TargetAbsolute $InstructionsSource

# --- Issue templates ---

$IsSubmodule = $false
$gitmodulesPath = Join-Path $ProjectRoot ".gitmodules"
if (Test-Path $gitmodulesPath) {
    $content = Get-Content $gitmodulesPath -Raw
    if ($content -match '\.ai') {
        $IsSubmodule = $true
    }
}

if ($IsSubmodule) {
    $templateSrc = Join-Path $ScriptDir ".github\ISSUE_TEMPLATE"
    $templateDst = Join-Path $ProjectRoot ".github\ISSUE_TEMPLATE"

    if (Test-Path $templateSrc) {
        if (-not (Test-Path $templateDst)) {
            New-Item -ItemType Directory -Path $templateDst -Force | Out-Null
        }

        Get-ChildItem -Path $templateSrc -Filter "*.yml" | ForEach-Object {
            $dstFile = Join-Path $templateDst $_.Name
            if (-not (Test-Path $dstFile)) {
                Copy-Item -Path $_.FullName -Destination $dstFile
                Write-Host "  Copied issue template $($_.Name)" -ForegroundColor Green
            }
            else {
                Write-Host "  Issue template $($_.Name) already exists, skipping" -ForegroundColor DarkGray
            }
        }
    }
}
else {
    Write-Host "  Skipping issue template copy (not a submodule context)" -ForegroundColor DarkGray
}

# --- Done ---

Write-Host ""
Write-Host "Done. Configuration files created." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Copy a language template:  Copy-Item .ai\templates\python\project.yaml .ai\project.yaml"
Write-Host "  2. Customize personas and conventions in project.yaml"
Write-Host "  3. Set governance profile:    governance.policy_profile: default"

if (-not $pythonOk) {
    Write-Host ""
    Write-Host "WARNING: Python 3.9+ is required for the governance policy engine." -ForegroundColor Red
    Write-Host "Install Python from https://www.python.org/downloads/ and ensure it is in your PATH." -ForegroundColor Red
    Write-Host "Then run: pip install jsonschema pyyaml" -ForegroundColor Red
}
