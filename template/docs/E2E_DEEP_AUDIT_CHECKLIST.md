# Phase 0: Deep Codebase Audit Checklist

**When to use:** BEFORE running the E2E pipeline for any feature  
**What it does:** Guides you to understand your feature's actual implementation  
**Why it matters:** AI-generated tests need to understand what actually exists, not guess

---

## Why This Matters

Tests that assume features exist when they don't = false test coverage. This checklist forces you to explore the **actual code** before generating tests.

You'll paste this understanding into the AI prompts. AI can then generate tests that match real code, not imaginary flows.

---

## Checklist: Routes & Pages

Map the actual routes your feature uses. Don't assume — verify in your codebase.

```
Route: _______________
Component: _______________
Auth required? Yes / No
Protected by role? _______________

Route: _______________
Component: _______________
Auth required? Yes / No
Protected by role? _______________
```

**Question for each route:**
- [ ] Does this route exist in your router?
- [ ] What component renders at this route?
- [ ] Is it protected by auth/roles?
- [ ] What does the route do on success?
- [ ] What happens if auth fails?

---

## Checklist: Components & UI Elements

For each page in your feature, list the actual UI elements and what they do.

```
Page: _______________

Heading:
- [ ] Exact text: _______________
- [ ] HTML element: <h1> / <h2> / <span>
- [ ] How to select: getByRole('heading', { name: /.../ })

Button:
- [ ] Button text: _______________
- [ ] What it does: _______________
- [ ] Disabled state exists? Yes / No
- [ ] How to select: getByRole('button', { name: /.../ })

Form Fields:
- [ ] Field label: _______________
- [ ] Input type: text / email / number / date
- [ ] Required? Yes / No
- [ ] Placeholder text: _______________
- [ ] How to select: getByLabel(/.../)
```

**Critical questions:**
- [ ] Does this element actually exist in the code?
- [ ] What's the exact visible text/label?
- [ ] How would a user select this element (without knowing data-testid)?

---

## Checklist: API Endpoints & Contracts

What API calls does this feature make?

```
Endpoint: GET /api/v1/...
Purpose: _______________
Success response:
  {
    "field": "value",
    ...
  }

Error responses:
  - 401 Unauthorized: _______________
  - 403 Forbidden: _______________
  - 500 Server Error: _______________

Endpoint: POST /api/v1/...
Purpose: _______________
Request body:
  {
    "field": "value",
    ...
  }
Success response: _______________
Error responses:
  - 400 Bad Request: _______________
  - 401 Unauthorized: _______________
```

**Questions for each endpoint:**
- [ ] What's the exact URL?
- [ ] What HTTP method (GET/POST/PUT/DELETE)?
- [ ] What does success look like (exact response structure)?
- [ ] What error codes can it return?
- [ ] What's required in the request?

---

## Checklist: User Flows (Happy Path)

What's the normal flow through your feature?

```
1. User starts at: _______________
2. User sees: _______________
3. User clicks: _______________
4. System does: _______________
5. User sees: _______________
6. User completes action
7. Success: _______________
```

**For each step:**
- [ ] Is this visible on the page?
- [ ] What's the exact text/label the user sees?
- [ ] What element does the user interact with?
- [ ] What happens after the interaction?

---

## Checklist: Error Scenarios

What can go wrong?

```
Error: _______________
Trigger: _______________
User sees: _______________
What the app does: _______________
How user recovers: _______________

Error: _______________
Trigger: _______________
User sees: _______________
What the app does: _______________
How user recovers: _______________
```

**Common errors to check:**
- [ ] Missing auth / expired session
- [ ] Missing permissions (403 Forbidden)
- [ ] Invalid input (400 Bad Request)
- [ ] Server error (500)
- [ ] Network timeout
- [ ] Empty state (no data)

---

## Checklist: Edge Cases & Unusual Situations

What unusual situations should work?

```
Case: _______________
Precondition: _______________
Expected behavior: _______________
What user sees: _______________
Verified in code? Yes / No

Case: _______________
Precondition: _______________
Expected behavior: _______________
What user sees: _______________
Verified in code? Yes / No
```

**Common edge cases:**
- [ ] Empty state (0 items, no data)
- [ ] Max items (pagination, limits)
- [ ] Special characters in input
- [ ] Very long text
- [ ] Concurrent actions
- [ ] Rapid clicking
- [ ] Browser back button
- [ ] Page refresh mid-action

---

## Checklist: State Management & Side Effects

How does your feature manage state?

```
State before action: _______________
Action user takes: _______________
State changes to: _______________
Side effects:
  - [ ] API call made
  - [ ] Data persisted
  - [ ] UI updated
  - [ ] User redirected
```

---

## Checklist: Preconditions & Test Data

What needs to be true before testing?

```
Precondition: _______________
How to set it up: _______________
Required test data:
  - Field: _______________ Value: _______________
  - Field: _______________ Value: _______________

Precondition: _______________
How to set it up: _______________
Required test data:
  - Field: _______________ Value: _______________
```

---

## Final Verification

Before moving forward, answer these questions:

- [ ] **Routes:** Can I trace the exact route in the router code?
- [ ] **Components:** Can I find the component file that renders this route?
- [ ] **Elements:** Can I see each UI element in the component's JSX/TSX?
- [ ] **APIs:** Can I find the endpoint in the backend code?
- [ ] **Flows:** Did I manually test the happy path in my browser?
- [ ] **Errors:** Did I manually trigger each error scenario?
- [ ] **Edge cases:** Did I verify edge cases actually happen in the code?

If you answered "no" to any of these, **go back and verify in the code**. Don't guess.

---

## What You'll Do Next

Once you've completed this checklist:

1. **Copy your audit notes** into the Planner Agent prompt
2. **Run the pipeline:** `./scripts/phase3-pipeline.sh "feature-name" "/route"`
3. **Paste your audit** when prompted
4. AI generates tests based on **your understanding** of the actual code

The better your audit, the better your tests.

---

**Remember:** This audit takes time, but it saves hours of debugging failing tests later.
