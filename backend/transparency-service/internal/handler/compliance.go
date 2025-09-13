package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/mifasol123/cex-exchange/backend/transparency-service/internal/service"
	"github.com/rs/zerolog/log"
)

type ComplianceHandler struct {
	transparencyService *service.TransparencyService
}

type ErrorResponse struct {
	Error     string `json:"error"`
	Code      string `json:"code"`
	Timestamp int64  `json:"timestamp"`
}

func NewComplianceHandler(transparencyService *service.TransparencyService) *ComplianceHandler {
	return &ComplianceHandler{
		transparencyService: transparencyService,
	}
}

func (h *ComplianceHandler) GetProofOfReserves(c *gin.Context) {
	log.Info().Msg("Proof of reserves requested")

	por := h.transparencyService.GetProofOfReserves()
	c.JSON(http.StatusOK, por)
}

func (h *ComplianceHandler) GetSystemStatus(c *gin.Context) {
	log.Info().Msg("System status requested")

	status := h.transparencyService.GetSystemStatus()
	c.JSON(http.StatusOK, status)
}

func (h *ComplianceHandler) GetAuditLogs(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("pageSize", "10")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page <= 0 {
		h.respondError(c, http.StatusBadRequest, "INVALID_PAGE", "page must be a positive integer")
		return
	}

	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize <= 0 || pageSize > 100 {
		h.respondError(c, http.StatusBadRequest, "INVALID_PAGE_SIZE", "pageSize must be between 1 and 100")
		return
	}

	log.Info().Int("page", page).Int("pageSize", pageSize).Msg("Audit logs requested")

	auditLogs := h.transparencyService.GetAuditLogs(page, pageSize)
	c.JSON(http.StatusOK, auditLogs)
}

func (h *ComplianceHandler) respondError(c *gin.Context, statusCode int, errorCode, message string) {
	errorResponse := ErrorResponse{
		Error:     message,
		Code:      errorCode,
		Timestamp: c.GetInt64("timestamp"),
	}

	c.JSON(statusCode, errorResponse)
}
