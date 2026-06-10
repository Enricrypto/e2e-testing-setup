# E2E Testing Bootstrap Setup

**A complete, opinionated E2E testing system that can be bootstrapped into any Next.js/React project in minutes.**

This repository contains the entire E2E testing infrastructure: working code, documentation, automation scripts, and proven workflows. It's designed to be cloned into any project and immediately functional.

---

## Table of Contents

- [What This Is](#-what-this-is)
- [Quick Start](#-quick-start-60-seconds)
- [Docker Setup](#-docker-setup-backend--database)
- [MemoryKit Integration](#-memorykit-integration-compounds-knowledge)
- [Core Principles](#-how-this-system-works)
- [The 9-Step Pipeline](#-architecture-the-9-step-pipeline)
- [The AI Agents](#-the-ai-agents)
- [File Structure](#-file-structure)
- [Real Example](#-real-example-testing-a-dashboard)
- [How to Use](#-how-to-use-this-system)
- [Context Documents](#-the-context-documents)
- [Key Concepts](#-key-concepts)
- [Common Mistakes](#️-common-mistakes)
- [Troubleshooting](#-troubleshooting)
- [Next Steps](#-next-steps)
- [License & Support](#-license--attribution)

---

## 🎯 What This Is

This is **NOT just a skill or guide**. This is a **complete working system** that includes:

- ✅ **Working code patterns** (Playwright config, fixtures, POM structure, test data factories)
- ✅ **Context documents** (Deep audit checklists, phase guides, workflow docs)
- ✅ **Automation script** (`phase3-pipeline.sh` - orchestrates the entire testing flow)
- ✅ **Setup installer** (One-command bootstrap into your project)
- ✅ **Examples** (Complete test examples following all best practices)
- ✅ **This README** (Everything you need to understand how it works)

---

## 🚀 Quick Start (60 seconds)

```bash
# In your project root (where package.json is)
bash <(curl -s https://raw.githubusercontent.com/youruser/e2e-testing-setup/main/install.sh)

# Follow prompts, then:
cat docs/E2E_DEEP_AUDIT_CHECKLIST.md
./scripts/phase3-pipeline.sh "my-feature" "/page/path"
```

After install, you'll have:
```
your-project/
├── frontend/e2e/              # Complete E2E structure
├── docs/                      # ALL documentation
├── scripts/phase3-pipeline.sh # The orchestrator
└── package.json               # E2E scripts added
```

---

## 🐳 Docker Setup (Backend + Database)

This system is optimized for **Docker + Local Tests**:
- Backend API + Database run in Docker containers
- E2E tests run locally for fast iteration and debugging
- Perfectly mimics production environment

### Quick Start with Docker

```bash
# 1. Start backend + database in Docker
docker-compose up

# 2. Start frontend dev server (new terminal)
npm run dev

# 3. Run E2E tests locally (new terminal)
npm run test:e2e:local
```

### Why Docker?

| Component | Where | Why |
|-----------|-------|-----|
| **Frontend Dev Server** | Local | Hot reload, instant feedback |
| **E2E Tests** | Local | 10x faster, see output immediately, easy debugging |
| **Backend + Database** | Docker | Production-like, isolated, easy reset |

**Result:** Tests run in ~30 seconds with production-like backend.

**For detailed setup:** Read `docs/E2E_DOCKER_SETUP.md` after installation.

---

## 🧠 MemoryKit Integration (Compounds Knowledge)

This system includes **MemoryKit** integration for autonomous learning across E2E features.

### What This Means

Each time you run the pipeline:
1. **Planner** retrieves prior test patterns for similar features
2. **Generator** learns from prior test patterns and reuses them
3. **Healer** uses prior failure patterns to diagnose issues faster
4. **Consolidator** extracts learnings after tests merge

### Knowledge Compounding

```
Feature 1: Dashboard listing page
  Time: 40 minutes (baseline)
  Learnings stored: JWT cleanup timing, table pagination patterns

Feature 2: Similar admin dashboard
  Time: 35 minutes (5% faster, retrieved JWT pattern)

Feature 5: Another dashboard variant
  Time: 25 minutes (35% faster, multiple patterns consolidated)

Feature 10: Another dashboard page
  Time: 24 minutes (40% faster, full knowledge compounding)
```

### MemoryKit Setup

MemoryKit is optional but strongly recommended. Without it, each feature starts from scratch.

**To enable:**
1. Verify MemoryKit MCP is installed and running
   ```bash
   # MemoryKit should be available in Claude Code
   # If not installed, follow: https://github.com/antoniorapozo/memorykit-mcp
   ```

2. When you run the pipeline, agents will automatically:
   - Retrieve prior patterns at start
   - Store new learnings after completion

No additional configuration needed—the pipeline automatically uses MemoryKit if available.

---

## 📋 How This System Works

### The Three Core Principles

1. **Codebase-First**: Never test imaginary flows. Understand what exists.
2. **Deep Audit**: Two mandatory audit phases (before and after test generation).
3. **AI-Assisted**: AI generates tests, but YOU verify and audit them.

### The Complete Workflow

```
Developer starts → Reads Global Skill
                    ↓
        Skill activates bootstrap
                    ↓
        Install copies system into project
                    ↓
        Developer does Phase 1 Audit
        (Understand actual codebase flows)
                    ↓
        Developer runs Phase 3 Pipeline
        (AI generates tests with human guidance)
                    ↓
        Developer does Phase 2 Audit
        (Verify tests match actual code)
                    ↓
        Tests committed, feature complete
```

---

## 🔍 Code-Reading Enforcement

This system enforces **actual code reading** instead of assumptions:

### Why Code Reading Matters

```
❌ ASSUMPTION-BASED (fails):
  Planner: "User clicks Save button"
  Generator: "API returns { success: true }"
  Tests pass locally
  Production: API structure changed, test caught nothing

✅ CODE-READING BASED (works):
  Planner: Reads component code → finds exact button text "Create New"
  Generator: Reads API code → finds response { listings[], total_count }
  Tests verify actual code behavior
  Production: Changes caught because tests match reality
```

### What This Means for You

- **Planner reads code** before creating test plans (routes, components, APIs)
- **Generator verifies code** before generating tests (responses, selectors, structure)
- **Every test assertion** references actual code
- **False assumptions caught early** (not in CI/production)

**For details:** Read `docs/E2E_CODE_READING_GUIDE.md` after installation.

---

## 🏗️ Architecture: The 9-Step Pipeline

This system runs through **9 automated steps** (including code-reading enforcement). Here's what happens at each:

### Phase -1: Production-Readiness (Validation)

**Step -1: PRODUCTION-READINESS CHECK** 🔍

**What happens:**
- System verifies code is production-ready (not mock-heavy)
- Checks API endpoints use real data
- Checks frontend components don't have dev overrides
- Ensures test data matches actual validation rules

**Why:** Testing mocks catches nothing. False coverage is worse than no coverage.

**Output:** Confirmation that code is ready for E2E testing

---

### Phase 0: Pre-Generation (Manual by Developer)

**Step 0: DEEP CODEBASE AUDIT** 🔍

**What you do:**
- Read `docs/E2E_DEEP_AUDIT_CHECKLIST.md`
- Map actual routes, pages, components
- Document API endpoints and contracts
- Identify edge cases and error scenarios
- List all preconditions and success messages

**Why:** AI needs to understand what actually exists in your code. Without this, it generates tests for imaginary features.

**Output:** A documented understanding of your feature (shared with AI in next step)

---

### Phase 1: Skill & Prerequisites

**Step 1: Prerequisites Check** ✓

**What happens:**
- System verifies `npm` is installed
- Checks app is running on `localhost:3000`
- Confirms E2E dependencies are available

**Step 2: Display E2E Skill** 📖

**What happens:**
- Shows this README
- Displays semantic locator patterns
- Shows fixture examples
- Explains test structure (Arrange → Act → Assert)

---

### Phase 2: AI-Assisted Test Generation

**Step 3: Planner Agent** (Exploration)

**What the AI does:**
```
INPUT:  Your codebase understanding (Phase 0 output)
PROCESS: Explores your app, maps actual user flows
OUTPUT: Test plan document
        (Happy paths, error scenarios, edge cases)
```

**Your role:**
1. Copy the prompt from terminal
2. Paste into Cursor/Claude chat
3. Run the Planner agent (read instructions in prompt)
4. Copy the test plan back to terminal

**Example output:**
```
# Test Plan: Advertiser Dashboard

## Happy Path
1. User logs in with valid credentials
2. Redirects to /painel/dashboard
3. Dashboard loads with user greeting
4. Listings table shows all listings
5. Can click edit on any listing

## Error Scenarios
- 401 Unauthorized → redirect to login
- Empty listings → show "No listings yet" message
- API timeout → show retry button

## Edge Cases
- User with 0 listings (empty state)
- Concurrent edit (conflict error)
- Stale JWT token (auto-logout)
```

**Step 4: Generator Agent** (Code Creation)

**What the AI does:**
```
INPUT:  Test plan from Step 3
        Your codebase structure
        Semantic locator patterns (from skill)
OUTPUT: Complete test code
        (Playwright specs, POM classes)
```

**Your role:**
1. Copy the updated prompt (includes test plan)
2. Paste into Cursor/Claude chat
3. Run the Generator agent
4. Copy the generated code back to terminal

**Example output:**
```typescript
import { test, expect } from '../fixtures'
import { AdvertiserDashboardPage } from '../../pom/AdvertiserDashboardPage'

test('AC1: Dashboard loads and displays user greeting', async ({ page }) => {
  // Arrange
  const dashboard = new AdvertiserDashboardPage(page)
  
  // Act
  await dashboard.goTo()
  
  // Assert
  await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible()
})
```

---

### Phase 3: Verification & Execution

**Step 5: Code Quality Verification** ✓

**What the system checks:**
- ✅ Uses semantic locators (getByRole, getByLabel, getByText — NOT testids)
- ✅ Uses fixtures (loginAsAdvertiser, cleanup)
- ✅ Has proper cleanup (test.afterEach)
- ✅ Uses UUID test data (not Date.now())
- ✅ Has explicit timeouts

**If checks fail:**
- System shows which checks failed
- You can either fix manually or ask Generator to fix

**Step 6: Type Checking** ✓

**What happens:**
- Runs `npx tsc --noEmit`
- Verifies TypeScript compilation
- Fails if types don't match

**Step 7: Test Execution** 🧪

**What happens:**
- Runs `npm run test:e2e:local`
- Executes all tests in the test file
- Reports PASS or FAIL with detailed output

**If tests fail:**
- System shows error output
- You can ask Healer agent to diagnose and fix

---

### Phase 8: Post-Generation (Manual by Developer)

**Step 8: DEEP TEST AUDIT** 🔍

**What you do:**
- Read `docs/E2E_PIPELINE_AUDIT.md`
- For EACH test, verify assertions match actual code
- Check test data matches real schemas
- Confirm edge cases are covered
- Validate no "ghost" features

**Why:** Tests that don't match code catch nothing. This audit prevents false coverage.

**Example verification:**
```typescript
❌ BROKEN:
// Test expects text "You have X listings"
await expect(page.getByText(/you have \d+ listings/i)).toBeVisible()

// But app actually displays "Listings (5)"
// FAIL in Phase 8: Fix assertion to match actual output

✅ FIXED:
await expect(page.getByText(/listings \(\d+\)/i)).toBeVisible()
```

---

## 🤖 The AI Agents

This system uses **four AI agents** that work together with MemoryKit:

### Agent 1: Planner (Exploration + Memory-Aware + Code-Reading)

**What it does:**
- **[Phase 1 Memory]** Retrieves prior test patterns for similar features
- **[Phase 3 Code-Reading]** Reads router, component, and API files (mandatory)
- Creates code-reading report with file:line references
- Reads your codebase understanding (Phase 0)
- Explores your app via Playwright MCP
- Maps actual user flows (verified against code)
- Documents happy paths, errors, edge cases
- **[Phase 1 Memory]** Stores test plan findings to memory

**When it runs:** Step 3 of pipeline

**Code-Reading Enforcement:**
- Reads actual route handler (verifies route exists, checks auth)
- Reads actual component (lists UI elements with exact text)
- Reads actual API endpoint (copies response structure from code)
- Reports if assumptions don't match code (stops early, prevents false tests)

**Memory Integration:**
- Retrieves context: `mcp__memorykit__retrieve_context("e2e: feature-name")`
- Surfaces prior patterns that succeeded or failed
- Stores test plan to memory for future reference

**Prompt it receives:**
```
You are the Planner Agent. Your job is to explore the app
and create a test plan.

[Your Phase 0 codebase understanding]
[Page path to test: /painel/dashboard]
[App running at: http://localhost:3000]

Explore this page, identify flows, document test scenarios.
Return: Markdown test plan with happy paths, errors, edge cases.
```

**How you use it:**
1. Copy prompt from terminal
2. Paste into Cursor/Claude
3. Let it explore your app
4. Copy the test plan back

### Agent 2: Generator (Code Creation + Memory-Aware + Code-Verification)

**What it does:**
- **[Phase 2 Memory]** Retrieves prior test patterns (auth flows, table pagination, etc.)
- **[Phase 3 Code-Verification]** Verifies API contracts against actual code
- **[Phase 3 Code-Verification]** Verifies selectors match actual component code
- Reads the test plan from Planner
- Generates Playwright test code with code references
- Creates POM (Page Object Model) classes
- **Reuses proven patterns** from memory
- **[Phase 2 Memory]** Stores new patterns to memory
- Follows all best practices

**When it runs:** Step 4 of pipeline

**Code-Verification Enforcement:**
- Reads actual endpoint handler (verifies response structure, error codes)
- Reads actual component JSX (verifies selectors match exact text/roles)
- Reads validation rules (verifies test data matches schema)
- Reports mismatches (stops before generating false tests)
- Includes code references in test comments (file:line for every assertion)

**Memory Integration:**
- Retrieves context: `mcp__memorykit__retrieve_context("e2e: test-patterns")`
- Surfaces "Patterns Recommended for Reuse", "Patterns to Watch", "Patterns to Avoid"
- Applies recommended patterns to generated code
- Stores generated patterns for future features

**Prompt it receives:**
```
You are the Generator Agent. Create Playwright tests.

[Test plan from Planner]
[Semantic locator patterns]
[Fixture patterns (loginAsAdvertiser, cleanup)]
[UUID test data patterns]

Generate:
1. Complete test file (.spec.ts)
2. POM class (PageObjectModel)

STRICT requirements:
- Use getByRole > getByLabel > getByText (semantic locators)
- Use fixtures for auth/setup
- Include cleanup (test.afterEach)
- Use UUID test data
- Explicit timeouts (from config)
```

**How you use it:**
1. Copy updated prompt (with test plan embedded)
2. Paste into Cursor/Claude
3. Let it generate code
4. Copy the generated code back

### Agent 3: Healer (Failure Diagnosis + Memory-Aware)

**What it does:**
- **[Phase 3 Memory]** Retrieves prior failure patterns and solutions
- Reads test failures
- Diagnoses why tests fail (with code reading, not assumptions)
- Suggests fixes based on prior solutions
- Explains the root cause
- **Autonomous iteration** — optionally attempts up to 3 fixes before escalating

**When it runs:** Only if Step 7 (test execution) fails

**Memory Integration:**
- Retrieves context: `mcp__memorykit__retrieve_context("e2e: failures")`
- Surfaces prior failure patterns and how they were solved
- Applies solutions from memory first

**How you use it:**
1. Copy the test failure output
2. Paste into Cursor/Claude chat
3. Paste this prompt:
   ```
   You are the Healer Agent. Diagnose why this test fails:
   [Paste error output]
   
   Suggest fixes. Root cause analysis. Return fixed code.
   ```
4. Get the fix, update the test, re-run

### Agent 4: Consolidator (Post-Merge Learning)

**What it does:**
- **[Phase 4 Memory]** Runs after PR is merged and tests pass for 24+ hours
- Extracts patterns that succeeded
- Documents patterns to watch
- Identifies patterns to avoid
- Computes time metrics for similar features
- Stores comprehensive learnings for future features

**When it runs:** After E2E tests are merged and verified in production/staging

**Output:** Consolidation report with:
- Metrics (time per agent, total iterations, confidence levels)
- Patterns that succeeded (100% success rate)
- Patterns to watch (needed debugging)
- Patterns to avoid (failed)
- Time estimates for next similar feature
- Risk adjustments

**Memory Storage:**
```
mcp__memorykit__store_memory(
  title: "E2E Consolidation: Feature Name",
  content: "[consolidation report]",
  tags: ["e2e", "consolidation", "feature-name"],
  scope: "project"
)
```

---

## 📂 File Structure

### This Bootstrap Package

```
e2e-testing-setup/                # Bootstrap package (you are here)
├── install.sh                     # Installer (copies template → projects)
├── README.md                      # This file
├── QUICK_START.md                 # 5-minute guide
├── SETUP_GUIDE.md                 # Installation help
├── PACKAGE_STRUCTURE.md           # Architecture overview
│
└── template/                      # Files copied into projects
    ├── frontend/e2e/
    │   ├── playwright.config.ts   # Config (environment-aware + Docker support)
    │   ├── tests/                 # Where tests go
    │   ├── pom/                   # Page Object Models
    │   └── utils/                 # Test utilities
    │
    ├── docs/                      # Documentation (8 essential guides)
    │   ├── E2E_TEST_SCOPE_GUARDRAILS.md      # Keep tests simple (max 15 lines, 1 assertion)
    │   ├── E2E_CODE_READING_GUIDE.md         # Code-reading enforcement for agents
    │   ├── E2E_DOCKER_SETUP.md               # Docker + Local E2E guide
    │   ├── E2E_PRODUCTION_READINESS.md       # Phase -1: validate code first
    │   ├── E2E_DEEP_AUDIT_CHECKLIST.md       # Phase 0: before pipeline
    │   ├── E2E_PIPELINE_AUDIT.md             # Phase 8: after pipeline
    │   ├── PHASE_3_AUTOMATED_PIPELINE.md     # Reference: complete flow
    │   └── E2E_SEMANTIC_LOCATORS.md          # Reference: locator patterns
    │
    ├── docker-compose.yml         # Docker Compose for backend + database
    ├── backend-Dockerfile.example # Example backend Dockerfile
    │
    └── scripts/
        └── phase3-pipeline.sh     # Orchestrator script
```

### After Installation in Your Project

When you run `install.sh`, it copies `template/` into your project:

```
your-project/
├── frontend/e2e/
│   ├── playwright.config.ts           # Playwright config (Docker + env-aware)
│   ├── tests/                         # Test files directory
│   │   └── 01-dashboard/             # Example: dashboard feature
│   │       ├── dashboard.spec.ts      # Generated by pipeline
│   │       └── README.md
│   │
│   ├── pom/                           # Page Object Models
│   │   └── DashboardPage.ts           # Generated by pipeline
│   │
│   └── utils/                         # Utilities
│       └── test-data.ts
│
├── docs/                              # 👈 COPIED FROM TEMPLATE
│   ├── E2E_TEST_SCOPE_GUARDRAILS.md   # Keep tests simple and maintainable
│   ├── E2E_DOCKER_SETUP.md            # Docker + Local E2E best practices
│   ├── E2E_PRODUCTION_READINESS.md    # Phase -1: Validate code before tests
│   ├── E2E_DEEP_AUDIT_CHECKLIST.md    # Phase 0: Read BEFORE pipeline
│   ├── E2E_PIPELINE_AUDIT.md          # Phase 8: Read AFTER pipeline
│   ├── PHASE_3_AUTOMATED_PIPELINE.md  # Reference: How pipeline works
│   └── E2E_SEMANTIC_LOCATORS.md       # Reference: Locator patterns
│
├── docker-compose.yml                 # 👈 Docker setup (backend + database)
├── backend-Dockerfile.example         # 👈 Example Dockerfile for backend
│
└── scripts/
    └── phase3-pipeline.sh             # Run this for each feature
```

### Documentation Guide

| File | When to Read | What It Does |
|------|-------------|--------------|
| **E2E_TEST_SCOPE_GUARDRAILS.md** | **CRITICAL: Before each feature** | Enforces simple, maintainable tests. Max 15 lines, 1 assertion, 5 actions. Prevents complex tests. |
| **E2E_CODE_READING_GUIDE.md** | **Before Planner/Generator run** | How agents read code to avoid assumptions. Red flags, checklists, examples. Critical for accurate tests. |
| **E2E_DOCKER_SETUP.md** | **First time setup** | Complete Docker setup guide. How to run backend/database in Docker while tests run locally. Includes troubleshooting. |
| **E2E_PRODUCTION_READINESS.md** | **BEFORE Phase 0** | Validates code is production-ready (not mock-heavy). Checks APIs, components, test data. |
| **E2E_DEEP_AUDIT_CHECKLIST.md** | **BEFORE** running pipeline | Guides you to audit your codebase (Phase 0). Ensures AI understands real code. |
| **E2E_PIPELINE_AUDIT.md** | **AFTER** pipeline generates tests | Guides you to verify tests match actual code (Phase 8). Prevents false coverage. |
| **PHASE_3_AUTOMATED_PIPELINE.md** | Anytime (reference) | Explains the complete 9-step flow. Read when you want to understand what's happening. |
| **E2E_SEMANTIC_LOCATORS.md** | When writing/reviewing tests | Reference guide for Playwright locators. Best practices for finding elements. |

---

## 🔄 Real Example: Testing a Dashboard

### What You Do (Phase -1 - Production-Readiness)

**First, validate the code is production-ready:**
```bash
# Read E2E_PRODUCTION_READINESS.md checklist
- [ ] API endpoints use real database (not hardcoded)
- [ ] Frontend has no dev overrides (if isDev branches)
- [ ] Test data matches actual validation rules

# Confirm all checks pass before proceeding
```

### What You Do (Phase 0 - Audit)

```
Reading E2E_DEEP_AUDIT_CHECKLIST.md...

Routes:
  ✓ /painel/dashboard → AdvertiserDashboardPage
  ✓ Authenticated (JWT required)
  ✓ Role check (must be advertiser)

Components:
  ✓ Header (displays user name)
  ✓ Listing table (pagination, sorting)
  ✓ Empty state (when 0 listings)
  ✓ Error messages

API Endpoints:
  ✓ GET /api/v1/advertiser/listings
  ✓ Response: { listings: [], total_count, has_next }
  ✓ Errors: 401, 403, 500

Edge Cases:
  ✓ User with 0 listings (empty state)
  ✓ API timeout (>10s, show retry)
  ✓ Concurrent edit (conflict error)
  ✓ Stale JWT (401 redirect to login)
```

### What the Pipeline Does (Steps 1-7)

**You run:**
```bash
./scripts/phase3-pipeline.sh "advertiser-dashboard" "/painel/dashboard"
```

**Step 1-2:** System checks prerequisites, shows patterns  
**Step 3:** Planner explores app, creates test plan  
**Step 4:** Generator creates test code + POM class  
**Step 5:** Verifies code quality (semantic locators, cleanup)  
**Step 6:** TypeScript compilation check  
**Step 7:** Runs tests, all pass ✅

### What You Do (Phase 8 - Audit)

```
Reading E2E_PIPELINE_AUDIT.md...

For each test:
  ✓ Assertion accuracy: "Welcome, John" text exists? ✓
  ✓ Test data realism: Email format valid? ✓
  ✓ Edge cases covered: Empty state tested? ✓
  ✓ State transitions: Before/after verified? ✓
  ✓ Cleanup: JWT cleared after test? ✓
  ✓ No ghost features: All tested routes exist? ✓

All checks pass ✅
```

**You commit:**
```bash
git add frontend/e2e/tests/02-advertiser-dashboard/
git add frontend/e2e/pom/AdvertiserDashboardPage.ts
git commit -m "feat(e2e): Add advertiser dashboard tests (Phase 3 AI-generated, manually audited)"
```

---

## 🛠️ How to Use This System

### Setup (One-Time)

```bash
# 1. Bootstrap the system into your project
bash <(curl -s https://raw.githubusercontent.com/youruser/e2e-testing-setup/main/install.sh)

# 2. Verify installation
ls frontend/e2e/
ls docs/
ls docker-compose.yml

# 3. Configure Docker (if using backend in Docker)
# Read the Docker setup guide and create backend/Dockerfile
cat docs/E2E_DOCKER_SETUP.md

# 4. Start backend + database (Terminal 1)
docker-compose up

# 5. Start your frontend app (Terminal 2)
npm run dev
```

### For Each Feature

```bash
# Terminal 3 (while docker-compose and npm run dev are running)

# 0. (First time only) Verify Docker setup
# Make sure docker-compose up is running (terminal 1)
# Make sure npm run dev is running (terminal 2)
curl http://localhost:3001/health  # Backend should respond
curl http://localhost:3000         # Frontend should respond

# 1. Read Phase -1 (Production-Readiness Check)
cat docs/E2E_PRODUCTION_READINESS.md
# Verify code is production-ready (not mock-heavy)

# 2. Read Phase 0 audit checklist
cat docs/E2E_DEEP_AUDIT_CHECKLIST.md

# 3. Document your feature
# (What routes exist, what flows, what edge cases)

# 4. Run the pipeline
./scripts/phase3-pipeline.sh "feature-name" "/page/path"

# 5. When prompts appear:
#    - Copy prompt to Cursor/Claude chat
#    - Let AI explore/generate
#    - Copy results back to terminal

# 6. Read Phase 8 audit checklist
cat docs/E2E_PIPELINE_AUDIT.md

# 7. Verify each test
# (Do assertions match actual code? Are edge cases covered?)

# 8. Commit
git add frontend/e2e/
git commit -m "feat(e2e): Add feature tests"
```

---

## 📚 The Context Documents

This repo includes **4 essential markdown files**. Read them in order:

### 1. `E2E_DEEP_AUDIT_CHECKLIST.md` (Phase 0)

**When:** Before running pipeline  
**What:** Checklist to understand your codebase  
**Includes:**
- Routes & pages (what exists?)
- Components & state management
- API endpoints & contracts
- User flows & preconditions
- Edge cases & error scenarios
- Existing test patterns

**Goal:** AI understands what actually exists (prevents ghost features)

### 2. `PHASE_3_AUTOMATED_PIPELINE.md` (Reference)

**When:** Anytime (reference guide)  
**What:** Detailed explanation of all 8 steps  
**Includes:**
- What each step does
- Your role at each step
- Expected outputs
- Troubleshooting

**Goal:** Understand the complete flow

### 3. `E2E_SEMANTIC_LOCATORS.md` (Reference)

**When:** When writing/reviewing tests  
**What:** Semantic locator patterns and rules  
**Includes:**
- Locator hierarchy (getByRole > getByLabel > getByText)
- When to use each
- Examples for common elements
- What NOT to do (testids, CSS selectors)

**Goal:** Understand why semantic locators matter

### 4. `E2E_PIPELINE_AUDIT.md` (Phase 8)

**When:** After pipeline generates tests  
**What:** Checklist to verify tests match code  
**Includes:**
- Assertion accuracy check
- Test data realism
- Edge case coverage
- State transitions
- Cleanup verification
- "No ghost features" validation

**Goal:** Prevent false test coverage (tests that pass but don't test real code)

---

## 🎓 Key Concepts

### Semantic Locators (Why They Matter)

Tests that use CSS selectors or testids are **fragile** — they break when UI changes. Semantic locators use **actual user-facing elements**:

```typescript
❌ FRAGILE:
await page.click('[data-testid="submit-button"]')

✅ ROBUST:
await page.click(page.getByRole('button', { name: /submit/i }))
// Finds button by what user sees, not internal testid
```

**Locator priority:**
1. `getByRole` — What users see
2. `getByLabel` — Form labels
3. `getByText` — Visible text
4. `getByTestId` — Last resort (internal ID)
5. ❌ CSS selectors, XPath — Never use

### UUID Test Data (Why It Matters)

Tests that use `Date.now()` can collide if tests run in parallel. UUID-based data is globally unique:

```typescript
❌ COLLISION RISK:
const email = `test${Date.now()}@example.com`
// If 2 tests run same second: test1685567890@example.com (same email!)

✅ COLLISION-FREE:
const email = generateTestEmail()  // test-a1b2c3d4@example.com
// Uses UUID: 99.99% unique across any parallel execution
```

### Fixtures (Reusable Setup)

Instead of repeating login logic in every test, use fixtures:

```typescript
// Defined once in fixtures.ts
export const loginAsAdvertiser = async (context) => {
  // Create user, register, login, return { email, jwt }
}

// Used in every test
test('my test', async ({ page, loginAsAdvertiser }) => {
  const { email, jwt } = await loginAsAdvertiser()
  // Test now has authenticated user, ready to go
})
```

---

## ⚠️ Common Mistakes

### Mistake 1: Testing Imaginary Flows

```typescript
❌ WRONG:
test('user can update listing title', async ({ page }) => {
  // Assumption: there's an "edit title" field
  await page.fill('#title-edit', 'New Title')
})

// But when you run this:
// "Element with selector '#title-edit' not found"

✅ RIGHT:
// Phase 0: Check app actually has a title edit field
// Generate test only after confirming it exists
```

**Fix:** Do Phase 0 audit BEFORE running pipeline

### Mistake 2: Assertions That Don't Match Code

```typescript
❌ WRONG:
// Test expects: "You have 5 listings"
await expect(page.getByText(/you have \d+ listings/i)).toBeVisible()

// But app displays: "Listings (5)"
// Test passes locally? No, it fails.

✅ RIGHT:
// Phase 8: Verify assertions match actual app output
await expect(page.getByText(/listings \(\d+\)/i)).toBeVisible()
```

**Fix:** Do Phase 8 audit AFTER running pipeline

### Mistake 3: Using testids Instead of Semantic Locators

```typescript
❌ WRONG:
await page.click('[data-testid="submit-btn"]')

✅ RIGHT:
await page.click(page.getByRole('button', { name: /submit/i }))
```

**Fix:** System checks this in Step 5, but understand why

### Mistake 4: No Cleanup Between Tests

```typescript
❌ WRONG:
test('creates listing', async ({ page }) => {
  // Creates user, listing, etc.
  // No cleanup!
  // Next test sees this created data, test order matters
})

✅ RIGHT:
test('creates listing', async ({ page }) => {
  // Creates user, listing, etc.
  
  // Cleanup happens automatically (fixtures handle it)
  // Test.afterEach clears session, JWT, etc.
})
```

**Fix:** Fixtures provide cleanup, use them

---

## 🆘 Troubleshooting

### Problem: "Element not found" during test execution

**Likely cause:** Test assumes element exists that doesn't  
**Fix:** 
1. Check app actually has this element (Phase 0 audit)
2. Use correct semantic locator (check E2E_SEMANTIC_LOCATORS.md)
3. Check element is visible (not hidden by CSS)

### Problem: "Cannot find type 'uuid'"

**Likely cause:** UUID package not installed  
**Fix:** 
```bash
npm install uuid
npm install --save-dev @types/uuid
```

### Problem: "Tests pass locally but fail in CI"

**Likely cause:** Timeouts too short for CI environment  
**Fix:** Check playwright.config.ts has environment-specific timeouts:
```typescript
const timeoutConfig = {
  local: { actionTimeout: 5000 },    // Dev machine
  staging: { actionTimeout: 15000 }, // Slower server
  production: { actionTimeout: 25000 } // Cold starts
}
```

### Problem: "Test order matters, tests fail in random order"

**Likely cause:** No cleanup between tests  
**Fix:** Ensure fixtures have proper cleanup (test.afterEach)

---

## 📖 Next Steps

1. **Install this system:**
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/youruser/e2e-testing-setup/main/install.sh)
   ```

2. **Read Phase 0 audit:**
   ```bash
   cat docs/E2E_DEEP_AUDIT_CHECKLIST.md
   ```

3. **Document your first feature's flows:**
   - What routes exist
   - What components
   - What APIs
   - What edge cases

4. **Run the pipeline:**
   ```bash
   ./scripts/phase3-pipeline.sh "your-feature" "/your/page/path"
   ```

5. **Follow the prompts:**
   - Copy prompts to Cursor/Claude
   - Let AI explore and generate
   - Copy results back
   - System verifies, runs tests

6. **Audit the results:**
   ```bash
   cat docs/E2E_PIPELINE_AUDIT.md
   ```

7. **Commit:**
   ```bash
   git add frontend/e2e/
   git commit -m "feat(e2e): Add feature tests"
   ```

---

## 📚 Complete Documentation Index

This system includes **16 comprehensive guides** to help you at every stage:

### Getting Started

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **QUICK_START.md** | 5-minute overview | Immediately (fastest path) |
| **SETUP_GUIDE.md** | Installation & first run | Before installing |
| **PACKAGE_STRUCTURE.md** | How pieces fit together | Want to understand architecture |

### Before Testing

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **E2E_PRODUCTION_READINESS.md** | Phase -1: Validate code is ready | Before starting any tests |
| **E2E_DEEP_AUDIT_CHECKLIST.md** | Phase 0: Understand your feature | Before running pipeline |
| **E2E_CODE_READING_GUIDE.md** | How agents read code | Before Planner/Generator run |

### Test Generation Pipeline

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **E2E_PIPELINE_REFERENCE.md** | 8-step visual guide | Understand the pipeline flow |
| **PHASE_3_AUTOMATED_PIPELINE.md** | Detailed reference (longer) | Want deep dive into each step |
| **E2E_EXAMPLES.md** | 9 real working test examples | Learn by example (copy-paste) |

### After Testing

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **E2E_PIPELINE_AUDIT.md** | Phase 8: Verify tests match code | After pipeline generates tests |
| **E2E_SEMANTIC_LOCATORS.md** | Best practices for selectors | When reviewing/writing tests |

### Practical Guides

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **E2E_DOCKER_SETUP.md** | Run backend/DB in Docker | Setting up Docker + tests |
| **E2E_CI_CD_INTEGRATION.md** | GitHub Actions + CI/CD | Integrating tests in CI |
| **E2E_DEBUGGING.md** | Troubleshoot test failures | When tests fail or are flaky |
| **E2E_TEST_REPORTING.md** | View + analyze results | After tests run |
| **E2E_RATE_LIMITING.md** | Handle API rate limits | Tests failing due to rate limits |
| **E2E_MCP_INTEGRATION.md** | Optional Playwright MCP | Want agent exploration |

### Advanced Topics

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **E2E_ACCESSIBILITY_TESTING.md** | Test for a11y compliance | Writing accessible tests |
| **E2E_TEST_SCOPE_GUARDRAILS.md** | Keep tests simple & focused | Prevent complex tests |
| **E2E_MONOREPO_SETUP.md** | Multiple frontend apps | Using monorepo structure |

### Reference

| Guide | Purpose | Read When |
|-------|---------|-----------|
| **VERSIONS.md** | Version history & compatibility | Check if system is current |
| **UPDATE_GUIDE.md** | Upgrade between versions | Updating existing setup |
| **PRAGMATISM_GUARDRAILS.md** | Deduplication + pragmatism | Ensure quality tests |

### Package Helper

| File | Purpose |
|------|---------|
| **package.json.snippet** | Copy E2E scripts to package.json |

---

## 🎯 Reading Paths (Pick Your Path)

### Path 1: "I'm Starting from Scratch" (90 minutes)

1. **QUICK_START.md** (5 min) — Overview
2. **SETUP_GUIDE.md** (10 min) — Installation
3. **E2E_PRODUCTION_READINESS.md** (15 min) — Validate code
4. **E2E_DEEP_AUDIT_CHECKLIST.md** (20 min) — Audit your feature
5. **E2E_EXAMPLES.md** (20 min) — See working examples
6. **E2E_PIPELINE_REFERENCE.md** (10 min) — Understand flow
7. Run pipeline: `./scripts/phase3-pipeline.sh "feature" "/path"`

### Path 2: "I Have Existing E2E Tests" (60 minutes)

1. **README.md** (15 min) — Understand system
2. **E2E_PIPELINE_REFERENCE.md** (10 min) — See 8-step flow
3. **E2E_EXAMPLES.md** (20 min) — Compare to your tests
4. **E2E_SEMANTIC_LOCATORS.md** (10 min) — Verify locators
5. **PRAGMATISM_GUARDRAILS.md** (5 min) — Check test quality

### Path 3: "I'm Having Issues" (Varies)

**Tests are failing?**
→ Read E2E_DEBUGGING.md

**Flaky tests?**
→ Read E2E_RATE_LIMITING.md, then E2E_DEBUGGING.md

**Setup problems?**
→ Read SETUP_GUIDE.md troubleshooting

**CI/CD not working?**
→ Read E2E_CI_CD_INTEGRATION.md

**Accessibility concerns?**
→ Read E2E_ACCESSIBILITY_TESTING.md

**Have multiple apps?**
→ Read E2E_MONOREPO_SETUP.md

### Path 4: "I Want to Understand Everything" (4 hours)

Read **all** guides in order:
1. QUICK_START
2. README
3. SETUP_GUIDE
4. E2E_PRODUCTION_READINESS
5. E2E_DEEP_AUDIT_CHECKLIST
6. E2E_CODE_READING_GUIDE
7. E2E_PIPELINE_REFERENCE
8. PHASE_3_AUTOMATED_PIPELINE
9. E2E_EXAMPLES
10. E2E_SEMANTIC_LOCATORS
11. E2E_PIPELINE_AUDIT
12. E2E_DOCKER_SETUP
13. E2E_CI_CD_INTEGRATION
14. E2E_DEBUGGING
15. E2E_TEST_REPORTING
16. E2E_ACCESSIBILITY_TESTING
17. E2E_MONOREPO_SETUP
18. PRAGMATISM_GUARDRAILS
19. VERSIONS

---

## 📝 License & Attribution

This E2E testing system is a complete, production-ready setup based on:
- Playwright best practices (v1.40+)
- Semantic locator principles
- Phase 1/2 deep audit methodology
- AI-assisted test generation workflow

Use it in any project. Contribute improvements back.

---

## 📞 Support

**Questions about:**
- **Phase 0 audit** → Read `docs/E2E_DEEP_AUDIT_CHECKLIST.md`
- **Pipeline flow** → Read `docs/PHASE_3_AUTOMATED_PIPELINE.md`
- **Semantic locators** → Read `docs/E2E_SEMANTIC_LOCATORS.md`
- **Phase 8 audit** → Read `docs/E2E_PIPELINE_AUDIT.md`
- **Test failures** → Use Healer agent (instructions in pipeline output)

---

**Created:** 2026-06-05  
**System:** E2E Bootstrap Package v1.0  
**Status:** Production-ready
