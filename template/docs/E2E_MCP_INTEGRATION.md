# Playwright MCP Integration (Optional)

**What is MCP?**
MCP stands for Model Context Protocol. The Playwright MCP allows AI agents (like Claude) to interact with your browser, run tests, and see results in real-time.

**Is it required?**
No. Tests work fine without it. MCP just makes AI-assisted test writing faster and easier.

---

## When MCP Helps

### With MCP (Recommended)
AI agents can:
- Explore your app interactively
- Run tests and see results instantly
- Debug failures by inspecting DOM
- Verify selectors before writing tests
- Faster test generation (2-3x speedup)

**Result:** Agents understand your app better → better tests → fewer iterations

### Without MCP
AI agents can:
- Read component code (slower exploration)
- Understand app structure from documentation
- Generate tests based on code analysis
- Still produce good tests, just takes longer

**Result:** Still works, just requires more manual code reading

---

## Installation

### Option 1: Install During Setup (Recommended)

When running `install.sh`, the script automatically tries to install MCP:

```bash
npm install --save-dev @playwright/mcp@1.0.0
```

If installation succeeds, you're ready to use MCP with AI agents.

### Option 2: Manual Installation

If you skipped MCP during setup:

```bash
npm install --save-dev @playwright/mcp@1.0.0
npx playwright install  # Install browser binaries
```

### Option 3: Verify Installation

Check if MCP is installed:

```bash
npm list @playwright/mcp
```

Expected output:
```
@playwright/mcp@1.0.0
```

If not installed, see Option 2 above.

---

## Using MCP with AI Agents

### With Claude or Cursor

When generating tests with an AI agent:

1. **Tell the agent MCP is available:**
   ```
   I have Playwright MCP installed. You can use it to explore the app interactively.
   ```

2. **Agent can now:**
   - Run the test app: `npx playwright test --debug`
   - Explore pages with code inspection
   - Verify selectors work before writing tests
   - See live DOM state

3. **Agent uses MCP like this:**
   ```
   # Run test to see results
   npm run e2e -- --grep "test-name"

   # See what elements exist
   npx playwright test --debug

   # Inspect failing test
   npx playwright show-report
   ```

### Without Telling Agent About MCP

If you don't mention MCP, the agent assumes it's not available and:
- Reads code instead of exploring interactively
- Takes longer (more code reading needed)
- Tests are usually still good, just slower to generate

**Recommendation:** Always tell agents when MCP is available for faster results.

---

## Troubleshooting

### "Cannot find module @playwright/mcp"

MCP isn't installed. Run:
```bash
npm install --save-dev @playwright/mcp@1.0.0
```

### "MCP command not found when running tests"

MCP is installed but not in your PATH. Try:
```bash
npx playwright test --debug
```

The `npx` prefix finds the local npm package.

### "MCP is slow or timing out"

MCP requires:
- App running on http://localhost:3000
- Browser installed (run `npx playwright install`)
- Decent machine performance (MCP spawns browser)

If slow, consider running tests without MCP or increasing timeouts.

---

## FAQ

**Q: Do I need MCP to write tests?**
A: No, tests work fine without it. It's optional.

**Q: Does MCP cost anything?**
A: No, it's free and open-source.

**Q: Does MCP require internet?**
A: No, it runs locally on your machine.

**Q: Can I use MCP in CI/CD?**
A: Yes, but it's slower in CI (headless mode). Recommended for local development only.

**Q: What if my app isn't on localhost:3000?**
A: Update FRONTEND_URL in playwright.config.ts or set FRONTEND_URL environment variable.

---

## Best Practices

### When To Use MCP
- Exploring unfamiliar app (interactive is faster)
- Writing complex test scenarios (verify before coding)
- Debugging failing tests (inspect DOM directly)
- Learning Playwright patterns (hands-on exploration)

### When To Skip MCP
- Simple tests from existing code (just read code)
- Automated test generation in CI (no need for UI)
- Limited machine resources (MCP uses more RAM/CPU)
- AI agent writing tests without human input (code reading is fine)

### Configuration

No special configuration needed. MCP works with default Playwright config.

Optional: Increase timeouts in playwright.config.ts if MCP feels slow:

```typescript
export default defineConfig({
  timeout: 60000, // Increase from 30000 if debugging complex flows
})
```

---

## Summary

| Feature | With MCP | Without MCP |
|---------|----------|-----------|
| Speed | Fast (interactive) | Slower (code reading) |
| Ease | Easy (visual exploration) | Medium (code analysis) |
| Required | No | No |
| Cost | Free | Free |
| Learning Curve | Low (visual) | Medium (code) |

**Recommendation for first-time users:** Install MCP and use it. Once you're comfortable with Playwright, you can skip it if you prefer code-based exploration.
