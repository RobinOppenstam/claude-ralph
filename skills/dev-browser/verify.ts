#!/usr/bin/env npx tsx
/**
 * Dev Browser - Quick verification script for Ralph
 * Usage: npx tsx verify.ts [url] [--screenshot name]
 * 
 * Examples:
 *   npx tsx verify.ts http://localhost:3000
 *   npx tsx verify.ts http://localhost:3000/login --screenshot login-page
 */

import { chromium, Page, Browser } from 'playwright';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

// Configuration
const CONFIG = {
  headless: process.env.HEADLESS === 'true' || process.env.CI === 'true',
  slowMo: parseInt(process.env.SLOW_MO || '50'),
  timeout: parseInt(process.env.TIMEOUT || '30000'),
  screenshotDir: process.env.SCREENSHOT_DIR || 'tmp',
};

// Detect running dev servers
function detectDevServers(): { port: number; url: string }[] {
  const ports = [3000, 3001, 5173, 5174, 8080, 8000, 4000, 4200];
  const servers: { port: number; url: string }[] = [];
  
  for (const port of ports) {
    try {
      if (process.platform === 'win32') {
        execSync(`netstat -an | findstr ":${port}.*LISTENING"`, { stdio: 'pipe' });
      } else {
        execSync(`lsof -i:${port} -P -n 2>/dev/null | grep LISTEN`, { stdio: 'pipe' });
      }
      servers.push({ port, url: `http://localhost:${port}` });
    } catch {
      // Port not in use
    }
  }
  
  return servers;
}

// Ensure screenshot directory exists
function ensureScreenshotDir() {
  if (!fs.existsSync(CONFIG.screenshotDir)) {
    fs.mkdirSync(CONFIG.screenshotDir, { recursive: true });
  }
}

// Take screenshot with timestamp
async function screenshot(page: Page, name: string): Promise<string> {
  ensureScreenshotDir();
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `${name}-${timestamp}.png`;
  const filepath = path.join(CONFIG.screenshotDir, filename);
  await page.screenshot({ path: filepath, fullPage: true });
  console.log(`📸 Screenshot saved: ${filepath}`);
  return filepath;
}

// Get page info
async function getPageInfo(page: Page) {
  return {
    url: page.url(),
    title: await page.title(),
    viewport: page.viewportSize(),
  };
}

// Get interactive elements
async function getInteractiveElements(page: Page) {
  return page.$$eval(
    'a, button, input, select, textarea, [role="button"], [onclick]',
    els => els.slice(0, 50).map((el, i) => ({
      index: i,
      tag: el.tagName.toLowerCase(),
      type: el.getAttribute('type'),
      text: el.textContent?.trim().slice(0, 30),
      name: el.getAttribute('name'),
      id: el.id || undefined,
      placeholder: el.getAttribute('placeholder'),
      href: el.getAttribute('href')?.slice(0, 50),
    })).filter(el => el.text || el.name || el.id || el.placeholder)
  );
}

// Main verification function
async function verify(targetUrl?: string, options: { screenshot?: string } = {}) {
  let browser: Browser | null = null;
  
  try {
    // Detect URL if not provided
    if (!targetUrl) {
      const servers = detectDevServers();
      if (servers.length === 0) {
        console.error('❌ No dev server detected. Start your dev server or provide a URL.');
        console.log('   Usage: npx tsx verify.ts http://localhost:3000');
        process.exit(1);
      }
      if (servers.length === 1) {
        targetUrl = servers[0].url;
        console.log(`🔍 Detected dev server: ${targetUrl}`);
      } else {
        console.log('🔍 Multiple dev servers detected:');
        servers.forEach((s, i) => console.log(`   ${i + 1}. ${s.url}`));
        targetUrl = servers[0].url;
        console.log(`   Using: ${targetUrl}`);
      }
    }
    
    // Launch browser
    console.log(`\n🚀 Launching browser (headless: ${CONFIG.headless})...`);
    browser = await chromium.launch({
      headless: CONFIG.headless,
      slowMo: CONFIG.slowMo,
    });
    
    const page = await browser.newPage();
    page.setDefaultTimeout(CONFIG.timeout);
    
    // Navigate
    console.log(`📄 Navigating to: ${targetUrl}`);
    await page.goto(targetUrl, { waitUntil: 'networkidle' });
    
    // Get page info
    const info = await getPageInfo(page);
    console.log(`\n✅ Page loaded successfully`);
    console.log(`   Title: ${info.title}`);
    console.log(`   URL: ${info.url}`);
    
    // Get interactive elements
    const elements = await getInteractiveElements(page);
    if (elements.length > 0) {
      console.log(`\n🎯 Interactive elements (${elements.length}):`);
      elements.slice(0, 10).forEach(el => {
        const desc = el.text || el.placeholder || el.name || el.id || 'unnamed';
        console.log(`   - ${el.tag}${el.type ? `[${el.type}]` : ''}: ${desc}`);
      });
      if (elements.length > 10) {
        console.log(`   ... and ${elements.length - 10} more`);
      }
    }
    
    // Take screenshot
    const screenshotName = options.screenshot || 'verification';
    await screenshot(page, screenshotName);
    
    // Check for common issues
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });
    
    // Brief wait to catch any delayed errors
    await page.waitForTimeout(1000);
    
    if (consoleErrors.length > 0) {
      console.log(`\n⚠️  Console errors detected:`);
      consoleErrors.forEach(err => console.log(`   - ${err.slice(0, 100)}`));
    }
    
    console.log(`\n✅ Verification complete!`);
    
  } catch (error) {
    console.error(`\n❌ Verification failed:`, error);
    process.exit(1);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

// Parse CLI args
function parseArgs(): { url?: string; screenshot?: string } {
  const args = process.argv.slice(2);
  const result: { url?: string; screenshot?: string } = {};
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--screenshot' && args[i + 1]) {
      result.screenshot = args[i + 1];
      i++;
    } else if (!args[i].startsWith('--')) {
      result.url = args[i];
    }
  }
  
  return result;
}

// Run
const { url, screenshot: screenshotName } = parseArgs();
verify(url, { screenshot: screenshotName });
