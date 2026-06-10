# Rate Limiting in E2E Tests

This guide explains how to handle rate limiting so it doesn't break your E2E tests.

---

## The Problem

Many APIs implement rate limiting to prevent abuse:

```
API: "Max 10 login attempts per minute"
E2E Test: "Create 50 test accounts per test run"
Result: ❌ Tests fail with rate limit errors
```

E2E tests create many requests quickly (50-100+ per test run), which easily hits production rate limits.

---

## The Solution: Test Environment Configuration

Create a separate test configuration with relaxed limits:

### Step 1: Create Test Config File

Create `appsettings.Test.json` (.NET) or similar for your backend:

**For .NET/.NET Core:**

```json
{
  "RateLimit": {
    "Login": {
      "Window": "00:10:00",
      "Permit": 1000
    },
    "Register": {
      "Window": "00:10:00",
      "Permit": 1000
    },
    "Api": {
      "Window": "00:01:00",
      "Permit": 10000
    }
  }
}
```

**For Node.js/Express:**

```typescript
// config/rate-limit.test.ts
export const rateLimitConfig = {
  login: {
    windowMs: 10 * 60 * 1000,  // 10 minutes
    max: 1000,                 // 1000 requests (effectively unlimited)
  },
  register: {
    windowMs: 10 * 60 * 1000,
    max: 1000,
  },
  api: {
    windowMs: 60 * 1000,
    max: 10000,
  },
}
```

**For Python/Django:**

```python
# settings/test.py
RATE_LIMIT = {
    'LOGIN': '1000/10m',      # 1000 per 10 minutes
    'REGISTER': '1000/10m',
    'API': '10000/1m',
}
```

### Step 2: Enable Test Environment

Set environment variable when running tests:

```bash
# Locally
export ASPNETCORE_ENVIRONMENT=Test
docker-compose up -d

# Or in docker-compose.test.yml
version: '3'
services:
  api:
    environment:
      ASPNETCORE_ENVIRONMENT: Test
      # ... other env vars
```

### Step 3: Use Test Config in Docker

Update `docker-compose.test.yml`:

```yaml
version: '3'
services:
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    environment:
      ASPNETCORE_ENVIRONMENT: Test  # Enable test limits
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test_db
    ports:
      - "5001:5000"
    depends_on:
      postgres:
        condition: service_healthy
```

### Step 4: Update Tests to Use Test Config

In your backend, load the appropriate config:

**For .NET:**

```csharp
// Program.cs
var environment = builder.Environment;

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false)
    .AddJsonFile($"appsettings.{environment.EnvironmentName}.json", optional: true)
    .AddEnvironmentVariables();

// Rate limiting automatically uses Test config when:
// ASPNETCORE_ENVIRONMENT=Test
```

**For Node.js:**

```typescript
// server.ts
const env = process.env.NODE_ENV || 'production';
const rateLimitConfig = env === 'test' 
  ? rateLimitConfigTest 
  : rateLimitConfigProduction;

app.use(rateLimit(rateLimitConfig));
```

---

## Configuration Comparison

| Aspect | Production | Test |
|--------|-----------|------|
| **Login limit** | 10/min | 1000/10min |
| **Register limit** | 5/hour | 1000/10min |
| **API limit** | 100/min | 10000/min |
| **Purpose** | Prevent abuse | Enable fast testing |
| **Window** | Short (1-5 min) | Longer (10+ min) |

**Key principle:** Test limits should be "unlimited" compared to production

---

## CI/CD Integration

In your CI/CD pipeline, use test config:

### GitHub Actions

```yaml
jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Start backend
        run: docker-compose -f docker-compose.test.yml up -d
        env:
          ASPNETCORE_ENVIRONMENT: Test
      
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          BACKEND_URL: http://localhost:5001
          CI: true
```

### GitLab CI

```yaml
e2e-tests:
  services:
    - docker:dind
  variables:
    ASPNETCORE_ENVIRONMENT: Test
  script:
    - docker-compose -f docker-compose.test.yml up -d
    - npm run test:e2e
```

---

## Debugging Rate Limit Issues

### Symptom: Tests fail with "Rate limit exceeded"

