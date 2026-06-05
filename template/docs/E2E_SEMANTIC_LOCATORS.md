# Semantic Locators: The Right Way to Find Elements

**Reference guide for all tests in this project**  
**Read this when writing or reviewing E2E tests**

---

## The Locator Hierarchy

Use locators in this order. Stop as soon as you find one that works:

### 1️⃣ getByRole — ALWAYS TRY FIRST

Find elements by their accessibility role (what users see).

```typescript
// Button
await page.click(page.getByRole('button', { name: /submit/i }))

// Link
await page.click(page.getByRole('link', { name: /login/i }))

// Heading
await expect(page.getByRole('heading', { name: /dashboard/i })).toBeVisible()

// Checkbox
await page.check(page.getByRole('checkbox', { name: /agree/i }))

// Radio button
await page.click(page.getByRole('radio', { name: /option a/i }))

// Dropdown/Combobox
await page.click(page.getByRole('combobox', { name: /select country/i }))

// List items
const items = page.getByRole('listitem')
await items.filter({ hasText: /important/ }).click()
```

**Why it's best:**
- Tests what users actually see
- Breaks when accessibility is broken (catches accessibility bugs)
- Works across different CSS implementations
- Resilient to styling changes

**Available roles:**
```
button, link, heading, checkbox, radio, combobox, listbox,
menuitem, option, tab, textbox, dialog, alertdialog, progressbar,
spinbutton, slider, and many more...
```

---

### 2️⃣ getByLabel — FOR FORM INPUTS

Find form fields by their `<label>` element.

```typescript
// Text input
await page.fill(page.getByLabel(/email address/i), 'user@example.com')

// Password input
await page.fill(page.getByLabel(/password/i), 'secret123')

// Select dropdown
await page.selectOption(page.getByLabel(/country/i), 'US')

// Textarea
await page.fill(page.getByLabel(/message/i), 'Hello world')

// Checkbox with label
await page.check(page.getByLabel(/remember me/i))
```

**Why it works:**
- Mimics how users identify fields (by label text)
- Requires proper HTML structure (`<label for="id">`)
- Encourages accessible form markup

**HTML structure required:**
```html
<label for="email">Email Address</label>
<input id="email" type="email" />
```

---

### 3️⃣ getByText — FOR STATIC TEXT CONTENT

Find elements containing visible text.

```typescript
// Find text anywhere in the page
await expect(page.getByText(/welcome, john/i)).toBeVisible()

// Click text that's inside a button or link
await page.click(page.getByText(/click here/i))

// Find success message
await expect(page.getByText(/listing created successfully/i)).toBeVisible()

// Find error message
await expect(page.getByText(/email already in use/i)).toBeVisible()
```

**When to use:**
- Static text content
- Success/error messages
- Text that doesn't have semantic role

**Avoid if:**
- Text is dynamically generated (timestamps, IDs)
- Text changes based on state
- Text could appear multiple times

---

### 4️⃣ getByTestId — LAST RESORT ONLY

Use only when semantic locators won't work.

```typescript
// Only use if element has no role, label, or text
await page.click(page.getByTestId('submit-button'))
```

**Why it's last resort:**
- Not what users see (internal implementation detail)
- Breaks when testid changes
- Doesn't test accessibility
- Tests the HTML structure, not the user experience

**Only add data-testid if:**
- Element has no semantic role
- Element has no visible text
- Semantic locators genuinely won't work

---

## ❌ NEVER USE

### CSS Selectors
```typescript
❌ page.click('.button-primary')           // Don't!
❌ page.click('#submit-btn')               // Don't!
❌ page.click('button.submit')             // Don't!
```

Why: Breaks when CSS changes, tests styling not behavior

### XPath
```typescript
❌ page.click('//button[@id="submit"]')    // Don't!
❌ page.click('//div[contains(@class, "primary")]')  // Don't!
```

Why: Fragile, hard to read, tests HTML structure

### Combining Multiple Selectors
```typescript
❌ page.click('section > div > button')    // Don't!
❌ page.locator('main button:nth-child(2)') // Don't!
```

Why: Breaks when HTML structure changes

---

## Common Element Examples

### Buttons

```typescript
// By role (BEST)
await page.click(page.getByRole('button', { name: /submit/i }))

// By text (fallback)
await page.click(page.getByText(/submit/i))

// With exact match
await page.click(page.getByRole('button', { name: 'Submit' }))

// Case-insensitive
await page.click(page.getByRole('button', { name: /submit/i }))

// Partial match
await page.click(page.getByRole('button', { name: /sub/i }))
```

### Form Inputs

```typescript
// Text input by label
await page.fill(page.getByLabel(/email/i), 'user@example.com')

// Password input
await page.fill(page.getByLabel(/password/i), 'secret')

// Textarea
await page.fill(page.getByLabel(/message/i), 'Hello')

// Select dropdown
await page.selectOption(page.getByLabel(/country/i), 'us')

// Checkbox
await page.check(page.getByLabel(/terms/i))

// Radio button
await page.click(page.getByLabel(/option a/i))
```

### Links

```typescript
// By visible text
await page.click(page.getByRole('link', { name: /login/i }))

// Or by text
await page.click(page.getByText(/login/i))
```

