# Render 免费部署一键脚本
Write-Host "=== Render 免费部署指南 ===" -ForegroundColor Green
Write-Host "Railway受限后的最佳免费替代方案" -ForegroundColor Yellow

Write-Host "`n📋 Render免费优势:" -ForegroundColor Cyan
Write-Host "  ✅ 750小时/月运行时间 (比Railway更多)" -ForegroundColor Green
Write-Host "  ✅ 支持Go微服务架构" -ForegroundColor Green
Write-Host "  ✅ 免费PostgreSQL数据库" -ForegroundColor Green
Write-Host "  ✅ 自动HTTPS和域名" -ForegroundColor Green
Write-Host "  ✅ GitHub集成，代码推送自动部署" -ForegroundColor Green
Write-Host "  ✅ 无需信用卡，真正免费" -ForegroundColor Green

Write-Host "`n🚀 立即部署步骤:" -ForegroundColor Yellow

Write-Host "`n第1步: 访问Render" -ForegroundColor Cyan
Write-Host "  🌐 打开浏览器访问: https://render.com" -ForegroundColor White
Write-Host "  👆 点击右上角 'Get Started'" -ForegroundColor White

Write-Host "`n第2步: GitHub登录" -ForegroundColor Cyan
Write-Host "  🔐 选择 'GitHub' 登录方式" -ForegroundColor White
Write-Host "  ✅ 授权Render访问您的仓库" -ForegroundColor White

Write-Host "`n第3步: 创建Web Service" -ForegroundColor Cyan
Write-Host "  🌐 在Dashboard点击 'New +'" -ForegroundColor White
Write-Host "  📱 选择 'Web Service'" -ForegroundColor White

Write-Host "`n第4步: 连接仓库" -ForegroundColor Cyan
Write-Host "  📂 搜索并选择 'cex-exchange'" -ForegroundColor White
Write-Host "  ✅ 点击 'Connect'" -ForegroundColor White

Write-Host "`n第5步: 配置服务" -ForegroundColor Cyan
Write-Host "  📝 填写以下配置:" -ForegroundColor White
Write-Host "    Name: cex-market-aggregator" -ForegroundColor Gray
Write-Host "    Environment: Go" -ForegroundColor Gray
Write-Host "    Region: Oregon (US West) - 免费" -ForegroundColor Gray
Write-Host "    Branch: main" -ForegroundColor Gray

Write-Host "`n第6步: 构建配置" -ForegroundColor Cyan
Write-Host "  🔧 Build Command:" -ForegroundColor White
Write-Host "    cd backend/market-aggregator && go mod download && go build -o main cmd/server/main.go" -ForegroundColor Gray
Write-Host "  🚀 Start Command:" -ForegroundColor White
Write-Host "    cd backend/market-aggregator && ./main" -ForegroundColor Gray

Write-Host "`n第7步: 环境变量" -ForegroundColor Cyan
Write-Host "  ⚙️ 添加以下环境变量:" -ForegroundColor White
Write-Host "    PORT = 10000" -ForegroundColor Gray
Write-Host "    GIN_MODE = release" -ForegroundColor Gray
Write-Host "    CORS_ORIGINS = https://mifasol123.github.io" -ForegroundColor Gray
Write-Host "    BINANCE_BASE_URL = https://api.binance.com" -ForegroundColor Gray
Write-Host "    COINGECKO_BASE_URL = https://api.coingecko.com/api/v3" -ForegroundColor Gray

Write-Host "`n第8步: 选择免费计划" -ForegroundColor Cyan
Write-Host "  🆓 Plan Type: Free" -ForegroundColor White
Write-Host "  💰 Cost: `$0.00/month" -ForegroundColor Green
Write-Host "  ⚡ Resources: 0.1 CPU, 512MB RAM" -ForegroundColor White

Write-Host "`n第9步: 部署" -ForegroundColor Cyan
Write-Host "  🚀 点击 'Create Web Service'" -ForegroundColor White
Write-Host "  ⏱️ 等待5-10分钟完成构建和部署" -ForegroundColor White

Write-Host "`n🎯 部署完成后:" -ForegroundColor Yellow
Write-Host "  🌐 您将获得类似这样的URL:" -ForegroundColor White
Write-Host "     https://cex-market-aggregator.onrender.com" -ForegroundColor Cyan
Write-Host "  🔍 测试健康检查:" -ForegroundColor White
Write-Host "     https://your-app.onrender.com/health" -ForegroundColor Cyan
Write-Host "  📊 测试API:" -ForegroundColor White
Write-Host "     https://your-app.onrender.com/public/market/ticker?symbol=BTCUSDT" -ForegroundColor Cyan

Write-Host "`n✨ 前端自动连接:" -ForegroundColor Yellow
Write-Host "  📱 访问: https://mifasol123.github.io/cex-exchange" -ForegroundColor Cyan
Write-Host "  ✅ 查看后端状态指示器变为绿色" -ForegroundColor Green
Write-Host "  🔄 前端会自动检测并连接新的后端" -ForegroundColor White

Write-Host "`n📊 免费资源监控:" -ForegroundColor Yellow
Write-Host "  ⏰ 750小时/月 = 约31天运行时间" -ForegroundColor Green
Write-Host "  💾 512MB内存，足够Go微服务使用" -ForegroundColor Green
Write-Host "  🌐 100GB/月带宽，支持大量API调用" -ForegroundColor Green
Write-Host "  😴 无活动15分钟后自动睡眠，访问时自动唤醒" -ForegroundColor Yellow

Write-Host "`n🛠️ 项目已优化:" -ForegroundColor Cyan
Write-Host "  ✅ render.yaml 配置文件已创建" -ForegroundColor Green
Write-Host "  ✅ 环境变量针对免费层优化" -ForegroundColor Green  
Write-Host "  ✅ 构建命令适配Render要求" -ForegroundColor Green
Write-Host "  ✅ CORS配置支持GitHub Pages" -ForegroundColor Green

Write-Host "`n🎊 开始部署:" -ForegroundColor Green
Write-Host "  👆 现在就访问 https://render.com 开始部署!" -ForegroundColor Cyan
Write-Host "  📞 如有问题，参考 ALTERNATIVE_FREE_DEPLOY.md 详细指南" -ForegroundColor White

Write-Host "`n💡 提示:" -ForegroundColor Yellow
Write-Host "  🔄 Render比Railway更稳定，免费额度更慷慨" -ForegroundColor White
Write-Host "  🚀 部署后您将拥有完全免费的企业级交易所!" -ForegroundColor Green

Read-Host "`n按Enter继续或Ctrl+C退出"