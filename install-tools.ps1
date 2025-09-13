# CEX Exchange Environment Setup
param(
    [switch]$TestOnly
)

Write-Host "=== CEX Exchange Environment Setup ===" -ForegroundColor Green

function Test-Command {
    param($CommandName)
    try {
        $null = Get-Command $CommandName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

Write-Host "`n=== Environment Check ===" -ForegroundColor Yellow

# Check Go
$goInstalled = Test-Command "go"
if ($goInstalled) {
    try {
        $goVersion = go version
        Write-Host "OK Go installed: $goVersion" -ForegroundColor Green
    } catch {
        Write-Host "ERROR Go found but not working" -ForegroundColor Red
        $goInstalled = $false
    }
} else {
    Write-Host "MISSING Go not installed" -ForegroundColor Red
}

# Check Docker
$dockerInstalled = Test-Command "docker"
if ($dockerInstalled) {
    try {
        $dockerVersion = docker --version
        Write-Host "OK Docker installed: $dockerVersion" -ForegroundColor Green
        
        # Check if Docker daemon is running
        try {
            docker info | Out-Null
            Write-Host "OK Docker daemon is running" -ForegroundColor Green
        } catch {
            Write-Host "WARNING Docker installed but daemon not running" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "ERROR Docker found but not working" -ForegroundColor Red
        $dockerInstalled = $false
    }
} else {
    Write-Host "MISSING Docker not installed" -ForegroundColor Red
}

if ($TestOnly) {
    Write-Host "`n=== Test Mode Complete ===" -ForegroundColor Cyan
    if ($goInstalled -and $dockerInstalled) {
        Write-Host "Environment is ready!" -ForegroundColor Green
        Write-Host "Run: make dev (for native Go)" -ForegroundColor White
        Write-Host "Run: make up (for Docker)" -ForegroundColor White
    } else {
        Write-Host "Environment needs setup" -ForegroundColor Yellow
    }
    exit 0
}

Write-Host "`n=== Installation Guide ===" -ForegroundColor Yellow

if (-not $goInstalled) {
    Write-Host "`nTo install Go:" -ForegroundColor Cyan
    Write-Host "1. Visit: https://golang.org/dl/" -ForegroundColor White
    Write-Host "2. Download Go 1.21+ for Windows" -ForegroundColor White
    Write-Host "3. Run installer and restart terminal" -ForegroundColor White
    Write-Host "4. Verify with: go version" -ForegroundColor White
}

if (-not $dockerInstalled) {
    Write-Host "`nTo install Docker:" -ForegroundColor Cyan
    Write-Host "1. Visit: https://docs.docker.com/desktop/install/windows-install/" -ForegroundColor White
    Write-Host "2. Download Docker Desktop for Windows" -ForegroundColor White
    Write-Host "3. Run installer and restart system" -ForegroundColor White
    Write-Host "4. Start Docker Desktop application" -ForegroundColor White
    Write-Host "5. Verify with: docker --version" -ForegroundColor White
}

Write-Host "`n=== Quick Test Commands ===" -ForegroundColor Green
Write-Host "After installation, run these commands:" -ForegroundColor White
Write-Host "  .\install-tools.ps1 -TestOnly" -ForegroundColor Cyan
Write-Host "  .\test-stack.ps1" -ForegroundColor Cyan

Write-Host "`n=== Alternative: Use Existing Services ===" -ForegroundColor Yellow
Write-Host "If you prefer to skip installation:" -ForegroundColor White
Write-Host "- Frontend demo works without backend: crypto-exchange-complete.html" -ForegroundColor Cyan
Write-Host "- Review code and architecture: backend/ directory" -ForegroundColor Cyan

Write-Host "`nSetup guide complete!" -ForegroundColor Green
