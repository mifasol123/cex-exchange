package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/mifasol123/cex-exchange/backend/market-aggregator/internal/service"
	"github.com/rs/zerolog/log"
)

type MarketHandler struct {
	marketService *service.MarketService
}

type ErrorResponse struct {
	Error     string `json:"error"`
	Code      string `json:"code"`
	RequestID string `json:"request_id"`
	Timestamp int64  `json:"timestamp"`
}

func NewMarketHandler(marketService *service.MarketService) *MarketHandler {
	return &MarketHandler{
		marketService: marketService,
	}
}

func (h *MarketHandler) GetTicker(c *gin.Context) {
	symbol := c.Query("symbol")
	if symbol == "" {
		h.respondError(c, http.StatusBadRequest, "MISSING_SYMBOL", "symbol parameter is required")
		return
	}

	// Validate symbol format (basic validation)
	if len(symbol) < 6 || len(symbol) > 12 {
		h.respondError(c, http.StatusBadRequest, "INVALID_SYMBOL", "symbol format is invalid")
		return
	}

	ticker, err := h.marketService.GetTicker(symbol)
	if err != nil {
		log.Error().Err(err).Str("symbol", symbol).Msg("Failed to get ticker")
		h.respondError(c, http.StatusServiceUnavailable, "TICKER_UNAVAILABLE", "unable to fetch ticker data")
		return
	}

	c.JSON(http.StatusOK, ticker)
}

func (h *MarketHandler) GetKlines(c *gin.Context) {
	symbol := c.Query("symbol")
	if symbol == "" {
		h.respondError(c, http.StatusBadRequest, "MISSING_SYMBOL", "symbol parameter is required")
		return
	}

	interval := c.DefaultQuery("interval", "1h")
	limitStr := c.DefaultQuery("limit", "100")

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 || limit > 1000 {
		h.respondError(c, http.StatusBadRequest, "INVALID_LIMIT", "limit must be between 1 and 1000")
		return
	}

	// Validate interval
	validIntervals := map[string]bool{
		"1m": true, "3m": true, "5m": true, "15m": true, "30m": true,
		"1h": true, "2h": true, "4h": true, "6h": true, "8h": true, "12h": true,
		"1d": true, "3d": true, "1w": true, "1M": true,
	}
	if !validIntervals[interval] {
		h.respondError(c, http.StatusBadRequest, "INVALID_INTERVAL", "invalid interval format")
		return
	}

	klines, err := h.marketService.GetKlines(symbol, interval, limit)
	if err != nil {
		log.Error().Err(err).Str("symbol", symbol).Str("interval", interval).Msg("Failed to get klines")
		h.respondError(c, http.StatusServiceUnavailable, "KLINES_UNAVAILABLE", "unable to fetch klines data")
		return
	}

	c.JSON(http.StatusOK, klines)
}

func (h *MarketHandler) GetDepth(c *gin.Context) {
	symbol := c.Query("symbol")
	if symbol == "" {
		h.respondError(c, http.StatusBadRequest, "MISSING_SYMBOL", "symbol parameter is required")
		return
	}

	limitStr := c.DefaultQuery("limit", "20")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 || limit > 100 {
		h.respondError(c, http.StatusBadRequest, "INVALID_LIMIT", "limit must be between 1 and 100")
		return
	}

	depth, err := h.marketService.GetDepth(symbol, limit)
	if err != nil {
		log.Error().Err(err).Str("symbol", symbol).Msg("Failed to get depth")
		h.respondError(c, http.StatusServiceUnavailable, "DEPTH_UNAVAILABLE", "unable to fetch depth data")
		return
	}

	c.JSON(http.StatusOK, depth)
}

func (h *MarketHandler) respondError(c *gin.Context, statusCode int, errorCode, message string) {
	requestID, _ := c.Get("request_id")
	
	errorResponse := ErrorResponse{
		Error:     message,
		Code:      errorCode,
		RequestID: requestID.(string),
		Timestamp: c.GetInt64("timestamp"),
	}

	c.JSON(statusCode, errorResponse)
}