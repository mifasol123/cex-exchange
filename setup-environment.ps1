# CEX Exchange 环境自动安装脚本
# 适用于 Windows 10/11

param(
    [switch]$SkipGo,
    [switch]$SkipDocker,
    [switch]$TestOnly
)

Write-Host "=== CEX Exchange 环境安装脚本 ===" -ForegroundColor Green
Write-Host "系统: $([Environment]::OSVersion.VersionString)" -ForegroundColor Cyan

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "⚠️ 建议以管理员身份运行以避免权限问题" -ForegroundColor Yellow
}

# 函数：检查工具是否已安装
function Test-Command {
    param($CommandName)
    try {
        $null = Get-Command $CommandName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# 函数：下载文件
function Download-File {
    param($Url, $Output)
    try {
        Write-Host "下载: $Url" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing
        return $true
    } catch {
        Write-Host "下载失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 创建临时目录
$tempDir = Join-Path $env:TEMP "cex-setup"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

Write-Host "`n=== 环境检查 ===" -ForegroundColor Yellow

# 检查 Go
$goInstalled = Test-Command "go"
if ($goInstalled) {
    $goVersion = go version
    Write-Host "✓ Go 已安装: $goVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Go 未安装" -ForegroundColor Red
}

# 检查 Docker
$dockerInstalled = Test-Command "docker"
if ($dockerInstalled) {
    try {
        $dockerVersion = docker --version
        Write-Host "✓ Docker 已安装: $dockerVersion" -ForegroundColor Green
    } catch {
        Write-Host "✗ Docker 已安装但无法运行" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Docker 未安装" -ForegroundColor Red
}

if ($TestOnly) {
    Write-Host "`n=== 仅测试模式，退出 ===" -ForegroundColor Yellow
    exit 0
}

# 安装 Go
if (-not $goInstalled -and -not $SkipGo) {
    Write-Host "`n=== 安装 Go 1.21.13 ===" -ForegroundColor Yellow
    
    $goVersion = "1.21.13"
    $goArch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
    $goUrl = "https://go.dev/dl/go$goVersion.windows-$goArch.msi"
    $goInstaller = Join-Path $tempDir "go-installer.msi"
    
    if (Download-File $goUrl $goInstaller) {
        Write-Host "启动 Go 安装程序..." -ForegroundColor Cyan
        Write-Host "请按照安装向导完成 Go 安装，然后重新运行此脚本。" -ForegroundColor Yellow
        Start-Process -FilePath $goInstaller -Wait
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        if (Test-Command "go") {
            Write-Host "✓ Go 安装成功!" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Go 安装完成，但可能需要重启终端或重新登录" -ForegroundColor Yellow
        }
    }
}

# 安装 Docker Desktop
if (-not $dockerInstalled -and -not $SkipDocker) {
    Write-Host "`n=== 安装 Docker Desktop ===" -ForegroundColor Yellow
    
    $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $dockerInstaller = Join-Path $tempDir "docker-installer.exe"
    
    Write-Host "Docker Desktop 需要:" -ForegroundColor Cyan
    Write-Host "- Windows 10 版本 2004 及更高版本 (build 19041 及更高版本)" -ForegroundColor White
    Write-Host "- 启用 WSL 2 功能" -ForegroundColor White
    Write-Host "- 启用虚拟化功能" -ForegroundColor White
    
    $installDocker = Read-Host "是否继续安装 Docker Desktop? (y/N)"
    if ($installDocker -eq "y" -or $installDocker -eq "Y") {
        if (Download-File $dockerUrl $dockerInstaller) {
            Write-Host "启动 Docker Desktop 安装程序..." -ForegroundColor Cyan
            Write-Host "请按照安装向导完成安装，安装后需要重启系统。" -ForegroundColor Yellow
            Start-Process -FilePath $dockerInstaller -Wait
        }
    }
}

Write-Host "`n=== 环境配置建议 ===" -ForegroundColor Yellow

if (-not $goInstalled) {
    Write-Host "Go 安装后，请确保以下环境变量正确设置:" -ForegroundColor Cyan
    Write-Host "- GOPATH: $env:USERPROFILE\go" -ForegroundColor White
    Write-Host "- PATH: 包含 $env:USERPROFILE\go\bin" -ForegroundColor White
}

if (-not $dockerInstalled) {
    Write-Host "Docker Desktop 安装后:" -ForegroundColor Cyan
    Write-Host "- 重启系统" -ForegroundColor White
    Write-Host "- 启动 Docker Desktop" -ForegroundColor White
    Write-Host "- 确保 WSL 2 正常工作" -ForegroundColor White
}

Write-Host "`n=== 下一步 ===" -ForegroundColor Green
Write-Host "1. 重启终端或重新登录" -ForegroundColor White
Write-Host "2. 运行: .\setup-environment.ps1 -TestOnly" -ForegroundColor White
Write-Host "3. 如果环境正常，运行: .\test-stack.ps1" -ForegroundColor White

# 清理临时文件
Write-Host "`n清理临时文件..." -ForegroundColor Gray
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== 安装完成 ===" -ForegroundColor Green
