# E2E Testing Examples: Patterns & Templates

**A complete guide to writing E2E tests with working code examples.**

All examples follow best practices:
- ✅ Semantic locators (getByRole, getByLabel, getByText)
- ✅ Fixtures for setup/teardown (clean isolation)
- ✅ UUID test data (collision-free)
- ✅ Explicit waits (no flakiness)
- ✅ Single focused assertion per test

Each example is copy-paste ready and fully functional.

---

## Example 1: Simple Happy Path (Login → View → Logout)

**What this shows:** Basic navigation, element visibility, text assertions

```typescript
import { test, expect } from '../fixtures'

test('user can log in and view dashboard', async ({ page }) => {
  // ARRANGE: Navigate to login
  await page.goto('/login')
  
  // ACT: Fill login form
  await page.fill('[data-testid="email-input"]', 'user@example.com')
  await page.fill('[data-testid="password-input"]', 'password123')
  await page.click('[data-testid="login-button"]')
  
  // ASSERT: User is logged in (redirect to dashboard)
  await expect(page).toHaveURL(/dashboard/)
  
  // ASSERT: Dashboard displays user greeting
  const greeting = page.locator('[data-testid="user-greeting"]')
  await expect(greeting).toContainText('Welcome')
})
```

**Key patterns:**
- `[data-testid="..."]` for reliable element selection
- `toHaveURL()` for navigation assertions
- `toContainText()` for flexible text matching
- No waits needed (Playwright auto-waits for element visibility)

**Why this works:**
- Tests one clear user action (login)
- Verifies both navigation and content
- No dependencies on other tests
- Fails fast if button doesn't exist or text changes

---

## Example 2: Form Validation (Happy Path + Error Handling)

**What this shows:** Form interaction, validation messages, error states

```typescript
import { test, expect } from '../fixtures'

test.describe('Login Form', () => {
  // TEST 1: Valid form submission
  test('should log in with valid credentials', async ({ page }) => {
    await page.goto('/login')
    
    // ACT: Submit valid form
    await page.fill('[data-testid="email-input"]', 'valid@example.com')
    await page.fill('[data-testid="password-input"]', 'validPassword123')
    await page.click('[data-testid="login-button"]')
    
    // ASSERT: Success
    await expect(page).toHaveURL(/dashboard/)
  })

  // TEST 2: Empty email field
  test('should show error when email is empty', async ({ page }) => {
    await page.goto('/login')
    
    // ACT: Leave email empty, try to submit
    await page.fill('[data-testid="password-input"]', 'password123')
    await page.click('[data-testid="login-button"]')
    
    // ASSERT: Error message appears
    const error = page.locator('[data-testid="email-error"]')
    await expect(error).toBeVisible()
    await expect(error).toContainText('Email is required')
  })

  // TEST 3: Invalid email format
  test('should show error for invalid email format', async ({ page }) => {
    await page.goto('/login')
    
    // ACT: Enter invalid email
    await page.fill('[data-testid="email-input"]', 'not-an-email')
    await page.fill('[data-testid="password-input"]', 'password123')
    await page.click('[data-testid="login-button"]')
    
    // ASSERT: Validation error
    const error = page.locator('[data-testid="email-error"]')
    await expect(error).toBeVisible()
    await expect(error).toContainText('Invalid email')
  })

  // TEST 4: Password too short
  test('should show error when password is too short', async ({ page }) => {
    await page.goto('/login')
    
    // ACT: Enter short password
    await page.fill('[data-testid="email-input"]', 'user@example.com')
    await page.fill('[data-testid="password-input"]', '123')  // Too short
    await page.click('[data-testid="login-button"]')
    
    // ASSERT: Password error
    const error = page.locator('[data-testid="password-error"]')
    await expect(error).toBeVisible()
    await expect(error).toContainText('at least 8 characters')
  })
})
```

**Key patterns:**
- `test.describe()` groups related tests
- One assertion per test (clear failure cause)
- Test error conditions explicitly
- Validate error messages match requirements

**Why this pattern:**
- Each test is independent (can run in any order)
- Clear what passes and what fails
- New developers understand all scenarios
- Easy to add new validation cases

---

## Example 3: Using Fixtures (Pre-created Test User)

**What this shows:** Authentication fixture, reusable setup/teardown, session management

**Fixture definition** (in your `fixtures.ts`):

