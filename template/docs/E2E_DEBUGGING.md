# E2E Test Debugging Guide

This guide helps you fix failing E2E tests quickly.

---

## Using Playwright Inspector

Step through your test line-by-line and inspect the DOM.

### Launch Inspector

```bash
npm run test:e2e -- --debug
```

Or for a specific test:

```bash
npm run test:e2e -- --grep "test name" --debug
```

### What You See

When Inspector opens:

1. **Browser window**: Your app running
2. **Inspector panel**: Shows test code and current line
3. **Actions**: Step, continue, pause buttons

### How to Use

1. **Step through test** — Click "Step" button to execute one line at a time
2. **Inspect DOM** — Right-click element in browser to inspect
3. **Try selectors** — Type selectors in Inspector to verify they work
4. **View page state** — See console logs, network requests, etc.

### Example Debugging Session

```bash
npm run test:e2e -- --grep "should submit form" --debug

# In Inspector:
# 1. Click "Step" → executes: await page.goto('/form')
# 2. See app loads in browser
# 3. Click "Step" → executes: await page.fill('[data-testid="email"]', 'test@example.com')
# 4. See email filled in browser
# 5. Right-click email input → Inspect
# 6. Verify [data-testid="email"] exists
# 7. Continue debugging until failure
```

---

## Reading Error Messages

### "Timeout waiting for element"

**Error:**
```
Error: Timeout 5000ms exceeded.
Waiting for selector '[data-testid="submit-button"]'
```

**Causes:**
1. Element doesn't exist
2. Selector is wrong
3. Element is hidden
4. Page didn't load yet

**Fix:**

1. **Check selector exists**
   ```bash
   npm run test:e2e -- --grep "test name" --debug
   # In Inspector, type in console:
   document.querySelector('[data-testid="submit-button"]')
   ```
   If returns `null`, element doesn't exist.

2. **Verify element is visible**
   ```typescript
   // Instead of:
   await page.click('[data-testid="submit-button"]')
   
   // Do this:
   await expect(page.locator('[data-testid="submit-button"]')).toBeVisible()
   await page.click('[data-testid="submit-button"]')
   ```

3. **Increase timeout if needed**
   ```typescript
   await page.waitForSelector('[data-testid="submit-button"]', { timeout: 10000 })
   await page.click('[data-testid="submit-button"]')
   ```

4. **Check actual HTML**
   - Open browser DevTools
   - Search for actual element name
   - Copy exact selector from HTML

---

### "Expected X, got Y"

**Error:**
```
Expected to contain: "Success"
Received: ""
```

**Causes:**
1. Page content doesn't match expectation
2. Text is slightly different (case, spacing)
3. Element hasn't loaded yet

**Fix:**

1. **Use flexible matching**
   ```typescript
   // Instead of:
   await expect(page.locator('[data-testid="message"]')).toContainText("Success")
   
   // More flexible:
   await expect(page.locator('[data-testid="message"]')).toContainText(/success/i)
   ```

2. **Wait for content**
   ```typescript
   await page.waitForFunction(() => {
     const msg = document.querySelector('[data-testid="message"]')
     return msg?.textContent?.includes('Success')
   })
   ```

3. **Check actual content**
   - View video of failed test
   - See what text is actually displayed
   - Update expectation to match reality

4. **Take screenshot before assertion**
   ```typescript
   await page.screenshot({ path: 'debug.png' })
   await expect(page.locator('[data-testid="message"]')).toContainText("Success")
   ```

---

### "Network error"

**Error:**
```
Error: net::ERR_CONNECTION_REFUSED
Failed to fetch from http://localhost:3001/api/listings
```

**Causes:**
1. Backend not running
2. Backend on wrong port
3. Firewall blocking connection
4. DNS issue

**Fix:**

1. **Check backend is running**
   ```bash
   curl http://localhost:3001/api/listings
   # If error, start backend
   npm run dev:backend
   ```

2. **Check BACKEND_URL in config**
   ```typescript
   // frontend/e2e/playwright.config.ts
   const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
   console.log('Backend URL:', BACKEND_URL)
   ```

3. **Check firewall**
   ```bash
   # macOS/Linux
   lsof -i :3001
   # Should show your backend process
   ```

4. **Check DNS**
   ```bash
   ping localhost
   # or
   nslookup localhost
   ```

---

## Video Playback

Videos show exactly what happened during test failure.

### View Video

1. Open HTML report:
   ```bash
   npx playwright show-report
   ```

2. Click on failed test

3. Scroll to "Video" section

4. Play video to see what went wrong

### What to Look For

- **Is element visible?** Can you see it on screen?
- **What's the text?** Compare to expectation
- **Is loading spinner visible?** Page might not be ready
- **Did navigation happen?** URL changed?
- **Error messages?** What does user see?

### Recording Settings

