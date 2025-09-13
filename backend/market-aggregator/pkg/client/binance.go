package client

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type BinanceClient struct {
	baseURL    string
	httpClient *http.Client
}

type BinanceTicker struct {
	Symbol             string `json:"symbol"`
	PriceChange        string `json:"priceChange"`
	PriceChangePercent string `json:"priceChangePercent"`
	WeightedAvgPrice   string `json:"weightedAvgPrice"`
	PrevClosePrice     string `json:"prevClosePrice"`
	LastPrice          string `json:"lastPrice"`
	LastQty            string `json:"lastQty"`
	BidPrice           string `json:"bidPrice"`
	BidQty             string `json:"bidQty"`
	AskPrice           string `json:"askPrice"`
	AskQty             string `json:"askQty"`
	OpenPrice          string `json:"openPrice"`
	HighPrice          string `json:"highPrice"`
	LowPrice           string `json:"lowPrice"`
	Volume             string `json:"volume"`
	QuoteVolume        string `json:"quoteVolume"`
	OpenTime           int64  `json:"openTime"`
	CloseTime          int64  `json:"closeTime"`
	Count              int    `json:"count"`
}

type BinanceDepth struct {
	LastUpdateId int64      `json:"lastUpdateId"`
	Bids         [][]string `json:"bids"`
	Asks         [][]string `json:"asks"`
}

func NewBinanceClient() *BinanceClient {
	return &BinanceClient{
		baseURL: "https://api.binance.com",
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (c *BinanceClient) Get24hrTicker(symbol string) (*BinanceTicker, error) {
	url := fmt.Sprintf("%s/api/v3/ticker/24hr?symbol=%s", c.baseURL, symbol)
	
	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch ticker: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("binance API error: %d - %s", resp.StatusCode, string(body))
	}

	var ticker BinanceTicker
	if err := json.NewDecoder(resp.Body).Decode(&ticker); err != nil {
		return nil, fmt.Errorf("failed to decode ticker response: %v", err)
	}

	return &ticker, nil
}

func (c *BinanceClient) GetKlines(symbol, interval string, limit int) ([][]interface{}, error) {
	url := fmt.Sprintf("%s/api/v3/klines?symbol=%s&interval=%s&limit=%d", 
		c.baseURL, symbol, interval, limit)
	
	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch klines: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("binance API error: %d - %s", resp.StatusCode, string(body))
	}

	var klines [][]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&klines); err != nil {
		return nil, fmt.Errorf("failed to decode klines response: %v", err)
	}

	return klines, nil
}

func (c *BinanceClient) GetDepth(symbol string, limit int) (*BinanceDepth, error) {
	url := fmt.Sprintf("%s/api/v3/depth?symbol=%s&limit=%d", c.baseURL, symbol, limit)
	
	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch depth: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("binance API error: %d - %s", resp.StatusCode, string(body))
	}

	var depth BinanceDepth
	if err := json.NewDecoder(resp.Body).Decode(&depth); err != nil {
		return nil, fmt.Errorf("failed to decode depth response: %v", err)
	}

	return &depth, nil
}