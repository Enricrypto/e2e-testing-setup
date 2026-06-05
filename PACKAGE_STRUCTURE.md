# E2E Testing Bootstrap Package Structure

This document explains the complete package structure, how files relate to each other, and how it integrates with the global skill system.

---

## What This Package Contains

```
e2e-testing-setup/                          # The complete bootstrap package
├── README.md                               # Main documentation (read first!)
├── SETUP_GUIDE.md                          # Installation & troubleshooting
├── PACKAGE_STRUCTURE.md                    # This file
├── install.sh                              # One-command installer
│
├── template/                               # Files to copy into project
│   ├── frontend/e2e/                       # E2E testing structure
│   │   ├── playwright.config.ts            # Playwright configuration
│   │   ├── global-setup.ts                 # Pre-test setup (seeds data)
│   │   ├── global-teardown.ts              # Post-test cleanup
│   │   │
│   │   ├── tests/
│   │   │   ├── fixtures.ts                 # Test fixtures (auth, setup)
│   │   │   ├── 01-example/
│   │   │   │   ├── example.spec.ts         # Example test (reference)
│   │   │   │   └── README.md
│   │   │   └── [XX-your-feature]/         # Your feature tests (generated)
│   │   │
│   │   ├── pom/
│   │   │   ├── BasePage.ts                 # Base class (semantic locators)
│   │   │   ├── ExamplePage.ts              # Example POM class
│   │   │   └── [YourFeaturePage.ts]       # Your feature POMs (generated)
│   │   │
│   │   └── utils/
│   │       ├── test-data.ts                # UUID factories, helpers
│   │       ├── assertions.ts               # Custom assertions
│   │       └── helpers.ts                  # Test utilities
│   │
│   ├── docs/                               # Context & guidance documents
│   │   ├── E2E_DEEP_AUDIT_CHECKLIST.md     # Phase 0: Pre-generation audit
│   │   ├── E2E_PIPELINE_AUDIT.md           # Phase 8: Post-generation audit
│   │   ├── PHASE_3_AUTOMATED_PIPELINE.md   # Pipeline flow reference
│   │   ├── E2E_SEMANTIC_LOCATORS.md        # Locator patterns & rules
│   │   └── E2E_TESTING.md                  # General E2E testing guide
│   │
│   ├── scripts/
│   │   └── phase3-pipeline.sh              # The orchestrator script
│   │
│   └── package.json.snippet                # Dependencies to add
│
└── config/
    └── e2e-init-checklist.md               # Verification checklist
```

---

## How It Works: The Three Layers

### Layer 1: Global Skill (`~/.claude/skills/software/playwright-e2e-modern.md`)

**Purpose:** Guidance and principles  
**Contains:**
- Philosophy (codebase-first, deep audits)
- Semantic locator patterns
- Fixture patterns
- UUID test data patterns
- Phase 0 & Phase 8 audit checklists

**Availability:** Available everywhere (all projects)

### Layer 2: Bootstrap Package (`e2e-testing-setup`)

**Purpose:** Working code and automation  
**Contains:**
- Template files (playwright config, fixtures, POM structure)
- Complete documentation (Phase 0/8 checklists)
- Install script (`install.sh`)
- Pipeline orchestrator (`phase3-pipeline.sh`)

**Availability:** Standalone repo (cloned into projects as needed)

### Layer 3: Project Integration

**Purpose:** Working E2E setup in your specific project  
**Created by:** `install.sh` (copies Layer 2 into project)  
**Contains:**
- `frontend/e2e/` with complete structure
- `docs/` with all guidance
- `scripts/phase3-pipeline.sh` ready to run

**Availability:** Inside each project after installation

---

## How They Work Together

```
Developer starts a new project
    ↓
Reads global skill (guidance)
    ↓
Runs install.sh from bootstrap package
    ↓
Package contents copied into project
    ↓
Developer runs ./scripts/phase3-pipeline.sh
    ↓
Pipeline guides through 8 steps:
  1. Phase 0 audit (using docs/E2E_DEEP_AUDIT_CHECKLIST.md)
  2. Prerequisites check
  3. Planner agent (explore app)
  4. Generator agent (create code)
  5. Code verification
  6. Type check
  7. Test execution
  8. Phase 8 audit (using docs/E2E_PIPELINE_AUDIT.md)
    ↓
Tests committed, feature complete
```

---

## File Relationships

### Global Skill → Bootstrap Package

The global skill provides **principles**. The bootstrap package implements them:

| Skill Section | Bootstrap Implementation |
|---|---|
| Semantic Locators | `pom/BasePage.ts` (helper methods) |
| Fixture Patterns | `tests/fixtures.ts` (examples) |
| UUID Test Data | `utils/test-data.ts` (factories) |
| Phase 0 Audit | `docs/E2E_DEEP_AUDIT_CHECKLIST.md` |
| Phase 8 Audit | `docs/E2E_PIPELINE_AUDIT.md` |
| Test Structure | `tests/01-example/*.spec.ts` (examples) |

### Within Project

After installation, files interact as:

```
playwright.config.ts
    ↓ (configures)
tests/fixtures.ts
    ↓ (uses)
tests/01-example/example.spec.ts
    ↓ (extends)
pom/BasePage.ts
    ↓ (uses)
utils/test-data.ts
```

---

## Installation Flow