### Headings

```typescript
// Find heading with specific text
const heading = page.getByRole('heading', { name: /dashboard/i })
await expect(heading).toBeVisible()

// Check heading level
await expect(page.getByRole('heading', { level: 1, name: /title/i })).toBeVisible()
```

### Tables

```typescript
// Find row containing text
const row = page.getByRole('row').filter({ hasText: /john doe/ })

// Click cell in that row
await row.getByRole('button', { name: /edit/i }).click()

// Find all cells in a column
const emailCells = page.getByRole('columnheader', { name: /email/i })
```

### Lists

```typescript
// Find list item
const item = page.getByRole('listitem').filter({ hasText: /important/ })

// Or by text
const item = page.getByText(/important item/)
```

### Modals/Dialogs

```typescript
// Find dialog and element inside it
const dialog = page.getByRole('dialog')
const button = dialog.getByRole('button', { name: /confirm/i })
await button.click()
```

---

## Case Sensitivity & Regex Patterns

### Case Insensitive (Recommended)

```typescript
// These all match "Submit", "submit", "SUBMIT"
page.getByRole('button', { name: /submit/i })  // ✅ Regex (i flag)
page.getByRole('button', { name: /Submit/i })  // ✅ Works
page.getByLabel(/email/i)                      // ✅ Works
```

### Case Sensitive (Be careful)

```typescript
// These only match exact case
page.getByRole('button', { name: /submit/ })   // Only lowercase "submit"
page.getByRole('button', { name: 'Submit' })   // Only exact "Submit"
```

### Regex Patterns

```typescript
// Simple match
/submit/i                      // Contains "submit"

// Beginning of string
/^submit/i                     // Starts with "submit"

// End of string
/submit$/i                     // Ends with "submit"

// Multiple options
/submit|cancel|ok/i            // Contains one of these

// Whitespace handling
/\s*submit\s*/i                // "submit" with possible spaces

// Numbers
/listing \d+/i                 // "listing" followed by number
```

---

## Common Mistakes & Fixes

### Mistake 1: Using testid when role exists

```typescript
❌ WRONG:
await page.click(page.getByTestId('submit-btn'))

✅ RIGHT:
await page.click(page.getByRole('button', { name: /submit/i }))
```

### Mistake 2: Using CSS selector

```typescript
❌ WRONG:
await page.click('button.primary')

✅ RIGHT:
await page.click(page.getByRole('button', { name: /submit/i }))
```

### Mistake 3: Too specific with text matching

```typescript
❌ WRONG:
// Fails if text has extra spaces or changes slightly
await page.getByText('Click here to submit now')

✅ RIGHT:
// Flexible matching
await page.getByRole('button', { name: /submit/i })
```

### Mistake 4: Chaining too many locators

```typescript
❌ WRONG:
page.locator('div.form').locator('input.email').fill('test@example.com')

✅ RIGHT:
page.getByLabel(/email/i).fill('test@example.com')
```

### Mistake 5: Assuming unique text

```typescript
❌ WRONG:
// If "Edit" button appears 5 times on page, which one?
await page.click(page.getByText(/edit/i))

✅ RIGHT:
// Be more specific
await page.getByRole('row').filter({ hasText: /john/ })
  .getByRole('button', { name: /edit/i }).click()
```

---

## Testing Accessibility

**Semantic locators double as accessibility tests.**

```typescript
// If this fails, the element isn't properly labeled for screen readers
await page.getByLabel(/email/i)  // Tests: <label> + <input> association

// If this fails, button isn't accessible to keyboard users
await page.getByRole('button')   // Tests: Proper ARIA roles

// If this fails, heading structure is broken
await page.getByRole('heading', { level: 1 })  // Tests: H1 exists
```

When locators fail, often it's an **accessibility bug** that affects real users with screen readers or keyboards.

---

## Quick Reference

| Goal | Locator | Example |
|------|---------|---------|
| Find button | getByRole | `page.getByRole('button', { name: /submit/i })` |
| Find link | getByRole | `page.getByRole('link', { name: /login/i })` |
| Find heading | getByRole | `page.getByRole('heading', { name: /title/i })` |
| Find form field | getByLabel | `page.getByLabel(/email/i)` |
| Find checkbox | getByRole | `page.getByRole('checkbox', { name: /agree/i })` |
| Find text | getByText | `page.getByText(/error message/i)` |
| Find by testid | getByTestId | `page.getByTestId('btn-submit')` (last resort) |
| Find multiple | filter | `page.getByRole('button').filter({ hasText: /save/i })` |

---

## Pro Tips

1. **Always use regex with `/i` flag** for case-insensitive matching
2. **Use `filter()` with `hasText`** to narrow down multiple matching elements
3. **Break down complex selectors** into simpler parts
4. **Test your locators in browser console** before committing:
   ```javascript
   // In browser console
   document.evaluate(
     "//*[@role='button' and contains(., 'Submit')]",
     document,
     null,
     XPathResult.FIRST_ORDERED_NODE_TYPE,
     null
   ).singleNodeValue // See if Playwright would find it
   ```

---

**Rule of thumb:** If a locator doesn't match real user behavior (what they see/click), it's the wrong locator.
