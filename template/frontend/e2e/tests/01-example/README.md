# Example E2E Test

This directory contains a working example E2E test that demonstrates all best practices.

## Files

- `example.spec.ts` — Example test with explanations
- `README.md` — This file

## How to Read the Example

Open `example.spec.ts` and read from top to bottom:

1. **Module comment** — Explains the test file's purpose
2. **Test groups** (`test.describe`)— How to organize tests
3. **Individual tests** — Each test shows a pattern
4. **Comments inside tests** — Step-by-step breakdown

## Key Patterns Demonstrated

### Pattern 1: Basic Navigation & Assertion
```typescript
test('should load homepage', async ({ page }) => {
  await page.goto('/')
  await expect(page.locator('[data-testid="page-title"]')).toBeVisible()
})
```

**Why this works:**
- `page.goto()` navigates to URL
- `[data-testid="..."]` targets stable selector (not class/id)
- `expect(...).toBeVisible()` waits for element + asserts

### Pattern 2: Form Interaction
```typescript
test('should fill and submit form', async ({ page }) => {
  await page.fill('[data-testid="input-name"]', 'Test User')
  await page.click('[data-testid="button-submit"]')
  await expect(page.locator('[data-testid="success-message"]')).toBeVisible()
})
```

**Why this works:**
- Form fields use `data-testid` for stability
- Click handler is on semantically correct element (button)
- Wait for success message = validate flow worked

### Pattern 3: Using Fixtures (Setup/Teardown)
```typescript
test('authenticated user can access dashboard', async ({ authenticatedPage, testUser }) => {
  await authenticatedPage.goto('/dashboard')
  await expect(authenticatedPage.locator('[data-testid="greeting"]')).toContainText(testUser.name)
})
```

**Why this works:**
- Fixture creates `testUser` before test
- Fixture logs in user (`authenticatedPage`)
- Test focuses on the workflow
- Fixture cleans up automatically after

### Pattern 4: API Calls
```typescript
test('can create item via API', async ({ apiClient }) => {
  const response = await apiClient.post('/items', { title: 'Test Item' })
  expect(response.status).toBe(201)
})
```

**Why this works:**
- `apiClient` fixture provides helper methods
- Tests both frontend AND backend in one flow
- Assertions are on response (easy to debug)

## Run the Example

### Run all example tests
```bash
npm run e2e -- --grep "example"
```

### Run in debug mode (step through)
```bash
npm run e2e -- --grep "example" --debug
```

### View the results
```bash
npx playwright show-report
```

## Adapt to Your Application

1. **Change URLs** — Replace `/` with your app's actual routes
2. **Change selectors** — Replace `[data-testid="page-title"]` with your actual `data-testid` values
3. **Change assertions** — Replace "Welcome" with actual text your app shows
4. **Change fixtures** — Update `testUser` creation to match your auth API
5. **Change API calls** — Update `/items` endpoint to match your actual API

### Checklist Before Copying

```
[ ] Does my app have data-testid on key elements?
    If not: Add data-testid to forms, buttons, messages (see docs/E2E_SEMANTIC_LOCATORS.md)

[ ] Does my app have a login flow?
    If not: Adapt authenticatedPage fixture to match your auth

[ ] Does my app have an API?
    If not: Remove apiClient tests or adapt to your backend

[ ] Does my app show success messages after actions?
    If not: Adjust success assertions to what your app actually shows
```

## Common Issues

### Test fails with "Timeout waiting for element"
- Element doesn't exist yet
- Selector is wrong
- See: docs/E2E_DEBUGGING.md → "Timeout waiting for element"

### Test passes locally but fails in CI
- Different backend URL
- Different test data
- See: docs/E2E_DOCKER_SETUP.md

### Test runs slow
- Too many waits
- Selector is inefficient
- See: docs/E2E_DEBUGGING.md → "Test is slow"

## Next Steps

1. **Read the example** — Open example.spec.ts and understand each pattern
2. **Run the example** — `npm run e2e -- --grep "example"`
3. **Debug failures** — Use `--debug` flag to step through
4. **Adapt to your app** — Copy patterns, change URLs/selectors
5. **Write your test** — Create `02-your-feature/your-feature.spec.ts`

## Related Documentation

- `docs/E2E_SEMANTIC_LOCATORS.md` — How to write stable selectors
- `docs/E2E_DEBUGGING.md` — How to debug failures
- `docs/E2E_DEEP_AUDIT_CHECKLIST.md` — Before writing tests
- `docs/E2E_PRODUCTION_READINESS.md` — Is your code ready for testing?
