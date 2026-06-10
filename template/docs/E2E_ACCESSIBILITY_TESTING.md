# E2E Accessibility Testing Guide

**Why accessibility matters in E2E tests and how to test for it.**

Accessibility isn't just for production code — it's also critical in E2E tests. Tests using semantic locators like `getByRole()` are inherently testing accessible code.

---

## Why Semantic Locators Are Accessibility Tests

When you write:

```typescript
// This uses the same accessibility tree that screen readers use
await page.getByRole('button', { name: /submit/i }).click()
```

You're **automatically testing accessibility** because:
1. `getByRole()` only finds elements that are accessible to assistive technology
2. If the button isn't properly marked for accessibility, the selector fails
3. Tests that use this pattern verify accessibility is working

### Comparison: Fragile vs Accessible

```typescript
// ❌ FRAGILE + INACCESSIBLE
// CSS selector bypasses accessibility layer
await page.click('.submit-btn')

// ✅ SEMANTIC + ACCESSIBLE
// Uses accessibility roles (screen readers can find it)
await page.click(page.getByRole('button', { name: /submit/i }))
```

---

## Testing Common Accessibility Issues

### 1. Form Labels (Critical)

**Problem:** Form fields without labels are inaccessible.

**Test for it:**

```typescript
test('email input has accessible label', async ({ page }) => {
  await page.goto('/login')
  
  // ASSERT: Input is associated with label
  const emailInput = page.getByLabel('Email')
  await expect(emailInput).toBeVisible()
})

test('all required form inputs have labels', async ({ page }) => {
  // Get all inputs
  const inputs = await page.locator('input').all()
  
  for (const input of inputs) {
    // Check each has aria-label or is wrapped by <label>
    const ariaLabel = await input.getAttribute('aria-label')
    const forAttribute = await input.getAttribute('aria-labelledby')
    
    // At least one must exist
    expect(ariaLabel || forAttribute).toBeTruthy()
  }
})
```

**Fix in component:**
```html
<!-- ❌ WRONG: No label -->
<input type="email" name="email" />

<!-- ✅ RIGHT: Label explicitly linked -->
<label for="email-input">Email</label>
<input id="email-input" type="email" name="email" />

<!-- ✅ ALSO RIGHT: Implicit label -->
<label>
  Email
  <input type="email" name="email" />
</label>

<!-- ✅ ALSO RIGHT: ARIA label -->
<input type="email" name="email" aria-label="Email address" />
```

### 2. Button Text (Critical)

**Problem:** Buttons with only icons don't work with screen readers.

**Test for it:**

```typescript
test('all buttons have accessible text', async ({ page }) => {
  const buttons = await page.locator('button').all()
  
  for (const button of buttons) {
    // Get accessible name (what screen reader says)
    const name = await button.getAttribute('aria-label')
                  || await button.textContent()
    
    // Button must have some text
    expect(name && name.trim()).toBeTruthy()
  }
})

test('submit button is accessible', async ({ page }) => {
  // ✅ This test FAILS if button isn't accessible
  await page.getByRole('button', { name: /submit/i })
    .click()
})
```

**Fix in component:**
```html
<!-- ❌ WRONG: Icon only, no text -->
<button>📤</button>

<!-- ✅ RIGHT: Icon + text -->
<button>Submit 📤</button>

<!-- ✅ ALSO RIGHT: Icon + aria-label -->
<button aria-label="Submit form">📤</button>

<!-- ✅ ALSO RIGHT: Icon with sr-only text -->
<button>
  <span class="sr-only">Submit</span>
  📤
</button>
```

### 3. ARIA Attributes (Important)

**Problem:** Screen readers can't understand custom components without ARIA.

**Test for it:**

