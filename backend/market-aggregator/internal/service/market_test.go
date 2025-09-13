package service

import (
	"errors"
	"testing"
	"time"

	"github.com/mifasol123/cex-exchange/backend/market-aggregator/pkg/client"
	"github.com/patrickmn/go-cache"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Mock clients for testing
type MockBinanceClient struct {
	mock.Mock
}

func (m *MockBinanceClient) Get24hrTicker(symbol string) (*client.BinanceTicker, error) {
	args := m.Called(symbol)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*client.BinanceTicker), args.Error(1)
}

func (m *MockBinanceClient) GetKlines(symbol, interval string, limit int) ([][]interface{}, error) {
	args := m.Called(symbol, interval, limit)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([][]interface{}), args.Error(1)
}

func (m *MockBinanceClient) GetDepth(symbol string, limit int) (*client.BinanceDepth, error) {
	args := m.Called(symbol, limit)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*client.BinanceDepth), args.Error(1)
}

type MockCoinGeckoClient struct {
	mock.Mock
}

func (m *MockCoinGeckoClient) GetPrice(symbol string) (*client.CoinGeckoPrice, error) {
	args := m.Called(symbol)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*client.CoinGeckoPrice), args.Error(1)
}

func TestMarketService_GetTicker_Success(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	expectedBinanceTicker := &client.BinanceTicker{
		Symbol:             "BTCUSDT",
		LastPrice:          "26543.21",
		PriceChangePercent: "2.45",
		Volume:             "45123.67",
		HighPrice:          "27100.00",
		LowPrice:           "26200.00",
		CloseTime:          time.Now().Unix() * 1000,
	}

	mockBinance.On("Get24hrTicker", "BTCUSDT").Return(expectedBinanceTicker, nil)

	// Act
	result, err := service.GetTicker("BTCUSDT")

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "BTCUSDT", result.Symbol)
	assert.Equal(t, "26543.21", result.Price)
	assert.Equal(t, "2.45", result.Change24h)
	assert.Equal(t, "binance", result.Source)

	mockBinance.AssertExpectations(t)
}

func TestMarketService_GetTicker_BinanceFailure_FallbackToCoinGecko(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	expectedCoinGeckoPrice := &client.CoinGeckoPrice{
		USD: 26543.21,
	}

	mockBinance.On("Get24hrTicker", "BTCUSDT").Return(nil, errors.New("API error"))
	mockCoinGecko.On("GetPrice", "BTCUSDT").Return(expectedCoinGeckoPrice, nil)

	// Act
	result, err := service.GetTicker("BTCUSDT")

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "BTCUSDT", result.Symbol)
	assert.Equal(t, "26543.21", result.Price)
	assert.Equal(t, "N/A", result.Change24h)
	assert.Equal(t, "coingecko_fallback", result.Source)

	mockBinance.AssertExpectations(t)
	mockCoinGecko.AssertExpectations(t)
}

func TestMarketService_GetTicker_BothAPIsFail(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	mockBinance.On("Get24hrTicker", "BTCUSDT").Return(nil, errors.New("Binance API error"))
	mockCoinGecko.On("GetPrice", "BTCUSDT").Return(nil, errors.New("CoinGecko API error"))

	// Act
	result, err := service.GetTicker("BTCUSDT")

	// Assert
	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "failed to fetch ticker data")

	mockBinance.AssertExpectations(t)
	mockCoinGecko.AssertExpectations(t)
}

func TestMarketService_GetTicker_CacheHit(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	// Set up cache
	cachedTicker := &TickerResponse{
		Symbol:    "BTCUSDT",
		Price:     "26543.21",
		Change24h: "2.45",
		Source:    "binance",
		Timestamp: time.Now(),
	}
	cacheInstance.Set("ticker:BTCUSDT", cachedTicker, cache.DefaultExpiration)

	// Act
	result, err := service.GetTicker("BTCUSDT")

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, cachedTicker, result)

	// Verify no API calls were made
	mockBinance.AssertNotCalled(t, "Get24hrTicker")
	mockCoinGecko.AssertNotCalled(t, "GetPrice")
}

func TestMarketService_GetKlines_Success(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	expectedKlines := [][]interface{}{
		{int64(1620000000000), "50000.00", "51000.00", "49000.00", "50500.00", "100.5"},
		{int64(1620003600000), "50500.00", "51500.00", "50000.00", "51000.00", "150.2"},
	}

	mockBinance.On("GetKlines", "BTCUSDT", "1h", 100).Return(expectedKlines, nil)

	// Act
	result, err := service.GetKlines("BTCUSDT", "1h", 100)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "BTCUSDT", result.Symbol)
	assert.Equal(t, "1h", result.Interval)
	assert.Equal(t, "binance", result.Source)
	assert.Len(t, result.Klines, 2)

	mockBinance.AssertExpectations(t)
}

func TestMarketService_GetKlines_Failure(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	mockBinance.On("GetKlines", "BTCUSDT", "1h", 100).Return(nil, errors.New("API error"))

	// Act
	result, err := service.GetKlines("BTCUSDT", "1h", 100)

	// Assert
	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "failed to fetch klines")

	mockBinance.AssertExpectations(t)
}

func TestMarketService_GetDepth_Success(t *testing.T) {
	// Arrange
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	expectedDepth := &client.BinanceDepth{
		LastUpdateId: 123456789,
		Bids: [][]string{
			{"50000.00", "1.5"},
			{"49999.00", "2.0"},
		},
		Asks: [][]string{
			{"50001.00", "1.2"},
			{"50002.00", "1.8"},
		},
	}

	mockBinance.On("GetDepth", "BTCUSDT", 20).Return(expectedDepth, nil)

	// Act
	result, err := service.GetDepth("BTCUSDT", 20)

	// Assert
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "BTCUSDT", result.Symbol)
	assert.Equal(t, "binance", result.Source)
	assert.Len(t, result.Bids, 2)
	assert.Len(t, result.Asks, 2)

	mockBinance.AssertExpectations(t)
}

// Benchmark tests
func BenchmarkMarketService_GetTicker_CacheHit(b *testing.B) {
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(5*time.Minute, 10*time.Minute)

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	// Set up cache
	cachedTicker := &TickerResponse{
		Symbol:    "BTCUSDT",
		Price:     "26543.21",
		Change24h: "2.45",
		Source:    "binance",
		Timestamp: time.Now(),
	}
	cacheInstance.Set("ticker:BTCUSDT", cachedTicker, cache.DefaultExpiration)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = service.GetTicker("BTCUSDT")
	}
}

func BenchmarkMarketService_GetTicker_APICalls(b *testing.B) {
	mockBinance := new(MockBinanceClient)
	mockCoinGecko := new(MockCoinGeckoClient)
	cacheInstance := cache.New(1*time.Nanosecond, 1*time.Nanosecond) // 禁用缓存

	service := &MarketService{
		binanceClient:   mockBinance,
		coinGeckoClient: mockCoinGecko,
		cache:           cacheInstance,
	}

	expectedTicker := &client.BinanceTicker{
		Symbol:             "BTCUSDT",
		LastPrice:          "26543.21",
		PriceChangePercent: "2.45",
		Volume:             "45123.67",
		HighPrice:          "27100.00",
		LowPrice:           "26200.00",
		CloseTime:          time.Now().Unix() * 1000,
	}

	mockBinance.On("Get24hrTicker", mock.Anything).Return(expectedTicker, nil)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = service.GetTicker("BTCUSDT")
	}
}
