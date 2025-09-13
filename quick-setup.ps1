# Quick Setup for CEX Exchange
Write-Host "=== CEX Exchange Quick Setup ===" -ForegroundColor Green

# Step 1: Download and install Go
Write-Host "`nStep 1: Installing Go 1.21.13..." -ForegroundColor Yellow

$goUrl = "https://go.dev/dl/go1.21.13.windows-amd64.msi"
$goInstaller = "$env:TEMP\go-installer.msi"

try {
    Write-Host "Downloading Go installer..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $goUrl -OutFile $goInstaller -UseBasicParsing
    
    Write-Host "Starting Go installer..." -ForegroundColor Cyan
    Write-Host "Please complete the installation wizard, then press Enter to continue..." -ForegroundColor Yellow
    Start-Process -FilePath $goInstaller -Wait
    
    Read-Host "Press Enter after Go installation is complete"
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Test Go
    try {
        $goVersion = go version
        Write-Host "SUCCESS: $goVersion" -ForegroundColor Green
    } catch {
        Write-Host "Go installed but not in PATH. Please restart terminal and run this script again." -ForegroundColor Yellow
        exit 1
    }
    
} catch {
    Write-Host "Failed to download or install Go: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please manually install Go from: https://golang.org/dl/" -ForegroundColor Yellow
    exit 1
}

# Step 2: Test our services
Write-Host "`nStep 2: Testing CEX services..." -ForegroundColor Yellow

Write-Host "Starting market aggregator service..." -ForegroundColor Cyan
$marketJob = Start-Job -ScriptBlock { 
    Set-Location "D:\区块链虚拟币\backend\market-aggregator"
    go run cmd/server/main.go 
}

Write-Host "Starting transparency service..." -ForegroundColor Cyan  
$transparencyJob = Start-Job -ScriptBlock { 
    Set-Location "D:\区块链虚拟币\backend\transparency-service"
    go run cmd/server/main.go 
}

Write-Host "Waiting for services to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 8

# Test endpoints
Write-Host "`nStep 3: Testing endpoints..." -ForegroundColor Yellow

function Test-Endpoint {
    param($url, $name)
    try {
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 10
        Write-Host "OK $name" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "FAIL $name - $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Health checks
Test-Endpoint "http://localhost:8080/health" "Market Service Health"
Test-Endpoint "http://localhost:8081/health" "Transparency Service Health"

# Market data
$ticker = Test-Endpoint "http://localhost:8080/public/market/ticker?symbol=BTCUSDT" "BTC Ticker"
if ($ticker) {
    Write-Host "  Price: $($ticker.price), Source: $($ticker.source)" -ForegroundColor White
}

# Transparency
$por = Test-Endpoint "http://localhost:8081/compliance/proof-of-reserves" "Proof of Reserves"
if ($por) {
    Write-Host "  Status: $($por.status), Scheme: $($por.commitmentScheme)" -ForegroundColor White
}

Write-Host "`n=== Test Results ===" -ForegroundColor Green
Write-Host "Services are running on:" -ForegroundColor White
Write-Host "- Market Data: http://localhost:8080" -ForegroundColor Cyan
Write-Host "- Transparency: http://localhost:8081" -ForegroundColor Cyan
Write-Host "- Frontend Demo: crypto-exchange-complete.html" -ForegroundColor Cyan

Write-Host "`nPress Enter to stop services..." -ForegroundColor Yellow
Read-Host

# Cleanup
Write-Host "Stopping services..." -ForegroundColor Gray
Stop-Job $marketJob -Force
Stop-Job $transparencyJob -Force
Remove-Job $marketJob
Remove-Job $transparencyJob

Write-Host "Setup and test complete!" -ForegroundColor Green
