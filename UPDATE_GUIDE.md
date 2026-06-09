# Update Guide: E2E Testing Setup Phases 1-3

**For existing users who installed the pipeline before June 2026**

This guide walks you through updating your project to use the new improvements:
- **Phase 1:** MemoryKit integration + Production-readiness checks
- **Phase 2:** Docker best practices guide + Environment configuration
- **Phase 3:** Code-reading enforcement in agents

---

## Quick Start (5 minutes)

```bash
# 1. Update the bootstrap repository
cd /path/to/e2e-testing-setup
git pull origin main

# 2. Copy new documentation to your project
cp template/docs/*.md /path/to/your-project/docs/

# 3. Copy new templates
cp template/docker-compose.yml /path/to/your-project/
cp template/backend-Dockerfile.example /path/to/your-project/

# 4. Review new documentation
cat /path/to/your-project/docs/E2E_CODE_READING_GUIDE.md

# You're done! Start using the new features.
```

---

## What's New

### Phase 1: MemoryKit Integration

**What changed:**
- Planner and Generator agents now retrieve prior test patterns from memory
- Production-readiness validation before running the pipeline
- Tests compound knowledge: each feature is faster than the last

**New files in your project:**
- `docs/E2E_PRODUCTION_READINESS.md` — Checklist for validating code

**How to use:**
```bash
# Automatically happens when you run phase3-pipeline.sh
./scripts/phase3-pipeline.sh "feature-name" "/page/path"

# Agents will:
# 1. Check Phase -1 production-readiness
# 2. Retrieve prior patterns from memory (if available)
# 3. Create test plans and code
# 4. Store learnings to memory for next feature
```

**If you don't have MemoryKit:**
- Memory integration is optional (agents gracefully skip if unavailable)
- To enable: follow MemoryKit setup in https://github.com/antoniorapozo/memorykit-mcp

---

### Phase 2: Docker + Environment Setup

**What changed:**
- New guide for running backend/database in Docker while tests run locally
- Playwright config now supports multiple environments
- Support for custom backend URLs

**New files in your project:**
- `docs/E2E_DOCKER_SETUP.md` — Complete Docker setup guide
- `docker-compose.yml` — Docker Compose template
- `backend-Dockerfile.example` — Reference Dockerfile

**How to use:**

#### Option A: Just use the new docs (no Docker changes needed)

```bash
# Read the Docker guide to understand best practices
cat docs/E2E_DOCKER_SETUP.md

# Your existing setup is still fully functional
npm run test:e2e:local
```

#### Option B: Adopt the Docker-based approach (recommended)

```bash
# 1. Copy docker-compose.yml to your project root
cp template/docker-compose.yml ./

# 2. Create backend/Dockerfile (use example as reference)
cp template/backend-Dockerfile.example ./backend-Dockerfile.example
# Then copy content to backend/Dockerfile and customize

# 3. Update frontend/e2e/playwright.config.ts with new config
# (Your existing config still works, but new one has better env support)

# 4. Start Docker
docker-compose up

# 5. In new terminal, start frontend
npm run dev

# 6. In another terminal, run tests
npm run test:e2e:local
```

**Key feature:** Environment-specific timeouts

```bash
# Local tests: fast timeouts (5s action, 15s nav, 30s test)
TEST_ENV=local npm run test:e2e:local

# Docker backend: moderate timeouts (10s action, 20s nav, 60s test)
TEST_ENV=docker npm run test:e2e:local

# Staging: conservative timeouts (15s action, 30s nav, 60s test)
TEST_ENV=staging npm run test:e2e
```

---

### Phase 3: Code-Reading Enforcement

**What changed:**
- Planner agent now reads actual code before creating test plans
- Generator agent verifies code before generating tests
- Tests reference actual code (file:line annotations)

**New files in your project:**
- `docs/E2E_CODE_READING_GUIDE.md` — Code-reading red flags and examples

**How to use:**

Automatically happens when you run the pipeline:

