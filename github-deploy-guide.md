# 🚀 GitHub Pages 部署指南

## 步骤1: 创建GitHub仓库

1. 访问 [github.com](https://github.com) 并登录
2. 点击右上角 "+" → "New repository"
3. 填写仓库信息:
   - **Repository name**: `cex-exchange`
   - **Description**: `Professional Cryptocurrency Exchange`
   - **Public** (必须选择Public才能使用免费GitHub Pages)
   - ✅ 勾选 "Add a README file"
4. 点击 "Create repository"

## 步骤2: 上传项目文件

### 方法A: 网页上传 (推荐新手)
1. 在新创建的仓库页面，点击 "uploading an existing file"
2. 拖拽以下文件到上传区域:
   ```
   ✅ index.html (主页面)
   ✅ manifest.json (PWA配置)
   ✅ sw.js (离线支持)
   ✅ crypto-exchange-complete.html (完整版)
   ```
3. 在底部填写提交信息: "Deploy CEX Exchange"
4. 点击 "Commit changes"

### 方法B: Git命令行 (推荐开发者)
```bash
git clone https://github.com/你的用户名/cex-exchange.git
cd cex-exchange
# 复制项目文件到此目录
git add .
git commit -m "Deploy CEX Exchange"
git push origin main
```

## 步骤3: 启用GitHub Pages

1. 进入仓库页面
2. 点击 "Settings" 标签页
3. 在左侧菜单中找到 "Pages"
4. 在 "Source" 部分:
   - 选择 "Deploy from a branch"
   - Branch: 选择 "main"
   - Folder: 保持 "/ (root)"
5. 点击 "Save"

## 步骤4: 访问你的交易所

- **URL格式**: `https://你的用户名.github.io/cex-exchange`
- **生效时间**: 通常5-10分钟
- **示例**: `https://johndoe.github.io/cex-exchange`

## 🔧 自定义域名 (可选)

如果你有自己的域名:

1. 在仓库根目录创建 `CNAME` 文件
2. 文件内容写入你的域名: `exchange.yourdomain.com`
3. 在域名DNS设置中添加CNAME记录指向: `你的用户名.github.io`

## 📱 验证部署成功

访问你的网站后检查:

- [ ] 页面正常加载
- [ ] 显示实时BTC价格
- [ ] WebSocket状态显示"已连接"
- [ ] 可以切换不同交易对
- [ ] 移动端显示正常
- [ ] 可以"添加到主屏幕"(PWA功能)

## 🛠️ 更新网站

每次修改后:
1. 上传新文件到GitHub仓库
2. 等待2-3分钟自动部署
3. 刷新网站查看更新

## 🆘 常见问题

**Q: 页面显示404**
A: 确保GitHub Pages已正确启用，等待5-10分钟生效

**Q: 数据不更新**
A: 检查浏览器控制台(F12)是否有错误信息

**Q: 移动端显示异常**
A: 清除浏览器缓存后重试

---

## 🎉 部署完成！

你的专业级数字货币交易所现已上线！

**功能特色:**
- 实时Binance市场数据
- 专业交易界面
- PWA移动应用支持
- 企业级安全防护
- 全球CDN加速

**下一步:**
- 分享你的交易所URL
- 在手机上安装PWA版本
- 考虑添加自定义域名
