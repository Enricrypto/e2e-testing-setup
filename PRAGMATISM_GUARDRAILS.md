# E2E Test Pragmatism Guardrails

**Purpose:** Prevent complex, redundant E2E tests that are hard to maintain and debug.

**Problem Solved:**
- ❌ Tests with 6+ user interactions that fail for unclear reasons
- ❌ Test duplication (same assertion in multiple test files)
- ❌ Tests created "just because" without clear purpose
- ❌ Complex flows that test multiple features in one test

---

## Changes Made

### 1. Planner Agent Guardrails

Added to the Planner prompt (in `install.sh` and `phase3-pipeline.sh`):

#### Deduplication Check (MANDATORY)
**What it does:**
- Planner must read ALL existing test files BEFORE planning new tests
- Creates a "Coverage Map" of what's already tested
- Rejects any test that duplicates existing assertions

**Example:**
```
Existing coverage:
  ✓ Create listing (test 01-create-listing.spec.ts)
  ✓ Required field validation (test 02-form-validation.spec.ts)
  ✓ Auth error handling (test 03-auth.spec.ts)

Test Plan: "User submits form → success message shows"
  ❌ Already covered by test 01-create-listing.spec.ts
  → SKIP this test
```

#### Pragmatism Filter (MANDATORY)
**What it does:**
- Rejects flows with >3-4 user interactions
- Requires single focused scenario per test
- Enforces independent tests (can run in any order)

**Rejected (too complex):**
```
❌ "User logs in → navigates to listings → clicks Create → fills form 
   → submits → sees success → navigates to list → verifies row → clicks row 
   → sees details"
   (8 interactions, 4+ independent assertions)
```

**Accepted (pragmatic):**
```
✓ "User submits form → success message appears"  (1 action, 1 assertion)
✓ "User submits invalid email → error shows"     (1 action, 1 assertion)
✓ "Page loads with no data → empty state shows"  (1 state, 1 assertion)
```

**Rule: Max 3-4 Interactions Per Test**

If a test needs more interactions, it MUST be split:
```typescript
// ❌ Don't do this (1 test with 8 interactions)
test('user creates and views listing', async () => {
  await page.goto('/create');
  await page.fill('input[name="title"]', 'My Listing');
  await page.click('button:has-text("Create")');
  await page.goto('/dashboard');
  await expect(page.getByText('My Listing')).toBeVisible();
  // ... more interactions
});

// ✓ Do this (3 separate tests)
test('successfully submits listing form', async () => {
  await page.goto('/create');
  await page.fill('input[name="title"]', 'My Listing');
  await page.click('button:has-text("Create")');
});

test('listing appears in dashboard', async () => {
  const listing = await createTestListing(); // Setup via API
  await page.goto('/dashboard');
  await expect(page.getByText(listing.title)).toBeVisible();
});
```

---

### 2. Generator Agent Guardrails

Added to the Generator prompt (in `install.sh` and `phase3-pipeline.sh`):

#### Deduplication Validation (MANDATORY - BLOCKING)
**What it does:**
- Generator MUST read existing tests before generating code
- For each test in the plan: checks for assertion overlap
- STOPS and reports duplication (blocks code generation)

**Example:**
```
Test Plan: "User submits form → success message shows"
Existing: test 01-create-listing.spec.ts already checks this
  ❌ DUPLICATION DETECTED
  Message: "Test 'form submission' duplicates existing test in 01-create-listing.spec.ts"
  Action: STOP — don't generate this test
```

#### Pragmatism Enforcement (MANDATORY - BLOCKING)
**What it does:**
- Generator MUST check each test for >4 interactions
- If found, STOPS and recommends splitting
- Rejects complex state setup (>2 API calls)

**Example:**
```
Test Plan: "User logs in, searches, filters, sorts, exports, verifies"
  ❌ TOO COMPLEX: 6 interactions
  Message: "Test has 6 interactions. Split into separate tests:
            - Login (already tested)
            - Search functionality
            - Filter functionality
            - Sort functionality
            - Export functionality"
  Action: STOP — split and resubmit
```

#### Design Justification (REQUIRED)
**What it does:**
- Generator must add a comment to EVERY test explaining:
  1. What the user does
  2. What scenario it covers
  3. Why this matters
  4. How it differs from existing tests (if related)

**Example:**
```typescript
// Test: User submits listing form with valid data
// Covers: Happy path form submission and success feedback
// Why: Validates that form posts correctly and user sees confirmation
// Existing: No other test covers form submission success message
test('successfully submits listing form', async ({ page }) => {
  // ...
});

// Test: Email validation error message
// Covers: Specific email format validation
// Why: Catches invalid emails early (prevents bad data in DB)
// Existing: Test 02-form-validation.spec.ts covers required fields,
//           but not email format specifically
test('shows validation error for invalid email', async ({ page }) => {
  // ...
});
```

---

## Enforcement Checkpoints