```bash
./scripts/phase3-pipeline.sh "feature-name" "/page/path"

# The Planner will:
# 1. READ src/routes/... to verify route exists
# 2. READ src/components/... to get exact UI text
# 3. READ src/api/... to copy response structure
# 4. Create test plan with code references

# The Generator will:
# 1. VERIFY API contracts against actual code
# 2. VERIFY selectors match component code
# 3. VERIFY test data matches schema
# 4. STOP if code doesn't match plan (prevents false tests)
```

**What to watch for:**

If agents report code mismatches:
```
❌ "Cannot find Delete button in component. Component has: Edit, Cancel."
→ Fix: Update test plan or add missing button to component
```

This is **good** — it catches problems early before writing tests.

---

## Detailed Update Steps

### Step 1: Update Bootstrap Repository

```bash
# If you cloned e2e-testing-setup separately:
cd /path/to/e2e-testing-setup
git pull origin main

# Verify new files exist:
ls -la template/docs/E2E_*_GUIDE.md
ls -la template/docker-compose.yml
```

### Step 2: Copy New Documentation

```bash
# Copy all new documentation files
cp template/docs/E2E_CODE_READING_GUIDE.md /path/to/your-project/docs/
cp template/docs/E2E_DOCKER_SETUP.md /path/to/your-project/docs/
cp template/docs/E2E_PRODUCTION_READINESS.md /path/to/your-project/docs/

# Verify:
ls /path/to/your-project/docs/ | grep E2E_
```

### Step 3: Copy Docker Files (Optional)

```bash
# Copy templates
cp template/docker-compose.yml /path/to/your-project/
cp template/backend-Dockerfile.example /path/to/your-project/

# Read guide to understand Docker setup
cat /path/to/your-project/docs/E2E_DOCKER_SETUP.md

# If adopting Docker approach, customize:
# 1. Edit docker-compose.yml (adjust DB credentials, ports, etc.)
# 2. Create backend/Dockerfile (customize from example)
# 3. Test the setup: docker-compose up
```

### Step 4: Update Playwright Config (Optional)

Your existing `frontend/e2e/playwright.config.ts` still works perfectly.

If you want the new features (env-aware timeouts, BACKEND_URL support):

**Option A: Minimal update** (add env support)
```typescript
// At the top of frontend/e2e/playwright.config.ts
const env = process.env.TEST_ENV || 'local'
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'

// Adjust timeouts per environment
const actionTimeout = env === 'local' ? 5000 : 15000
// ... etc
```

**Option B: Full update** (copy new template)
```bash
# Backup old config
cp frontend/e2e/playwright.config.ts frontend/e2e/playwright.config.ts.backup

# Copy new config from template
# (The new install.sh creates this automatically)
# You can view the template in the bootstrap repo for reference
```

### Step 5: Verify Installation

```bash
# Check all new files exist
ls -la docs/E2E_*_GUIDE.md
ls -la docker-compose.yml
ls -la backend-Dockerfile.example

# Read code-reading guide
cat docs/E2E_CODE_READING_GUIDE.md

# You're done! Try the pipeline:
./scripts/phase3-pipeline.sh "test-feature" "/test-page"
```

---

## Backward Compatibility

**Your existing setup is 100% compatible:**

✅ **Existing tests still work** — No changes required  
✅ **Existing scripts still work** — phase3-pipeline.sh unchanged  
✅ **Existing documentation still valid** — All old docs still apply  
✅ **No breaking changes** — Only additions  

**You can adopt new features gradually:**
- Start using Phase 1 (MemoryKit) whenever ready
- Adopt Phase 2 (Docker) only if you want production-like environment
- Phase 3 (Code-Reading) happens automatically, no action needed

---

## Feature-by-Feature Adoption

### For a Single Feature (Testing the Updates)

```bash
# 1. Read Phase -1: Production-Readiness
cat docs/E2E_PRODUCTION_READINESS.md
# Verify your code is production-ready

# 2. Read Phase 0: Code Reading Guide
cat docs/E2E_CODE_READING_GUIDE.md
# Understand what agents will do

# 3. Run pipeline as usual
./scripts/phase3-pipeline.sh "my-feature" "/my-page"

# 4. Notice the changes:
# - Planner reads actual code
# - Generator verifies code
# - Tests reference file:line
# - Learnings stored to memory (if MemoryKit available)
```