Control what gets recorded:

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    video: 'retain-on-failure',  // Only on failure
    // OR
    video: 'on',                 // Every test
    // OR
    video: 'off',                // Never
  },
})
```

---

## Trace Viewer

For deep debugging, use trace viewer:

```bash
npx playwright show-trace path/to/trace.zip
```

Traces show:
- Every action (click, type, goto)
- DOM state after each action
- Network requests
- Console logs

### Enable Traces

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    trace: 'retain-on-failure',
  },
})
```

### Use Traces to Debug

1. Open trace viewer
2. Step through test actions
3. At each step, inspect DOM
4. Find where test goes wrong
5. See exact page state when failure occurs

---

## Common Patterns

### Flaky Test (Sometimes Fails, Sometimes Passes)

**Symptom:** Test passes locally but fails in CI, or fails randomly

**Causes:**
1. Timing too tight
2. Missing wait for network
3. Missing wait for element
4. Race condition

**Fix:**

```typescript
// ❌ Don't do this:
await page.goto('/dashboard')
await expect(page.locator('text=Listings')).toBeVisible()

// ✓ Do this instead:
await page.goto('/dashboard')
await page.waitForLoadState('networkidle')  // Wait for network
await expect(page.locator('text=Listings')).toBeVisible()

// Or use explicit wait:
await page.waitForSelector('[data-testid="listings-loaded"]', { timeout: 5000 })
await expect(page.locator('text=Listings')).toBeVisible()
```

### Test Passes Locally but Fails in CI

**Causes:**
1. Different backend URL
2. Different test data
3. Slower network in CI
4. Missing environment variable

**Fix:**

1. **Check BACKEND_URL**
   ```bash
   echo $BACKEND_URL
   # Should be set in CI
   ```

2. **Check environment**
   ```bash
   # In CI workflow
   env:
     BACKEND_URL: http://localhost:5001
     TEST_ENV: ci
   ```

3. **Increase CI timeouts**
   ```typescript
   const config = process.env.CI ? {
     timeout: 60000,  // 60 seconds in CI
     navigationTimeout: 30000,
   } : {
     timeout: 30000,  // 30 seconds locally
   }
   ```

4. **Check test data exists**
   - Create test data in global-setup.ts
   - Use fixtures to create per-test data
   - Don't assume data from previous tests

### Test is Slow

**Causes:**
1. Unnecessary waits
2. Too many page loads
3. Complex selectors
4. Not using fixtures

**Fix:**

```typescript
// ❌ Slow - loads page twice:
await page.goto('/dashboard')
await page.waitForLoadState('load')
await page.reload()

// ✓ Fast - loads once:
await page.goto('/dashboard')
await page.waitForLoadState('networkidle')

// ❌ Slow - creates user manually:
await page.fill('[data-testid="email"]', 'user@example.com')
await page.fill('[data-testid="password"]', 'password123')
await page.click('button:has-text("Sign Up")')

// ✓ Fast - creates user via API:
const user = await createTestUser({ email: 'user@example.com' })
```

### Element Found but Not Clickable

**Error:**
```
Element is not visible or not clickable
```

**Causes:**
1. Element hidden behind modal
2. Element scrolled off screen
3. Element disabled
4. CSS `pointer-events: none`

**Fix:**

```typescript
// Scroll into view first
await page.locator('[data-testid="button"]').scrollIntoViewIfNeeded()
await page.click('[data-testid="button"]')

// Or force click
await page.click('[data-testid="button"]', { force: true })

// Check if disabled
const isDisabled = await page.locator('[data-testid="button"]').isDisabled()
if (isDisabled) {
  // Fix test logic - why is button disabled?
}
```

---

## Debugging Workflow

When a test fails:

1. **Run test in debug mode**
   ```bash
   npm run test:e2e -- --grep "failing test" --debug
   ```

2. **Step through test** — Find exact line where it fails

3. **Inspect DOM** — Right-click to see actual HTML

4. **Check console** — See any JavaScript errors

5. **Take screenshot** — See page state at failure

6. **Try selector** — Verify selector works in console

7. **Read error message** — Understand what expected vs actual

8. **Fix code or test** — Update test or app code

9. **Run again** — Verify fix works

10. **Commit** — Save working test

---

## Useful Commands

```bash
# Debug specific test
npm run test:e2e -- --grep "test name" --debug

# Show report
npx playwright show-report

# Show trace
npx playwright show-trace path/to/trace.zip

# List all tests
npm run test:e2e -- --list

# Run single test file
npm run test:e2e -- frontend/e2e/tests/01-example/example.spec.ts

# Run tests matching pattern
npm run test:e2e -- --grep "submit"

# Run with custom timeout
npm run test:e2e -- --timeout=60000
```

---

## Getting Help

When stuck:

1. **Check Playwright docs** — https://playwright.dev/docs/debug
2. **Read error carefully** — Usually points to exact problem
3. **Watch video** — See what actually happened
4. **Use Inspector** — Step through to find issue
5. **Check selector** — Verify element exists
6. **Increase timeout** — Sometimes just a timing issue

Remember: **Every test failure has a reason.** Find it, fix it, move forward.