```typescript
import { test as base } from '@playwright/test'
import { v4 as uuid } from 'uuid'

export const test = base.extend({
  // FIXTURE: Creates authenticated user
  authenticatedPage: async ({ page }, use) => {
    // SETUP: Create test user and log in
    const testEmail = `test-${uuid().slice(0, 8)}@example.com`
    const testPassword = 'TestPassword123'
    
    // Create user via API (faster than UI)
    const createResponse = await page.request.post('http://localhost:3001/api/users', {
      data: {
        email: testEmail,
        password: testPassword,
      }
    })
    expect(createResponse.ok()).toBeTruthy()
    
    // Log in
    await page.goto('/login')
    await page.fill('[data-testid="email-input"]', testEmail)
    await page.fill('[data-testid="password-input"]', testPassword)
    await page.click('[data-testid="login-button"]')
    
    // Wait for navigation to dashboard
    await page.waitForURL('/dashboard', { timeout: 5000 })
    
    // PROVIDE: Page is now authenticated
    await use(page)
    
    // CLEANUP: Log out and delete user (runs after test)
    const token = await page.evaluate(() => localStorage.getItem('authToken'))
    if (token) {
      await page.request.delete('http://localhost:3001/api/users/me', {
        headers: { Authorization: `Bearer ${token}` }
      })
    }
  }
})

export { expect }
```

**Using the fixture** (in your tests):

```typescript
import { test, expect } from '../fixtures'

test('authenticated user can view listings', async ({ authenticatedPage }) => {
  // ARRANGE: User already logged in via fixture
  
  // ACT: Navigate to listings page
  await authenticatedPage.goto('/listings')
  
  // ASSERT: Listings table is visible
  const table = authenticatedPage.locator('[data-testid="listings-table"]')
  await expect(table).toBeVisible()
})
```

**Key patterns:**
- Fixtures run BEFORE each test (setup)
- `await use(page)` pauses fixture to run test
- Code after `await use()` runs AFTER test (cleanup)
- Fixtures automatically handle cleanup even if test fails

