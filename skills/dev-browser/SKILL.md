# Dev Browser Skill

Browser automation skill for verifying UI stories. Essential for Ralph's autonomous workflow when implementing frontend features.

Based on [SawyerHood/dev-browser](https://github.com/SawyerHood/dev-browser) - adapted for Claude Code.

## Purpose

When Ralph implements UI stories, this skill enables:
- Visual verification that changes work correctly
- Form testing and interaction
- Screenshot capture for documentation
- Detection of UI bugs before committing

## Prerequisites

```bash
# Install Playwright
npm install -D playwright
npx playwright install chromium

# Or use Bun (recommended)
bun add -D playwright
bunx playwright install chromium
```

## Usage

### Quick Verification

For simple UI verification during Ralph iterations:

```typescript
// verify-ui.ts
import { chromium } from 'playwright';

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

async function verify() {
  const browser = await chromium.launch({ headless: false, slowMo: 100 });
  const page = await browser.newPage();
  
  try {
    await page.goto(BASE_URL);
    
    // Your verification logic here
    console.log('✅ Page loaded successfully');
    console.log('Title:', await page.title());
    
    // Take screenshot
    await page.screenshot({ path: 'tmp/verification.png' });
    
  } catch (error) {
    console.error('❌ Verification failed:', error);
    await page.screenshot({ path: 'tmp/error.png' });
    throw error;
  } finally {
    await browser.close();
  }
}

verify();
```

Run with:
```bash
npx tsx verify-ui.ts
# or
bun run verify-ui.ts
```

## Common Patterns

### 1. Detect Dev Server

Before running tests, detect what's running:

```typescript
import { execSync } from 'child_process';

function detectDevServers(): { port: number; url: string }[] {
  const ports = [3000, 3001, 5173, 8080, 4000];
  const servers: { port: number; url: string }[] = [];
  
  for (const port of ports) {
    try {
      execSync(`lsof -i:${port} -P -n | grep LISTEN`, { stdio: 'pipe' });
      servers.push({ port, url: `http://localhost:${port}` });
    } catch {
      // Port not in use
    }
  }
  
  return servers;
}

const servers = detectDevServers();
console.log('Found servers:', servers);
```

### 2. Form Testing

```typescript
// Test a login form
await page.goto(`${BASE_URL}/login`);
await page.fill('input[name="email"]', 'test@example.com');
await page.fill('input[name="password"]', 'password123');
await page.click('button[type="submit"]');

// Wait for redirect or success message
await page.waitForURL('**/dashboard', { timeout: 5000 });
console.log('✅ Login successful');
```

### 3. Visual Regression

```typescript
// Take before/after screenshots
await page.screenshot({ path: 'tmp/before.png', fullPage: true });

// Make changes...

await page.screenshot({ path: 'tmp/after.png', fullPage: true });
```

### 4. Wait Strategies

```typescript
// Wait for specific element
await page.waitForSelector('.success-message');

// Wait for URL change
await page.waitForURL('**/success');

// Wait for network idle
await page.waitForLoadState('networkidle');

// Wait for specific text
await page.waitForSelector('text=Welcome back');
```

### 5. Element Discovery (AI Snapshot)

Get a structured view of the page for AI understanding:

```typescript
// Get accessibility tree (great for AI)
const snapshot = await page.accessibility.snapshot();
console.log(JSON.stringify(snapshot, null, 2));

// Or get all interactive elements
const interactiveElements = await page.$$eval(
  'a, button, input, select, textarea, [role="button"]',
  els => els.map(el => ({
    tag: el.tagName,
    text: el.textContent?.slice(0, 50),
    name: el.getAttribute('name'),
    id: el.id,
    href: el.getAttribute('href'),
  }))
);
console.log('Interactive elements:', interactiveElements);
```

## Ralph Integration

### In prompt.md

Reference this skill for UI stories:

```markdown
## Browser Verification (UI Stories)

If a story involves frontend/UI changes:

1. Start the dev server if not running
2. Use the dev-browser skill to navigate to the page
3. Verify the changes work as expected
4. Take a screenshot for documentation

A frontend story is NOT complete until browser verification passes.
```

### In prd.json

Add browser verification to UI story acceptance criteria:

```json
{
  "id": "US-004",
  "title": "Create login form UI",
  "acceptanceCriteria": [
    "Login form with email and password fields",
    "Form validation shows errors",
    "Redirects to dashboard on success",
    "Verify in browser using dev-browser skill"
  ]
}
```

## Headless Mode

For CI or Ralph's autonomous mode, use headless:

```typescript
const browser = await chromium.launch({ 
  headless: true  // No visible browser window
});
```

## Error Handling

Always capture screenshots on failure:

```typescript
try {
  await page.click('.submit-button');
  await page.waitForSelector('.success');
} catch (error) {
  // Capture state at failure
  await page.screenshot({ path: 'tmp/failure.png' });
  
  // Get console logs
  const logs = await page.evaluate(() => 
    (window as any).__CONSOLE_LOGS || []
  );
  console.error('Console logs:', logs);
  
  throw error;
}
```

## Quick Reference

| Action | Code |
|--------|------|
| Navigate | `await page.goto(url)` |
| Click | `await page.click('selector')` |
| Fill input | `await page.fill('input[name="x"]', 'value')` |
| Get text | `await page.textContent('selector')` |
| Screenshot | `await page.screenshot({ path: 'file.png' })` |
| Wait for element | `await page.waitForSelector('selector')` |
| Wait for URL | `await page.waitForURL('**/path')` |
| Check visibility | `await page.isVisible('selector')` |
| Get all elements | `await page.$$('selector')` |

## Full Example: Verify Login Flow

```typescript
// scripts/verify-login.ts
import { chromium } from 'playwright';

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

async function verifyLoginFlow() {
  const browser = await chromium.launch({ 
    headless: process.env.CI === 'true',
    slowMo: 50 
  });
  const page = await browser.newPage();
  
  console.log('🔍 Testing login flow...');
  
  try {
    // 1. Navigate to login
    await page.goto(`${BASE_URL}/login`);
    await page.screenshot({ path: 'tmp/01-login-page.png' });
    console.log('✅ Login page loaded');
    
    // 2. Test empty form submission
    await page.click('button[type="submit"]');
    await page.waitForSelector('.error-message');
    console.log('✅ Validation errors shown for empty form');
    
    // 3. Test invalid credentials
    await page.fill('input[name="email"]', 'wrong@example.com');
    await page.fill('input[name="password"]', 'wrongpassword');
    await page.click('button[type="submit"]');
    await page.waitForSelector('text=Invalid credentials');
    console.log('✅ Invalid credentials handled');
    
    // 4. Test valid login
    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'correctpassword');
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard', { timeout: 10000 });
    await page.screenshot({ path: 'tmp/02-dashboard.png' });
    console.log('✅ Login successful, redirected to dashboard');
    
    console.log('\n🎉 All login flow tests passed!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
    await page.screenshot({ path: 'tmp/error-state.png' });
    process.exit(1);
  } finally {
    await browser.close();
  }
}

verifyLoginFlow();
```

## Tips for Ralph

1. **Always detect servers first** - Don't hardcode ports
2. **Use headless in CI** - Set via environment variable
3. **Screenshot on success AND failure** - Helps debugging
4. **Keep tests focused** - One verification per script
5. **Use slow motion** - `slowMo: 100` helps see what's happening
6. **Wait properly** - Use explicit waits, not `sleep()`

## See Also

- [Playwright Documentation](https://playwright.dev/docs/intro)
- [SawyerHood/dev-browser](https://github.com/SawyerHood/dev-browser) - Full plugin with persistent server
