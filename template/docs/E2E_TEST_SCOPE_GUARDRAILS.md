# E2E Test Scope Guardrails: Keep Tests Simple

**When to use:** Every time the Planner or Generator runs  
**What it covers:** Rules for simple, maintainable, focused tests  
**Why it matters:** Complex tests catch nothing. Simple tests catch bugs and are maintainable.

---

## The Problem with Complex Tests

### ❌ Complex Test (Hard to Maintain, Catches Nothing)

```typescript
test('User can create listing, edit it, add photos, change status, and delete it', async ({ page }) => {
  // Arrange: Complex setup with multiple preconditions
  const user = await loginAsAdvertiser()
  const listing = await createListing({ title: 'Test' })
  await attachPhotos(listing.id, [photo1, photo2])
  
  // Act: Multiple actions in sequence
  await page.goto(`/listings/${listing.id}/edit`)
  await page.fill('input[name="title"]', 'Updated')
  await page.click('button[name="add-photo"]')
  // ... 20 more lines of actions
  
  // Assert: Multiple assertions checking different things
  expect(page.url()).toContain('/listings')
  expect(page.getByText('Updated')).toBeVisible()
  expect(page.getByText('2 photos')).toBeVisible()
  expect(page.getByText('active')).toBeVisible()
  // ... more assertions
})
```

**Problems:**
- ❌ Tests 5 different features in one test
- ❌ 50+ lines of setup, action, assertion
- ❌ If photo upload breaks, whole test fails even though title edit works
- ❌ Hard to understand what's being tested
- ❌ Hard to debug when it fails
- ❌ Catches only catastrophic failures

### ✅ Simple Tests (Easy to Maintain, Catches Real Bugs)

```typescript
test('AC1: User can navigate to create listing page', async ({ page }) => {
  await page.goto('/listings')
  await page.getByRole('button', { name: 'Create New' }).click()
  await expect(page).toHaveURL('/listings/create')
})

test('AC2: Create listing form accepts valid data', async ({ page }) => {
  await page.goto('/listings/create')
  await page.fill('input[aria-label="Title"]', 'My Listing')
  await page.fill('textarea[aria-label="Description"]', 'Great property')
  await page.getByRole('button', { name: 'Save' }).click()
  await expect(page).toHaveURL('/listings/view')
})

test('AC3: Edit listing updates title', async ({ page, api }) => {
  const listing = await api.post('/api/listings', { title: 'Old Title' })
  await page.goto(`/listings/${listing.id}/edit`)
  await page.fill('input[aria-label="Title"]', 'New Title')
  await page.getByRole('button', { name: 'Save' }).click()
  
  const updated = await api.get(`/api/listings/${listing.id}`)
  expect(updated.title).toBe('New Title')
})
```

**Advantages:**
- ✅ Each test does one thing
- ✅ 10-15 lines per test (easy to read)
- ✅ If photo upload breaks, title edit test still passes
- ✅ Clear what's being tested (test name = what it does)
- ✅ Easy to debug (one assertion usually fails)
- ✅ Catches real bugs because each behavior is isolated

---

## The Rules: Test Scope Guardrails

### Rule 1: One Assertion Per Test (Usually)

**Good:**
```typescript
test('AC1: Page displays user greeting', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page.getByText('Welcome, John')).toBeVisible()
})

test('AC2: Dashboard loads listings table', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page.locator('table')).toBeVisible()
})
```

**Bad:**
```typescript
test('Dashboard loads properly', async ({ page }) => {
  await page.goto('/dashboard')
  // Multiple assertions checking different things
  expect(page.getByText('Welcome, John')).toBeVisible()
  expect(page.locator('table')).toBeVisible()
  expect(page.getByRole('button', { name: 'Create' })).toBeVisible()
  expect(page.getByText('Last updated')).toBeVisible()
  // ... 10 more assertions
})
```

**Why:**
- One assertion = easy to fix when it fails
- Multiple assertions = hard to know what broke

### Rule 2: One Feature Per Test

