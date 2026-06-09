# Production-Readiness Validation (Step -1)

**When to use:** BEFORE running the E2E pipeline for any feature  
**What it does:** Verify the code under test is production-ready, not mock-heavy  
**Why it matters:** Testing mocks catches nothing. False test coverage is worse than no coverage.

---

## Quick Overview

Before generating tests, verify:
- [ ] API endpoints use real data (not hardcoded responses)
- [ ] Frontend components don't have development overrides
- [ ] Test data matches actual validation rules
- [ ] Database isn't using simplified test schema

If any check fails, fix the code first. Then re-run the pipeline.

---

## Detailed Checks: API Code

For each endpoint being tested:

### Check 1: NOT Hardcoded Responses

**What to look for:**
```typescript
// ❌ WRONG: Hardcoded response
app.get('/api/listings', (req, res) => {
  res.json({ listings: [{ id: 1, title: "Test" }] })
})

// ✅ RIGHT: Real database query
app.get('/api/listings', async (req, res) => {
  const listings = await db.query('SELECT * FROM listings')
  res.json({ listings })
})
```

**How to check:**
```bash
# Look for hardcoded objects or arrays in routes
grep -r "res.json({.*})" src/routes/
grep -r "res.json(\[" src/routes/

# Should NOT find these patterns
# Should find: database queries, service calls, or real data fetching
```

**Questions to answer:**
- [ ] Does the endpoint query a real database (Postgres, MongoDB, etc.)?
- [ ] Or does it return hardcoded values?
- [ ] If using a mock, is it for testing only (not production code)?

### Check 2: Real Error Handling

**What to look for:**
```typescript
// ❌ WRONG: Always returns success
app.post('/api/save', (req, res) => {
  try {
    saveData(req.body)
    res.json({ success: true })
  } catch (e) {
    res.json({ success: true, error: null }) // Still returns 200!
  }
})

// ✅ RIGHT: Returns appropriate status codes
app.post('/api/save', async (req, res) => {
  try {
    validateInput(req.body) // Throws on invalid
    await saveData(req.body)
    res.json({ success: true })
  } catch (e) {
    res.status(400).json({ error: e.message })
  }
})
```

**How to check:**
```bash
# Look for actual error handling
grep -r "res.status" src/routes/
grep -r "throw new\|throw " src/routes/

# Should find error status codes (400, 401, 403, 500)
# Should NOT find: all errors returning 200 OK
```

**Questions to answer:**
- [ ] Does endpoint return 400 on bad input?
- [ ] Does endpoint return 401 on auth failure?
- [ ] Does endpoint return 403 on permission failure?
- [ ] Or does it always return 200 success?

### Check 3: Real Validation

**What to look for:**
```typescript
// ❌ WRONG: No validation
app.post('/api/user', (req, res) => {
  createUser(req.body) // Accepts anything
})

// ✅ RIGHT: Validates input
app.post('/api/user', (req, res) => {
  const { email, name } = req.body
  
  if (!email || !email.includes('@')) {
    return res.status(400).json({ error: 'Invalid email' })
  }
  
  if (!name || name.length < 2) {
    return res.status(400).json({ error: 'Name too short' })
  }
  
  createUser(req.body)
})
```

**How to check:**
```bash
# Look for validation logic
grep -r "validator\|validate\|if (!" src/routes/
grep -r "schema\|joi\|yup\|zod" src/routes/

# Should find validation library or manual checks
# Should NOT find: accept all requests without validation
```

**Questions to answer:**
- [ ] Are input fields validated (type, length, format)?
- [ ] Are required fields enforced?
- [ ] Does it match the schema in the database?

---

## Detailed Checks: Frontend Code

For each component being tested:

### Check 4: NOT Development-Overridden

**What to look for:**
```typescript
// ❌ WRONG: Development override
function DashboardPage() {
  if (process.env.NODE_ENV === 'development') {
    return <MockDashboard /> // Returns fake data in dev!
  }
  
  return <RealDashboard />
}

// ❌ WRONG: Feature flag returning fake data
function Dashboard() {
  if (isDev) {
    return <div>Fake dashboard with hardcoded data</div>
  }
  return <RealDashboard />
}

// ✅ RIGHT: No dev overrides in component
function DashboardPage() {
  const { data, loading } = useQuery(DASHBOARD_QUERY)
  
  if (loading) return <Spinner />
  return <Dashboard data={data} />
}
```

**How to check:**
```bash
# Look for development branches
grep -r "isDev\|__DEV__\|NODE_ENV.*development" src/components/
grep -r "if.*dev\|if.*mock" src/pages/

# Should NOT find development overrides in production code
# (It's OK in test files, but not in src/components or src/pages)
```

**Questions to answer:**
- [ ] Are there any `if (isDev)` or `if (__DEV__)` branches in the component?
- [ ] Do they return fake/mock data?
- [ ] If yes, remove them before running E2E tests

### Check 5: Real API Calls

