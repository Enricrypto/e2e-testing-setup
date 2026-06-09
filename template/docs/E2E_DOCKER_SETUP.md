# Docker Setup for E2E Testing: Best Practices

**When to use:** During local development and CI/CD  
**What it covers:** Configuring Docker for backend + database while E2E tests run locally  
**Why it matters:** Fast iteration (local tests) + production-like backend (Docker)

---

## The Recommended Setup

### Local Development

```
┌─────────────────────────────────────────────┐
│  Your Computer (Host Machine)               │
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │  Terminal 1: Frontend Dev Server       │ │
│  │  npm run dev → localhost:3000          │ │
│  └────────────────────────────────────────┘ │
│                                             │
│  ┌────────────────────────────────────────┐ │
│  │  Terminal 2: E2E Tests (Local)         │ │
│  │  npm run test:e2e:local                │ │
│  │  Points to localhost:3001 (backend)    │ │
│  └────────────────────────────────────────┘ │
│                                             │
│  ┌─────────────────────────────────────────────────────┐
│  │  Docker Container (Backend API)                     │
│  │  localhost:3001 ← Backend server                   │
│  │  Database: postgres://localhost:5432 (inside)      │
│  │                                                     │
│  │  ┌─────────────────────────────────────────────┐   │
│  │  │  Docker Container (PostgreSQL)              │   │
│  │  │  localhost:5432 ← Database                  │   │
│  │  └─────────────────────────────────────────────┘   │
│  └─────────────────────────────────────────────────────┘
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Why This Setup?

| Component | Where | Why |
|-----------|-------|-----|
| **Frontend Dev Server** | Local (npm run dev) | Hot reload, instant feedback, easy debugging |
| **E2E Tests** | Local (npm run test:e2e:local) | Fast iteration, see failures immediately, easiest debugging |
| **Backend API** | Docker container | Production-like environment, isolated, easy reset |
| **Database** | Docker container | Consistent schema, fast reset between test runs, no local Postgres setup |

**Benefits:**
- ✅ Tests run in ~30 seconds (not through Docker)
- ✅ You see test output immediately
- ✅ Easy to debug failing tests (set breakpoints, see logs)
- ✅ Backend is production-like (Docker, not mocked)
- ✅ Database can reset between test runs (docker-compose down -v)

---

## Prerequisites

### Install Docker & Docker Compose

**macOS:**
```bash
# Install Docker Desktop (includes Docker & Compose)
brew install --cask docker
# Then start Docker Desktop from Applications
```

**Linux:**
```bash
# Install Docker
sudo apt-get install docker.io docker-compose

# Allow docker without sudo
sudo usermod -aG docker $USER
newgrp docker
```

**Windows:**
```bash
# Install Docker Desktop (includes Docker & Compose)
# Download from https://www.docker.com/products/docker-desktop
```

**Verify installation:**
```bash
docker --version
docker-compose --version
```

---

## Setup: Docker Compose Configuration

### Step 1: Create `docker-compose.yml` in project root

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: e2e_postgres
    environment:
      POSTGRES_USER: ${DB_USER:-test_user}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-test_password}
      POSTGRES_DB: ${DB_NAME:-test_db}
    ports:
      - "5432:5432"
    volumes:
      # Database data persists between runs
      - postgres_data:/var/lib/postgresql/data
      
      # (Optional) Initialize database with seed data
      # - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER:-test_user}"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - e2e-network

  # Backend API Server
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: e2e_backend
    environment:
      # Database connection (inside docker network, use service name)
      DATABASE_URL: postgres://${DB_USER:-test_user}:${DB_PASSWORD:-test_password}@postgres:5432/${DB_NAME:-test_db}
      
      # Node environment
      NODE_ENV: ${NODE_ENV:-test}
      
      # API port
      API_PORT: 3001
      
      # (Add other env vars your backend needs)
      # LOG_LEVEL: debug
      # JWT_SECRET: test-secret
    ports:
      # Expose to host machine (for E2E tests)
      - "3001:3001"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - e2e-network
    # Restart on failure (useful in CI)
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local

networks:
  e2e-network:
    driver: bridge
```