**Good:**
```typescript
test('AC1: Form shows error for empty email', async ({ page }) => {
  await page.goto('/register')
  await page.getByRole('button', { name: 'Sign Up' }).click()
  await expect(page.getByText('Email is required')).toBeVisible()
})

test('AC2: Form shows error for invalid email format', async ({ page }) => {
  await page.goto('/register')
  await page.fill('input[aria-label="Email"]', 'not-an-email')
  await page.getByRole('button', { name: 'Sign Up' }).click()
  await expect(page.getByText('Invalid email format')).toBeVisible()
})
```

**Bad:**
```typescript
test('Form validation works', async ({ page }) => {
  // Tests multiple validation rules in one test
  await page.goto('/register')
  
  // Test 1: empty email
  await page.getByRole('button', { name: 'Sign Up' }).click()
  expect(page.getByText('Email is required')).toBeVisible()
  
  // Test 2: invalid format (need to fill and clear)
  await page.fill('input[aria-label="Email"]', 'not-an-email')
  expect(page.getByText('Invalid email format')).toBeVisible()
  
  // Test 3: too short password
  await page.fill('input[aria-label="Password"]', 'short')
  expect(page.getByText('Password too short')).toBeVisible()
})
```

**Why:**
- One feature = test fails for one reason
- Multiple features = test fails for multiple possible reasons

### Rule 3: Max 15 Lines Per Test

**Good (12 lines):**
```typescript
test('AC1: User can submit contact form', async ({ page }) => {
  await page.goto('/contact')
  await page.fill('input[aria-label="Name"]', 'John')
  await page.fill('input[aria-label="Email"]', 'john@example.com')
  await page.fill('textarea[aria-label="Message"]', 'Hello')
  await page.getByRole('button', { name: 'Send' }).click()
  await expect(page.getByText('Message sent')).toBeVisible()
})
```

**Bad (40 lines):**
```typescript
test('User can submit contact form with full flow', async ({ page }) => {
  // Navigate to contact page
  await page.goto('/contact')
  
  // Fill all fields
  await page.fill('input[aria-label="Name"]', 'John')
  await page.fill('input[aria-label="Email"]', 'john@example.com')
  await page.fill('input[aria-label="Phone"]', '123-456-7890')
  await page.fill('input[aria-label="Company"]', 'Acme Corp')
  
  // Select dropdown
  await page.selectOption('select[aria-label="Subject"]', 'bug-report')
  
  // Check checkboxes
  await page.check('input[name="subscribe"]')
  
  // Fill textarea
  await page.fill('textarea[aria-label="Message"]', 'Hello there')
  
  // Upload file (complex)
  const fileInput = page.locator('input[type="file"]')
  await fileInput.setInputFiles('test-file.pdf')
  
  // Submit
  await page.getByRole('button', { name: 'Send' }).click()
  
  // Multiple assertions
  expect(page.getByText('Message sent')).toBeVisible()
  expect(page.url()).toContain('/thank-you')
  expect(page.getByText('John')).toBeVisible()
})
```

**Why:**
- 15 lines = easy to read and understand
- 40+ lines = hard to follow the intent

### Rule 4: Max 5 User Actions Per Test

**Good (3 actions):**
```typescript
test('AC1: User can create a listing', async ({ page }) => {
  // Action 1: Navigate
  await page.goto('/listings/create')
  
  // Action 2: Fill form
  await page.fill('input[aria-label="Title"]', 'My House')
  
  // Action 3: Submit
  await page.getByRole('button', { name: 'Create' }).click()
  
  // Assert: Page changed
  await expect(page).toHaveURL('/listings/view')
})
```

