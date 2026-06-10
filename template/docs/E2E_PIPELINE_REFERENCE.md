# E2E Testing Pipeline Reference

**A visual guide to the 8-step E2E test generation pipeline.**

This document clarifies the pipeline structure and naming to prevent confusion about "phases" vs "steps."

---

## Quick Reference: The 8 Steps

| Step | Name | Who? | Input | Output | Time |
|------|------|------|-------|--------|------|
| **0** | Codebase Audit | You | App code | Understanding doc | 30m |
| **1** | Check Setup | System | Dependencies | ✅ Ready | 1m |
| **2** | Show Patterns | System | Skill | Documentation | 2m |
| **3** | Planner Agent | AI | Audit + App | Test plan | 5-10m |
| **4** | Generator Agent | AI | Test plan | Test code | 10-15m |
| **5** | Quality Check | System | Code | Pass/Fail | 1m |
| **6** | Type Check | System | Code | Pass/Fail | 1m |
| **7** | Test Execution | System | Tests | Results | 1-5m |
| **8** | Test Audit | You | Test code | Confidence ✅ | 15-20m |

**Total Time:** 2-3 hours per feature (first time), 30-45 minutes (with MemoryKit patterns)

---

## Visual Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    BEFORE STARTING                              │
│  Phase -1: Production-Readiness Check                           │
│  (Is code production-ready? Any mock-heavy paths?)              │
│  👤 You read: docs/E2E_PRODUCTION_READINESS.md                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                        STEP 0                                   │
│  CODEBASE AUDIT (Phase 0 Manual)                               │
│  Read actual routes, components, APIs, edge cases              │
│  👤 You read: docs/E2E_DEEP_AUDIT_CHECKLIST.md                 │
│  📋 Output: Understanding doc (routes, flows, edge cases)      │
│  ⏱ Time: 30 minutes                                            │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                  STEPS 1-2: SETUP                               │
│  Step 1: Prerequisites Check ✓                                 │
│  Step 2: Display Patterns & Skill                             │
│  🤖 System verifies Node.js, npm, Playwright                   │
│  📚 System shows semantic locators + test patterns             │
│  ⏱ Time: 3 minutes                                             │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│              STEPS 3-4: AI CODE GENERATION                      │
│              (Phase 2 AI-Assisted)                              │
│                                                                 │
│  Step 3: PLANNER AGENT                                        │
│  🤖 AI explores your app                                       │
│  📖 Reads actual routes, components, APIs                      │
│  📋 Output: Test plan (happy path + edge cases)               │
│  ⏱ Time: 5-10 minutes                                          │
│                                                                 │
│  👤 You: Copy prompt → Paste into Claude → Copy result back   │
│                                                                 │
│                            ↓                                    │
│                                                                 │
│  Step 4: GENERATOR AGENT                                      │
│  🤖 AI creates test code                                       │
│  ✍️  Writes Playwright specs + POM classes                     │
│  🔍 Verifies code matches actual implementation               │
│  📋 Output: Complete test file + Page Object Model            │
│  ⏱ Time: 10-15 minutes                                         │
│                                                                 │
│  👤 You: Copy prompt → Paste into Claude → Copy result back   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│          STEPS 5-7: VERIFICATION & EXECUTION                   │
│          (Phase 3 Verification)                                │
│                                                                 │
│  Step 5: CODE QUALITY CHECK                                   │
│  ✓ Semantic locators (getByRole, not testids)                 │
│  ✓ Fixtures used (not hardcoded login)                        │
│  ✓ Proper cleanup (afterEach hooks)                           │
│  ✓ UUID test data (not Date.now())                            │
│  ✓ Explicit timeouts                                          │
│  ⏱ Time: 1 minute                                             │
│                                                                 │
│                            ↓                                    │
│                                                                 │
│  Step 6: TYPESCRIPT TYPE CHECK                                │
│  🔍 Compile TypeScript: npx tsc --noEmit                      │
│  ✓ No type errors                                             │
│  ⏱ Time: 1 minute                                             │
│                                                                 │
│                            ↓                                    │
│                                                                 │
│  Step 7: TEST EXECUTION                                       │
│  🧪 Run: npm run test:e2e:local                               │
│  ✓ All tests pass (or show failures)                          │
│  📺 View: npx playwright show-report                           │
│  ⏱ Time: 1-5 minutes                                          │
│                                                                 │
│  If tests fail:                                               │
│  → Copy error to Claude (Healer Agent)                        │
│  → AI diagnoses root cause                                    │
│  → Apply fix, re-run Step 7                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                       STEP 8                                    │
│  TEST AUDIT (Phase 8 Manual)                                   │
│  Verify tests match actual code                                │
│  👤 You read: docs/E2E_PIPELINE_AUDIT.md                      │
│  ✓ Each assertion matches actual code                         │
│  ✓ Test data matches real schemas                             │
│  ✓ Edge cases are covered                                     │
│  ✓ No "ghost" features (testing things that don't exist)      │
│  ⏱ Time: 15-20 minutes                                        │
│                                                                 │
│  If issues found:                                             │
│  → Fix in test code                                           │
│  → Re-run Step 7                                              │
│  → Re-audit                                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│                      COMPLETE ✅                                │
│  git add frontend/e2e/                                         │
│  git commit -m "feat(e2e): Add feature tests"                 │
│  PR → Review → Merge                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step Details

### Step 0: Codebase Audit (Phase 0 - Manual by You)

**What you do:**
Read `docs/E2E_DEEP_AUDIT_CHECKLIST.md` and document:
- What routes exist (and their handlers)
- What components exist (and their UI text)
- What APIs exist (and their response structure)
- What user workflows exist
- What edge cases and error scenarios exist

**Why this matters:**
- AI needs to know what actually exists (not assume)
- Prevents testing imaginary features
- Provides code references for test generation

**Output:** Understanding document you'll share with AI

**Time:** 30 minutes (first feature), 10 minutes (subsequent)

---

### Step 1: Prerequisites Check

**What the system does:**
```bash
✓ Node.js 18+ installed?
✓ npm 9+ installed?
✓ @playwright/test installed?
✓ Frontend running on localhost:3000?
```

**If something fails:**
Install missing dependencies and re-run

**Time:** 1 minute

---

### Step 2: Display Patterns & Skill

**What the system does:**
Shows you:
- Semantic locator patterns (getByRole, getByLabel, getByText)
- Fixture patterns (loginAsAdvertiser, cleanup)
- Test organization patterns (describe, grouped assertions)
- Example test file

**Why this matters:**
Ensures you and AI are aligned on patterns before generation

**Time:** 2 minutes

---

### Step 3: Planner Agent (AI-Assisted)

**What the AI does:**
1. **Reads your codebase understanding** (from Step 0)
2. **Reads actual routes** in your app (verifies they exist)
3. **Reads actual components** (documents UI text exactly)
4. **Reads actual APIs** (copies response structure from code)
5. **Explores your running app** (via Playwright MCP if available)
6. **Creates a test plan** with:
   - Happy path flows
   - Error scenarios
   - Edge cases (with code references)

**What you do:**
```bash
# 1. Script prints a prompt:
# "Copy the prompt below and paste into Cursor/Claude..."

# 2. You copy the prompt

# 3. You open Cursor/Claude and paste the prompt

# 4. Let the AI explore and generate

# 5. Copy the test plan back to terminal
```

**Output:** Markdown test plan document

**Time:** 5-10 minutes (includes AI exploration + your copy/paste)

---

### Step 4: Generator Agent (AI-Assisted)

**What the AI does:**
1. **Reads the test plan** from Step 3
2. **Reads actual API response structures** (verifies contracts)
3. **Reads actual component code** (verifies selectors exist)
4. **Generates complete test code** with:
   - Playwright test specs (.spec.ts)
   - Page Object Model (POM) classes
   - Fixtures and cleanup
   - Code comments with file:line references
5. **Verifies code matches actual implementation** (stops if mismatches)

**What you do:**
```bash
# Same as Step 3:
# 1. Copy prompt from terminal
# 2. Paste into Cursor/Claude
# 3. Let AI generate
# 4. Copy result back
```

**Output:** Test files + POM classes (ready to run)

**Time:** 10-15 minutes

---

### Step 5: Code Quality Verification

**What the system checks:**

```typescript
// ✅ Uses semantic locators (NOT testids)
page.getByRole('button', { name: /submit/i })  ✓
page.locator('[data-testid="submit"]')          ✗

// ✅ Uses fixtures (NOT hardcoded login)
test('...', async ({ authenticatedPage }) => ...) ✓
test('...', async ({ page }) => { loginCode... }) ✗

// ✅ Has proper cleanup
test.afterEach(async ({ page }) => { await page.evaluate(...) }) ✓
// No cleanup ✗

// ✅ Uses UUID test data (NOT Date.now())
const email = `test-${uuid()}@example.com` ✓
const email = `test${Date.now()}@example.com` ✗

// ✅ Has explicit timeouts
await page.waitForSelector('[data-testid="loaded"]', { timeout: 5000 }) ✓
await page.waitForSelector('[data-testid="loaded"]') ✗
```

**If it fails:**
- System shows which checks failed
- Fix manually or ask Generator to fix
- Re-run this step

**Time:** 1 minute

---

### Step 6: TypeScript Type Check

**What the system does:**
```bash
npx tsc --noEmit
```

Verifies:
- No type errors
- All imports resolve
- Function signatures match

**If it fails:**
- System shows TypeScript errors
- Fix types in test code
- Re-run this step

**Time:** 1 minute

---

### Step 7: Test Execution

**What the system does:**
```bash
npm run test:e2e:local
```

Runs all tests in the generated file:
- ✅ All pass → Done!
- ❌ Some fail → Diagnose with Healer agent

**If tests fail:**
```bash
# 1. Read error output
# 2. Copy to Claude with this prompt:
#    "You are Healer Agent. Why did this test fail?
#     [Paste error output]
#     Suggest fixes. Return fixed code."
# 3. Get fix from AI
# 4. Update test file
# 5. Re-run this step
```

**View results:**
```bash
npx playwright show-report
# Opens HTML report with videos, traces, screenshots
```

**Time:** 1-5 minutes (or longer if debugging)

---

### Step 8: Test Audit (Phase 8 - Manual by You)

**What you do:**
Read `docs/E2E_PIPELINE_AUDIT.md` and for EACH test verify:

- [ ] **Assertion accuracy:** Does text/element actually exist?
- [ ] **Test data realism:** Does test data match actual schema?
- [ ] **Edge cases:** Are edge cases covered?
- [ ] **State transitions:** Are before/after states verified?
- [ ] **Cleanup:** Does cleanup run (via fixture)?
- [ ] **No ghost features:** Do all tested routes/APIs actually exist?

**Common issues found at this stage:**
- Assertion expects "You have 5 listings" but app displays "Listings (5)"
- Test assumes email validation allows "test@" but app requires domain
- Test checks for error message that app doesn't actually show

**How to fix:**
- Update test assertion to match actual code
- Update test data to match actual schema
- Re-run Step 7
- Re-audit Step 8

**Time:** 15-20 minutes per test file

---

## Timing Expectations

### First Feature
```
Step 0 (Audit):     30 min
Step 1-2 (Setup):    3 min
Step 3 (Planner):   10 min
Step 4 (Generator): 15 min
Step 5-7 (Verify):   5 min
Step 8 (Audit):     20 min
─────────────────────────
TOTAL:              83 min (1.5 hours)
```

### Second Feature (with MemoryKit)
```
Step 0 (Audit):     15 min  (faster, familiar patterns)
Step 1-2 (Setup):    3 min  (cached)
Step 3 (Planner):    7 min  (retrieves prior patterns)
Step 4 (Generator):  8 min  (reuses proven patterns)
Step 5-7 (Verify):   3 min  (fewer issues)
Step 8 (Audit):     15 min  (familiar patterns)
─────────────────────────
TOTAL:              51 min (0.85 hours)
```

### Subsequent Features (with MemoryKit)
```
Each feature: 30-45 minutes (reusing established patterns)
```

---

## Key Terminology (Clarified)

### "Phase" vs "Step"

**This pipeline is called "Phase 3 Automated Pipeline"** in the context of the broader E2E system:
- **Phase -1** — Production-readiness check (before pipeline starts)
- **Phase 0** — Codebase audit (Step 0 in pipeline)
- **Phase 1** — Setup (Steps 1-2 in pipeline)
- **Phase 2** — AI generation (Steps 3-4 in pipeline)
- **Phase 3** — Verification (Steps 5-7 in pipeline)
- **Phase 8** — Test audit (Step 8 in pipeline)

To avoid confusion, we call them "Steps" within the pipeline itself:
- **Step 0** = Phase 0 (audit)
- **Step 3** = Phase 2, Part 1 (Planner)
- **Step 4** = Phase 2, Part 2 (Generator)
- **Step 5-7** = Phase 3 (verification)
- **Step 8** = Phase 8 (test audit)

### Manual vs Automated

| Step | Who | Type |
|------|-----|------|
| 0, 8 | You | Manual (you read checklist) |
| 1, 2, 5, 6, 7 | System | Automated (system runs checks) |
| 3, 4 | AI | AI-Assisted (you guide AI) |

---

## When Things Go Wrong

### Test fails in Step 7
```
→ This is GOOD. Better to fail here than in production.
→ Use Healer agent to diagnose
→ Fix and re-run Step 7
→ Re-audit Step 8
```

### Code quality check fails in Step 5
```
→ Fix the specific issue (use testid → getByRole)
→ Re-run Step 5
→ Usually quick fix (1-2 minutes)
```

### Assertion wrong in Step 8 audit
```
→ Update assertion to match actual code
→ Re-run Step 7
→ Re-audit Step 8
```

---

## Full Pipeline Command

```bash
# Run the entire pipeline for a feature:
./scripts/phase3-pipeline.sh "feature-name" "/page/path"

# Example:
./scripts/phase3-pipeline.sh "advertiser-dashboard" "/painel/dashboard"
```

The script automates Steps 1-7 (you copy/paste for 3-4).  
You manually handle Steps 0 and 8.

---

## Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| **"Element not found"** | Re-audit Step 8: verify element actually exists in code |
| **"Timeout waiting for element"** | Verify explicit wait in test; may need to increase timeout |
| **"Assertion failed"** | Re-audit Step 8: verify assertion matches actual code output |
| **"Type errors"** | Fix in test code; re-run Step 6 |
| **"Test passes locally but fails in CI"** | Check environment-specific timeouts in playwright.config.ts |

---

## Related Documentation

- **Before starting:** Read `docs/E2E_PRODUCTION_READINESS.md` (Phase -1)
- **Step 0:** Read `docs/E2E_DEEP_AUDIT_CHECKLIST.md`
- **Steps 3-4:** Reference `docs/E2E_SEMANTIC_LOCATORS.md` and `E2E_EXAMPLES.md`
- **Step 8:** Read `docs/E2E_PIPELINE_AUDIT.md`
- **When tests fail:** Use Healer agent (see Step 7 instructions)
- **General reference:** See `PHASE_3_AUTOMATED_PIPELINE.md` (longer version)

---

**Status:** Ready to reference  
**Last Updated:** 2026-06-10
