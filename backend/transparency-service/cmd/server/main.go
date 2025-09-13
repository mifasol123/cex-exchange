package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/mifasol123/cex-exchange/backend/transparency-service/internal/handler"
	"github.com/mifasol123/cex-exchange/backend/transparency-service/internal/service"
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
		port = "8081"
	}

	// Initialize services
	transparencyService := service.NewTransparencyService()

	// Initialize handlers
	complianceHandler := handler.NewComplianceHandler(transparencyService)
	healthHandler := handler.NewHealthHandler()

	// Setup router
	router := setupRouter(complianceHandler, healthHandler)

	// Create server
	srv := &http.Server{
		Addr:    ":" + port,
		Handler: router,
	}

	// Start server in goroutine
	go func() {
		log.Info().Str("port", port).Msg("Starting transparency service")
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

func setupRouter(complianceHandler *handler.ComplianceHandler, healthHandler *handler.HealthHandler) *gin.Engine {
	// Set gin mode
	if os.Getenv("GIN_MODE") == "" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()

	// Middlewares
	router.Use(gin.Logger())
	router.Use(gin.Recovery())

	// CORS configuration
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowAllOrigins = true
	corsConfig.AllowMethods = []string{"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}
	corsConfig.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization", "X-Request-ID"}
	router.Use(cors.New(corsConfig))

	// Health check
	router.GET("/health", healthHandler.Health)

	// Compliance routes
	compliance := router.Group("/compliance")
	{
		compliance.GET("/proof-of-reserves", complianceHandler.GetProofOfReserves)
		compliance.GET("/system-status", complianceHandler.GetSystemStatus)
		compliance.GET("/audit-logs", complianceHandler.GetAuditLogs)
	}

	return router
}
