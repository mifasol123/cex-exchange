package client

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type CoinGeckoClient struct {
	baseURL    string
	httpClient *http.Client
}

type CoinGeckoPrice struct {
	USD float64 `json:"usd"`
}

func NewCoinGeckoClient() *CoinGeckoClient {
	return &CoinGeckoClient{
		baseURL: "https://api.coingecko.com/api/v3",
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
	}
}

func (c *CoinGeckoClient) GetPrice(symbol string) (*CoinGeckoPrice, error) {
	// Convert trading pair to CoinGecko format
	coinId := c.symbolToCoinGeckoId(symbol)
	if coinId == "" {
		return nil, fmt.Errorf("unsupported symbol: %s", symbol)
	}

	url := fmt.Sprintf("%s/simple/price?ids=%s&vs_currencies=usd", c.baseURL, coinId)
	
	resp, err := c.httpClient.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch price: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("coingecko API error: %d - %s", resp.StatusCode, string(body))
	}

	// CoinGecko returns nested structure: {"bitcoin": {"usd": 26543.21}}
	var priceData map[string]CoinGeckoPrice
	if err := json.NewDecoder(resp.Body).Decode(&priceData); err != nil {
		return nil, fmt.Errorf("failed to decode price response: %v", err)
	}

	price, exists := priceData[coinId]
	if !exists {
		return nil, fmt.Errorf("price not found for %s", coinId)
	}

	return &price, nil
}

// Convert trading symbol to CoinGecko coin ID
func (c *CoinGeckoClient) symbolToCoinGeckoId(symbol string) string {
	// Remove USDT suffix and convert to lowercase
	base := strings.TrimSuffix(symbol, "USDT")
	base = strings.TrimSuffix(base, "BUSD")
	base = strings.ToLower(base)

	// Map common symbols to CoinGecko IDs
	symbolMap := map[string]string{
		"btc":  "bitcoin",
		"eth":  "ethereum",
		"bnb":  "binancecoin",
		"ada":  "cardano",
		"dot":  "polkadot",
		"link": "chainlink",
		"ltc":  "litecoin",
		"xrp":  "ripple",
		"sol":  "solana",
		"matic": "matic-network",
		"avax": "avalanche-2",
		"atom": "cosmos",
		"near": "near",
		"ftm":  "fantom",
		"algo": "algorand",
		"vet":  "vechain",
		"icp":  "internet-computer",
		"fil":  "filecoin",
		"trx":  "tron",
		"xlm":  "stellar",
		"aave": "aave",
		"uni":  "uniswap",
	}

	if coinId, exists := symbolMap[base]; exists {
		return coinId
	}

	// For unknown symbols, try the base name directly
	return base
}