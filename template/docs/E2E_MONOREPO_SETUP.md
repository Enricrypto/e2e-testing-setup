# E2E Testing in Monorepos (Advanced Topic)

**Optional guide for teams using monorepo structures with multiple frontend apps.**

If you have a single frontend app, you don't need this guide. This is for advanced setups only.

---

## When You Need This Guide

You're in a monorepo if your structure looks like:

```
my-monorepo/
├── apps/
│   ├── advertiser-dashboard/     ← Separate Next.js app
│   ├── admin-panel/              ← Separate Next.js app
│   └── user-site/                ← Separate Next.js app
├── packages/
│   ├── api/                       ← Shared backend
│   ├── components/                ← Shared UI components
│   └── types/                     ← Shared TypeScript types
└── docker-compose.yml             ← Single Docker setup
```

If your structure is simpler (one backend, one frontend), use the standard setup.

---

## Monorepo E2E Testing Architecture

### Shared vs App-Specific Tests

```
my-monorepo/
├── apps/
│   ├── advertiser-dashboard/
│   │   └── e2e/
│   │       ├── tests/
│   │       │   ├── dashboard.spec.ts        ← App-specific
│   │       │   └── listings.spec.ts         ← App-specific
│   │       ├── pom/
│   │       │   └── DashboardPage.ts         ← App-specific
│   │       └── fixtures.ts                  ← App-specific
│   │
│   └── admin-panel/
│       └── e2e/
│           ├── tests/
│           │   ├── admin-users.spec.ts      ← App-specific
│           │   └── admin-settings.spec.ts   ← App-specific
│           └── fixtures.ts                  ← App-specific
│
├── e2e-shared/                              ← NEW: Shared test utilities
│   ├── fixtures/
│   │   ├── auth.ts                          ← Shared login/logout
│   │   ├── api.ts                           ← Shared API client
│   │   └── test-data.ts                     ← Shared test data factory
│   │
│   ├── pom/
│   │   ├── BasePage.ts                      ← Base POM (both apps inherit)
│   │   ├── HeaderPage.ts                    ← Shared header (both apps)
│   │   └── LoginPage.ts                     ← Shared login (both apps)
│   │
│   └── playwright.config.base.ts            ← Base config (extended by each app)
│
└── docker-compose.yml                       ← Single Docker setup for all apps
```

---

## Setup Steps

### Step 1: Create Shared Testing Utilities

Create `e2e-shared/` directory with reusable fixtures and POMs:

```typescript
// e2e-shared/fixtures/auth.ts
import { test as base } from '@playwright/test'
import { v4 as uuid } from 'uuid'

export const test = base.extend({
  // Shared fixture: Advertiser login
  authenticatedAdvertiser: async ({ page }, use) => {
    const email = `advertiser-${uuid().slice(0, 8)}@test.com`
    const password = 'TestPassword123'
    
    // Create user via API (shared across all apps)
    const createResponse = await page.request.post(
      'http://localhost:5001/api/v1/auth/register',
      {
        data: {
          email,
          password,
          role: 'advertiser'
        }
      }
    )
    
    expect(createResponse.ok()).toBeTruthy()
    const { token } = await createResponse.json()
    
    // Log in
    await page.goto('/login')
    await page.fill('[data-testid="email-input"]', email)
    await page.fill('[data-testid="password-input"]', password)
    await page.click('[data-testid="login-button"]')
    
    await use({ page, email, password, token })
    
    // Cleanup
    if (token) {
      await page.request.delete('http://localhost:5001/api/v1/auth/user', {
        headers: { Authorization: `Bearer ${token}` }
      })
    }
  }
})

export { expect }
```

```typescript
// e2e-shared/pom/BasePage.ts
import { Page, Locator } from '@playwright/test'

export class BasePage {
  readonly page: Page
  readonly header: Locator
  readonly mainNav: Locator
  
  constructor(page: Page) {
    this.page = page
    this.header = page.locator('[data-testid="header"]')
    this.mainNav = page.locator('[data-testid="main-nav"]')
  }
  
  // Shared method: Navigate to URL
  async goto(path: string) {
    await this.page.goto(path)
  }
  
  // Shared method: Get current app name
  async getAppName(): Promise<string> {
    return this.page.evaluate(() => {
      const meta = document.querySelector('meta[name="app-name"]')
      return meta?.getAttribute('content') || 'unknown'
    })
  }
  
  // Shared method: Check if user logged in
  async isLoggedIn(): Promise<boolean> {
    return this.page.evaluate(() => {
      return !!localStorage.getItem('authToken')
    })
  }
}
```

### Step 2: Configure Each App's E2E

In each app (`apps/advertiser-dashboard/e2e/`):