```typescript
test('dialog has accessible role and label', async ({ page }) => {
  // Open dialog
  await page.click('[data-testid="open-dialog"]')
  
  // ASSERT: Dialog has proper ARIA attributes
  const dialog = page.locator('[role="dialog"]')
  
  // Dialog must have accessible name
  const ariaLabel = await dialog.getAttribute('aria-label')
                  || await dialog.getAttribute('aria-labelledby')
  expect(ariaLabel).toBeTruthy()
  
  // Focus should be in dialog
  const activeElement = await page.evaluate(() => 
    document.activeElement?.getAttribute('aria-label')
  )
  expect(activeElement).toBeTruthy()
})

test('dropdown properly announces state changes', async ({ page }) => {
  const dropdown = page.locator('[role="combobox"]')
  
  // ASSERT: Initial state
  let expanded = await dropdown.getAttribute('aria-expanded')
  expect(expanded).toBe('false')
  
  // ACT: Open dropdown
  await dropdown.click()
  
  // ASSERT: Updated state
  expanded = await dropdown.getAttribute('aria-expanded')
  expect(expanded).toBe('true')
})
```

**Common ARIA attributes to test:**

```typescript
// role: What type of component is this?
aria-label="Close" 
aria-labelledby="heading-id"
aria-describedby="description-id"

// State: What state is it in?
aria-expanded="true"    // Is dropdown open?
aria-selected="true"    // Is item selected?
aria-disabled="true"    // Is it disabled?
aria-hidden="true"      // Should it be hidden from screen readers?

// Relationships: How does it relate to other elements?
aria-owns="list-id"     // What does this component contain?
aria-controls="panel-id" // What does this control?
aria-live="polite"      // Should changes be announced?
```

### 4. Keyboard Navigation (Critical)

**Problem:** Users can't use keyboard to navigate.

**Test for it:**

```typescript
test('form is fully keyboard accessible', async ({ page }) => {
  await page.goto('/form')
  
  // Start with Tab key
  await page.press('body', 'Tab')
  
  // First input should be focused
  let focused = await page.evaluate(() => 
    document.activeElement?.getAttribute('data-testid')
  )
  expect(focused).toBe('email-input')
  
  // Tab to next field
  await page.press('body', 'Tab')
  focused = await page.evaluate(() => 
    document.activeElement?.getAttribute('data-testid')
  )
  expect(focused).toBe('password-input')
  
  // Tab to submit button
  await page.press('body', 'Tab')
  focused = await page.evaluate(() => 
    document.activeElement?.getAttribute('data-testid')
  )
  expect(focused).toBe('submit-button')
  
  // Shift+Tab goes back
  await page.press('body', 'Shift+Tab')
  focused = await page.evaluate(() => 
    document.activeElement?.getAttribute('data-testid')
  )
  expect(focused).toBe('password-input')
})

test('menu can be opened and navigated with keyboard', async ({ page }) => {
  const button = page.getByRole('button', { name: /menu/i })
  
  // Open with Enter
  await button.focus()
  await page.press('body', 'Enter')
  
  // Menu should appear
  const menu = page.locator('[role="menu"]')
  await expect(menu).toBeVisible()
  
  // First item should have focus
  const firstItem = menu.locator('[role="menuitem"]').first()
  await expect(firstItem).toBeFocused()
  
  // Arrow keys navigate
  await page.press('body', 'ArrowDown')
  const secondItem = menu.locator('[role="menuitem"]').nth(1)
  await expect(secondItem).toBeFocused()
})
```

**Fix in component:**
```jsx
// ❌ WRONG: Only mouse interactive
<div onClick={handleClick}>
  Menu
  <div>{menuItems}</div>
</div>

// ✅ RIGHT: Keyboard support
<button 
  aria-haspopup="menu"
  aria-expanded={isOpen}
  onClick={handleClick}
  onKeyDown={handleKeyDown}  // Arrow keys, Enter, Escape
>
  Menu
</button>

{isOpen && (
  <ul role="menu" onKeyDown={handleMenuKeyDown}>
    {menuItems.map(item => (
      <li role="menuitem" key={item.id}>
        {item.label}
      </li>
    ))}
  </ul>
)}
```

