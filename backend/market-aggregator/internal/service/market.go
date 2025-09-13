package service

import (
	"fmt"
	"strconv"
	"time"

	"github.com/mifasol123/cex-exchange/backend/market-aggregator/pkg/client"
	"github.com/patrickmn/go-cache"
	"github.com/rs/zerolog/log"
)

type MarketService struct {
	binanceClient   *client.BinanceClient
	coinGeckoClient *client.CoinGeckoClient
	cache           *cache.Cache
}

type TickerResponse struct {
	Symbol     string    `json:"symbol"`
	Price      string    `json:"price"`
	Change24h  string    `json:"change24h"`
	Volume24h  string    `json:"volume24h"`
	High24h    string    `json:"high24h"`
	Low24h     string    `json:"low24h"`
	Source     string    `json:"source"`
	Timestamp  time.Time `json:"timestamp"`
	LastUpdate time.Time `json:"last_update"`
}

type KlineResponse struct {
	Symbol   string     `json:"symbol"`
	Interval string     `json:"interval"`
	Klines   [][]string `json:"klines"`
	Source   string     `json:"source"`
}

type DepthResponse struct {
	Symbol    string     `json:"symbol"`
	Bids      [][]string `json:"bids"`
	Asks      [][]string `json:"asks"`
	Source    string     `json:"source"`
	Timestamp time.Time  `json:"timestamp"`
}

func NewMarketService(binanceClient *client.BinanceClient, coinGeckoClient *client.CoinGeckoClient, cache *cache.Cache) *MarketService {
	return &MarketService{
		binanceClient:   binanceClient,
		coinGeckoClient: coinGeckoClient,
		cache:           cache,
	}
}

func (s *MarketService) GetTicker(symbol string) (*TickerResponse, error) {
	cacheKey := fmt.Sprintf("ticker:%s", symbol)

	// Try cache first
	if cached, found := s.cache.Get(cacheKey); found {
		if ticker, ok := cached.(*TickerResponse); ok {
			log.Debug().Str("symbol", symbol).Msg("Ticker served from cache")
			return ticker, nil
		}
	}

	// Try Binance first
	binanceData, err := s.binanceClient.Get24hrTicker(symbol)
	if err == nil {
		ticker := &TickerResponse{
			Symbol:     binanceData.Symbol,
			Price:      binanceData.LastPrice,
			Change24h:  binanceData.PriceChangePercent,
			Volume24h:  binanceData.Volume,
			High24h:    binanceData.HighPrice,
			Low24h:     binanceData.LowPrice,
			Source:     "binance",
			Timestamp:  time.Now(),
			LastUpdate: time.Unix(binanceData.CloseTime/1000, 0),
		}

		// Cache the result
		s.cache.Set(cacheKey, ticker, cache.DefaultExpiration)
		log.Info().Str("symbol", symbol).Str("source", "binance").Msg("Ticker fetched successfully")
		return ticker, nil
	}

	log.Warn().Err(err).Str("symbol", symbol).Msg("Binance API failed, trying CoinGecko fallback")

	// Fallback to CoinGecko (price only)
	coinGeckoData, cgErr := s.coinGeckoClient.GetPrice(symbol)
	if cgErr != nil {
		log.Error().Err(cgErr).Str("symbol", symbol).Msg("Both Binance and CoinGecko failed")
		return nil, fmt.Errorf("failed to fetch ticker data: binance=%v, coingecko=%v", err, cgErr)
	}

	ticker := &TickerResponse{
		Symbol:     symbol,
		Price:      fmt.Sprintf("%.2f", coinGeckoData.USD),
		Change24h:  "N/A",
		Volume24h:  "N/A",
		High24h:    "N/A",
		Low24h:     "N/A",
		Source:     "coingecko_fallback",
		Timestamp:  time.Now(),
		LastUpdate: time.Now(),
	}

	// Cache the result with shorter TTL for fallback data
	s.cache.Set(cacheKey, ticker, 10*time.Second)
	log.Info().Str("symbol", symbol).Str("source", "coingecko").Msg("Ticker fetched from fallback")
	return ticker, nil
}

func (s *MarketService) GetKlines(symbol, interval string, limit int) (*KlineResponse, error) {
	cacheKey := fmt.Sprintf("klines:%s:%s:%d", symbol, interval, limit)

	// Try cache first
	if cached, found := s.cache.Get(cacheKey); found {
		if klines, ok := cached.(*KlineResponse); ok {
			log.Debug().Str("symbol", symbol).Str("interval", interval).Msg("Klines served from cache")
			return klines, nil
		}
	}

	// Only Binance supports klines
	binanceKlines, err := s.binanceClient.GetKlines(symbol, interval, limit)
	if err != nil {
		log.Error().Err(err).Str("symbol", symbol).Str("interval", interval).Msg("Failed to fetch klines")
		return nil, fmt.Errorf("failed to fetch klines: %v", err)
	}

	// Convert binance klines to string format
	var klines [][]string
	for _, k := range binanceKlines {
		kline := []string{
			strconv.FormatInt(k[0].(int64), 10), // Open time
			k[1].(string),                       // Open
			k[2].(string),                       // High
			k[3].(string),                       // Low
			k[4].(string),                       // Close
			k[5].(string),                       // Volume
		}
		klines = append(klines, kline)
	}

	response := &KlineResponse{
		Symbol:   symbol,
		Interval: interval,
		Klines:   klines,
		Source:   "binance",
	}

	// Cache with longer TTL for klines
	s.cache.Set(cacheKey, response, 1*time.Minute)
	log.Info().Str("symbol", symbol).Str("interval", interval).Int("count", len(klines)).Msg("Klines fetched successfully")
	return response, nil
}

func (s *MarketService) GetDepth(symbol string, limit int) (*DepthResponse, error) {
	cacheKey := fmt.Sprintf("depth:%s:%d", symbol, limit)

	// Try cache first (shorter cache for depth data)
	if cached, found := s.cache.Get(cacheKey); found {
		if depth, ok := cached.(*DepthResponse); ok {
			log.Debug().Str("symbol", symbol).Msg("Depth served from cache")
			return depth, nil
		}
	}

	// Only Binance supports depth
	binanceDepth, err := s.binanceClient.GetDepth(symbol, limit)
	if err != nil {
		log.Error().Err(err).Str("symbol", symbol).Msg("Failed to fetch depth")
		return nil, fmt.Errorf("failed to fetch depth: %v", err)
	}

	response := &DepthResponse{
		Symbol:    symbol,
		Bids:      binanceDepth.Bids,
		Asks:      binanceDepth.Asks,
		Source:    "binance",
		Timestamp: time.Now(),
	}

	// Cache with very short TTL for depth (5 seconds)
	s.cache.Set(cacheKey, response, 5*time.Second)
	log.Info().Str("symbol", symbol).Int("bids", len(response.Bids)).Int("asks", len(response.Asks)).Msg("Depth fetched successfully")
	return response, nil
}
