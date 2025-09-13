# CEX Exchange 性能优化指南

## 概述

本文档描述了 CEX Exchange 系统的性能优化策略和最佳实践。

## 前端性能优化

### 1. 资源优化

#### JavaScript 优化
```javascript
// 使用 Web Workers 处理重计算
const worker = new Worker('market-worker.js');
worker.postMessage({ type: 'CALCULATE_INDICATORS', data: marketData });

// 使用 RequestAnimationFrame 优化动画
function updateChart() {
  requestAnimationFrame(() => {
    // 更新图表
    updateChartData();
  });
}

// 防抖处理用户输入
const debouncedSearch = debounce((query) => {
  searchSymbols(query);
}, 300);
```

#### CSS 优化
```css
/* 使用 CSS containment 优化重排 */
.trading-chart {
  contain: layout style paint;
}

/* 使用 transform 而不是改变 left/top */
.animated-element {
  transform: translateX(100px);
  will-change: transform;
}

/* 优化字体加载 */
@font-face {
  font-family: 'TradingFont';
  font-display: swap;
  src: url('font.woff2') format('woff2');
}
```

#### 图片和资源优化
```html
<!-- 使用现代图片格式 -->
<picture>
  <source srcset="logo.avif" type="image/avif">
  <source srcset="logo.webp" type="image/webp">
  <img src="logo.png" alt="CEX Exchange" loading="lazy">
</picture>

<!-- 预加载关键资源 -->
<link rel="preload" href="critical.css" as="style">
<link rel="preload" href="market-data.js" as="script">

<!-- 预连接外部域名 -->
<link rel="preconnect" href="https://api.binance.com">
<link rel="dns-prefetch" href="https://api.coingecko.com">
```

### 2. 网络优化

#### Service Worker 缓存策略
```javascript
// 缓存优先策略用于静态资源
const cacheFirst = async (request) => {
  const cached = await caches.match(request);
  if (cached) return cached;
  
  const response = await fetch(request);
  const cache = await caches.open(CACHE_NAME);
  cache.put(request, response.clone());
  return response;
};

// 网络优先策略用于 API 数据
const networkFirst = async (request) => {
  try {
    const response = await fetch(request);
    const cache = await caches.open(CACHE_NAME);
    cache.put(request, response.clone());
    return response;
  } catch (error) {
    return caches.match(request);
  }
};
```

#### HTTP/2 推送
```nginx
# Nginx HTTP/2 配置
server {
    listen 443 ssl http2;
    
    # 推送关键资源
    location / {
        http2_push /critical.css;
        http2_push /app.js;
    }
}
```

### 3. WebSocket 优化

```javascript
class OptimizedWebSocket {
  constructor(url) {
    this.url = url;
    this.reconnectDelay = 1000;
    this.maxReconnectDelay = 30000;
    this.reconnectAttempts = 0;
    this.messageQueue = [];
    
    this.connect();
  }
  
  connect() {
    this.ws = new WebSocket(this.url);
    
    this.ws.onopen = () => {
      this.reconnectAttempts = 0;
      this.reconnectDelay = 1000;
      this.flushMessageQueue();
    };
    
    this.ws.onclose = () => {
      this.scheduleReconnect();
    };
    
    this.ws.onmessage = (event) => {
      // 使用 RAF 批处理消息
      this.batchProcessMessages(JSON.parse(event.data));
    };
  }
  
  batchProcessMessages(message) {
    this.messageQueue.push(message);
    
    if (!this.processingScheduled) {
      this.processingScheduled = true;
      requestAnimationFrame(() => {
        this.processMessageBatch();
        this.processingScheduled = false;
      });
    }
  }
}</script>
```

## 后端性能优化

### 1. Go 服务优化

#### 连接池配置
```go
// HTTP 客户端连接池优化
func NewOptimizedHTTPClient() *http.Client {
    transport := &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     90 * time.Second,
        DisableCompression:  false,
        ForceAttemptHTTP2:   true,
    }
    
    return &http.Client{
        Transport: transport,
        Timeout:   30 * time.Second,
    }
}

// 数据库连接池
func setupDatabase() *sql.DB {
    db, err := sql.Open("postgres", dsn)
    if err != nil {
        log.Fatal(err)
    }
    
    db.SetMaxOpenConns(25)
    db.SetMaxIdleConns(25)
    db.SetConnMaxLifetime(5 * time.Minute)
    
    return db
}
```

#### 缓存策略
```go
// 多级缓存实现
type MultiLevelCache struct {
    l1 *cache.Cache      // 内存缓存
    l2 *redis.Client     // Redis 缓存
}

func (c *MultiLevelCache) Get(key string) (interface{}, bool) {
    // L1 缓存查找
    if value, found := c.l1.Get(key); found {
        return value, true
    }
    
    // L2 缓存查找
    value, err := c.l2.Get(context.Background(), key).Result()
    if err == nil {
        // 回填 L1 缓存
        c.l1.Set(key, value, cache.DefaultExpiration)
        return value, true
    }
    
    return nil, false
}

// 缓存预热
func (s *MarketService) WarmupCache() {
    symbols := []string{"BTCUSDT", "ETHUSDT", "BNBUSDT"}
    
    for _, symbol := range symbols {
        go func(sym string) {
            s.GetTicker(sym)
        }(symbol)
    }
}
```

