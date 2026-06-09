# Code Reading: Enforcement Guide for E2E Agents

**When to use:** Every time before Planner and Generator agents run  
**What it covers:** How to read code instead of guessing, with examples  
**Why it matters:** Tests built on assumptions fail. Tests built on actual code work.

---

## The Problem: Assumption-Based Testing

### ❌ What Fails

```
Planner assumes:
  "User clicks 'Save' button, API returns { success: true }"

Generator creates test expecting:
  await expect(response).toContain('success: true')

Tests pass locally

Deploy to production
  - API actually returns { success: true, id: 123 }
  - Response body changed but test still passes
  - Test caught nothing real
```

### ✅ What Works

```
Planner reads actual code:
  - Router file: GET /api/save exists ✓
  - Component: <button>Save</button> renders ✓
  - API response: { success: bool, id: string, timestamp: number } ✓

Generator verifies:
  - Creates test that checks actual response shape
  - Verifies button text matches exactly
  - Test catches real changes to API/component
```

---

## Code Reading: The Planner's Job

### Step 1: Read the Router/Route File

**Goal:** Verify the endpoint exists and understand auth/permissions

**What to read:**
```bash
# Find the route file (location varies by framework)
# Next.js
app/api/v1/listings/route.ts
app/api/v1/listings/[id]/route.ts

# Express
src/routes/listings.ts
src/routes/api/listings.ts

# Other frameworks
src/handlers/listings.ts
src/endpoints/listings.ts
```

**What to look for:**
```typescript
// ✓ Verify route exists
export async function GET(request: Request) {
  // ...
}

// ✓ Check auth protection
async function protectedRoute(req, res, next) {
  const user = await verifyAuth(req)  // ← Auth required
  if (!user) return res.status(401).json({ error: 'Unauthorized' })
  // ...
}

// ✓ Check role-based access
if (!user.roles.includes('advertiser')) {
  return res.status(403).json({ error: 'Forbidden' })
}
```

**Example output:**
```
Route: GET /api/v1/listings
  ✓ Exists in src/routes/listings.ts
  ✓ Auth required: via middleware verifyAuth()
  ✓ Role check: must be 'advertiser' or 'admin'
  ✓ Success response: HTTP 200
  ✓ Auth error: HTTP 401
  ✓ Permission error: HTTP 403
```

### Step 2: Read the Component File

**Goal:** Verify UI elements exist and their exact labels/text

**What to read:**
```bash
# Find the component
src/components/DashboardPage.tsx
src/components/dashboard/page.tsx
src/pages/dashboard.tsx
```

**What to look for:**
```typescript
// ✓ Verify heading exists and get exact text
<h1>My Listings</h1>  // Exact text: "My Listings"

// ✓ Verify button exists
<button onClick={handleCreate}>Create New</button>  // Text: "Create New"

// ✓ Check for hidden/conditional elements
{isLoading && <Spinner />}  // Shows during load
{listings.length === 0 && <p>No listings created yet</p>}  // Empty state

// ✓ Check for error display
{error && <ErrorAlert message={error} />}  // Error state

// ✓ Verify form fields
<input
  type="email"
  placeholder="your@email.com"
  required
  aria-label="Email address"
/>
```

**Example output:**
```
Component: DashboardPage.tsx
  ✓ Heading: "My Listings" (exact text)
  ✓ Button: "Create New" (role: button)
  ✓ Loading state: Shows <Spinner /> while loading
  ✓ Empty state: Text "No listings created yet"
  ✓ Error state: Shows error message in <ErrorAlert />
```

### Step 3: Read the API Endpoint File

**Goal:** Get exact response structure, not guesses

**What to read:**
```bash
# Find the endpoint handler
src/api/listings.ts
src/routes/api/listings.ts
src/pages/api/listings.ts
```

