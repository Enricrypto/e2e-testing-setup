# E2E Testing Setup Guide

This guide helps you integrate the E2E testing bootstrap into your project and run your first test.

---

## Prerequisites

Before installing, ensure you have:
- ✅ Node.js 18+ (`node --version`)
- ✅ npm 9+ (`npm --version`)
- ✅ Next.js 13+ or React 18+ project
- ✅ `package.json` in project root

---

## Installation

### Option 1: From GitHub (Recommended)

If this package is published to GitHub:

```bash
cd your-project/
bash <(curl -s https://raw.githubusercontent.com/youruser/e2e-testing-setup/main/install.sh)
```

### Option 2: Manual Installation

Copy the complete template into your project:

```bash
# Copy E2E directory structure
mkdir -p frontend/e2e/{tests,pom,utils}
mkdir -p docs
mkdir -p scripts

# Copy files from this repo
cp template/frontend/e2e/* your-project/frontend/e2e/
cp template/docs/* your-project/docs/
cp template/scripts/* your-project/scripts/
```

---

## Installation Checklist

After installation, verify you have:

```
your-project/
├── frontend/
│   ├── e2e/
│   │   ├── playwright.config.ts        ✅
│   │   ├── global-setup.ts             ✅
│   │   ├── global-teardown.ts          ✅
│   │   ├── tests/
│   │   │   └── fixtures.ts             ✅
│   │   ├── pom/
│   │   │   └── BasePage.ts             ✅
│   │   └── utils/
│   │       └── test-data.ts            ✅
│   └── package.json                    (E2E scripts added)
│
├── docs/
│   ├── E2E_DEEP_AUDIT_CHECKLIST.md     ✅
│   ├── E2E_PIPELINE_AUDIT.md           ✅
│   ├── PHASE_3_AUTOMATED_PIPELINE.md   ✅
│   └── E2E_SEMANTIC_LOCATORS.md        ✅
│
└── scripts/
    └── phase3-pipeline.sh              ✅
```

Verify:
```bash
ls frontend/e2e/
ls docs/
ls scripts/phase3-pipeline.sh
```

---

## MemoryKit Integration (Optional)

This system optionally integrates with **MemoryKit** for knowledge compounding across features.

### If You Have MemoryKit

MemoryKit enables AI agents to remember test patterns from prior sessions:
- **Planner** retrieves similar test patterns from previous features
- **Generator** reuses proven test patterns (faster code generation)
- **Healer** learns from prior failure patterns (better debugging)
- Each feature gets faster (40% speed improvement after 5-10 features)

**MemoryKit is pre-installed** if you have Claude Code with MCP support.

### If You Don't Have MemoryKit

**Tests work perfectly without it.** MemoryKit is completely optional.

Without MemoryKit:
- ✅ Tests still run and pass
- ✅ Agents still generate good code
- ✅ Pipeline still works end-to-end
- ⚠️ Agents start from scratch each feature (no knowledge compounding)

**You re-describe patterns each session**, but that's fine for small teams or occasional feature work.

### How to Tell If MemoryKit Is Available

When you run `./scripts/phase3-pipeline.sh`, look for this message:

```bash
# WITH MemoryKit:
[MemoryKit] Retrieving prior patterns for "advertiser-dashboard"...
✓ Found 3 similar patterns from prior features

# WITHOUT MemoryKit:
[MemoryKit] Not available (proceeding without memory)
→ Agents will explore code from scratch
```

### Enabling MemoryKit (Advanced)

If you want to install MemoryKit:

1. **Verify Claude Code is running** with MCP support
2. **Install MemoryKit MCP**:
   ```bash
   # Follow: https://github.com/antoniorapozo/memorykit-mcp
   ```
3. **Restart Claude Code**
4. **Re-run the pipeline** — agents will automatically use MemoryKit

No other changes needed. The pipeline automatically detects and uses MemoryKit if available.

### Bottom Line

- **Starting out?** Don't worry about MemoryKit. Focus on writing good tests.
- **Have many features?** MemoryKit saves time (optional upgrade later).
- **Already installed?** Great! Agents will automatically use it.

---

## Initial Dependencies

Install Playwright and required packages:

```bash
npm install --save-dev @playwright/test @playwright/mcp
npm install uuid
npm install --save-dev @types/uuid
```

Verify:
```bash
npm list @playwright/test @playwright/mcp uuid
```

---

## First Test Run

### 1. Start Your App

