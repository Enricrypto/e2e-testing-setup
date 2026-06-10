# The Complete E2E Testing Pipeline

**Reference guide for the automated test generation system**  
**Read when you want to understand the full 8-step flow**

---

## Quick Overview

This project uses an **8-step pipeline** for E2E testing:

- **Phase 0 & 8:** Manual (you do the audit)
- **Phase 1-7:** Automated (pipeline orchestrates AI agents + checks)

The pipeline script (`./scripts/phase3-pipeline.sh`) runs steps 1-7 automatically, but guides you through manual steps 0 and 8.

---

## The Complete Flow

```
┌─────────────────────────────────────────────────────────┐
│ PHASE 0: Deep Codebase Audit (YOU)                       │
│ Read: docs/E2E_DEEP_AUDIT_CHECKLIST.md                   │
│ Task: Document what actually exists in your feature      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ PHASE 1-2: Prerequisites & Setup (AUTOMATED)             │
│ Step 1: Check npm, app running, E2E installed            │
│ Step 2: Display E2E skill & patterns                     │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ PHASE 3: AI-Assisted Test Generation (INTERACTIVE)      │
│ Step 3: Planner Agent explores app → test plan          │
│ Step 4: Generator Agent writes tests → test code        │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ PHASE 5-7: Verification & Execution (AUTOMATED)         │
│ Step 5: Code quality verification (locators, cleanup)   │
│ Step 6: TypeScript type checking                        │
│ Step 7: Test execution (npm run test:e2e:local)         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ PHASE 8: Deep Test Audit (YOU)                          │
│ Read: docs/E2E_PIPELINE_AUDIT.md                        │
│ Task: Verify tests match actual code                    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│ DONE: Commit tests to git                               │
│ git add frontend/e2e/                                   │
│ git commit -m "feat(e2e): Add [feature] tests"         │
└─────────────────────────────────────────────────────────┘
```

---

## Phase-by-Phase Breakdown

### PHASE 0: Deep Codebase Audit (Manual)

**What you do:**
1. Read `docs/E2E_DEEP_AUDIT_CHECKLIST.md`
2. Explore your actual codebase
3. Document:
   - Actual routes (verify in router)
   - Actual components (verify JSX/TSX)
   - Actual API endpoints (verify backend)
   - User flows (trace through code)
   - Error scenarios (find error handling)
   - Edge cases (find special cases)

**Output:** Your audit notes (text document or clipboard)

**Why:** AI needs to understand real code, not guess. Garbage audit → garbage tests.

**Time:** 15-30 minutes per feature

---

### PHASE 1: Prerequisites Check (Automated - Step 1)

**What the pipeline does:**
```bash
✓ Check npm is installed
✓ Check package.json exists
✓ Check app is running on localhost:3000
✓ Check frontend/e2e/playwright.config.ts exists
```

**If any check fails:**
- Error message tells you exactly what to fix
- Fix it, then re-run `./scripts/phase3-pipeline.sh`

**Example error:**
```
❌ App not running on http://localhost:3000
   Start it with: npm run dev
```

---

### PHASE 2: Skill & Pattern Display (Automated - Step 2)

**What the pipeline does:**
1. Displays this README
2. Shows semantic locator patterns
3. Shows fixture examples
4. Reminds you of best practices

**Your role:** Read, understand, remember for later

---

### PHASE 3: AI-Assisted Test Generation (Interactive - Steps 3-4)

#### Step 3: Planner Agent (Exploration)

**What AI does:**
```
INPUT:  Your Phase 0 audit notes
        Route to test: /dashboard
        App running at: http://localhost:3000

PROCESS: Uses Playwright MCP to:
         - Load the page
         - Inspect the HTML
         - Map user flows
         - Identify error scenarios
         - Find edge cases

OUTPUT: Markdown test plan document
```

**Your role:**
1. Pipeline displays a prompt (copy it)
2. Paste prompt into Cursor/Claude chat
3. Let AI explore your app (via Playwright MCP)
4. AI returns test plan (Markdown)
5. Copy the test plan back to terminal

**Example output:**
```
# Test Plan: Dashboard

## Happy Path
1. User logs in with valid credentials
2. Redirected to /dashboard
3. Dashboard loads with greeting
4. Listings table displays all user listings

## Error Scenarios
- 401 Unauthorized: redirect to login
- 403 Forbidden: show "access denied"
- Empty state: show "no listings yet"

## Edge Cases
- User with 0 listings
- Concurrent edit conflict
- Stale JWT token
```

**Time:** 5-10 minutes (AI exploration + your copy/paste)

---

#### Step 4: Generator Agent (Code Creation)

