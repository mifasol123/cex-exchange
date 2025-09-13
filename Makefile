# CEX Exchange Makefile
# 支持 Windows PowerShell 和 Linux/macOS

# 检测操作系统
ifeq ($(OS),Windows_NT)
    SHELL := powershell.exe
    .SHELLFLAGS := -NoProfile -Command
    RM = Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    MKDIR = New-Item -ItemType Directory -Force
    COPY = Copy-Item
    WHICH = Get-Command
else
    RM = rm -rf
    MKDIR = mkdir -p
    COPY = cp
    WHICH = which
endif

# 项目变量
PROJECT_NAME := cex-exchange
VERSION := 1.0.0
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Go 变量
GO_VERSION := 1.21
GOPATH := $(shell go env GOPATH 2>/dev/null)
GOOS := $(shell go env GOOS 2>/dev/null)
GOARCH := $(shell go env GOARCH 2>/dev/null)

# 服务路径
MARKET_SERVICE := backend/market-aggregator
TRANSPARENCY_SERVICE := backend/transparency-service

# Docker 变量
DOCKER_COMPOSE := docker-compose
DOCKER_COMPOSE_FILE := docker-compose.yml

.PHONY: help setup dev build test clean docker-up docker-down logs frontend check-env install-deps

# 帮助信息
.DEFAULT_GOAL := help

help: ## 显示帮助信息
	@echo ""
	@echo "CEX Exchange - 企业级数字货币交易所"
	@echo ""
	@echo "可用命令:"
	@echo "  help         - 显示帮助信息"
	@echo "  setup        - 初始化开发环境"
	@echo "  dev          - 启动本地开发服务"
	@echo "  build        - 构建 Docker 镜像"
	@echo "  docker-up    - 启动 Docker 服务"
	@echo "  docker-down  - 停止 Docker 服务"
	@echo "  test         - 运行 API 测试"
	@echo "  logs         - 查看服务日志"
	@echo "  frontend     - 打开前端演示"
	@echo "  clean        - 清理资源"
	@echo ""
	@echo "使用示例:"
	@echo "  make setup          # 初始化开发环境"
	@echo "  make dev             # 启动本地开发服务"
	@echo "  make test            # 运行所有测试"
	@echo "  make docker-up       # 启动 Docker 服务"

check-env: ## 检查开发环境
ifeq ($(OS),Windows_NT)
	@powershell -Command "Write-Host '检查 Windows 开发环境...' -ForegroundColor Yellow"
	@powershell -Command "try { go version; Write-Host '  ✓ Go 环境正常' -ForegroundColor Green } catch { Write-Host '  ✗ Go 未安装' -ForegroundColor Red }"
	@powershell -Command "try { docker --version; Write-Host '  ✓ Docker 环境正常' -ForegroundColor Green } catch { Write-Host '  ✗ Docker 未安装' -ForegroundColor Red }"
else
	@echo "检查开发环境..."
	@command -v go >/dev/null 2>&1 && echo "  ✓ Go 环境正常" || echo "  ✗ Go 未安装"
	@command -v docker >/dev/null 2>&1 && echo "  ✓ Docker 环境正常" || echo "  ✗ Docker 未安装"
endif

setup: check-env ## 初始化开发环境
	@echo "初始化开发环境..."
	$(MAKE) install-deps
	@echo "环境设置完成!"

install-deps: ## 安装依赖
ifeq ($(OS),Windows_NT)
	@powershell -Command "Write-Host '安装 Go 依赖...' -ForegroundColor Yellow"
	@cd $(MARKET_SERVICE) && go mod download && go mod tidy
	@cd $(TRANSPARENCY_SERVICE) && go mod download && go mod tidy
else
	@echo "安装 Go 依赖..."
	@cd $(MARKET_SERVICE) && go mod download && go mod tidy
	@cd $(TRANSPARENCY_SERVICE) && go mod download && go mod tidy
endif

dev: ## 启动本地开发服务
	@echo "启动本地开发服务..."
	@echo "Market Aggregator: http://localhost:8080"
	@echo "Transparency Service: http://localhost:8081"
	@echo "Frontend Demo: crypto-exchange-complete.html"
	@cd $(MARKET_SERVICE) && go run cmd/server/main.go &
	@cd $(TRANSPARENCY_SERVICE) && go run cmd/server/main.go &
	@echo "服务已启动，按 Ctrl+C 停止"

build: ## 构建 Docker 镜像
	$(DOCKER_COMPOSE) build

docker-up: ## 启动 Docker 服务
	$(DOCKER_COMPOSE) up -d
	@echo "服务已启动:"
	@echo "  Kong Gateway: http://localhost:8000"
	@echo "  Kong Admin: http://localhost:8001"
	@echo "  Market Data: http://localhost:8080"
	@echo "  Transparency: http://localhost:8081"

docker-down: ## 停止 Docker 服务
	$(DOCKER_COMPOSE) down

logs: ## 查看服务日志
	$(DOCKER_COMPOSE) logs -f

test: ## 运行 API 测试
	@echo "测试 API 端点..."
ifeq ($(OS),Windows_NT)
	@powershell -Command "try { Invoke-RestMethod http://localhost:8080/health | ConvertTo-Json; Write-Host '  ✓ Market service OK' -ForegroundColor Green } catch { Write-Host '  ✗ Market service 未响应' -ForegroundColor Red }"
	@powershell -Command "try { Invoke-RestMethod http://localhost:8081/health | ConvertTo-Json; Write-Host '  ✓ Transparency service OK' -ForegroundColor Green } catch { Write-Host '  ✗ Transparency service 未响应' -ForegroundColor Red }"
else
	@curl -s http://localhost:8080/health | jq . || echo "  ✗ Market service 未响应"
	@curl -s http://localhost:8081/health | jq . || echo "  ✗ Transparency service 未响应"
	@curl -s "http://localhost:8080/public/market/ticker?symbol=BTCUSDT" | jq . || echo "  ✗ Ticker endpoint 失败"
endif

frontend: ## 打开前端演示
	@echo "打开前端演示..."
ifeq ($(OS),Windows_NT)
	@powershell -Command "Start-Process crypto-exchange-complete.html"
else
	@open crypto-exchange-complete.html 2>/dev/null || xdg-open crypto-exchange-complete.html 2>/dev/null || echo "请手动打开 crypto-exchange-complete.html"
endif

clean: ## 清理资源
	$(DOCKER_COMPOSE) down -v
	docker system prune -f