### Step 2: Create `.env` file (optional, for secrets)

```bash
# Copy this to your .env file (or just use defaults)
DB_USER=test_user
DB_PASSWORD=test_password
DB_NAME=test_db
NODE_ENV=test
```

**Important:** Add `.env` to `.gitignore` — don't commit secrets

### Step 3: Create Backend Dockerfile

Create `backend/Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build if needed (TypeScript, etc.)
RUN npm run build || true

# Expose port
EXPOSE 3001

# Start server
CMD ["npm", "start"]
```

**Alternative if using different setup:**
```dockerfile
# For a monorepo or different structure, adjust paths accordingly
COPY backend/package*.json ./
# ... etc
```

---

## Setup: Playwright Configuration

### Step 4: Update `playwright.config.ts`

```typescript
import { defineConfig, devices } from '@playwright/test'

// Determine test environment
const env = process.env.TEST_ENV || 'local'
const isLocal = env === 'local'
const isCI = !!process.env.CI

// Backend URL based on environment
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3000'

// Timeout configuration per environment
const timeoutConfig = {
  local: {
    // Local tests: fast feedback
    actionTimeout: 5000,
    navigationTimeout: 15000,
    testTimeout: 30000,
    name: 'Local Development',
  },
  docker: {
    // Docker containers: slightly slower
    actionTimeout: 10000,
    navigationTimeout: 20000,
    testTimeout: 60000,
    name: 'Docker (Backend in Container)',
  },
  ci: {
    // CI/CD: conservative timeouts
    actionTimeout: 15000,
    navigationTimeout: 30000,
    testTimeout: 120000,
    name: 'CI/CD Pipeline',
  },
  staging: {
    // Staging/production-like: realistic timeouts
    actionTimeout: 15000,
    navigationTimeout: 30000,
    testTimeout: 60000,
    name: 'Staging Environment',
  },
  production: {
    // Production smoke tests: very conservative
    actionTimeout: 25000,
    navigationTimeout: 45000,
    testTimeout: 120000,
    name: 'Production Smoke Tests',
  },
}[env as keyof typeof timeoutConfig] || timeoutConfig.local

export default defineConfig({
  testDir: './e2e/tests',
  testMatch: '**/*.spec.ts',

  timeout: timeoutConfig.testTimeout,
  navigationTimeout: timeoutConfig.navigationTimeout,
  expect: { timeout: 10000 },

  fullyParallel: true,
  workers: isCI ? 1 : 4, // 1 worker in CI (safer), 4 locally

  forbidOnly: !!process.env.CI,
  retries: isCI ? 1 : 0,

  reporter: [
    ['html'],
    ['list'],
    ...(isCI ? [
      ['json', { outputFile: 'test-results/results.json' }],
      ['junit', { outputFile: 'test-results/results.xml' }],
    ] : []),
  ],

  use: {
    baseURL: FRONTEND_URL,
    actionTimeout: timeoutConfig.actionTimeout,
    navigationTimeout: timeoutConfig.navigationTimeout,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  webServer: {
    command: 'npm run dev',
    url: FRONTEND_URL,
    reuseExistingServer: !isCI,
    timeout: 120000,
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    // Skip mobile in local dev for speed
    ...(isLocal ? [] : [
      {
        name: 'mobile-chrome',
        use: { ...devices['Pixel 5'] },
      },
    ]),
  ],
})

// Export for test fixtures
export const BACKEND_API_URL = BACKEND_URL
```

### Step 5: Create Test Fixture with Backend API

Create or update `e2e/fixtures.ts`:

```typescript
import { test as base, expect } from '@playwright/test'
import { BACKEND_API_URL } from '../playwright.config'

// Extended test fixture with API utilities
export const test = base.extend({
  // Helper to make API calls to backend
  api: async ({}, use) => {
    const api = {
      async get(path: string) {
        const response = await fetch(`${BACKEND_API_URL}${path}`)
        return response.json()
      },
      async post(path: string, data: any) {
        const response = await fetch(`${BACKEND_API_URL}${path}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
        })
        return response.json()
      },
      async delete(path: string) {
        const response = await fetch(`${BACKEND_API_URL}${path}`, {
          method: 'DELETE',
        })
        return response.ok
      },
    }
    await use(api)
  },
})