**What to look for:**
```typescript
// ✓ Get exact response structure
async function getListings(req, res) {
  const listings = await db.query(`
    SELECT id, title, description, status, created_at
    FROM listings
    WHERE advertiser_id = $1
  `, [req.user.id])
  
  return res.json({
    listings,
    total_count: listings.length,
    has_next: false  // Exact field names!
  })
}

// ✓ Check error responses
catch (error) {
  if (error.code === 'PERMISSION_DENIED') {
    return res.status(403).json({ error: 'Access denied' })
  }
  return res.status(500).json({ error: 'Server error' })
}
```

**Example output:**
```
Endpoint: GET /api/v1/listings
  ✓ Success response structure:
    {
      listings: [
        {
          id: "uuid",
          title: "string",
          description: "string",
          status: "active" | "inactive",
          created_at: "2024-01-01T12:00:00Z"
        }
      ],
      total_count: number,
      has_next: boolean
    }
  ✓ Error responses:
    401: { error: "Unauthorized" }
    403: { error: "Access denied" }
    500: { error: "Server error" }
```

### Step 4: Verify State Management

**Goal:** Understand how data flows through the component

**What to read:**
```typescript
// ✓ Check if using fetch, axios, or API client
const [listings, setListings] = useState([])
const [loading, setLoading] = useState(true)
const [error, setError] = useState(null)

useEffect(() => {
  fetch('/api/v1/listings')
    .then(r => r.json())
    .then(data => setListings(data.listings))  // ← Exact data structure
    .catch(err => setError(err.message))
    .finally(() => setLoading(false))
}, [])

// ✓ Check what's displayed at each state
if (loading) return <Spinner />
if (error) return <ErrorAlert error={error} />
if (!listings.length) return <EmptyState />
return <ListingsList items={listings} />
```

**Example output:**
```
State Management:
  ✓ Fetches from: /api/v1/listings
  ✓ Loading state: Shows <Spinner /> while true
  ✓ Error state: Shows error in <ErrorAlert />
  ✓ Empty state: Shows <EmptyState /> when listings.length === 0
  ✓ Success state: Renders <ListingsList items={listings} />
```

---

## Code Reading: The Generator's Job

### Code Verification Before Test Generation

**Goal:** Ensure API calls and selectors match actual code

#### Check 1: API Contract Verification

**Before writing test:**
```typescript
// ✓ Read actual endpoint response
// From src/api/listings.ts:
{
  listings: Listing[],
  total_count: number,
  has_next: boolean
}

// ✗ DON'T assume response shape
// ✗ DON'T use incomplete response structure
```

**In test:**
```typescript
// ✓ RIGHT: Uses actual response structure
const response = await fetch('/api/v1/listings')
const data = await response.json()
expect(data).toHaveProperty('listings')  // Matches actual response
expect(data).toHaveProperty('total_count')
expect(Array.isArray(data.listings)).toBe(true)

// ✗ WRONG: Assumed response doesn't have these fields
expect(response).toContain('success: true')  // Never in actual response
expect(data.count).toBeDefined()  // Field name is 'total_count', not 'count'
```

#### Check 2: Selector Verification

**Before writing test:**
```typescript
// ✓ Read actual component JSX
// From src/components/DashboardPage.tsx:
<h1>My Listings</h1>

// ✓ Read actual button
<button onClick={handleCreate}>Create New</button>

// ✗ DON'T assume selector patterns
// ✗ DON'T use data-testid without verifying it exists
```

**In test:**
```typescript
// ✓ RIGHT: Verified from actual code
await expect(page.getByRole('heading', { name: 'My Listings' })).toBeVisible()
await expect(page.getByRole('button', { name: 'Create New' })).toBeVisible()

// ✗ WRONG: Assumed text exists
await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible()  // Actually "My Listings"
await expect(page.getByRole('button', { name: 'Add New' })).toBeVisible()  // Actually "Create New"

// ✗ WRONG: Using data-testid without checking code
await expect(page.locator('[data-testid="create-btn"]')).toBeVisible()  // Maybe doesn't exist
```

#### Check 3: Error Response Verification

**Before writing error tests:**
```typescript
// ✓ Read actual error responses
// From src/api/listings.ts:
if (!user.roles.includes('advertiser')) {
  return res.status(403).json({ error: 'Access denied' })
}

// ✓ Read status codes
// 401 for auth, 403 for permission, 500 for server error
```