**What AI does:**
```
INPUT:  Test plan from Step 3
        Semantic locator patterns (from skill)
        Fixture patterns
        UUID test data patterns

PROCESS: Generates:
         - Complete test file (.spec.ts)
         - Page Object Model class
         - All tests following best practices

OUTPUT: Production-ready test code
```

**Your role:**
1. Pipeline displays updated prompt (includes test plan)
2. Paste prompt into Cursor/Claude chat
3. Let AI generate code
4. AI returns complete test file + POM class
5. Copy the code back to terminal

**Example output:**
```typescript
import { test, expect } from '@playwright/test'
import { DashboardPage } from '../../pom/DashboardPage'

test('AC1: Dashboard loads and displays user greeting', async ({ page }) => {
  const dashboard = new DashboardPage(page)
  
  await dashboard.goTo()
  
  await expect(page.getByRole('heading', { name: /welcome/i }))
    .toBeVisible()
})
```

**Time:** 5-10 minutes (AI generation + your copy/paste)

---

### PHASE 5: Code Quality Verification (Automated - Step 5)

**What the pipeline checks:**
```
✓ Uses semantic locators (getByRole, getByLabel, getByText)
✓ Uses fixtures for auth/setup (not hardcoded)
✓ Has cleanup (test.afterEach clears session)
✓ Uses UUID test data (not Date.now())
✓ Explicit timeouts configured
✓ Pragmatism guardrails (max 3-4 interactions per test)
✓ Design justification comments (why each test exists)
✓ No duplicate tests (coverage map verified)
```

**Pragmatism Checks:**
- Each test has ≤ 3-4 user interactions (fails if >4)
- Each test checks 1 focused assertion (not multiple independent things)
- Tests can run independently (no test-to-test dependencies)
- Setup is simple (uses fixtures, not long manual setup)
- Comments explain why test exists and what it covers

**If checks fail:**
```
⚠ No semantic locators found
  → Fix code to use getByRole/getByLabel/getByText
  → Re-run pipeline
```

**Your role:** Fix any failing checks, then re-run

**Time:** < 1 minute (automated check)

---

### PHASE 6: TypeScript Type Checking (Automated - Step 6)

**What the pipeline does:**
```bash
cd frontend
npx tsc --noEmit  # Check types without building
```

**If type check fails:**
```
error TS2339: Property 'getByRole' does not exist
  → Fix import statements
  → Use correct Playwright types
  → Re-run pipeline
```

**Your role:** Fix any type errors, then re-run

**Time:** < 1 minute (automated check)

---

### PHASE 7: Test Execution (Automated - Step 7)

**What the pipeline does:**
```bash
npm run test:e2e:local  # Run tests in local environment
```

**Output:**
```
✓ AC1: Dashboard loads with greeting (2.3s)
✓ AC2: Can edit listing (3.1s)
✓ AC3: Shows error when API fails (1.8s)

Passed: 3, Failed: 0
```

**If tests fail:**
```
✗ AC2: Can edit listing (timeout)
  → Element not found: getByRole('button', { name: /edit/i })
  → Reason: Selector doesn't match actual HTML
```

**Your role:**
- Review failures carefully
- Identify root cause (wrong selector? missing data? timing?)
- Either:
  - Fix the test (wrong assertion)
  - Fix the test data (unrealistic data)
  - Fix preconditions (setup is wrong)
- Re-run tests

**Time:** 2-5 minutes (tests run + any fixes)

---

### PHASE 8: Deep Test Audit (Manual)

**What you do:**
1. Read `docs/E2E_PIPELINE_AUDIT.md`
2. For **each test**, verify:
   - Assertion matches actual app output
   - Test data is realistic
   - Setup creates required preconditions
   - Cleanup works correctly
   - No "ghost features"
3. Re-run tests if you make changes

**Output:** Confidence that tests actually verify real code

**Why:** Tests that don't match code catch nothing. This audit prevents false coverage.

**Time:** 15-30 minutes per feature

---

## How to Run the Pipeline

### One-Time Setup
```bash
# In your project root
bash <(curl -s https://raw.githubusercontent.com/youruser/e2e-testing-setup/main/install.sh)
# Or if local:
bash /path/to/e2e-testing-setup/install.sh
```

### For Each Feature

**Terminal 1 (start app):**
```bash
npm run dev
# App runs on http://localhost:3000
```