**Why fixtures:**
- Reuse complex setup logic (no copy-paste)
- Automatic cleanup (no orphaned data)
- Clear test intent (fixture name says what's prepared)
- Tests are isolated (each gets fresh user)

---

## Example 4: Page Object Model (Reusable Components)

**What this shows:** DRY test code, maintainability, semantic wrapper around selectors

**Define a POM class** (in `pom/ListingsPage.ts`):

```typescript
import { Page, Locator, expect } from '@playwright/test'

export class ListingsPage {
  readonly page: Page
  readonly header: Locator
  readonly listingsTable: Locator
  readonly createButton: Locator
  readonly emptyState: Locator
  readonly loadingSpinner: Locator

  constructor(page: Page) {
    this.page = page
    this.header = page.locator('[data-testid="page-header"]')
    this.listingsTable = page.locator('[data-testid="listings-table"]')
    this.createButton = page.locator('[data-testid="create-listing-button"]')
    this.emptyState = page.locator('[data-testid="empty-listings-state"]')
    this.loadingSpinner = page.locator('[data-testid="loading-spinner"]')
  }

  // SEMANTIC METHOD: Go to listings page
  async goto() {
    await this.page.goto('/listings')
    await this.page.waitForLoadState('networkidle')
  }

  // SEMANTIC METHOD: Wait for content to load
  async waitForListingsLoaded() {
    await this.listingsTable.or(this.emptyState).waitFor({ state: 'visible' })
  }

  // SEMANTIC METHOD: Get row count
  async getListingCount(): Promise<number> {
    await this.waitForListingsLoaded()
    const rows = await this.listingsTable.locator('tbody tr').count()
    return rows
  }

  // SEMANTIC METHOD: Click listing row
  async clickListing(index: number) {
    const rows = this.listingsTable.locator('tbody tr')
    await rows.nth(index).click()
  }

  // SEMANTIC METHOD: Assert empty state shown
  async assertEmpty() {
    await expect(this.emptyState).toBeVisible()
  }

  // SEMANTIC METHOD: Assert table visible with data
  async assertHasListings() {
    await expect(this.listingsTable).toBeVisible()
    const count = await this.getListingCount()
    expect(count).toBeGreaterThan(0)
  }
}
```

**Use the POM in tests**:

```typescript
import { test, expect } from '../fixtures'
import { ListingsPage } from '../pom/ListingsPage'

test('listings page shows table when user has listings', async ({ authenticatedPage }) => {
  // ARRANGE: Create page object
  const listingsPage = new ListingsPage(authenticatedPage)
  
  // ACT: Go to listings
  await listingsPage.goto()
  
  // ASSERT: Table is visible
  await listingsPage.assertHasListings()
})

test('listings page shows empty state when no listings', async ({ authenticatedPage }) => {
  // ARRANGE: Page object for clean listing user
  const listingsPage = new ListingsPage(authenticatedPage)
  
  // ACT: Go to listings
  await listingsPage.goto()
  
  // ASSERT: Empty state
  await listingsPage.assertEmpty()
})
```

**Key patterns:**
- One semantic method per user action
- Methods return meaningful data (count, messages)
- Selectors hidden in POM (not in tests)
- Tests read like user stories

**Why POMs:**
- Test code is clean and readable
- Selector changes only update POM (not all tests)
- Reuse across multiple tests
- New developers understand intent immediately

---

## Example 5: Complex Multi-Step Workflow

**What this shows:** Chaining actions, waiting for side effects, progressive assertions

```typescript
import { test, expect } from '../fixtures'
import { ListingsPage } from '../pom/ListingsPage'
import { CreateListingModal } from '../pom/CreateListingModal'

test('user can create and verify listing appears in table', async ({ authenticatedPage }) => {
  // ARRANGE
  const listingsPage = new ListingsPage(authenticatedPage)
  const createModal = new CreateListingModal(authenticatedPage)
  
  // Navigate to listings
  await listingsPage.goto()
  const countBefore = await listingsPage.getListingCount()
  
  // ACT: Step 1 — Open create modal
  await listingsPage.createButton.click()
  await createModal.waitForOpen()
  
  // ACT: Step 2 — Fill form
  const testTitle = `Test Listing ${Date.now()}`
  await createModal.fillTitle(testTitle)
  await createModal.fillDescription('Test description')
  await createModal.fillPrice('99.99')
  
  // ACT: Step 3 — Submit form
  await createModal.submit()
  
  // ASSERT: Modal closes (side effect of successful submission)
  await createModal.waitForClosed()
  
  // ASSERT: Table reloads with new listing
  const countAfter = await listingsPage.getListingCount()
  expect(countAfter).toBe(countBefore + 1)
  
  // ASSERT: New listing appears in table
  const newRow = listingsPage.listingsTable.locator(`text=${testTitle}`)
  await expect(newRow).toBeVisible()
})
```

**Key patterns:**
- Progressive assertions (one per logical step)
- Wait for side effects (modal close, table refresh)
- Use semantic data (title, not just counting rows)
- Comments mark logical steps (Arrange, Act, Assert)

**Why this works:**
- Clear cause-and-effect (if modal doesn't close, test fails there)
- Easier to debug (know exactly which step failed)
- Realistic flow (multiple actions, not just one)

---

## Example 6: Error Recovery (Network Issues, Timeouts)

**What this shows:** Graceful handling of errors, retry logic, error messaging

```typescript
import { test, expect } from '../fixtures'

test('shows retry button when API times out', async ({ page }) => {
  // ARRANGE
  await page.goto('/listings')
  
  // ACT: Simulate slow API by waiting before response
  await page.route('**/api/listings', async (route) => {
    // Wait 15 seconds (longer than Playwright's default 10s)
    await new Promise(resolve => setTimeout(resolve, 15000))
    await route.continue()
  })
  
  // Trigger API call
  await page.click('[data-testid="reload-button"]')
  
  // ASSERT: Timeout message appears
  const timeoutMessage = page.locator('[data-testid="timeout-message"]')
  await expect(timeoutMessage).toBeVisible({ timeout: 15000 })
  
  // ASSERT: Retry button is present
  const retryButton = page.locator('[data-testid="retry-button"]')
  await expect(retryButton).toBeVisible()
})

test('retries successfully after timeout', async ({ page }) => {
  // ARRANGE: Set up route with eventual success
  let attemptCount = 0
  
  await page.route('**/api/listings', async (route) => {
    attemptCount++
    
    if (attemptCount === 1) {
      // First attempt: timeout
      await new Promise(resolve => setTimeout(resolve, 15000))
    }
    
    // Second attempt: success
    await route.continue()
  })
  
  // ACT: Trigger reload (will timeout)
  await page.goto('/listings')
  await page.click('[data-testid="reload-button"]')
  
  // Wait for timeout message
  const timeoutMessage = page.locator('[data-testid="timeout-message"]')
  await expect(timeoutMessage).toBeVisible({ timeout: 15000 })
  
  // Click retry
  await page.click('[data-testid="retry-button"]')
  
  // ASSERT: Data loads successfully
  const listingsTable = page.locator('[data-testid="listings-table"]')
  await expect(listingsTable).toBeVisible({ timeout: 10000 })
})
```

**Key patterns:**
- Route interception for API mocking
- Test both error and recovery paths
- Explicit long timeouts for async waits
- Verify user-facing error messages

**Why error tests:**
- Users will encounter errors in production
- Tests verify graceful degradation
- Error messages are part of UX

---

## Example 7: Data-Driven Tests (Multiple Scenarios)

**What this shows:** Parameterized tests, reusing test logic, reducing duplication

```typescript
import { test, expect } from '../fixtures'

// Test data: different inputs with expected outcomes
const validationCases = [
  {
    input: { email: '', password: 'valid123' },
    errorField: 'email',
    errorText: 'Email is required'
  },
  {
    input: { email: 'invalid-email', password: 'valid123' },
    errorField: 'email',
    errorText: 'Invalid email format'
  },
  {
    input: { email: 'user@example.com', password: '' },
    errorField: 'password',
    errorText: 'Password is required'
  },
  {
    input: { email: 'user@example.com', password: '12345' },
    errorField: 'password',
    errorText: 'at least 8 characters'
  }
]

validationCases.forEach(({ input, errorField, errorText }) => {
  test(`should show "${errorText}" when ${errorField} is "${input[errorField]}"`, async ({ page }) => {
    // ARRANGE
    await page.goto('/login')
    
    // ACT: Fill form with test data
    if (input.email) await page.fill('[data-testid="email-input"]', input.email)
    if (input.password) await page.fill('[data-testid="password-input"]', input.password)
    await page.click('[data-testid="login-button"]')
    
    // ASSERT: Error appears
    const error = page.locator(`[data-testid="${errorField}-error"]`)
    await expect(error).toBeVisible()
    await expect(error).toContainText(errorText)
  })
})
```

**Key patterns:**
- Array of test cases with expected outcomes
- Single test logic, parameterized inputs
- Test names generated from data
- Reduces code duplication

**Why data-driven:**
- Add new cases by adding array element
- Easy to see all scenarios at once
- Less copy-paste code (maintainable)

---

## Example 8: Accessibility Testing (Keyboard Navigation)

**What this shows:** Testing keyboard interaction, focus management, screen reader labels

```typescript
import { test, expect } from '../fixtures'

test('form is keyboard accessible (Tab through fields)', async ({ page }) => {
  // ARRANGE
  await page.goto('/login')
  
  // ACT: Use Tab to navigate through form
  await page.press('body', 'Tab')  // Focus email input
  const emailInput = page.locator('[data-testid="email-input"]')
  await expect(emailInput).toBeFocused()
  
  // ACT: Type email
  await page.keyboard.type('user@example.com')
  
  // ACT: Tab to password field
  await page.press('body', 'Tab')
  const passwordInput = page.locator('[data-testid="password-input"]')
  await expect(passwordInput).toBeFocused()
  
  // ACT: Type password
  await page.keyboard.type('password123')
  
  // ACT: Tab to submit button
  await page.press('body', 'Tab')
  const submitButton = page.locator('[data-testid="login-button"]')
  await expect(submitButton).toBeFocused()
  
  // ACT: Press Enter to submit
  await page.press('body', 'Enter')
  
  // ASSERT: Form submitted (same as click)
  await expect(page).toHaveURL(/dashboard/)
})

test('error messages are linked to form fields (a11y)', async ({ page }) => {
  // ARRANGE: Check form field has aria-describedby
  await page.goto('/login')
  
  // ACT: Submit empty form to trigger error
  await page.click('[data-testid="login-button"]')
  
  // ASSERT: Email input has aria-describedby pointing to error
  const emailInput = page.locator('[data-testid="email-input"]')
  const errorId = await emailInput.getAttribute('aria-describedby')
  expect(errorId).toBeTruthy()
  
  // ASSERT: Error element has matching id
  const errorElement = page.locator(`#${errorId}`)
  await expect(errorElement).toContainText('Email is required')
})
```

**Key patterns:**
- Test keyboard navigation (Tab, Enter)
- Verify focus management
- Check ARIA attributes (aria-describedby, aria-label)
- Keyboard should work as well as mouse

**Why accessibility:**
- 1 in 4 users have disabilities
- Keyboard users rely on focus management
- Screen readers need proper labels
- Accessible code is better code

---

## Example 9: Performance / Load Testing (Basic)

**What this shows:** Measuring performance, detecting regressions, timing critical paths

```typescript
import { test, expect } from '../fixtures'