```typescript
// apps/advertiser-dashboard/e2e/playwright.config.ts
import { defineConfig, devices } from '@playwright/test'
import baseConfig from '../../../e2e-shared/playwright.config.base'

export default defineConfig({
  ...baseConfig,
  
  // App-specific settings
  testDir: './tests',
  webServer: {
    command: 'npm run dev',
    port: 3000,
    timeout: 120000,
  },
  
  // Use different timeouts or browsers if needed
  use: {
    ...baseConfig.use,
    baseURL: 'http://localhost:3000',
  },
})
```

```typescript
// apps/advertiser-dashboard/e2e/tests/fixtures.ts
import { test as sharedTest, expect } from '../../../e2e-shared/fixtures/auth'

// Extend shared fixtures with app-specific ones
export const test = sharedTest.extend({
  // App-specific fixture: Advertiser with listings
  advertiserWithListings: async ({ authenticatedAdvertiser }, use) => {
    const { page, token } = authenticatedAdvertiser
    
    // Create test listings for this app
    const listings = await page.request.post(
      'http://localhost:5001/api/v1/listings',
      {
        headers: { Authorization: `Bearer ${token}` },
        data: [
          { title: 'Apartment 1', price: 100 },
          { title: 'House 1', price: 500 },
        ]
      }
    )
    
    await use({ 
      page, 
      ...authenticatedAdvertiser, 
      listings: await listings.json() 
    })
  }
})

export { expect }
```

### Step 3: Run E2E Tests in Each App

```bash
# Run tests for one app
cd apps/advertiser-dashboard
npm run e2e

# Run tests for all apps
for app in apps/*/; do
  cd "$app"
  npm run e2e
  cd - > /dev/null
done
```

---

## Monorepo-Specific Patterns

### Shared API Client Fixture

```typescript
// e2e-shared/fixtures/api.ts
import { test as base } from '@playwright/test'

export const test = base.extend({
  apiClient: async ({ page }, use) => {
    const apiBase = process.env.API_URL || 'http://localhost:5001/api/v1'
    
    const client = {
      // Generic request method
      async request(method: string, path: string, data?: any) {
        const token = await page.evaluate(() => localStorage.getItem('authToken'))
        
        return page.request[method.toLowerCase()](
          `${apiBase}${path}`,
          {
            headers: token ? { Authorization: `Bearer ${token}` } : {},
            data
          }
        )
      },
      
      // Convenience methods
      async get(path: string) {
        return this.request('GET', path)
      },
      
      async post(path: string, data: any) {
        return this.request('POST', path, data)
      },
      
      async put(path: string, data: any) {
        return this.request('PUT', path, data)
      },
      
      async delete(path: string) {
        return this.request('DELETE', path)
      }
    }
    
    await use(client)
  }
})

export { expect }
```

Use it in tests:

```typescript
test('can fetch listings via shared API', async ({ apiClient }) => {
  const response = await apiClient.get('/listings')
  expect(response.ok()).toBeTruthy()
  
  const listings = await response.json()
  expect(listings.length).toBeGreaterThan(0)
})
```

### Shared Test Data Factory

```typescript
// e2e-shared/fixtures/test-data.ts
import { v4 as uuid } from 'uuid'

export const testData = {
  // Generate unique test email
  email: () => `test-${uuid().slice(0, 8)}@example.com`,
  
  // Generate unique test listing
  listing: () => ({
    title: `Listing ${uuid().slice(0, 8)}`,
    description: 'Test listing description',
    price: Math.floor(Math.random() * 1000) + 100,
  }),
  
  // Generate unique test user
  user: (role = 'advertiser') => ({
    email: `test-${uuid().slice(0, 8)}@example.com`,
    password: 'TestPassword123',
    role,
  }),
}
```

Use it in tests:

```typescript
import { testData } from '../../../e2e-shared/fixtures/test-data'

test('create listing with unique data', async ({ page }) => {
  const listing = testData.listing()
  
  await page.fill('[data-testid="title"]', listing.title)
  await page.fill('[data-testid="price"]', listing.price.toString())
  // ...
})
```

### Running Tests with Different Backend URLs

```bash
# Test against local backend
API_URL=http://localhost:5001/api/v1 npm run e2e

# Test against staging backend
API_URL=https://api-staging.example.com/api/v1 npm run e2e

# Test against production (rarely do this!)
API_URL=https://api.example.com/api/v1 npm run e2e
```

---

## CI/CD for Monorepos

### GitHub Actions Example

