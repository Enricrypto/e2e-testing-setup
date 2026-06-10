/**
 * Global Test Teardown
 *
 * Runs ONCE after ALL tests complete in the entire test suite.
 *
 * Use global-teardown for:
 * - Cleanup after all tests (reset database, stop services)
 * - Collect final reports
 * - Archive logs/videos
 * - Health check summary
 *
 * DO NOT use for:
 * - Per-test cleanup (use fixtures instead)
 * - Deleting test-specific data (use fixtures)
 *
 * Learn more: https://playwright.dev/docs/test-global-setup-teardown
 */

/**
 * Main global teardown function
 * Called once after all tests complete
 */
async function globalTeardown() {
  console.log('\n🧹 Global Teardown Starting...')

  try {
    // Step 1: Clean up test database
    await cleanupTestDatabase()

    // Step 2: Generate summary
    await generateTestSummary()

    console.log('✅ Global Teardown Complete\n')
  } catch (error) {
    console.error('❌ Global Teardown Error:', error)
    // Don't exit(1) - teardown errors shouldn't fail the test run
    // (tests already completed)
  }
}

/**
 * Clean up test database
 * Reset to clean state for next test run
 */
async function cleanupTestDatabase() {
  const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
  const DB_RESET_URL = `${BACKEND_URL}/test/reset-database`

  console.log('🔄 Cleaning up test database...')

  try {
    const response = await fetch(DB_RESET_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    })

    if (response.ok) {
      console.log('✓ Test database cleaned up')
    } else if (response.status === 404) {
      console.log('⚠ Reset endpoint not found (might not be implemented)')
    } else {
      console.warn(`⚠ Cleanup returned ${response.status}`)
    }
  } catch (error) {
    console.warn('⚠ Could not cleanup test database:', error)
  }
}

/**
 * Generate test summary
 * Called after all tests complete
 */
async function generateTestSummary() {
  console.log('📊 Test Summary Generated')
  console.log('   Check test-results/ for:')
  console.log('   - HTML report (open with browser)')
  console.log('   - JSON results (for CI integration)')
  console.log('   - Videos/screenshots of failures')
}

export default globalTeardown

/**
 * Global Teardown Best Practices
 *
 * ✓ DO:
 * - Clean up test data (so next run is fresh)
 * - Stop any services you started
 * - Archive important logs/reports
 * - Log summary information
 * - Continue even if cleanup fails
 *
 * ✗ DON'T:
 * - Delete test reports before archiving
 * - Fail the entire test run (tests already completed)
 * - Delete user files (only test-specific data)
 * - Use setTimeout for waits (use proper async/await)
 * - Assume backend is running (wrap in try/catch)
 *
 * Configuration:
 * In playwright.config.ts:
 * ```
 * export default defineConfig({
 *   globalTeardown: './e2e/global-teardown.ts',
 * })
 * ```
 */
