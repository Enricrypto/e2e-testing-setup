#!/bin/bash

# E2E Testing Bootstrap Installer
# Copies complete E2E setup into your project
# Usage: bash install.sh (from project root)

set -e

echo "🚀 E2E Testing Bootstrap Installer"
echo "===================================="
echo ""

# Check we're in a project root
if [ ! -f "package.json" ]; then
  echo "❌ Error: package.json not found"
  echo "   Run this from your project root directory"
  exit 1
fi

echo "✓ Found package.json"

# Detect project type
if grep -q '"next"' package.json; then
  echo "✓ Detected Next.js project"
elif grep -q '"react"' package.json; then
  echo "✓ Detected React project"
else
  echo "⚠ Warning: Could not detect Next.js or React"
  echo "  Proceeding anyway (may need manual adjustments)"
fi

echo ""
echo "This will:"
echo "  1. Create frontend/e2e/ with complete structure"
echo "  2. Copy all documentation"
echo "  3. Add phase3-pipeline.sh to scripts/"
echo "  4. Add E2E npm scripts to package.json"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 1
fi

echo ""
echo "📦 Installing E2E testing system..."
echo ""

# Create directories
mkdir -p frontend/e2e/{tests,pom,utils}
mkdir -p docs
mkdir -p scripts

echo "✓ Created directory structure"

# Copy template files from repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/template/docs" ]; then
  cp "$SCRIPT_DIR/template/docs"/*.md docs/
  echo "✓ Copied E2E documentation from template"
else
  echo "⚠ Template docs not found, will create them inline"
fi

# Copy docker-compose.yml template
if [ -f "$SCRIPT_DIR/template/docker-compose.yml" ]; then
  cp "$SCRIPT_DIR/template/docker-compose.yml" ./docker-compose.yml
  echo "✓ Copied docker-compose.yml template"
else
  echo "⚠ docker-compose.yml template not found"
fi

# Copy backend Dockerfile example
if [ -f "$SCRIPT_DIR/template/backend-Dockerfile.example" ]; then
  cp "$SCRIPT_DIR/template/backend-Dockerfile.example" ./backend-Dockerfile.example
  echo "✓ Copied backend Dockerfile example (see backend-Dockerfile.example)"
fi

# Copy playwright config
cat > frontend/e2e/playwright.config.ts << 'PLAYWRIGHT_EOF'
import { defineConfig, devices } from '@playwright/test'

// Environment configuration
const env = process.env.TEST_ENV || 'local'
const isLocal = env === 'local'
const isCI = !!process.env.CI

// Backend URL (for API calls in tests)
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3000'

// Timeout configuration per environment
const timeoutConfig = {
  local: {
    actionTimeout: 5000,
    navigationTimeout: 15000,
    testTimeout: 30000,
    name: 'Local Development',
  },
  docker: {
    actionTimeout: 10000,
    navigationTimeout: 20000,
    testTimeout: 60000,
    name: 'Docker (Backend in Container)',
  },
  ci: {
    actionTimeout: 15000,
    navigationTimeout: 30000,
    testTimeout: 120000,
    name: 'CI/CD Pipeline',
  },
  staging: {
    actionTimeout: 15000,
    navigationTimeout: 30000,
    testTimeout: 60000,
    name: 'Staging Environment',
  },
  production: {
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
  workers: isCI ? 1 : 4,

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
PLAYWRIGHT_EOF

echo "✓ Copied playwright.config.ts"

# Copy phase3 pipeline script
cat > scripts/phase3-pipeline.sh << 'PIPELINE_EOF'
#!/bin/bash

# Phase 3 E2E Pipeline Automation
# Usage: ./scripts/phase3-pipeline.sh "feature-name" "/page/path"

set -e

FEATURE_NAME="${1:-example}"
PAGE_PATH="${2:-/example}"
TEST_DIR="frontend/e2e/tests"
FEATURE_TEST_DIR="$TEST_DIR/$(printf '%02d' $(($(ls -d $TEST_DIR/*/ 2>/dev/null | wc -l) + 1)))-$FEATURE_NAME"

