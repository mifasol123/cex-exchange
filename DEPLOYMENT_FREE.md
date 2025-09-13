# 🚀 CEX Exchange 免费部署指南

本指南将帮您使用免费平台部署 CEX Exchange 系统。

## 📋 部署选项对比

| 平台 | 前端 | 后端 | 数据库 | 免费额度 | 推荐指数 |
|------|------|------|--------|----------|----------|
| **Vercel** | ✅ | ✅ Go | ❌ | 100GB带宽/月 | ⭐⭐⭐⭐⭐ |
| **Railway** | ✅ | ✅ | ✅ PostgreSQL | 500小时/月 | ⭐⭐⭐⭐⭐ |
| **Render** | ✅ | ✅ | ✅ PostgreSQL | 750小时/月 | ⭐⭐⭐⭐ |
| **Netlify** | ✅ | ❌ | ❌ | 100GB带宽/月 | ⭐⭐⭐ |

## 🚀 方案一：Railway 部署（推荐）

### 优势
- ✅ 支持 Go 微服务
- ✅ 免费 PostgreSQL 数据库
- ✅ 自动 HTTPS
- ✅ 简单配置

### 部署步骤

1. **注册 Railway 账号**
   - 访问 [railway.app](https://railway.app)
   - 使用 GitHub 账号登录

2. **创建新项目**
   ```bash
   # 选择 "Deploy from GitHub repo"
   # 选择您的 cex-exchange 仓库
   ```

3. **配置服务**
   - Railway 会自动检测到 `railway.toml` 配置
   - 市场数据服务将部署到 8080 端口
   - 系统会自动分配域名

4. **访问应用**
   ```
   前端: https://your-app.railway.app
   API: https://your-app.railway.app/health
   ```

### 环境变量配置
```bash
# 在 Railway 控制台设置
PORT=8080
GIN_MODE=release
CORS_ORIGINS=*
BINANCE_BASE_URL=https://api.binance.com
COINGECKO_BASE_URL=https://api.coingecko.com/api/v3
```

## 🌐 方案二：Vercel 部署

### 优势
- ✅ 全球 CDN
- ✅ 自动 HTTPS
- ✅ GitHub 集成
- ✅ 无服务器架构

### 部署步骤

1. **安装 Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **登录并部署**
   ```bash
   vercel login
   vercel --prod
   ```

3. **设置环境变量**
   ```bash
   vercel env add GO_VERSION production
   # 输入: 1.21
   
   vercel env add PORT production  
   # 输入: 8080
   
   vercel env add GIN_MODE production
   # 输入: release
   ```

### 配置说明
- 项目已包含 `vercel.json` 配置
- 支持 Go 函数和静态文件托管
- 自动 CORS 配置

## 🔧 方案三：Render 部署

### 优势
- ✅ 免费 PostgreSQL
- ✅ 支持 Docker
- ✅ 自动扩容
- ✅ 健康检查

### 部署步骤

1. **注册 Render 账号**
   - 访问 [render.com](https://render.com)
   - 连接 GitHub 账号

2. **创建 Web Service**
   ```yaml
   # 使用项目中的 render.yaml 配置
   Name: cex-market-aggregator
   Environment: Go
   Build Command: cd backend/market-aggregator && go build -o main cmd/server/main.go
   Start Command: cd backend/market-aggregator && ./main
   ```

3. **配置数据库**
   ```bash
   # 创建 PostgreSQL 数据库
   Database Name: cex_production
   User: cex_user
   ```

## 📱 前端单独部署

### GitHub Pages
```bash
# 推送到 gh-pages 分支
git checkout -b gh-pages
cp index.html crypto-exchange-complete.html manifest.json sw.js ./
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
```

### Netlify
```bash
# 拖拽部署
1. 访问 netlify.com
2. 拖拽项目文件夹到部署区域
3. 自动部署完成
```

## 🔗 域名配置

### 自定义域名
```bash
# Railway
railway domain add your-domain.com

# Vercel  
vercel domains add your-domain.com

# Render
# 在控制台添加自定义域名
```

### DNS 配置
```dns
# A 记录指向平台 IP
A     @     76.76.19.61    # Railway
A     @     76.76.21.21    # Vercel  
A     @     216.24.57.1    # Render

# CNAME 记录
CNAME www   your-app.railway.app
```

## 📊 监控和分析

### 免费监控工具
```bash
# UptimeRobot - 网站监控
https://uptimerobot.com

# Google Analytics - 用户分析  
https://analytics.google.com

# LogRocket - 错误追踪
https://logrocket.com
```

### 健康检查端点
```bash
# 市场数据服务
GET https://your-domain.com/health

# 透明度服务  
GET https://your-domain.com/health

# API 测试
GET https://your-domain.com/api/market/ticker?symbol=BTCUSDT
```

## 🛠️ 故障排除

### 常见问题

1. **Go 模块问题**
   ```bash
   # 解决方案
   go mod tidy
   go mod download
   ```

2. **端口冲突**
   ```bash
   # 检查环境变量
   echo $PORT
   # 确保使用平台分配的端口
   ```

3. **CORS 错误**
   ```bash
   # 检查 CORS 配置
   CORS_ORIGINS=*  # 开发环境
   CORS_ORIGINS=https://your-domain.com  # 生产环境
   ```

4. **API 连接失败**
   ```bash
   # 检查外部 API 访问
   curl https://api.binance.com/api/v3/ping
   ```

### 日志查看
```bash
# Railway
railway logs

# Vercel
vercel logs

# Render  
# 在控制台查看实时日志
```

## 💰 成本优化

### 免费额度管理
```bash
# Railway: 500小时/月
# 建议: 只在需要时运行

# Vercel: 100GB带宽/月  
# 建议: 启用缓存

# Render: 750小时/月
# 建议: 使用睡眠模式
```

### 性能优化
```bash
# 启用 gzip 压缩
# 使用 CDN 加速
# 优化图片大小
# 减少 API 调用频率
```

## 🔄 持续集成

项目已配置 GitHub Actions，自动执行：
- ✅ 代码测试
- ✅ 安全扫描  
- ✅ 自动部署
- ✅ 通知提醒

推送到 `main` 分支即可触发自动部署。

## 📞 获取支持

遇到问题？
1. 查看项目 [Issues](https://github.com/mifasol123/cex-exchange/issues)
2. 参考平台官方文档
3. 联系技术支持

---

**开始部署**: 选择一个平台，按照上述步骤操作即可! 🚀