**In test:**
```typescript
// ✓ RIGHT: Tests actual error response
const response = await fetch('/api/v1/listings', {
  headers: { 'Authorization': 'invalid' }
})
expect(response.status).toBe(401)
const data = await response.json()
expect(data.error).toBe('Unauthorized')  // Exact error message from code

// ✗ WRONG: Assumed error structure
expect(response.error).toBe('Unauthorized')  // Response is JSON, not object with .error
expect(data.message).toBeDefined()  // Field is 'error', not 'message'
```

---

## Enforcement: Red Flags to Catch

### Red Flag 1: "Assume" Language

When you see these phrases, **STOP and read code**:

❌ "Probably returns..."
❌ "Should have a button..."
❌ "API likely returns..."
❌ "Component probably shows..."
❌ "User can probably..."

Replace with:
✅ "Code shows endpoint returns..."
✅ "Component renders button with text..."
✅ "API always returns..."
✅ "Component displays..."
✅ "Test verifies user can..."

### Red Flag 2: Missing File References

When creating tests, **every assertion needs a source**:

❌ Test without reference
```typescript
// Where does this come from?
await expect(page.getByText('Save Progress')).toBeVisible()
```

✅ Test with source reference
```typescript
// From src/components/Dashboard.tsx, line 42:
// <button>Save Progress</button>
await expect(page.getByText('Save Progress')).toBeVisible()
```

### Red Flag 3: Guessing API Structure

When testing API calls, **verify response structure exists**:

❌ Guessed response
```typescript
// Assumed this response shape exists
const { data, success } = await api.getListings()
```

✅ Verified response
```typescript
// From src/api/listings.ts, lines 15-25:
// Response structure: { listings: [], total_count: number, has_next: boolean }
const response = await api.getListings()
expect(response).toHaveProperty('listings')
expect(response).toHaveProperty('total_count')
```

### Red Flag 4: Selector Without Verification

When selecting elements, **verify in component code**:

❌ Assumed selector works
```typescript
// Does this element exist?
await page.locator('[data-testid="user-greeting"]').click()
```

✅ Verified selector exists
```typescript
// From src/components/Header.tsx, line 8:
// <span data-testid="user-greeting">Welcome, {user.name}</span>
await page.locator('[data-testid="user-greeting"]').isVisible()
```

---

## Code Reading Checklist for Agents

### For Planner Agent

**Before creating test plan, verify:**

- [ ] **Route Exists**
  - [ ] Read router file
  - [ ] Confirm route path matches
  - [ ] Check HTTP method (GET/POST/PUT)
  - [ ] Document auth requirements
  - [ ] Document role requirements

- [ ] **Component Renders**
  - [ ] Read component file
  - [ ] List all UI elements
  - [ ] Copy exact text/labels
  - [ ] Check for conditional rendering
  - [ ] Document loading/error/empty states

- [ ] **API Structure Known**
  - [ ] Read endpoint handler
  - [ ] Copy exact response structure
  - [ ] Document all response fields
  - [ ] Document error responses
  - [ ] Verify status codes

- [ ] **State Flow Understood**
  - [ ] Trace how component fetches data
  - [ ] Verify loading state behavior
  - [ ] Verify error state behavior
  - [ ] Verify empty state behavior

**Deliverable:** Test plan with code references
```
## Test Plan: Dashboard Listings

### Happy Path
1. User navigates to /painel/dashboard
   - From src/routes: route exists, requires JWT auth
   - From component: DashboardPage.tsx renders
2. Page loads with heading "My Listings"
   - From code: <h1>My Listings</h1> on line 12
3. Table shows listings from API
   - From API: GET /api/v1/listings returns { listings[], total_count, has_next }

[Complete with actual code references and line numbers]
```

### For Generator Agent

**Before generating test, verify:**

- [ ] **API Endpoints Exist**
  - [ ] Read all endpoint files
  - [ ] Copy exact request/response structures
  - [ ] Document all error codes
  - [ ] Verify endpoints aren't mocked