```
1. Developer has project root with package.json

2. Developer runs:
   bash <(curl -s https://... e2e-testing-setup/install.sh)

3. install.sh does:
   - Create frontend/e2e/{tests,pom,utils} directories
   - Copy template/frontend/e2e/* → frontend/e2e/
   - Copy template/docs/* → docs/
   - Copy template/scripts/* → scripts/
   - Add E2E npm scripts to package.json

4. Result: Complete E2E setup ready to use
   - playwright.config.ts configured
   - Fixtures ready
   - POM structure ready
   - All documentation available
   - phase3-pipeline.sh ready to run
```

---

## Documentation Map

### For Developers New to E2E

1. **README.md** (this package)
   - Read first, 10 min
   - Explains what the system is
   - High-level overview of flows

2. **SETUP_GUIDE.md** (this package)
   - Install and verify setup
   - Troubleshoot issues
   - First test run

3. **docs/E2E_DEEP_AUDIT_CHECKLIST.md** (in project after install)
   - Before running pipeline
   - Understand your feature
   - Document flows and edge cases

4. **docs/PHASE_3_AUTOMATED_PIPELINE.md** (in project after install)
   - Reference for all 8 steps
   - What happens at each step
   - Expected outputs

5. **docs/E2E_SEMANTIC_LOCATORS.md** (in project after install)
   - When writing tests
   - Locator patterns
   - Why semantic locators matter

6. **docs/E2E_PIPELINE_AUDIT.md** (in project after install)
   - After pipeline generates tests
   - Verify tests match actual code
   - Prevent false coverage

### For Reference

- **E2E_TESTING.md** (in project after install)
  - General E2E testing principles
  - Best practices
  - Common patterns

- **Global Skill** (`~/.claude/skills/software/playwright-e2e-modern.md`)
  - Complete philosophy
  - All patterns
  - All audit checklists (duplicated in project docs)

---

## The Three Audit Phases

### Phase 0: Pre-Generation (Manual)

**What:** Developer understands the codebase  
**When:** Before running pipeline  
**Using:** `docs/E2E_DEEP_AUDIT_CHECKLIST.md`  
**Output:** Documented understanding (shared with AI)  
**Purpose:** AI understands what actually exists

**Checklist includes:**
- Routes & pages
- Components & state
- API endpoints & contracts
- User flows & preconditions
- Edge cases & error scenarios
- Existing test patterns

### Phases 1-7: Automated Pipeline (AI-Assisted)

**What:** System generates tests with human oversight  
**When:** During `./scripts/phase3-pipeline.sh` execution  
**Process:**
1. Prerequisites check
2. Skill display
3. Planner explores app
4. Generator creates code
5. Code verified (semantic locators, cleanup, etc.)
6. TypeScript type check
7. Tests execute

**Human role:** Copy/paste prompts, review outputs

### Phase 8: Post-Generation (Manual)

**What:** Developer verifies tests match code  
**When:** After pipeline generates tests  
**Using:** `docs/E2E_PIPELINE_AUDIT.md`  
**Output:** Verified, working tests  
**Purpose:** Prevent false test coverage

**Checklist includes:**
- Assertion accuracy
- Test data realism
- Edge case coverage
- State transitions
- Cleanup verification
- No ghost features validation

---

## Key Design Decisions

### Why Two Docs for Each Audit Phase?

1. **Global Skill** (`playwright-e2e-modern.md`)
   - Available across ALL projects
   - Principles and patterns
   - Portable, doesn't change per-project

2. **Project Docs** (`docs/E2E_*_CHECKLIST.md`)
   - Copied into each project
   - Same content as skill
   - Easy reference (don't need to remember skill path)

**Benefit:** Developer has everything they need inside their project. No need to jump between skill and project docs.

### Why install.sh?

**Problem:** Developers can forget to copy all files, miss dependencies, miss npm scripts.

**Solution:** Single script does it all:
- Creates directories
- Copies all template files
- Adds npm scripts to package.json
- Verifies installation

**Benefit:** No manual setup steps = fewer mistakes = faster onboarding

### Why Bootstrap Package Instead of NPM Package?

**Considered:**
- NPM package (@yourorg/e2e-setup)
- Docker image
- Monorepo template

**Chosen: Git repo + install.sh**
- Easy to clone
- Easy to keep updated
- Easy to customize per project
- No npm version dependency
- Works with any setup

---

## For Contributors

If you improve this package:

1. **Update `template/` files** — these get copied to projects
2. **Update `docs/` files** — these are project documentation
3. **Update `install.sh`** — if adding new files
4. **Update this README.md** — if changing how it works
5. **Version it** — tag releases so projects can pin versions

---

## Deployment Path

```
1. You maintain: e2e-testing-setup/ repo
   ↓
2. Users clone/install via:
   bash <(curl -s .../install.sh)
   ↓
3. Becomes: your-project/frontend/e2e/ + docs/ + scripts/
   ↓
4. Developer uses: ./scripts/phase3-pipeline.sh
   ↓
5. Tests generated, committed, shipped
```

---

## Summary

This package solves the **portability problem**:

- **Global Skill**: Guidance (available everywhere)
- **Bootstrap Package**: Implementation (cloned into projects)
- **Install Script**: Automation (one command to set everything up)

Result: Any developer on any project can get a complete, working E2E system in minutes.

---

**Package Version:** 1.0  
**Created:** 2026-06-05  
**Status:** Production-ready