### 5. Focus Management (Important)

**Problem:** Focus disappears or moves to wrong place after action.

**Test for it:**

```typescript
test('focus moves to modal content when modal opens', async ({ page }) => {
  // Initial focus
  const button = page.getByRole('button', { name: /open modal/i })
  
  // Click modal button
  await button.click()
  
  // Focus should move into modal (not stay on button)
  const modal = page.locator('[role="dialog"]')
  await expect(modal).toBeVisible()
  
  const focusedElement = await page.evaluate(() => 
    document.activeElement?.getAttribute('data-testid')
  )
  
  // Focus should be on modal content (e.g., first input or close button)
  expect(focusedElement).toMatch(/(modal|close|input)/)
})

test('focus returns to trigger when modal closes', async ({ page }) => {
  // Get button for reference
  const button = page.getByRole('button', { name: /open modal/i })
  
  // Open modal
  await button.click()
  
  // Close modal
  await page.getByRole('button', { name: /close/i }).click()
  
  // Focus should return to original button
  const focused = await page.evaluate(() => 
    document.activeElement === button
  )
  expect(focused).toBe(true)
})
```

**Fix in component:**
```jsx
// When modal opens: focus first input or close button
useEffect(() => {
  if (isOpen) {
    const firstInput = dialogRef.current?.querySelector('input')
    if (firstInput) {
      firstInput.focus()
    }
  }
}, [isOpen])

// When modal closes: return focus
const handleClose = () => {
  setIsOpen(false)
  triggerButtonRef.current?.focus()
}
```

### 6. Color Contrast (Important)

**Problem:** Text isn't readable by users with low vision.

**Test for it:**

```typescript
test('text has sufficient color contrast', async ({ page }) => {
  // Check heading contrast
  const heading = page.getByRole('heading', { name: /sign up/i })
  
  const bgColor = await heading.evaluate((el) => 
    window.getComputedStyle(el).backgroundColor
  )
  const textColor = await heading.evaluate((el) => 
    window.getComputedStyle(el).color
  )
  
  // Calculate contrast ratio (should be at least 4.5:1 for normal text)
  const contrastRatio = calculateContrast(textColor, bgColor)
  expect(contrastRatio).toBeGreaterThanOrEqual(4.5)
})
```

**Tools to use:**
- WebAIM Contrast Checker: https://webaim.org/resources/contrastchecker/
- Use CSS variables for colors to ensure consistency

### 7. Alt Text for Images (Important)

**Problem:** Images without alt text aren't described to screen reader users.

**Test for it:**

```typescript
test('all images have alt text', async ({ page }) => {
  const images = await page.locator('img').all()
  
  for (const img of images) {
    const alt = await img.getAttribute('alt')
    
    // Every image must have alt text
    // (alt="" is OK if image is purely decorative)
    expect(alt).toBeDefined()
  }
})

test('product images have descriptive alt text', async ({ page }) => {
  const productImage = page.locator('[data-testid="product-image"]')
  const alt = await productImage.getAttribute('alt')
  
  // Should describe what's in the image
  expect(alt).toMatch(/\w+/); // Not empty
  expect(alt.length).toBeGreaterThan(5); // Not just "image"
})
```

### 8. Skip Links (Nice to Have)

**Problem:** Users can't skip to main content on keyboard.

**Test for it:**

```typescript
test('skip link is keyboard accessible', async ({ page }) => {
  await page.goto('/')
  
  // First thing on page when using keyboard
  await page.press('body', 'Tab')
  
  const skipLink = page.getByRole('link', { name: /skip/i })
  await expect(skipLink).toBeFocused()
  
  // Click it
  await skipLink.click()
  
  // Should jump to main content
  await expect(page).toHaveURL(/#main|\/main/))
})
```

---

## Accessibility Testing Tools

### Integrated into Tests

