# CEX Exchange 快速部署脚本
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("railway", "vercel", "render", "netlify")]
    [string]$Platform
)

Write-Host "=== CEX Exchange 快速部署 ===" -ForegroundColor Green
Write-Host "目标平台: $Platform" -ForegroundColor Yellow

# 检查依赖
function Test-Dependencies {
    Write-Host "`n检查依赖..." -ForegroundColor Yellow
    
    # 检查 Git
    try {
        git --version | Out-Null
        Write-Host "✓ Git 已安装" -ForegroundColor Green
    } catch {
        Write-Host "✗ Git 未安装，请先安装 Git" -ForegroundColor Red
        exit 1
    }
    
    # 检查 Go
    try {
        go version | Out-Null
        Write-Host "✓ Go 已安装" -ForegroundColor Green
    } catch {
        Write-Host "✗ Go 未安装，请先安装 Go 1.21+" -ForegroundColor Red
        exit 1
    }
}

# 构建项目
function Build-Project {
    Write-Host "`n构建项目..." -ForegroundColor Yellow
    
    # 构建市场数据服务
    Write-Host "构建市场数据聚合服务..." -ForegroundColor Cyan
    Set-Location "backend\market-aggregator"
    go mod tidy
    go build -o main cmd/server/main.go
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 市场数据服务构建失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ 市场数据服务构建成功" -ForegroundColor Green
    Set-Location "..\..\"
    
    # 构建透明度服务
    Write-Host "构建透明度服务..." -ForegroundColor Cyan
    Set-Location "backend\transparency-service"
    go mod tidy
    go build -o main cmd/server/main.go
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 透明度服务构建失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ 透明度服务构建成功" -ForegroundColor Green
    Set-Location "..\..\"
}

# 测试服务
function Test-Services {
    Write-Host "`n测试服务..." -ForegroundColor Yellow
    
    # 启动市场数据服务进行测试
    Write-Host "测试市场数据服务..." -ForegroundColor Cyan
    Set-Location "backend\market-aggregator"
    $job1 = Start-Job -ScriptBlock { 
        Set-Location $using:PWD
        ./main 
    }
    Start-Sleep -Seconds 3
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
        Write-Host "✓ 市场数据服务健康检查通过" -ForegroundColor Green
    } catch {
        Write-Host "✗ 市场数据服务健康检查失败" -ForegroundColor Red
    }
    
    Stop-Job $job1 -Force
    Remove-Job $job1
    Set-Location "..\..\"
}

# Railway 部署
function Deploy-Railway {
    Write-Host "`n部署到 Railway..." -ForegroundColor Yellow
    
    # 检查 Railway CLI
    try {
        railway --version | Out-Null
        Write-Host "✓ Railway CLI 已安装" -ForegroundColor Green
    } catch {
        Write-Host "安装 Railway CLI..." -ForegroundColor Cyan
        npm install -g @railway/cli
    }
    
    # 登录
    Write-Host "请在浏览器中完成 Railway 登录..." -ForegroundColor Yellow
    railway login
    
    # 初始化项目
    railway init
    
    # 部署
    railway up
    
    Write-Host "✓ Railway 部署完成!" -ForegroundColor Green
    Write-Host "查看应用: railway open" -ForegroundColor Cyan
}

# Vercel 部署
function Deploy-Vercel {
    Write-Host "`n部署到 Vercel..." -ForegroundColor Yellow
    
    # 检查 Vercel CLI
    try {
        vercel --version | Out-Null
        Write-Host "✓ Vercel CLI 已安装" -ForegroundColor Green
    } catch {
        Write-Host "安装 Vercel CLI..." -ForegroundColor Cyan
        npm install -g vercel
    }
    
    # 登录
    Write-Host "请在浏览器中完成 Vercel 登录..." -ForegroundColor Yellow
    vercel login
    
    # 部署
    vercel --prod
    
    Write-Host "✓ Vercel 部署完成!" -ForegroundColor Green
}