```yaml
name: E2E Tests - All Apps

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        app: [advertiser-dashboard, admin-panel, user-site]
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: password
      
      redis:
        image: redis:7
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies (root)
        run: npm install
      
      - name: Start backend
        run: docker-compose up -d api
      
      - name: Wait for backend
        run: |
          until curl http://localhost:5001/health; do
            sleep 1
          done
      
      - name: Run E2E tests - ${{ matrix.app }}
        working-directory: apps/${{ matrix.app }}
        run: npm run e2e
      
      - name: Upload results - ${{ matrix.app }}
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: e2e-results-${{ matrix.app }}
          path: apps/${{ matrix.app }}/e2e/playwright-report/
```

---

## Sharing Test Results Across Apps

### Consolidated Test Report

Create a script to merge results:

```bash
#!/bin/bash
# scripts/merge-e2e-reports.sh

# Create reports directory
mkdir -p reports

# For each app, copy results
for app in apps/*/; do
  app_name=$(basename "$app")
  cp -r "$app/e2e/playwright-report" "reports/$app_name"
done

# Generate summary
cat > reports/summary.md << EOF
# E2E Test Results Summary

Generated: $(date)

EOF

for report in reports/*/; do
  app_name=$(basename "$report")
  if [ -f "$report/summary.json" ]; then
    echo "## $app_name" >> reports/summary.md
    grep -E '"passed"|"failed"' "$report/summary.json" >> reports/summary.md
  fi
done
```

---

## Monorepo-Specific Best Practices

### 1. Use Shared Dependencies

Don't repeat fixtures across apps. Put them in `e2e-shared/` and import:

```typescript
// DON'T do this in each app
const authenticateUser = async (page, email) => { ... }

// DO this instead
import { test } from '../../../e2e-shared/fixtures/auth'
```

### 2. Keep Base Config in Shared Directory

```typescript
// e2e-shared/playwright.config.base.ts
export default {
  timeout: 30000,
  retries: 1,
  use: { baseURL: 'http://localhost:3000' },
  // ...
}

// apps/advertiser-dashboard/e2e/playwright.config.ts
import baseConfig from '../../../e2e-shared/playwright.config.base'
export default defineConfig({
  ...baseConfig,
  // App-specific overrides
})
```

### 3. Use Workspace Package Management

If using npm workspaces:

```json
{
  "workspaces": [
    "apps/*",
    "e2e-shared",
    "packages/*"
  ]
}
```

Then install once at root:

```bash
npm install
# All workspaces get dependencies
```

### 4. Test Cross-App Flows

If one app talks to another, test the integration:

```typescript
test('advertiser can share listing with admin', async ({ advertiser, admin }) => {
  // Advertiser creates listing
  const listing = await advertiser.apiClient.post('/listings', {
    title: 'Test Property'
  })
  
  // Admin app can see it
  await admin.page.goto(`/listings/${listing.id}`)
  await expect(admin.page.getByText('Test Property')).toBeVisible()
})
```

### 5. Manage Test Data Across Apps

If tests create data that affects other apps:

```typescript
// Clean up test data created across all apps
afterAll(async () => {
  // Delete test user (affects advertiser + admin app)
  await page.request.delete('/api/v1/auth/user')
  
  // Cleanup propagates across all apps
})
```

---

## Troubleshooting Monorepo Setup

### Problem: "Module not found" in shared fixtures

**Solution:** Ensure paths are correct:

```typescript
// ❌ WRONG: Relative path breaks if test moves
import { test } from '../../fixtures/auth'

// ✅ RIGHT: Explicit path from repo root
import { test } from '../../../e2e-shared/fixtures/auth'

// ✅ ALSO RIGHT: Use npm workspace alias
// In package.json: "@monorepo/e2e-shared": "*"
import { test } from '@monorepo/e2e-shared/fixtures/auth'
```

### Problem: Tests interfere with each other across apps

**Solution:** Use app-specific test databases or test users:

```bash
# Each app gets its own test DB
ADVERTISER_TEST_DB=postgres://localhost/advertiser_test \
ADMIN_TEST_DB=postgres://localhost/admin_test \
npm run e2e
```

### Problem: Backend URL differs per app

**Solution:** Use environment variables:

```typescript
const baseURL = process.env.API_URL || 'http://localhost:5001/api/v1'

export const test = base.extend({
  apiClient: async ({ page }, use) => {
    const client = {
      async get(path: string) {
        return page.request.get(`${baseURL}${path}`)
      }
    }
    await use(client)
  }
})
```

---

## When NOT to Use Monorepo Setup

If you have:
- Single frontend app
- Separate backend service
- No shared test utilities

Then use the standard setup (single `frontend/e2e/` directory).

---

## Resources

- **npm Workspaces:** https://docs.npmjs.com/cli/v8/using-npm/workspaces
- **Monorepo Tools:** Lerna, pnpm, Yarn, Turbo
- **Playwright Monorepo Testing:** https://playwright.dev/docs/testing-library

---

**Last Updated:** 2026-06-10  
**Status:** Complete, ready for advanced teams