```typescript
import { injectAxe, checkA11y } from 'axe-playwright'

test('page has no accessibility violations', async ({ page }) => {
  // Inject axe-core library
  await page.goto('/')
  await injectAxe(page)
  
  // Check for violations
  await checkA11y(page, null, {
    detailedReport: true,
    detailedReportOptions: {
      html: true
    }
  })
})
```

### Manual Tools (For Developers)

- **axe DevTools:** Browser extension (Chrome, Firefox)
- **WAVE:** Browser extension (checks contrast, labels, etc.)
- **Lighthouse:** Built into Chrome DevTools (Accessibility audit)
- **Keyboard Navigation:** Just use Tab, Shift+Tab, Arrow keys

---

## Accessibility Testing Checklist

Before submitting a feature:

- [ ] All form inputs have associated labels
- [ ] All buttons have accessible text (not just icons)
- [ ] Keyboard navigation works (Tab, Shift+Tab, Arrow keys, Enter, Escape)
- [ ] Focus is visible (not hidden with `outline: none`)
- [ ] Focus management works (modal, dropdown, etc.)
- [ ] All custom components have proper ARIA roles
- [ ] Color contrast is sufficient (4.5:1 for normal text, 3:1 for large)
- [ ] Images have alt text
- [ ] Modal dialogs trap focus
- [ ] Error messages are associated with fields (aria-describedby)

---

## Common Patterns

### Accessible Form

```jsx
function LoginForm() {
  return (
    <form onSubmit={handleSubmit} noValidate>
      <div>
        <label htmlFor="email">Email Address</label>
        <input
          id="email"
          type="email"
          name="email"
          required
          aria-required="true"
          aria-invalid={errors.email ? 'true' : 'false'}
          aria-describedby={errors.email ? 'email-error' : undefined}
        />
        {errors.email && (
          <div id="email-error" role="alert">
            {errors.email}
          </div>
        )}
      </div>
      
      <button type="submit">Sign In</button>
    </form>
  )
}
```

### Accessible Modal

```jsx
function Modal({ isOpen, onClose, title, children }) {
  useEffect(() => {
    if (isOpen) {
      // Focus first input
      document.querySelector('[role="dialog"] input')?.focus()
    }
  }, [isOpen])
  
  return (
    isOpen && (
      <div
        role="dialog"
        aria-labelledby="modal-title"
        aria-modal="true"
      >
        <h2 id="modal-title">{title}</h2>
        {children}
        <button
          onClick={onClose}
          aria-label="Close dialog"
        >
          ×
        </button>
      </div>
    )
  )
}
```

### Accessible Dropdown

```jsx
function Dropdown({ label, options, value, onChange }) {
  const [isOpen, setIsOpen] = useState(false)
  
  return (
    <div>
      <label htmlFor="dropdown">{label}</label>
      <button
        id="dropdown"
        aria-haspopup="listbox"
        aria-expanded={isOpen}
        onClick={() => setIsOpen(!isOpen)}
      >
        {value || 'Select...'}
      </button>
      {isOpen && (
        <ul role="listbox">
          {options.map(option => (
            <li
              key={option.id}
              role="option"
              onClick={() => {
                onChange(option)
                setIsOpen(false)
              }}
            >
              {option.label}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
```

---

## Resources

- **WCAG 2.1 Guidelines:** https://www.w3.org/WAI/WCAG21/quickref/
- **ARIA Best Practices:** https://www.w3.org/WAI/ARIA/apg/
- **Playwright Accessibility:** https://playwright.dev/docs/accessibility-testing
- **axe DevTools:** https://www.deque.com/axe/devtools/
- **WebAIM:** https://webaim.org/

---

## Key Takeaway

**Semantic locators (`getByRole`) are accessibility tests.** When you use them, you're automatically verifying:
- Elements are properly labeled
- Components have proper ARIA attributes
- The DOM structure is accessible

Use them consistently, and your code will be more accessible by default.

---

**Last Updated:** 2026-06-10  
**Status:** Complete, ready to reference
