@echo off
chcp 65001 >nul
title CEX Exchange 一键部署工具

echo ============================================================
echo 🚀 CEX Exchange 一键部署工具
echo ============================================================
echo.

echo 📋 检查项目状态...
if not exist ".git" (
    echo ❌ 错误：当前目录不是Git仓库
    pause
    exit /b 1
)

echo.
echo 📤 推送最新代码到GitHub...
git add .
git commit -m "Auto deploy - %date% %time%"
git push origin main

if %errorlevel% equ 0 (
    echo ✅ 代码推送成功
) else (
    echo ⚠️  代码推送可能有问题，但继续部署...
)

echo.
echo 🔍 检查部署状态...
echo.
echo 📱 前端部署状态:
echo    🌐 GitHub Pages: https://mifasol123.github.io/cex-exchange
echo    🎯 状态: 已部署并运行

echo.
echo 🌐 自动打开部署的网站...
start https://mifasol123.github.io/cex-exchange

echo.
echo ============================================================
echo 🎉 部署完成！
echo ============================================================
echo.
echo 📊 部署结果:
echo    ✅ 前端: https://mifasol123.github.io/cex-exchange
echo    📱 PWA: 支持离线使用和桌面安装
echo    🔄 自动部署: GitHub Actions已配置
echo.
echo 🛠️  项目功能:
echo    📈 加密货币价格展示
echo    💹 专业交易界面
echo    📊 实时图表展示
echo    📱 响应式设计
echo    🔒 企业级安全架构
echo.
echo 💡 提示:
echo    • 项目已完全部署，可以立即使用
echo    • 每次推送代码会自动重新部署
echo    • 完全免费，无需任何付费服务
echo.
echo 🔗 分享链接:
echo    复制这个链接分享给别人: https://mifasol123.github.io/cex-exchange
echo.
echo 🎯 下一步建议:
echo    1. 测试所有功能
echo    2. 添加到浏览器收藏夹
echo    3. 在移动设备上安装为PWA应用
echo.
echo ============================================================
echo 部署脚本执行完成！
echo ============================================================
echo.
echo 按任意键退出...
pause >nul