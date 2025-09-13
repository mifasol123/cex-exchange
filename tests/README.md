# CEX Exchange 测试文档

本目录包含 CEX Exchange 系统的所有测试代码和文档。

## 测试策略

### 1. 单元测试 (Unit Tests)
- **目录**: `unit/`
- **覆盖率要求**: > 90%
- **工具**: Go 内置测试框架 + Testify
- **执行**: `make test`

### 2. 集成测试 (Integration Tests)
- **目录**: `integration/`
- **范围**: 服务间接口测试
- **工具**: Docker Compose + 测试容器
- **执行**: `make test:integration`

### 3. 性能测试 (Performance Tests)
- **目录**: `performance/`
- **工具**: k6 + Artillery
- **指标**: 延迟、吞吐量、资源占用
- **执行**: `make test:performance`

## 测试数据管理

### 测试环境配置
```yaml
# test-config.yaml
database:
  host: localhost
  port: 5433
  name: cex_test
  
external_apis:
  binance: 
    base_url: "https://testnet.binance.vision"
  coingecko:
    base_url: "https://api.coingecko.com/api/v3"
```

### 测试数据
- **Mock 数据**: `testdata/`
- **测试夹具**: `fixtures/`
- **种子数据**: `seeds/`

## 测试执行

### 本地测试
```bash
# 运行所有测试
make test:all

# 运行单元测试
make test:unit

# 运行集成测试（需要 Docker）
make test:integration

# 运行性能测试
make test:performance

# 测试覆盖率报告
make test:coverage
```

### CI/CD 测试
- **触发条件**: 每次 push 和 PR
- **环境**: 隔离的测试容器
- **报告**: 自动生成测试报告和覆盖率

## 测试最佳实践

### 1. 测试命名
```go
func TestMarketService_GetTicker_Success(t *testing.T) {
    // Given
    // When  
    // Then
}

func TestMarketService_GetTicker_BinanceAPIFailure_ShouldFallbackToCoinGecko(t *testing.T) {
    // 详细描述测试场景
}
```

### 2. 测试结构
```go
func TestExample(t *testing.T) {
    // Arrange (Given)
    service := setupTestService()
    
    // Act (When)
    result, err := service.DoSomething()
    
    // Assert (Then)
    assert.NoError(t, err)
    assert.Equal(t, expectedResult, result)
}
```

### 3. Mock 使用
```go
// 使用接口进行依赖注入，便于测试
type ExternalAPIClient interface {
    GetData() (*Data, error)
}

// 测试中使用 mock
mockClient := &MockAPIClient{}
mockClient.On("GetData").Return(expectedData, nil)
```

## 测试环境

### 开发环境
- **数据库**: PostgreSQL 测试实例
- **外部 API**: Mock 服务器
- **配置**: 本地配置文件

### CI 环境
- **数据库**: Docker PostgreSQL
- **外部 API**: WireMock 容器
- **配置**: 环境变量

## 质量门禁

### 代码提交前
- [ ] 所有单元测试通过
- [ ] 代码覆盖率 > 90%
- [ ] 静态代码分析通过
- [ ] 安全扫描无高危漏洞

### 版本发布前
- [ ] 所有测试套件通过
- [ ] 性能测试满足指标
- [ ] 安全测试通过
- [ ] 合规检查完成

---

**注意**: 测试代码同样需要维护和重构，保持测试的可读性和可维护性。