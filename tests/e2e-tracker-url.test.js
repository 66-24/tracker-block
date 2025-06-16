import puppeteer from "puppeteer";
import path from "path";
import { fileURLToPath } from "url";
import assert from "assert";

// CommonJS was created for Node.js to allow modular code using require and module.exports.
// ES Modules were later added to the JavaScript language standard, designed to work in both browsers and Node.js,
// using import and export.
// Today, Node.js supports both, but ES Modules are the official standard for JavaScript going forward.

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const EXT_PATH = path.resolve(__dirname, "../extension");

const TRACKER_URL =
  "https://pmwebq.clicks.mlsend.com/tj/c/eyJ2Ijoie1wiYVwiOjEyMzU0MDAsXCJsXCI6MTU3MjAyNDk2OTQ4Nzk4ODQ5LFwiclwiOjE1NzIwMjUwOTYwNjE1OTkwN30iLCJzIjoiOTg1OTEzNzhlZDc1NTczZCJ9";

const EXPECTED_URL =
  "https://www.infoq.com/articles/microservices-traffic-mirroring-istio-vpc/";

(async () => {
  console.log("[DEBUG] EXT_PATH:", EXT_PATH);

  // Use Chrome DevTools Protocol (CDP) to launch the browser with the extension.
  // WebDriver-BiDi is still experimental and not widely supported at this time.
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      `--disable-extensions-except=${EXT_PATH}`,
      `--load-extension=${EXT_PATH}`,
    ],
  });

  // wait for service worker to register
  // Javascript is designed to be non-blocking and event-drive. So we use setTimeout event to wait for the extension to load.
  await new Promise((res) => setTimeout(res, 1000));
  const targets = browser.targets();
  console.log("[DEBUG] Targets found:");
  targets.forEach((t) => console.log(`→ ${t.type()} | ${t.url()}`));

  const extensionTarget = targets.find(
    (t) => t.type() === "background_page" || t.type() === "service_worker"
  );

  if (!extensionTarget) {
    console.error("❌ Extension failed to load.");
    await browser.close();
    process.exit(1);
  }

  console.log("✅ Extension loaded successfully.");

  const testPage = await browser.newPage();
  testPage.on("console", (msg) => console.log("[BROWSER]", msg.text()));

  console.log(`[INFO] Navigating to: ${TRACKER_URL}`);
  await testPage.goto(TRACKER_URL, { waitUntil: "domcontentloaded" });

  console.log(`[INFO] Waiting for new tab with: ${EXPECTED_URL}`);
  const target = await browser.waitForTarget((t) => t.url() === EXPECTED_URL, {
    timeout: 5000,
  });

  assert(target, `❌ Expected tab not found: ${EXPECTED_URL}`);
  console.log("✅ Test passed: extension redirected as expected.");
  console.log("[DEBUG] Tab opened:", target.url());

  await browser.close();
})();