### For Docker Setup (When Ready)

```bash
# 1. Read Docker guide
cat docs/E2E_DOCKER_SETUP.md

# 2. Customize docker-compose.yml for your project

# 3. Create backend/Dockerfile

# 4. Start Docker
docker-compose up

# 5. Run tests against Docker backend
TEST_ENV=docker npm run test:e2e:local
```

### For MemoryKit (Advanced)

```bash
# 1. Install MemoryKit MCP (one-time setup)
# See: https://github.com/antoniorapozo/memorykit-mcp

# 2. Verify MemoryKit is available
# Agents will retrieve context automatically

# 3. After first feature, watch agents reuse patterns
# Feature 2 should be faster than Feature 1
```

---

## Troubleshooting

### "New docs don't show in my project"

```bash
# Copy them manually
cp template/docs/E2E_*_GUIDE.md /path/to/your-project/docs/

# Verify they exist
ls /path/to/your-project/docs/ | grep -E "GUIDE|READINESS"
```

### "Agents skip code-reading steps"

**This is normal.** Code-reading is integrated into the agent prompts, not a separate step.

When you run the pipeline:
1. Agents automatically read code (you'll see progress messages)
2. They verify against actual files
3. They create test plans/code with references

No action needed from you.

### "Docker setup is complex for my project"

**You don't have to use Docker.** Phase 2 is optional.

Your existing local setup still works perfectly:
```bash
npm run test:e2e:local  # Unchanged, still works
```

Phase 2 is a guide for teams that want production-like environments. Use it when ready.

### "MemoryKit not available"

**That's fine.** Phase 1 memory integration is optional.

```bash
# Without MemoryKit:
./scripts/phase3-pipeline.sh "feature" "/page"  # Still works

# With MemoryKit:
./scripts/phase3-pipeline.sh "feature" "/page"  # Agents retrieve/store learnings
```

Both work. With MemoryKit, each feature gets faster.

### "My playwright.config.ts is customized"

**No problem.** Keep your config as-is.

If you want the new features (env-aware timeouts):
```typescript
// Add to top of your existing config
const env = process.env.TEST_ENV || 'local'
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3001'

// You can selectively add features without replacing the whole file
```

---

## Next Steps

### Immediately (Right Now)

1. ✅ Pull latest bootstrap code: `git pull origin main`
2. ✅ Copy docs: `cp template/docs/*.md your-project/docs/`
3. ✅ Read code-reading guide: `cat docs/E2E_CODE_READING_GUIDE.md`
4. ✅ Try pipeline: `./scripts/phase3-pipeline.sh "feature" "/page"`

### Soon (This Week)

- [ ] Read E2E_PRODUCTION_READINESS.md
- [ ] Check if code is production-ready (Phase -1)
- [ ] Review agent code-reading behavior

### Later (This Month)

- [ ] Consider Docker setup (read E2E_DOCKER_SETUP.md)
- [ ] Set up docker-compose.yml if adopting Docker approach
- [ ] Install MemoryKit for knowledge compounding

### Long-Term (Ongoing)

- [ ] Watch agents learn from features (Phase 1 compounding)
- [ ] Use Docker for production-like testing (Phase 2)
- [ ] Reference code-reading patterns in new features (Phase 3)

---

## Questions?

**If something doesn't work:**
1. Check this UPDATE_GUIDE.md first
2. Read the relevant doc (E2E_CODE_READING_GUIDE.md, E2E_DOCKER_SETUP.md, etc.)
3. Check bootstrap repo issues: https://github.com/Enricrypto/e2e-testing-setup/issues

---

## Summary

| Phase | What's New | Required? | Action |
|-------|-----------|-----------|--------|
| **Phase 1** | MemoryKit + Production-readiness | Optional | Copy docs, agents handle rest |
| **Phase 2** | Docker guide + Environment config | Optional | Read guide, adopt if you want |
| **Phase 3** | Code-reading enforcement | Automatic | No action, happens in pipeline |

**Bottom line:** Copy the docs, keep using the pipeline as normal. New features activate automatically, existing setup is unchanged.
