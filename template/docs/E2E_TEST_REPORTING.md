# E2E Test Reporting

This guide explains how to read and understand Playwright test reports and metrics.

---

## HTML Report

After running tests, Playwright generates an interactive HTML report.

### View Report

```bash
npx playwright show-report
```

This opens the report in your browser at `file:///path/to/playwright-report/index.html`.

### What You See

The report shows:

- **Test Status**: ✅ Passed, ❌ Failed, ⏭️ Skipped
- **Execution Time**: How long each test took
- **Failure Details**: Error messages and stack traces
- **Video Playback**: Video of test execution (if enabled)
- **Traces**: Detailed step-by-step execution (if enabled)
- **Screenshots**: Failed test screenshots

### Reading the Report

1. **Summary Page**: Shows overall pass/fail rate
   ```
   3 passed (2s)
   1 failed (5s)
   5 skipped
   ```

2. **Test List**: Each test shows status and duration
   ```
   ✅ should load homepage (1.2s)
   ❌ should submit form (4.8s) → Error: element not found
   ✅ should show success message (2.1s)
   ```

3. **Detailed View**: Click test to see full details
   - Error message
   - Stack trace (where error occurred)
   - Video of test execution
   - Screenshots

### Video Playback

If videos are enabled (`video: 'retain-on-failure'` in config):

- Failed tests have video recordings
- Useful for understanding WHY test failed
- Can see timing issues, missing elements, etc.
- VCS friendly: Only saves on failure

### Trace Viewer

If traces are enabled (`trace: 'retain-on-failure'`):

```bash
npx playwright show-trace test-results/trace.zip
```

Traces show:
- Every action (click, type, navigate)
- DOM state after each action
- Network events
- Console logs

Useful for debugging complex failures.

---

## JSON Results

For programmatic analysis (CI/CD integration):

```bash
cat frontend/e2e/test-results/results.json
```

### Structure

```json
{
  "stats": {
    "expected": 10,
    "unexpected": 1,
    "flaky": 0,
    "skipped": 0
  },
  "tests": [
    {
      "title": "should load homepage",
      "status": "passed",
      "duration": 1200,
      "location": "frontend/e2e/tests/01-example/example.spec.ts:15"
    },
    {
      "title": "should submit form",
      "status": "failed",
      "duration": 4800,
      "error": {
        "message": "Element not found: [data-testid='submit-button']",
        "stack": "Error: Element not found...",
        "location": "frontend/e2e/tests/01-example/example.spec.ts:42"
      }
    }
  ]
}
```

### Parse Results

Extract metrics from JSON:

```typescript
// analyze-results.ts
const fs = require('fs');
const results = JSON.parse(fs.readFileSync('frontend/e2e/test-results/results.json', 'utf8'));

const { stats, tests } = results;

console.log(`Total Tests: ${stats.expected}`);
console.log(`Passed: ${stats.expected - stats.unexpected}`);
console.log(`Failed: ${stats.unexpected}`);
console.log(`Flaky: ${stats.flaky}`);
console.log(`Pass Rate: ${((stats.expected - stats.unexpected) / stats.expected * 100).toFixed(1)}%`);

// Find slowest tests
const sorted = tests.sort((a, b) => b.duration - a.duration);
console.log('\nSlowest Tests:');
sorted.slice(0, 5).forEach(t => {
  console.log(`  ${t.title}: ${t.duration}ms`);
});

// Find flaky tests
const flaky = tests.filter(t => t.status === 'flaky');
console.log('\nFlaky Tests:');
flaky.forEach(t => {
  console.log(`  ${t.title}`);
});
```

### JUnit XML

For CI integration (Jenkins, GitLab CI, etc.):

```bash
npm run test:e2e -- --reporter=junit
cat frontend/e2e/test-results/results.xml
```

---

## Coverage Tracking Over Time

Track test health trends:

### Weekly Report

Run tests weekly and save reports:

```bash
#!/bin/bash
# save-weekly-report.sh

DATE=$(date +%Y-%m-%d)
REPORT_DIR="test-reports/$DATE"

mkdir -p "$REPORT_DIR"

npm run test:e2e
cp -r frontend/e2e/playwright-report/* "$REPORT_DIR/"

# Also save metrics
node analyze-results.ts >> "$REPORT_DIR/metrics.txt"
```

Schedule in GitHub Actions:

```yaml
on:
  schedule:
    # Run at 9 AM Monday UTC
    - cron: '0 9 * * 1'

jobs:
  weekly-report:
    runs-on: ubuntu-latest
    steps:
      # ... standard setup ...
      - name: Run E2E tests
        run: npm run test:e2e

      - name: Save report
        run: bash save-weekly-report.sh

      - name: Commit report
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "test-report: weekly test results (${{ env.DATE }})"
          file_pattern: test-reports/
```

### Compare Reports

