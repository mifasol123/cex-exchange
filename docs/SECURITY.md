# CEX Exchange 安全架构与配置

## 安全原则

### 1. 深度防御 (Defense in Depth)
- 多层安全控制
- 失效安全设计
- 最小权限原则

### 2. 零信任架构
- 内外网络边界一视同仁
- 身份验证贯穿始终
- 持续验证和监控

### 3. 合规优先
- 符合国际金融监管要求
- 数据保护法规遵循
- 审计跟踪完整性

## 网络安全

### API 网关安全
```yaml
# Kong Gateway 安全配置
plugins:
  - name: rate-limiting
    config:
      minute: 100
      hour: 1000
      fault_tolerant: true
      
  - name: ip-restriction
    config:
      allow: ["192.168.0.0/16", "10.0.0.0/8"]
      deny: ["1.2.3.4", "5.6.7.8"]
      
  - name: bot-detection
    config:
      whitelist: ["GoogleBot", "BingBot"]
      blacklist: ["BadBot", "ScrapBot"]
```

### DDoS 防护
- **第3层**: IP黑名单、GeoIP过滤
- **第4层**: SYN flood防护、连接限制
- **第7层**: 请求频率限制、行为分析

### WAF 规则
```nginx
# ModSecurity 核心规则
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off

# OWASP CRS 规则集
Include /etc/modsecurity/crs/crs-setup.conf
Include /etc/modsecurity/crs/rules/*.conf

# 自定义规则
SecRule ARGS "@detectSQLi" \
    "id:1001,phase:2,msg:'SQL注入攻击',deny,status:403"
    
SecRule ARGS "@detectXSS" \
    "id:1002,phase:2,msg:'XSS攻击',deny,status:403"
```

## 应用安全

### 输入验证
```go
// 参数验证示例
type TickerRequest struct {
    Symbol string `json:"symbol" binding:"required,alphanum,min=6,max=12"`
    Limit  int    `json:"limit" binding:"min=1,max=1000"`
}

func validateSymbol(symbol string) error {
    if !regexp.MustCompile(`^[A-Z]{3,6}(USDT|BUSD|BTC|ETH)$`).MatchString(symbol) {
        return errors.New("invalid symbol format")
    }
    return nil
}
```

### 错误处理
```go
// 安全错误响应
func (h *Handler) respondError(c *gin.Context, statusCode int, errorCode, message string) {
    // 不暴露敏感信息
    sanitizedMessage := sanitizeErrorMessage(message)
    
    errorResponse := ErrorResponse{
        Error:     sanitizedMessage,
        Code:      errorCode,
        RequestID: c.GetString("request_id"),
        Timestamp: time.Now().Unix(),
    }
    
    // 记录详细错误到日志，但不返回给客户端
    log.Error().
        Str("request_id", errorResponse.RequestID).
        Str("original_error", message).
        Str("client_ip", c.ClientIP()).
        Msg("Request failed")
    
    c.JSON(statusCode, errorResponse)
}
```

### HTTPS 配置
```nginx
# Nginx SSL 配置
server {
    listen 443 ssl http2;
    
    # SSL 证书
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/private.key;
    
    # 强安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
    
    # 其他安全头
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Content-Security-Policy "default-src 'self'";
}
```

## 数据安全

### 数据库安全
```sql
-- 数据库用户权限控制
CREATE USER 'market_reader'@'%' IDENTIFIED BY 'strong_password';
GRANT SELECT ON market_data.* TO 'market_reader'@'%';

CREATE USER 'audit_writer'@'%' IDENTIFIED BY 'strong_password';
GRANT INSERT ON audit_logs.* TO 'audit_writer'@'%';

-- 敏感数据加密
ALTER TABLE users ADD COLUMN email_encrypted VARBINARY(255);
ALTER TABLE users ADD COLUMN phone_encrypted VARBINARY(255);
```

### 密钥管理
```yaml
# HashiCorp Vault 配置
storage "postgresql" {
  connection_url = "postgres://vault:password@localhost/vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_cert_file = "/path/to/cert.pem"
  tls_key_file  = "/path/to/key.pem"
}

seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "alias/vault-seal-key"
}
```

## 监控与日志

### 安全事件监控
```go
// 安全事件记录
type SecurityEvent struct {
    ID          string    `json:"id"`
    Type        string    `json:"type"`        // LOGIN_FAILED, SUSPICIOUS_ACTIVITY, etc.
    Severity    string    `json:"severity"`    // LOW, MEDIUM, HIGH, CRITICAL
    UserID      string    `json:"user_id"`
    IPAddress   string    `json:"ip_address"`
    UserAgent   string    `json:"user_agent"`
    Details     map[string]interface{} `json:"details"`
    Timestamp   time.Time `json:"timestamp"`
}

func logSecurityEvent(event SecurityEvent) {
    // 发送到SIEM系统
    siem.SendEvent(event)
    
    // 高危事件立即告警
    if event.Severity == "CRITICAL" {
        alert.SendImmediate(event)
    }
}
```

### 日志配置
```yaml
# 结构化日志配置
logging:
  level: info
  format: json
  output: 
    - stdout
    - /var/log/cex/app.log
  
  # 敏感字段过滤
  redact_fields:
    - password
    - secret
    - token
    - private_key
    
  # 日志保留策略
  retention:
    days: 90
    max_size: 10GB
```

## 合规要求

### GDPR 合规
- 数据主体权利实现
- 数据处理记录
- 隐私设计原则

### AML/KYC 流程
- 身份验证层级
- 可疑交易监控
- 合规报告生成

### SOX 合规
- 内控制度建立
- 审计跟踪完整
- 访问控制记录

## 应急响应

### 安全事件响应流程
1. **检测**: 自动监控 + 人工分析
2. **分析**: 影响评估 + 根因分析
3. **遏制**: 立即止损 + 隔离威胁
4. **根除**: 清除威胁 + 修复漏洞
5. **恢复**: 服务恢复 + 监控加强
6. **总结**: 经验教训 + 流程改进

### 应急联系人
```yaml
security_contacts:
  ciso: security@cex.com
  infrastructure: ops@cex.com
  legal: legal@cex.com
  external_security: vendor@security-firm.com
```

## 安全测试

### 渗透测试计划
- **频率**: 季度测试
- **范围**: 全系统覆盖
- **方法**: 黑盒 + 白盒
- **报告**: 详细漏洞清单

### 代码安全扫描
```yaml
# SonarQube 配置
sonar:
  rules:
    - security-hotspots
    - vulnerability-detection
    - code-smells
  quality_gate:
    security_rating: A
    reliability_rating: A
```

---

**注意**: 本文档包含安全配置示例，实际部署时需要根据具体环境调整，并定期更新安全配置。