**Check current config:**

```bash
# For .NET
curl -H "X-API-Version: 1" http://localhost:5001/api/config
# Returns rate limit config

# For Node.js
node -e "console.log(require('./config/rate-limit').current)"
```

**Verify environment:**

```bash
# Should be 'Test'
echo $ASPNETCORE_ENVIRONMENT
echo $NODE_ENV
```

**Check docker container:**

```bash
docker-compose logs api | grep "Rate limit\|Environment"
```

### Symptom: Tests run slow after many iterations

**Cause:** Rate limit window hasn't expired yet

**Fix:** Increase test environment window to be longer:

```json
{
  "RateLimit": {
    "Login": {
      "Window": "00:30:00",  // Increase from 10 minutes to 30
      "Permit": 1000
    }
  }
}
```

---

## Best Practices

1. **Never use production limits in tests** — Tests will fail intermittently
2. **Make test limits "unlimited"** — 1000+ per window effectively unlimited
3. **Use separate config files** — Production and test configs stay clean
4. **Document your choices** — Why these specific limits?
5. **Test in CI environment** — Verify rate limiting works in CI before merging

---

## Examples by Framework

### .NET / ASP.NET Core

```csharp
// Startup.cs
public void ConfigureServices(IServiceCollection services)
{
    var rateLimitConfig = Configuration.GetSection("RateLimit");
    
    services.AddRateLimiting(options =>
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        
        options.AddSlidingWindowLimiter("login", (context) =>
        {
            var window = TimeSpan.Parse(rateLimitConfig["Login:Window"]);
            var permit = int.Parse(rateLimitConfig["Login:Permit"]);
            
            return new SlidingWindowRateLimiterOptions
            {
                Window = window,
                PermitLimit = permit,
                SegmentsPerWindow = 8,
            };
        });
    });
}
```

### Node.js / Express

```typescript
import rateLimit from 'express-rate-limit';

const config = process.env.NODE_ENV === 'test'
  ? {
      windowMs: 10 * 60 * 1000,
      max: 1000,
    }
  : {
      windowMs: 1 * 60 * 1000,
      max: 10,
    };

app.use('/api/login', rateLimit(config));
```

### Python / Django

```python
# settings.py
if DEBUG or os.environ.get('ENVIRONMENT') == 'test':
    # Test environment - high limits
    RATE_LIMIT = {
        'LOGIN': '1000/10m',
        'REGISTER': '1000/10m',
        'API': '10000/1m',
    }
else:
    # Production - strict limits
    RATE_LIMIT = {
        'LOGIN': '10/1m',
        'REGISTER': '5/1h',
        'API': '100/1m',
    }
```

---

## Validating Rate Limit Configuration

Before running tests, verify rate limits are set correctly:

```bash
# Test the endpoint
curl -X GET http://localhost:5001/api/health

# Make multiple rapid requests (should not get rate limited)
for i in {1..100}; do
  curl -X GET http://localhost:5001/api/health
done

# Should succeed (no 429 errors)
```

---

## Portal Aurora Example

If using Portal Aurora (.NET backend):

1. **Create appsettings.Test.json:**
   ```json
   {
     "RateLimit": {
       "Login": { "Window": "00:10:00", "Permit": 1000 },
       "Register": { "Window": "00:10:00", "Permit": 1000 },
       "Ads": { "Window": "00:01:00", "Permit": 10000 }
     }
   }
   ```

2. **Update docker-compose.test.yml:**
   ```yaml
   api:
     environment:
       ASPNETCORE_ENVIRONMENT: Test
   ```

3. **Run tests with test config:**
   ```bash
   ASPNETCORE_ENVIRONMENT=Test docker-compose up -d
   npm run test:e2e
   ```

---

## Summary

**Without Rate Limit Configuration:**
- E2E tests fail randomly (hitting rate limits)
- Developers get confused ("works locally, fails in CI")
- Tests become unreliable

**With Rate Limit Configuration:**
- Tests run reliably
- Production stays protected
- CI/CD pipeline works smoothly

**Key takeaway:** Rate limiting is a feature for production. E2E tests need disabled/relaxed limits to work reliably.