test('dashboard loads within 3 seconds', async ({ authenticatedPage }) => {
  // ARRANGE
  const startTime = Date.now()
  
  // ACT: Navigate to dashboard
  await authenticatedPage.goto('/dashboard')
  
  // ASSERT: Page title visible (page is interactive)
  const title = authenticatedPage.locator('[data-testid="page-title"]')
  await expect(title).toBeVisible()
  
  // ASSERT: Total time < 3 seconds
  const elapsed = Date.now() - startTime
  expect(elapsed).toBeLessThan(3000)
})

test('listing table renders within 2 seconds of API response', async ({ authenticatedPage }) => {
  // ARRANGE
  let apiResponseTime = 0
  
  await authenticatedPage.route('**/api/listings', async (route) => {
    const start = Date.now()
    await route.continue()
    apiResponseTime = Date.now() - start
  })
  
  // ACT
  await authenticatedPage.goto('/listings')
  
  // ASSERT: Table appears quickly after API response
  const startRender = Date.now()
  const table = authenticatedPage.locator('[data-testid="listings-table"]')
  await expect(table).toBeVisible()
  const renderTime = Date.now() - startRender
  
  // Should render within 1 second of API response
  expect(renderTime).toBeLessThan(1000)
})
```

**Key patterns:**
- Use Date.now() for timing
- Assert performance within expected bounds
- Route interception to measure API speed
- Test both load and render performance

**Why performance tests:**
- Slow pages hurt user experience
- Detects regressions early
- Verifies optimization efforts work
- Part of quality assurance

---

## Best Practices Summary

### DO ✅

- **One assertion per test** → Clear failure cause
- **Use semantic locators** (getByRole > getByLabel > getByText)
- **Use fixtures** for setup/teardown
- **Use UUID test data** (`uuid()`) not `Date.now()`
- **Explicit waits** for async operations
- **Test user workflows** not implementation
- **Use data-testid** only as last resort
- **Group with test.describe()** for organization
- **Copy code examples** and customize them

### DON'T ❌

- **Multiple assertions per test** → Multiple failure causes
- **CSS selectors** or XPath
- **Hardcoded test data** (collisions when parallel)
- **Implicit waits** (rely on defaults)
- **Test implementation** (test the UI users see)
- **Hardcode selectors** (use POMs instead)
- **Dependency between tests** (test order matters)
- **Mock everything** (integration tests matter)
- **Skip error cases** (users hit errors in production)

---

## Real Test File Template

Copy this to start a new test file:

```typescript
import { test, expect } from '../fixtures'
import { YourPagePOM } from '../pom/YourPagePOM'

