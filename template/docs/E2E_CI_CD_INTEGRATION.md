# E2E Testing in CI/CD

This guide shows how to integrate Playwright E2E tests into GitHub Actions, GitLab CI, or similar CI/CD systems.

---

## GitHub Actions Example

### Basic Workflow

Create `.github/workflows/e2e-tests.yml`:

```yaml
name: E2E Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps

      - name: Start backend (Docker)
        run: docker-compose -f docker-compose.test.yml up -d
        env:
          ASPNETCORE_ENVIRONMENT: Test  # Use test rate limits if .NET

      - name: Wait for services
        run: |
          npx wait-on http://localhost:5001/health --timeout 30000

      - name: Run E2E tests
        run: npm run test:e2e
        env:
          CI: true
          BACKEND_URL: http://localhost:5001
          FRONTEND_URL: http://localhost:3000

      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: frontend/e2e/playwright-report/
          retention-days: 30

      - name: Upload test videos (failures only)
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-videos
          path: frontend/e2e/test-results/
          retention-days: 7
```

### Run Tests Only on PR

If you want to run E2E tests only on pull requests (not on every commit):

```yaml
on:
  pull_request:
    branches: [main]
```

### Run Tests on Schedule

Run E2E tests nightly:

```yaml
on:
  schedule:
    # Run at 2 AM UTC every night
    - cron: '0 2 * * *'
```

---

## Environment-Specific Configuration

Different environments need different timeouts and settings:

### playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test'

const env = process.env.TEST_ENV || 'local'
const isCI = !!process.env.CI

const config = {
  local: {
    workers: 4,
    timeout: 30000,
    navigationTimeout: 15000,
    retries: 0,
    name: 'Local Development',
  },
  ci: {
    workers: 2,  // GitHub Actions typically has 2 CPU cores
    timeout: 60000,  // Longer timeout for CI
    navigationTimeout: 30000,
    retries: 1,  // Retry once on failure
    name: 'CI/CD Pipeline',
  },
  staging: {
    workers: 1,  // Conservative on staging
    timeout: 120000,  // Even longer for staging
    navigationTimeout: 45000,
    retries: 1,
    name: 'Staging Environment',
  },
  debug: {
    workers: 1,
    timeout: 300000,  // 5 minutes for manual debugging
    navigationTimeout: 120000,
    retries: 0,
    name: 'Debug Mode',
  },
}[env] || config.local

export default defineConfig({
  testDir: './e2e/tests',
  timeout: config.timeout,
  navigationTimeout: config.navigationTimeout,
  fullyParallel: true,
  workers: config.workers,
  retries: config.retries,
  
  reporter: [
    ['html'],
    ['list'],
    ...(isCI ? [
      ['json', { outputFile: 'test-results/results.json' }],
      ['junit', { outputFile: 'test-results/results.xml' }],
      ['github'],  // GitHub Actions reporter
    ] : []),
  ],

  use: {
    baseURL: process.env.FRONTEND_URL || 'http://localhost:3000',
    actionTimeout: 10000,
    trace: isCI ? 'retain-on-failure' : 'on-first-retry',
    screenshot: 'only-on-failure',
    video: isCI ? 'retain-on-failure' : 'off',
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
    ...(isCI ? [] : [
      {
        name: 'webkit',
        use: { ...devices['Desktop Safari'] },
      },
    ]),
  ],
})
```

---

## Parallel Sharding (Speed Up CI)

Run tests across multiple CI workers (faster):

### Sharded Workflow

```yaml
jobs:
  e2e:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3, 4]  # Run 4 parallel shards
      fail-fast: false  # Don't cancel other shards if one fails

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Run E2E tests (shard ${{ matrix.shard }}/4)
        run: npm run test:e2e -- --shard=${{ matrix.shard }}/4
        env:
          CI: true

      - name: Upload blob report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: blob-report-${{ matrix.shard }}
          path: blob-report/
```

Then merge results:

```yaml
  merge-reports:
    needs: [e2e]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Download all blob reports
        uses: actions/download-artifact@v4
        with:
          path: all-blob-reports/
          pattern: blob-report-*

      - name: Merge reports
        run: npx playwright merge-reports --reporter html all-blob-reports/

      - name: Upload HTML report
        uses: actions/upload-artifact@v4
        with:
          name: html-report
          path: playwright-report/
```

---

## Fail on Flaky Tests

Mark tests as expected to fail sometimes:

```typescript
test('might be flaky', async ({ page }) => {
  test.annotations.push({ type: 'flaky', description: 'Unreliable on slow CI' })
  // test code...
})
```

Filter out flaky tests from CI failures:

```typescript
// playwright.config.ts
export default defineConfig({
  webServer: {
    // ...
  },
  
  // Flaky tests don't fail the build in CI
  ...(isCI ? {
    retries: 2,
  } : {}),
})
```

---

## Slack Notifications

Post test results to Slack:

```yaml
      - name: Notify Slack on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "E2E tests failed in ${{ github.ref }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*E2E Tests Failed*\nBranch: ${{ github.ref }}\nAuthor: ${{ github.actor }}\nRun: <${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Details>"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Docker Compose for CI

Create `docker-compose.test.yml` for CI/CD:

```yaml
version: '3'

services:
  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "5001:5000"
    environment:
      ASPNETCORE_ENVIRONMENT: Test
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/test_db
      REDIS_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: test_db
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
```

---

## Common Issues

### Tests timeout in CI

Increase timeout in `playwright.config.ts`:

```typescript
timeout: 60000,  // Increase from 30000
navigationTimeout: 30000,  // Increase from 15000
```

### Backend not reachable in CI

Ensure health check passes before tests:

```yaml
      - name: Wait for backend
        run: |
          for i in {1..30}; do
            curl http://localhost:5001/health && exit 0
            sleep 1
          done
          exit 1
```

### Tests pass locally but fail in CI

Common causes:
- Different backend (check BACKEND_URL env var)
- Different database state (use test database reset)
- Timing issues (increase timeouts, reduce parallelization)
- Missing environment variables (check CI secrets)

---

## Best Practices

1. **Pin Node.js version** — Ensures consistency
   ```yaml
   node-version: '20.11.0'  # Use exact version
   ```

2. **Cache dependencies** — Speeds up CI
   ```yaml
   cache: 'npm'
   ```

3. **Fail fast on errors** — Report problems quickly
   ```yaml
   fail-fast: false  # But don't cancel shards
   ```

4. **Save artifacts** — For debugging
   ```yaml
   uses: actions/upload-artifact@v4
   ```

5. **Use health checks** — Ensure services are ready
   ```yaml
   condition: service_healthy
   ```

6. **Reasonable timeouts** — Not too strict, not too loose
   ```yaml
   timeout-minutes: 10  # For whole job
   ```

---

## Troubleshooting Checklist

- [ ] Playwright installed: `npm ci` runs successfully
- [ ] Browsers installed: `npx playwright install --with-deps`
- [ ] Services running: Health checks pass
- [ ] Backend URL correct: Check `BACKEND_URL` env var
- [ ] Tests run locally: `npm run test:e2e` passes
- [ ] Artifacts saved: Check uploads in Actions tab
- [ ] Timeouts reasonable: Not too strict for CI
- [ ] Environment vars set: Check GitHub Secrets

---

## Summary

Key points:
- Tests need longer timeouts in CI (network latency)
- Run on Ubuntu, pin Node.js version
- Health checks ensure services are ready
- Sharding parallelizes tests for speed
- Artifacts preserve reports and videos for debugging
- Slack notifications keep team informed
