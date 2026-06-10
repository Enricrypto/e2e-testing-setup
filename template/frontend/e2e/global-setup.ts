/**
 * Global Test Setup
 *
 * Runs ONCE before ALL tests in the entire test suite.
 *
 * Use global-setup for:
 * - Database initialization
 * - Creating seed test data
 * - Starting external services
 * - Verifying test environment is ready
 *
 * DO NOT use for:
 * - Per-test setup (use fixtures instead)
 * - Creating test-specific users (use fixtures)
 * - Logging in (use fixtures)
 *
 * Learn more: https://playwright.dev/docs/test-global-setup-teardown
 */

/**
 * Main global setup function
 * Called once before all tests
 */
async function globalSetup() {
  console.log('🚀 Global Setup Starting...')

  try {
    // Step 1: Verify backend is reachable
    await verifyBackendIsReady()

    // Step 2: Initialize test database
    await initializeTestDatabase()

    // Step 3: Seed test data (optional)
    // await seedTestData()

    console.log('✅ Global Setup Complete')
  } catch (error) {
    console.error('❌ Global Setup Failed:', error)
    process.exit(1)
  }
}

/**
 * Verify backend is running and reachable
 * This ensures tests don't fail due to missing backend
 */
async function verifyBackendIsReady() {
  const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
  const HEALTH_CHECK_URL = `${BACKEND_URL}/health`
  const MAX_RETRIES = 30
  const RETRY_DELAY = 1000 // 1 second

  console.log(`📡 Checking backend at ${HEALTH_CHECK_URL}...`)

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      const response = await fetch(HEALTH_CHECK_URL, { timeout: 5000 })
      if (response.ok) {
        console.log(`✓ Backend is ready (${response.status})`)
        return
      }
    } catch (error) {
      // Continue to next retry
    }

    if (attempt < MAX_RETRIES) {
      console.log(`⏳ Attempt ${attempt}/${MAX_RETRIES}: Waiting for backend...`)
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY))
    }
  }

  throw new Error(`Backend not ready after ${MAX_RETRIES} attempts at ${HEALTH_CHECK_URL}`)
}

/**
 * Initialize test database
 * Call your backend's database reset endpoint or script
 */
async function initializeTestDatabase() {
  const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'
  const DB_RESET_URL = `${BACKEND_URL}/test/reset-database`

  console.log('🔄 Resetting test database...')

  try {
    const response = await fetch(DB_RESET_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    })

    if (response.ok) {
      console.log('✓ Test database reset')
    } else {
      console.warn(`⚠ Database reset returned ${response.status} (may be expected)`)
    }
  } catch (error) {
    // This is optional - if your backend doesn't have a reset endpoint,
    // just log a warning and continue
    console.warn('⚠ Could not reset test database (endpoint not found or disabled)')
    console.warn('  If tests fail due to stale data, implement a reset endpoint')
  }
}

/**
 * Seed test data (optional)
 * Create baseline test accounts, listings, etc.
 */
async function seedTestData() {
  const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'

  console.log('🌱 Seeding test data...')

  try {
    // Example: Create test advertiser account
    const response = await fetch(`${BACKEND_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'advertiser@test.com',
        password: 'TempPassword123!',
        name: 'Test Advertiser',
        role: 'advertiser',
      }),
    })

    if (response.ok) {
      console.log('✓ Created test advertiser account')
    } else if (response.status === 409) {
      // Account already exists
      console.log('✓ Test advertiser account already exists')
    } else {
      console.warn(`⚠ Failed to seed test data: ${response.status}`)
    }
  } catch (error) {
    console.warn('⚠ Could not seed test data:', error)
    console.warn('  Tests may need to create their own data')
  }
}

export default globalSetup

/**
 * Global Setup Best Practices
 *
 * ✓ DO:
 * - Verify external dependencies are ready
 * - Initialize database (drop/recreate tables)
 * - Seed baseline data (test accounts, admin users)
 * - Check file system is writable (for logs, screenshots)
 * - Run once and let it complete (don't fail fast)
 *
 * ✗ DON'T:
 * - Create test-specific data (use fixtures)
 * - Login or authenticate (use fixtures)
 * - Make assumptions about test data (seed broadly)
 * - Fail if endpoint returns 404 (might be expected)
 * - Use setTimeout for delays (use proper waits)
 *
 * Configuration:
 * In playwright.config.ts:
 * ```
 * export default defineConfig({
 *   globalSetup: './e2e/global-setup.ts',
 * })
 * ```
 */
