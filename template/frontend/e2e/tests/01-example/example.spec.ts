/**
 * Example E2E Test
 *
 * This test demonstrates best practices for E2E testing.
 *
 * Key patterns:
 * 1. Use data-testid for selectors (stable, intentional)
 * 2. Use fixtures for setup/teardown (clean isolation)
 * 3. Use semantic locators (meaningful assertions)
 * 4. Test user workflows (not implementation details)
 *
 * Run this test:
 *   npm run e2e -- --grep "example"
 *
 * Debug this test:
 *   npm run e2e -- --grep "example" --debug
 *
 * View results:
 *   npx playwright show-report
 */

import { test, expect } from '../fixtures'

/**
 * Example Test Group
 * Demonstrates complete testing patterns
 */
test.describe('Example Feature', () => {
  /**
   * Test 1: Navigate to home page
   * Demonstrates basic navigation and assertions
   */
  test('should load homepage', async ({ page }) => {
    // 1. Navigate to page
    await page.goto('/')

    // 2. Wait for expected element to appear
    await page.waitForSelector('[data-testid="page-title"]', { timeout: 5000 })

    // 3. Assert element exists and has expected text
    const title = page.locator('[data-testid="page-title"]')
    await expect(title).toBeVisible()
    await expect(title).toContainText('Welcome')
  })

  /**
   * Test 2: Interact with form
   * Demonstrates form input, submission, and validation
   */
  test('should fill and submit form', async ({ page }) => {
    // 1. Navigate to form page
    await page.goto('/form-example')

    // 2. Fill form fields using data-testid
    await page.fill('[data-testid="input-name"]', 'Test User')
    await page.fill('[data-testid="input-email"]', 'test@example.com')

    // 3. Submit form
    await page.click('[data-testid="button-submit"]')

    // 4. Wait for success message and assert
    const successMessage = page.locator('[data-testid="success-message"]')
    await expect(successMessage).toBeVisible({ timeout: 5000 })
    await expect(successMessage).toContainText('Success')
  })

  /**
   * Test 3: Test with fixtures (authenticated user)
   * Demonstrates using custom fixtures for setup/teardown
   */
  test('authenticated user can access dashboard', async ({ authenticatedPage, testUser }) => {
    // testUser was created by fixture before test
    // authenticatedPage has user logged in

    // 1. Navigate to protected page
    await authenticatedPage.goto('/dashboard')

    // 2. Assert user-specific content
    const greeting = authenticatedPage.locator('[data-testid="user-greeting"]')
    await expect(greeting).toContainText(testUser.name)

    // 3. Assert dashboard content loaded
    const dashboard = authenticatedPage.locator('[data-testid="dashboard-content"]')
    await expect(dashboard).toBeVisible()

    // After test completes:
    // - testUser fixture will delete the test user
    // - authenticatedPage session will be cleaned up
  })

  /**
   * Test 4: API calls within test
   * Demonstrates using apiClient fixture for backend communication
   */
  test('can create item via API', async ({ apiClient }) => {
    // 1. Create item via API
    const response = await apiClient.post('/items', {
      title: 'Test Item',
      description: 'This is a test',
    })

    // 2. Assert response
    expect(response.status).toBe(201)
    expect(response.body.id).toBeDefined()
    expect(response.body.title).toBe('Test Item')
  })

  /**
   * Test 5: Complex user workflow
   * Demonstrates multi-step user interactions
   */
  test('should complete user workflow', async ({ page, testUser }) => {
    // Step 1: Navigate to feature
    await page.goto('/feature')

    // Step 2: Trigger action
    await page.click('[data-testid="action-button"]')

    // Step 3: Verify modal appears
    const modal = page.locator('[data-testid="modal-dialog"]')
    await expect(modal).toBeVisible()

    // Step 4: Fill modal form
    await page.fill('[data-testid="modal-input"]', 'User input')

    // Step 5: Submit modal
    await page.click('[data-testid="modal-submit"]')

    // Step 6: Verify result
    await expect(modal).not.toBeVisible()
    const resultMessage = page.locator('[data-testid="result-message"]')
    await expect(resultMessage).toContainText('Complete')
  })
})

/**
 * Example Error Case Tests
 */
test.describe('Error Handling', () => {
  /**
   * Test: Handle missing element gracefully
   */
  test('should show error when required field is missing', async ({ page }) => {
    await page.goto('/form-example')

    // Try to submit without filling required field
    await page.click('[data-testid="button-submit"]')

    // Assert error message appears
    const errorMessage = page.locator('[data-testid="error-message"]')
    await expect(errorMessage).toBeVisible()
    await expect(errorMessage).toContainText('Required')
  })

  /**
   * Test: Handle API error
   */
  test('should handle API error gracefully', async ({ apiClient, page }) => {
    // Try to create item with invalid data
    const response = await apiClient.post('/items', {
      title: '', // Invalid: empty title
    })

    // Assert error response
    expect(response.status).toBe(400) // or appropriate error code
    expect(response.body.error).toBeDefined()
  })
})

/**
 * Test Organization Best Practices:
 *
 * 1. GROUP BY FEATURE
 *    test.describe('Feature Name', () => { ... })
 *    Groups related tests together
 *
 * 2. USE SEMANTIC NAMES
 *    test('should [user action] [expected result]', ...)
 *    Describes behavior, not implementation
 *
 * 3. USE DATA-TESTID
 *    page.locator('[data-testid="element-name"]')
 *    Stable selectors, resilient to styling changes
 *
 * 4. USE FIXTURES FOR SETUP
 *    async ({ testUser, authenticatedPage }) => { ... }
 *    Clean isolation, automatic cleanup
 *
 * 5. ASSERT VISIBILITY FIRST
 *    await expect(element).toBeVisible()
 *    Ensures element is ready before interaction
 *
 * 6. USE EXPLICIT WAITS
 *    await page.waitForSelector('[data-testid="..."]', { timeout: 5000 })
 *    Prevents timing issues
 *
 * 7. TEST USER WORKFLOWS
 *    Focus on: navigate → interact → verify
 *    Not on: implementation details
 *
 * Running tests:
 *   npm run e2e                    # Run all tests
 *   npm run e2e -- --grep example  # Run specific test
 *   npm run e2e -- --debug         # Step through with inspector
 *   npx playwright show-report     # View results
 */
