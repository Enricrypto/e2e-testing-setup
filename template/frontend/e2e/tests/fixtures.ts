/**
 * Shared Test Fixtures
 *
 * Fixtures provide reusable test setup and teardown logic.
 * They run before each test and clean up after, ensuring test isolation.
 *
 * Learn more: https://playwright.dev/docs/test-fixtures
 */

import { test as base, expect, Page } from '@playwright/test'
import { BACKEND_API_URL } from '../playwright.config'

/**
 * API Helper - Makes requests to the backend
 *
 * Usage in tests:
 * ```
 * test('create listing', async ({ apiClient }) => {
 *   const result = await apiClient.post('/listings', { title: 'Test' })
 *   expect(result.status).toBe(201)
 * })
 * ```
 */
class APIClient {
  constructor(private baseURL: string) {}

  async post(path: string, data: Record<string, unknown>, options?: { headers?: Record<string, string> }) {
    const response = await fetch(`${this.baseURL}${path}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
      body: JSON.stringify(data),
    })
    return {
      status: response.status,
      body: await response.json(),
      response,
    }
  }

  async get(path: string, options?: { headers?: Record<string, string> }) {
    const response = await fetch(`${this.baseURL}${path}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    })
    return {
      status: response.status,
      body: await response.json(),
      response,
    }
  }

  async delete(path: string, options?: { headers?: Record<string, string> }) {
    const response = await fetch(`${this.baseURL}${path}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    })
    return {
      status: response.status,
      body: await response.json().catch(() => null),
      response,
    }
  }
}

/**
 * Test User Fixture
 *
 * Creates a test user account before each test and deletes it after.
 * Ensures clean isolation between tests.
 *
 * Usage:
 * ```
 * test('user can login', async ({ testUser, page }) => {
 *   await page.goto('/login')
 *   await page.fill('[data-testid="email"]', testUser.email)
 *   await page.fill('[data-testid="password"]', testUser.password)
 *   await page.click('button[type="submit"]')
 * })
 * ```
 */
interface TestUser {
  id: string
  email: string
  password: string
  name: string
}

/**
 * Authenticated Session Fixture
 *
 * Logs in a test user and maintains the auth session.
 * Useful for tests that require authentication.
 *
 * Usage:
 * ```
 * test('authenticated user can view dashboard', async ({ authenticatedPage }) => {
 *   await authenticatedPage.goto('/dashboard')
 *   await expect(authenticatedPage.locator('[data-testid="greeting"]')).toContainText('Welcome')
 * })
 * ```
 */

/**
 * Extend base test with custom fixtures
 */
export const test = base.extend<{
  apiClient: APIClient
  testUser: TestUser
  authenticatedPage: Page
}>({
  /**
   * API Client Fixture
   * Provides HTTP methods for backend communication
   */
  apiClient: async ({}, use) => {
    const client = new APIClient(BACKEND_API_URL)
    await use(client)
    // Cleanup: No cleanup needed for API client
  },

  /**
   * Test User Fixture
   * Creates a unique test user before test, deletes after
   */
  testUser: async ({ apiClient }, use) => {
    // SETUP: Create test user via API
    const randomId = Math.random().toString(36).substring(7)
    const testUser: TestUser = {
      id: randomId,
      email: `testuser-${randomId}@example.com`,
      password: 'TempPassword123!',
      name: `Test User ${randomId}`,
    }

    // Create user via API (adjust endpoint based on your backend)
    try {
      await apiClient.post('/auth/register', {
        email: testUser.email,
        password: testUser.password,
        name: testUser.name,
      })
    } catch (error) {
      console.warn('Failed to create test user:', error)
      // Continue anyway - test may handle this
    }

    // RUN TEST: Pass user to test
    await use(testUser)

    // TEARDOWN: Delete user after test
    try {
      await apiClient.delete(`/auth/users/${testUser.id}`)
    } catch (error) {
      console.warn('Failed to delete test user:', error)
      // Continue anyway - cleanup is best-effort
    }
  },

  /**
   * Authenticated Page Fixture
   * Logs in a test user and provides authenticated page
   */
  authenticatedPage: async ({ page, testUser, apiClient }, use) => {
    // SETUP: Login before test
    // Step 1: Get auth token from API
    let authToken = ''
    try {
      const result = await apiClient.post('/auth/login', {
        email: testUser.email,
        password: testUser.password,
      })
      if (result.status === 200 && result.body.token) {
        authToken = result.body.token
      }
    } catch (error) {
      console.warn('Failed to login:', error)
    }

    // Step 2: Set auth token in cookies or localStorage
    // (Adjust based on your auth implementation)
    if (authToken) {
      await page.context().addCookies([
        {
          name: 'authToken', // Adjust cookie name based on your app
          value: authToken,
          url: 'http://localhost:3000', // Adjust based on your FRONTEND_URL
          httpOnly: true,
        },
      ])
    }

    // RUN TEST: Pass authenticated page to test
    await use(page)

    // TEARDOWN: Logout/clear auth
    // Delete user via testUser fixture (runs after this)
  },
})

/**
 * Export expect for use in tests
 * Standard Playwright assertions
 */
export { expect }
