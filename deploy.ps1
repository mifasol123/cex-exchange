# CEX Exchange 一键部署脚本
param(
    [string]$Platform = "github",  # github, vercel, netlify
    [switch]$SkipBuild = $false
)

Write-Host "=== CEX Exchange 一键部署 ===" -ForegroundColor Green
Write-Host "部署平台: $Platform" -ForegroundColor Cyan

# 检查Git状态
if (-not (Test-Path ".git")) {
    Write-Host "初始化Git仓库..." -ForegroundColor Yellow
    git init
    git add .
    git commit -m "Initial commit: CEX Exchange"
}

# 构建前端 (如果需要)
if (-not $SkipBuild) {
    Write-Host "准备部署文件..." -ForegroundColor Yellow
    
    # 复制部署文件到根目录
    Copy-Item "deploy/index.html" "index.html" -Force
    Copy-Item "deploy/manifest.json" "manifest.json" -Force  
    Copy-Item "deploy/sw.js" "sw.js" -Force
    
    # 创建简单的图标文件 (占位符)
    $iconSvg = @"
<svg width="192" height="192" xmlns="http://www.w3.org/2000/svg">
  <rect width="192" height="192" fill="#3b82f6"/>
  <text x="96" y="110" text-anchor="middle" fill="white" font-size="48" font-family="Arial">CEX</text>
</svg>
"@
    $iconSvg | Out-File -FilePath "icon.svg" -Encoding UTF8
    
    Write-Host "✅ 部署文件准备完成" -ForegroundColor Green
}

switch ($Platform.ToLower()) {
    "github" {
        Write-Host "`n=== GitHub Pages 部署 ===" -ForegroundColor Cyan
        
        # 检查GitHub远程仓库
        $remoteUrl = git remote get-url origin 2>$null
        if (-not $remoteUrl) {
            Write-Host "请先设置GitHub远程仓库:" -ForegroundColor Yellow
            Write-Host "1. 在GitHub创建新仓库" -ForegroundColor White
            Write-Host "2. 运行: git remote add origin https://github.com/username/repo.git" -ForegroundColor White
            Write-Host "3. 重新运行此脚本" -ForegroundColor White
            exit 1
        }
        
        # 提交并推送
        git add .
        git commit -m "Deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git push -u origin main
        
        Write-Host "✅ 代码已推送到GitHub" -ForegroundColor Green
        Write-Host "请在GitHub仓库设置中启用Pages (Settings > Pages > Source: Deploy from a branch > main)" -ForegroundColor Yellow
        Write-Host "部署URL将是: https://username.github.io/repository-name" -ForegroundColor Cyan
    }
    
    "vercel" {
        Write-Host "`n=== Vercel 部署 ===" -ForegroundColor Cyan
        
        # 检查Vercel CLI
        try {
            vercel --version | Out-Null
            Write-Host "✅ Vercel CLI已安装" -ForegroundColor Green
        } catch {
            Write-Host "安装Vercel CLI..." -ForegroundColor Yellow
            npm install -g vercel
        }
        
        # 部署
        Write-Host "开始部署到Vercel..." -ForegroundColor Yellow
        vercel --prod --yes
        
        Write-Host "✅ Vercel部署完成" -ForegroundColor Green
    }
    
    "netlify" {
        Write-Host "`n=== Netlify 部署 ===" -ForegroundColor Cyan
        
        # 检查Netlify CLI
        try {
            netlify --version | Out-Null
            Write-Host "✅ Netlify CLI已安装" -ForegroundColor Green
        } catch {
            Write-Host "安装Netlify CLI..." -ForegroundColor Yellow
            npm install -g netlify-cli
        }
        
        # 部署
        Write-Host "开始部署到Netlify..." -ForegroundColor Yellow
        netlify deploy --prod --dir=.
        
        Write-Host "✅ Netlify部署完成" -ForegroundColor Green
    }
    
    default {
        Write-Host "不支持的平台: $Platform" -ForegroundColor Red
        Write-Host "支持的平台: github, vercel, netlify" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n=== 部署完成 ===" -ForegroundColor Green
Write-Host "功能特性:" -ForegroundColor White
Write-Host "✅ 实时Binance市场数据" -ForegroundColor Green
Write-Host "✅ WebSocket实时更新" -ForegroundColor Green  
Write-Host "✅ PWA支持 (可安装到手机)" -ForegroundColor Green
Write-Host "✅ 响应式设计" -ForegroundColor Green
Write-Host "✅ 离线缓存" -ForegroundColor Green

Write-Host "`n测试你的部署:" -ForegroundColor Cyan
Write-Host "1. 访问部署URL" -ForegroundColor White
Write-Host "2. 检查实时价格更新" -ForegroundColor White
Write-Host "3. 测试移动端体验" -ForegroundColor White
Write-Host "4. 尝试离线访问" -ForegroundColor White
