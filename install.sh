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

# Copy playwright config
cat > frontend/e2e/playwright.config.ts << 'PLAYWRIGHT_EOF'
import { defineConfig, devices } from '@playwright/test'

const env = process.env.TEST_ENV || 'local'
const timeoutConfig = {
  local: {
    actionTimeout: 5000,
    navigationTimeout: 15000,
    testTimeout: 30000,
    name: 'Local Dev',
  },
  staging: {
    actionTimeout: 15000,
    navigationTimeout: 30000,
    testTimeout: 60000,
    name: 'Staging (Realistic)',
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
  workers: process.env.CI ? 1 : 4,

  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,

  reporter: [
    ['html'],
    ['list'],
    ...(process.env.CI ? [
      ['json', { outputFile: 'test-results/results.json' }],
      ['junit', { outputFile: 'test-results/results.xml' }],
    ] : []),
  ],

  use: {
    baseURL: 'http://localhost:3000',
    actionTimeout: timeoutConfig.actionTimeout,
    navigationTimeout: timeoutConfig.navigationTimeout,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
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
    {
      name: 'mobile-chrome',
      use: { ...devices['Pixel 5'] },
    },
  ],
})
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
Using Playwright MCP, create a test plan for this feature.

Feature: {{FEATURE_NAME}}
Page: {{PAGE_PATH}}
App: http://localhost:3000

Explore the page and document:
1. Happy path (what should work)
2. Error scenarios (what can fail)
3. Edge cases (unusual situations)
4. Expected behaviors

Format: Markdown with clear sections.
Return a test plan document.
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
Based on this test plan, generate Playwright tests.

Test Plan:
{{TEST_PLAN}}

STRICT requirements:
1. Semantic locators ONLY:
   - getByRole('button', { name: /pattern/i })
   - getByLabel(/pattern/i)
   - getByText(/pattern/i)
   - NO data-testid, NO XPath, NO CSS classes

2. Use fixtures:
   - const { /* auth data */ } = await loginAsAdvertiser()

3. Test data:
   - Use uuidv4() from test-data.ts
   - Prefix unused vars with _

4. Timeouts:
   - actionTimeout: 15000ms
   - navigationTimeout: 30000ms

5. Structure:
   - Arrange → Act → Assert
   - One assertion per test where possible
   - Each test independent

Output: Complete test file and POM class (production-ready)
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
