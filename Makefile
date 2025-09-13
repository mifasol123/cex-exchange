.PHONY: help build up down logs test clean dev

# Default target
help:
	@echo "CEX Exchange Development Commands"
	@echo ""
	@echo "Available commands:"
	@echo "  make dev         - Start services in development mode"
	@echo "  make build       - Build all Docker images"
	@echo "  make up          - Start all services with Docker Compose"
	@echo "  make down        - Stop all services"
	@echo "  make logs        - View logs from all services"
	@echo "  make test        - Run API tests"
	@echo "  make clean       - Clean up Docker resources"
	@echo "  make frontend    - Open frontend demo in browser"

# Development mode (native Go processes)
dev:
	@echo "Starting services in development mode..."
	@echo "Market Aggregator: http://localhost:8080"
	@echo "Transparency Service: http://localhost:8081"
	@echo "Frontend Demo: file://$(PWD)/crypto-exchange-complete.html"
	@cd backend/market-aggregator && go run cmd/server/main.go &
	@cd backend/transparency-service && go run cmd/server/main.go &
	@echo "Services started. Press Ctrl+C to stop."

# Docker operations
build:
	docker-compose build

up:
	docker-compose up -d
	@echo "Services started:"
	@echo "  Kong Gateway: http://localhost:8000"
	@echo "  Kong Admin: http://localhost:8001"
	@echo "  Market Data: http://localhost:8080"
	@echo "  Transparency: http://localhost:8081"

down:
	docker-compose down

logs:
	docker-compose logs -f

# API Testing
test:
	@echo "Testing API endpoints..."
	@curl -s http://localhost:8080/health | jq . || echo "Market service not responding"
	@curl -s http://localhost:8081/health | jq . || echo "Transparency service not responding"
	@curl -s "http://localhost:8080/public/market/ticker?symbol=BTCUSDT" | jq . || echo "Ticker endpoint failed"
	@curl -s "http://localhost:8081/compliance/proof-of-reserves" | jq . || echo "PoR endpoint failed"

# Cleanup
clean:
	docker-compose down -v
	docker system prune -f

# Open frontend
frontend:
	@echo "Opening frontend demo..."
	@start crypto-exchange-complete.html 2>/dev/null || open crypto-exchange-complete.html 2>/dev/null || xdg-open crypto-exchange-complete.html 2>/dev/null || echo "Please open crypto-exchange-complete.html manually"
