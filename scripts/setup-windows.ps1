# Claude Code Docker Environment Setup Script for Windows
# Run this script in PowerShell as Administrator

param(
    [switch]$SkipDockerDesktop,
    [switch]$Help
)

if ($Help) {
    Write-Host "Claude Code Docker Environment Setup for Windows"
    Write-Host ""
    Write-Host "Usage: .\setup-windows.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -SkipDockerDesktop    Skip Docker Desktop installation"
    Write-Host "  -Help                 Show this help message"
    Write-Host ""
    Write-Host "Prerequisites:"
    Write-Host "  - Windows 10/11 with WSL2 enabled"
    Write-Host "  - PowerShell running as Administrator"
    exit 0
}

# Color functions
function Write-Info {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if WSL2 is enabled
function Test-WSL2 {
    try {
        $wslVersion = wsl --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Enable WSL2
function Enable-WSL2 {
    Write-Info "Enabling WSL2..."
    
    # Enable WSL feature
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    
    # Enable Virtual Machine Platform
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    # Download and install WSL2 kernel update
    $kernelUpdateUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelUpdatePath = "$env:TEMP\wsl_update_x64.msi"
    
    Write-Info "Downloading WSL2 kernel update..."
    Invoke-WebRequest -Uri $kernelUpdateUrl -OutFile $kernelUpdatePath
    
    Write-Info "Installing WSL2 kernel update..."
    Start-Process -FilePath $kernelUpdatePath -ArgumentList "/quiet" -Wait
    
    # Set WSL2 as default version
    wsl --set-default-version 2
    
    Write-Success "WSL2 enabled. A restart may be required."
    Write-Warning "Please restart your computer and run this script again if needed."
}

# Install Docker Desktop
function Install-DockerDesktop {
    Write-Info "Installing Docker Desktop..."
    
    # Check if Docker Desktop is already installed
    $dockerPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerPath) {
        Write-Info "Docker Desktop is already installed"
        return $true
    }
    
    # Download Docker Desktop
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    
    Write-Info "Downloading Docker Desktop..."
    try {
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
    }
    catch {
        Write-Error "Failed to download Docker Desktop: $($_.Exception.Message)"
        return $false
    }
    
    Write-Info "Installing Docker Desktop (this may take a while)..."
    try {
        Start-Process -FilePath $dockerInstaller -ArgumentList "install", "--quiet" -Wait
        Write-Success "Docker Desktop installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install Docker Desktop: $($_.Exception.Message)"
        return $false
    }
}

# Check if Docker is running
function Test-Docker {
    try {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) {
            Write-Success "Docker is available: $dockerVersion"
            return $true
        }
    }
    catch {
        return $false
    }
    return $false
}

# Setup environment file
function Setup-Environment {
    Write-Info "Setting up environment file..."
    
    if (-not (Test-Path ".env")) {
        if (Test-Path ".env.example") {
            Copy-Item ".env.example" ".env"
            Write-Success "Created .env file from template"
            Write-Warning "Please edit .env file and add your ANTHROPIC_API_KEY"
        }
        else {
            Write-Error ".env.example file not found"
            return $false
        }
    }
    else {
        Write-Info ".env file already exists"
    }
    return $true
}

# Main setup function
function Main {
    Write-Host "=== Claude Code Docker Environment Setup for Windows ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Error "This script must be run as Administrator"
        Write-Info "Right-click PowerShell and select 'Run as Administrator'"
        exit 1
    }
    
    Write-Success "Running with Administrator privileges"
    
    # Check WSL2
    if (-not (Test-WSL2)) {
        Write-Warning "WSL2 is not enabled"
        $enableWSL = Read-Host "Do you want to enable WSL2? (y/N)"
        if ($enableWSL -eq 'y' -or $enableWSL -eq 'Y') {
            Enable-WSL2
            Write-Warning "Please restart your computer and run this script again"
            exit 0
        }
        else {
            Write-Error "WSL2 is required for Docker Desktop"
            exit 1
        }
    }
    else {
        Write-Success "WSL2 is available"
    }
    
    # Install Docker Desktop
    if (-not $SkipDockerDesktop) {
        if (-not (Install-DockerDesktop)) {
            Write-Error "Docker Desktop installation failed"
            exit 1
        }
    }
    
    # Setup environment
    if (-not (Setup-Environment)) {
        Write-Error "Environment setup failed"
        exit 1
    }
    
    Write-Host ""
    Write-Success "Setup completed!"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Start Docker Desktop (from Start Menu)"
    Write-Host "2. Wait for Docker Desktop to fully start"
    Write-Host "3. Edit .env file and add your ANTHROPIC_API_KEY"
    Write-Host "4. Open PowerShell in this directory and run:"
    Write-Host "   .\test-local.sh  # (in WSL or Git Bash)"
    Write-Host "5. docker-compose up -d --build"
    Write-Host "6. docker-compose exec claude-dev bash"
    Write-Host "7. claude"
    Write-Host ""
    Write-Warning "Note: You may need to restart your computer if WSL2 was just enabled"
    Write-Info "For WSL/Linux commands, use WSL terminal or Git Bash"
}

# Run main function
try {
    Main
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}