```bash
# Terminal 1
npm run dev
# Wait for: "ready - started server on 0.0.0.0:3000"
```

### 2. Run the Pipeline

```bash
# Terminal 2
./scripts/phase3-pipeline.sh "example" "/example-page"
```

### 3. Follow Prompts

- The script guides you through each step
- Copy prompts to Cursor/Claude when instructed
- Paste results back to terminal
- System verifies and runs tests

### 4. Check Results

Tests should run and report results. On first run, expect:
- ✅ Setup completed
- ⚠ May see some type warnings (normal on first run)
- Tests execute (may pass or need tuning)

---

## Troubleshooting Installation

### Problem: "npm: command not found"

```bash
# Install Node.js from https://nodejs.org
node --version  # Verify installation
```

### Problem: "playwright.config.ts not found"

```bash
# Reinstall from this repo
cp template/frontend/e2e/playwright.config.ts frontend/e2e/
```

### Problem: "@playwright/test not found"

```bash
npm install --save-dev @playwright/test @playwright/mcp
npm install uuid @types/uuid
```

### Problem: "permission denied: ./scripts/phase3-pipeline.sh"

```bash
chmod +x scripts/phase3-pipeline.sh
```

---

## Next Steps

1. **Read Phase 0 Audit**: `cat docs/E2E_DEEP_AUDIT_CHECKLIST.md`
2. **Document your first feature** (routes, components, APIs, edge cases)
3. **Run the pipeline**: `./scripts/phase3-pipeline.sh "your-feature" "/your/page"`
4. **Follow AI-assisted workflow** (Planner → Generator → Verify → Test)
5. **Read Phase 8 Audit**: `cat docs/E2E_PIPELINE_AUDIT.md`
6. **Commit**: `git add frontend/e2e/; git commit -m "feat(e2e): Add tests"`

---

## Package.json Addition Reference

The installer adds these scripts to your `package.json`:

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:local": "TEST_ENV=local playwright test",
    "test:e2e:staging": "TEST_ENV=staging playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug"
  }
}
```

Use them:
```bash
npm run test:e2e:local        # Run tests with local timeouts
npm run test:e2e:ui          # Run with interactive UI
npm run test:e2e:debug       # Debug mode with inspector
```

---

## Test Setup & Teardown

Your project includes `global-setup.ts` and `global-teardown.ts` for one-time setup/cleanup:

### Global Setup (Runs Once Before All Tests)

Used for:
- Database initialization
- Test data seeding
- Verifying backend is ready
- Starting services

Location: `frontend/e2e/global-setup.ts`

Example:
```typescript
// Verifies backend is running
async function globalSetup() {
  await verifyBackendIsReady()
  await initializeTestDatabase()
}
```

### Global Teardown (Runs Once After All Tests)

Used for:
- Database cleanup
- Service shutdown
- Report generation

Location: `frontend/e2e/global-teardown.ts`

Example:
```typescript
// Cleans up after all tests complete
async function globalTeardown() {
  await cleanupTestDatabase()
  await generateTestSummary()
}
```

### Fixture Setup/Teardown (Per Test)

Runs before each individual test and cleans up after:

Location: `frontend/e2e/tests/fixtures.ts`

Example:
```typescript
// Creates test user before test, deletes after
test.extend({
  testUser: async ({ apiClient }, use) => {
    // SETUP: Create user
    const user = await apiClient.post('/auth/register', {...})
    
    // TEST RUNS HERE
    await use(user)
    
    // TEARDOWN: Delete user
    await apiClient.delete(`/auth/users/${user.id}`)
  }
})
```

### When to Use Each

| Goal | Tool | Runs |
|------|------|------|
| Initialize database once | global-setup | Once (before all) |
| Create account for ONE test | fixture | Per test |
| Cleanup after ONE test | fixture | Per test |
| Reset database for all tests | global-teardown | Once (after all) |

**Recommended pattern:**
- Global setup: One-time initialization
- Fixtures: Per-test user creation/cleanup
- Global teardown: Final cleanup and reporting

---

## Questions?

- **Setup issues**: Check Prerequisites section above
- **How pipeline works**: Read `README.md` (starts with "What This Is")
- **First feature**: Follow `docs/E2E_DEEP_AUDIT_CHECKLIST.md`
- **Test examples**: Look in `frontend/e2e/tests/01-example/`
- **POM pattern**: Look in `frontend/e2e/pom/ExamplePage.ts`

---

**Status**: Ready to use  
**Last Updated**: 2026-06-05