Create dashboard to compare over time:

```bash
# compare-reports.sh
echo "Test Results Trend"
echo "=================="

for dir in test-reports/*/; do
  date=$(basename "$dir")
  
  metrics=$(cat "$dir/metrics.txt")
  echo "$date: $metrics"
done
```

Result:
```
Test Results Trend
==================
2024-06-01: Passed: 45/50 (90%)
2024-06-08: Passed: 47/50 (94%)
2024-06-15: Passed: 50/50 (100%)
```

---

## Reporting Tools

Recommended tools for enterprise reporting:

### Allure Reports

Beautiful test reports with trends:

```bash
npm install --save-dev @playwright/test allure-playwright

# In playwright.config.ts:
reporter: [
  ['html'],
  ['allure-playwright'],
]

# Generate report
npm run test:e2e
allure serve
```

Features:
- Trend graphs
- Test history
- Detailed failure analysis
- Custom dashboards

### Qase.io

Test case management + reporting:

```bash
# Install integration
npm install --save-dev qase-playwright

# Connect to Qase
# Set QASE_API_TOKEN, QASE_PROJECT_CODE env vars

# Run tests (auto-sync with Qase)
npm run test:e2e
```

Features:
- Test case management
- Results tracking
- Metrics and analytics
- Team collaboration

### TestRail

Enterprise test management:

```bash
# Integration guide
# https://www.testrail.io/docs/api/getting-started/

# Set TEST_RAIL_API_KEY, TEST_RAIL_PROJECT_ID env vars
npm run test:e2e

# Results auto-sync to TestRail
```

Features:
- Complete test management
- Milestone tracking
- Defect linking
- Custom workflows

---

## Common Metrics

### Pass Rate

```
Pass Rate = (Passed Tests / Total Tests) × 100
```

Target: **95%+** (98%+ is excellent)

### Flaky Test Rate

```
Flaky Rate = (Flaky Tests / Total Tests) × 100
```

Target: **<2%** (flaky tests reduce confidence)

### Average Test Duration

```
Average Duration = Sum of all test times / Total Tests
```

Target: **<2s per test** (slower tests = longer CI runs)

### Slowest Tests

Which tests take the most time?

```typescript
// Find tests >5s
tests
  .filter(t => t.duration > 5000)
  .sort((a, b) => b.duration - a.duration)
```

Optimize by:
- Removing unnecessary waits
- Using fixtures instead of manual setup
- Parallelizing independent tests

---

## GitHub Actions Integration

Show test results directly in GitHub:

```yaml
      - name: Publish test results
        if: always()
        uses: dorny/test-reporter@v1
        with:
          name: E2E Test Results
          path: 'frontend/e2e/test-results/results.xml'
          reporter: 'java-junit'
          fail-on-error: false
```

This shows:
- ✅ Summary in PR
- 📊 Test count and pass rate
- 📝 Failed test details
- 🔗 Link to full report

---

## Dashboard Example

Create simple test dashboard:

```html
<!-- test-dashboard.html -->
<!DOCTYPE html>
<html>
<head>
  <title>E2E Test Dashboard</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
  <h1>E2E Test Metrics</h1>
  
  <div>
    <h2>Pass Rate Trend</h2>
    <canvas id="passRateChart"></canvas>
  </div>
  
  <script>
    const data = {
      labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
      datasets: [{
        label: 'Pass Rate (%)',
        data: [90, 92, 95, 98],
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1
      }]
    };

    new Chart(document.getElementById('passRateChart'), {
      type: 'line',
      data: data,
      options: {
        responsive: true,
        scales: {
          y: {
            beginAtZero: true,
            max: 100
          }
        }
      }
    });
  </script>
</body>
</html>
```

---

## Best Practices

1. **Automate Report Saving** — Save every test run
   ```bash
   npm run test:e2e && cp -r playwright-report reports/$(date +%Y-%m-%d)/
   ```

2. **Track Trends** — Compare over weeks/months
   - Notice improving/declining patterns
   - Identify flaky tests early

3. **Share Reports** — Make results visible to team
   - Post in Slack
   - Upload to dashboard
   - Attach to CI/CD artifacts

4. **Investigate Failures** — Don't ignore errors
   - Watch videos
   - Read stack traces
   - Fix root cause

5. **Celebrate Improvements** — 100% pass rate is achievable
   - Track from current state
   - Set realistic targets
   - Celebrate milestones

---

## Summary

Playwright provides:
- **HTML Report**: Visual inspection with videos
- **JSON Results**: Programmatic analysis
- **JUnit XML**: CI/CD integration
- **Traces**: Deep debugging

Use reporting tools (Allure, Qase, TestRail) for enterprise features.

Key metrics:
- Pass rate (target: 95%+)
- Flaky rate (target: <2%)
- Average duration (target: <2s)

Make test health visible to your team!