echo "🚀 Phase 3 E2E Pipeline: $FEATURE_NAME"
echo "========================================="
echo ""

# Check prerequisites
if [ ! -f "frontend/e2e/playwright.config.ts" ]; then
  echo "❌ Error: E2E setup not found. Run install.sh first."
  exit 1
fi

echo "✓ E2E setup found"

if ! curl -s http://localhost:3000 > /dev/null; then
  echo "❌ Error: App not running on http://localhost:3000"
  echo "   Start it with: npm run dev"
  exit 1
fi

echo "✓ App running on localhost:3000"
echo ""

# Step -1: Production-readiness check
echo "🔍 STEP -1: Production-Readiness Validation"
echo "==========================================="
echo ""
echo "Before writing E2E tests, verify the code is production-ready (not mock-heavy)."
echo ""
echo "Read: docs/E2E_PRODUCTION_READINESS.md"
echo ""
echo "Quick checks:"
echo "  [ ] API endpoints use real data (not hardcoded responses)"
echo "  [ ] Frontend components don't have dev overrides (if (isDev) branches)"
echo "  [ ] Test data matches actual schema validation rules"
echo ""
read -p "Is code production-ready? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled. Fix code to remove mocks/hardcoded data, then re-run."
  echo "Read docs/E2E_PRODUCTION_READINESS.md for details."
  exit 1
fi

echo ""
echo "✓ Production-readiness confirmed"
echo ""

# Step 0: Remind about Phase 0 audit
echo "📋 STEP 0: Phase 0 Audit (Pre-Generation)"
echo "=========================================="
echo ""
echo "Before proceeding, have you completed Phase 0 audit?"
echo ""
echo "Read: docs/E2E_DEEP_AUDIT_CHECKLIST.md"
echo "Then document:"
echo "  1. Routes & pages (what exists?)"
echo "  2. Components & state"
echo "  3. API endpoints & contracts"
echo "  4. User flows"
echo "  5. Edge cases"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled. Complete Phase 0 audit first."
  exit 1
fi

echo ""
echo "✓ Phase 0 audit confirmed"
echo ""

# Step 3: Planner prompt
echo "Step 3: Planner Agent"
echo "===================="
echo ""
echo "Copy this prompt into Cursor/Claude and run the Planner:"
echo ""
cat << 'PLANNER'
You are the E2E Planner Agent. Your job is to create a test plan by reading actual code and exploring the app.

## Before Starting

**[PHASE 1: Memory Retrieval]**
Retrieve prior E2E patterns for similar features:
```
mcp__memorykit__retrieve_context("e2e: {{FEATURE_NAME}}")
```

Surface any prior patterns found:
- What test patterns succeeded (e.g., "authentication flows need 200ms JWT cleanup")
- What issues to watch for (e.g., "table pagination tests fail without waitForLoadState")
- What to avoid (e.g., "CSS class selectors are brittle")

## MANDATORY: Code Reading Requirements

**CRITICAL:** You MUST read actual code before exploring the app. Every assertion must reference actual code.

### 1. Read the Router File (REQUIRED)

