# Phase 8: Deep Test Audit Checklist

**When to use:** AFTER the pipeline generates tests (after Step 7)  
**What it does:** Verifies generated tests actually test real code  
**Why it matters:** Tests that don't match code catch nothing. False coverage is worse than no coverage.

---

## Why This Matters

Generated tests can:
- ✅ Use correct syntax
- ✅ Follow best practices
- ❌ Still test things that don't exist ("ghost features")
- ❌ Still have assertions that don't match actual code

This phase ensures your tests **actually verify real behavior**.

---

## Checklist: For Each Test

### Test 1: _______________

**What the test does:**
```
Arrange: _______________
Act: _______________
Assert: _______________
```

### Verify Assertion Accuracy

**Assertion in test:**
```typescript
await expect(page.getByText(/exact text here/i)).toBeVisible()
```

**Questions:**
- [ ] Does the app actually display this exact text?
- [ ] Is the text visible or hidden?
- [ ] Is the text dynamically generated (e.g., timestamp)?
- [ ] Does the selector match actual HTML structure?

**If assertion fails verification:**
- [ ] Fix the assertion to match actual app output
- [ ] Re-run the test
- [ ] Verify it passes

### Verify Test Data Realism

**Test data used:**
```
Email: _______________
Name: _______________
Amount: _______________
```

**Questions:**
- [ ] Does the data match real schema requirements?
- [ ] Is email in valid format?
- [ ] Is amount within valid range?
- [ ] Are required fields included?
- [ ] Does test data collide with other tests (UUID-based)?

**If test data is unrealistic:**
- [ ] Update to match actual validation rules
- [ ] Re-run the test
- [ ] Verify it still passes

### Verify Setup/Preconditions

**Test assumes:**
- [ ] User is authenticated
- [ ] User has required role
- [ ] Data exists in database
- [ ] Feature flag is enabled

**Questions:**
- [ ] Does fixture/setup actually create these preconditions?
- [ ] Are preconditions verified in the test?
- [ ] Could test fail if preconditions aren't met?

**If preconditions are wrong:**
- [ ] Update fixture/setup
- [ ] Re-run the test
- [ ] Verify it passes consistently

### Verify Cleanup

**Questions:**
- [ ] Does test have `test.afterEach` cleanup?
- [ ] Does cleanup remove created data?
- [ ] Does cleanup clear authentication?
- [ ] Can tests run in any order?

**If cleanup is missing:**
- [ ] Add `test.afterEach` block
- [ ] Cleanup created users/listings/data
- [ ] Clear JWT/session
- [ ] Re-run tests
- [ ] Verify they pass in random order

### Verify Semantic Locators

**Locators used in test:**
```typescript
page.getByRole('button', { name: /submit/i })  ✅
page.getByLabel(/email/i)                        ✅
page.getByText(/submit/i)                        ✅
page.locator('[data-testid="btn"]')              ❌ WRONG
page.locator('.button-class')                    ❌ WRONG
```

**Questions:**
- [ ] Are all locators semantic (getByRole/getByLabel/getByText)?
- [ ] Are there any data-testid locators?
- [ ] Are there any CSS class selectors?
- [ ] Are there any XPath selectors?

**If locators are wrong:**
- [ ] Replace with semantic locators
- [ ] Re-run the test
- [ ] Verify it passes

---

## Checklist: Happy Path Coverage

**Happy path flow:**
```
1. User starts at: _______________
2. User sees: _______________
3. User clicks: _______________
4. System processes
5. User sees success: _______________
```

**Questions:**
- [ ] Does a test verify each step?
- [ ] Does the test verify the success message/redirect?
- [ ] Could the happy path break without tests catching it?

**If happy path isn't covered:**
- [ ] Add test for the missing step
- [ ] Run the test
- [ ] Verify it passes

---

## Checklist: Error Scenario Coverage

**Error scenarios that can happen:**
```
Error: 401 Unauthorized
- [ ] Test exists
- [ ] Test verifies error message
- [ ] Test verifies user is logged out
- [ ] Test verifies redirect to login

Error: 403 Forbidden
- [ ] Test exists
- [ ] Test verifies permission message
- [ ] Test verifies user can't proceed

Error: Empty state (0 items)
- [ ] Test exists
- [ ] Test verifies "no data" message
- [ ] Test verifies appropriate UI state
```

**For each possible error:**
- [ ] Is there a test?
- [ ] Does it verify the error message?
- [ ] Does it verify the app's recovery behavior?