export { expect }
```

---

## Workflow: Running Tests Locally with Docker

### Terminal 1: Start Docker Services

```bash
# Start backend + database
docker-compose up

# You should see:
# ✓ postgres ready for connections
# ✓ backend listening on 0.0.0.0:3001
```

### Terminal 2: Start Frontend Dev Server

```bash
# Start next.js / react dev server
npm run dev

# You should see:
# ✓ Frontend running at http://localhost:3000
```

### Terminal 3: Run E2E Tests

```bash
# Run all tests
npm run test:e2e:local

# Or watch mode for development
npm run test:e2e:local -- --watch

# Or run single test file
npm run test:e2e:local -- tests/01-auth/login.spec.ts

# Or run with UI (visual mode)
npm run test:e2e:ui
```

### Common Commands

```bash
# View Docker logs
docker-compose logs -f backend   # Backend logs
docker-compose logs -f postgres  # Database logs

# Reset database (clean slate for next test run)
docker-compose down -v           # Remove volumes (-v flag)
docker-compose up                # Recreate fresh database

# Stop everything
docker-compose down

# Rebuild backend image (if code changed)
docker-compose build --no-cache backend
docker-compose up
```

---

## Configuration by Environment

### Local Development (Default)

```bash
# No env vars needed, uses defaults
npm run test:e2e:local

# Or explicitly
TEST_ENV=local npm run test:e2e:local
BACKEND_URL=http://localhost:3001 npm run test:e2e:local
```

**Timeouts:** Fast (5s action, 15s nav, 30s test)

### Docker Backend (Production-Like)

```bash
# Backend running in docker (slower than local)
TEST_ENV=docker npm run test:e2e:local
BACKEND_URL=http://localhost:3001 npm run test:e2e:local
```

**Timeouts:** Moderate (10s action, 20s nav, 60s test)

### Staging/Production

```bash
# Test against staging environment
TEST_ENV=staging npm run test:e2e
BACKEND_URL=https://api-staging.example.com npm run test:e2e

# Or production (use with extreme caution!)
TEST_ENV=production npm run test:e2e
BACKEND_URL=https://api.example.com npm run test:e2e
```

**Timeouts:** Conservative (15-25s)

---

## Troubleshooting

### Tests Can't Reach Backend

**Error:** "Connection refused" or "localhost:3001 refused"

**Fix:**
1. Check Docker is running:
   ```bash
   docker ps
   ```
   Should show `e2e_postgres` and `e2e_backend` containers.

2. Check backend is healthy:
   ```bash
   curl http://localhost:3001/health
   ```
   Should return HTTP 200.

3. Check BACKEND_URL in playwright.config.ts:
   ```typescript
   console.log('Backend URL:', BACKEND_API_URL) // Debug line
   ```

4. If still failing, restart:
   ```bash
   docker-compose down
   docker-compose up --build
   ```

### Database State Carries Between Tests

**Problem:** Test 1 creates a user, Test 2 fails because user already exists (collision)

**Fix:**
1. Tests should use **UUID-based identifiers** (not predictable values):
   ```typescript
   // ✅ RIGHT
   const userId = uuidv4()
   const email = `test-${userId}@example.com`
   
   // ❌ WRONG
   const email = 'test@example.com' // collides across runs
   ```

2. Include cleanup in each test:
   ```typescript
   test.afterEach(async ({ page, api }) => {
     // Delete test data
     await api.delete(`/api/users/${userId}`)
     // Or clear auth
     await page.context().clearCookies()
   })
   ```

3. Or reset database between runs:
   ```bash
   docker-compose down -v
   docker-compose up
   ```

### Backend Won't Start (Database Connection Error)

**Error:** "connection refused" from backend → postgres

**Fix:**
The backend needs to wait for postgres to be ready. In `docker-compose.yml`, ensure:
```yaml
depends_on:
  postgres:
    condition: service_healthy  # ← This is critical
healthcheck:  # ← Backend also needs healthcheck
  test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
  interval: 5s
  timeout: 5s
  retries: 5