**Bad (10+ actions):**
```typescript
test('User can create listing and add multiple photos', async ({ page }) => {
  // Action 1
  await page.goto('/listings/create')
  // Action 2
  await page.fill('input[aria-label="Title"]', 'My House')
  // Action 3
  await page.fill('textarea[aria-label="Description"]', '...')
  // Action 4
  await page.click('button[name="add-photo"]')
  // Action 5
  await page.locator('input[type="file"]').setInputFiles('photo1.jpg')
  // Action 6
  await page.click('button[name="add-photo"]')
  // Action 7
  await page.locator('input[type="file"]').setInputFiles('photo2.jpg')
  // Action 8
  await page.click('button[name="add-photo"]')
  // Action 9
  await page.locator('input[type="file"]').setInputFiles('photo3.jpg')
  // Action 10
  await page.getByRole('button', { name: 'Create' }).click()
})
```

**Why:**
- 5 actions = easy flow to follow
- 10+ actions = complex branching, hard to debug

### Rule 5: No Complex State Combinations

**Good (one scenario):**
```typescript
test('AC1: Empty state shows when no listings exist', async ({ page }) => {
  // User has no listings
  await page.goto('/my-listings')
  await expect(page.getByText('No listings yet')).toBeVisible()
})

test('AC2: Table shows listings when they exist', async ({ page, api }) => {
  // Create a listing first
  await api.post('/api/listings', { title: 'My House' })
  
  // Now page shows it
  await page.goto('/my-listings')
  await expect(page.getByText('My House')).toBeVisible()
})
```

**Bad (complex combinations):**
```typescript
test('Listings page handles all states', async ({ page, api }) => {
  // Scenario 1: No listings
  await page.goto('/my-listings')
  expect(page.getByText('No listings')).toBeVisible()
  
  // Scenario 2: Create one listing
  await api.post('/api/listings', { title: 'House1' })
  await page.reload()
  expect(page.getByText('House1')).toBeVisible()
  
  // Scenario 3: Create another, verify sorting
  await api.post('/api/listings', { title: 'House2' })
  await page.reload()
  expect(page.locator('table tr').nth(0)).toContainText('House2')
  expect(page.locator('table tr').nth(1)).toContainText('House1')
  
  // Scenario 4: Filter by status
  await page.selectOption('select[name="status"]', 'active')
  expect(page.getByText('House1')).toBeVisible()
  expect(page.getByText('House2')).toBeVisible()
  
  // Scenario 5: Error on delete
  await page.getByRole('button', { name: 'Delete' }).click()
  // ... more state changes
})
```

**Why:**
- One scenario per test = clear what's being tested
- Multiple scenarios = if one breaks, hard to know which

---

## What This Looks Like in Practice

### Acceptance Criteria → Simple Tests

**User Story:**
```
As an advertiser
I want to create a listing with basic info
So that I can list my property

Acceptance Criteria:
1. Form accepts valid title
2. Form accepts valid description
3. Form rejects empty title
4. Form shows success message on save
```

**Generated Tests:**
```typescript
test('AC1: Form accepts valid title', async ({ page }) => {
  await page.goto('/listings/create')
  await page.fill('input[aria-label="Title"]', 'My House')
  // No assertion needed yet, just proving form accepts it
})

test('AC2: Form accepts valid description', async ({ page }) => {
  await page.goto('/listings/create')
  await page.fill('textarea[aria-label="Description"]', 'Great property')
  // Proving form accepts it
})

test('AC3: Form rejects empty title', async ({ page }) => {
  await page.goto('/listings/create')
  await page.getByRole('button', { name: 'Create' }).click()
  await expect(page.getByText('Title is required')).toBeVisible()
})

test('AC4: Shows success message on save', async ({ page }) => {
  await page.goto('/listings/create')
  await page.fill('input[aria-label="Title"]', 'My House')
  await page.fill('textarea[aria-label="Description"]', 'Great property')
  await page.getByRole('button', { name: 'Create' }).click()
  await expect(page.getByText('Listing created')).toBeVisible()
})
```

**Why this is better:**
- ✅ 4 tests, each 5-8 lines
- ✅ Each tests one thing
- ✅ Easy to read, easy to debug
- ✅ Catches real bugs
- ✅ Maintainable

---

## Guardrails Summary

