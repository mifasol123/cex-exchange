package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/mifasol123/cex-exchange/backend/market-aggregator/internal/handler"
	"github.com/mifasol123/cex-exchange/backend/market-aggregator/internal/service"
	"github.com/mifasol123/cex-exchange/backend/market-aggregator/pkg/client"
	"github.com/patrickmn/go-cache"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	// Configure logger
	zerolog.TimeFieldFormat = time.RFC3339
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})

	// Get port from environment
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Initialize cache
	cacheInstance := cache.New(30*time.Second, 1*time.Minute)

	// Initialize clients
	binanceClient := client.NewBinanceClient()
	coinGeckoClient := client.NewCoinGeckoClient()

	// Initialize services
	marketService := service.NewMarketService(binanceClient, coinGeckoClient, cacheInstance)

	// Initialize handlers
	marketHandler := handler.NewMarketHandler(marketService)
	healthHandler := handler.NewHealthHandler()

	// Setup router
	router := setupRouter(marketHandler, healthHandler)

	// Create server
	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// Start server in goroutine
	go func() {
		log.Info().Str("port", port).Msg("Starting market aggregator service")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("Failed to start server")
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Info().Msg("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatal().Err(err).Msg("Server forced to shutdown")
	}

	log.Info().Msg("Server exited")
}

func setupRouter(marketHandler *handler.MarketHandler, healthHandler *handler.HealthHandler) *gin.Engine {
	// Set gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Middlewares
	router.Use(gin.Logger())
	router.Use(gin.Recovery())
	router.Use(RequestIDMiddleware())
	router.Use(LoggerMiddleware())

	// CORS configuration
	corsConfig := cors.DefaultConfig()
	corsOrigins := os.Getenv("CORS_ORIGINS")
	if corsOrigins != "" {
		if corsOrigins == "*" {
			corsConfig.AllowAllOrigins = true
		} else {
			corsConfig.AllowOrigins = []string{corsOrigins}
		}
	} else {
		corsConfig.AllowAllOrigins = true
	}
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization", "X-Request-ID"}
	router.Use(cors.New(corsConfig))

	// Health check
	router.GET("/health", healthHandler.Health)

	// Public market data routes
	public := router.Group("/public")
	{
		market := public.Group("/market")
		{
			market.GET("/ticker", marketHandler.GetTicker)
			market.GET("/klines", marketHandler.GetKlines)
			market.GET("/depth", marketHandler.GetDepth)
		}
	}

	return router
}

// RequestIDMiddleware generates a unique request ID for each request
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = generateRequestID()
		}
		c.Header("X-Request-ID", requestID)
		c.Set("request_id", requestID)
		c.Next()
	}
}

// LoggerMiddleware logs requests with structured logging
func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		param := gin.LogFormatterParams{
			Request:    c.Request,
			StatusCode: c.Writer.Status(),
			Latency:    time.Since(start),
			ClientIP:   c.ClientIP(),
			Method:     c.Request.Method,
			Path:       path,
		}

		if raw != "" {
			path = path + "?" + raw
		}

		requestID, _ := c.Get("request_id")
		log.Info().
			Str("request_id", fmt.Sprintf("%v", requestID)).
			Str("method", param.Method).
			Str("path", path).
			Int("status", param.StatusCode).
			Dur("latency", param.Latency).
			Str("client_ip", param.ClientIP).
			Msg("Request completed")
	}
}

func generateRequestID() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}