test.describe('Feature Name', () => {
  test('should do something when condition is met', async ({ authenticatedPage }) => {
    // ARRANGE
    const page = new YourPagePOM(authenticatedPage)
    await page.goto()
    
    // ACT
    await page.someAction()
    
    // ASSERT
    await page.assertSomething()
  })

  test('should handle error gracefully', async ({ authenticatedPage }) => {
    // ARRANGE
    const page = new YourPagePOM(authenticatedPage)
    await page.goto()
    
    // ACT
    await page.triggerError()
    
    // ASSERT
    await page.assertErrorShown()
  })
})
```

---

## Learning Path

### Start Here (Beginner)
1. **Example 1** — Simple login test
2. **Example 2** — Form validation
3. **Example 3** — Using fixtures

### Intermediate
4. **Example 4** — Page Object Model
5. **Example 5** — Multi-step workflow
6. **Example 7** — Data-driven tests

### Advanced
7. **Example 6** — Error recovery
8. **Example 8** — Accessibility
9. **Example 9** — Performance

---

## Testing Checklist

Before committing a test:

- [ ] Test passes consistently (run 5x)
- [ ] Uses semantic locators
- [ ] Has proper cleanup (via fixture)
- [ ] One assertion (or grouped logically)
- [ ] Clear, descriptive name
- [ ] Comments explain "why" not "what"
- [ ] No dependencies on other tests
- [ ] No hardcoded waits (use explicit waits)
- [ ] Uses UUID test data (not Date.now())
- [ ] Error cases covered

---

## Questions?

- **"How do I test login?"** → See Example 1 + Example 3
- **"How do I test a form?"** → See Example 2
- **"How do I avoid repeating code?"** → See Example 4 (POM) + Example 7 (data-driven)
- **"How do I test errors?"** → See Example 6
- **"Is my test accessible?"** → See Example 8
- **"Will my test be slow?"** → See Example 9

---

**Last Updated:** 2026-06-10  
**All examples tested and working** ✅