### In the Planner:
1. ✅ Must list existing tests and create coverage map
2. ✅ Must apply pragmatism filter to each scenario
3. ✅ Must justify each test (why it exists, why it's not complex)

### In the Generator:
1. ✅ Must validate deduplication before generating code
2. ✅ Must validate pragmatism before generating code
3. ✅ Must add design justification comments

### In the Pipeline Script:
1. ✅ Checks for semantic locators
2. ✅ Checks for cleanup
3. ✅ Checks for UUID usage
4. ✅ **NEW:** Checks for pragmatism (interaction count)
5. ✅ **NEW:** Checks for design justification comments
6. ✅ **NEW:** Reminds to verify deduplication

---

## Why This Matters

### Complex tests are brittle
- A 10-step test can fail on step 7 for reasons unrelated to step 7
- Debugging takes hours instead of minutes
- Flaky tests waste developer time

### Duplicate tests are wasted effort
- Same assertion tested twice = half the value
- Maintenance burden increases with code
- False sense of coverage

### Pragmatic tests are maintainable
- One interaction = clear failure point
- Easy to debug (if it fails, know what broke)
- Fast to run
- Easy to understand

---

## How to Use

### For Planner Agent
```
✓ Read existing tests first
✓ Create a coverage map
✓ For each test scenario:
  - Does it duplicate existing tests? Skip if yes
  - Does it have >4 interactions? Split if yes
  - Can you explain why it exists? Write it down
```

### For Generator Agent
```
✓ Validate no duplication (read existing tests)
✓ Validate pragmatism (max 4 interactions)
✓ Add design justification to every test
✓ If you find violations: STOP and report
```

### For Developers
```
✓ Review generated tests for these guardrails
✓ If tests seem complex: split them
✓ If tests seem redundant: combine or remove
✓ Check comments explain why each test exists
```

---

## Quick Checklist: Is Your Test Pragmatic?

- [ ] Does it have ≤4 user interactions? (if >4, split it)
- [ ] Does it check ONE focused assertion? (if multiple, split it)
- [ ] Can it run independently? (if depends on another test, make it independent)
- [ ] Is setup simple? (if >2 API calls, use fixtures)
- [ ] Does it have a comment explaining why? (justification required)
- [ ] Does it NOT duplicate another test? (check before writing)

If you answer ❌ to any, refactor the test.

---

## Examples

### ❌ Too Complex (Don't Do This)
```typescript
test('complete user workflow', async ({ page, advertiser }) => {
  // 1. Login
  await page.goto('/login');
  await page.fill('input[name="email"]', advertiser.email);
  await page.fill('input[name="password"]', advertiser.password);
  await page.click('button:has-text("Sign in")');
  
  // 2. Navigate
  await page.goto('/listings');
  
  // 3. Create
  await page.click('button:has-text("Create New")');
  await page.fill('input[name="title"]', 'Test Listing');
  await page.fill('textarea[name="description"]', 'Test description');
  
  // 4. Submit
  await page.click('button:has-text("Create")');
  
  // 5. Verify multiple things
  await expect(page).toHaveURL('/dashboard');
  await expect(page.getByText('Test Listing')).toBeVisible();
  
  // 6. Click listing
  await page.click('text=Test Listing');
  
  // 7. Verify details
  await expect(page).toHaveURL(/\/listing\/\d+/);
  await expect(page.getByRole('heading', { name: 'Test Listing' })).toBeVisible();
});
```

### ✓ Pragmatic (Do This Instead)
```typescript
// Test 1: Form submission
// Covers: Happy path form submission and success redirect
// Why: Validates form data posts correctly
test('successfully submits listing form', async ({ page, advertiser }) => {
  await loginAsAdvertiser(page, advertiser);
  await page.goto('/create');
  await page.fill('input[name="title"]', 'Test Listing');
  await page.fill('textarea[name="description"]', 'Test description');
  await page.click('button:has-text("Create")');
  
  // One assertion
  await expect(page).toHaveURL('/dashboard');
});

// Test 2: Listing visibility
// Covers: Newly created listing appears in dashboard
// Why: Verifies user can find their listing immediately
// Existing: No other test covers this (form submission test doesn't verify list)
test('newly created listing appears in dashboard', async ({ page }) => {
  const listing = await createTestListing(); // Setup via API
  await loginAsAdvertiser(page);
  await page.goto('/dashboard');
  
  // One assertion
  await expect(page.getByText(listing.title)).toBeVisible();
});

// Test 3: Listing details page
// Covers: Clicking listing opens details page
// Why: Verifies navigation works and details load
test('clicking listing opens details page', async ({ page }) => {
  const listing = await createTestListing();
  await loginAsAdvertiser(page);
  await page.goto('/dashboard');
  await page.click(`text=${listing.title}`);
  
  // One assertion
  await expect(page).toHaveURL(`/listing/${listing.id}`);
});
```

---

## Summary

**The core principle:** Tests should be simple, focused, non-redundant, and easy to understand.

| Attribute | ❌ Complex | ✓ Pragmatic |
|-----------|-----------|------------|
| Interactions | 6+ | ≤4 |
| Assertions | Multiple independent | 1 focused (or 1 group) |
| Duplication | Unknown, maybe | Verified against existing |
| Setup | Complex (3+ API calls) | Simple (fixture/1 API) |
| Debug time | Hours | Minutes |
| Flakiness | High | Low |
| Maintenance | Hard | Easy |

**Goal:** Write tests that catch real bugs, not tests that are hard to write and maintain.