# Render 部署
function Deploy-Render {
    Write-Host "`n部署到 Render..." -ForegroundColor Yellow
    Write-Host "请按照以下步骤在 Render 控制台操作:" -ForegroundColor Cyan
    Write-Host "1. 访问 https://render.com" -ForegroundColor White
    Write-Host "2. 连接您的 GitHub 账号" -ForegroundColor White
    Write-Host "3. 选择 cex-exchange 仓库" -ForegroundColor White
    Write-Host "4. 使用 render.yaml 配置文件" -ForegroundColor White
    Write-Host "5. 点击 'Create Web Service'" -ForegroundColor White
    
    Write-Host "`n配置已准备就绪，render.yaml 文件包含所有必要设置" -ForegroundColor Green
}

# Netlify 部署
function Deploy-Netlify {
    Write-Host "`n部署到 Netlify..." -ForegroundColor Yellow
    
    # 检查 Netlify CLI
    try {
        netlify --version | Out-Null
        Write-Host "✓ Netlify CLI 已安装" -ForegroundColor Green
    } catch {
        Write-Host "安装 Netlify CLI..." -ForegroundColor Cyan
        npm install -g netlify-cli
    }
    
    # 登录
    Write-Host "请在浏览器中完成 Netlify 登录..." -ForegroundColor Yellow
    netlify login
    
    # 初始化
    netlify init
    
    # 部署
    netlify deploy --prod --dir .
    
    Write-Host "✓ Netlify 部署完成!" -ForegroundColor Green
}

# 提交更改
function Commit-Changes {
    Write-Host "`n提交部署配置..." -ForegroundColor Yellow
    
    git add .
    git commit -m "feat: 添加 $Platform 部署配置

- 配置自动化部署流程
- 添加环境变量设置
- 优化构建和启动脚本
- 准备生产环境部署

Platform: $Platform"
    
    git push origin main
    
    Write-Host "✓ 配置已推送到 GitHub" -ForegroundColor Green
}

# 显示部署信息
function Show-DeploymentInfo {
    Write-Host "`n=== 部署完成 ===" -ForegroundColor Green
    Write-Host "平台: $Platform" -ForegroundColor Yellow
    
    switch ($Platform) {
        "railway" {
            Write-Host "管理控制台: https://railway.app/dashboard" -ForegroundColor Cyan
            Write-Host "查看应用: railway open" -ForegroundColor Cyan
            Write-Host "查看日志: railway logs" -ForegroundColor Cyan
        }
        "vercel" {
            Write-Host "管理控制台: https://vercel.com/dashboard" -ForegroundColor Cyan
            Write-Host "查看应用: vercel open" -ForegroundColor Cyan
            Write-Host "查看日志: vercel logs" -ForegroundColor Cyan
        }
        "render" {
            Write-Host "管理控制台: https://dashboard.render.com" -ForegroundColor Cyan
            Write-Host "配置文件: render.yaml" -ForegroundColor Cyan
        }
        "netlify" {
            Write-Host "管理控制台: https://app.netlify.com" -ForegroundColor Cyan
            Write-Host "查看应用: netlify open" -ForegroundColor Cyan
        }
    }
    
    Write-Host "`n测试端点:" -ForegroundColor Yellow
    Write-Host "健康检查: /health" -ForegroundColor White
    Write-Host "市场数据: /api/market/ticker?symbol=BTCUSDT" -ForegroundColor White
    Write-Host "透明度: /api/compliance/proof-of-reserves" -ForegroundColor White
    
    Write-Host "`n享受您的 CEX Exchange! 🚀" -ForegroundColor Green
}

# 主流程
try {
    Test-Dependencies
    Build-Project
    Test-Services
    Commit-Changes
    
    switch ($Platform) {
        "railway" { Deploy-Railway }
        "vercel" { Deploy-Vercel }
        "render" { Deploy-Render }
        "netlify" { Deploy-Netlify }
    }
    
    Show-DeploymentInfo
    
} catch {
    Write-Host "`n❌ 部署失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "请检查错误信息并重试" -ForegroundColor Yellow
    exit 1
}