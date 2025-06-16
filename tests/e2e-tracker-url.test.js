import puppeteer from "puppeteer";
import path from "path";
import { fileURLToPath } from "url";
import assert from "assert";

const EXT_PATH = path.resolve(".");

const TRACKER_URL =
  // "https://pmwebq.clicks.mlsend.com/tj/c/eyJ2Ijoie1wiYVwiOjEyMzU0MDAsXCJsXCI6MTU3MjAyNDk2OTQ4Nzk4ODQ5LFwiclwiOjE1NzIwMjUwOTYwNjE1OTkwN30iLCJzIjoiOTg1OTEzNzhlZDc1NTczZCJ9";
  "https://google.com";
const EXPECTED_URL =
  "https://www.infoq.com/articles/microservices-traffic-mirroring-istio-vpc/";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

(async () => {
  const browser = await puppeteer.launch({
    // Set to false to visually debug
    headless: false,
    args: [
      `--disable-extensions-except=${EXT_PATH}`,
      `--load-extension=${EXT_PATH}`,
    ],
  });

  const targets = await browser.targets();
  // The code checks all browser targets (pages, workers, etc.) and 
  // finds the one that matches either type, so it works for both V2 and V3 extensions.
  const extensionTarget = targets.find(
    t => t.type() === 'background_page' || t.type() === 'service_worker'
  );
  console.log("[DEBUG] Extension loaded:", !!extensionTarget);


  const page = await browser.newPage();
  await page.goto("about:blank");

  // Open the test URL
  const testPage = await browser.newPage();
  // If this is missing, console.log from the content script won't show up
  testPage.on("console", (msg) => {
    console.log("[BROWSER]", msg.text());
  });
  await testPage.goto(TRACKER_URL, { waitUntil: "domcontentloaded" });

  // Wait a moment to let content.js act (click simulation, etc.)
  await new Promise(resolve => setTimeout(resolve, 3000));

  // Check if a new tab was opened with the expected final URL
  const pages = await browser.pages();
  const urls = pages.map(p => p.url());

  assert(
    urls.includes(EXPECTED_URL),
    `Expected URL not found. Found: ${urls.join("\n")}`
  );

  console.log("Test passed: tracking URL redirected successfully.");
  await browser.close();
})();
