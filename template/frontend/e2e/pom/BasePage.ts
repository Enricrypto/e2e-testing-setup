/**
 * Base Page Object Model (POM)
 *
 * The POM pattern encapsulates page-specific logic and selectors.
 * This base class provides common helpers that all pages inherit.
 *
 * Learn more: https://playwright.dev/docs/pom
 *
 * Usage:
 * ```
 * class LoginPage extends BasePage {
 *   async fillEmail(email: string) {
 *     await this.fill('[data-testid="email-input"]', email)
 *   }
 *
 *   async submit() {
 *     await this.click('[data-testid="submit-button"]')
 *   }
 * }
 *
 * test('user can login', async ({ page }) => {
 *   const loginPage = new LoginPage(page)
 *   await loginPage.navigate('/login')
 *   await loginPage.fillEmail('user@example.com')
 *   await loginPage.submit()
 * })
 * ```
 */

import { Page, Locator, expect } from '@playwright/test'

/**
 * Base Page Object Model
 * All page classes extend this to get common helpers
 */
export class BasePage {
  /**
   * Page instance (from Playwright test)
   * Access with: this.page
   */
  protected page: Page

  /**
   * Constructor
   * @param page — Playwright Page object
   */
  constructor(page: Page) {
    this.page = page
  }

  /**
   * Navigate to URL
   * @param path — URL path (e.g., '/login')
   */
  async navigate(path: string) {
    await this.page.goto(path)
  }

  /**
   * Fill input field
   * @param selector — Element selector with data-testid
   * @param value — Text to enter
   */
  async fill(selector: string, value: string) {
    await this.page.fill(selector, value)
  }

  /**
   * Click element
   * @param selector — Element selector
   */
  async click(selector: string) {
    await this.page.click(selector)
  }

  /**
   * Click and wait for navigation
   * @param selector — Element selector
   */
  async clickAndWaitForNavigation(selector: string) {
    await this.page.click(selector)
    await this.page.waitForLoadState('networkidle')
  }

  /**
   * Get locator for element
   * @param selector — Element selector
   * @returns Playwright Locator
   *
   * Usage:
   * ```
   * const element = await this.getLocator('[data-testid="title"]')
   * await expect(element).toBeVisible()
   * ```
   */
  getLocator(selector: string): Locator {
    return this.page.locator(selector)
  }

  /**
   * Get text content of element
   * @param selector — Element selector
   * @returns Element text
   */
  async getText(selector: string): Promise<string> {
    return this.page.locator(selector).textContent() || ''
  }

  /**
   * Get attribute value
   * @param selector — Element selector
   * @param attribute — Attribute name (e.g., 'href', 'value')
   * @returns Attribute value
   */
  async getAttribute(selector: string, attribute: string): Promise<string | null> {
    return this.page.locator(selector).getAttribute(attribute)
  }

  /**
   * Wait for element to be visible
   * @param selector — Element selector
   * @param timeout — Timeout in ms (default: 5000)
   */
  async waitForElement(selector: string, timeout: number = 5000) {
    await this.page.waitForSelector(selector, { timeout })
  }

  /**
   * Wait for element to disappear
   * @param selector — Element selector
   * @param timeout — Timeout in ms
   */
  async waitForElementToDisappear(selector: string, timeout: number = 5000) {
    await this.page.waitForSelector(selector, { state: 'hidden', timeout })
  }

  /**
   * Wait for navigation (e.g., after form submit)
   */
  async waitForNavigation() {
    await this.page.waitForLoadState('networkidle')
  }

  /**
   * Check if element is visible
   * @param selector — Element selector
   * @returns true if visible, false otherwise
   */
  async isVisible(selector: string): Promise<boolean> {
    return this.page.locator(selector).isVisible()
  }

  /**
   * Check if element is enabled
   * @param selector — Element selector
   * @returns true if enabled, false otherwise
   */
  async isEnabled(selector: string): Promise<boolean> {
    return this.page.locator(selector).isEnabled()
  }

  /**
   * Scroll element into view
   * @param selector — Element selector
   */
  async scrollIntoView(selector: string) {
    await this.page.locator(selector).scrollIntoViewIfNeeded()
  }

  /**
   * Select dropdown option
   * @param selector — Select element selector
   * @param value — Option value to select
   */
  async selectOption(selector: string, value: string) {
    await this.page.locator(selector).selectOption(value)
  }

  /**
   * Take screenshot
   * @param name — Screenshot filename (e.g., 'login-form')
   */
  async takeScreenshot(name: string) {
    await this.page.screenshot({ path: `./test-results/${name}.png` })
  }

  /**
   * Get current URL
   * @returns Current page URL
   */
  async getCurrentUrl(): Promise<string> {
    return this.page.url()
  }

  /**
   * Wait for function to return true
   * @param fn — Function to evaluate
   * @param timeout — Timeout in ms
   *
   * Usage:
   * ```
   * await this.waitForFunction(
   *   () => fetch('/api/status').then(r => r.ok),
   *   10000
   * )
   * ```
   */
  async waitForFunction(fn: () => Promise<boolean>, timeout: number = 5000) {
    const startTime = Date.now()
    while (Date.now() - startTime < timeout) {
      try {
        if (await fn()) {
          return true
        }
      } catch (error) {
        // Ignore errors while waiting
      }
      await this.page.waitForTimeout(100)
    }
    throw new Error(`Timeout waiting for function after ${timeout}ms`)
  }

  /**
   * Type text character by character (slower, more realistic)
   * @param selector — Element selector
   * @param text — Text to type
   */
  async type(selector: string, text: string) {
    await this.page.locator(selector).type(text)
  }

  /**
   * Press key
   * @param key — Key name (e.g., 'Enter', 'Escape', 'Tab')
   */
  async pressKey(key: string) {
    await this.page.keyboard.press(key)
  }

  /**
   * Clear input field
   * @param selector — Element selector
   */
  async clear(selector: string) {
    await this.page.locator(selector).clear()
  }

  /**
   * Check checkbox
   * @param selector — Checkbox selector
   */
  async check(selector: string) {
    await this.page.locator(selector).check()
  }

  /**
   * Uncheck checkbox
   * @param selector — Checkbox selector
   */
  async uncheck(selector: string) {
    await this.page.locator(selector).uncheck()
  }

  /**
   * Get page title
   * @returns Page title
   */
  async getTitle(): Promise<string> {
    return this.page.title()
  }

  /**
   * Reload page
   */
  async reload() {
    await this.page.reload()
  }
}

/**
 * BasePage Usage Guide
 *
 * 1. CREATE A PAGE CLASS
 * ```
 * class DashboardPage extends BasePage {
 *   async navigateToDashboard() {
 *     await this.navigate('/dashboard')
 *   }
 *
 *   async clickUserMenu() {
 *     await this.click('[data-testid="user-menu"]')
 *   }
 *
 *   async getUserGreeting() {
 *     return this.getText('[data-testid="greeting"]')
 *   }
 * }
 * ```
 *
 * 2. USE IN TEST
 * ```
 * test('user can access dashboard', async ({ page }) => {
 *   const dashboard = new DashboardPage(page)
 *   await dashboard.navigateToDashboard()
 *   const greeting = await dashboard.getUserGreeting()
 *   expect(greeting).toContain('Welcome')
 * })
 * ```
 *
 * BENEFITS OF POM:
 * - Selectors centralized (change once, works everywhere)
 * - Page logic encapsulated (page knows how to interact with itself)
 * - Tests read like user workflows (high level, clear intent)
 * - Easier to maintain (no selector changes in tests)
 */
