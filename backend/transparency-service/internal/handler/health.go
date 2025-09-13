package handler

import (
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

type HealthHandler struct{}

type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Service   string    `json:"service"`
	Version   string    `json:"version"`
	Uptime    string    `json:"uptime"`
}

var startTime = time.Now()

func NewHealthHandler() *HealthHandler {
	return &HealthHandler{}
}

func (h *HealthHandler) Health(c *gin.Context) {
	uptime := time.Since(startTime)
	version := os.Getenv("SERVICE_VERSION")
	if version == "" {
		version = "0.1.0-dev"
	}

	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Service:   "transparency-service",
		Version:   version,
		Uptime:    uptime.String(),
	}

	c.JSON(http.StatusOK, response)
}