**What to look for:**
```typescript
// ❌ WRONG: Hardcoded mock data
function UserList() {
  const users = [
    { id: 1, name: 'John' },
    { id: 2, name: 'Jane' },
  ]
  return <ul>{users.map(u => <li>{u.name}</li>)}</ul>
}

// ✅ RIGHT: Fetches from real API
function UserList() {
  const [users, setUsers] = useState([])
  
  useEffect(() => {
    fetch('/api/users').then(r => r.json()).then(setUsers)
  }, [])
  
  return <ul>{users.map(u => <li>{u.name}</li>)}</ul>
}
```

**How to check:**
```bash
# Look for hardcoded data in components
grep -r "\[{.*}" src/components/ | grep -v "props\|map\|filter"
grep -r "const.*=.*\[{" src/components/

# Should NOT find hardcoded arrays/objects
# Should find: fetch, axios, GraphQL, or similar API calls
```

**Questions to answer:**
- [ ] Does the component fetch data from an API?
- [ ] Or does it use hardcoded values?
- [ ] If using real API, is it pointing to real endpoint?

### Check 6: Real Loading/Error States

**What to look for:**
```typescript
// ❌ WRONG: Always shows data, no loading state
function Listings() {
  const listings = fakeData // Always available
  return <ListingTable listings={listings} />
}

// ✅ RIGHT: Shows loading while fetching
function Listings() {
  const [listings, setListings] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  
  useEffect(() => {
    fetch('/api/listings')
      .then(r => r.json())
      .then(data => setListings(data))
      .catch(err => setError(err))
      .finally(() => setLoading(false))
  }, [])
  
  if (loading) return <Spinner />
  if (error) return <ErrorMessage error={error} />
  return <ListingTable listings={listings} />
}
```

**How to check:**
```bash
# Look for loading/error state logic
grep -r "useState.*loading\|setLoading" src/components/
grep -r "if.*loading.*return\|if.*error.*return" src/components/

# Should find explicit loading and error states
# Should NOT find: always showing data without loading state
```

**Questions to answer:**
- [ ] Does component show loading state while fetching?
- [ ] Does component show error message on failure?
- [ ] Does component show empty state when no data?
- [ ] Or does it always show data magically?

---

## Detailed Checks: Test Data

### Check 7: Matches Real Schema

**What to look for:**
```typescript
// ❌ WRONG: Unrealistic test data
const testEmail = 'test'  // Invalid email format
const testAmount = 99999999  // Outside range
const testName = 'x'  // Too short

// ✅ RIGHT: Matches actual validation rules
const testEmail = 'user@example.com'  // Valid format
const testAmount = 100  // Within valid range
const testName = 'John Doe'  // Meets length requirement
```

**How to check:**
1. Read your schema/database definition:
   ```bash
   # For PostgreSQL
   psql -d yourdb -c "\d your_table"
   
   # For MongoDB
   db.your_collection.findOne()
   ```

2. Compare test data to schema:
   - Email: Must match email validation pattern
   - Amount: Must be within numeric range
   - Name: Must meet length constraints
   - Dates: Must be valid ISO format

**Questions to answer:**
- [ ] Does test email match actual email validation?
- [ ] Does test amount match actual min/max limits?
- [ ] Does test name meet actual length requirements?
- [ ] Would this data pass the real validation rules?

---

## Checklist: Before Running Pipeline

```
Production-Readiness Validation Checklist

API Code
- [ ] Endpoints use real database queries (not hardcoded)
- [ ] Error handling returns appropriate status codes
- [ ] Input validation matches schema requirements

Frontend Code
- [ ] No development overrides (isDev branches)
- [ ] Components fetch from real APIs
- [ ] Loading and error states implemented

Test Data
- [ ] Email/phone format matches validation rules
- [ ] Numbers within valid ranges
- [ ] Strings meet length requirements
- [ ] UUID-based unique data (not predictable values)

General
- [ ] All checks above passed
- [ ] Ready to run E2E pipeline
```

---

## If Production-Readiness Check Fails

**Don't skip this step.** Fix the code first:

1. **Hardcoded responses?**
   → Replace with real database queries or API calls

2. **Development overrides?**
   → Remove `if (isDev)` branches from production code

3. **Test data unrealistic?**
   → Update to match actual validation rules

4. **No validation?**
   → Add schema validation to API endpoints

5. **No loading state?**
   → Add loading/error/empty states to components

**Then:** Re-run the production-readiness check and confirm all pass before proceeding to Step 0.

---

## Why This Matters

E2E tests should validate your **actual production code**, not mocks or test harnesses.

**Bad scenario:**
```
Code: Uses fake data in dev
Tests: Pass against fake data
Deploy to prod: App doesn't work with real data
Result: Tests caught nothing
```

**Good scenario:**
```
Code: Uses real data everywhere
Tests: Pass against real data
Deploy to prod: App works (tests validated it)
Result: Tests caught real bugs
```

This checklist ensures you're in the good scenario.
