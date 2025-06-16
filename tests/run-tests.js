const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
  console.log('🧪 Starting minimal Chrome extension test');

  const extensionPath = path.resolve('extension');
  const requiredFiles = [
    'manifest.json',
    'background.js',
    'tracker-block-extension.js',
    'tracking-blocker.js',
    'tracker-urls.txt',
  ];

  for (const file of requiredFiles) {
    const fullPath = path.join(extensionPath, file);
    if (!fs.existsSync(fullPath)) {
      console.error(`❌ Missing: ${file}`);
      process.exit(1);
    }
  }

  console.log('✅ All required extension files found');

  const browser = await puppeteer.launch({
    headless: 'new',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      `--load-extension=${extensionPath}`,
      `--disable-extensions-except=${extensionPath}`,
    ],
  });

  console.log('✅ Chrome launched with extension');
  await browser.close();
  console.log('✅ Test complete — browser closed cleanly');
})();
