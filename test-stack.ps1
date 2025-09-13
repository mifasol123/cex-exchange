# CEX 完整栈测试脚本
Write-Host "=== CEX Exchange Stack Test ===" -ForegroundColor Green

# 检查Go是否安装
try {
    $goVersion = go version
    Write-Host "Go available: $goVersion" -ForegroundColor Green
} catch {
    Write-Host "Go not found. Please install Go 1.21+" -ForegroundColor Red
    exit 1
}

Write-Host "`n启动服务..." -ForegroundColor Yellow

# 启动市场数据聚合服务
Write-Host "启动市场数据聚合服务 (端口 8080)..." -ForegroundColor Cyan
Start-Process -FilePath "powershell" -ArgumentList "-Command", "cd 'backend/market-aggregator'; go run cmd/server/main.go" -WindowStyle Minimized

# 启动透明度服务
Write-Host "启动透明度服务 (端口 8081)..." -ForegroundColor Cyan
Start-Process -FilePath "powershell" -ArgumentList "-Command", "cd 'backend/transparency-service'; go run cmd/server/main.go" -WindowStyle Minimized

# 等待服务启动
Write-Host "`n等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 测试函数
function Test-Endpoint {
    param($url, $name)
    try {
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 10
        Write-Host "✓ $name - OK" -ForegroundColor Green
        return $response
    } catch {
        Write-Host "✗ $name - FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Write-Host "`n=== 测试端点 ===" -ForegroundColor Yellow

# 健康检查
Test-Endpoint "http://localhost:8080/health" "市场服务健康检查"
Test-Endpoint "http://localhost:8081/health" "透明度服务健康检查"

# 市场数据端点
Write-Host "`n--- 市场数据测试 ---" -ForegroundColor Cyan
$ticker = Test-Endpoint "http://localhost:8080/public/market/ticker?symbol=BTCUSDT" "BTC/USDT 行情"
if ($ticker) {
    Write-Host "价格: $($ticker.price), 来源: $($ticker.source)" -ForegroundColor White
}

$klines = Test-Endpoint "http://localhost:8080/public/market/klines?symbol=BTCUSDT&interval=1m&limit=5" "BTC/USDT K线"
if ($klines) {
    Write-Host "K线数量: $($klines.Count)" -ForegroundColor White
}

# 透明度端点
Write-Host "`n--- 透明度测试 ---" -ForegroundColor Cyan
$por = Test-Endpoint "http://localhost:8081/compliance/proof-of-reserves" "储备金证明"
if ($por) {
    Write-Host "状态: $($por.status), 承诺方案: $($por.commitmentScheme)" -ForegroundColor White
}

$status = Test-Endpoint "http://localhost:8081/compliance/system-status" "系统状态"
if ($status) {
    Write-Host "服务: $($status.service), 版本: $($status.version)" -ForegroundColor White
}

Write-Host "`n=== 测试完成 ===" -ForegroundColor Green
Write-Host "前端演示: crypto-exchange-complete.html" -ForegroundColor Yellow
Write-Host "按任意键停止服务..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 停止服务
Write-Host "`n停止服务..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "go"} | Stop-Process -Force
Write-Host "服务已停止。" -ForegroundColor Green
