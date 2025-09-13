package handler

import (
	"net/http"
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
	
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now(),
		Service:   "market-aggregator",
		Version:   "0.1.0-dev",
		Uptime:    uptime.String(),
	}

	c.JSON(http.StatusOK, response)
}