- [ ] **Selectors Match Code**
  - [ ] Read component JSX
  - [ ] Verify button/input/heading text
  - [ ] Check for data-testid usage
  - [ ] Verify elements are visible (not hidden)

- [ ] **Test Data Realistic**
  - [ ] Read schema validation
  - [ ] Verify email format
  - [ ] Verify number ranges
  - [ ] Verify string lengths

- [ ] **State Transitions Valid**
  - [ ] Verify loading state triggers
  - [ ] Verify error handling works
  - [ ] Verify cleanup clears state

**Deliverable:** Tests with code references
```typescript
test('AC1: Dashboard loads and displays user greeting', async ({ page }) => {
  // Arrange
  // From src/components/Header.tsx line 8:
  // <span>Welcome, {user.name}</span>
  const dashboard = new DashboardPage(page)

  // Act
  await dashboard.goTo()

  // Assert
  // Verify exact text from code
  await expect(page.getByText('Welcome, John')).toBeVisible()
})
```

---

## Examples: Code Reading in Action

### Example 1: Route That Doesn't Exist

**Agent assumes:**
```
"User can delete a listing by clicking Delete button"
"API endpoint: DELETE /api/listings/{id}"
```

**But code reading finds:**
```
src/routes.ts:
  - GET /api/v1/listings ✓
  - POST /api/v1/listings ✓
  - No DELETE endpoint ✗

Component:
  - No Delete button ✗
  - Only Edit button exists
```

**Result:** Test would fail. Code reading catches it early.

### Example 2: Response Structure Mismatch

**Agent assumes:**
```typescript
const { count, items } = response
```

**But code reading shows:**
```typescript
// src/api/listings.ts
return res.json({
  total_count: listings.length,  // Field is "total_count", not "count"
  listings: listings,  // Field is "listings", not "items"
})
```

**Result:** Test written with correct field names because agent read code.

### Example 3: Loading State Not Implemented

**Agent assumes:**
```typescript
// Wait for table to appear
await page.locator('table').waitFor()
```

**But code reading finds:**
```typescript
// Component doesn't have loading state
const Listings = () => {
  return <ListingTable />  // Always renders table
}
```

**Result:** Table appears immediately, no wait needed. Code reading found the truth.

### Example 4: Auth Not Enforced

**Agent assumes:**
```
"API requires JWT auth"
```

**But code reading finds:**
```typescript
// src/api/listings.ts
app.get('/api/listings', (req, res) => {
  // No auth check!
  return res.json(...)
})
```

**Result:** Test doesn't add auth header, which is correct (API doesn't require it).

---

## Integration with Phase 3 Pipeline

When Planner and Generator agents run:

1. **Phase 1:** Retrieve prior code-reading patterns from memory
2. **Code Reading:** Read actual router, component, API files
3. **Verification:** Create checklist with file references
4. **Generation:** Write tests based on actual code, not assumptions
5. **Memory:** Store code-reading insights for next feature

---

## Common Misconceptions

### ❌ "Code reading takes too long"

**Reality:** Spending 5 minutes reading code saves 30+ minutes of test debugging.

### ❌ "We can guess the API structure"

**Reality:** API structures change. Tests built on guesses catch nothing.

### ❌ "The component definitely has a button"

**Reality:** Check the code. Maybe it's a link. Maybe it's hidden. Maybe it doesn't exist.

### ❌ "Semantic locators work without seeing code"

**Reality:** Semantic locators depend on exact text. Code reading gets exact text right.

### ✅ "Code reading is the guardrail"

**Reality:** Yes. Read code once, write correct tests forever.

---

## Summary

| Phase | Agent | Action | Verification |
|-------|-------|--------|--------------|
| **Input** | Planner | Read code | Routes exist? Components render? APIs real? |
| **Output** | Planner | Test plan with references | Every assertion has a code source |
| **Input** | Generator | Read code | APIs unchanged? Selectors match? |
| **Output** | Generator | Test code with references | Tests match actual implementation |

**Golden Rule:** Every test assertion = one line of actual code being tested.
