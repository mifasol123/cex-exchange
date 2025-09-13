@echo off
echo === CEX Exchange Services ===

REM Add Go to PATH
set "PATH=%PATH%;C:\Program Files\Go\bin"

echo Checking Go installation...
go version
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Go not found in PATH
    echo Please add Go to your system PATH or restart terminal
    pause
    exit /b 1
)

echo.
echo Starting Market Aggregator on port 8080...
cd /d "%~dp0backend\market-aggregator"
start "Market Service" cmd /k "go run cmd/server/main.go"

echo.
echo Starting Transparency Service on port 8081...
cd /d "%~dp0backend\transparency-service"
start "Transparency Service" cmd /k "go run cmd/server/main.go"

echo.
echo Waiting for services to start...
timeout /t 5 /nobreak > nul

echo.
echo Testing services...
cd /d "%~dp0"

echo Testing Market Service Health...
curl -s http://localhost:8080/health || echo FAILED

echo Testing BTC Price...
curl -s "http://localhost:8080/public/market/ticker?symbol=BTCUSDT" || echo FAILED

echo Testing Transparency Service...
curl -s http://localhost:8081/compliance/proof-of-reserves || echo FAILED

echo.
echo === Services Started ===
echo Market Data: http://localhost:8080
echo Transparency: http://localhost:8081
echo Frontend Demo: crypto-exchange-complete.html
echo.
echo Press any key to continue...
pause