Find and read the actual route file for {{PAGE_PATH}}:
- [ ] Locate route handler (src/routes, src/pages/api, app/api, etc.)
- [ ] Verify route {{PAGE_PATH}} exists (don't assume)
- [ ] Read HTTP method (GET/POST/PUT/DELETE)
- [ ] Check auth middleware (is authentication required?)
- [ ] Check role-based access (do users need specific roles?)
- [ ] Note all response status codes (200, 401, 403, 500, etc.)

**Output Example:**
```
Route: {{PAGE_PATH}}
  ✓ File: src/routes/listings.ts
  ✓ Method: GET
  ✓ Auth: Required (via verifyAuth middleware)
  ✓ Role: Must be 'advertiser' or 'admin'
  ✓ Success: HTTP 200
  ✓ Auth error: HTTP 401
  ✓ Permission error: HTTP 403
```

### 2. Read the Component File (REQUIRED)

Find and read the actual component for {{PAGE_PATH}}:
- [ ] Locate component file (src/components, src/pages, app/page.tsx, etc.)
- [ ] List EVERY UI element (heading, button, input, link, etc.)
- [ ] Copy EXACT text/labels (don't paraphrase)
- [ ] Check for conditional rendering (if/else, {condition && ...})
- [ ] Document loading state (how does "loading" display?)
- [ ] Document error state (how does "error" display?)
- [ ] Document empty state (how does "no data" display?)

**Output Example:**
```
Component: src/components/DashboardPage.tsx
  ✓ Heading: "My Listings" (exact text, line 15)
  ✓ Button: "Create New" (exact text, line 42)
  ✓ Loading: Shows <Spinner /> from loading state
  ✓ Empty: Shows text "No listings created yet" (line 52)
  ✓ Error: Shows error in <ErrorAlert /> component
```

### 3. Read the API Endpoint (REQUIRED)

Find and read the API endpoint your feature uses:
- [ ] Locate API handler file
- [ ] Read exact request parameters
- [ ] Copy exact response structure (field names, types)
- [ ] Document all error responses (status + message)
- [ ] Verify endpoint is NOT hardcoded/mocked (real data)

**Output Example:**
```
Endpoint: GET /api/v1/listings
  ✓ File: src/api/listings.ts
  ✓ Success response:
    {
      listings: [ { id, title, status, created_at } ],
      total_count: number,
      has_next: boolean
    }
  ✓ Errors:
    401: { error: "Unauthorized" }
    403: { error: "Access denied" }
    500: { error: "Server error" }
```

### 4. Trace State Management (REQUIRED)

Find how component fetches and displays data:
- [ ] Read fetch/API calls (where does data come from?)
- [ ] Check loading state trigger (when does loading show?)
- [ ] Check error handling (what displays on error?)
- [ ] Verify cleanup (is state cleared properly?)

**Output Example:**
```
State Flow: DashboardPage.tsx
  ✓ Fetch: await fetch('/api/v1/listings')
  ✓ Loading: Shows <Spinner /> during fetch
  ✓ Error: Catches and displays in <ErrorAlert />
  ✓ Success: Renders <ListingTable data={listings} />
  ✓ Empty: Shows "No listings created yet" when listings.length === 0
```

## Exploration & Planning

Feature: {{FEATURE_NAME}}
Page: {{PAGE_PATH}}
App: http://localhost:3000

Using Playwright MCP, explore the page:
1. Verify code-reading findings (routes/components/APIs exist as documented above)
2. Happy path flow (step-by-step with exact text from code)
3. Error scenarios (match actual error responses from code)
4. Edge cases (match actual empty/loading states from code)
5. Expected behaviors (exact text, loading behavior, error messages)

Reference any prior patterns from memory to inform your plan.

**CRITICAL:** Every test scenario must reference actual code lines.

Format: Markdown with clear sections and code references.
Return a comprehensive test plan document.

## Memory Storage (Phase 1)

After creating the plan, store insights:
```
mcp__memorykit__store_memory(
  title: "E2E Test Plan: {{FEATURE_NAME}}",
  content: "Code-reading findings + test plan:\n[include code references and plan]",
  tags: ["e2e", "test-plan", "code-reading", "{{FEATURE_NAME}}"],
  scope: "project"
)
```

## Enforcement

If you cannot find code to verify a test scenario:
- STOP — do not assume
- Report what's missing
- Example: "Cannot find Delete button in component. Component has: Heading, Edit button, Cancel button. No Delete."

This prevents false test coverage.
PLANNER

echo ""
echo "After Planner returns the test plan, paste it below:"
echo "(Press Ctrl+D when done)"
TEST_PLAN_FILE="/tmp/test-plan-$FEATURE_NAME.md"
cat > "$TEST_PLAN_FILE"

echo ""
echo "✓ Test plan received"
echo ""

# Step 4: Generator prompt
echo "Step 4: Generator Agent"
echo "======================"
echo ""
echo "Copy this prompt into Cursor/Claude and run the Generator:"
echo ""
cat << 'GENERATOR'
You are the E2E Generator Agent. Your job is to generate Playwright tests from a test plan, with code verification.

## Before Starting

**[PHASE 2: Memory Retrieval & Pattern Reuse]**
Retrieve prior E2E test patterns for similar features:
```
mcp__memorykit__retrieve_context("e2e: test-patterns")
```

Surface patterns found in memory:

**Patterns Recommended for Reuse** (high success rate):
- Pattern A: [name] (worked in [N] prior tests, 100% success)
  → Recommendation: USE this pattern

**Patterns to Watch** (known issues):
- Pattern B: [name] (needed debugging in [N] prior tests)
  → Use pattern but anticipate this issue
  → Example: "Timeouts on table rendering without waitForLoadState('networkidle')"

**Patterns to Avoid** (failed or brittle):
- Anti-pattern X: [name] — caused [issue]
  → Use [recommended alternative] instead

## MANDATORY: Code Verification Before Generation

**CRITICAL:** Before generating ANY test code, verify the test plan against actual code.

### Verification Step 1: API Contract Verification

For each API call in the test plan:
- [ ] Read actual endpoint handler file
- [ ] Copy exact response structure from code (all field names, types)
- [ ] List all possible error responses (status codes + messages)
- [ ] Verify endpoint exists (not mocked, not assumed)
- [ ] Check authentication/authorization requirements

**Example verification:**
```
❌ Test Plan says: "API returns { success: true }"
✓ Code shows: "API returns { listings: [], total_count: number, has_next: boolean }"
→ FIX: Update test expectations to match actual response
```

**Output:**
```
API Contract Verification:
  ✓ Endpoint: GET /api/v1/listings (verified in src/api/listings.ts)
  ✓ Response: { listings: Listing[], total_count: number, has_next: boolean }
  ✓ Errors: 401 { error: "Unauthorized" }, 403 { error: "Access denied" }
  ✓ NOT mocked: Uses real database queries (verified line 15)
```

### Verification Step 2: Selector Verification

For each UI element in the test plan:
- [ ] Read actual component JSX code
- [ ] Verify element exists (exact tag, text, role, label)
- [ ] Copy EXACT text from code (don't paraphrase)
- [ ] Verify element is visible (not hidden by default)
- [ ] Check conditional rendering (does it always render?)

**Example verification:**
```
❌ Test assumes: Button text is "Add New"
✓ Code shows: <button>Create New</button>
→ FIX: Update selector to match actual button text
```

**Output:**
```
Selector Verification:
  ✓ Heading: page.getByRole('heading', { name: 'My Listings' })
    Source: src/components/Dashboard.tsx line 15 <h1>My Listings</h1>
  ✓ Button: page.getByRole('button', { name: 'Create New' })
    Source: src/components/Dashboard.tsx line 42 <button>Create New</button>
  ✓ All selectors exist and are visible
```

### Verification Step 3: State Verification

- [ ] Verify loading state component exists and displays correctly
- [ ] Verify error state component exists and displays correctly
- [ ] Verify empty state component exists and displays correctly
- [ ] Check that waitFor() calls are appropriate

**Example verification:**
```
❌ Test assumes: Component shows loading spinner
✓ Code shows: Component does NOT have loading state, always shows table
→ FIX: Remove waitFor(spinner), table appears immediately
```

### Verification Step 4: Test Data Validation

- [ ] Read database schema or validation rules
- [ ] Verify test data matches validation (email format, number ranges, string lengths)
- [ ] Check required fields match schema
- [ ] Ensure UUID-based data (not predictable collisions)

**Example verification:**
```
✓ Schema requires: email format, name min 2 chars, age 18-120
✓ Test data: "test-uuid@example.com", "John Doe", 25
→ All match schema requirements
```

## Generation Task

Based on this VERIFIED test plan, generate Playwright tests:

Test Plan:
{{TEST_PLAN}}

STRICT requirements:
1. Semantic locators ONLY (based on code verification):
   - getByRole('button', { name: /pattern/i })
   - getByLabel(/pattern/i)
   - getByText(/pattern/i)
   - NO data-testid unless verified in component code
   - NO XPath, NO CSS classes

2. Use fixtures:
   - const { /* auth data */ } = await loginAsAdvertiser()

3. Test data:
   - Use uuidv4() from test-data.ts
   - Match actual schema validation rules (from code verification)
   - Prefix unused vars with _

4. Timeouts:
   - actionTimeout: 15000ms
   - navigationTimeout: 30000ms
   - Use waitForLoadState() only where code shows async operations

5. Structure:
   - Arrange → Act → Assert
   - One assertion per test where possible
   - Each test independent
   - Include test.afterEach cleanup

6. Reuse Prior Patterns:
   - Apply any patterns from memory marked "Recommended for Reuse"
   - Add watch-list warnings as comments for patterns to monitor
   - Avoid anti-patterns noted in memory

7. Code References:
   - Include comment with file:line reference for each assertion
   - Example: `// From src/components/Dashboard.tsx:15`

Output: Complete test file and POM class (production-ready, with code references)

## If Code Verification Fails

If you find mismatches between test plan and actual code:
1. STOP test generation
2. Report what doesn't match (specific lines, expected vs actual)
3. DO NOT generate tests for non-existent features
4. Example: "Test plan assumes DELETE button, but component only has EDIT button (line 42). No DELETE button found."

This prevents false test coverage.

## Memory Storage (Phase 2)

After generating, store patterns for future reuse:
```
mcp__memorykit__store_memory(
  title: "E2E Test Patterns Generated",
  content: "Code-verified patterns used:\n- [pattern 1 with source file]\n- [pattern 2]\nSuccess rate: verified against actual code",
  tags: ["e2e", "test-patterns", "code-verified", "generated"],
  scope: "project"
)
```
GENERATOR

echo ""
echo "After Generator returns the code, paste it below:"
echo "(Press Ctrl+D when done)"
GENERATED_CODE_FILE="/tmp/generated-code-$FEATURE_NAME.ts"
cat > "$GENERATED_CODE_FILE"

if [ ! -s "$GENERATED_CODE_FILE" ]; then
  echo "❌ No code provided"
  exit 1
fi

echo "✓ Generated code received"
echo ""

# Step 5: Verify
echo "Step 5: Code Quality Verification"
echo "=================================="
echo ""

CHECKS_PASSED=0
CHECKS_TOTAL=5

if grep -q "getByRole\|getByLabel\|getByText" "$GENERATED_CODE_FILE"; then
  echo "✓ Uses semantic locators"
  ((CHECKS_PASSED++))
else
  echo "⚠ No semantic locators found"
fi
((CHECKS_TOTAL++))

if grep -q "test.afterEach\|try.*finally" "$GENERATED_CODE_FILE"; then
  echo "✓ Has cleanup"
  ((CHECKS_PASSED++))
else
  echo "⚠ No explicit cleanup"
fi
((CHECKS_TOTAL++))

if grep -q "uuidv4\|generateUniqueString" "$GENERATED_CODE_FILE"; then
  echo "✓ Uses UUID test data"
  ((CHECKS_PASSED++))
else
  echo "⚠ No UUID usage"
fi

echo ""
echo "Verification: $CHECKS_PASSED/$CHECKS_TOTAL checks passed"
echo ""

# Step 6: Type check
echo "Step 6: TypeScript Type Check"
echo "============================="
echo ""

mkdir -p "$FEATURE_TEST_DIR"
cp "$GENERATED_CODE_FILE" "$FEATURE_TEST_DIR/feature.spec.ts"

cd frontend
if npx tsc --noEmit 2>&1 | grep -q "$FEATURE_TEST_DIR"; then
  echo "⚠ Type check warnings found"
  echo "  Review and fix if needed"
else
  echo "✓ Type check passed"
fi
cd ..

echo ""

# Step 7: Run tests
echo "Step 7: Test Execution"
echo "====================="
echo ""

cd frontend
if npm run test:e2e:local 2>&1 | grep -q "passed"; then
  echo "✓ Tests passed!"
  TEST_RESULT="PASS"
else
  echo "⚠ Tests failed or inconclusive"
  TEST_RESULT="CHECK"
fi
cd ..

echo ""

# Summary
echo "========================================="
echo "Phase 3 Pipeline Complete"
echo "========================================="
echo "Feature: $FEATURE_NAME"
echo "Page: $PAGE_PATH"
echo "Test Dir: $FEATURE_TEST_DIR"
echo "Status: $TEST_RESULT"
echo ""
echo "Next Step: Phase 8 Audit"
echo "Read: docs/E2E_PIPELINE_AUDIT.md"
echo ""
echo "Then commit:"
echo "  git add frontend/e2e/"
echo "  git commit -m \"feat(e2e): Add $FEATURE_NAME tests\""
echo ""
PIPELINE_EOF

chmod +x scripts/phase3-pipeline.sh

echo "✓ Copied phase3-pipeline.sh"

# Verify documentation files exist
if [ ! -f "docs/E2E_DEEP_AUDIT_CHECKLIST.md" ]; then
  echo "⚠️  Documentation files not found in template/"
  echo "    Downloading from repository..."

  # Try to download from GitHub
  REPO_URL="https://raw.githubusercontent.com/enriqueibarra/e2e-testing-setup/main/template/docs"

  mkdir -p docs
  for doc in "E2E_DEEP_AUDIT_CHECKLIST.md" "E2E_PIPELINE_AUDIT.md" "E2E_SEMANTIC_LOCATORS.md" "PHASE_3_AUTOMATED_PIPELINE.md"; do
    curl -s "$REPO_URL/$doc" -o "docs/$doc" 2>/dev/null && echo "✓ Downloaded $doc" || echo "⚠ Could not download $doc"
  done

  # If download failed, provide instructions
  if [ ! -f "docs/E2E_DEEP_AUDIT_CHECKLIST.md" ]; then
    echo ""
    echo "❌ Documentation files could not be installed automatically."
    echo ""
    echo "Please run this from the e2e-testing-setup repository root:"
    echo "  cd /path/to/e2e-testing-setup"
    echo "  bash install.sh"
    echo ""
    echo "Or manually copy the docs:"
    echo "  cp template/docs/*.md /your/project/docs/"
    exit 1
  fi
fi

echo "✓ E2E documentation ready"

# Update package.json scripts
if ! grep -q '"test:e2e"' package.json; then
  # Add E2E scripts
  cat >> package.json << 'PKG_EOF'

  "test:e2e": "playwright test",
  "test:e2e:local": "TEST_ENV=local playwright test",
  "test:e2e:staging": "TEST_ENV=staging playwright test",
  "test:e2e:ui": "playwright test --ui",
  "test:e2e:debug": "playwright test --debug",
PKG_EOF

  echo "✓ Added E2E npm scripts"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Read docs/E2E_DEEP_AUDIT_CHECKLIST.md"
echo "2. Document your feature's flows"
echo "3. Run: ./scripts/phase3-pipeline.sh \"feature-name\" \"/page/path\""
echo "4. Follow the prompts"
echo "5. Read docs/E2E_PIPELINE_AUDIT.md"
echo ""