#### 并发优化
```go
// 使用 worker pool 处理并发请求
type WorkerPool struct {
    workers    int
    jobQueue   chan Job
    resultChan chan Result
}

func (p *WorkerPool) Start() {
    for i := 0; i < p.workers; i++ {
        go p.worker()
    }
}

func (p *WorkerPool) worker() {
    for job := range p.jobQueue {
        result := job.Process()
        p.resultChan <- result
    }
}

// 批处理请求
func (s *MarketService) BatchGetTickers(symbols []string) map[string]*TickerResponse {
    results := make(map[string]*TickerResponse)
    var wg sync.WaitGroup
    var mu sync.Mutex
    
    // 限制并发数
    semaphore := make(chan struct{}, 10)
    
    for _, symbol := range symbols {
        wg.Add(1)
        go func(sym string) {
            defer wg.Done()
            semaphore <- struct{}{}
            defer func() { <-semaphore }()
            
            ticker, err := s.GetTicker(sym)
            if err == nil {
                mu.Lock()
                results[sym] = ticker
                mu.Unlock()
            }
        }(symbol)
    }
    
    wg.Wait()
    return results
}
```

### 2. 数据库优化

#### 索引策略
```sql
-- 复合索引优化查询
CREATE INDEX CONCURRENTLY idx_transactions_user_time 
ON transactions(user_id, created_at DESC);

-- 部分索引减少存储空间
CREATE INDEX CONCURRENTLY idx_transactions_pending 
ON transactions(status) 
WHERE status = 'pending';

-- 表达式索引
CREATE INDEX CONCURRENTLY idx_users_email_lower 
ON users(LOWER(email));

-- 查询优化
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM transactions 
WHERE user_id = $1 AND created_at > $2
ORDER BY created_at DESC 
LIMIT 100;
```

#### 连接池优化
```yaml
# PostgreSQL 配置优化
postgresql.conf: |
  # 连接设置
  max_connections = 200
  shared_buffers = 256MB
  effective_cache_size = 1GB
  
  # 性能优化
  random_page_cost = 1.1
  checkpoint_completion_target = 0.9
  wal_buffers = 16MB
  
  # 日志优化
  log_min_duration_statement = 1000
  log_checkpoints = on
  log_lock_waits = on
```

### 3. Redis 优化

```yaml
# Redis 配置
redis.conf: |
  # 内存优化
  maxmemory 2gb
  maxmemory-policy allkeys-lru
  
  # 持久化优化
  save 900 1
  save 300 10
  save 60 10000
  
  # 网络优化
  tcp-keepalive 300
  timeout 0
```

## 监控和性能测试

### 1. 性能监控

#### Prometheus 指标
```go
// 自定义指标
var (
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration",
        },
        []string{"method", "endpoint", "status"},
    )
    
    cacheHitRate = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "cache_hits_total",
            Help: "Cache hit rate",
        },
        []string{"cache_type"},
    )
)

// 中间件记录指标
func metricsMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()
        
        c.Next()
        
        duration := time.Since(start).Seconds()
        requestDuration.WithLabelValues(
            c.Request.Method,
            c.FullPath(),
            strconv.Itoa(c.Writer.Status()),
        ).Observe(duration)
    }
}
```

### 2. 负载测试

#### k6 测试脚本
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 }, // 逐步增加到 100 用户
    { duration: '5m', target: 100 }, // 保持 100 用户 5 分钟
    { duration: '2m', target: 200 }, // 增加到 200 用户
    { duration: '5m', target: 200 }, // 保持 200 用户 5 分钟
    { duration: '2m', target: 0 },   // 逐步减少到 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% 请求在 500ms 内完成
    http_req_failed: ['rate<0.01'],   // 错误率小于 1%
  },
};

export default function() {
  // 测试市场数据接口
  let response = http.get('http://localhost:8080/public/market/ticker?symbol=BTCUSDT');
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  sleep(1);
}
```

### 3. 性能基准

#### 目标指标
- **API 响应时间**: P95 < 100ms, P99 < 200ms
- **WebSocket 延迟**: < 10ms
- **吞吐量**: > 1000 RPS
- **内存使用**: < 512MB per service
- **CPU 使用**: < 70% under normal load
- **缓存命中率**: > 90%

#### 监控告警
```yaml
# Grafana 告警配置
alerts:
  - name: "High Response Time"
    condition: "avg(http_request_duration_seconds) > 0.5"
    frequency: "10s"
    
  - name: "High Error Rate"
    condition: "rate(http_requests_total{status=~'5.*'}) > 0.01"
    frequency: "30s"
    
  - name: "Low Cache Hit Rate"
    condition: "cache_hit_rate < 0.9"
    frequency: "1m"
```

## 最佳实践总结

1. **缓存策略**: 多级缓存 + 适当的 TTL
2. **连接池**: 合理配置数据库和 HTTP 连接池
3. **异步处理**: 使用 goroutines 和 channels
4. **批处理**: 合并相似请求减少网络开销
5. **压缩**: 启用 gzip 压缩减少传输量
6. **监控**: 全面的性能监控和告警
7. **测试**: 定期进行负载和压力测试

---

定期回顾和更新性能优化策略，确保系统始终保持最佳性能。