```

### Tests Timeout

**Problem:** Tests consistently timeout

**Check:**
1. What's the environment?
   ```bash
   echo $TEST_ENV  # Should be 'local', 'docker', 'staging', etc.
   ```

2. What's the timeout?
   ```typescript
   // playwright.config.ts
   console.log('Test timeout:', timeoutConfig.testTimeout)
   ```

3. Is backend responding slowly?
   ```bash
   time curl http://localhost:3001/health
   ```

4. Are tests waiting for elements that don't exist?
   - Use `waitForLoadState()` to wait for network
   - Use explicit waits, not sleep(5000)

**Fix:**
```typescript
// ✅ RIGHT: Wait for network
await page.waitForLoadState('networkidle')

// ✅ RIGHT: Explicit wait for element
await page.getByRole('button', { name: 'Save' }).waitFor({ timeout: 10000 })

// ❌ WRONG: Fixed sleep
await page.waitForTimeout(5000)
```

### Docker Image Won't Build

**Error:** "failed to load dockerfile"

**Fix:**
1. Verify `backend/Dockerfile` exists:
   ```bash
   ls -la backend/Dockerfile
   ```

2. Check path is correct in `docker-compose.yml`:
   ```yaml
   build:
     context: ./backend  # ← Correct path?
     dockerfile: Dockerfile
   ```

3. Rebuild:
   ```bash
   docker-compose build --no-cache
   ```

---

## Environment Variables Reference

### In `docker-compose.yml`

| Variable | Default | Purpose |
|----------|---------|---------|
| `POSTGRES_USER` | `test_user` | Database user |
| `POSTGRES_PASSWORD` | `test_password` | Database password |
| `POSTGRES_DB` | `test_db` | Database name |
| `DATABASE_URL` | (auto-constructed) | Full connection string |
| `NODE_ENV` | `test` | Environment mode |
| `API_PORT` | `3001` | Backend port |

### In `playwright.config.ts`

| Variable | Default | Purpose |
|----------|---------|---------|
| `TEST_ENV` | `local` | Environment (local/docker/staging/ci) |
| `BACKEND_URL` | `http://localhost:3001` | Backend API URL |
| `FRONTEND_URL` | `http://localhost:3000` | Frontend app URL |
| `CI` | unset | Set by CI systems automatically |

### Example: Full Setup with Custom Values

```bash
# Override everything
DB_USER=myuser \
DB_PASSWORD=mypass \
DB_NAME=mydb \
NODE_ENV=test \
TEST_ENV=docker \
BACKEND_URL=http://localhost:3001 \
FRONTEND_URL=http://localhost:3000 \
docker-compose up
```

---

## Best Practices Summary

✅ **Do:**
- Use Docker for backend/database (production-like)
- Run tests locally (fast feedback)
- Use UUID test data (no collisions)
- Reset database between test runs
- Use `waitForLoadState()` for async operations
- Configure timeouts per environment
- Use semantic locators (not testid)

❌ **Don't:**
- Run tests in Docker (slow, hard to debug)
- Use hardcoded test data (causes collisions)
- Use fixed sleeps instead of explicit waits
- Skip database cleanup (leaves state)
- Use same timeout for local and production
- Test against production unless absolutely necessary

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      
      - name: Install dependencies
        run: npm ci
      
      - name: Build backend
        run: cd backend && npm run build
      
      - name: Start backend
        run: cd backend && npm start &
        env:
          DATABASE_URL: postgres://test_user:test_password@localhost:5432/test_db
          NODE_ENV: test
      
      - name: Wait for backend
        run: |
          for i in {1..30}; do
            curl http://localhost:3001/health && exit 0
            sleep 1
          done
          exit 1
      
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          TEST_ENV: ci
```

---

## Next: Integration with Phase 3 Pipeline

The phase3-pipeline.sh script automatically uses these Docker settings when:

1. `BACKEND_URL` environment variable is set
2. Tests reference the configured `playwright.config.ts`
3. Agents retrieve docker configuration from memory

No additional configuration needed — just run:
```bash
./scripts/phase3-pipeline.sh "feature-name" "/page/path"
```

The system will use your Docker setup automatically.