**If error coverage is missing:**
- [ ] Add tests for missing errors
- [ ] Run the tests
- [ ] Verify they all pass

---

## Checklist: Edge Case Coverage

**Edge cases that should work:**
```
Edge case: User with 0 items
- [ ] Test exists
- [ ] Test verifies empty state message
- [ ] Test verifies UI is still functional

Edge case: Very long input
- [ ] Test exists
- [ ] Test verifies input is truncated/wrapped
- [ ] Test verifies form still works

Edge case: Rapid clicking
- [ ] Test exists
- [ ] Test verifies no duplicate submissions
- [ ] Test verifies only one result
```

**For each edge case:**
- [ ] Is there a test?
- [ ] Does it verify the app handles it correctly?
- [ ] Does it verify no unintended side effects?

**If edge case coverage is missing:**
- [ ] Add tests for missing edge cases
- [ ] Run the tests
- [ ] Verify they all pass

---

## Checklist: No "Ghost Features"

**Ghost feature:** Test assumes something exists that doesn't

```typescript
❌ GHOST:
test('user can update listing title', async ({ page }) => {
  await page.fill('#title-edit', 'New Title')  // This field doesn't exist!
})

✅ REAL:
test('user can update listing title', async ({ page }) => {
  // Phase 0 verified this field exists at this selector
  await page.fill('[aria-label="Listing title"]', 'New Title')
})
```

**Questions:**
- [ ] Does every selector in the test correspond to actual HTML?
- [ ] Does every API call correspond to actual endpoint?
- [ ] Does every error message exist in the actual app?
- [ ] Does every success flow work in the actual browser?

**How to verify:**
1. Run the test in your browser
2. Does it actually find the elements?
3. Does it actually complete the flow?
4. Does the app actually respond as expected?

**If you find a ghost feature:**
- [ ] Remove the test or fix it to match actual code
- [ ] Re-run the test
- [ ] Verify it passes against real app

---

## Checklist: Test Independence

**Run tests in random order:**
```bash
npm run test:e2e:local -- --shard=1/1
```

**Questions:**
- [ ] Do all tests pass when run individually?
- [ ] Do all tests pass when run together?
- [ ] Do tests pass in random order?
- [ ] Does test order matter?

**If tests aren't independent:**
- [ ] Add cleanup to `test.afterEach`
- [ ] Remove global state between tests
- [ ] Use fixtures to create fresh state
- [ ] Re-run tests
- [ ] Verify they pass in random order

---

## Checklist: Timeout Realism

**Test timeouts in config:**
```typescript
actionTimeout: 5000   // local dev
navigationTimeout: 15000  // page loads
testTimeout: 30000    // entire test
```

**Questions:**
- [ ] Are timeouts appropriate for your environment?
- [ ] Do tests timeout locally but pass in CI?
- [ ] Are there any `await` statements without timeout?

**If timeouts are wrong:**
- [ ] Adjust in `playwright.config.ts`
- [ ] Re-run the tests
- [ ] Verify they pass consistently

---

## Checklist: All Tests Pass

```bash
npm run test:e2e:local
```

**Final verification:**
- [ ] All tests pass? ✅
- [ ] No flaky tests? ✅
- [ ] Errors are clear and actionable? ✅
- [ ] Coverage matches your Phase 0 audit? ✅

**If tests fail:**
- [ ] Read the error message carefully
- [ ] Identify the root cause (wrong selector? missing data? timing?)
- [ ] Fix the test or the test data
- [ ] Re-run
- [ ] Verify it passes

---

## What You'll Do Next

Once you've passed all checks:

1. **Commit the tests:**
   ```bash
   git add frontend/e2e/tests/
   git add frontend/e2e/pom/
   git commit -m "feat(e2e): Add [feature-name] tests (Phase 3 generated, Phase 8 audited)"
   ```

2. **Mark as complete** in your task/PR

3. **Optional: Set up CI** to run tests on every PR

---

## Quick Reference: Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "Element not found" | Wrong selector or element doesn't exist | Verify element in browser, use correct semantic locator |
| "Assertion failed" | Assertion doesn't match actual app output | Check what app actually displays, update assertion |
| "Test timeout" | Action takes too long | Increase timeout, or simplify test |
| "Flaky test" (passes/fails randomly) | Race condition or missing wait | Add explicit waits, ensure cleanup |
| "Tests fail in CI but pass locally" | Environment difference (timing, data, etc) | Use environment-specific timeouts, verify CI has same data |

---

**Remember:** This audit takes time, but catches 80% of test bugs before they hit the codebase.
