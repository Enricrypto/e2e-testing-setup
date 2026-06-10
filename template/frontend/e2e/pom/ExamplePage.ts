/**
 * Example Page Object Model
 *
 * This file demonstrates how to extend BasePage for a specific page.
 * Copy this pattern for each page in your application.
 *
 * Usage:
 * ```
 * test('example page interaction', async ({ page }) => {
 *   const examplePage = new ExamplePage(page)
 *   await examplePage.navigate()
 *   await examplePage.fillForm('John', 'john@example.com')
 *   await examplePage.submitForm()
 *   await expect(examplePage.getSuccessMessage()).toBeVisible()
 * })
 * ```
 */

import { Page, Locator, expect } from '@playwright/test'
import { BasePage } from './BasePage'

/**
 * Example Page Object Model
 * Extends BasePage with example-specific methods
 */
export class ExamplePage extends BasePage {
  /**
   * Constructor
   * @param page — Playwright Page object
   */
  constructor(page: Page) {
    super(page)
  }

  /**
   * Navigate to example page
   */
  async navigate() {
    await super.navigate('/')
  }

  /**
   * Get page title element
   * @returns Locator for page title
   */
  getPageTitle(): Locator {
    return this.getLocator('[data-testid="page-title"]')
  }

  /**
   * Check if page title is visible
   * @returns true if visible
   */
  async isTitleVisible(): Promise<boolean> {
    return this.isVisible('[data-testid="page-title"]')
  }

  /**
   * Get page title text
   * @returns Title text
   */
  async getTitleText(): Promise<string> {
    return this.getText('[data-testid="page-title"]')
  }

  /**
   * Fill example form
   * @param name — User name
   * @param email — User email
   */
  async fillForm(name: string, email: string) {
    await this.fill('[data-testid="input-name"]', name)
    await this.fill('[data-testid="input-email"]', email)
  }

  /**
   * Submit example form
   */
  async submitForm() {
    await this.click('[data-testid="button-submit"]')
  }

  /**
   * Check if form is visible
   * @returns true if form visible
   */
  async isFormVisible(): Promise<boolean> {
    return this.isVisible('[data-testid="example-form"]')
  }

  /**
   * Get success message element
   * @returns Locator for success message
   */
  getSuccessMessage(): Locator {
    return this.getLocator('[data-testid="success-message"]')
  }

  /**
   * Wait for success message to appear
   * @param timeout — Timeout in ms
   */
  async waitForSuccessMessage(timeout: number = 5000) {
    await this.waitForElement('[data-testid="success-message"]', timeout)
  }

  /**
   * Get error message element
   * @returns Locator for error message
   */
  getErrorMessage(): Locator {
    return this.getLocator('[data-testid="error-message"]')
  }

  /**
   * Check if error message is visible
   * @returns true if error visible
   */
  async isErrorVisible(): Promise<boolean> {
    return this.isVisible('[data-testid="error-message"]')
  }

  /**
   * Get input field value
   * @param fieldTestId — data-testid of input field
   * @returns Input value
   */
  async getInputValue(fieldTestId: string): Promise<string | null> {
    return this.getAttribute(`[data-testid="${fieldTestId}"]`, 'value')
  }

  /**
   * Clear form (reset all fields)
   */
  async clearForm() {
    await this.clear('[data-testid="input-name"]')
    await this.clear('[data-testid="input-email"]')
  }

  /**
   * Check if submit button is enabled
   * @returns true if enabled
   */
  async isSubmitButtonEnabled(): Promise<boolean> {
    return this.isEnabled('[data-testid="button-submit"]')
  }

  /**
   * Fill form and submit (complete workflow)
   * @param name — User name
   * @param email — User email
   */
  async fillAndSubmit(name: string, email: string) {
    await this.fillForm(name, email)
    await this.submitForm()
    await this.waitForSuccessMessage()
  }
}

/**
 * Creating POM Classes - Step-by-Step
 *
 * 1. IDENTIFY PAGE ELEMENTS
 *    What data-testid elements does your page have?
 *    - [data-testid="page-title"]
 *    - [data-testid="form"]
 *    - [data-testid="input-name"]
 *    - [data-testid="button-submit"]
 *
 * 2. CREATE PAGE CLASS
 *    class YourPage extends BasePage {
 *      // Inherit all helpers from BasePage
 *    }
 *
 * 3. ADD PAGE-SPECIFIC METHODS
 *    These encapsulate user interactions:
 *    - async fillForm(name, email)
 *    - async submitForm()
 *    - async isSuccessVisible()
 *
 * 4. USE GETTERS FOR LOCATORS
 *    Return Locators for assertions in tests:
 *    - getSuccessMessage(): Locator
 *    - getTitleElement(): Locator
 *
 * 5. USE IN TESTS
 *    test('page interaction', async ({ page }) => {
 *      const yourPage = new YourPage(page)
 *      await yourPage.fillAndSubmit('name', 'email')
 *      await expect(yourPage.getSuccessMessage()).toBeVisible()
 *    })
 *
 * BENEFITS:
 * - Tests read like user workflows, not technical details
 * - Page selectors centralized (DRY principle)
 * - Easy to refactor when UI changes
 * - Reusable components across tests
 */