| Rule | Limit | Reason |
|------|-------|--------|
| **Assertions per test** | Max 1-2 | Easy to debug |
| **Features per test** | 1 | Isolate failures |
| **Lines per test** | Max 15 | Easy to read |
| **User actions** | Max 5 | Simple flow |
| **State scenarios** | 1 per test | Clear intent |
| **Setup complexity** | Simple | Easy to understand |
| **Test dependencies** | None | Tests run in any order |

---

## How Agents Should Generate Tests

### Planner Agent: Create Simple Test Plans

**Bad test plan:**
```
1. User logs in
2. Creates listing with title, description, photos, location, pricing
3. Edits listing with new photos
4. Changes status to inactive
5. Deletes listing
6. Verifies in dashboard, email, API
```

**Good test plan:**
```
AC1: Navigation to create page works
AC2: Form accepts valid title
AC3: Form accepts valid description  
AC4: Form rejects empty title
AC5: Success message shows on save
AC6: Redirect to listing view on save
```

### Generator Agent: Create Simple Tests

**Bad generated test (30+ lines):**
```typescript
test('User flow from login to listing creation', async ({ page }) => {
  // ... complex setup, multiple actions, multiple assertions
})
```

**Good generated tests (6-10 lines each):**
```typescript
test('AC1: Navigate to create listing', async ({ page }) => { ... })
test('AC2: Form accepts valid title', async ({ page }) => { ... })
test('AC3: Form accepts valid description', async ({ page }) => { ... })
// ... one test per AC
```

---

## When to Break the Rules

### ✅ OK to Break Rule 1 (One Assertion) When:
- Testing a complete user flow (happy path only)
- Assertions are strongly related
- Test is still < 15 lines

Example:
```typescript
test('User can successfully create and view listing', async ({ page }) => {
  await page.goto('/listings/create')
  await page.fill('input[aria-label="Title"]', 'My House')
  await page.getByRole('button', { name: 'Create' }).click()
  
  // These two are related (same feature)
  await expect(page).toHaveURL('/listings/view')
  await expect(page.getByText('My House')).toBeVisible()
})
```

### ❌ Don't Break Rules For:
- Testing multiple different features
- Adding "just one more check"
- Testing edge cases (separate test per edge case)
- Complex state setups

---

## Red Flags: When Tests Get Too Complex

🚩 **Too many lines** (> 20 lines)
→ Split into separate tests

🚩 **Multiple setup steps** (> 5 lines of setup)
→ Use fixtures or API setup, not UI

🚩 **Multiple assertions** (> 3 unrelated assertions)
→ One assertion per test

🚩 **Complex condition logic** (if/else, loops in test)
→ Each branch should be separate test

🚩 **Testing multiple features** (create, edit, delete in one test)
→ One feature per test

🚩 **Page interactions are confusing** (clicking confusing buttons, hard to follow)
→ Simplify the flow or split into smaller tests

---

## Memory: Learning from Test Scope

After each feature, store to memory:

```
mcp__memorykit__store_memory(
  title: "E2E Test Scope Learnings: Feature X",
  content: "
  Scope Analysis:
  - Tests generated: 8
  - Avg lines per test: 9
  - Avg assertions per test: 1.2
  - Test failures: 1 (easy to debug)
  
  What worked:
  - Kept each test to one AC
  - 5-8 lines per test
  - Single assertion focus
  
  What was complex:
  - None (followed guardrails well)
  ",
  tags: ["e2e", "test-scope", "feature-x"],
  scope: "project"
)
```

This helps agents learn what scope works and what doesn't.

---

## Summary

**The Goal:** Simple, maintainable, focused tests that catch real bugs.

**The Rules:**
1. ✅ One assertion per test (usually)
2. ✅ One feature per test
3. ✅ Max 15 lines per test
4. ✅ Max 5 user actions per test
5. ✅ One scenario per test

**The Result:**
- 10 simple tests catch more bugs than 100 complex tests
- Each test is 30 seconds to understand
- Each test failure points to one root cause
- New developers can write tests using same pattern
- Tests are maintainable for years

**The Golden Rule:** If a test is hard to read, it's probably too complex. Simplify it.