**Terminal 2 (run pipeline):**
```bash
# Phase 0
cat docs/E2E_DEEP_AUDIT_CHECKLIST.md
# Document your feature...

# Run the pipeline
./scripts/phase3-pipeline.sh "dashboard" "/dashboard"

# Follow prompts:
# - Copy/paste Planner prompt to Claude
# - Copy/paste test plan back to terminal
# - Copy/paste Generator prompt to Claude
# - Copy/paste generated code back to terminal
# - System verifies, runs tests

# Phase 8
cat docs/E2E_PIPELINE_AUDIT.md
# Verify each test matches actual code...

# Commit
git add frontend/e2e/
git commit -m "feat(e2e): Add dashboard tests"
```

---

## The Three AI Agents

### Agent 1: Planner
- **Role:** Exploration
- **Input:** Your audit notes + app running
- **Output:** Test plan (what to test)
- **Tools:** Playwright MCP to inspect app
- **When:** Step 3

### Agent 2: Generator
- **Role:** Code creation
- **Input:** Test plan + patterns
- **Output:** Test code (how to test)
- **Tools:** Code generation
- **When:** Step 4

### Agent 3: Healer (Optional)
- **Role:** Failure diagnosis
- **Input:** Test failure output
- **Output:** Root cause + fix
- **Tools:** Code analysis
- **When:** Only if Step 7 fails

---

## Common Issues & Fixes

| Issue | Step | Likely Cause | Fix |
|-------|------|--------------|-----|
| "App not running" | 1 | npm dev not started | `npm run dev` in Terminal 1 |
| "Element not found" | 7 | Wrong selector | Update selector to match actual HTML |
| "Type error" | 6 | Missing import | Add import for Playwright types |
| "Assertion failed" | 7 | Test assumes wrong output | Fix assertion to match app output |
| "Timeout" | 7 | Element takes too long to appear | Increase timeout or add explicit wait |
| "Flaky test" | 7 | Race condition | Add cleanup or explicit waits |

---

## Phase Summary

| Phase | Who | Task | Time | Read |
|-------|-----|------|------|------|
| **0** | You | Audit code | 15-30m | E2E_DEEP_AUDIT_CHECKLIST.md |
| **1** | Auto | Prerequisites | < 1m | — |
| **2** | Auto | Display skill | < 1m | — |
| **3** | AI + You | Generate tests | 10-20m | — |
| **5** | Auto | Verify quality | < 1m | — |
| **6** | Auto | Type check | < 1m | — |
| **7** | Auto | Run tests | 2-5m | — |
| **8** | You | Audit tests | 15-30m | E2E_PIPELINE_AUDIT.md |
| **TOTAL** | — | — | **60-90m per feature** | — |

---

## Real Example: Testing a Dashboard

**Phase 0 (30m):**
```
✓ Route: /dashboard (protected, requires auth)
✓ Component: pages/dashboard/page.tsx
✓ API: GET /api/v1/listings
✓ Flow: Login → Redirect → Load listings → Display table
✓ Errors: 401 (not logged in), 403 (not advertiser), 500 (API error)
✓ Edge case: 0 listings (show empty state)
```

**Phase 1-2 (2m):** Prerequisites check, display skill

**Phase 3 (15m):**
```
Step 3: Planner explores /dashboard, creates test plan
  - Happy path: login → dashboard → see listings
  - Error: 401 redirect to login
  - Edge case: empty state message

Step 4: Generator creates tests + DashboardPage POM
  - Test 1: Dashboard loads with greeting
  - Test 2: Can edit listing
  - Test 3: Shows error when API fails
```

**Phase 5-7 (5m):**
```
Step 5: Code quality check → ✓ Passed
Step 6: Type check → ✓ Passed
Step 7: Test execution → ✓ All 3 tests passed
```

**Phase 8 (20m):**
```
✓ Assertion "welcome" matches actual output
✓ Test data is valid email format
✓ Setup creates authenticated user
✓ Cleanup clears JWT
✓ No ghost features
✓ Tests pass in random order
```

**Total: ~75 minutes for complete, audited E2E test coverage**

---

## Next Steps

1. **Install:** `bash install.sh` (one time)
2. **Read Phase 0:** `cat docs/E2E_DEEP_AUDIT_CHECKLIST.md`
3. **Document feature:** (15-30m)
4. **Run pipeline:** `./scripts/phase3-pipeline.sh "feature" "/route"`
5. **Follow prompts:** (copy/paste to Claude)
6. **Read Phase 8:** `cat docs/E2E_PIPELINE_AUDIT.md`
7. **Verify tests:** (15-30m)
8. **Commit:** `git add frontend/e2e/ && git commit -m "feat(e2e): ..."`

---

**Questions?** Read the specific phase guide (E2E_DEEP_AUDIT_CHECKLIST.md, E2E_PIPELINE_AUDIT.md, or E2E_SEMANTIC_LOCATORS.md) for that part of the workflow.
